// Autores:
// Allan Giovanni Matias Paes - 25008211
// Pedro Vinícius Romanato - 25004075
import { HttpsError } from "firebase-functions/v2/https";
import { Timestamp } from "firebase-admin/firestore";
import { db } from "../../shared/firebase";
import { normalizeString } from "../../shared/validation";
import {
  getOfferById,
  getOffersBySellerId,
  listOffers,
  createOfferInTransaction,
  cancelOfferInTransaction,
  expireOfferInTransaction,
} from "../repositories/offerRepository";
import { upsertStartupInvestor } from "../../startups/shared/upsertInvestor";
import { Wallet } from "../../user/types";
import { TransactionService } from "./transactionService";
import { Offer, OfferWithId } from "../types";
import {
  CreateOfferRequestDTO,
  BuyTokensRequestDTO,
  BuyTokensResponseDTO,
  CancelOfferRequestDTO,
  CancelOfferResponseDTO,
  ExpireOfferResponseDTO,
  GetMyOffersResponseDTO,
  MyOfferDTO,
  GetOffersRequestDTO,
  PaginatedOffersResponseDTO,
} from "../types/dtos";
import { validateTransactionData } from "../utils";
import { TokenPricingService } from "../../shared/tokenPricingService";
import { StartupDocument } from "../../startups/types";
import { UserService } from "../../user/shared/userService";
import { WalletTokenPositionDTO } from "../../user/types/dtos";

// Regras de negocios do balcão de negociação
export class OfferService {
  private tokenPricingService = new TokenPricingService();
  private transactionService = new TransactionService();
  private userService = new UserService();

  // Autor: Allan
  // Método para criar ofertas
  async createOffer(
    sellerId: string,
    data: CreateOfferRequestDTO,
  ): Promise<OfferWithId> {
    const { startupId, qtdTokens, tokenPriceCents, expiresAt } = data;

    // Verifica se vem tudo certo do request
    if (!startupId || !qtdTokens || !tokenPriceCents) {
      throw new HttpsError(
        "invalid-argument",
        "Dados insuficientes (startupId, qtdTokens, tokenPriceCents).",
      );
    }

    // função auxiliar que verifica se está apto a fazer a transação
    const { sellerUser, startup } = await validateTransactionData({
      sellerId,
      startupId,
      qtdTokens,
      tokenPriceCents,
    });

    // limita o valor do token a ser ofertado um range de de -50% a +50% do valor unitário do token atualmente.
    const maxPrice = startup.currentTokenPriceCents * 1.5; // +50%
    const minPrice = startup.currentTokenPriceCents * 0.5; // -50%

    // caso esteja fora da banda, lança um erro
    if (tokenPriceCents > maxPrice || tokenPriceCents < minPrice) {
      throw new HttpsError(
        "invalid-argument",
        "Preço fora da banda permitida de mercado.",
      );
    }

    const now = Timestamp.now();

    // encontra a posição do comprador
    const sellerPosition = sellerUser?.wallet?.positions?.find(
      (p: WalletTokenPositionDTO) => p.startupId === startupId,
    );
    // pega o preço medio que o vendedor pagou naquela posição.
    const averageAcquisitionPriceCents = sellerPosition?.averagePriceCents || 0;

    // Cria uma oferta
    const offerData: Offer = {
      startupId,
      startupName: startup.name,
      seller: {
        id: sellerId,
        name: sellerUser?.name || startup.name,
        type: "USER",
      },
      qtdTokens,
      initialQtdTokens: qtdTokens,
      averageAcquisitionPriceCents,
      tokenPriceCents,
      totalCents: qtdTokens * tokenPriceCents,
      status: "OPEN",
      transactionType: "USER_TRADE",
      createdAt: now,
    };

    // se tiver data de expiração, só valida ela e se estiver correto, coloca nos dados da oferta.
    if (expiresAt) {
      const expirationDate = new Date(expiresAt);
      if (isNaN(expirationDate.getTime())) {
        throw new HttpsError("invalid-argument", "Data de expiração inválida.");
      }
      offerData.expiresAt = Timestamp.fromDate(expirationDate);
    }

    // Armazena a oferta e pega o ID gerado
    const offerId = await createOfferInTransaction(sellerId, offerData);
    const offer = await getOfferById(offerId);

    if (!offer) {
      throw new HttpsError("internal", "Erro ao recuperar oferta criada.");
    }

    return offer;
  }

  // Autor: Pedro
  // Método para cancelar uma oferta
  async cancelOffer(
    sellerId: string,
    data: CancelOfferRequestDTO,
  ): Promise<CancelOfferResponseDTO> {
    // pega o id da oferta
    const offerId = normalizeString(data?.id);

    if (!offerId) {
      throw new HttpsError(
        "invalid-argument",
        "offerId deve estar presente no corpo da requisição.",
      );
    }

    // busca a oferta no banco
    const offer = await getOfferById(offerId);

    if (!offer) {
      throw new HttpsError("not-found", "Oferta não encontrada.");
    }

    // se o vendedor e o usuario que esta tentando cancelar a oferta forem diferentes, dá erro
    if (offer.seller.id !== sellerId) {
      throw new HttpsError(
        "permission-denied",
        "Apenas o vendedor pode cancelar a própria oferta.",
      );
    }

    // Só pode cancelar se estiver aberta
    if (offer.status !== "OPEN") {
      throw new HttpsError(
        "failed-precondition",
        `Oferta não pode ser cancelada: status atual é ${offer.status}.`,
      );
    }

    // cancela a oferta usando transaction
    const cancelled = await cancelOfferInTransaction(offerId, sellerId);

    return { offerId, cancelled };
  }

  // Autor: Allan
  // método para comprar tokens de outros usuários
  async buyTokens(
    buyerId: string,
    data: BuyTokensRequestDTO,
  ): Promise<BuyTokensResponseDTO> {
    // Validações iniciais
    const offerId = normalizeString(data?.offerId);
    const qtdTokens = data.qtdTokens;

    if (!offerId || !qtdTokens || qtdTokens <= 0) {
      throw new HttpsError(
        "invalid-argument",
        "offerId e qtdTokens > 0 são obrigatórios.",
      );
    }

    // pega oferta e o comprador
    const [offer, buyerUser] = await Promise.all([
      getOfferById(offerId),
      this.userService.get(buyerId),
    ]);

    if (!offer) {
      throw new HttpsError("not-found", "Oferta não encontrada.");
    }

    if (!buyerUser) {
      throw new HttpsError("not-found", "Comprador não encontrado.");
    }

    const now = Timestamp.now();

    // se a oferta não estiver aberta, lança erro
    if (offer.status !== "OPEN") {
      throw new HttpsError("failed-precondition", "Oferta não está aberta.");
    }

    // se a oferta expirou, lança erro
    if (offer.expiresAt && offer.expiresAt.toMillis() < now.toMillis()) {
      throw new HttpsError("failed-precondition", "Oferta expirou.");
    }

    // o vendedor não pode comprar sua propria oferta
    if (offer.seller.id === buyerId) {
      throw new HttpsError(
        "invalid-argument",
        "Comprador não pode ser vendedor.",
      );
    }

    // pega o vendedor da oferta
    const sellerId = offer.seller.id;

    if (!sellerId) {
      throw new HttpsError("failed-precondition", "Vendedor inválido.");
    }

    // roda uma transaction (só vai alterar o estado do banco se todas as querys derem certo)
    return db.runTransaction(async (tx) => {
      // pega tudo que está sendo usado (comprador, vendedor, oferta, investidor e startup)
      const sellerRef = db.collection("users").doc(sellerId);
      const buyerRef = db.collection("users").doc(buyerId);
      const offerRef = db.collection("offers").doc(offerId);
      const startupRef = db.collection("startups").doc(offer.startupId);
      const investorRef = db
        .collection("startups")
        .doc(offer.startupId)
        .collection("investors")
        .doc(buyerId);

      // pega o snapshot de cada uma das referncias
      const [sellerSnap, buyerSnap, offerSnap, startupSnap, investorSnap] =
        await Promise.all([
          tx.get(sellerRef),
          tx.get(buyerRef),
          tx.get(offerRef),
          tx.get(startupRef),
          tx.get(investorRef),
        ]);

      // verifica se vendedor, comprador, oferta e startup existem
      if (!sellerSnap.exists) {
        throw new HttpsError("not-found", "Vendedor não encontrado.");
      }

      if (!buyerSnap.exists) {
        throw new HttpsError("not-found", "Comprador não encontrado.");
      }

      if (!offerSnap.exists) {
        throw new HttpsError("not-found", "Oferta não encontrada.");
      }

      if (!startupSnap.exists) {
        throw new HttpsError("not-found", "Startup não encontrada.");
      }

      // pega os dados de forma definitiva da oferta e da startup
      const freshOffer = offerSnap.data() as Offer;
      const freshStartup = startupSnap.data() as StartupDocument; // Para revalorização

      if (!freshOffer) {
        throw new HttpsError("not-found", "Oferta inválida.");
      }

      // se a oferta não estiver aberta, quer dizer que já foi processada antes
      if (freshOffer.status !== "OPEN") {
        throw new HttpsError("failed-precondition", "Oferta já processada.");
      }

      // se a quantidade d etokens solicitada é maior do que a disponivel, lança erro
      if (qtdTokens > freshOffer.qtdTokens) {
        throw new HttpsError(
          "failed-precondition",
          "A quantidade solicitada é maior do que a disponível na oferta.",
        );
      }

      // Quanto o usuario vai pagar
      const purchaseTotalCents = qtdTokens * freshOffer.tokenPriceCents;

      // pega os dados do comprador e do vendedor
      const sellerData = sellerSnap.data();
      const buyerData = buyerSnap.data();

      // pega as carteiras de ambos e caso não tenha, é preenchido com []
      const sellerWallet: Wallet = sellerData?.wallet;
      const buyerWallet: Wallet = buyerData?.wallet;

      sellerWallet.positions ??= [];
      buyerWallet.positions ??= [];

      // verificações de saldo, posição, tokens, etc.
      if (buyerWallet.balanceInCents < purchaseTotalCents) {
        throw new HttpsError("failed-precondition", "Saldo insuficiente.");
      }

      const sellerPosition = sellerWallet.positions.find(
        (p: WalletTokenPositionDTO) => p.startupId === offer.startupId,
      );

      if (!sellerPosition) {
        throw new HttpsError("failed-precondition", "Vendedor sem posição.");
      }

      if (sellerPosition.qtdTokens < qtdTokens) {
        throw new HttpsError(
          "failed-precondition",
          "Tokens totais insuficientes.",
        );
      }

      if (sellerPosition.lockedTokens < qtdTokens) {
        throw new HttpsError(
          "failed-precondition",
          "Tokens bloqueados insuficientes.",
        );
      }

      // calculos para saber novos tokens, quanto investiu, quanto ta o preço atual, etc
      sellerPosition.qtdTokens =
        (Number(sellerPosition.qtdTokens) || 0) - qtdTokens;

      sellerPosition.lockedTokens =
        (Number(sellerPosition.lockedTokens) || 0) - qtdTokens;

      const sellerAvgPrice = Number(sellerPosition.averagePriceCents) || 0;
      const sellerCurrentPrice =
        Number(sellerPosition.currentTokenPriceCents) || 0;

      sellerPosition.investedCents = Math.round(
        sellerPosition.qtdTokens * sellerAvgPrice,
      );

      sellerPosition.currentValueCents = Math.round(
        sellerPosition.qtdTokens * sellerCurrentPrice,
      );

      sellerPosition.updatedAt = now;

      // pega as posições que tem quantidade de tokens > 0
      sellerWallet.positions = sellerWallet.positions.filter(
        (p: WalletTokenPositionDTO) => (Number(p.qtdTokens) || 0) > 0,
      );

      // pega o saldo do vendedor e adiciona com o valor da compra feita
      sellerWallet.balanceInCents =
        (Number(sellerWallet.balanceInCents) || 0) + purchaseTotalCents;

      // para cada posição, soma de forma acumulativa os tokens investidos naquela posição
      sellerWallet.totalInvestedCents = sellerWallet.positions.reduce(
        (acc: number, p: WalletTokenPositionDTO) =>
          acc + (Number(p.investedCents) || 0),
        0,
      );

      sellerWallet.updatedAt = now;

      // Faz quase as mesmas verificações para o comprador
      // pega a posição do comprador caso exista
      const existingBuyerPosition = buyerWallet.positions.find(
        (p: WalletTokenPositionDTO) => p.startupId === offer.startupId,
      );

      // se existir, atualiza quantidade de tokens daquela startup, quanto ele investiu, quanto ele tem investido, etc
      if (existingBuyerPosition) {
        const currentBuyerQtd = Number(existingBuyerPosition.qtdTokens) || 0;
        const currentBuyerInvested =
          Number(existingBuyerPosition.investedCents) || 0;
        const currentBuyerPrice =
          Number(existingBuyerPosition.currentTokenPriceCents) ||
          offer.tokenPriceCents;

        const newQtdTokens = currentBuyerQtd + qtdTokens;
        const newInvestedCents = currentBuyerInvested + purchaseTotalCents;

        // atualiza a posição para a nova quantidade de tokens
        existingBuyerPosition.qtdTokens = newQtdTokens;
        // atualiza a posição para guardar a nova quantidade investida
        existingBuyerPosition.investedCents = newInvestedCents;
        // atualiza a posição calculando a nova média baseado na nova quantidade de tokens
        existingBuyerPosition.averagePriceCents =
          newQtdTokens > 0 ? Math.round(newInvestedCents / newQtdTokens) : 0;
        // atualiza valor unitario atual daquele token
        existingBuyerPosition.currentTokenPriceCents = currentBuyerPrice;
        // pega o total (qtd_tokens * valor_atual_token)
        existingBuyerPosition.currentValueCents = Math.round(
          newQtdTokens * currentBuyerPrice,
        );
        existingBuyerPosition.updatedAt = now;

        // caso não tenha posição, só adiciona nas posições dele aquela startup com as informações da oferta
      } else {
        const currentValueCents = qtdTokens * offer.tokenPriceCents;
        buyerWallet.positions.push({
          startupId: offer.startupId,
          startupName: offer.startupName,
          qtdTokens: qtdTokens,
          lockedTokens: 0,
          averagePriceCents: offer.tokenPriceCents,
          investedCents: purchaseTotalCents,
          currentTokenPriceCents: offer.tokenPriceCents,
          currentValueCents,
          updatedAt: now,
        });
      }

      // diminui o saldo do comprador
      buyerWallet.balanceInCents =
        (Number(buyerWallet.balanceInCents) || 0) - purchaseTotalCents;

      // adiciona ao total investido o valor em centavos que ele pagou naquela posição
      buyerWallet.totalInvestedCents = buyerWallet.positions.reduce(
        (acc: number, p: WalletTokenPositionDTO) =>
          acc + (Number(p.investedCents) || 0),
        0,
      );

      buyerWallet.updatedAt = now;

      // insere como investidor caso ele ainda não seja
      await upsertStartupInvestor(
        tx,
        {
          startupId: offer.startupId,
          startupName: offer.startupName,
          userId: buyerId,
          userName: buyerUser.name,
          qtdTokens: qtdTokens,
          tokenPriceCents: offer.tokenPriceCents,
        },
        investorSnap,
      );

      // registra uma transação
      const transactionRef =
        await this.transactionService.registerTransactionTx(tx, {
          startupId: offer.startupId,
          startupName: offer.startupName,
          buyer: {
            id: buyerId,
            name: buyerUser.name,
            type: "USER",
          },
          seller: {
            id: sellerId,
            name: offer.seller.name,
            type: "USER",
          },
          qtdTokens: qtdTokens,
          tokenPriceCents: offer.tokenPriceCents,
        });
      // atualiza a carteira dos envolvidos
      tx.update(sellerRef, {
        wallet: sellerWallet,
      });

      tx.update(buyerRef, {
        wallet: buyerWallet,
      });

      // se a quantidade de tokens solicitada for igual aos tokens restantes, muda o status para "aceito" (finalizada lá no frontend) e zera os valores
      const isFullAcceptance = qtdTokens === freshOffer.qtdTokens;

      if (isFullAcceptance) {
        tx.update(offerRef, {
          status: "ACCEPTED",
          qtdTokens: 0,
          totalCents: 0,
          acceptedAt: now,
          buyer: {
            id: buyerId,
            name: buyerUser.name,
          },
        });
        // caso ainda reste algum token, apenas atualiza as informações da oferta
      } else {
        tx.update(offerRef, {
          qtdTokens: freshOffer.qtdTokens - qtdTokens,
          totalCents:
            (freshOffer.qtdTokens - qtdTokens) * freshOffer.tokenPriceCents,
        });
      }

      // reprecifica o token daquela startup
      await this.tokenPricingService.revalueFromSecondaryTradeTx(
        tx,
        offer.startupId,
        qtdTokens,
        offer.tokenPriceCents,
        freshStartup,
      );

      return {
        transactionId: transactionRef.id,
        remainingTokens: freshOffer.qtdTokens - qtdTokens,
      };
    });
  }

  // Autor: Allan
  // Método para expirar uma oferta (verificada cada vez que alguém toca em 'comprar' lá no celular)
  async expireOffer(offerId: string): Promise<ExpireOfferResponseDTO> {
    // verificações da requisição
    const normalizedOfferId = normalizeString(offerId);
    const expirationDate = Timestamp.now();

    if (!normalizedOfferId) {
      throw new HttpsError(
        "invalid-argument",
        "offerId deve estar presente no corpo da requisição.",
      );
    }

    // pega a oferta
    const offer = await getOfferById(normalizedOfferId);
    if (!offer) throw new HttpsError("not-found", "Oferta não encontrada.");

    // pega quando a oferta expira se houver
    const expiresAt = offer.expiresAt?.toMillis();

    // caso não tenha data de expiração, retorna falso
    if (!expiresAt) {
      return {
        offerId: normalizedOfferId,
        expired: false,
      };
    }

    // verifica se agora é depois da data de expiração da oferta
    const isExpired = expiresAt < expirationDate.toMillis();
    // se não estiver expirado, retorna falso
    if (!isExpired) {
      return {
        offerId: normalizedOfferId,
        expired: false,
      };
    }

    // caso esteja expirada, muda o status para "EXPIRED" atraves de uma função que manipula o banco
    const success = await expireOfferInTransaction(normalizedOfferId);

    // no final, retorna sucesso
    return {
      offerId: normalizedOfferId,
      expired: success,
    };
  }

  // Autor: Allan
  // Método para pegar as ofertas do usuário
  async getMyOffers(userId: string): Promise<GetMyOffersResponseDTO> {
    // pega as ofertas daquele usuario quando ele é vendedor
    const offers = await getOffersBySellerId(userId);

    // mapeia as ofertas com alguns dados adicionais (quanto ainda resta, quanto vendido e quanto ganhou)
    const mappedOffers: MyOfferDTO[] = offers.map((offer) => {
      const initialQtd = offer.initialQtdTokens;
      const remainingQtd = offer.qtdTokens;
      const soldQtd = initialQtd - remainingQtd;
      const totalEarned = soldQtd * offer.tokenPriceCents;

      return {
        id: offer.id,
        startupId: offer.startupId,
        startupName: offer.startupName,
        status: offer.status,
        initialQtdTokens: initialQtd ?? offer.qtdTokens,
        remainingQtdTokens: remainingQtd,
        soldQtdTokens: soldQtd,
        tokenPriceCents: offer.tokenPriceCents,
        totalEarnedCents: totalEarned,
        createdAt: offer.createdAt.toDate().toISOString(),
        expiresAt: offer.expiresAt?.toDate().toISOString() || null,
      };
    });

    return {
      offers: mappedOffers,
    };
  }

  // Pega todas as ofertas usando a técnica de "inifity loading"
  async getOffers(
    data: GetOffersRequestDTO,
  ): Promise<PaginatedOffersResponseDTO> {
    const { limit } = data;
    const startupId = normalizeString(data.startupId);
    const lastOfferId = normalizeString(data.lastOfferId);

    return listOffers(startupId, limit, lastOfferId);
  }
}

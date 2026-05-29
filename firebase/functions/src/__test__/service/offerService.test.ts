// Autor: Murilo Rigoni - 25006049
import { OfferService } from "../../exchange/shared/offerService";
import { HttpsError } from "firebase-functions/v2/https";
import { db } from "../../shared/firebase";
import {
  getOfferById,
  getOffersBySellerId,
  createOfferInTransaction,
  expireOfferInTransaction,
} from "../../exchange/repositories/offerRepository";
import { upsertStartupInvestor } from "../../startups/shared/upsertInvestor";
import { validateTransactionData } from "../../exchange/utils";

// 2. Acoplamento de dublês com mapeamento de caminhos correto
jest.mock("../../shared/firebase", () => {
  const mockDoc = (id: string): any => ({
    id,
    path: `mock/${id}`,
    collection: jest.fn(() => mockCollection()),
  });
  const mockCollection = (): any => ({
    doc: jest.fn((id) => mockDoc(id)),
  });
  return {
    db: {
      runTransaction: jest.fn(),
      collection: jest.fn(() => mockCollection()),
    },
  };
});

jest.mock("../../exchange/repositories/offerRepository");
jest.mock("../../startups/shared/upsertInvestor");
jest.mock("../../exchange/utils");

// Mocks de classes para evitar problemas com instanciações fora ou dentro do escopo da classe
jest.mock("../../user/shared/userService");
jest.mock("../../exchange/shared/transactionService");
jest.mock("../../shared/tokenPricingService");

import { UserService } from "../../user/shared/userService";
import { TransactionService } from "../../exchange/shared/transactionService";
import { TokenPricingService } from "../../shared/tokenPricingService";

describe("OfferService - Testes Unitários do Backend", () => {
  let offerService: OfferService;
  let mockTx: any;

  beforeEach(() => {
    jest.clearAllMocks();
    offerService = new OfferService();

    mockTx = {
      get: jest.fn(),
      update: jest.fn(),
      set: jest.fn(),
    };

    // força a execução imediata da função de transação do firestore
    (db.runTransaction as jest.Mock).mockImplementation((callback) =>
      callback(mockTx),
    );

    // Configuração padrão dos mocks de protótipo
    (UserService.prototype.get as jest.Mock).mockResolvedValue({
      name: "Roberto Comprador",
      wallet: { balanceInCents: 10000, positions: [] },
    });
    (
      TransactionService.prototype.registerTransactionTx as jest.Mock
    ).mockResolvedValue({ id: "tx_roberto_sec" });
    (
      TokenPricingService.prototype.revalueFromSecondaryTradeTx as jest.Mock
    ).mockResolvedValue({});
  });

  // teste do método createOffer com dados insuficientes
  test("createOffer - deve lancar httpserror invalid-argument se os dados essenciais do roberto nao forem enviados", async () => {
    const invalidData: any = {
      startupId: "",
      qtdTokens: 50,
      tokenPriceCents: 0,
    };

    await expect(
      offerService.createOffer("user_roberto_123", invalidData),
    ).rejects.toThrow(
      new HttpsError(
        "invalid-argument",
        "Dados insuficientes (startupId, qtdTokens, tokenPriceCents).",
      ),
    );
  });

  // teste do método createOffer com preço fora da banda permitida
  test("createOffer - deve rejeitar a oferta se o preco configurado pelo roberto ultrapassar o limite de mercado", async () => {
    const validData = {
      startupId: "startup_quantum_99",
      qtdTokens: 10,
      tokenPriceCents: 2000,
    };

    const mockValidationResult = {
      sellerUser: { name: "Roberto", wallet: { positions: [] } },
      startup: { name: "Quantum", currentTokenPriceCents: 1000 },
    };

    (validateTransactionData as jest.Mock).mockResolvedValue(
      mockValidationResult,
    );

    await expect(
      offerService.createOffer("user_roberto_123", validData),
    ).rejects.toThrow(
      new HttpsError(
        "invalid-argument",
        "Preço fora da banda permitida de mercado.",
      ),
    );
  });

  // teste de sucesso para a criação de uma nova oferta do roberto
  test("createOffer - deve gerar os registros de intencao de venda no mercado secundario com sucesso", async () => {
    const validData = {
      startupId: "startup_quantum_99",
      qtdTokens: 100,
      tokenPriceCents: 1000,
      expiresAt: "2026-12-31T23:59:59.000Z",
    };

    const mockValidationResult = {
      sellerUser: {
        name: "Roberto",
        wallet: {
          positions: [
            { startupId: "startup_quantum_99", averagePriceCents: 800 },
          ],
        },
      },
      startup: { name: "Quantum", currentTokenPriceCents: 1000 },
    };

    const mockCreatedOffer = {
      id: "offer_roberto_abc",
      startupId: "startup_quantum_99",
      startupName: "Quantum",
      seller: { id: "user_roberto_123", name: "Roberto", type: "USER" },
      qtdTokens: 100,
      tokenPriceCents: 1000,
      status: "OPEN",
    };

    (validateTransactionData as jest.Mock).mockResolvedValue(
      mockValidationResult,
    );
    (createOfferInTransaction as jest.Mock).mockResolvedValue(
      "offer_roberto_abc",
    );
    (getOfferById as jest.Mock).mockResolvedValue(mockCreatedOffer);

    const result = await offerService.createOffer(
      "user_roberto_123",
      validData,
    );

    expect(createOfferInTransaction).toHaveBeenCalled();
    expect(result).toEqual(mockCreatedOffer);
  });

  // teste do método cancelOffer para validar restrições de permissão
  test("cancelOffer - deve barrar a solicitacao se o solicitante nao for o roberto proprietario da oferta", async () => {
    const mockOfferData = {
      id: "offer_roberto_abc",
      seller: { id: "user_roberto_123" },
      status: "OPEN",
    };

    (getOfferById as jest.Mock).mockResolvedValue(mockOfferData);

    await expect(
      offerService.cancelOffer("user_invasor_999", { id: "offer_roberto_abc" }),
    ).rejects.toThrow(
      new HttpsError(
        "permission-denied",
        "Apenas o vendedor pode cancelar a própria oferta.",
      ),
    );
  });

  // teste de fluxo principal do acceptOffer com transferência financeira
  test("acceptOffer - deve realizar o debito e credito de fundos atualizando as posicoes na carteira", async () => {
    const acceptRequest = {
      offerId: "offer_roberto_abc",
      qtdTokens: 50,
    };

    const mockOfferData = {
      startupId: "startup_quantum_99",
      startupName: "Quantum",
      tokenPriceCents: 100,
      qtdTokens: 100,
      status: "OPEN",
      seller: { id: "user_vendedor_roberto", name: "Roberto Vendedor" },
    };

    const mockBuyerUserData = { name: "Roberto Comprador" };

    (getOfferById as jest.Mock).mockResolvedValue(mockOfferData);
    (UserService.prototype.get as jest.Mock).mockResolvedValue(
      mockBuyerUserData,
    );

    // Mapeamento dinâmico baseado no ID do documento para evitar quebras de ordem paralela (Promise.all)
    mockTx.get.mockImplementation(async (ref: any) => {
      if (ref.path.includes("user_vendedor_roberto")) {
        return {
          exists: true,
          data: () => ({
            wallet: {
              positions: [
                {
                  startupId: "startup_quantum_99",
                  qtdTokens: 100,
                  lockedTokens: 100,
                  averagePriceCents: 800,
                },
              ],
              balanceInCents: 5000,
            },
          }),
        };
      }
      if (ref.path.includes("user_comprador_roberto")) {
        return {
          exists: true,
          data: () => ({
            wallet: {
              positions: [],
              balanceInCents: 10000,
            },
          }),
        };
      }
      if (ref.path.includes("offer_roberto_abc")) {
        return {
          exists: true,
          data: () => ({
            qtdTokens: 100,
            tokenPriceCents: 100,
            status: "OPEN",
          }),
        };
      }
      if (ref.path.includes("startup_quantum_99")) {
        return {
          exists: true,
          data: () => ({ currentTokenPriceCents: 100 }),
        };
      }
      return { exists: true }; // Fallback para subcoleções (Ex: investors)
    });

    const result = await offerService.buyTokens(
      "user_comprador_roberto",
      acceptRequest,
    );

    expect(mockTx.update).toHaveBeenCalled();
    expect(upsertStartupInvestor).toHaveBeenCalled();
    expect(result).toEqual({
      transactionId: "tx_roberto_sec",
      remainingTokens: 50,
    });
  });

  // teste do método expireOffer validando prazos expirados no servidor
  test("expireOffer - deve retornar status expirado verdadeiro se o timestamp ja passou da janela atual", async () => {
    const mockOfferData = {
      status: "OPEN",
      expiresAt: { toMillis: () => Date.now() - 100000 },
    };

    (getOfferById as jest.Mock).mockResolvedValue(mockOfferData);
    (expireOfferInTransaction as jest.Mock).mockResolvedValue(true);

    const result = await offerService.expireOffer("offer_roberto_abc");

    expect(result).toEqual({
      offerId: "offer_roberto_abc",
      expired: true,
    });
  });

  // teste do método getMyOffers consolidando cálculos de rendimento
  test("getMyOffers - deve computar o historico e somar os valores totais arrecadados pelo roberto", async () => {
    const mockOffersArray = [
      {
        id: "offer_roberto_01",
        startupId: "startup_quantum_99",
        startupName: "Quantum",
        status: "OPEN",
        initialQtdTokens: 200,
        qtdTokens: 150,
        tokenPriceCents: 10,
        createdAt: { toDate: () => new Date() },
        expiresAt: null,
      },
    ];

    (getOffersBySellerId as jest.Mock).mockResolvedValue(mockOffersArray);

    const result = await offerService.getMyOffers("user_roberto_123");

    expect(result.offers.length).toBe(1); // Corrigido a sintaxe do expect do Jest 🚀
    expect(result.offers[0].soldQtdTokens).toBe(50);
    expect(result.offers[0].totalEarnedCents).toBe(500);
  });
});

import { BuyFromStartupService } from "../../exchange/shared/buyFromStartupService";
import { db } from "../../shared/firebase";
import { getStartupById } from "../../startups/repositories/startupRepository";
import { upsertStartupInvestor } from "../../startups/shared/upsertInvestor";
import { HttpsError } from "firebase-functions/v2/https";
import { Timestamp } from "firebase-admin/firestore";


// Mock do Firebase/Firestore
const mockTransaction = {
  get: jest.fn(),
  update: jest.fn(),
  set: jest.fn(),
};

jest.mock("../../shared/firebase", () => ({
  db: {
    collection: jest.fn().mockReturnThis(),
    doc: jest.fn().mockReturnThis(),
    // Executa imediatamente a função interna simulando a transação atômica
    runTransaction: jest.fn((callback) => callback(mockTransaction)),
  },
}));

// Mock das classes e funções de serviços externos
jest.mock("../../startups/repositories/startupRepository");
jest.mock("../../startups/shared/upsertInvestor");

const mockRegisterTransactionTx = jest.fn().mockResolvedValue({ id: "tx_history_123" });
jest.mock("./transactionService", () => {
  return {
    TransactionService: jest.fn().mockImplementation(() => ({
      registerTransactionTx: mockRegisterTransactionTx,
    })),
  };
});

const mockUserGet = jest.fn();
jest.mock("../../user/shared/userService", () => {
  return {
    UserService: jest.fn().mockImplementation(() => ({
      get: mockUserGet,
    })),
  };
});

const mockRevalueFromPrimaryTradeTx = jest.fn().mockResolvedValue(undefined);
jest.mock("../../shared/tokenPricingService", () => {
  return {
    TokenPricingService: jest.fn().mockImplementation(() => ({
      revalueFromPrimaryTradeTx: mockRevalueFromPrimaryTradeTx,
    })),
  };
});

describe("BuyFromStartupService - Testes Unitários", () => {
  let service: BuyFromStartupService;
  const buyerId = "buyer_roberto";
  const startupId = "startup_investapp";

  beforeEach(() => {
    jest.clearAllMocks();
    service = new BuyFromStartupService();
  });

  // ------------------------------------------------------------------------
  // Validações de Payload Primárias
  describe("Validações de Payload", () => {
    test("Deve falhar se o data for nulo ou inválido", async () => {
      await expect(service.buyTokens(buyerId, null as any))
        .rejects.toThrow(new HttpsError("invalid-argument", "Dados da requisição inválidos."));
    });

    test("Deve falhar se startupId for inválido ou vazio", async () => {
      await expect(service.buyTokens(buyerId, { startupId: "", qtdTokens: 10 }))
        .rejects.toThrow(new HttpsError("invalid-argument", "startupId é obrigatório e deve ser uma string não vazia."));
    });

    test("Deve falhar se qtdTokens for menor ou igual a zero ou não for inteiro", async () => {
      await expect(service.buyTokens(buyerId, { startupId, qtdTokens: -5 }))
        .rejects.toThrow(new HttpsError("invalid-argument", "qtdTokens deve ser um inteiro maior que zero."));
      
      await expect(service.buyTokens(buyerId, { startupId, qtdTokens: 10.5 }))
        .rejects.toThrow(new HttpsError("invalid-argument", "qtdTokens deve ser um inteiro maior que zero."));
    });
  });

  // ------------------------------------------------------------------------
  // Validações de Negócio Pré-Transação (Fora do db.runTransaction)
  describe("Validações de Negócio Antecipadas", () => {
    test("Deve falhar se a Startup não for encontrada no repositório", async () => {
      (getStartupById as jest.Mock).mockResolvedValue(undefined);
      mockUserGet.mockResolvedValue({ wallet: { balanceInCents: 1000 } });

      await expect(service.buyTokens(buyerId, { startupId, qtdTokens: 10 }))
        .rejects.toThrow(new HttpsError("not-found", `Startup '${startupId}' não encontrada.`));
    });

    test("Deve falhar se a Startup não tiver preço por token definido ou menor/igual a zero", async () => {
      (getStartupById as jest.Mock).mockResolvedValue({ currentTokenPriceCents: 0, totalTokensIssued: 1000 });
      mockUserGet.mockResolvedValue({ wallet: { balanceInCents: 1000 } });

      await expect(service.buyTokens(buyerId, { startupId, qtdTokens: 10 }))
        .rejects.toThrow(new HttpsError("failed-precondition", "Startup sem preço de token definido. Compra indisponível."));
    });

    test("Deve falhar se a quantidade de tokens solicitada ultrapassar o disponível circulante", async () => {
      (getStartupById as jest.Mock).mockResolvedValue({
        currentTokenPriceCents: 100,
        totalTokensIssued: 100,
        circulatingTokens: 95, // Sobram apenas 5 tokens disponíveis
      });
      mockUserGet.mockResolvedValue({ wallet: { balanceInCents: 10000 } });

      await expect(service.buyTokens(buyerId, { startupId, qtdTokens: 10 }))
        .rejects.toThrow(new HttpsError("failed-precondition", "Tokens insuficientes. Disponível: 5, Solicitado: 10."));
    });

    test("Deve falhar se o saldo inicial do usuário for menor que o custo total antes de abrir a transação", async () => {
      (getStartupById as jest.Mock).mockResolvedValue({
        currentTokenPriceCents: 500, // R$ 5,00 por token
        totalTokensIssued: 1000,
        circulatingTokens: 0,
      });
      mockUserGet.mockResolvedValue({
        wallet: { balanceInCents: 4000 }, // Tem apenas R$ 40,00
      });

      // Compra custará 10 * 500 = 5000 cents (R$ 50,00)
      await expect(service.buyTokens(buyerId, { startupId, qtdTokens: 10 }))
        .rejects.toThrow(new HttpsError("failed-precondition", "Saldo insuficiente. Necessário: R$50.00, Disponível: R$40.00."));
    });
  });

  // ------------------------------------------------------------------------
  // Validações e Processamento Interno da Transação (Garantia Atômica)
  describe("Processamento Concorrente e Transacional", () => {
    let mockStartupData: any;
    let mockUserData: any;

    beforeEach(() => {
      mockStartupData = {
        name: "InvestApp Premium",
        currentTokenPriceCents: 200,
        totalTokensIssued: 10000,
        circulatingTokens: 100,
      };

      mockUserData = {
        name: "Roberto Carlos",
        wallet: {
          balanceInCents: 5000,
          positions: [],
        },
      };

      (getStartupById as jest.Mock).mockResolvedValue(mockStartupData);
      mockUserGet.mockResolvedValue(mockUserData);
    });

    test("Deve abortar se na re-leitura dentro da transação os tokens tiverem esgotado por concorrência", async () => {
      const buyerSnap = { exists: true, data: () => mockUserData };
      // Simula que outro comprador comprou quase tudo logo antes
      const startupSnapConcorrente = {
        exists: true,
        data: () => ({
          ...mockStartupData,
          circulatingTokens: 9995, // Apenas 5 livres agora
        }),
      };
      const investorSnap = { exists: false };

      mockTransaction.get
        .mockResolvedValueOnce(buyerSnap)
        .mockResolvedValueOnce(startupSnapConcorrente)
        .mockResolvedValueOnce(investorSnap);

      await expect(service.buyTokens(buyerId, { startupId, qtdTokens: 10 }))
        .rejects.toThrow(new HttpsError("aborted", "Tokens reservados por outro comprador. Disponível: 5. Tente novamente."));
    });

    test("Deve executar o fluxo feliz com push de nova posição na carteira e chamadas de escrita atômica", async () => {
      const buyerSnap = { exists: true, data: () => mockUserData };
      const startupSnap = { exists: true, data: () => mockStartupData };
      const investorSnap = { exists: false, data: () => null };

      mockTransaction.get
        .mockResolvedValueOnce(buyerSnap)
        .mockResolvedValueOnce(startupSnap)
        .mockResolvedValueOnce(investorSnap);

      const payload = { startupId, qtdTokens: 10 };
      const res = await service.buyTokens(buyerId, payload);

      // Asserts do retorno
      expect(res).toEqual({
        transactionId: "tx_history_123",
        qtdTokens: 10,
        tokenPriceCents: 200,
        totalCents: 2000,
        newBalanceCents: 3000, // 5000 - 2000
      });

      // Valida se o upsertStartupInvestor foi devidamente acionado passando o snapshot
      expect(upsertStartupInvestor).toHaveBeenCalledWith(
        mockTransaction,
        expect.objectContaining({
          startupId,
          userId: buyerId,
          qtdTokens: 10,
        }),
        investorSnap
      );

      // Verifica atualizações no Firestore
      expect(mockTransaction.update).toHaveBeenCalledWith(
        expect.any(Object), // startupRef
        expect.objectContaining({ circulatingTokens: 110 })
      );

      // Verifica se invocou o cálculo de revalorização ao final do trade primário
      expect(mockRevalueFromPrimaryTradeTx).toHaveBeenCalledWith(
        mockTransaction,
        startupId,
        10,
        mockStartupData
      );
    });

    test("Deve recalcular preço médio corretamente se já possuir posição prévia daquela startup", async () => {
      // Modifica usuário para já ter uma posição de 10 tokens comprados a 100 cents (total 1000)
      mockUserData.wallet.positions = [
        {
          startupId,
          qtdTokens: 10,
          investedCents: 1000,
          averagePriceCents: 100,
        }
      ];

      const buyerSnap = { exists: true, data: () => mockUserData };
      const startupSnap = { exists: true, data: () => mockStartupData }; // preço atual é 200 cents
      const investorSnap = { exists: true, data: () => ({}) };

      mockTransaction.get
        .mockResolvedValueOnce(buyerSnap)
        .mockResolvedValueOnce(startupSnap)
        .mockResolvedValueOnce(investorSnap);

      // Nova compra: 10 tokens * 200 cents = 2000 cents
      // Total consolidado: 20 tokens, Investimento Total: 3000 cents. Preço médio: 3000/20 = 150 cents
      await service.buyTokens(buyerId, { startupId, qtdTokens: 10 });

      expect(mockTransaction.update).toHaveBeenCalledWith(
        expect.any(Object), // buyerRef
        expect.objectContaining({
          wallet: expect.objectContaining({
            balanceInCents: 3000,
            totalInvestedCents: 3000,
            positions: expect.arrayContaining([
              expect.objectContaining({
                qtdTokens: 20,
                investedCents: 3000,
                averagePriceCents: 150,
              })
            ]),
          })
        })
      );
    });
  });
});
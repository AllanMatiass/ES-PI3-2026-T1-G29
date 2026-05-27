import { TransactionService } from "../../exchange/shared/transactionService"
import { HttpsError } from "firebase-functions/v2/https";
import * as transactionRepository from "../../exchange/repositories/transactionRepository";
import { getStartupById } from "../../startups/repositories/startupRepository";
import { validateTransactionData } from "../../exchange/utils";
import { db } from "../../shared/firebase";

// realizando o acoplamento de dubles globais nos modulos externos e repositorios
jest.mock("../repositories/transactionRepository");
jest.mock("../../startups/repositories/startupRepository");
jest.mock("../utils");
jest.mock("../../shared/firebase", () => ({
  db: {
    collection: jest.fn(() => ({
      doc: jest.fn(() => ({
        id: "mock_tx_doc_id",
      })),
    })),
  },
}));

describe("TransactionService - Testes Unitários do Backend", () => {
  let transactionService: TransactionService;
  let mockTx: any;

  beforeEach(() => {
    jest.clearAllMocks();
    transactionService = new TransactionService();
    mockTx = {
      set: jest.fn(),
    };
  });

  // teste do metodo registertransaction com campos obrigatorios ausentes
  test("registerTransaction - deve lancar httpserror invalid-argument se faltarem dados essenciais do roberto", async () => {
    const invalidData: any = {
      startupId: "   ", // string vazia apos normalizacao
      buyer: { id: "user_roberto_123", name: "Roberto" },
      qtdTokens: 10,
      tokenPriceCents: 100,
    };

    await expect(transactionService.registerTransaction(invalidData)).rejects.toThrow(
      new HttpsError("invalid-argument", "Missing required transaction fields"),
    );
  });

  // teste de seguranca impedindo operacoes com comprador e vendedor identicos
  test("registerTransaction - deve bloquear o registro se o roberto tentar comprar de si mesmo", async () => {
    const tradeData = {
      startupId: "startup_quantum_123",
      buyer: { id: "user_roberto_123", name: "Roberto" },
      seller: { id: "user_roberto_123", name: "Roberto" },
      qtdTokens: 50,
      tokenPriceCents: 200,
    };

    (validateTransactionData as jest.Mock).mockResolvedValue({
      startup: { name: "Quantum Code" },
    });

    await expect(transactionService.registerTransaction(tradeData)).rejects.toThrow(
      new HttpsError("invalid-argument", "Comprador e vendedor não podem ser iguais."),
    );
  });

  // teste de sucesso para compra direta de tokens emitida por uma startup
  test("registerTransaction - deve registrar transacao do tipo buy_from_startup se nao houver vendedor secundario", async () => {
    const primaryPurchaseData = {
      startupId: "startup_quantum_123",
      buyer: { id: "user_roberto_123", name: "Roberto" },
      qtdTokens: 100,
      tokenPriceCents: 500,
    };

    (validateTransactionData as jest.Mock).mockResolvedValue({
      startup: { name: "Quantum Code" },
    });
    (transactionRepository.createTransaction as jest.Mock).mockResolvedValue("id_transacao_primaria");

    const result = await transactionService.registerTransaction(primaryPurchaseData);

    expect(transactionRepository.createTransaction).toHaveBeenCalledWith(
      expect.objectContaining({
        transactionType: "BUY_FROM_STARTUP",
        seller: expect.objectContaining({
          type: "STARTUP",
        }),
        totalCents: 50000,
      }),
    );
    expect(result).toBe("id_transacao_primaria");
  });

  // teste do buscador por id da startup validando limites numericos invalidos
  test("getStartupTransactions - deve rejeitar a busca se o limite fornecido pelo roberto quebrar a regra de negocios", async () => {
    await expect(transactionService.getStartupTransactions("startup_id", 0)).rejects.toThrow(
      new HttpsError("invalid-argument", "Limit deve ser entre 1 e 50."),
    );

    await expect(transactionService.getStartupTransactions("startup_id", 51)).rejects.toThrow(
      new HttpsError("invalid-argument", "Limit deve ser entre 1 e 50."),
    );
  });

  // teste de erro caso a busca ocorra para uma startup inexistente
  test("getStartupTransactions - deve falhar se o documento da startup informada nao constar no repositorio", async () => {
    (getStartupById as jest.Mock).mockResolvedValue(null);

    await expect(transactionService.getStartupTransactions("startup_fantasma", 20)).rejects.toThrow(
      new HttpsError("not-found", "Startup não encontrada."),
    );
  });

  // teste de listagem paginada para o historico do roberto
  test("getUserTransactions - deve normalizar o limite e encaminhar a busca para o repositorio", async () => {
    const requestData = { limit: 99, lastTransactionId: "tx_anterior" }; // limite invalido que deve ser normalizado para o default de 20
    const mockRepoResponse = { transactions: [], lastTransactionId: null };

    (transactionRepository.listTransactionsByUserId as jest.Mock).mockResolvedValue(mockRepoResponse);

    const result = await transactionService.getUserTransactions("user_roberto_123", requestData);

    expect(transactionRepository.listTransactionsByUserId).toHaveBeenCalledWith(
      "user_roberto_123",
      20, // confirma que o limite de 99 estourado caiu na seguranca e virou 20
      "tx_anterior",
    );
    expect(result).toEqual(mockRepoResponse);
  });

  // teste do metodo injetado em lote transacional
  test("registerTransactionTx - deve anexar os dados da transacao ao lote set do firestore usando o timestamp local", async () => {
    const txData = {
      startupId: "startup_quantum_123",
      startupName: "Quantum Code",
      buyer: { id: "user_roberto_123", name: "Roberto" },
      qtdTokens: 10,
      tokenPriceCents: 150,
    };

    const result = await transactionService.registerTransactionTx(mockTx, txData);

    expect(mockTx.set).toHaveBeenCalledWith(
      expect.anything(),
      expect.objectContaining({
        startupName: "Quantum Code",
        buyer: expect.objectContaining({ name: "Roberto" }),
        transactionType: "BUY_FROM_STARTUP",
        totalCents: 1500,
        createdAt: expect.any(Date),
      }),
    );
    expect(result.id).toBe("mock_tx_doc_id");
  });
});
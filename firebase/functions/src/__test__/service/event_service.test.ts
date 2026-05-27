// Autor: Murilo Rigoni - 25006049
import { EventService } from "../../events/shared/eventService";
import { HttpsError } from "firebase-functions/https";
import { db } from "../../firebase";
import { createEventTx } from "../../events/repositories/eventRepository";
import { startupsCollection } from "../../startups/repositories/startupRepository";
import { TokenPricingService } from "../../shared/tokenPricingService";

// realizando o mock das dependencias de infraestrutura e repositório
jest.mock("../../firebase", () => ({
  db: {
    runTransaction: jest.fn(),
  },
}));

jest.mock("../../events/repositories/eventRepository", () => ({
  createEventTx: jest.fn(),
}));

jest.mock("../../startups/repositories/startupRepository", () => ({
  startupsCollection: {
    doc: jest.fn(),
  },
}));

jest.mock("../../shared/tokenPricingService");

describe("EventService - Testes Unitários do Backend", () => {
  let eventService: EventService;
  let mockTx: any;
  let mockStartupRef: any;
  let mockStartupSnap: any;

  beforeEach(() => {
    jest.clearAllMocks();
    eventService = new EventService();

    // configurando os objetos falsos de transacao do firestore admin
    mockTx = {
      get: jest.fn(),
    };

    mockStartupRef = {
      id: "startup_roberto_123",
    };

    mockStartupSnap = {
      exists: true,
      data: jest.fn(() => ({
        id: "startup_roberto_123",
        name: "Startup do Roberto",
        currentTokenPriceCents: 1000,
        totalTokensIssued: 50000,
      })),
    };

    // mock transação a executar nossa lógica callback imediatamente
    (db.runTransaction as jest.Mock).mockImplementation((callback) =>
      callback(mockTx),
    );
    (startupsCollection.doc as jest.Mock).mockReturnValue(mockStartupRef);
  });

  // ------------------------------------------------------------------------
  // teste de validacao de parametros obrigatorios (guard clause)
  test("add - deve lancar httpserror failed-precondition se dados estruturais do roberto vierem incompletos", async () => {
    const invalidRequest: any = {
      title: "lançamento do app do roberto",
      summary: "", // campo obrigatorio vazio
      delta: 0.5,
      startupId: "startup_roberto_123",
      content: "conteudo completo",
    };

    // act & assert
    // valida se o backend intercepta o payload invalido antes de abrir conexoes
    await expect(eventService.add(invalidRequest)).rejects.toThrow(
      new HttpsError(
        "failed-precondition",
        "Verifique se: `title`, `summary`, `delta`, `startupId` e `content` estão sendo enviados corretamente na requisição ",
      ),
    );
  });

  // ------------------------------------------------------------------------
  //  teste de fluxo completo de sucesso
  test("add - deve normalizar textos, criar o evento e revalorizar o token com sucesso", async () => {
    const validRequest = {
      title: "   parceria tecnologica do roberto   ", // string com espaços para testar normalizeString
      summary: "roberto fecha acordo secundario de mercado",
      delta: 0.15,
      startupId: "startup_roberto_123",
      content: "detalhes sobre a nova integracao do ecossistema de tokens",
      tags: ["parceria", "expansao"],
    };

    const mockEventRepoResult = {
      id: "event_random_id_roberto",
      title: "parceria tecnologica do roberto", // resultado esperado apos normalizacao
      summary: "roberto fecha acordo secundario de mercado",
      delta: 0.15,
      startupId: "startup_roberto_123",
      content: "detalhes sobre a nova integracao do ecossistema de tokens",
      tags: ["parceria", "expansao"],
    };

    const mockPricingEngineResult = {
      previousPriceCents: 1000,
      newPriceCents: 1150, // novo preco calculado pelo motor de pricing
      previousValuationCents: 50000000,
      newValuationCents: 57500000,
    };

    // configurando stubs para responderem os dados mockados dentro da transacao
    mockTx.get.mockResolvedValue(mockStartupSnap);
    (createEventTx as jest.Mock).mockReturnValue(mockEventRepoResult);

    (
      TokenPricingService.prototype.revalueFromEventTx as jest.Mock
    ).mockResolvedValue(mockPricingEngineResult);

    // act
    const result = await eventService.add(validRequest);

    // assert
    // garante a integridade atomica de execucao do firestore transaction
    expect(db.runTransaction).toHaveBeenCalled();
    expect(startupsCollection.doc).toHaveBeenCalledWith("startup_roberto_123");
    expect(mockTx.get).toHaveBeenCalledWith(mockStartupRef);

    // garante que o repositorio recebeu a string ja normalizada
    expect(createEventTx).toHaveBeenCalledWith(
      mockTx,
      expect.objectContaining({ title: "parceria tecnologica do roberto" }),
    );

    // valida o repasse correto do snapshot data para o calculo matematico
    expect(
      TokenPricingService.prototype.revalueFromEventTx,
    ).toHaveBeenCalledWith(
      mockTx,
      "startup_roberto_123",
      0.15,
      expect.objectContaining({ name: "Startup do Roberto" }),
    );

    // valida a uniao correta das propriedades no EventResponseDTO final
    expect(result).toEqual({
      id: "event_random_id_roberto",
      title: "parceria tecnologica do roberto",
      summary: "roberto fecha acordo secundario de mercado",
      delta: 0.15,
      startupId: "startup_roberto_123",
      content: "detalhes sobre a nova integracao do ecossistema de tokens",
      tags: ["parceria", "expansao"],
      newTokenPrice: 1150,
    });
  });

  // ------------------------------------------------------------------------
  // teste de consistência e segurança (startup inexistente)
  test("add - deve interromper a execucao e lancar erro se a startup informada nao existir", async () => {
    const validRequest = {
      title: "evento fantasma",
      summary: "resumo generico",
      delta: -0.1,
      startupId: "startup_inexistente",
      content: "conteudo de teste",
    };

    // simulando que o snapshot retornou vazio no banco do firestore
    mockStartupSnap.exists = false;
    mockTx.get.mockResolvedValue(mockStartupSnap);

    // act & assert
    // garante que a transacao sofra rollback se a startup nao for validada
    await expect(eventService.add(validRequest)).rejects.toThrow(
      new HttpsError("not-found", "Startup não encontrada"),
    );

    // garante que o motor de precificacao e a criacao de evento nunca foram chamados
    expect(createEventTx).not.toHaveBeenCalled();
    expect(
      TokenPricingService.prototype.revalueFromEventTx,
    ).not.toHaveBeenCalled();
  });
});

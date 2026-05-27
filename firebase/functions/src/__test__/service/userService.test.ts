// Autor: Murilo Rigoni - 25006049
import { UserService } from "../../user/shared/userService";
import { HttpsError } from "firebase-functions/https";
import { getUserById } from "../../user/repositories/userRepository";
import { auth } from "../../shared/firebase";

// realizando o acoplamento de dubles globais nos modulos externos e repositorios
jest.mock("../../user/repositories/userRepository");
jest.mock("../../shared/firebase", () => ({
  auth: {
    deleteUser: jest.fn(),
  },
  db: {
    collection: jest.fn(() => ({
      doc: jest.fn(),
    })),
  },
}));

describe("UserService - Testes Unitários do Backend", () => {
  let userService: UserService;

  beforeEach(() => {
    jest.clearAllMocks();
    userService = new UserService();
  });

  // teste do fluxo de sucesso quando o usuario roberto e localizado
  test("get - deve retornar o perfil completo do usuario quando o documento constar no repositorio", async () => {
    const mockUserProfile = {
      uid: "user_roberto_123",
      name: "Roberto",
      email: "roberto@investapp.com",
      wallet: {
        balanceInCents: 50000,
        positions: [],
      },
    };

    (getUserById as jest.Mock).mockResolvedValue(mockUserProfile);

    const result = await userService.get("user_roberto_123");

    expect(getUserById).toHaveBeenCalledWith("user_roberto_123");
    expect(auth.deleteUser).not.toHaveBeenCalled();
    expect(result).toEqual(mockUserProfile);
  });

  // teste de seguranca e consistencia deletando a credencial do roberto caso o firestore falhe
  test("get - deve deletar o registro do auth e lancar erro se o perfil nao existir no firestore", async () => {
    (getUserById as jest.Mock).mockResolvedValue(null);
    (auth.deleteUser as jest.Mock).mockResolvedValue(undefined);

    // act & assert
    // valida se o backend dispara o gatilho corretivo de exclusao para manter a base integra
    await expect(userService.get("user_roberto_123")).rejects.toThrow(
      new HttpsError("not-found", "Usuário não encontrado"),
    );

    expect(getUserById).toHaveBeenCalledWith("user_roberto_123");
    expect(auth.deleteUser).toHaveBeenCalledWith("user_roberto_123");
  });
});

import * as admin from "firebase-admin";
import { getAuth } from "firebase-admin/auth";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { withCallHandler } from "../shared/middlewares/errorHandler";

admin.initializeApp();

async function enable() {
  try {
    await getAuth()
      .projectConfigManager()
      .updateProjectConfig({
        multiFactorConfig: {
          providerConfigs: [
            {
              state: "ENABLED",
              totpProviderConfig: {
                adjacentIntervals: 5,
              },
            },
          ],
          state: "ENABLED",
        },
      });

    return true;
  } catch (e) {
    throw new HttpsError("internal", "Erro ao ativar MFA: " + e);
  }
}

export const enableMfa = onCall(
  withCallHandler<void, void>(async (_) => {
    await enable();
  }),
);

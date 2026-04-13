// Autor: Allan Giovanni Matias Paes
import { logger } from "firebase-functions";
import { Startup, StartupResponseDTO } from "../models/startupModels";
import { startupsData } from "../utils/startups";
import * as admin from "firebase-admin";

// Serviço responsável por operações relacionadas a startups,
// como a criação de dados iniciais (seeding) e outras lógicas
// de negócio que envolvem startups.

export class StartupService {
  private startupsCollection: FirebaseFirestore.CollectionReference;

  constructor(startupsCollection: FirebaseFirestore.CollectionReference) {
    this.startupsCollection = startupsCollection;
  }

  async seedStartups() {
    for (let i = 1; i <= startupsData.length; i++) {
      const startup: Startup = startupsData[i - 1];

      await this.startupsCollection.doc(i.toString()).set({
        ...startup,
        createdAt: admin.firestore.Timestamp.now(),
        updatedAt: null,
      });
    }
  }

  async getAllStartups() {
    const snapshot = await this.startupsCollection.get();
    return snapshot.docs.map((doc) => {
      const data = doc.data();
      logger.info(`Fetched startup: ${data.name} (ID: ${doc.id})`);
      logger.info(`Startup data: ${JSON.stringify(data)}`);
      return { ...data, id: doc.id } as StartupResponseDTO;
    });
  }
}

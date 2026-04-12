import { Startup } from "../@types/startupTypes";
import { startupsData } from "../utils/startups";
import * as admin from "firebase-admin";

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
}

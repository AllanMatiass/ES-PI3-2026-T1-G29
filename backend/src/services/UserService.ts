// Autores: Allan Giovanni Matias Paes
import type { Firestore } from "firebase-admin/firestore";

export class UserService {
    private db: Firestore;

    constructor(db: Firestore) {
        this.db = db;
    }

    async getCurrentUser(userId: string){
        const user = await this.db.collection('users').doc(userId).get();
        return user.data();
    }
    
}
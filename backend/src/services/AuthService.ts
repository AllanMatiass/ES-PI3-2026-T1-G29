// Autores: Allan Giovanni Matias Paes
import type { Firestore } from "firebase-admin/firestore";
import admin from "../config/firebase.js";
import type { CreateUserDTO } from "../models/userSchema.js";

export class AuthService {
    private db: Firestore;

    constructor(db: Firestore){
        this.db = db;
    }
    

    async createUser(dto: CreateUserDTO) {

        const { email, password, name, cpf } = dto;

        
        const userRecord = await admin.auth().createUser({
            email,
            password,
            displayName: name
        });

        await this.db.collection("users").doc(userRecord.uid).set({
            name,
            email,
            cpf,
            walletBalance: 0,
            createdAt: new Date()
        });

        return {
            id: userRecord.uid,
            email,
            name,
            cpf
        };
    }
}
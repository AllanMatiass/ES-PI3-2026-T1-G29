import { type Request, type Response } from "express";
import { AuthService } from "../services/AuthService.js";
import { db } from "../config/firebase.js";

const authService = new AuthService(db);

export async function signupController(req: Request, res: Response) {
    const {email, password, name, cpf} = req.body;
    const user = await authService.createUser({email, password, name, cpf})
    return res.status(201).json({
        success: true,
        data: user
    });
}
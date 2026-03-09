// Autores: Allan Giovanni Matias Paes
import { Router } from "express";
import { db } from "../../config/firebase.js";
import { UserService } from "../../services/UserService.js";

const router = Router();

router.get('/', async (req, res) =>{
    const userService = new UserService(db);
    const user = await userService.getCurrentUser(req.uid!);
    return res.json({
        success: true,
        data: user
    });
})

export default router;

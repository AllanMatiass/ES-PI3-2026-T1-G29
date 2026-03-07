import { Router } from "express";
import { signupController } from "../../controllers/authController.js";

const router = Router();

router.post('/signup', async (req, res) => {
    await signupController(req, res);
});

export default router;
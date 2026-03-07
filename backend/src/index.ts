import express from 'express';
import cors from 'cors';
import {config} from 'dotenv';
import { firebaseTest } from './config/firebase.js';
import  authRoutes  from './routes/public/authRoutes.js';
import { errorHandler } from './middlewares/errorHandler.js';

config();
await firebaseTest();

const app = express();
const PORT = process.env.BACKEND_PORT;

app.use(express.json());
app.use(cors());

app.use('/auth', authRoutes);

app.use(errorHandler);

app.listen(PORT, () => {
    console.log('Server started');
});




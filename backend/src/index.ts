import express from 'express';
import cors from 'cors';
import {config} from 'dotenv';
import { firebaseTest } from './config/firebase.js';

config();
firebaseTest();

const app = express();
const PORT = process.env.BACKEND_PORT;

app.use(express.json());
app.use(cors());

app.listen(PORT, () => {
    console.log('Server started');
});




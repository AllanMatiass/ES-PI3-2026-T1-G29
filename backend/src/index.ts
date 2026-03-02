import express from 'express';
import cors from 'cors';
import {config} from 'dotenv';
config();

const app = express();
const PORT = process.env.FRONTEND_PORT;

app.use(express.json());
app.use(cors({
    origin: 'http://localhost:3000'
}));

app.listen(PORT, () => {
    console.log('Server started');
});




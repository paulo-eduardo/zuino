import express from "express";
import bodyParser from "body-parser";
import cors from "cors";
import dotenv from "dotenv";
dotenv.config();

import receiptRoutes from "./receipt/receipt.routes";

const app = express();
const port = process.env.PORT || 3000;

app.use(cors());
app.use(bodyParser.json());

app.use("/receipt", receiptRoutes);

app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});

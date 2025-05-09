import express from "express";
import bodyParser from "body-parser";
import cors from "cors";
import dotenv from "dotenv";
dotenv.config();

import receiptRoutes from "./receipt/receipt.routes.js";

const app = express();
const port = process.env.PORT || 3000;

app.use(cors());
app.use(bodyParser.json());

app.use((req, _res, next) => {
  console.log(
    `[ReceiptService] Request Received: ${req.method} ${req.originalUrl} from ${req.ip}`,
  );
  next();
});

app.get("/health", (_, res) => {
  res.status(200).send("OK");
});

app.use("/receipt", receiptRoutes);

// Initialize the database before starting the server
async function startServer() {
  try {
    app.listen(port, () => {
      console.log(`Server is running on port ${port}`);
    });
  } catch (error) {
    console.error("Failed to start server:", error);
  }
}

startServer();

import { Router } from "express";
import * as receiptController from "./receipt.controller.ts";

const router = Router();

router.post("/scan", receiptController.getReceiptItems);

export default router;

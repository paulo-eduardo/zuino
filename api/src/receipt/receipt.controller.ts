import { Request, Response } from "express";
import * as receiptService from "./receipt.service";

export async function getReceiptItems(req: Request, res: Response) {
  const { url } = req.body;
  console.log("Scanning receipt: ", url);
  if (!url) res.status(400).send({ message: "No url found" });

  const receiptItems = await receiptService.getReceiptItems(url);
  res.status(200).send(receiptItems);
  console.log("Items: ", receiptItems);
  return;
}

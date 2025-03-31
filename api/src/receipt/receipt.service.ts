import axios from "axios";
import * as cheerio from "cheerio";
import { ReceiptItem } from "./receipt.interfaces";

export async function getReceiptItems(url: string): Promise<ReceiptItem[]> {
  const response = await axios.get(url);
  const $ = cheerio.load(response.data);
  const store = $(".txtTopo").text();

  const receiptItemsMap: Record<string, ReceiptItem> = {};

  $("#tabResult tr").each((i, element) => {
    const row = $(element);
    const name = row.find(".txtTit2").text();
    const unit = row
      .find(".RUN")
      .text()
      .replace("UN:", "")
      .trim()
      .toLowerCase();
    const unitValueText = row
      .find(".RvlUnit")
      .text()
      .replace("Vl. Unit.:", "")
      .trim();
    const quantityText = row.find(".Rqtd").text().replace("Qtde.:", "").trim();
    const totalText = row.find(".valor").text().trim();

    const codigoMatch = row
      .find(".RCod")
      .text()
      .match(/Código: (\d+)/);
    const codigo = codigoMatch ? codigoMatch[1] : `unknown_${i}`;

    if (name) {
      const unitValue = parseFloat(unitValueText.replace(",", "."));
      const quantity = parseFloat(quantityText.replace(",", "."));
      const total = parseFloat(totalText.replace(",", "."));

      if (receiptItemsMap[codigo]) {
        const currentQuantity = receiptItemsMap[codigo].quantity;
        receiptItemsMap[codigo].quantity =
          Math.round((currentQuantity + quantity) * 1000) / 1000;
        receiptItemsMap[codigo].total += total;
      } else {
        receiptItemsMap[codigo] = {
          codigo,
          name,
          store,
          unit,
          unitValue,
          quantity,
          total,
        };
      }
    }
  });

  return Object.values(receiptItemsMap);
}

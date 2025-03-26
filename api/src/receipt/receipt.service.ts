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
    const unit = row.find(".RUN").text().replace("UN:", "").trim();
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
      const compositeKey = getCompositeKey(name, unitValueText);
      const unitValue = parseFloat(unitValueText.replace(",", "."));
      const quantity = parseFloat(quantityText.replace(",", "."));
      const total = parseFloat(totalText.replace(",", "."));

      if (receiptItemsMap[compositeKey]) {
        receiptItemsMap[compositeKey].quantity += quantity;
        receiptItemsMap[compositeKey].total += total;
      } else {
        receiptItemsMap[compositeKey] = {
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

function getCompositeKey(name: string, unitValue: string): string {
  const normalizedName = name.trim().toLowerCase().replace(/\s+/g, " ");

  const normalizeUnitValue = unitValue.replace(",", ".");
  return `${normalizedName}_${normalizeUnitValue}`;
}

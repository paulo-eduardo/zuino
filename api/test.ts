import axios from "axios";
import * as cheerio from "cheerio";
import { ReceiptItem } from "./receipt/receipt.interfaces";

console.log(
  "####################################################################################",
);

const response = await axios.get(
  "http://www.fazenda.pr.gov.br/nfce/qrcode?p=41250318813526000156650010002234451622619530|2|1|3|BCF38F561D79575CEB424509D7D3926FF61FD2C1",
);
const $ = cheerio.load(response.data);
console.log($(".txtTopo").text());

const receiptItemsMap: Record<string, ReceiptItem> = {};

$("#tabResult tr").each((i, element) => {
  const row = $(element);
  const name = row.find(".txtTit2").text();
  const unit = row.find(".RUN").text().replace("UN:", "").trim();
  const unitValue = row
    .find(".RvlUnit")
    .text()
    .replace("Vl. Unit.:", "")
    .trim();
  const quantityText = row.find(".Rqtd").text().replace("Qtde.:", "").trim();
  const totalText = row.find(".valor").text().trim();

  const codigoMatch = row
    .find(".RCod")
    .text()
    .match(/Codigo: (\d+)/);
  const codigo = codigoMatch ? codigoMatch[1] : `unknown_${i}`;

  if (name) {
    const quantity = parseFloat(quantityText.replace(",", "."));
    const total = parseFloat(totalText.replace(",", "."));

    if (receiptItemsMap[codigo]) {
      receiptItemsMap[codigo].quantity += quantity;
      receiptItemsMap[codigo].total += total;
    } else {
      receiptItemsMap[codigo] = {
        name,
        unit,
        unitValue,
        quantity,
        total,
      };
    }
  }
});

const groupedItems = Object.values(receiptItemsMap);

console.log(groupedItems);

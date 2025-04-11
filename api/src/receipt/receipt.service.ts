import axios from "axios";
import * as cheerio from "cheerio";
import { ReceiptItem, Receipt } from "./receipt.interfaces";
import { getCategoryForProduct } from "../db/category.db";

export async function getReceiptDetails(
  url: string,
): Promise<{ receipt: Receipt; items: ReceiptItem[] }> {
  const response = await axios.get(url);
  const $ = cheerio.load(response.data);

  // Extract receipt details

  const $headerBlock = $("#conteudo > .txtCenter");

  const storeName = $headerBlock.find("#u20").text().trim();
  let cnpj = "";
  let address = "";

  $headerBlock.find(".text").each((i, element) => {
    const elementText = $(element).text();

    if (elementText.includes("CNPJ:")) {
      cnpj = elementText.replace("CNPJ:", "").trim();
    } else {
      address = elementText.trim().replace(/\s+/g, " ");
    }
  });

  const $generalInfoLi = $("#infos > div[data-role='collapsible']")
    .first()
    .find("ul li")
    .first();

  const dateTimeStr =
    $generalInfoLi
      .text()
      .match(/Emissão:\s*(\d{2}\/\d{2}\/\d{4}\s+\d{2}:\d{2}:\d{2})/)![1]
      .trim() || "";

  const dateTime = dateTimeStr
    ? new Date(dateTimeStr.replace(/(\d{2})\/(\d{2})\/(\d{4})/, "$3-$2-$1"))
    : new Date();

  const number =
    $generalInfoLi
      .text()
      .match(/Número:\s*(\d+)/)![1]
      .trim() || "";
  const series =
    $generalInfoLi
      .text()
      .match(/Série:\s*(\d+)/)![1]
      .trim() || "";

  const totalAmount = parseFloat(
    $("#linhaTotal .totalNumb.txtMax").text().trim().replace(",", "."),
  );

  const paymentMethod = $("#linhaTotal .tx").text().trim();

  const receipt: Receipt = {
    id: url.split("chave=")[1],
    store: {
      name: storeName,
      cnpj: cnpj,
      address: address,
    },
    date: dateTime || new Date(),
    number: number,
    series: series,
    totalAmount: totalAmount,
    paymentMethod: paymentMethod,
    url: url,
  };

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
      const category = getCategoryForProduct(name);

      if (receiptItemsMap[codigo]) {
        const currentQuantity = receiptItemsMap[codigo].quantity;
        receiptItemsMap[codigo].quantity =
          Math.round((currentQuantity + quantity) * 1000) / 1000;
        receiptItemsMap[codigo].total += total;
      } else {
        receiptItemsMap[codigo] = {
          codigo,
          name,
          quantity,
          unit,
          unitValue,
          total,
          category,
        };
      }
    }
  });

  const items = Object.values(receiptItemsMap);

  return { receipt, items };
}

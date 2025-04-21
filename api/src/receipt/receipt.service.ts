import axios from "axios";
import * as cheerio from "cheerio";
import { ReceiptItem, Receipt, Store } from "./receipt.interfaces";
import { aiProductFormat } from "../services/ai.service";

export async function getReceiptDetails(
  url: string,
): Promise<{ receipt: Receipt; items: ReceiptItem[] }> {
  const response = await axios.get(url);
  const $ = cheerio.load(response.data);

  // Extract store information
  const store = extractStoreInfo($, $("#conteudo > .txtCenter"));

  // Extract receipt metadata
  const { date, number, series } = extractReceiptMetadata(
    $("#infos > div[data-role='collapsible']").first().find("ul li").first(),
  );

  // Extract payment information
  const { totalAmount, paymentMethod } = extractPaymentInfo($("#linhaTotal"));

  const receipt: Receipt = {
    id: url.split("chave=")[1],
    store,
    date: date,
    number,
    series,
    totalAmount,
    paymentMethod,
    url,
  };

  // Extract receipt items
  const items = extractReceiptItems($, $("#tabResult tr"));

  const aiFormatedProducts = await aiProductFormat(items);

  return { receipt, items: aiFormatedProducts };
}

function extractStoreInfo(
  $: cheerio.Root,
  $headerBlock: cheerio.Cheerio,
): Store {
  const name = $headerBlock.find("#u20").text().trim();
  let cnpj = "";
  let address = "";

  $headerBlock.find(".text").each((_, element) => {
    const elementText = $(element).text();

    if (elementText.includes("CNPJ:")) {
      cnpj = elementText.replace("CNPJ:", "").trim();
    } else {
      address = elementText.trim().replace(/\s+/g, " ");
    }
  });

  return { name, cnpj, address };
}

function extractReceiptMetadata($generalInfoLi: cheerio.Cheerio): {
  date: Date;
  number: string;
  series: string;
} {
  const dateTimeStr =
    $generalInfoLi
      .text()
      .match(/Emissão:\s*(\d{2}\/\d{2}\/\d{4}\s+\d{2}:\d{2}:\d{2})/)![1]
      .trim() || "";

  const date = dateTimeStr
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

  return { date, number, series };
}

function extractPaymentInfo($linhaTotal: cheerio.Cheerio): {
  totalAmount: number;
  paymentMethod: string;
} {
  const totalAmount = parseFloat(
    $linhaTotal.find(".totalNumb.txtMax").text().trim().replace(",", "."),
  );

  const paymentMethod = $linhaTotal.find(".tx").text().trim();

  return { totalAmount, paymentMethod };
}

function extractReceiptItems(
  $: cheerio.Root,
  $tableResult: cheerio.Cheerio,
): ReceiptItem[] {
  const receiptItemsMap: Record<string, ReceiptItem> = {};

  $tableResult.each((i, element) => {
    const row = $(element);

    // More precise selection for product name
    // Get only the text from the specific span with class txtTit or txtTit2
    const name =
      row.find("span.txtTit2").text() || row.find("span.txtTit").text();

    if (!name) return; // Skip rows without a product name

    const unit = row
      .find(".RUN")
      .text()
      .replace(/UN:|\s+/g, " ")
      .trim()
      .toLowerCase();

    const unitValueText = row
      .find(".RvlUnit")
      .text()
      .replace(/Vl\.\s*Unit\.:|Â|¿/g, "")
      .trim();

    const quantityText = row
      .find(".Rqtd")
      .text()
      .replace(/Qtde\.:|Â|¿/g, "")
      .trim();

    // Get the total value specifically from the span with class valor
    const totalText = row.find("span.valor").text().replace(/Â|¿/g, "").trim();

    // Handle different formats of code extraction
    let codigo = `unknown_${i}`;
    const codText = row.find(".RCod").text();

    // Try different regex patterns to extract the code
    const codigoMatch =
      codText.match(/Código:\s*(\d+)/) ||
      codText.match(/\(Código:\s*(\d+)/) ||
      codText.match(/\(Cód\w*:\s*(\d+)/);

    if (codigoMatch) {
      codigo = codigoMatch[1];
    }

    if (name) {
      // Clean and parse numeric values
      const cleanNumber = (text: string) =>
        parseFloat(
          text
            .replace(/\./g, "")
            .replace(/,/g, ".")
            .replace(/[^\d.-]/g, ""),
        );

      const unitValue = cleanNumber(unitValueText);
      const quantity = cleanNumber(quantityText);
      const total = cleanNumber(totalText);

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
        };
      }
    }
  });

  return Object.values(receiptItemsMap);
}

import { model } from "../config/gemini.config";
import { ReceiptItem } from "../receipt/receipt.interfaces";

interface AIResponse {
  codigo: string;
  original_name: string;
  category: string;
  standardized_name?: string;
}

export async function aiProductFormat(
  products: ReceiptItem[],
): Promise<ReceiptItem[]> {
  const produtsJsonString = JSON.stringify(
    products.map((item) => ({ codigo: item.codigo, name: item.name })),
  );
  const userPrompt = `Process the following products according to the established rules: json${produtsJsonString}`;

  try {
    const result = await model.generateContent(userPrompt);
    const processedData = JSON.parse(result.response.text());

    console.log(`�� Successfully processed ${processedData.length} products`);
    return processedData.map((aiResponse: AIResponse) =>
      convertAIResponseToReceiptItem(aiResponse, products),
    );
  } catch (error) {
    console.error("Error generating content:", error);
    throw error;
  }
}

function convertAIResponseToReceiptItem(
  aiResponse: AIResponse,
  originalItems: ReceiptItem[],
): ReceiptItem {
  const originalItem = originalItems.find(
    (item) => item.codigo === aiResponse.codigo,
  );
  if (!originalItem) {
    throw new Error(`No matching product found for code ${aiResponse.codigo}`);
  }

  return {
    ...originalItem,
    name: aiResponse.standardized_name || aiResponse.original_name,
    category: aiResponse.category,
  };
}

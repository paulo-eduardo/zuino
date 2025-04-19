import fs from "fs/promises";
import path from "path";
import axios from "axios";
import { performance } from "perf_hooks";
import dotenv from "dotenv";

// Load environment variables from .env file
dotenv.config();

// Get API key from environment variables
const GEMINI_API_KEY = process.env.GEMINI_API_KEY;

if (!GEMINI_API_KEY) {
  console.error("Error: GEMINI_API_KEY environment variable is not set.");
  console.error("Please create a .env file with your Gemini API key:");
  console.error("GEMINI_API_KEY=your_api_key_here");
  process.exit(1);
}

const GEMINI_CONFIGS = [
  {
    name: "gemini-2.0-flash",
    url: `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=${GEMINI_API_KEY}`,
    headers: { "Content-Type": "application/json" },
    payload: (prompt) => ({
      contents: [
        {
          parts: [{ text: prompt }],
        },
      ],
    }),
    extractResponse: (data) => {
      if (data.candidates && data.candidates[0] && data.candidates[0].content) {
        return data.candidates[0].content.parts[0].text;
      }
      return null;
    },
  },
  {
    name: "gemini-2.0-pro",
    url: `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-pro:generateContent?key=${GEMINI_API_KEY}`,
    headers: { "Content-Type": "application/json" },
    payload: (prompt) => ({
      contents: [
        {
          parts: [{ text: prompt }],
        },
      ],
    }),
    extractResponse: (data) => {
      if (data.candidates && data.candidates[0] && data.candidates[0].content) {
        return data.candidates[0].content.parts[0].text;
      }
      return null;
    },
  },
  {
    name: "gemini-2.5-flash",
    url: `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${GEMINI_API_KEY}`,
    headers: { "Content-Type": "application/json" },
    payload: (prompt) => ({
      contents: [
        {
          parts: [{ text: prompt }],
        },
      ],
    }),
    extractResponse: (data) => {
      if (data.candidates && data.candidates[0] && data.candidates[0].content) {
        return data.candidates[0].content.parts[0].text;
      }
      return null;
    },
  },
  {
    name: "gemini-2.5-pro",
    url: `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-pro:generateContent?key=${GEMINI_API_KEY}`,
    headers: { "Content-Type": "application/json" },
    payload: (prompt) => ({
      contents: [
        {
          parts: [{ text: prompt }],
        },
      ],
    }),
    extractResponse: (data) => {
      if (data.candidates && data.candidates[0] && data.candidates[0].content) {
        return data.candidates[0].content.parts[0].text;
      }
      return null;
    },
  },
];

// Category definitions with keywords
const CATEGORIES = [
  {
    name: "Essenciais",
    // Apenas exemplos chave! Não a lista completa.
    keywords: [
      "ARROZ",
      "FEIJAO",
      "MACARRAO",
      "OLEO",
      "ACUCAR",
      "SAL",
      "CAFE",
      "OVOS",
      "PAO",
      "LEITE",
      "IOGURTE",
      "QUEIJO",
      "MANTEIGA",
      "MARGARINA",
      "AGUA",
    ],
  },
  {
    name: "Hortifruti",
    keywords: [
      "ALFACE",
      "TOMATE",
      "CEBOLA",
      "BATATA",
      "CENOURA",
      "MACA",
      "BANANA",
      "LARANJA",
      "MELANCIA",
      "UVA",
    ],
  },
  {
    name: "Proteínas",
    keywords: [
      "FRANGO",
      "PEITO",
      "COXA",
      "BIFE",
      "CARNE",
      "MOIDA",
      "COSTELA",
      "LOMBO",
      "PEIXE",
      "ATUM",
      "SARDINHA",
      "PRESUNTO",
      "LINGUICA",
      "BACON",
    ],
  },
  {
    name: "Limpeza e Higiene",
    keywords: [
      "SABAO",
      "DETERGENTE",
      "DESINFETANTE",
      "SANITARIA",
      "ALVEJANTE",
      "AMACIANTE",
      "SHAMPOO",
      "CONDICIONADOR",
      "SABONETE",
      "PAPEL",
      "HIGIENICO",
      "FRALDA",
      "ABSORVENTE",
      "PASTA",
      "DENTAL",
      "ESCOVA",
    ],
  },
  {
    name: "Guloseimas",
    keywords: [
      "BISCOITO",
      "BOLACHA",
      "CHOCOLATE",
      "BOMBOM",
      "BALA",
      "CHICLETE",
      "SALGADINHO",
      "BOLO",
      "TORTA",
      "PUDIM",
      "GELATINA",
      "NESCAU",
      "TODDY",
      "DOCE",
    ],
  },
  {
    name: "Bazar",
    keywords: [
      "PILHA",
      "BATERIA",
      "LAMPADA",
      "VELA",
      "FOSFORO",
      "ISQUEIRO",
      "GUARDANAPO",
      "ALUMINIO",
      "FILME",
      "PLASTICO",
      "COPO",
      "DESCARTAVEL",
      "CARVAO",
      "INSETICIDA",
    ],
  },
  {
    name: "Bebidas",
    keywords: [
      "SUCO",
      "REFRESCO",
      "CHA",
      "MATE",
      "REFRIGERANTE",
      "GUARANA",
      "COLA",
      "CERVEJA",
      "VINHO",
      "VODKA",
      "ENERGETICO",
    ],
  },
];

const TEST_PRODUCTS = [
  // Lista 1
  { code: "4986", name: "ARROZ PARBOILIZADO DALFOVO 1kg TIPO 1" },
  { code: "5804", name: "CHOCOLATE BARRA MILKA 100G MORANGO E IOGURTE" },
  { code: "5827", name: "CHOCOLATE BARRA MILKA 100G CARAMELO" },
  { code: "6437", name: "LEITE LONGA VIDA UHT LEITISSIMO 1 L INTEGRAL PET" },
  { code: "11301", name: "KIT SHAMPOO ELSEVE 375ML+COND 170ML CACHO DO SONHO" },
  { code: "17028", name: "PAO LIEVITO FERM NATURAL 450G ITALIANO" },
  { code: "18764", name: "PAO FRANCES SUPERPAN kg TRADICIONAL" },
  { code: "27958", name: "SOBRECOXA DE FRANGO C/OSSO ASSADA PADARIA COOPER K" },
  { code: "34397", name: "MIX SALADA COOPER kg CASTANHA E LEMON PEPPER" },
  { code: "38680", name: "MELANCIA BABY VERMELHA CORTADA EMB FILME kg COOPER" },
  { code: "42976", name: "CHOCOLATE BARRA MILKA 100G NOISETTE" },
  { code: "43303", name: "BRIOCHE COOPER kg CRAQUELADO" },
  { code: "46629", name: "COLOMBA BAUDUCCO 400G CACAU" },
  { code: "2901984", name: "AMEIXA AGROLIFE 500G" },
  { code: "2902189", name: "PAO COOPER MANDIOQUINHA kg" },
  { code: "2909477", name: "MACA SENNINHA 1kg PCT" },
  // Lista 2
  { code: "180819", name: "DETERG LIMPOL 500ML NEUTRO" },
  { code: "182563", name: "BOMBOM LACTA PCT 1KG SONHO CHOC" },
  { code: "187791", name: "DROPS MENTOS STICK 37,5GR C/14UN TUTTI FRUT" },
  { code: "232742", name: "MAC NISSIN LAMEN MIOJO 80GR LEGUMES" },
  { code: "258351", name: "CAFE 3 CORACOES 250GR GOURMER ARABICA" },
  { code: "261307", name: "ISQUEIRO BIC MAXI UNID" },
];

// Function to create the prompt for the LLM
function createPrompt(products, categories) {
  // Limita o número de keywords por categoria no prompt para não ficar muito longo
  const categoriesString = categories
    .map(
      (cat) =>
        `- ${cat.name}: (exemplos: ${cat.keywords.slice(0, 7).join(", ")}...)`, // Mostra só os 7 primeiros como exemplo
    )
    .join("\n");

  // Formata a lista de produtos de entrada como JSON string (mais robusto)
  const productsJsonString = JSON.stringify(
    products.map((p) => ({ codigo: p.code, name: p.name })),
    null,
    2,
  );

  return `
Você é um assistente especialista em processamento de dados de produtos de supermercado brasileiros.
Sua tarefa é, para CADA item na lista de entrada ('productsInput'):
1. Atribuir UMA das categorias válidas listadas abaixo.
2. Gerar um nome de produto padronizado e limpo.

**Categorias Válidas e Exemplos de Keywords:**
${categoriesString}
- Outros: (Use APENAS se nenhuma das 7 acima for claramente adequada)

**Instruções Detalhadas para Padronização do Nome:**
1. Mantenha a informação essencial do produto e marca principal.
2. Remova unidades/pesos/volumes (ex: 1kg, 500G, 1L, 250ML).
3. Remova termos genéricos de embalagem (ex: PCT, CX, LATA, PET, EMBALAGEM).
4. Remova nomes de loja/rede genéricos (ex: COOPER, SUPERPAN).
5. Remova termos genéricos de qualidade/tipo se não forem distintivos (ex: TIPO 1, TRADICIONAL, ESPECIAL). Mantenha descritores chave (ex: INTEGRAL, PARBOILIZADO, DIET, ZERO, MORANGO).
6. Expanda abreviações comuns de produto (ex: COND -> CONDICIONADOR, SHAMP -> SHAMPOO). Mantenha siglas comuns (ex: UHT).
7. Mantenha o resultado em LETRAS MAIÚSCULAS.

**Exemplo Completo de Processamento:**
*Entrada Exemplo:*
\`\`\`json
[
  {"codigo": "11301", "name": "KIT SHAMPOO ELSEVE 375ML+COND 170ML CACHO DO SONHO"}
]
\`\`\`
*Saída Exemplo:*
\`\`\`json
[
  {
    "codigo": "11301",
    "original_name": "KIT SHAMPOO ELSEVE 375ML+COND 170ML CACHO DO SONHO",
    "category": "Limpeza e Higiene",
    "standardized_name": "KIT SHAMPOO ELSEVE + CONDICIONADOR CACHO DO SONHO"
  }
]
\`\`\`

**Produtos para Processar:**
\`\`\`json
${productsJsonString}
\`\`\`

**Sua Resposta:**
Retorne **APENAS E SOMENTE** um array JSON válido contendo um objeto para CADA produto da entrada. Cada objeto deve ter as chaves: "codigo", "original_name", "category" (com uma das categorias válidas), e "standardized_name".
`;
}

// Function to call an LLM API
async function callLLM(config, prompt) {
  try {
    const startTime = performance.now();
    const response = await axios.post(config.url, config.payload(prompt), {
      headers: config.headers,
    });
    const endTime = performance.now();

    const result = config.extractResponse(response.data);
    return {
      result: parseJsonFromLLMResponse(result),
      executionTime: endTime - startTime,
    };
  } catch (error) {
    console.error(`Error calling ${config.name}:`, error.message);
    if (error.response) {
      console.error(
        "Response data:",
        JSON.stringify(error.response.data, null, 2),
      );
    }
    return { result: null, executionTime: 0, error: error.message };
  }
}

// Function to extract JSON from LLM response (handles cases where LLM adds extra text)
function parseJsonFromLLMResponse(text) {
  if (!text) return null;

  try {
    // Try to parse the entire response as JSON first
    return JSON.parse(text);
  } catch (e) {
    // If that fails, try to extract JSON using various patterns

    // Pattern 1: Extract content between ```json and ``` markers
    const codeBlockMatch = text.match(/```(?:json)?\s*([\s\S]*?)```/);
    if (codeBlockMatch && codeBlockMatch[1]) {
      try {
        return JSON.parse(codeBlockMatch[1].trim());
      } catch (e2) {
        console.log("Failed to parse JSON from code block");
      }
    }

    // Pattern 2: Look for array pattern with square brackets
    const jsonArrayMatch = text.match(/(\[[\s\S]*\])/);
    if (jsonArrayMatch && jsonArrayMatch[1]) {
      try {
        return JSON.parse(jsonArrayMatch[1]);
      } catch (e3) {
        console.log("Failed to parse JSON array pattern");
      }
    }

    // Pattern 3: Try to find any JSON-like structure
    const possibleJson = text.replace(/^[\s\S]*?(\[[\s\S]*\])[\s\S]*$/, "$1");
    if (possibleJson !== text) {
      try {
        return JSON.parse(possibleJson);
      } catch (e4) {
        console.log("Failed to parse extracted JSON-like structure");
      }
    }

    // Log the raw response for debugging
    console.error("No valid JSON found in response. Raw response excerpt:");
    console.error(text.substring(0, 200) + "...");

    return null;
  }
}

// Main function
async function main() {
  const prompt = createPrompt(TEST_PRODUCTS, CATEGORIES);
  const resultsDir = path.join(process.cwd(), "results");

  // Create results directory if it doesn't exist
  try {
    await fs.mkdir(resultsDir, { recursive: true });
  } catch (err) {
    console.error("Error creating results directory:", err);
  }

  // Test each Gemini model
  for (const config of GEMINI_CONFIGS) {
    console.log(`Testing ${config.name}...`);

    const { result, executionTime, error } = await callLLM(config, prompt);

    const output = {
      model: config.name,
      executionTimeMs: executionTime,
      timestamp: new Date().toISOString(),
      success: result !== null,
      error: error || null,
      results: result,
    };

    // Save results to file
    const filename = path.join(resultsDir, `${config.name}-results.json`);
    await fs.writeFile(filename, JSON.stringify(output, null, 2));

    console.log(`${config.name} completed in ${executionTime.toFixed(2)}ms`);
    if (error) {
      console.log(`Error: ${error}`);
    } else {
      console.log(`Results saved to ${filename}`);
    }
  }

  console.log("All Gemini tests completed!");
}

main().catch(console.error);

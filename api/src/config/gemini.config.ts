import { GoogleGenerativeAI } from "@google/generative-ai";
import dotenv from "dotenv";

dotenv.config();

const GEMINI_API_KEY = process.env.GEMINI_API_KEY || "";
const genAI = new GoogleGenerativeAI(GEMINI_API_KEY);

const CATEGORIES = [
  {
    name: "Essenciais",
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

function createPrompt() {
  // Limita o número de keywords por categoria no prompt para não ficar muito longo
  const categoriesString = CATEGORIES.map(
    (cat) => `- ${cat.name}: (exemplos: ${cat.keywords.join(", ")}...)`, // Mostra só os 7 primeiros como exemplo
  ).join("\n");

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
    "name": "KIT SHAMPOO ELSEVE 375ML+COND 170ML CACHO DO SONHO",
    "category": "Limpeza e Higiene",
    "standardized_name": "KIT SHAMPOO ELSEVE + CONDICIONADOR CACHO DO SONHO"
  }
]
\`\`\`

**Formato da Entrada do Usuário:**
A entrada do usuário conterá APENAS a lista de produtos a serem processados no formato JSON string, dentro de um bloco de código.

**Sua Resposta:**
Retorne **APENAS E SOMENTE** um array JSON válido contendo um objeto para CADA produto da entrada. Cada objeto deve ter as chaves: "codigo", "original_name", "category" (com uma das categorias válidas), e "standardized_name". Não inclua nenhuma outra explicação ou texto fora do JSON.
`;
}

export const model = genAI.getGenerativeModel({
  model: "gemini-2.0-flash",
  systemInstruction: {
    role: "model",
    parts: [{ text: createPrompt() }],
  },
  generationConfig: {
    responseMimeType: "application/json",
    temperature: 0.1,
  },
});

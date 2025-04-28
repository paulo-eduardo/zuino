import { SSMClient, GetParameterCommand } from "@aws-sdk/client-ssm";
import { GoogleGenerativeAI } from "@google/generative-ai";
import dotenv from "dotenv";
dotenv.config();

const parameterName = "/zuino/api/gemini-api-key";
const region = process.env.AWS_REGION || "us-east-1";
const ssmClient = new SSMClient({ region });

let geminiApiKey = process.env.GEMINI_API_KEY || undefined;
let genAIClient: GoogleGenerativeAI | undefined;

async function getGeminiKeyAndInitClient(): Promise<GoogleGenerativeAI> {
  if (genAIClient) {
    return genAIClient;
  }

  if (geminiApiKey) {
    console.log(
      "[ReceiptService] Inicializando cliente de AI Generativo Gemini com chave em variavel de ambiente",
    );
    genAIClient = new GoogleGenerativeAI(geminiApiKey);
    return genAIClient;
  }

  try {
    console.log(
      `[ReceiptService] Buscando chave gemini do parameter Store: ${parameterName}`,
    );
    const command = new GetParameterCommand({
      Name: parameterName,
      WithDecryption: true,
    });
    const response = await ssmClient.send(command);
    geminiApiKey = response.Parameter?.Value;

    if (!geminiApiKey) {
      throw new Error(
        "Valor da chave Gemini nao encontrado no Parameter Store.",
      );
    }
    console.log("[ReceiptService] Chave Gemini obtida.");
  } catch (error) {
    console.error("[ReceiptService] Errp ap biscar cjave gemini:", error);
    throw error;
  }

  console.log(
    "[ReceiptService] Inicializando cliente de AI Generativo Gemini com chave do Parameter Store",
  );
  genAIClient = new GoogleGenerativeAI(geminiApiKey);
  return genAIClient;
}

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
      "FRANGO",
      "PEITO",
      "COXA",
      "BIFE",
      "CARNE",
      "MOIDA",
      "HAMBURGUER",
      "PEIXE",
      "ATUM",
      "SARDINHA",
      "PRESUNTO",
      "LINGUICA",
      "BACON",
      "TEMPERO",
      "PAPRICA",
      "PIMENTA",
      "OREGANO",
      "COMINHO",
      "COLORAU",
      "ACAFRAO",
      "CANELA",
      "CRAVO",
      "LOURO",
      "CALDO",
    ],
    description:
      "Itens básicos da alimentação diária e despensa, incluindo grãos, farinhas, óleos, laticínios básicos, pães, água, café, TODAS as proteínas como carnes (boi, frango, porco, peixe), ovos, embutidos e itens derivados (ex: hambúrguer), sal, açúcar e temperos secos diversos.",
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
      "ABOBRINHA",
      "BROCOLIS",
      "COUVE",
      "PERA",
      "MAMAO",
    ],
    description:
      "Frutas, legumes, verduras e tubérculos frescos ou minimamente processados (cortados, embalados).",
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
    description:
      "Produtos para limpeza doméstica (roupa, louça, casa) e cuidados pessoais (banho, cabelo, higiene bucal, fraldas, absorventes).",
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
      "SORVETE",
      "PIPOCA",
      "WAFER",
    ],
    description:
      "Itens não essenciais, geralmente para lanche ou sobremesa: chocolates, biscoitos, salgadinhos, doces, bolos prontos, sorvetes, achocolatados em pó.",
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
      "UTENSILIO",
      "PANO",
    ],
    description:
      "Itens não alimentícios diversos: utensílios domésticos básicos, descartáveis, pilhas, lâmpadas, velas, fósforos, produtos para churrasco (carvão), inseticidas, etc.",
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
      "ISOTONICO",
      "AGUA",
      "COCO",
    ],
    description:
      "Bebidas prontas para consumo, exceto leite e café (que estão em Essenciais). Inclui sucos, refrigerantes, chás prontos, bebidas alcoólicas, energéticos, isotônicos, água de coco.",
  },
];

function createPrompt() {
  // Generate category string with descriptions and ALL defined keywords
  const categoriesString = CATEGORIES.map(
    (cat) =>
      `- **${cat.name}:** ${cat.description} (Keywords: ${cat.keywords.join(", ")})`, // Removed .slice() to include all keywords
  ).join("\n");

  return `
Você é um assistente especialista em processamento de dados de produtos de supermercado brasileiros.
Sua tarefa é, para CADA item na lista de entrada ('productsInput'):
1. Atribuir UMA das categorias válidas listadas abaixo.
2. Gerar um nome de produto padronizado e limpo.

**Categorias Válidas, Descrições e Keywords:**
${categoriesString}
- **Outros:** Use APENAS se nenhuma das 6 categorias acima for claramente adequada.

**Instruções Detalhadas para Padronização do Nome:**
1.  **Mantenha a Essência:** Preserve a informação principal do produto e a marca principal.
2.  **Remova Medidas:** Exclua unidades, pesos, volumes (ex: 1kg, 500G, 1L, 250ML, 6 UNIDADES).
3.  **Remova Embalagens Genéricas:** Exclua termos como PCT, CX, LATA, PET, EMBALAGEM, GARRAFA, SACO, POTE, VIDRO, KIT (a menos que 'KIT' seja parte essencial do nome, nesse caso, mantenha 'Kit').
4.  **Remova Nomes de Loja/Rede:** Exclua nomes genéricos de supermercados (ex: COOPER, SUPERPAN, CARREFOUR).
5.  **Remova Qualidade Genérica:** Exclua termos como TIPO 1, TRADICIONAL, ESPECIAL, PREMIUM, SELECIONADO, se não forem um diferencial chave e específico do produto (ex: Mantenha em "Café Tradicional", mas remova de "Arroz Tradicional").
6.  **Mantenha Descritores Chave:** Preserve palavras importantes que definem o produto (ex: INTEGRAL, PARBOILIZADO, DIET, ZERO, LIGHT, MORANGO, CHOCOLATE, FRANGO ASSADO). Mantenha a acentuação original destas palavras.
7.  **Expanda Abreviações Comuns:** Converta abreviações óbvias para a palavra completa (ex: COND -> Condicionador, SHAMP -> Shampoo, DET -> Detergente, MAC -> Macarrão, REF -> Refrigerante, CERV -> Cerveja). Mantenha siglas consagradas (ex: UHT, NCM). A palavra expandida deve seguir a regra de capitalização final.
8.  **Use o Contexto (Inclusive Marcas):** Ao encontrar termos ambíguos ou abreviações não óbvias, use o contexto do nome, especialmente a marca, para deduzir o significado correto. **Exemplo:** "AZ MAMMA MIA 500ML" deve ser padronizado como "Azeite Mamma Mia", pois "MAMMA MIA" é uma marca conhecida de azeite. Não invente informações, mas use o contexto para desambiguar. Preserve a capitalização original da marca, se reconhecível.
9.  **Formato Final e Capitalização:**
    * **Preserve Acentos:** Mantenha os acentos (como á, ç, õ, ê) presentes nas palavras relevantes do nome original.
    * **Capitalização "Proper Case":** Formate o nome capitalizando a primeira letra de palavras significativas (substantivos, adjetivos, verbos, marcas). Mantenha artigos (o, a, os, as), preposições (de, do, da, em, para, com) e conjunções (e) em minúsculas, a menos que iniciem o nome ou façam parte de um nome de marca que os utilize em maiúsculas (ex: Leite Moça). Se a marca for reconhecida e usar um padrão específico (ex: NESTLÉ, Sadia), tente replicar esse padrão. A primeira palavra do nome deve sempre ser capitalizada.

**Exemplo Completo de Processamento:**
*Entrada Exemplo:*
\`\`\`json
[
  {"codigo": "11301", "name": "KIT SHAMPOO ELSEVE 375ML+COND 170ML CACHO DO SONHO"},
  {"codigo": "9988", "name": "HAMBURGUER BOVINO SADIA CX 672G C/12 UN"},
  {"codigo": "1234", "name": "ACUCAR CRISTAL DOCUCAR PCT 5KG"}
]
\`\`\`
*Saída Exemplo:*
\`\`\`json
[
  {
    "codigo": "11301",
    "original_name": "KIT SHAMPOO ELSEVE 375ML+COND 170ML CACHO DO SONHO",
    "category": "Limpeza e Higiene",
    "standardized_name": "Kit Shampoo Elseve + Condicionador Cacho do Sonho"
  },
  {
    "codigo": "9988",
    "original_name": "HAMBURGUER BOVINO SADIA CX 672G C/12 UN",
    "category": "Essenciais",
    "standardized_name": "Hambúrguer Bovino Sadia"
  },
  {
      "codigo": "1234",
      "original_name": "ACUCAR CRISTAL DOCUCAR PCT 5KG",
      "category": "Essenciais",
      "standardized_name": "Açúcar Cristal Doçúcar"
  }
]
\`\`\`

**Formato da Entrada do Usuário:**
A entrada do usuário conterá APENAS a lista de produtos a serem processados no formato JSON string, dentro de um bloco de código.

**Sua Resposta:**
Retorne **APENAS E SOMENTE** um array JSON válido contendo um objeto para CADA produto da entrada. Cada objeto deve ter as chaves: "codigo", "original_name", "category" (com uma das 6 categorias válidas ou "Outros"), e "standardized_name". Não inclua nenhuma outra explicação ou texto fora do JSON.;
`;
}

export const model = (await getGeminiKeyAndInitClient()).getGenerativeModel({
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

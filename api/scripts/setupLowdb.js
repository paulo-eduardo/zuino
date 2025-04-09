import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

import { LowSync } from "lowdb";
import { JSONFileSync } from "lowdb/node";

const initialData = {
  DEFAULT_CATEGORY: "Outros",
  categories: [
    // --- PASTE or DEFINE your categories array here ---
    // (Using a smaller example set for brevity in the script)
    {
      name: "Alimentos Básicos",
      keywords: [
        "ARROZ",
        "FEIJÃO",
        "MACARRÃO",
        "MAC ",
        "LAMEN",
        "MIOJO",
        "FARINHA",
        "AÇÚCAR",
        "ACUCAR",
        "SAL",
        "ÓLEO",
        "OLEO",
        "AZEITE",
      ],
    },
    {
      name: "Bebidas",
      keywords: [
        "REFRIGERANTE",
        "SUCO",
        "ÁGUA",
        "AGUA",
        "LEITE",
        "CERVEJA",
        "VINHO",
        "CACHAÇA",
        "ENERGETICO",
        "REFRESCO",
        "GUARANA",
      ],
    },
    {
      name: "Limpeza",
      keywords: [
        "DETERGENTE",
        "DETERG",
        "SABÃO",
        "SABAO",
        "LIMPOL",
        "DESINFETANTE",
        "ÁGUA SANITÁRIA",
        "AGUA SANITARIA",
        "LIMPADOR",
        "ESPONJA",
        "LUSTRA",
        "AMACIANTE",
        "ALVEJANTE",
      ],
    },
    {
      name: "Utilidades",
      keywords: [
        "ISQUEIRO",
        "FÓSFORO",
        "FOSFORO",
        "VELA",
        "PILHA",
        "BATERIA",
        "LÂMPADA",
        "LAMPADA",
        "GUARDANAPO",
      ],
    },
    {
      name: "Café e Chá",
      keywords: ["CAFE", "CAFÉ", "CHÁ", "CHA", "CAPPUCCINO", "FILTRO DE PAPEL"],
    },
    // --- Add the rest of your desired initial categories ---
  ],
};

const __dirname = dirname(fileURLToPath(import.meta.url));
const file = join(__dirname, "categories_lowdb.json");

const adapter = new JSONFileSync(file);

const db = new LowSync(adapter, initialData);

try {
  db.read();

  db.write();

  console.log(`✅ LowDB database initialized successfully at: ${file}`);
  console.log(`   - Default Category: ${db.data.DEFAULT_CATEGORY}`);
  console.log(`   - Number of Categories: ${db.data.categories.length}`);
} catch (error) {
  console.error(`❌ Error initializing LowDB database:`, error);
}

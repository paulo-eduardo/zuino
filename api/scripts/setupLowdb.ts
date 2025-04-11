import * as path from "path";

import { LowSync } from "lowdb";
import { JSONFileSync } from "lowdb/node";

// Define the interface for the database structure
interface DbSchema {
  DEFAULT_CATEGORY: string;
  categories: Array<{
    name: string;
    keywords: string[];
  }>;
}

const initialData: DbSchema = {
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

const __dirname = process.cwd();
const file = path.join(__dirname, "config/categories_lowdb.json");
const adapter = new JSONFileSync<DbSchema>(file);

// Use the DbSchema type for the LowSync instance
const db = new LowSync<DbSchema>(adapter, initialData);

try {
  db.read();

  db.write();

  console.log(`✅ LowDB database initialized successfully at: ${file}`);
  console.log(`   - Default Category: ${db.data.DEFAULT_CATEGORY}`);
  console.log(`   - Number of Categories: ${db.data.categories.length}`);
} catch (error) {
  console.error(`❌ Error initializing LowDB database:`, error);
}

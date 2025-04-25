import { Low } from "lowdb";
import { JSONFile } from "lowdb/node";
import * as path from "path";
import * as process from "process";

export interface Category {
  name: string;
  keywords: string[];
}

export interface CategoryData {
  DEFAULT_CATEGORY: string;
  categories: Category[];
}

// Replace the problematic lines with this approach
const __dirname = process.cwd();
const file = path.join(__dirname, "config/categories_lowdb.json");
const adapter = new JSONFile<CategoryData>(file);

const minimalDefaultData: CategoryData = {
  DEFAULT_CATEGORY: "Outros",
  categories: [],
};

export const db = new Low<CategoryData>(adapter, minimalDefaultData);

export async function initDb() {
  await db.read();
  db.data ||= { DEFAULT_CATEGORY: "Other", categories: [] };
  await db.write();
}

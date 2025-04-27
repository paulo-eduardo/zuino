import * as fs from "fs";
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

const __dirname = process.cwd();
const dbFilePath = path.join(__dirname, "config/categories_lowdb.json");
const initialKeywordsPath = path.join(
  __dirname,
  "config/keywords_initial.json",
);

// Default initial data if keywords_initial.json doesn't exist or is invalid
const defaultInitialData: DbSchema = {
  DEFAULT_CATEGORY: "Outros",
  categories: [],
};

// Try to load initial data from keywords_initial.json
let initialData: DbSchema;

try {
  // Check if the initial keywords file exists
  if (fs.existsSync(initialKeywordsPath)) {
    console.log(`📄 Loading initial data from: ${initialKeywordsPath}`);
    const fileContent = fs.readFileSync(initialKeywordsPath, "utf8");
    const parsedData = JSON.parse(fileContent);

    // Validate the structure
    if (parsedData.DEFAULT_CATEGORY && Array.isArray(parsedData.categories)) {
      initialData = parsedData;
      console.log(
        `✅ Successfully loaded initial data with ${parsedData.categories.length} categories`,
      );
    } else {
      console.warn(
        `⚠️ Invalid format in keywords_initial.json, using default structure`,
      );
      initialData = defaultInitialData;
    }
  } else {
    console.log(`⚠️ No keywords_initial.json found at: ${initialKeywordsPath}`);
    console.log(`   Using default initial data`);
    initialData = defaultInitialData;
  }

  // Ensure the config directory exists
  const configDir = path.dirname(dbFilePath);
  if (!fs.existsSync(configDir)) {
    fs.mkdirSync(configDir, { recursive: true });
    console.log(`📁 Created config directory: ${configDir}`);
  }

  // Initialize the database
  const adapter = new JSONFileSync<DbSchema>(dbFilePath);
  const db = new LowSync<DbSchema>(adapter, initialData);

  // Read (to merge with any existing data) and write
  db.read();
  db.write();

  console.log(`✅ LowDB database initialized successfully at: ${dbFilePath}`);
  console.log(`   - Default Category: ${db.data.DEFAULT_CATEGORY}`);
  console.log(`   - Number of Categories: ${db.data.categories.length}`);
} catch (error) {
  console.error(`❌ Error initializing LowDB database:`, error);
}

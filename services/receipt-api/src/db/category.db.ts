import { db } from "./lowdb.client";
import type { Category } from "./lowdb.client.ts";

function escapeRegex(string: string): string {
  return string.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function normalizeName(name: string): string {
  return name.trim().toLowerCase();
}

export async function addCategory(
  categoryName: string,
  initialKeywords: string[] = [],
): Promise<boolean> {
  await db.read();

  const normName = normalizeName(categoryName);

  const exists = db.data.categories.some(
    (cat: { name: string }) => normalizeName(cat.name) === normName,
  );

  if (exists) {
    console.warn(`[CategoryDB] Category "${categoryName}" already exists.`);
    return false;
  }

  const processedKeywords = [...new Set(initialKeywords)].map((kw) =>
    kw.toUpperCase(),
  );
  const newCategory: Category = {
    name: categoryName.trim(),
    keywords: processedKeywords,
  };
  db.data.categories.push(newCategory);
  try {
    await db.write();
    console.log(`[CategoryDB] Added category "${categoryName}".`);
    return true;
  } catch (error) {
    console.error(
      `[CategoryDB] Error adding category "${categoryName}":`,
      error,
    );
    throw error;
  }
}

export async function addKeyword(
  categoryName: string,
  keyword: string,
): Promise<boolean> {
  await db.read();
  const normName = normalizeName(categoryName);
  const categoryIndex = db.data.categories.findIndex(
    (cat) => normalizeName(cat.name) === normName,
  );
  if (categoryIndex === -1) {
    console.error(
      `[CategoryDB] Category "${categoryName}" not found for adding keyword.`,
    );
    return false;
  }

  const upperKeyword = keyword.toUpperCase();

  if (db.data.categories[categoryIndex].keywords.includes(upperKeyword)) {
    console.warn(
      `[CategoryDB] Keyword "${keyword}" already exists in category "${categoryName}".`,
    );
    return false;
  }

  db.data.categories[categoryIndex].keywords.push(upperKeyword);
  try {
    await db.write();
    console.log(
      `[CategoryDB] Added keyword "${keyword}" to category "${categoryName}".`,
    );
    return true;
  } catch (error) {
    console.error(
      `[CategoryDB] Error adding keyword "${keyword}" to category "${categoryName}":`,
      error,
    );
    throw error;
  }
}

export function getCategoryForProduct(productName: string) {
  const categories = db.data?.categories;
  const DEFAULT_CATEGORY = db.data?.DEFAULT_CATEGORY || "Outros";

  if (
    !productName ||
    typeof productName !== "string" ||
    !Array.isArray(categories)
  ) {
    return DEFAULT_CATEGORY;
  }

  const nameUpper = productName.toUpperCase();

  for (const category of categories) {
    if (!Array.isArray(category.keywords)) continue;

    for (const keyword of category.keywords) {
      try {
        const pattern = new RegExp(`\\b${escapeRegex(keyword)}\\b`);
        if (pattern.test(nameUpper)) {
          return category.name;
        }
      } catch (regexError) {
        console.error(
          `Regex error for keyword "${keyword}" in category "${category.name}:`,
          regexError,
        );
      }
    }
  }

  return DEFAULT_CATEGORY;
}

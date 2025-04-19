import { getCategoryForProduct, initializeCategorySystem } from "./category.db";

// Wait for the category system to initialize before running tests
async function runTests() {
  console.log("Waiting for category system to initialize...");
  await initializeCategorySystem();

  testCleanProductName();
}

function testCleanProductName() {
  const testProducts = [
    "ARROZ PARBOILIZADO DALFOVO 1kg TIPO 1",
    "CHOCOLATE BARRA MILKA 100G MORANGO E IOGURTE",
    "LEITE LONGA VIDA UHT LEITISSIMO 1 L INTEGRAL PET",
    "SOBRECOXA DE FRANGO C/OSSO ASSADA PADARIA COOPER K",
  ];

  console.log("Testing product name cleaning:");
  for (const product of testProducts) {
    const category = getCategoryForProduct(product);
    console.log(`Original: "${product}"`);
    console.log(`Category: "${category}"`);
    console.log("---");
  }
}

// Run the tests
runTests().catch((err) => {
  console.error("Test failed:", err);
  process.exit(1);
});

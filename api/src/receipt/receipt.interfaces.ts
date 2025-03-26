export type ReceiptItem = {
  codigo: string;
  name: string;
  store: string;
  unit: string;
  unitValue: number;
  quantity: number; // Changed to number for summing
  total: number; // Changed to number for summing
};

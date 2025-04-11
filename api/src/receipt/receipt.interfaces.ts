export interface Store {
  name: string;
  cnpj: string;
  address: string;
}

export interface Receipt {
  id: string;
  store: Store;
  date: Date;
  number: string;
  series: string;
  totalAmount: number;
  paymentMethod: string;
  url: string;
}

export interface ReceiptItem {
  codigo: string;
  name: string;
  quantity: number;
  unit: string;
  unitValue: number;
  total: number;
  category: string | undefined;
}

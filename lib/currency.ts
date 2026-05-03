export function formatZAR(amount: number): string {
  return `R${amount.toFixed(2)}`;
}

export function parseAmount(input: string): number {
  const cleaned = input.replace(/[^0-9.]/g, '');
  const parsed = parseFloat(cleaned);
  return isNaN(parsed) ? 0 : parsed;
}

export function calculateChange(cashReceived: number, totalAmount: number): number {
  return Math.max(0, cashReceived - totalAmount);
}

export function suggestMarkdownPercent(daysUntilExpiry: number): number {
  if (daysUntilExpiry <= 1) return 50;
  if (daysUntilExpiry <= 3) return 40;
  return 30;
}

export function daysUntilDate(dateStr: string): number {
  const expiry = new Date(dateStr);
  expiry.setHours(23, 59, 59, 999);
  const now = new Date();
  const diffMs = expiry.getTime() - now.getTime();
  return Math.ceil(diffMs / (1000 * 60 * 60 * 24));
}

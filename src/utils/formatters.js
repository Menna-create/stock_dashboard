/**
 * Format a number as currency
 * @param {number} value - The value to format
 * @returns {string} Formatted currency string
 */
export function formatCurrency(value) {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  }).format(value);
}

/**
 * Format a number as a percentage
 * @param {number} value - The value to format (e.g., 5.25 for 5.25%)
 * @returns {string} Formatted percentage string
 */
export function formatPercent(value) {
  return new Intl.NumberFormat('en-US', {
    style: 'percent',
    minimumFractionDigits: 2,
    maximumFractionDigits: 2
  }).format(value / 100);
}

/**
 * Format a date as a time string
 * @param {Date} date - The date to format
 * @returns {string} Formatted time string (e.g., "14:30:45")
 */
export function formatTime(date) {
  if (!(date instanceof Date)) return '';
  
  return new Intl.DateTimeFormat('en-US', {
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hour12: false
  }).format(date);
}

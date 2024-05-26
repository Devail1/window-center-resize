/* eslint import/prefer-default-export: off */

export function capitalizeFirstLetterOfEachWord(str: string): string {
  if (!str) return '';
  return str
    .split(' ')
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
    .join(' ');
}

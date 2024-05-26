/* eslint import/prefer-default-export: off */
import { URL } from 'url';
import path from 'path';
import { nativeTheme } from 'electron';

export function resolveHtmlPath(htmlFileName: string) {
  if (process.env.NODE_ENV === 'development') {
    const port = process.env.PORT || 1212;
    const url = new URL(`http://localhost:${port}`);
    url.pathname = htmlFileName;
    return url.href;
  }
  return `file://${path.resolve(__dirname, '../renderer/', htmlFileName)}`;
}

export function getIconPath(iconName: string) {
  const theme = nativeTheme.shouldUseDarkColors ? 'dark' : 'light';
  return path.join(
    __dirname,
    '../../assets',
    'icons-copy',
    theme,
    `${iconName}.png`,
  );
}

export function capitalizeFirstLetterOfEachWord(str: string): string {
  if (!str) return '';
  return str
    .split(' ')
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
    .join(' ');
}

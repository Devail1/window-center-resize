/* eslint import/prefer-default-export: off */
import { URL } from 'url';
import path from 'path';
import { app, nativeTheme } from 'electron';

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

  const { isPackaged } = app;

  const resourcesPath = isPackaged
    ? path.join(process.resourcesPath, 'assets', 'icons-copy')
    : path.join(app.getAppPath(), 'assets', 'icons-copy');

  const iconPath = path.join(resourcesPath, theme, `${iconName}.png`);

  console.log('Icon Path:', iconPath);

  return iconPath;
}

export function capitalizeFirstLetterOfEachWord(str: string): string {
  if (!str) return '';
  return str
    .split(' ')
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
    .join(' ');
}

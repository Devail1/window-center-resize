import { createRoot } from 'react-dom/client';
import AppV2 from './App-v2';
import './tailwind.css';

const container = document.getElementById('root') as HTMLElement;
const root = createRoot(container);
root.render(<AppV2 />);

import { MemoryRouter as Router, Routes, Route } from 'react-router-dom';
import AppV2 from './App-v2';
import './App.css';

export default function App() {
  return (
    <Router>
      <Routes>
        <Route path="/" element={<AppV2 />} />
      </Routes>
    </Router>
  );
}

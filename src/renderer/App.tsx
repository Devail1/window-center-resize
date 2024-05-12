import { MemoryRouter as Router, Routes, Route } from 'react-router-dom';
import AppContainer from './components/AppContainer/AppContainer';
import './App.css';
import Footer from './components/Footer/Footer';
import TabsView from './components/tabs/TabsView/TabsView';

function MyApp() {
  return (
    <div>
      <AppContainer>
        <TabsView />
        <Footer />
      </AppContainer>
    </div>
  );
}
export default function App() {
  return (
    <Router>
      <Routes>
        <Route path="/" element={<MyApp />} />
      </Routes>
    </Router>
  );
}

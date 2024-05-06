import { MemoryRouter as Router, Routes, Route } from 'react-router-dom';
import AppContainer from './components/AppContainer/AppContainer';
import './App.css';
import Footer from './components/Footer/Footer';
import TabList from './components/TabList/TabList';
import About from './components/About/About';

function MyApp() {
  return (
    <div>
      <AppContainer>
        <div className="innerContainer">
          <h1>Window Snapper & Resizer</h1>
          <TabList />
          {/* <TabContent /> */}
        </div>
        <About />
      </AppContainer>
      <Footer />
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

import About from '@/renderer/components/About/About';
import GlobalActionsSection from '@/renderer/components/GlobalActionsSection';
import UnifiedTabContent from '../content/UnifiedTabContent/UnifiedTabContent';
import './TabsView.css';

export default function TabsView() {
  return (
    <div className="inner-container">
      <h1 className="title">Window Snapper & Resizer</h1>
      <div className="tabs-content">
        <UnifiedTabContent />
        <GlobalActionsSection />
      </div>
      <About />
    </div>
  );
}

import { useEffect } from 'react';
import { useTabsContext } from '../../../providers/TabsProvider';
import About from '../../About/About';
import TabsList from '../TabsList/TabsList';
import CenterTabContent from '../content/CenterTabContent/CenterTabContent';
import ResizeTabContent from '../content/ResizeTabContent/ResizeTabContent';
import './TabsView.css';

export default function TabsView() {
  const { activeTab } = useTabsContext();

  useEffect(() => {
    if (activeTab === 'center') {
      document.title = 'Center Window';
    } else if (activeTab === 'resize') {
      document.title = 'Resize Window';
    }
  }, [activeTab]);

  return (
    <div className="inner-container">
      <h1 className="title">Window Snapper & Resizer</h1>
      <TabsList />
      <div className="tabs-content">
        {activeTab === 'center' && <CenterTabContent />}
        {activeTab === 'resize' && <ResizeTabContent />}
      </div>
      <About />
    </div>
  );
}

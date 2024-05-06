import './TabList.css';
import { TTabAction } from '../../context/tabs/tabsContext'; // Import the context
import { useTabsContext } from '../../context/tabs/TabsProvider';

function TabList() {
  const { activeTab, setActiveTab } = useTabsContext();

  const handleClick = (tabName: TTabAction) => {
    setActiveTab(tabName);
  };

  return (
    <div className="nav">
      <div className="tab">
        <button
          type="button"
          className={`tablinks ${activeTab === 'center' ? 'active' : ''}`}
          onClick={() => handleClick('center')}
        >
          Center Window
        </button>
        <button
          type="button"
          className={`tablinks ${activeTab === 'resize' ? 'active' : ''}`}
          onClick={() => handleClick('resize')}
        >
          Resize Window
        </button>
      </div>
      <button id="reset-button" type="button">
        Reset
      </button>
    </div>
  );
}

export default TabList;

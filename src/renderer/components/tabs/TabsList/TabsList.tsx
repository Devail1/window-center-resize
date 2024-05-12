import './TabsList.css';
import { useTabsContext } from '../../../providers/TabsProvider';
import { TTabAction } from '../../AppContainer/AppContainer';

function TabsList() {
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

export default TabsList;

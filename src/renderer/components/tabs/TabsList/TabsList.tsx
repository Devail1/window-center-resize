import './TabsList.css';
import { useTabsContext } from '../../../providers/TabsProvider';
import { TTabAction } from '../../AppContainer/AppContainer';
import { useSettingsContext } from '../../../providers/SettingsProvider';

function TabsList() {
  const { resetSettings } = useSettingsContext();

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
      <button id="reset-button" type="button" onClick={resetSettings}>
        Reset
      </button>
    </div>
  );
}

export default TabsList;

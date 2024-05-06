import { ReactNode, useContext, useMemo, useReducer } from 'react';
import { TTabAction, TabsContext, TabsState } from './tabsContext';

export const useTabsContext = () => {
  const context = useContext(TabsContext);
  if (!context) {
    throw new Error('useTabsContext must be used within a TabsProvider');
  }
  return context;
};

type TabsAction = { type: 'SET_ACTIVE_TAB'; payload: TTabAction };

function TabsProvider({ children }: { children: ReactNode }) {
  const tabsReducer = (state: TabsState, action: TabsAction): TabsState => {
    switch (action.type) {
      case 'SET_ACTIVE_TAB':
        return { ...state, activeTab: action.payload };
      default:
        return state;
    }
  };

  const [state, dispatch] = useReducer(tabsReducer, { activeTab: 'center' });

  const setActiveTab = (tab: TTabAction) => {
    dispatch({ type: 'SET_ACTIVE_TAB', payload: tab });
  };

  const contextValue = useMemo(() => ({ ...state, setActiveTab }), [state]);

  return (
    <TabsContext.Provider value={contextValue}>{children}</TabsContext.Provider>
  );
}

export default TabsProvider;

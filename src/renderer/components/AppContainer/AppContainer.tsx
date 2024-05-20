import { ReactNode, createContext } from 'react';
import './AppContainer.css';
import TabsProvider from '../../providers/TabsProvider';
import SettingsProvider from '../../providers/SettingsProvider';

export type TTabAction = 'center' | 'resize';

export interface TabsState {
  activeTab: TTabAction;
}

interface TabsContextProps extends TabsState {
  setActiveTab: (tab: TTabAction) => void;
}

export const TabsContext = createContext<TabsContextProps | null>(null);

function AppContainer({ children }: { children: ReactNode }) {
  return (
    <div id="container">
      <SettingsProvider>
        <TabsProvider>{children}</TabsProvider>
      </SettingsProvider>
    </div>
  );
}

export default AppContainer;

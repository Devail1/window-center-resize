import { ReactNode, createContext } from 'react';
import './AppContainer.css';
import TabsProvider from '../../providers/TabsProvider';

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
      <TabsProvider>{children}</TabsProvider>
    </div>
  );
}

export default AppContainer;

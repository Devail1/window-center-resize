import React, { ReactNode, createContext } from 'react';
import './AppContainer.css';
import TabsProvider from '@/renderer/providers/TabsProvider';
import SettingsProvider from '@/renderer/providers/SettingsProvider';

export type TTabAction = 'center' | 'resize';

export interface TabsState {
  activeTab: TTabAction;
}

interface TabsContextProps extends TabsState {
  setActiveTab: (tab: TTabAction) => void;
}

export const TabsContext = createContext<TabsContextProps | null>(null);

interface AppContainerProps {
  children: ReactNode;
}

function AppContainer({ children }: AppContainerProps): React.ReactElement {
  return (
    <SettingsProvider>
      <TabsProvider>{children}</TabsProvider>
    </SettingsProvider>
  );
}

export default AppContainer;

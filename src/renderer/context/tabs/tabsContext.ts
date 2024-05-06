import { createContext } from 'react';

export type TTabAction = 'center' | 'resize';

export interface TabsState {
  activeTab: TTabAction;
}

interface TabsContextProps extends TabsState {
  setActiveTab: (tab: TTabAction) => void;
}

export const TabsContext = createContext<TabsContextProps | null>(null);

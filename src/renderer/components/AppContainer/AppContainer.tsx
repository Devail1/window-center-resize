import { ReactNode } from 'react';
import './AppContainer.css';
import TabsProvider from '../../context/tabs/TabsProvider';

function AppContainer({ children }: { children: ReactNode }) {
  return (
    <div id="container">
      <TabsProvider>{children}</TabsProvider>
    </div>
  );
}

export default AppContainer;

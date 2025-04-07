import React from 'react';
import About from '@/renderer/components/About/About';
import GlobalSaveButton from '@/renderer/components/GlobalSaveButton';
import UnifiedTabContent from '../content/UnifiedTabContent/UnifiedTabContent';
import './TabsView.css';

export default function TabsView() {
  return (
    <div className="inner-container">
      <h1 className="title">Window Snapper & Resizer</h1>
      <div className="tabs-content">
        <UnifiedTabContent />
        <GlobalSaveButton />
      </div>
      <About />
    </div>
  );
}

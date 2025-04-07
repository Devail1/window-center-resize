import React from 'react';
import './GridControls.css';

interface GridControlsProps {
  showGrid: boolean;
  snapToGrid: boolean;
  onShowGridChange: (value: boolean) => void;
  onSnapToGridChange: (value: boolean) => void;
}

function GridControls({
  showGrid,
  snapToGrid,
  onShowGridChange,
  onSnapToGridChange,
}: GridControlsProps): React.ReactElement {
  return (
    <div className="grid-controls">
      <label className="control-label" htmlFor="show-grid">
        <input
          type="checkbox"
          id="show-grid"
          className="control-checkbox"
          checked={showGrid}
          onChange={(e) => onShowGridChange(e.target.checked)}
        />
        <span className="checkbox-text">Show Grid</span>
      </label>
      <label className="control-label" htmlFor="snap-grid">
        <input
          type="checkbox"
          id="snap-grid"
          className="control-checkbox"
          checked={snapToGrid}
          disabled={!showGrid}
          onChange={(e) => onSnapToGridChange(e.target.checked)}
        />
        <span className="checkbox-text">Snap to Grid</span>
      </label>
    </div>
  );
}

export default GridControls;

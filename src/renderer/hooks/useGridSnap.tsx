import React from 'react';

interface Position {
  x: number;
  y: number;
  width: number;
  height: number;
}

export const useGridSnap = (
  containerRef: React.RefObject<HTMLDivElement>,
  showGrid: boolean,
) => {
  const gridSize = 20; // Size of grid cells in pixels

  const snapToGrid = React.useCallback((value: number) => {
    return Math.round(value / gridSize) * gridSize;
  }, []);

  const snapPosition = React.useCallback(
    (position: Position): Position => {
      return {
        x: snapToGrid(position.x),
        y: snapToGrid(position.y),
        width: snapToGrid(position.width),
        height: snapToGrid(position.height),
      };
    },
    [snapToGrid],
  );

  const gridLines = React.useMemo(() => {
    if (!showGrid || !containerRef.current) return null;

    const containerRect = containerRef.current.getBoundingClientRect();
    const lines = [];

    // Vertical lines
    for (let x = 0; x <= containerRect.width; x += gridSize) {
      lines.push(
        <div
          key={`v-${x}`}
          className="grid-line vertical"
          style={{
            left: x,
            top: 0,
            height: '100%',
          }}
        />,
      );
    }

    // Horizontal lines
    for (let y = 0; y <= containerRect.height; y += gridSize) {
      lines.push(
        <div
          key={`h-${y}`}
          className="grid-line horizontal"
          style={{
            top: y,
            left: 0,
            width: '100%',
          }}
        />,
      );
    }

    return <div className="grid-overlay">{lines}</div>;
  }, [showGrid, containerRef]);

  return {
    gridLines,
    snapPosition: showGrid ? snapPosition : null,
  };
};

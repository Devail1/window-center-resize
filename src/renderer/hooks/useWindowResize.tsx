import React from 'react';
import { Rnd, RndResizeCallback, RndDragCallback } from 'react-rnd';

interface Position {
  x: number;
  y: number;
  width: number;
  height: number;
}

interface ScreenSize {
  width: number;
  height: number;
}

interface WindowConstraints {
  minWidth: number;
  minHeight: number;
  maxWidth?: number;
  maxHeight?: number;
}

interface RndWindowProps {
  children: React.ReactNode;
  position: Position;
  constraints?: WindowConstraints;
}

const DEFAULT_CONSTRAINTS: WindowConstraints = {
  minWidth: 100,
  minHeight: 100,
};

const getBoundedPosition = (
  position: Position,
  screenSize: ScreenSize,
  constraints: WindowConstraints = DEFAULT_CONSTRAINTS,
): Position => {
  const {
    minWidth,
    minHeight,
    maxWidth = screenSize.width,
    maxHeight = screenSize.height,
  } = constraints;

  return {
    x: Math.max(0, Math.min(position.x, screenSize.width - position.width)),
    y: Math.max(0, Math.min(position.y, screenSize.height - position.height)),
    width: Math.max(minWidth, Math.min(position.width, maxWidth)),
    height: Math.max(minHeight, Math.min(position.height, maxHeight)),
  };
};

export const useWindowResize = (
  containerRef: React.RefObject<HTMLDivElement>,
  windowRef: React.RefObject<HTMLDivElement>,
  snapPosition: ((position: Position) => Position) | null,
  screenSize: ScreenSize,
  onPositionChange: (position: Position) => void,
  showGrid: boolean = false,
  snapToGrid: boolean = false,
) => {
  const getScaledPosition = React.useCallback(
    (position: Position) => {
      if (!containerRef.current) return position;
      const containerRect = containerRef.current.getBoundingClientRect();
      const scaleX = containerRect.width / screenSize.width;
      const scaleY = containerRect.height / screenSize.height;

      return {
        x: position.x * scaleX,
        y: position.y * scaleY,
        width: position.width * scaleX,
        height: position.height * scaleY,
      };
    },
    [containerRef, screenSize],
  );

  const getUnscaledPosition = React.useCallback(
    (x: number, y: number, width: number, height: number) => {
      if (!containerRef.current) return { x, y, width, height };
      const containerRect = containerRef.current.getBoundingClientRect();
      const scaleX = screenSize.width / containerRect.width;
      const scaleY = screenSize.height / containerRect.height;

      return {
        x: Math.round(x * scaleX),
        y: Math.round(y * scaleY),
        width: Math.round(width * scaleX),
        height: Math.round(height * scaleY),
      };
    },
    [containerRef, screenSize],
  );

  const handleDragStop = React.useCallback<RndDragCallback>(
    (_e, d) => {
      const newPosition = getUnscaledPosition(
        d.x,
        d.y,
        windowRef.current?.offsetWidth || 0,
        windowRef.current?.offsetHeight || 0,
      );

      const boundedPosition = getBoundedPosition(newPosition, screenSize);

      if (snapPosition && snapToGrid) {
        const snappedPosition = snapPosition(boundedPosition);
        onPositionChange(snappedPosition);
      } else {
        onPositionChange(boundedPosition);
      }
    },
    [
      windowRef,
      snapPosition,
      onPositionChange,
      getUnscaledPosition,
      screenSize,
      snapToGrid,
    ],
  );

  const handleResizeStop = React.useCallback<RndResizeCallback>(
    (_e, _direction, ref, _delta, position) => {
      const newPosition = getUnscaledPosition(
        position.x,
        position.y,
        ref.offsetWidth,
        ref.offsetHeight,
      );

      const boundedPosition = getBoundedPosition(newPosition, screenSize);

      if (snapPosition && snapToGrid) {
        const snappedPosition = snapPosition(boundedPosition);
        onPositionChange(snappedPosition);
      } else {
        onPositionChange(boundedPosition);
      }
    },
    [
      snapPosition,
      onPositionChange,
      getUnscaledPosition,
      screenSize,
      snapToGrid,
    ],
  );

  const RndWindow = React.useCallback(
    ({
      children,
      position,
      constraints = DEFAULT_CONSTRAINTS,
    }: RndWindowProps) => {
      const scaledPos = getScaledPosition(position);

      return (
        <Rnd
          ref={windowRef as any}
          bounds="parent"
          minWidth={constraints.minWidth}
          minHeight={constraints.minHeight}
          size={{
            width: scaledPos.width,
            height: scaledPos.height,
          }}
          position={{
            x: scaledPos.x,
            y: scaledPos.y,
          }}
          dragHandleClassName="window-drag-handle"
          onDragStop={handleDragStop}
          onResizeStop={handleResizeStop}
          enableResizing={{
            top: true,
            right: true,
            bottom: true,
            left: true,
            topRight: true,
            bottomRight: true,
            bottomLeft: true,
            topLeft: true,
          }}
          resizeHandleClasses={{
            top: 'resize-handle top',
            right: 'resize-handle right',
            bottom: 'resize-handle bottom',
            left: 'resize-handle left',
            topRight: 'resize-handle top-right',
            bottomRight: 'resize-handle bottom-right',
            bottomLeft: 'resize-handle bottom-left',
            topLeft: 'resize-handle top-left',
          }}
          style={{
            transition: 'transform 0.2s ease',
            background: showGrid ? 'rgba(59, 130, 246, 0.08)' : 'transparent',
            border: showGrid ? '1px dashed rgba(59, 130, 246, 0.3)' : 'none',
          }}
          grid={showGrid ? [10, 10] : undefined}
          scale={1}
          lockAspectRatio={false}
        >
          {children}
        </Rnd>
      );
    },
    [windowRef, handleDragStop, handleResizeStop, getScaledPosition, showGrid],
  );

  return {
    RndWindow,
  };
};

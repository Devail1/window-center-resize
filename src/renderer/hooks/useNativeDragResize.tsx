import React, { useCallback, useRef } from 'react';

interface Position {
  x: number;
  y: number;
  width: number;
  height: number;
}

interface WindowConstraints {
  minWidth?: number;
  minHeight?: number;
  maxWidth?: number;
  maxHeight?: number;
}

interface ScreenSize {
  width: number;
  height: number;
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

export const useNativeDragResize = (
  containerRef: React.RefObject<HTMLDivElement>,
  windowRef: React.RefObject<HTMLDivElement>,
  snapPosition: ((position: Position) => Position) | null,
  screenSize: ScreenSize,
  onPositionChange: (position: Position) => void,
  showGrid: boolean = false,
  snapToGrid: boolean = false,
) => {
  const dragStartPos = useRef({ x: 0, y: 0 });
  const resizeStartPos = useRef({ x: 0, y: 0, width: 0, height: 0 });
  const isDragging = useRef(false);
  const isResizing = useRef(false);
  const resizeDirection = useRef('');

  const getScaledPosition = useCallback(
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

  const getUnscaledPosition = useCallback(
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

  const handleDragStart = useCallback(
    (e: React.MouseEvent) => {
      if (!windowRef.current) return;
      const rect = windowRef.current.getBoundingClientRect();
      dragStartPos.current = {
        x: e.clientX - rect.left,
        y: e.clientY - rect.top,
      };
      isDragging.current = true;
    },
    [windowRef],
  );

  const handleResizeStart = useCallback(
    (e: React.MouseEvent, direction: string) => {
      if (!windowRef.current) return;
      const rect = windowRef.current.getBoundingClientRect();
      resizeStartPos.current = {
        x: rect.left,
        y: rect.top,
        width: rect.width,
        height: rect.height,
      };
      resizeDirection.current = direction;
      isResizing.current = true;
    },
    [windowRef],
  );

  const handleMouseMove = useCallback(
    (e: React.MouseEvent) => {
      if (!windowRef.current || !containerRef.current) return;

      if (isDragging.current) {
        const containerRect = containerRef.current.getBoundingClientRect();
        const newX = e.clientX - containerRect.left - dragStartPos.current.x;
        const newY = e.clientY - containerRect.top - dragStartPos.current.y;

        const newPosition = getUnscaledPosition(
          newX,
          newY,
          windowRef.current.offsetWidth,
          windowRef.current.offsetHeight,
        );

        const boundedPosition = getBoundedPosition(newPosition, screenSize);
        if (snapPosition && snapToGrid) {
          const snappedPosition = snapPosition(boundedPosition);
          onPositionChange(snappedPosition);
        } else {
          onPositionChange(boundedPosition);
        }
      } else if (isResizing.current) {
        const containerRect = containerRef.current.getBoundingClientRect();
        const deltaX = e.clientX - resizeStartPos.current.x;
        const deltaY = e.clientY - resizeStartPos.current.y;

        let newWidth = resizeStartPos.current.width;
        let newHeight = resizeStartPos.current.height;
        let newX = resizeStartPos.current.x;
        let newY = resizeStartPos.current.y;

        switch (resizeDirection.current) {
          case 'right':
            newWidth = resizeStartPos.current.width + deltaX;
            break;
          case 'bottom':
            newHeight = resizeStartPos.current.height + deltaY;
            break;
          case 'left':
            newWidth = resizeStartPos.current.width - deltaX;
            newX = resizeStartPos.current.x + deltaX;
            break;
          case 'top':
            newHeight = resizeStartPos.current.height - deltaY;
            newY = resizeStartPos.current.y + deltaY;
            break;
          case 'topRight':
            newWidth = resizeStartPos.current.width + deltaX;
            newHeight = resizeStartPos.current.height - deltaY;
            newY = resizeStartPos.current.y + deltaY;
            break;
          case 'bottomRight':
            newWidth = resizeStartPos.current.width + deltaX;
            newHeight = resizeStartPos.current.height + deltaY;
            break;
          case 'bottomLeft':
            newWidth = resizeStartPos.current.width - deltaX;
            newHeight = resizeStartPos.current.height + deltaY;
            newX = resizeStartPos.current.x + deltaX;
            break;
          case 'topLeft':
            newWidth = resizeStartPos.current.width - deltaX;
            newHeight = resizeStartPos.current.height - deltaY;
            newX = resizeStartPos.current.x + deltaX;
            newY = resizeStartPos.current.y + deltaY;
            break;
        }

        const newPosition = getUnscaledPosition(
          newX - containerRect.left,
          newY - containerRect.top,
          newWidth,
          newHeight,
        );

        const boundedPosition = getBoundedPosition(newPosition, screenSize);
        if (snapPosition && snapToGrid) {
          const snappedPosition = snapPosition(boundedPosition);
          onPositionChange(snappedPosition);
        } else {
          onPositionChange(boundedPosition);
        }
      }
    },
    [
      windowRef,
      containerRef,
      getUnscaledPosition,
      screenSize,
      snapPosition,
      snapToGrid,
      onPositionChange,
    ],
  );

  const handleMouseUp = useCallback(() => {
    isDragging.current = false;
    isResizing.current = false;
  }, []);

  React.useEffect(() => {
    document.addEventListener('mousemove', handleMouseMove as any);
    document.addEventListener('mouseup', handleMouseUp);
    return () => {
      document.removeEventListener('mousemove', handleMouseMove as any);
      document.removeEventListener('mouseup', handleMouseUp);
    };
  }, [handleMouseMove, handleMouseUp]);

  const NativeWindow = useCallback(
    ({
      children,
      position,
      constraints = DEFAULT_CONSTRAINTS,
    }: {
      children: React.ReactNode;
      position: Position;
      constraints?: WindowConstraints;
    }) => {
      const scaledPos = getScaledPosition(position);

      return (
        <div
          ref={windowRef as any}
          className="native-window"
          style={{
            position: 'absolute',
            left: scaledPos.x,
            top: scaledPos.y,
            width: scaledPos.width,
            height: scaledPos.height,
            background: showGrid ? 'rgba(59, 130, 246, 0.08)' : 'transparent',
            border: showGrid ? '1px dashed rgba(59, 130, 246, 0.3)' : 'none',
            transition: 'transform 0.2s ease',
          }}
        >
          <div
            className="window-drag-handle"
            onMouseDown={handleDragStart}
            style={{
              position: 'absolute',
              top: 0,
              left: 0,
              right: 0,
              height: '30px',
              cursor: 'move',
            }}
          />
          {children}
          <div className="resize-handles">
            <div
              className="resize-handle top"
              onMouseDown={(e) => handleResizeStart(e, 'top')}
            />
            <div
              className="resize-handle right"
              onMouseDown={(e) => handleResizeStart(e, 'right')}
            />
            <div
              className="resize-handle bottom"
              onMouseDown={(e) => handleResizeStart(e, 'bottom')}
            />
            <div
              className="resize-handle left"
              onMouseDown={(e) => handleResizeStart(e, 'left')}
            />
            <div
              className="resize-handle top-right"
              onMouseDown={(e) => handleResizeStart(e, 'topRight')}
            />
            <div
              className="resize-handle bottom-right"
              onMouseDown={(e) => handleResizeStart(e, 'bottomRight')}
            />
            <div
              className="resize-handle bottom-left"
              onMouseDown={(e) => handleResizeStart(e, 'bottomLeft')}
            />
            <div
              className="resize-handle top-left"
              onMouseDown={(e) => handleResizeStart(e, 'topLeft')}
            />
          </div>
        </div>
      );
    },
    [
      windowRef,
      getScaledPosition,
      showGrid,
      handleDragStart,
      handleResizeStart,
    ],
  );

  return {
    NativeWindow,
  };
};

import React, { useCallback, useRef, useEffect } from 'react';
import throttle from 'lodash/throttle';

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
  minWidth?: number;
  minHeight?: number;
  maxWidth?: number;
  maxHeight?: number;
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
    minWidth = 100,
    minHeight = 100,
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
  const containerRect = useRef<DOMRect | null>(null);
  const scaleFactors = useRef({ x: 1, y: 1 });

  // Cache container dimensions and scale factors
  useEffect(() => {
    const updateContainerRect = () => {
      if (containerRef.current) {
        const rect = containerRef.current.getBoundingClientRect();
        containerRect.current = rect;
        scaleFactors.current = {
          x: screenSize.width / rect.width,
          y: screenSize.height / rect.height,
        };
      }
    };

    updateContainerRect();
    window.addEventListener('resize', updateContainerRect);
    return () => window.removeEventListener('resize', updateContainerRect);
  }, [screenSize, containerRef]);

  const getScaledPosition = useCallback(
    (position: Position) => {
      if (!containerRect.current) return position;
      const scaleX = containerRect.current.width / screenSize.width;
      const scaleY = containerRect.current.height / screenSize.height;

      return {
        x: position.x * scaleX,
        y: position.y * scaleY,
        width: position.width * scaleX,
        height: position.height * scaleY,
      };
    },
    [screenSize],
  );

  const getUnscaledPosition = useCallback(
    (x: number, y: number, width: number, height: number) => {
      if (!containerRect.current) return { x, y, width, height };

      return {
        x: Math.round(x * scaleFactors.current.x),
        y: Math.round(y * scaleFactors.current.y),
        width: Math.round(width * scaleFactors.current.x),
        height: Math.round(height * scaleFactors.current.y),
      };
    },
    [],
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

  // Mouse move handler with proper type checking
  const handleMouseMove = useCallback(
    (e: MouseEvent) => {
      if (!windowRef.current || !containerRect.current) return;

      if (isDragging.current) {
        const currentRect = containerRect.current;
        const currentWindow = windowRef.current;

        const newX = e.clientX - currentRect.left - dragStartPos.current.x;
        const newY = e.clientY - currentRect.top - dragStartPos.current.y;
        const width =
          (currentWindow.offsetWidth || DEFAULT_CONSTRAINTS.minWidth) ?? 0;
        const height =
          (currentWindow.offsetHeight || DEFAULT_CONSTRAINTS.minHeight) ?? 0;

        const newPosition = getUnscaledPosition(newX, newY, width, height);
        const boundedPosition = getBoundedPosition(newPosition, screenSize);

        if (snapPosition && snapToGrid) {
          const snappedPosition = snapPosition(boundedPosition);
          onPositionChange(snappedPosition);
        } else {
          onPositionChange(boundedPosition);
        }
      } else if (isResizing.current) {
        const currentContainerBounds =
          containerRef.current?.getBoundingClientRect();
        if (!currentContainerBounds) return;

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
          default:
            // Handle unexpected resize direction
            // console.warn(`Unexpected resize direction: ${resizeDirection.current}`);
            break;
        }

        const newPosition = getUnscaledPosition(
          newX - currentContainerBounds.left,
          newY - currentContainerBounds.top,
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
      getUnscaledPosition,
      screenSize,
      snapPosition,
      snapToGrid,
      onPositionChange,
      containerRef,
    ],
  );

  // Create a stable throttled version of handleMouseMove
  const throttledMouseMove = useCallback(
    (e: MouseEvent) => {
      const throttledFn = throttle(() => handleMouseMove(e), 16);
      throttledFn();
    },
    [handleMouseMove],
  );

  const handleMouseUp = useCallback(() => {
    isDragging.current = false;
    isResizing.current = false;
  }, []);

  React.useEffect(() => {
    document.addEventListener('mousemove', throttledMouseMove as any);
    document.addEventListener('mouseup', handleMouseUp);
    return () => {
      document.removeEventListener('mousemove', throttledMouseMove as any);
      document.removeEventListener('mouseup', handleMouseUp);
    };
  }, [throttledMouseMove, handleMouseUp]);

  const NativeWindow = useCallback(
    ({
      children,
      position,
    }: {
      children: React.ReactNode;
      position: Position;
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
            role="button"
            tabIndex={0}
            className="window-drag-handle"
            onMouseDown={handleDragStart}
            onKeyDown={(e) => e.key === 'Enter' && handleDragStart(e as any)}
            style={{
              position: 'absolute',
              top: 0,
              left: 0,
              right: 0,
              height: '30px',
              cursor: 'move',
            }}
            aria-label="Drag window"
          />
          {children}
          <div className="resize-handles">
            <div
              role="button"
              tabIndex={0}
              className="resize-handle top"
              onMouseDown={(e) => handleResizeStart(e, 'top')}
              onKeyDown={(e) =>
                e.key === 'Enter' && handleResizeStart(e as any, 'top')
              }
              aria-label="Resize from top"
            />
            <div
              role="button"
              tabIndex={0}
              className="resize-handle right"
              onMouseDown={(e) => handleResizeStart(e, 'right')}
              onKeyDown={(e) =>
                e.key === 'Enter' && handleResizeStart(e as any, 'right')
              }
              aria-label="Resize from right"
            />
            <div
              role="button"
              tabIndex={0}
              className="resize-handle bottom"
              onMouseDown={(e) => handleResizeStart(e, 'bottom')}
              onKeyDown={(e) =>
                e.key === 'Enter' && handleResizeStart(e as any, 'bottom')
              }
              aria-label="Resize from bottom"
            />
            <div
              role="button"
              tabIndex={0}
              className="resize-handle left"
              onMouseDown={(e) => handleResizeStart(e, 'left')}
              onKeyDown={(e) =>
                e.key === 'Enter' && handleResizeStart(e as any, 'left')
              }
              aria-label="Resize from left"
            />
            <div
              role="button"
              tabIndex={0}
              className="resize-handle top-right"
              onMouseDown={(e) => handleResizeStart(e, 'topRight')}
              onKeyDown={(e) =>
                e.key === 'Enter' && handleResizeStart(e as any, 'topRight')
              }
              aria-label="Resize from top-right"
            />
            <div
              role="button"
              tabIndex={0}
              className="resize-handle bottom-right"
              onMouseDown={(e) => handleResizeStart(e, 'bottomRight')}
              onKeyDown={(e) =>
                e.key === 'Enter' && handleResizeStart(e as any, 'bottomRight')
              }
              aria-label="Resize from bottom-right"
            />
            <div
              role="button"
              tabIndex={0}
              className="resize-handle bottom-left"
              onMouseDown={(e) => handleResizeStart(e, 'bottomLeft')}
              onKeyDown={(e) =>
                e.key === 'Enter' && handleResizeStart(e as any, 'bottomLeft')
              }
              aria-label="Resize from bottom-left"
            />
            <div
              role="button"
              tabIndex={0}
              className="resize-handle top-left"
              onMouseDown={(e) => handleResizeStart(e, 'topLeft')}
              onKeyDown={(e) =>
                e.key === 'Enter' && handleResizeStart(e as any, 'topLeft')
              }
              aria-label="Resize from top-left"
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

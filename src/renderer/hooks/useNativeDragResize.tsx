import React, { useCallback, useRef, useEffect, useState } from 'react';

interface Position {
  x: number;
  y: number;
  width: number;
  height: number;
}

interface ContainerSize {
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
  containerSize: ContainerSize,
  constraints: WindowConstraints = DEFAULT_CONSTRAINTS,
): Position => {
  const {
    minWidth = 100,
    minHeight = 100,
    maxWidth = containerSize.width,
    maxHeight = containerSize.height,
  } = constraints;

  return {
    x: Math.max(0, Math.min(position.x, containerSize.width - position.width)),
    y: Math.max(
      0,
      Math.min(position.y, containerSize.height - position.height),
    ),
    width: Math.max(minWidth, Math.min(position.width, maxWidth)),
    height: Math.max(minHeight, Math.min(position.height, maxHeight)),
  };
};

export const useNativeDragResize = (
  containerRef: React.RefObject<HTMLDivElement>,
  windowRef: React.RefObject<HTMLDivElement>,
  onPositionChange: (position: Position) => void,
) => {
  const dragStartPos = useRef({ x: 0, y: 0 });
  const resizeStartPos = useRef({ x: 0, y: 0, width: 0, height: 0 });
  const resizeStartMousePos = useRef({ x: 0, y: 0 });
  const isDragging = useRef(false);
  const isResizing = useRef(false);
  const resizeDirection = useRef('');
  const containerRect = useRef<DOMRect | null>(null);
  const [isActive, setIsActive] = useState(false);

  // Cache container dimensions
  useEffect(() => {
    const updateContainerRect = () => {
      if (containerRef.current) {
        const rect = containerRef.current.getBoundingClientRect();
        containerRect.current = rect;
      }
    };

    updateContainerRect();

    // Set up resize observer to update container rect when size changes
    const resizeObserver = new ResizeObserver(() => {
      updateContainerRect();
    });

    if (containerRef.current) {
      resizeObserver.observe(containerRef.current);
    }

    // Cleanup
    return () => {
      resizeObserver.disconnect();
    };
  }, [containerRef]);

  const getScaledPosition = useCallback((position: Position) => {
    // No scaling needed - return position as is for display
    return position;
  }, []);

  const handleDragStart = useCallback(
    (e: React.MouseEvent) => {
      if (!windowRef.current || !containerRect.current) return;
      const rect = windowRef.current.getBoundingClientRect();

      // Store the initial mouse position
      dragStartPos.current = {
        x: e.clientX,
        y: e.clientY,
      };

      // Store the initial window position
      resizeStartPos.current = {
        width: rect.width,
        height: rect.height,
        x: rect.left - containerRect.current.left,
        y: rect.top - containerRect.current.top,
      };
      resizeStartMousePos.current = {
        x: e.clientX,
        y: e.clientY,
      };
      isDragging.current = true;
      setIsActive(true);

      console.log('Drag started:', {
        mousePos: dragStartPos.current,
        windowPos: resizeStartPos.current,
      });
    },
    [windowRef],
  );

  const handleResizeStart = useCallback(
    (e: React.MouseEvent, direction: string) => {
      if (!windowRef.current || !containerRect.current) return;
      const rect = windowRef.current.getBoundingClientRect();
      resizeStartPos.current = {
        x: rect.left - containerRect.current.left,
        y: rect.top - containerRect.current.top,
        width: rect.width,
        height: rect.height,
      };
      resizeStartMousePos.current = {
        x: e.clientX,
        y: e.clientY,
      };
      resizeDirection.current = direction;
      isResizing.current = true;
      setIsActive(true);
    },
    [windowRef],
  );

  const handleMouseMove = useCallback(
    (e: MouseEvent) => {
      if (!windowRef.current || !containerRect.current) return;

      if (isDragging.current) {
        const currentRect = containerRect.current;

        // Calculate the mouse movement delta
        const deltaX = e.clientX - dragStartPos.current.x;
        const deltaY = e.clientY - dragStartPos.current.y;

        // Apply the delta to the initial window position
        const newX = resizeStartPos.current.x + deltaX;
        const newY = resizeStartPos.current.y + deltaY;

        const newPosition = {
          x: newX,
          y: newY,
          width: resizeStartPos.current.width,
          height: resizeStartPos.current.height,
        };
        const boundedPosition = getBoundedPosition(newPosition, {
          width: currentRect.width,
          height: currentRect.height,
        });

        console.log('Drag move:', {
          delta: { x: deltaX, y: deltaY },
          newPos: { x: newX, y: newY },
          bounded: boundedPosition,
        });

        onPositionChange(boundedPosition);
      } else if (isResizing.current) {
        const currentContainerBounds = containerRect.current;
        if (!currentContainerBounds) return;

        // Calculate deltas from the initial mouse position
        const deltaX = e.clientX - resizeStartMousePos.current.x;
        const deltaY = e.clientY - resizeStartMousePos.current.y;

        // Start with the original window dimensions
        let newWidth = resizeStartPos.current.width;
        let newHeight = resizeStartPos.current.height;
        let newX = resizeStartPos.current.x;
        let newY = resizeStartPos.current.y;

        switch (resizeDirection.current) {
          case 'right':
            newWidth += deltaX;
            break;
          case 'bottom':
            newHeight += deltaY;
            break;
          case 'left':
            newWidth -= deltaX;
            newX += deltaX;
            break;
          case 'top':
            newHeight -= deltaY;
            newY += deltaY;
            break;
          case 'topRight':
            newWidth += deltaX;
            newHeight -= deltaY;
            newY += deltaY;
            break;
          case 'bottomRight':
            newWidth += deltaX;
            newHeight += deltaY;
            break;
          case 'bottomLeft':
            newWidth -= deltaX;
            newHeight += deltaY;
            newX += deltaX;
            break;
          case 'topLeft':
            newWidth -= deltaX;
            newHeight -= deltaY;
            newX += deltaX;
            newY += deltaY;
            break;
          default:
            break;
        }

        const newPosition = {
          x: newX,
          y: newY,
          width: newWidth,
          height: newHeight,
        };
        const boundedPosition = getBoundedPosition(newPosition, {
          width: currentContainerBounds.width,
          height: currentContainerBounds.height,
        });
        onPositionChange(boundedPosition);
      }
    },
    [windowRef, onPositionChange],
  );

  const throttledMouseMove = useCallback(
    (e: MouseEvent) => {
      if (!isDragging.current && !isResizing.current) return;
      e.preventDefault();
      handleMouseMove(e);
    },
    [handleMouseMove],
  );

  const handleMouseUp = useCallback(() => {
    isDragging.current = false;
    isResizing.current = false;
    setIsActive(false);
  }, []);

  useEffect(() => {
    document.addEventListener('mousemove', throttledMouseMove as any);
    document.addEventListener('mouseup', handleMouseUp);
    return () => {
      document.removeEventListener('mousemove', throttledMouseMove as any);
      document.removeEventListener('mouseup', handleMouseUp);
    };
  }, [throttledMouseMove, handleMouseUp]);

  const NativeWindow = useCallback(
    ({ position }: { position: Position }) => {
      const scaledPos = getScaledPosition(position);

      return (
        <div
          ref={windowRef as any}
          className={`native-window ${isActive ? 'active' : ''}`}
          style={{
            left: scaledPos.x,
            top: scaledPos.y,
            width: scaledPos.width,
            height: scaledPos.height,
          }}
          onMouseDown={handleDragStart}
          onKeyDown={(e) => e.key === 'Enter' && handleDragStart(e as any)}
          role="button"
          tabIndex={0}
          aria-label="Draggable window"
        >
          <div className="native-window-content" />
          <div className="resize-handles">
            <div
              role="button"
              tabIndex={0}
              className="resize-handle top"
              onMouseDown={(e) => {
                e.stopPropagation();
                handleResizeStart(e, 'top');
              }}
              onKeyDown={(e) => {
                e.stopPropagation();
                if (e.key === 'Enter') handleResizeStart(e as any, 'top');
              }}
              aria-label="Resize from top"
            />
            <div
              role="button"
              tabIndex={0}
              className="resize-handle right"
              onMouseDown={(e) => {
                e.stopPropagation();
                handleResizeStart(e, 'right');
              }}
              onKeyDown={(e) => {
                e.stopPropagation();
                if (e.key === 'Enter') handleResizeStart(e as any, 'right');
              }}
              aria-label="Resize from right"
            />
            <div
              role="button"
              tabIndex={0}
              className="resize-handle bottom"
              onMouseDown={(e) => {
                e.stopPropagation();
                handleResizeStart(e, 'bottom');
              }}
              onKeyDown={(e) => {
                e.stopPropagation();
                if (e.key === 'Enter') handleResizeStart(e as any, 'bottom');
              }}
              aria-label="Resize from bottom"
            />
            <div
              role="button"
              tabIndex={0}
              className="resize-handle left"
              onMouseDown={(e) => {
                e.stopPropagation();
                handleResizeStart(e, 'left');
              }}
              onKeyDown={(e) => {
                e.stopPropagation();
                if (e.key === 'Enter') handleResizeStart(e as any, 'left');
              }}
              aria-label="Resize from left"
            />
            <div
              role="button"
              tabIndex={0}
              className="resize-handle top-right"
              onMouseDown={(e) => {
                e.stopPropagation();
                handleResizeStart(e, 'topRight');
              }}
              onKeyDown={(e) => {
                e.stopPropagation();
                if (e.key === 'Enter') handleResizeStart(e as any, 'topRight');
              }}
              aria-label="Resize from top-right"
            />
            <div
              role="button"
              tabIndex={0}
              className="resize-handle bottom-right"
              onMouseDown={(e) => {
                e.stopPropagation();
                handleResizeStart(e, 'bottomRight');
              }}
              onKeyDown={(e) => {
                e.stopPropagation();
                if (e.key === 'Enter')
                  handleResizeStart(e as any, 'bottomRight');
              }}
              aria-label="Resize from bottom-right"
            />
            <div
              role="button"
              tabIndex={0}
              className="resize-handle bottom-left"
              onMouseDown={(e) => {
                e.stopPropagation();
                handleResizeStart(e, 'bottomLeft');
              }}
              onKeyDown={(e) => {
                e.stopPropagation();
                if (e.key === 'Enter')
                  handleResizeStart(e as any, 'bottomLeft');
              }}
              aria-label="Resize from bottom-left"
            />
            <div
              role="button"
              tabIndex={0}
              className="resize-handle top-left"
              onMouseDown={(e) => {
                e.stopPropagation();
                handleResizeStart(e, 'topLeft');
              }}
              onKeyDown={(e) => {
                e.stopPropagation();
                if (e.key === 'Enter') handleResizeStart(e as any, 'topLeft');
              }}
              aria-label="Resize from top-left"
            />
          </div>
        </div>
      );
    },
    [
      windowRef,
      getScaledPosition,
      handleDragStart,
      handleResizeStart,
      isActive,
    ],
  );

  return {
    NativeWindow,
    getScaledPosition,
  };
};

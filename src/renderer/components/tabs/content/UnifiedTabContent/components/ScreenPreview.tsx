import React, { useRef } from 'react';
import { useNativeDragResize } from '@/renderer/hooks/useNativeDragResize';
import '@/renderer/hooks/useNativeDragResize.css';
import './ScreenPreview.css';

interface Position {
  x: number;
  y: number;
  width: number;
  height: number;
}

interface ScreenPreviewProps {
  position: Position;
  screenSize: { width: number; height: number };
  onPositionChange: (position: Position) => void;
}

function ScreenPreview({
  position,
  screenSize,
  onPositionChange,
}: ScreenPreviewProps): React.ReactElement {
  const containerRef = useRef<HTMLDivElement>(null);
  const windowRef = useRef<HTMLDivElement>(null);

  const { NativeWindow } = useNativeDragResize(
    containerRef,
    windowRef,
    screenSize,
    onPositionChange,
  );

  return (
    <div
      ref={containerRef}
      className="screen-preview"
      style={{
        width: '100%',
        height: '100%',
        position: 'relative',
        background: '#f0f0f0',
        overflow: 'hidden',
      }}
    >
      <NativeWindow position={position}>
        <div
          style={{
            width: '100%',
            height: '100%',
            background: 'rgba(59, 130, 246, 0.1)',
            border: '1px solid rgba(59, 130, 246, 0.3)',
          }}
        />
      </NativeWindow>
    </div>
  );
}

export default ScreenPreview;

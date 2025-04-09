import React from 'react';
import './QuickActions.css';

interface Position {
  x: number;
  y: number;
  width: number;
  height: number;
}

interface QuickActionButtonProps {
  onQuickAction: (position: Position) => void;
  position: Position;
  title: string;
  iconClass: string;
  description?: string;
}

function QuickActionButton({
  onQuickAction,
  position,
  title,
  iconClass,
  description,
}: QuickActionButtonProps): React.ReactElement {
  const handleClick = () => {
    onQuickAction(position);
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === 'Enter' || e.key === ' ') {
      e.preventDefault();
      handleClick();
    }
  };

  return (
    <button
      type="button"
      className="quick-action-button"
      onClick={handleClick}
      onKeyDown={handleKeyDown}
      title={description || title}
      aria-label={title}
    >
      <div
        className={`layout-icon ${iconClass}`}
        style={{
          width: '24px',
          height: '24px',
          margin: '4px',
        }}
      />
    </button>
  );
}

QuickActionButton.defaultProps = {
  description: undefined,
};

interface QuickActionsProps {
  screenSize: { width: number; height: number };
  onQuickAction: (position: Position) => void;
}

function QuickActions({
  screenSize,
  onQuickAction,
}: QuickActionsProps): React.ReactElement {
  const quickActions = [
    {
      title: 'Left Half',
      iconClass: 'left-half',
      position: {
        x: 0,
        y: 0,
        width: screenSize.width / 2,
        height: screenSize.height,
      },
    },
    {
      title: 'Right Half',
      iconClass: 'right-half',
      position: {
        x: screenSize.width / 2,
        y: 0,
        width: screenSize.width / 2,
        height: screenSize.height,
      },
    },
    {
      title: 'Top Half',
      iconClass: 'top-half',
      position: {
        x: 0,
        y: 0,
        width: screenSize.width,
        height: screenSize.height / 2,
      },
    },
    {
      title: 'Bottom Half',
      iconClass: 'bottom-half',
      position: {
        x: 0,
        y: screenSize.height / 2,
        width: screenSize.width,
        height: screenSize.height / 2,
      },
    },
    {
      title: 'Center',
      iconClass: 'center',
      position: {
        x: screenSize.width * 0.25,
        y: screenSize.height * 0.25,
        width: screenSize.width * 0.5,
        height: screenSize.height * 0.5,
      },
    },
  ];

  return (
    <div className="quick-actions">
      {quickActions.map((action) => (
        <QuickActionButton
          key={action.title}
          onQuickAction={onQuickAction}
          position={action.position}
          title={action.title}
          iconClass={action.iconClass}
        />
      ))}
    </div>
  );
}

export default QuickActions;

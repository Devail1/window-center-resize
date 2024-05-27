import '@testing-library/jest-dom';
import { act, render, screen } from '@testing-library/react';
import App from '@/renderer/App';
import mockElectron from '@/__mock__/electron';

beforeAll(() => {
  global.window.electron = mockElectron;
});

describe('App', () => {
  it('should render', async () => {
    await act(async () => {
      render(<App />);
    });

    expect(screen.getByText('Window Snapper & Resizer')).toBeInTheDocument();
  });
});

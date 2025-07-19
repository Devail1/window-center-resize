# Port Cleanup Guide

This project includes several tools to help manage port conflicts during development.

## Problem

When the Electron app is closed abruptly (Ctrl+C, force quit, etc.), the development server processes may not be properly terminated, leaving ports in use. This can cause the "Port already in use" error when trying to restart the app.

## Solutions

### 1. Automatic Port Detection

The improved port checking script will automatically find an available port if the default port (1212) is in use.

```bash
npm start
```

If port 1212 is busy, it will automatically try the next available port.

### 2. Manual Port Cleanup

#### Using Node.js script (Cross-platform):

```bash
npm run cleanup
```

#### Using PowerShell script (Windows):

```bash
npm run cleanup:ps
```

Or directly:

```powershell
powershell -ExecutionPolicy Bypass -File scripts/cleanup-ports.ps1
```

### 3. Clean Start

Automatically clean ports before starting:

```bash
npm run start:clean
```

### 4. Manual Process Killing

If the scripts don't work, you can manually kill processes:

#### Windows:

```cmd
# Kill all Node.js processes
taskkill /f /im node.exe

# Kill all Electron processes
taskkill /f /im electron.exe

# Kill specific port (replace 1212 with your port)
netstat -ano | findstr :1212
taskkill /F /PID <PID>
```

#### macOS/Linux:

```bash
# Kill all Node.js processes
pkill -f node

# Kill specific port
lsof -ti:1212 | xargs kill -9
```

## Enhanced App Cleanup

The main process now includes improved cleanup:

- **will-quit**: Properly closes watchers and AutoHotkey processes
- **window-all-closed**: Handles window closing on different platforms
- **before-quit**: Ensures all windows are destroyed before quitting
- **Force exit**: Uses `app.exit(0)` to ensure complete termination

## Ports Monitored

The cleanup scripts check these common development ports:

- 1212 (default Electron dev server)
- 4343 (alternative port)
- 8080 (alternative port)
- 3000 (common React dev server)
- 3001 (common React dev server)

## Troubleshooting

If you're still having port issues:

1. Run the cleanup script: `npm run cleanup`
2. Wait a few seconds for processes to fully terminate
3. Try starting again: `npm start`
4. If using Windows, try the PowerShell version: `npm run cleanup:ps`

## Development Workflow

For the best development experience:

1. Always use `Ctrl+C` to stop the development server
2. If the app crashes or is force-quit, run `npm run cleanup` before restarting
3. Use `npm run start:clean` for automatic cleanup on startup

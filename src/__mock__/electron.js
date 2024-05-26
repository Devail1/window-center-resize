const mockElectron = {
  ipcRenderer: {
    sendMessage: jest.fn(),
    on: jest.fn(),
    once: jest.fn(),
    invoke: jest.fn(),
    removeAllListeners: jest.fn(),
  },
};

export default mockElectron;

const { exec } = require('child_process');
const { promisify } = require('util');

const execAsync = promisify(exec);

async function cleanupPorts() {
  const ports = [1212, 4343, 8080, 3000, 3001];

  console.log('Cleaning up ports...');

  await Promise.all(
    ports.map(async (port) => {
      try {
        // Find processes using the port
        const { stdout } = await execAsync(`netstat -ano | findstr :${port}`);

        if (stdout) {
          const lines = stdout.split('\n');
          await Promise.all(
            lines.map(async (line) => {
              const parts = line.trim().split(/\s+/);
              if (parts.length >= 5) {
                const pid = parts[4];
                if (pid && pid !== '0') {
                  try {
                    await execAsync(`taskkill /F /PID ${pid}`);
                    console.log(`Killed process ${pid} using port ${port}`);
                  } catch (error) {
                    // Process might already be dead
                    console.log(
                      `Process ${pid} on port ${port} already terminated`,
                    );
                  }
                }
              }
            }),
          );
        }
      } catch (error) {
        // Port might not be in use
        console.log(`Port ${port} is not in use`);
      }
    }),
  );

  console.log('Port cleanup completed!');
}

// Run cleanup if this script is executed directly
if (require.main === module) {
  cleanupPorts().catch(console.error);
}

module.exports = cleanupPorts;

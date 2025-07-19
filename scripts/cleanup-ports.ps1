# PowerShell script to clean up ports
param(
    [int[]]$Ports = @(1212, 4343, 8080, 3000, 3001)
)

Write-Host "Cleaning up ports..." -ForegroundColor Yellow

foreach ($port in $Ports) {
    try {
        # Find processes using the port
        $connections = netstat -ano | Select-String ":$port\s"

        if ($connections) {
            foreach ($connection in $connections) {
                $parts = $connection -split '\s+'
                if ($parts.Length -ge 5) {
                    $pid = $parts[4]
                    if ($pid -and $pid -ne "0") {
                        try {
                            Stop-Process -Id $pid -Force
                            Write-Host "Killed process $pid using port $port" -ForegroundColor Green
                        } catch {
                            Write-Host "Process $pid on port $port already terminated" -ForegroundColor Gray
                        }
                    }
                }
            }
        } else {
            Write-Host "Port $port is not in use" -ForegroundColor Gray
        }
    } catch {
        Write-Host "Error checking port $port" -ForegroundColor Red
    }
}

Write-Host "Port cleanup completed!" -ForegroundColor Green

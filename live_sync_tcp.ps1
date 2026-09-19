# Server Web TCP Sincronizzato per Antigravity -> Smartphone
$port = 8080
$filePath = Join-Path $PSScriptRoot "index.html"

# Primary IPv4 Listener
$ipAddress = [System.Net.IPAddress]::Parse("127.0.0.1")
$tcpListener = [System.Net.Sockets.TcpListener]::new($ipAddress, $port)
$tcpListener.Start()
Write-Host "TCP Web Server attivo su 127.0.0.1:$port..."

# Avvia il tunnel SSH Serveo con binding esplicito a 127.0.0.1
$sshProc = Start-Process -FilePath "C:\Windows\System32\OpenSSH\ssh.exe" -ArgumentList "-o StrictHostKeyChecking=no -R 80:127.0.0.1:${port} serveo.net" -PassThru -NoNewWindow

while ($true) {
    try {
        $client = $tcpListener.AcceptTcpClient()
        $stream = $client.GetStream()
        
        $buffer = New-Object byte[] 2048
        $bytesRead = $stream.Read($buffer, 0, $buffer.Length)
        
        if (Test-Path $filePath) {
            $htmlBytes = [System.IO.File]::ReadAllBytes($filePath)
            $headerStr = "HTTP/1.1 200 OK`r`nContent-Type: text/html; charset=utf-8`r`nContent-Length: $($htmlBytes.Length)`r`nCache-Control: no-cache, no-store, must-revalidate`r`nConnection: close`r`n`r`n"
            $headerBytes = [System.Text.Encoding]::UTF8.GetBytes($headerStr)
            
            $stream.Write($headerBytes, 0, $headerBytes.Length)
            $stream.Write($htmlBytes, 0, $htmlBytes.Length)
            $stream.Flush()
        }
        $client.Close()
    } catch {
        # Continue on socket error
    }
}

# Server di Sincronizzazione Live per Antigravity -> Smartphone (Host Header Fix)
$port = 8080
$filePath = Join-Path $PSScriptRoot "index.html"

# Avvia il Listener HTTP locale con wildcard host
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://*:${port}/")

try {
    $listener.Start()
    Write-Host "Server HTTP locale attivo su porta $port con wildcard host..."
} catch {
    # Fallback se wildcard richiede permessi elevati
    $listener = New-Object System.Net.HttpListener
    $listener.Prefixes.Add("http://localhost:${port}/")
    $listener.Prefixes.Add("http://127.0.0.1:${port}/")
    $listener.Start()
    Write-Host "Server HTTP locale attivo su localhost:$port..."
}

# Avvia il tunnel SSH Serveo in background
$sshProc = Start-Process -FilePath "C:\Windows\System32\OpenSSH\ssh.exe" -ArgumentList "-o StrictHostKeyChecking=no -R 80:localhost:${port} serveo.net" -PassThru -NoNewWindow

while ($listener.IsListening) {
    try {
        $context = $listener.GetContext()
        $response = $context.Response
        
        if (Test-Path $filePath) {
            $bytes = [System.IO.File]::ReadAllBytes($filePath)
            $response.ContentType = "text/html; charset=utf-8"
            $response.Headers.Add("Cache-Control", "no-cache, no-store, must-revalidate")
            $response.Headers.Add("Pragma", "no-cache")
            $response.Headers.Add("Expires", "0")
            $response.ContentLength64 = $bytes.Length
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
        } else {
            $response.StatusCode = 404
        }
        $response.Close()
    } catch {
        # Continue loop
    }
}

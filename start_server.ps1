# Server Web Locale per Scenografia Film (Vibegram Prop)
$port = 8080
$localIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notlike "*Loopback*" -and $_.IPAddress -notlike "169.*" } | Select-Object -First 1).IPAddress
if (-not $localIP) { $localIP = "localhost" }

$serverUrl = "http://${localIP}:${port}/"

Write-Host "`n==================================================" -ForegroundColor Cyan
Write-Host " 🎬 VIBEGRAM PROP APP - SERVER ATTIVO " -ForegroundColor Yellow
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Dallo smartphone dell'attrice (connesso al Wi-Fi):" -ForegroundColor White
Write-Host " APRI QUESTO INDIRIZZO: " -NoNewline
Write-Host "$serverUrl" -ForegroundColor Green -BackgroundColor Black
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Premi CTRL+C per terminare il server.`n"

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://*:${port}/")

try {
    $listener.Start()
} catch {
    Write-Host "Impossibile avviare il listener sulla porta $port. Prova ad eseguire PowerShell come Amministratore o ad usare una porta diversa." -ForegroundColor Red
    exit
}

while ($listener.IsListening) {
    try {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        
        $filePath = Join-Path $PSScriptRoot "index.html"
        if (Test-Path $filePath) {
            $bytes = [System.IO.File]::ReadAllBytes($filePath)
            $response.ContentType = "text/html; charset=utf-8"
            $response.ContentLength64 = $bytes.Length
            $response.OutputStream.Write($bytes, 0, $bytes.Length)
        } else {
            $response.StatusCode = 404
        }
        $response.Close()
    } catch {
        # Listener stopped
    }
}

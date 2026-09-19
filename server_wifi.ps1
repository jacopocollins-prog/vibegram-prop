# Server Web Locale Wi-Fi per Scenografia Film
$port = 8080
$filePath = Join-Path $PSScriptRoot "index.html"

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://*:${port}/")

try {
    $listener.Start()
    Write-Host "Server Wi-Fi attivo su porta $port..."
} catch {
    $listener = New-Object System.Net.HttpListener
    $listener.Prefixes.Add("http://localhost:${port}/")
    $listener.Prefixes.Add("http://127.0.0.1:${port}/")
    $listener.Start()
    Write-Host "Server locale attivo su porta $port..."
}

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
        # Keep server running
    }
}

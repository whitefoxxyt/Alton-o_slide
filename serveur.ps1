# Mini serveur local pour ouvrir la presentation (aucune installation requise)
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$port = 8765
while ($true) {
  $listener = New-Object System.Net.HttpListener
  $listener.Prefixes.Add("http://localhost:$port/")
  try { $listener.Start(); break } catch { $port++ }
}
$types = @{
  '.html' = 'text/html; charset=utf-8'; '.js' = 'application/javascript; charset=utf-8'; '.mjs' = 'application/javascript'
  '.css' = 'text/css; charset=utf-8'; '.json' = 'application/json'; '.svg' = 'image/svg+xml'; '.png' = 'image/png'
  '.jpg' = 'image/jpeg'; '.ico' = 'image/x-icon'; '.woff2' = 'font/woff2'; '.woff' = 'font/woff'; '.txt' = 'text/plain; charset=utf-8'
}
$url = "http://localhost:$port/"
Write-Host "Presentation disponible sur $url"
Write-Host "Laissez cette fenetre ouverte pendant la presentation. Fermez-la pour arreter."
Start-Process $url
while ($listener.IsListening) {
  $ctx = $listener.GetContext()
  $path = [Uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath.TrimStart('/'))
  if ($path -eq '') { $path = 'index.html' }
  $file = Join-Path $root $path
  $full = [IO.Path]::GetFullPath($file)
  if (-not $full.StartsWith($root) -or -not (Test-Path $full -PathType Leaf)) { $full = Join-Path $root 'index.html' }
  $ext = [IO.Path]::GetExtension($full).ToLower()
  $ctx.Response.ContentType = $(if ($types.ContainsKey($ext)) { $types[$ext] } else { 'application/octet-stream' })
  $bytes = [IO.File]::ReadAllBytes($full)
  $ctx.Response.ContentLength64 = $bytes.Length
  $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
  $ctx.Response.Close()
}

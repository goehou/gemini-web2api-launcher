@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
title gemini-web2api

set "CFG_FILE=%~dp0config.cfg"
set "API_KEY=sk-gemini"
set "PID_FILE=%TEMP%\gemini-web2api.pid"
set "PID_FILE_2=%TEMP%\gemini-web2api-2.pid"

if not exist "%CFG_FILE%" goto :setup
for /f "usebackq tokens=1,* delims==" %%A in ("%CFG_FILE%") do (
  if "%%A"=="PROJECT_DIR" set "PROJECT_DIR=%%B"
  if "%%A"=="PYTHON_EXE" set "PYTHON_EXE=%%B"
)
if not defined PROJECT_DIR goto :setup
if not defined PYTHON_EXE goto :setup

rem 双端口模式: 项目目录同时存在 .env.anon 和 .env.cookie 时生效
set "ENV_ANON=%PROJECT_DIR%\.env.anon"
set "ENV_COOKIE=%PROJECT_DIR%\.env.cookie"
set "DUAL=0"
if exist "!ENV_ANON!" if exist "!ENV_COOKIE!" set "DUAL=1"

rem 从 .env 文件读取端口 (缺省 8081 / 8082)
set "PORT=8081"
set "PORT2=8082"
if exist "!ENV_ANON!" for /f "usebackq tokens=1,* delims==" %%A in ("!ENV_ANON!") do if "%%A"=="PORT" set "PORT=%%B"
if exist "!ENV_COOKIE!" for /f "usebackq tokens=1,* delims==" %%A in ("!ENV_COOKIE!") do if "%%A"=="PORT" set "PORT2=%%B"

rem chcp 65001 下 for /f 读 CRLF 文件会残留 CR, 剥掉
set "CR=" & for /f "delims=" %%a in ('copy /Z "%~dp0config.cfg" nul') do if not defined CR set "CR=%%a"
set "PYTHON_EXE=!PYTHON_EXE:%CR%=!"

if /i "%~1"=="start" goto :start
if /i "%~1"=="stop" goto :stop
if /i "%~1"=="status" goto :status
if /i "%~1"=="folder" goto :folder
if /i "%~1"=="config" goto :setup

:menu
cls
if "!DUAL!"=="1" (
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Write-Host '=================================================='; Write-Host '             gemini-web2api 控制台 (双端口)'; Write-Host '=================================================='; Write-Host ''; Write-Host '  项目目录  : !PROJECT_DIR!'; Write-Host '  匿名实例  : http://127.0.0.1:%PORT%/v1'; Write-Host '  cookie实例: http://127.0.0.1:%PORT2%/v1'; Write-Host '  密钥      : %API_KEY%'; Write-Host ''"
) else (
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Write-Host '=================================================='; Write-Host '             gemini-web2api 控制台'; Write-Host '=================================================='; Write-Host ''; Write-Host '  项目目录: !PROJECT_DIR!'; Write-Host '  接口地址: http://127.0.0.1:%PORT%/v1'; Write-Host '  密钥    : %API_KEY%'; Write-Host ''"
)
call :status_inline
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command "Write-Host '  [1] 启动服务'; Write-Host '  [2] 停止服务'; Write-Host '  [3] 查看状态'; Write-Host '  [4] 打开项目目录'; Write-Host '  [5] 重新配置'; Write-Host '  [0] 退出'; Write-Host ''"
set /p "CHOICE=>> "
if "%CHOICE%"=="1" call "%~f0" start & pause & goto :menu
if "%CHOICE%"=="2" call "%~f0" stop & pause & goto :menu
if "%CHOICE%"=="3" call "%~f0" status & pause & goto :menu
if "%CHOICE%"=="4" call "%~f0" folder & goto :menu
if "%CHOICE%"=="5" call "%~f0" config & goto :menu
if "%CHOICE%"=="0" exit /b 0
goto :menu

:setup
cls
powershell -NoProfile -ExecutionPolicy Bypass -Command "Write-Host '=================================================='; Write-Host '          gemini-web2api 首次配置'; Write-Host '=================================================='; Write-Host ''; Write-Host '  请配置以下路径：'; Write-Host ''"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Write-Host '  [1] 项目目录 (gemini_web2api 包所在文件夹 路径到\gemini-web2api)' -NoNewline"
echo.
if defined PROJECT_DIR (
  set /p "NEW_PROJECT_DIR=      [%PROJECT_DIR%] >> "
  if "!NEW_PROJECT_DIR!"=="" set "NEW_PROJECT_DIR=!PROJECT_DIR!"
) else (
  set /p "NEW_PROJECT_DIR=      >> "
)
if "!NEW_PROJECT_DIR!"=="" (
  powershell -NoProfile -Command "Write-Host '  路径不能为空，请重试。' -ForegroundColor Red"
  pause
  goto :setup
)
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command "Write-Host '  [2] Python 路径 (python.exe 完整路径 路径到\python.exe)' -NoNewline"
echo.
if defined PYTHON_EXE (
  set /p "NEW_PYTHON_EXE=      [%PYTHON_EXE%] >> "
  if "!NEW_PYTHON_EXE!"=="" set "NEW_PYTHON_EXE=!PYTHON_EXE!"
) else (
  set /p "NEW_PYTHON_EXE=      >> "
)
if "!NEW_PYTHON_EXE!"=="" (
  powershell -NoProfile -Command "Write-Host '  路径不能为空，请重试。' -ForegroundColor Red"
  pause
  goto :setup
)
set "PROJECT_DIR=!NEW_PROJECT_DIR!"
set "PYTHON_EXE=!NEW_PYTHON_EXE!"
powershell -NoProfile -Command "[IO.File]::WriteAllText('%CFG_FILE%', \"PROJECT_DIR=!PROJECT_DIR!`nPYTHON_EXE=!PYTHON_EXE!`n\")"
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command "Write-Host '  配置已保存到: %CFG_FILE%' -ForegroundColor Green; Write-Host '  双端口模式: 在项目目录放置 .env.anon 和 .env.cookie (参考项目 .env.example)'; Write-Host ''"
pause
if /i "%~1"=="config" exit /b 0
goto :menu

:start
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command "Write-Host '[gemini-web2api] 正在启动...'"
call :check_files || exit /b 1
call :stop_quiet
if "!DUAL!"=="1" goto :start_dual
powershell -NoProfile -ExecutionPolicy Bypass -Command "$p = Start-Process -FilePath '!PYTHON_EXE!' -ArgumentList '-m','gemini_web2api' -WorkingDirectory '!PROJECT_DIR!' -WindowStyle Hidden -PassThru; Set-Content -Path '%PID_FILE%' -Value $p.Id"
call :wait_port "%PORT%" "启动成功: http://127.0.0.1:%PORT%/v1"
exit /b %errorlevel%

:start_dual
powershell -NoProfile -ExecutionPolicy Bypass -Command "$p = Start-Process -FilePath '!PYTHON_EXE!' -ArgumentList '-m','gemini_web2api','--env-file','.env.anon' -WorkingDirectory '!PROJECT_DIR!' -WindowStyle Hidden -PassThru; Set-Content -Path '%PID_FILE%' -Value $p.Id"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$p = Start-Process -FilePath '!PYTHON_EXE!' -ArgumentList '-m','gemini_web2api','--env-file','.env.cookie' -WorkingDirectory '!PROJECT_DIR!' -WindowStyle Hidden -PassThru; Set-Content -Path '%PID_FILE_2%' -Value $p.Id"
call :wait_port "%PORT%" "匿名实例启动成功: http://127.0.0.1:%PORT%/v1"
call :wait_port "%PORT2%" "cookie实例启动成功: http://127.0.0.1:%PORT2%/v1"
exit /b %errorlevel%

:wait_port
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ok = $false; for ($i = 0; $i -lt 15; $i++) { Start-Sleep -Seconds 1; try { Invoke-RestMethod -Uri 'http://127.0.0.1:%~1/v1/models' -Headers @{Authorization='Bearer %API_KEY%'} -TimeoutSec 2 | Out-Null; $ok = $true; break } catch {} }; if ($ok) { Write-Host '[gemini-web2api] %~2'; exit 0 } else { Write-Host '[gemini-web2api] 启动失败 (端口 %~1)。'; exit 1 }"
exit /b %errorlevel%

:stop
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command "Write-Host '[gemini-web2api] 正在停止...'"
set "STOP_PORTS=%PORT%"
if "!DUAL!"=="1" set "STOP_PORTS=%PORT%,%PORT2%"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$stopped = @(); $pidFiles = @('%PID_FILE%', '%PID_FILE_2%'); foreach ($f in $pidFiles) { if (Test-Path $f) { $pidText = Get-Content $f -ErrorAction SilentlyContinue | Select-Object -First 1; if ($pidText -match '^\d+$') { Stop-Process -Id ([int]$pidText) -Force -ErrorAction SilentlyContinue; $stopped += [int]$pidText }; Remove-Item $f -Force -ErrorAction SilentlyContinue } }; $portList = '%STOP_PORTS%'.Split(','); foreach ($p in $portList) { $lines = netstat -ano | Select-String ('(?:0\.0\.0\.0|127\.0\.0\.1):' + $p + '\s+.*LISTENING\s+(\d+)'); foreach ($line in $lines) { if ($line.Line -match 'LISTENING\s+(\d+)$') { $proc = [int]$Matches[1]; Stop-Process -Id $proc -Force -ErrorAction SilentlyContinue; $stopped += $proc } } }; Start-Sleep -Seconds 1; $alive = $false; foreach ($p in $portList) { try { Invoke-RestMethod -Uri ('http://127.0.0.1:' + $p + '/v1/models') -Headers @{Authorization='Bearer %API_KEY%'} -TimeoutSec 2 | Out-Null; $alive = $true } catch {} }; if ($alive) { Write-Host '[gemini-web2api] 停止失败: 服务仍在响应。'; exit 1 } elseif ($stopped.Count -gt 0) { Write-Host ('[gemini-web2api] 已停止进程 ' + (($stopped | Select-Object -Unique) -join ', ')); exit 0 } else { Write-Host '[gemini-web2api] 服务未运行。'; exit 0 }"
exit /b %errorlevel%

:status
echo.
set "STATUS_PORTS=%PORT%"
set "STATUS_LABELS=匿名实例"
if "!DUAL!"=="1" (
  set "STATUS_PORTS=%PORT%,%PORT2%"
  set "STATUS_LABELS=匿名实例,cookie实例"
)
powershell -NoProfile -ExecutionPolicy Bypass -Command "$portList = '%STATUS_PORTS%'.Split(','); $labels = '%STATUS_LABELS%'.Split(','); for ($i = 0; $i -lt $portList.Count; $i++) { $p = $portList[$i]; $label = $labels[$i]; $httpOk = $false; $models = ''; try { $r = Invoke-RestMethod -Uri ('http://127.0.0.1:' + $p + '/v1/models') -Headers @{Authorization='Bearer %API_KEY%'} -TimeoutSec 2; $httpOk = $true; $models = (($r.data | Select-Object -First 3 -ExpandProperty id) -join ', ') } catch {}; $portPid = @(); $lines = netstat -ano | Select-String ('(?:0\.0\.0\.0|127\.0\.0\.1):' + $p + '\s+.*LISTENING\s+(\d+)'); foreach ($line in $lines) { if ($line.Line -match 'LISTENING\s+(\d+)$') { $portPid += $Matches[1] } }; Write-Host ('[' + $label + '] 端口 ' + $p + ' : ' + $(if ($httpOk -or $portPid.Count -gt 0) { '运行中' } else { '已停止' })); Write-Host ('  接口地址: http://127.0.0.1:' + $p + '/v1'); Write-Host ('  HTTP状态: ' + $(if ($httpOk) { '正常' } else { '无响应' })); Write-Host ('  端口进程: ' + $(if ($portPid.Count -gt 0) { (($portPid | Select-Object -Unique) -join ', ') } else { '无' })); if ($models) { Write-Host ('  可用模型: ' + $models) } }"
exit /b 0

:folder
start "" "!PROJECT_DIR!"
exit /b 0

:status_inline
if "!DUAL!"=="1" goto :status_inline_dual
powershell -NoProfile -ExecutionPolicy Bypass -Command "$running = $false; try { Invoke-RestMethod -Uri 'http://127.0.0.1:%PORT%/v1/models' -Headers @{Authorization='Bearer %API_KEY%'} -TimeoutSec 1 | Out-Null; $running = $true } catch {}; if (-not $running) { $running = [bool](netstat -ano | Select-String '(?:0\.0\.0\.0|127\.0\.0\.1):%PORT%\s+.*LISTENING\s+\d+') }; if ($running) { Write-Host '  状态    : 运行中' } else { Write-Host '  状态    : 已停止' }"
exit /b 0

:status_inline_dual
powershell -NoProfile -ExecutionPolicy Bypass -Command "foreach ($spec in @(@('匿名', '%PORT%'), @('cookie', '%PORT2%'))) { $running = $false; try { Invoke-RestMethod -Uri ('http://127.0.0.1:' + $spec[1] + '/v1/models') -Headers @{Authorization='Bearer %API_KEY%'} -TimeoutSec 1 | Out-Null; $running = $true } catch {}; if (-not $running) { $running = [bool](netstat -ano | Select-String ('(?:0\.0\.0\.0|127\.0\.0\.1):' + $spec[1] + '\s+.*LISTENING\s+\d+')) }; Write-Host ('  状态 ' + $spec[0] + ' : ' + $(if ($running) { '运行中' } else { '已停止' }) + ' (端口 ' + $spec[1] + ')') }"
exit /b 0

:stop_quiet
set "STOP_PORTS=%PORT%"
if "!DUAL!"=="1" set "STOP_PORTS=%PORT%,%PORT2%"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$pidFiles = @('%PID_FILE%', '%PID_FILE_2%'); foreach ($f in $pidFiles) { if (Test-Path $f) { $pidText = Get-Content $f -ErrorAction SilentlyContinue | Select-Object -First 1; if ($pidText -match '^\d+$') { Stop-Process -Id ([int]$pidText) -Force -ErrorAction SilentlyContinue }; Remove-Item $f -Force -ErrorAction SilentlyContinue } }; $portList = '%STOP_PORTS%'.Split(','); foreach ($p in $portList) { $lines = netstat -ano | Select-String ('(?:0\.0\.0\.0|127\.0\.0\.1):' + $p + '\s+.*LISTENING\s+(\d+)'); foreach ($line in $lines) { if ($line.Line -match 'LISTENING\s+(\d+)$') { Stop-Process -Id ([int]$Matches[1]) -Force -ErrorAction SilentlyContinue } } }"
exit /b 0

:check_files
if not exist "!PROJECT_DIR!\gemini_web2api\__main__.py" (
  powershell -NoProfile -Command "Write-Host '[gemini-web2api] 错误: 未找到 gemini_web2api 包目录。'"
  exit /b 1
)
if not exist "!PYTHON_EXE!" (
  powershell -NoProfile -Command "Write-Host '[gemini-web2api] 错误: 未找到 Python: !PYTHON_EXE!'"
  exit /b 1
)
exit /b 0

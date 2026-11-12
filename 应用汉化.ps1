param([switch]$RestartNow)
$ErrorActionPreference='Stop'
$appRoot=Join-Path $env:LOCALAPPDATA 'Programs\antigravity'
$archive=Join-Path $appRoot 'resources\app.asar'
$node=(Get-Command node.exe -ErrorAction Stop).Source
if (!(Test-Path -LiteralPath $archive)) { throw '未找到 Antigravity' }
$bytes=[IO.File]::ReadAllBytes($archive)
if ([Text.Encoding]::UTF8.GetString($bytes).Contains('/* --- ANTIGRAVITY CHINESE LOCALIZATION START --- */')) { Write-Output 'ALREADY_LOCALIZED'; exit 0 }
$active=@(Get-Process Antigravity -ErrorAction SilentlyContinue)
if ($active.Count -and !$RestartNow) { Write-Output 'WAIT_FOR_APP_EXIT'; exit 0 }
$originalHash=(Get-FileHash -LiteralPath $archive).Hash
$runRoot=Join-Path $PSScriptRoot ('work\'+[guid]::NewGuid().ToString('N'))
$stage=Join-Path $runRoot 'app'
$engine=Join-Path $runRoot 'engine'
New-Item -ItemType Directory -Force (Join-Path $stage 'resources'),$engine | Out-Null
Copy-Item -LiteralPath $archive -Destination (Join-Path $stage 'resources\app.asar')
Copy-Item -LiteralPath (Join-Path $appRoot 'resources\app.asar.unpacked') -Destination (Join-Path $stage 'resources\app.asar.unpacked') -Recurse
Copy-Item -Path (Join-Path $PSScriptRoot 'engine\*') -Destination $engine -Recurse
# This temporary directory is newly created within this maintenance package.
& $node (Join-Path $engine 'localization_engine.js') --install-dir $stage --no-kill --brand-title english *> (Join-Path $runRoot 'build.log')
if ($LASTEXITCODE -ne 0) { throw "补丁构建失败，原程序未替换。日志：$runRoot\build.log" }
$patched=Join-Path $stage 'resources\app.asar'
$verify=Join-Path $runRoot 'verify'
& npx.cmd --yes @electron/asar extract $patched $verify *> (Join-Path $runRoot 'verify.log')
if ($LASTEXITCODE -ne 0) { throw '补丁解包验证失败，原程序未替换' }
$version=(Get-Content -LiteralPath (Join-Path $verify 'package.json') -Raw | ConvertFrom-Json).version
foreach($file in @('preload.js','ipcHandlers.js','menu.js','tray.js','loadingOverlay.js','updater.js')) {
  & $node --check (Join-Path $verify "dist\$file")
  if ($LASTEXITCODE -ne 0) { throw "脚本语法验证失败：$file" }
}
$preload=Get-Content -LiteralPath (Join-Path $verify 'dist\preload.js') -Raw
$ipc=Get-Content -LiteralPath (Join-Path $verify 'dist\ipcHandlers.js') -Raw
if (!$preload.Contains('ANTIGRAVITY CHINESE LOCALIZATION START') -or !$ipc.Contains('translateContextLabels(template)')) { throw '汉化注入验证失败' }
if ((Get-FileHash -LiteralPath $archive).Hash -ne $originalHash) { throw '构建期间软件又发生更新，已取消替换' }
$active=@(Get-Process Antigravity -ErrorAction SilentlyContinue)
if ($active.Count -and !$RestartNow) { Write-Output 'WAIT_FOR_APP_EXIT'; exit 0 }
$backupRoot=Join-Path $PSScriptRoot ("backups\$version-$originalHash")
New-Item -ItemType Directory -Force $backupRoot | Out-Null
Copy-Item -LiteralPath $archive -Destination (Join-Path $backupRoot 'app.original.asar')
if ($active.Count) { $active | Stop-Process; Start-Sleep -Seconds 2 }
try {
  Copy-Item -LiteralPath $patched -Destination $archive -Force
  $patchedHash=(Get-FileHash -LiteralPath $archive).Hash
  if ($patchedHash -ne (Get-FileHash -LiteralPath $patched).Hash) { throw '复制校验失败' }
  @{version=$version;originalHash=$originalHash;patchedHash=$patchedHash;backup=(Join-Path $backupRoot 'app.original.asar');appliedAt=(Get-Date).ToString('o')} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'state.json') -Encoding utf8
} catch {
  Copy-Item -LiteralPath (Join-Path $backupRoot 'app.original.asar') -Destination $archive -Force
  throw
} finally {
  if ($active.Count) { Start-Process (Join-Path $appRoot 'Antigravity.exe') }
}
Write-Output "LOCALIZED_VERSION=$version"

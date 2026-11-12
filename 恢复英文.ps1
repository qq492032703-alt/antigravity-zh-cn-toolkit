$ErrorActionPreference='Stop'
$statePath=Join-Path $PSScriptRoot 'state.json'
if (!(Test-Path -LiteralPath $statePath)) { throw '尚未发现本工具包创建的汉化记录。' }
$state=Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
$appRoot=Join-Path $env:LOCALAPPDATA 'Programs\antigravity'
$archive=Join-Path $appRoot 'resources\app.asar'
if (!(Test-Path -LiteralPath $state.backup)) { throw '原版备份不存在。' }
if ((Get-FileHash -LiteralPath $archive).Hash -ne $state.patchedHash) { throw '当前资源与本工具包的记录不一致，已取消恢复。' }
if ((Get-FileHash -LiteralPath $state.backup).Hash -ne $state.originalHash) { throw '原版备份校验失败。' }
Get-Process Antigravity -ErrorAction SilentlyContinue | Stop-Process
Start-Sleep -Seconds 2
Copy-Item -LiteralPath $state.backup -Destination $archive -Force
Start-Process (Join-Path $appRoot 'Antigravity.exe')
Write-Output '已恢复本次汉化前的官方原版资源。'

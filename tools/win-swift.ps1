# Build and test the core on Windows with the Swift toolchain.
#
#   powershell -File tools\win-swift.ps1 test
#   powershell -File tools\win-swift.ps1 build
param([Parameter(Position = 0)] [string] $Command = "test")

$scratch = "C:\Dev\chipload-build"
$u = [Environment]::GetEnvironmentVariable('Path', 'User'); $m = [Environment]::GetEnvironmentVariable('Path', 'Machine'); $env:Path = "$m;$u"
foreach ($n in 'SDKROOT', 'SWIFTFLAGS', 'INCLUDE', 'LIB') {
    $v = [Environment]::GetEnvironmentVariable($n, 'User'); if ($v) { Set-Item "env:$n" $v }
}
Set-Location (Split-Path -Parent $PSScriptRoot)

function Show($lines) {
    $lines | Where-Object { $_ -notmatch 'WinSDK|wchar_t|^\s*[|`]|SwiftDriver|Failed frontend|builtin-Swift' } | Select-Object -Last 150
}

switch ($Command) {
    "build" { Show (swift build --scratch-path $scratch 2>&1 | ForEach-Object { "$_" }) }
    "test"  { Show (swift test --scratch-path $scratch 2>&1 | ForEach-Object { "$_" }) }
    default { "Unknown command: $Command" }
}

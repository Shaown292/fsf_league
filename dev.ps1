# Starts the Firebase emulators with saved data and makes sure the dev admin exists.
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

# The seed script waits for the Auth emulator by itself, then creates the admin.
Start-Process -FilePath node -ArgumentList 'tools/set-admin/seed-emulator.mjs' `
  -WorkingDirectory $PSScriptRoot -NoNewWindow

$fbArgs = @('emulators:start', '--export-on-exit=./emulator-data')
if (Test-Path './emulator-data/firebase-export-metadata.json') {
  $fbArgs += '--import=./emulator-data'
}

Write-Host 'Press Ctrl+C ONCE when you are done, then wait for the shutdown to finish.'
firebase @fbArgs
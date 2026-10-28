# Rebuild bookstore.db from schema.sql + seed.py, then run all 20 queries.
# Usage: powershell -ExecutionPolicy Bypass -File .\run.ps1
Set-Location -LiteralPath $PSScriptRoot

$py = Get-Command python -ErrorAction SilentlyContinue
if (-not $py) { Write-Error "python not found on PATH"; exit 1 }

python seed.py
if ($LASTEXITCODE -ne 0) { Write-Error "seed.py failed"; exit $LASTEXITCODE }

python run_queries.py
if ($LASTEXITCODE -ne 0) { Write-Error "a query failed"; exit $LASTEXITCODE }

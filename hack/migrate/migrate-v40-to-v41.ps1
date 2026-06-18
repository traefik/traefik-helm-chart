<#
.SYNOPSIS
  Migrate Traefik Helm chart user values from v40 to v41 (PR #1887).
.DESCRIPTION
  Renames logs.* -> log.* / accessLog.* and camelCases the affected keys.
  Runs yq via Docker, so no local tool install is required.
.EXAMPLE
  .\migrate-v40-to-v41.ps1 myvalues.yaml
  .\migrate-v40-to-v41.ps1 myvalues.yaml -InPlace
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory = $true, Position = 0)] [string]$File,
  [Alias('i')] [switch]$InPlace
)
$ErrorActionPreference = 'Stop'

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not (Test-Path -LiteralPath $File)) { Write-Error "file not found: $File"; exit 1 }
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) { Write-Error 'Docker is required.'; exit 1 }

$FileFull = (Resolve-Path -LiteralPath $File).Path
$FileDir  = Split-Path -Parent $FileFull
$FileName = Split-Path -Leaf   $FileFull

function Invoke-Yq { param([string[]]$YqArgs)
  & docker run --rm -v "${ScriptDir}:/x" -v "${FileDir}:/w" -w /w mikefarah/yq:4 @YqArgs
}

# Warn on breaking change #2: providers.file.content string -> object (not auto-migrated).
$contentType = (Invoke-Yq @('.providers.file.content | type', $FileName)) 2>$null
if ($contentType -eq '!!str') {
  Write-Warning "providers.file.content is a string. In v41 it must be an object."
  Write-Warning "This script does NOT convert it. Migrate it manually."
  Write-Warning "See https://github.com/traefik/traefik-helm-chart/pull/1887"
}

if ($InPlace) {
  Copy-Item -LiteralPath $FileFull -Destination "$FileFull.bak" -Force
  Invoke-Yq @('--from-file', '/x/v40-to-v41.yq', '-i', $FileName)
  Write-Host "migrated in place: $File (backup: $File.bak)"
} else {
  Invoke-Yq @('--from-file', '/x/v40-to-v41.yq', $FileName)
}

#Requires -Version 5.1
param(
    [ValidateSet('AUTOCAD', 'GCAD', 'ZWCAD')]
    [string]$Cad = 'AUTOCAD'
)

$ErrorActionPreference = 'Stop'
if ($env:OS -ne 'Windows_NT') {
    throw 'CAD-MCP requires Windows and a locally installed CAD application.'
}

function Invoke-Checked {
    param([string]$Program, [string[]]$Arguments)
    & $Program @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed (exit $LASTEXITCODE): $Program $($Arguments -join ' ')"
    }
}

function Find-Python {
    foreach ($name in 'python.exe', 'py.exe') {
        $command = Get-Command $name -CommandType Application -ErrorAction SilentlyContinue
        if (-not $command -or $command.Source -like '*\Microsoft\WindowsApps\*') { continue }
        $arguments = @('-c', 'import sys; print(sys.executable) if sys.version_info >= (3, 10) else sys.exit(1)')
        if ($name -eq 'py.exe') { $arguments = @('-3') + $arguments }
        $executable = & $command.Source @arguments 2>$null
        if ($LASTEXITCODE -eq 0) { return $executable }
    }
    throw 'Install Python 3.10 or later for Windows and reopen PowerShell.'
}

$codex = (Get-Command codex -ErrorAction Stop).Source
$codexDir = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HOME '.codex' }
$skillName = 'cad-reference-to-dwg'
$legacySkill = Join-Path $codexDir "skills/$skillName"
$userSkill = Join-Path $HOME ".agents/skills/$skillName"
$skillDir = if (Test-Path -LiteralPath $legacySkill) { $legacySkill } else { $userSkill }
$skillFiles = @('SKILL.md', 'agents/openai.yaml')
$installFiles = @()
foreach ($relativePath in $skillFiles) {
    $source = Join-Path $PSScriptRoot $relativePath
    $target = Join-Path $skillDir $relativePath
    if (-not (Test-Path -LiteralPath $source -PathType Leaf)) {
        throw "Missing $relativePath. Run the installer from the extracted repository."
    }
    if (Test-Path -LiteralPath $target) {
        $localText = [IO.File]::ReadAllText($target).Replace("`r`n", "`n")
        $sourceText = [IO.File]::ReadAllText($source).Replace("`r`n", "`n")
        if ($localText -cne $sourceText) {
            throw "An edited skill file already exists: $target. Back it up and move the skill directory before retrying."
        }
    } else {
        $installFiles += $relativePath
    }
}

$serverName = 'cad-mcp'
$servers = (Invoke-Checked $codex @('mcp', 'list', '--json') | Out-String) | ConvertFrom-Json
$existing = $servers | Where-Object name -eq $serverName
if ($existing -and -not $existing.enabled) {
    throw "The existing $serverName entry is disabled. Enable or rename that entry and rerun."
}

if (-not $existing) {
    $revision = 'daf7502951175e01aba9126a702400186ba2d4f9'
    $upstream = "https://github.com/daobataotie/CAD-MCP/archive/$revision.zip"
    $python = Find-Python
    $runtime = Join-Path $codexDir "cad-reference-to-dwg/CAD-MCP-$revision"
    $venv = Join-Path $runtime '.venv'
    $venvPython = Join-Path $venv 'Scripts/python.exe'
    $serverScript = Join-Path $runtime "CAD-MCP-$revision/src/server.py"
    $settingsPath = Join-Path (Split-Path -Parent $serverScript) 'config.json'

    if (-not (Test-Path -LiteralPath $serverScript -PathType Leaf)) {
        New-Item -ItemType Directory -Path $runtime -Force | Out-Null
        $archive = Join-Path $runtime 'CAD-MCP.zip'
        Invoke-WebRequest -UseBasicParsing -Uri $upstream -OutFile $archive
        Expand-Archive -LiteralPath $archive -DestinationPath $runtime -Force
        Remove-Item -LiteralPath $archive
    }

    if (-not (Test-Path -LiteralPath $venvPython -PathType Leaf)) {
        Invoke-Checked $python @('-m', 'venv', $venv)
    }
    $requirements = Join-Path (Split-Path -Parent (Split-Path -Parent $serverScript)) 'requirements.txt'
    Invoke-Checked $venvPython @('-m', 'pip', 'install', '-r', $requirements)
    Invoke-Checked $venvPython @('-m', 'pip', 'check')
    $settings = Get-Content -LiteralPath $settingsPath -Encoding UTF8 -Raw | ConvertFrom-Json
    $settings.cad.type = $Cad
    $settings.server.transport = 'stdio'
    [IO.File]::WriteAllText($settingsPath, ($settings | ConvertTo-Json -Depth 10), [Text.UTF8Encoding]::new($false))
    Invoke-Checked $venvPython @($serverScript, '--help')

    # Register last, after the server and its dependencies have been checked.
    Invoke-Checked $codex @('mcp', 'add', $serverName, '--', $venvPython, $serverScript)
} else {
    Write-Host "Using the existing enabled Codex MCP entry: $serverName"
}

foreach ($relativePath in $installFiles) {
    $target = Join-Path $skillDir $relativePath
    [IO.Directory]::CreateDirectory((Split-Path -Parent $target)) | Out-Null
    [IO.File]::Copy((Join-Path $PSScriptRoot $relativePath), $target, $false)
}
Write-Host "Skill files ready: $skillDir"
Write-Host 'Restart Codex and use a CAD read-only query to verify the connection.'

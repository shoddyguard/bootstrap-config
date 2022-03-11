# Get the modules to load
$Modules = @(
    'posh-git',
    'ITOps.PSTools',
    'oh-my-posh',
    'Terminal-Icons'
)
$Modules | ForEach-Object { Import-Module $_ }
Set-PoshPrompt -Theme (Join-Path $PSScriptRoot 'profile.omp.json')

# Load my ssh keys into the agent if they are not already
$CurrentKeys = & ssh-add -L
Get-ChildItem (Join-Path $HOME '.ssh') | Where-Object { $_.Extension -eq '.pub' } | ForEach-Object {
    $Content = (Get-Content $_.FullName)
    $Key = $_.FullName -replace '\.pub$', ''
    if ($CurrentKeys -notcontains $Content)
    {
        & ssh-add $Key
    }
}

## Set a bunch of non-secure variables

# Repo stuff
$Global:RepoPath = Join-Path $HOME 'Repositories'
$Global:WorkRepoPath = Join-Path $Global:RepoPath 'Redgate'
$Global:PersonalRepoPath = Join-Path $Global:RepoPath 'Personal'
$Global:BrownserveRepoPath = Join-Path $Global:RepoPath 'Brownserve'

# Vault
$env:VAULT_ADDR = 'https://vault.red-gate.com'

# Helper function to upgrade chocolatey packages
function Update-ChocolateyPackages
{
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) -eq $false)
    {
        throw "This script must be run as an administrator"
    }
    $Upgrades = & choco outdated -r
    if ($Upgrades)
    {
        Write-Host 'The following packages will be upgraded:'
        $Upgrades
        $Answer = Read-Host 'Do you want to upgrade the Chocolatey packages? [Y/n]'
        if ($Answer -eq 'Y')
        {
            & choco upgrade all -y
        }
    }
    else
    {
        Write-Host 'No packages need to be upgraded.'
    }
}

# Initializes the shell with various secrets and such
function Set-SecureShellVariables
{
    # Unlock vault first for 30 seconds so we can grab any secrets we need to
    Unlock-SecretStore -PasswordTimeout 30
    # Store all the secrets in a global hashtable so it's easy to clear them later on.
    $Global:SecureShellVariables = @{
        RedgatePrivateNugetFeed = @{
            Username = 'steve.brown@red-gate.com'
            APIKey   = (Get-Secret -Name 'NugetAPIKey' -Vault SecretStore)
            Name     = 'red-gate-vsts-main-v3'
            URL      = 'https://red-gate.pkgs.visualstudio.com/_packaging/Main/nuget/v3/index.json'
        }
        GitHubToken             = (Get-Secret -Name 'GitHubToken' -Vault SecretStore)
    }
}
function Clear-SecureShellVariables
{
    $Global:SecureShellVariables = @{}
}
# Get the modules to load
$Modules = @(
    'posh-git',
    'ITOps.PSTools',
    'oh-my-posh',
    'Terminal-Icons'
)
$Modules | ForEach-Object { Import-Module $_ }
Set-PoshPrompt -Theme (Join-Path $PSScriptRoot "profile.omp.json")

# Set some helpful history search things in PSReadline
Set-PSReadlineKeyHandler -Key Ctrl+Shift+UpArrow -Function HistorySearchBackward
Set-PSReadlineKeyHandler –Key Ctrl+Shift+DownArrow -Function HistorySearchForward

## Set a bunch of non-secure variables

# Repo stuff
$Global:RepoPath = Join-Path $HOME 'Repositories'
$Global:WorkRepoPath = Join-Path $Global:RepoPath 'Redgate'
$Global:PersonalRepoPath = Join-Path $Global:RepoPath 'Personal'
$Global:BrownserveRepoPath = Join-Path $Global:RepoPath 'Brownserve'

# Vault
$env:VAULT_ADDR = 'https://vault.red-gate.com'

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
        GitHubToken = (Get-Secret -Name 'GitHubToken' -Vault SecretStore)
    }
}
function Clear-SecureShellVariables
{
    $Global:SecureShellVariables = @{}
}
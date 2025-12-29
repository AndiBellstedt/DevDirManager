<#
    Configuration Loader for DevDirManager

    This script loads the user configuration from the JSON file during module import.
    Configuration is stored in the PSFramework configuration system for runtime access.

    The configuration file is stored in the PowerShell data folder within the user's profile,
    respecting different locations for Windows PowerShell (5.1) and PowerShell 7+.

    Version: 1.0.0
    Last Modified: 2025-12-28
#>

#region -- Configuration path determination

# Determine the correct PowerShell data folder based on PS version.
# Windows PowerShell 5.1 uses a different path than PowerShell 7+.
if ($PSVersionTable.PSVersion.Major -ge 6) {
    # PowerShell 7+ (Core)
    $script:DevDirManagerPowerShellDataFolder = Join-Path -Path $env:LOCALAPPDATA -ChildPath "Microsoft\PowerShell"
} else {
    # Windows PowerShell 5.1
    $script:DevDirManagerPowerShellDataFolder = Join-Path -Path $env:LOCALAPPDATA -ChildPath "Microsoft\Windows\PowerShell"
}

# Define the configuration file path.
$script:DevDirManagerConfigPath = Join-Path -Path $script:DevDirManagerPowerShellDataFolder -ChildPath "DevDirManagerConfiguration.json"

#endregion Configuration path determination


#region -- Configuration defaults

# Define default values for all configuration keys.
# These values are used when no configuration file exists or when loading fails.
$script:DevDirManagerConfigDefaults = @{
    "System.RepositoryListPath"  = ""
    "System.LocalDevDirectory"   = ""
    "System.AutoSyncEnabled"     = $false
    "System.SyncIntervalMinutes" = 60
    "System.DefaultSystemFilter" = "*"
    "System.LastSyncTime"        = $null
    "System.LastSyncResult"      = ""
    "System.ConfigFilePath"      = $script:DevDirManagerConfigPath
}

#endregion Configuration defaults


#region -- Load configuration from JSON file

if (Test-Path -Path $script:DevDirManagerConfigPath -PathType Leaf) {
    try {
        $configContent = Get-Content -Path $script:DevDirManagerConfigPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop

        # Map JSON properties to PSFramework configuration.
        $configMapping = @{
            "RepositoryListPath"  = "System.RepositoryListPath"
            "LocalDevDirectory"   = "System.LocalDevDirectory"
            "AutoSyncEnabled"     = "System.AutoSyncEnabled"
            "SyncIntervalMinutes" = "System.SyncIntervalMinutes"
            "DefaultSystemFilter" = "System.DefaultSystemFilter"
            "LastSyncTime"        = "System.LastSyncTime"
            "LastSyncResult"      = "System.LastSyncResult"
        }

        foreach ($jsonKey in $configMapping.Keys) {
            $psfKey = $configMapping[$jsonKey]
            $value = $configContent.$jsonKey

            # Use default if value is null or not present.
            if ($null -eq $value) {
                $value = $script:DevDirManagerConfigDefaults[$psfKey]
            }

            # Handle datetime conversion for LastSyncTime.
            if ($psfKey -eq "System.LastSyncTime" -and $value -is [string] -and -not [string]::IsNullOrWhiteSpace($value)) {
                try {
                    $value = [datetime]::Parse($value)
                } catch {
                    $value = $null
                }
            }

            Set-PSFConfig -Module "DevDirManager" -Name $psfKey -Value $value
        }

        Write-PSFMessage -Level Verbose -Message "Loaded DevDirManager configuration from '$($script:DevDirManagerConfigPath)'"
    } catch {
        Write-PSFMessage -Level Warning -Message "Failed to load DevDirManager configuration from '$($script:DevDirManagerConfigPath)': $($_)"

        # Set defaults on failure.
        foreach ($key in $script:DevDirManagerConfigDefaults.Keys) {
            Set-PSFConfig -Module "DevDirManager" -Name $key -Value $script:DevDirManagerConfigDefaults[$key]
        }
    }
} else {
    # No config file exists, set defaults.
    foreach ($key in $script:DevDirManagerConfigDefaults.Keys) {
        Set-PSFConfig -Module "DevDirManager" -Name $key -Value $script:DevDirManagerConfigDefaults[$key]
    }

    Write-PSFMessage -Level Verbose -Message "No DevDirManager configuration file found at '$($script:DevDirManagerConfigPath)'. Using defaults."
}

# Always set the config file path (this is dynamic based on PS version).
Set-PSFConfig -Module "DevDirManager" -Name "System.ConfigFilePath" -Value $script:DevDirManagerConfigPath

#endregion Load configuration from JSON file

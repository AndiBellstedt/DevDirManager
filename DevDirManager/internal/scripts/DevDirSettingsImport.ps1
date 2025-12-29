<#
    DevDirManager Settings Import

    This script loads the user configuration from the JSON file during module import
    and initializes the PSFramework configuration system with validators and handlers.

    The configuration file is stored in the PowerShell data folder within the user's profile,
    respecting different locations for Windows PowerShell (5.1) and PowerShell 7+.

    Version: 1.1.0
    Last Modified: 2025-12-29
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


#region -- Scheduled Task Name determination

# Build user-specific task name to avoid conflicts in multi-user environments.
# Format: PS<MajorVersion>_DevDirManager_<UserIdentifier>
$psMajorVersion = $PSVersionTable.PSVersion.Major

if ($IsWindows -or (-not (Test-Path variable:IsWindows))) {
    # Windows environment - use SID for uniqueness.
    try {
        $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $userIdentifier = $currentUser.User.Value
    } catch {
        # Fallback to username if SID retrieval fails.
        $userIdentifier = $env:USERNAME
    }
} else {
    # Non-Windows environment - use username.
    $userIdentifier = $env:USER
    if ([string]::IsNullOrWhiteSpace($userIdentifier)) {
        $userIdentifier = $env:USERNAME
    }
}

$script:DevDirManagerScheduledTaskName = "PS{0}_DevDirManager_{1}" -f $psMajorVersion, $userIdentifier

#endregion Scheduled Task Name determination


#region -- Configuration handler scriptblock

# This handler is executed whenever a PSFConfig value is changed.
# It persists the configuration to the JSON file automatically.
$script:DevDirManagerConfigHandler = {
    param($Value)

    # Prevent recursive handler execution by using a flag.
    if ($script:DevDirManagerHandlerExecuting) {
        return
    }

    $script:DevDirManagerHandlerExecuting = $true

    try {
        $configPath = $script:DevDirManagerConfigPath

        # Ensure directory exists.
        $configDir = Split-Path -Path $configPath -Parent
        if (-not (Test-Path -Path $configDir -PathType Container)) {
            $null = New-Item -Path $configDir -ItemType Directory -Force
        }

        # Build configuration object for export from current PSFConfig values.
        $configExport = [ordered]@{
            RepositoryListPath  = Get-PSFConfigValue -FullName "DevDirManager.System.RepositoryListPath"
            LocalDevDirectory   = Get-PSFConfigValue -FullName "DevDirManager.System.LocalDevDirectory"
            AutoSyncEnabled     = Get-PSFConfigValue -FullName "DevDirManager.System.AutoSyncEnabled"
            SyncIntervalMinutes = Get-PSFConfigValue -FullName "DevDirManager.System.SyncIntervalMinutes"
            LastSyncTime        = Get-PSFConfigValue -FullName "DevDirManager.System.LastSyncTime"
            LastSyncResult      = Get-PSFConfigValue -FullName "DevDirManager.System.LastSyncResult"
        }

        # Convert datetime to ISO 8601 string for JSON serialization.
        if ($configExport.LastSyncTime -is [datetime]) {
            $configExport.LastSyncTime = $configExport.LastSyncTime.ToString("o")
        }

        # Write the configuration to JSON file.
        $configExport | ConvertTo-Json -Depth 3 | Set-Content -Path $configPath -Encoding UTF8 -Force
    } finally {
        $script:DevDirManagerHandlerExecuting = $false
    }
}

# Initialize handler execution flag.
$script:DevDirManagerHandlerExecuting = $false

#endregion Configuration handler scriptblock


#region -- Configuration defaults and initialization

# Define default values for all configuration keys.
# Note: Default sync interval is 6 hours (360 minutes).
$script:DevDirManagerConfigDefaults = @{
    "System.RepositoryListPath"  = ""
    "System.LocalDevDirectory"   = ""
    "System.AutoSyncEnabled"     = $false
    "System.SyncIntervalMinutes" = 360
    "System.LastSyncTime"        = $null
    "System.LastSyncResult"      = ""
}

# Initialize internal static configuration for task name (not user-configurable).
Set-PSFConfig -Module "DevDirManager" -Name "Internal.ScheduledTaskName" -Value $script:DevDirManagerScheduledTaskName -Hidden -Initialize -Description "Internal scheduled task name (read-only)"

#endregion Configuration defaults and initialization


#region -- Load configuration from JSON file

# Helper function to set a configuration with validation and handler.
function script:Set-DevDirManagerConfigItem {
    param(
        [string]$Name,
        [object]$Value,
        [string]$Validation,
        [string]$Description,
        [switch]$NoHandler
    )

    $setParams = @{
        Module      = "DevDirManager"
        Name        = $Name
        Value       = $Value
        Description = $Description
        Initialize  = $true
    }

    if ($Validation) {
        $setParams["Validation"] = $Validation
    }

    # Add handler for automatic persistence (except for read-only fields like LastSyncTime/LastSyncResult).
    if (-not $NoHandler) {
        $setParams["Handler"] = $script:DevDirManagerConfigHandler
    }

    Set-PSFConfig @setParams
}

# Load existing configuration from JSON file if it exists.
$configFromFile = $null
if (Test-Path -Path $script:DevDirManagerConfigPath -PathType Leaf) {
    try {
        $configFromFile = Get-Content -Path $script:DevDirManagerConfigPath -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        Write-PSFMessage -Level Verbose -String "DevDirSettingsImport.ConfigLoaded" -StringValues @($script:DevDirManagerConfigPath) -Tag "DevDirSettingsImport", "Load"
    } catch {
        Write-PSFMessage -Level Warning -String "DevDirSettingsImport.ConfigLoadFailed" -StringValues @($script:DevDirManagerConfigPath, $_) -Tag "DevDirSettingsImport", "Error"
        $configFromFile = $null
    }
} else {
    Write-PSFMessage -Level Verbose -String "DevDirSettingsImport.ConfigNotFound" -StringValues @($script:DevDirManagerConfigPath) -Tag "DevDirSettingsImport", "Load"
}

# Initialize all configuration items with validation and handlers.
# RepositoryListPath - Optional path (no validation to allow empty strings).
$repoListValue = if ($configFromFile -and $configFromFile.RepositoryListPath) { $configFromFile.RepositoryListPath } else { $script:DevDirManagerConfigDefaults["System.RepositoryListPath"] }
Set-DevDirManagerConfigItem -Name "System.RepositoryListPath" -Value $repoListValue -Description "Path to the central repository list file (JSON, CSV, or XML)"

# LocalDevDirectory - Optional path (no validation to allow empty strings).
$localDevValue = if ($configFromFile -and $configFromFile.LocalDevDirectory) { $configFromFile.LocalDevDirectory } else { $script:DevDirManagerConfigDefaults["System.LocalDevDirectory"] }
Set-DevDirManagerConfigItem -Name "System.LocalDevDirectory" -Value $localDevValue -Description "Local directory where repositories should be synchronized"

# AutoSyncEnabled - Boolean validation.
$autoSyncValue = if ($null -ne $configFromFile -and $null -ne $configFromFile.AutoSyncEnabled) { [bool]$configFromFile.AutoSyncEnabled } else { $script:DevDirManagerConfigDefaults["System.AutoSyncEnabled"] }
Set-DevDirManagerConfigItem -Name "System.AutoSyncEnabled" -Value $autoSyncValue -Validation "bool" -Description "Enable or disable automatic synchronization"

# SyncIntervalMinutes - Integer validation (positive integer).
$syncIntervalValue = if ($configFromFile -and $configFromFile.SyncIntervalMinutes) { [int]$configFromFile.SyncIntervalMinutes } else { $script:DevDirManagerConfigDefaults["System.SyncIntervalMinutes"] }
if ($syncIntervalValue -lt 1) { $syncIntervalValue = 1 }
if ($syncIntervalValue -gt 1440) { $syncIntervalValue = 1440 }
Set-DevDirManagerConfigItem -Name "System.SyncIntervalMinutes" -Value $syncIntervalValue -Validation "integerpositive" -Description "Interval in minutes between automatic sync operations (default: 360 = 6 hours)"

# LastSyncTime - No handler (set programmatically only).
$lastSyncTimeValue = $null
if ($configFromFile -and $configFromFile.LastSyncTime -is [string] -and -not [string]::IsNullOrWhiteSpace($configFromFile.LastSyncTime)) {
    try {
        $lastSyncTimeValue = [datetime]::Parse($configFromFile.LastSyncTime)
    } catch {
        $lastSyncTimeValue = $null
    }
}
Set-DevDirManagerConfigItem -Name "System.LastSyncTime" -Value $lastSyncTimeValue -Description "Timestamp of last sync operation" -NoHandler

# LastSyncResult - Optional string, no handler (set programmatically only).
$lastSyncResultValue = if ($configFromFile -and $configFromFile.LastSyncResult) { $configFromFile.LastSyncResult } else { $script:DevDirManagerConfigDefaults["System.LastSyncResult"] }
Set-DevDirManagerConfigItem -Name "System.LastSyncResult" -Value $lastSyncResultValue -Description "Result of last sync operation" -NoHandler

#endregion Load configuration from JSON file


#region -- Manual configuration file creation

# Create JSON configuration file with current values if it doesn't exist.
# PSFramework handlers are only executed when values CHANGE, not during -Initialize.
# Therefore, we must manually create the file during module load if it's missing.
if (-not (Test-Path -Path $script:DevDirManagerConfigPath -PathType Leaf)) {
    Write-PSFMessage -Level Verbose -String "DevDirSettingsImport.CreateDefaultConfig" -StringValues @($script:DevDirManagerConfigPath) -Tag "DevDirSettingsImport", "Initialize"

    # Ensure directory exists.
    $configDirectory = Split-Path -Path $script:DevDirManagerConfigPath -Parent
    if (-not (Test-Path -Path $configDirectory -PathType Container)) {
        $null = New-Item -Path $configDirectory -ItemType Directory -Force
    }

    # Build configuration object from current PSFConfig values.
    $configExport = [ordered]@{
        RepositoryListPath  = Get-PSFConfigValue -FullName "DevDirManager.System.RepositoryListPath"
        LocalDevDirectory   = Get-PSFConfigValue -FullName "DevDirManager.System.LocalDevDirectory"
        AutoSyncEnabled     = Get-PSFConfigValue -FullName "DevDirManager.System.AutoSyncEnabled"
        SyncIntervalMinutes = Get-PSFConfigValue -FullName "DevDirManager.System.SyncIntervalMinutes"
        LastSyncTime        = Get-PSFConfigValue -FullName "DevDirManager.System.LastSyncTime"
        LastSyncResult      = Get-PSFConfigValue -FullName "DevDirManager.System.LastSyncResult"
    }

    # Convert datetime to string for JSON serialization.
    if ($configExport.LastSyncTime -is [datetime]) {
        $configExport.LastSyncTime = $configExport.LastSyncTime.ToString("o")
    }

    # Write configuration to JSON file.
    $configExport | ConvertTo-Json -Depth 3 | Set-Content -Path $script:DevDirManagerConfigPath -Encoding UTF8 -Force

    Write-PSFMessage -Level Verbose -String "DevDirSettingsImport.ConfigFileCreated" -StringValues @($script:DevDirManagerConfigPath) -Tag "DevDirSettingsImport", "Initialize"
}

#endregion Manual configuration file creation


#region -- AutoSyncEnabled validation

# Validate AutoSyncEnabled consistency with scheduled task.
# Check for configuration/task state inconsistencies.
$taskName = $script:DevDirManagerScheduledTaskName
$existingTask = Get-ScheduledTask -TaskPath "\" -TaskName $taskName -ErrorAction SilentlyContinue

if ($autoSyncValue -eq $true) {
    # AutoSyncEnabled is true - task should exist and be enabled.
    if (-not $existingTask) {
        Write-PSFMessage -Level Warning -String "DevDirSettingsImport.AutoSyncInconsistent.TaskMissing" -StringValues @($taskName) -Tag "DevDirSettingsImport", "Warning"
    } elseif ($existingTask.State -eq "Disabled") {
        Write-PSFMessage -Level Warning -String "DevDirSettingsImport.AutoSyncInconsistent.TaskDisabled" -StringValues @($taskName) -Tag "DevDirSettingsImport", "Warning"
    }
} else {
    # AutoSyncEnabled is false - task should not exist or should be disabled.
    if ($existingTask -and $existingTask.State -ne "Disabled") {
        Write-PSFMessage -Level Warning -String "DevDirSettingsImport.AutoSyncInconsistent.TaskExists" -StringValues @($taskName) -Tag "DevDirSettingsImport", "Warning"
    }
}

#endregion AutoSyncEnabled validation

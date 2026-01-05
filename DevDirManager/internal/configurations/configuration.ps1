<#
This is an example configuration file

By default, it is enough to have a single one of them,
however if you have enough configuration settings to justify having multiple copies of it,
feel totally free to split them into multiple files.

# Example Configuration
Set-PSFConfig -Module 'DevDirManager' -Name 'Example.Setting' -Value 10 -Initialize -Validation 'integer' -Handler { } -Description "Example configuration setting. Your module can then use the setting using 'Get-PSFConfigValue'"
#>

Set-PSFConfig -Module 'DevDirManager' -Name 'Import.DoDotSource' -Value $false -Initialize -Validation 'bool' -Description "Whether the module files should be dotsourced on import. By default, the files of this module are read as string value and invoked, which is faster but worse on debugging."
Set-PSFConfig -Module 'DevDirManager' -Name 'Import.IndividualFiles' -Value $false -Initialize -Validation 'bool' -Description "Whether the module files should be imported individually. During the module build, all module code is compiled into few files, which are imported instead by default. Loading the compiled versions is faster, using the individual files is easier for debugging and testing out adjustments."


# Git executable path
Set-PSFConfig -Module 'DevDirManager' -Name 'Git.Executable' -Value 'git.exe' -Initialize -Validation 'string' -Description "Path to the git executable. Defaults to 'git.exe' which assumes git is in PATH."


# Default Git remote name
Set-PSFConfig -Module 'DevDirManager' -Name 'Git.RemoteName' -Value 'origin' -Initialize -Validation 'string' -Description "Default Git remote name to use when scanning repositories or synchronizing. Defaults to 'origin'."


# Default output format for repository lists
Set-PSFConfig -Module 'DevDirManager' -Name 'DefaultOutputFormat' -Value 'CSV' -Initialize -Validation 'string' -Description "Default format for exporting/importing repository lists. Valid values: CSV, JSON, XML. Defaults to 'CSV'."


# Determine the correct PowerShell data folder based on version.
# PowerShell 7+ (Core) uses a different location than Windows PowerShell 5.1.
if ($PSVersionTable.PSVersion.Major -ge 6) {
    # PowerShell 7+ (Core) stores user data in Microsoft\PowerShell.
    $local:_powerShellDataFolder = Join-Path -Path $env:LOCALAPPDATA -ChildPath "Microsoft\PowerShell"
} else {
    # Windows PowerShell 5.1 stores user data in Microsoft\Windows\PowerShell.
    $local:_powerShellDataFolder = Join-Path -Path $env:LOCALAPPDATA -ChildPath "Microsoft\Windows\PowerShell"
}
Set-PSFConfig -Module 'DevDirManager' -Name 'SettingsPath' -Value (Join-Path -Path $local:_powerShellDataFolder -ChildPath "DevDirManagerConfiguration.json") -Initialize -Validation 'string' -Description "Path to the DevDirManager settings JSON file. Determined automatically based on PowerShell version."


# Build the scheduled task name with user context and PowerShell version.
# This ensures unique task names in multi-user environments and when both PS5 and PS7 are used.
Set-PSFConfig -Module 'DevDirManager' -Name 'ScheduledTaskName' -Value "DevDirManager_Sync_$($env:USERNAME)_PS$($PSVersionTable.PSVersion.Major)" -Initialize -Validation 'string' -Description "Name of the Windows scheduled task for automatic repository synchronization. Unique per user and PowerShell version."


# Initialize settings file if missing
# Check if settings file exists and create it with default values if missing.
# This ensures the configuration file exists when the module is loaded.
if (-not (Test-Path -Path (Get-PSFConfigValue -FullName "DevDirManager.SettingsPath") -PathType Leaf)) {
    Write-PSFMessage -Level Verbose -ModuleName "DevDirManager" -String "DevDirSettingsImport.CreateDefaultConfig" -StringValues @((Get-PSFConfigValue -FullName "DevDirManager.SettingsPath")) -Tag "Configuration", "Initialize"

    # Call Set-DevDirectorySetting with -Reset to create the file with defaults.
    Set-DevDirectorySetting -Reset

    Write-PSFMessage -Level Verbose -ModuleName "DevDirManager" -String "DevDirSettingsImport.ConfigFileCreated" -StringValues @((Get-PSFConfigValue -FullName "DevDirManager.SettingsPath")) -Tag "Configuration", "Initialize"
} else {
    Write-PSFMessage -Level Debug -ModuleName "DevDirManager" -String "DevDirSettingsImport.ConfigLoaded" -StringValues @((Get-PSFConfigValue -FullName "DevDirManager.SettingsPath")) -Tag "Configuration", "Load"
}

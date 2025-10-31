﻿<#
This is an example configuration file

By default, it is enough to have a single one of them,
however if you have enough configuration settings to justify having multiple copies of it,
feel totally free to split them into multiple files.
#>

<#
# Example Configuration
Set-PSFConfig -Module 'DevDirManager' -Name 'Example.Setting' -Value 10 -Initialize -Validation 'integer' -Handler { } -Description "Example configuration setting. Your module can then use the setting using 'Get-PSFConfigValue'"
#>

# Git executable path
Set-PSFConfig -Module 'DevDirManager' -Name 'Git.Executable' -Value 'git.exe' -Initialize -Validation 'string' -Description "Path to the git executable. Defaults to 'git.exe' which assumes git is in PATH."

# Default Git remote name
Set-PSFConfig -Module 'DevDirManager' -Name 'Git.RemoteName' -Value 'origin' -Initialize -Validation 'string' -Description "Default Git remote name to use when scanning repositories or synchronizing. Defaults to 'origin'."

# Default output format for repository lists
Set-PSFConfig -Module 'DevDirManager' -Name 'DefaultOutputFormat' -Value 'CSV' -Initialize -Validation 'string' -Description "Default format for exporting/importing repository lists. Valid values: CSV, JSON, XML. Defaults to 'CSV'."

Set-PSFConfig -Module 'DevDirManager' -Name 'Import.DoDotSource' -Value $false -Initialize -Validation 'bool' -Description "Whether the module files should be dotsourced on import. By default, the files of this module are read as string value and invoked, which is faster but worse on debugging."
Set-PSFConfig -Module 'DevDirManager' -Name 'Import.IndividualFiles' -Value $false -Initialize -Validation 'bool' -Description "Whether the module files should be imported individually. During the module build, all module code is compiled into few files, which are imported instead by default. Loading the compiled versions is faster, using the individual files is easier for debugging and testing out adjustments."
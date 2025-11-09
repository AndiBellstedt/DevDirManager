<#
.DESCRIPTION
    This test verifies the integrity and requirements of localization files:
    1. Every localization folder must contain an about help file
    2. String format placeholders should use double quotes (""{0}"") instead of single quotes ('{0}')
#>

$moduleRoot = (Resolve-Path "$global:testroot\..").Path

Describe "Verifying localization folder requirements" {
    Context "Validating localization folders" {
        $localizationFolders = Get-ChildItem -Path $moduleRoot -Directory | Where-Object { $_.Name -match '^[a-z]{2}-[a-z]{2}$' }

        foreach ($folder in $localizationFolders) {
            $folderName = $folder.Name
            $aboutFile = Join-Path -Path $folder.FullName -ChildPath "about_DevDirManager.help.txt"

            It "[$folderName] Should contain about_DevDirManager.help.txt" -TestCases @{ aboutFile = $aboutFile; folderName = $folderName } {
                Test-Path -Path $aboutFile -PathType Leaf | Should -Be $true
            }
        }
    }

    Context "Validating strings.psd1 format" {
        $localizationFolders = Get-ChildItem -Path $moduleRoot -Directory | Where-Object { $_.Name -match '^[a-z]{2}-[a-z]{2}$' }

        foreach ($folder in $localizationFolders) {
            $folderName = $folder.Name
            $stringsFile = Join-Path -Path $folder.FullName -ChildPath "strings.psd1"

            if (Test-Path -Path $stringsFile -PathType Leaf) {
                $content = Get-Content -Path $stringsFile -Raw

                # Check for double quotes around placeholders like ""{0}"", ""{1}"", etc.
                # These should be single quotes like '{0}', '{1}', etc.
                $doubleQuotedPlaceholders = [regex]::Matches($content, '""(\{[0-9]+\})""')

                It "[$folderName\strings.psd1] Should not contain double-quoted placeholders like ""{0}""" -TestCases @{
                    folderName  = $folderName
                    matches     = $doubleQuotedPlaceholders
                    stringsFile = $stringsFile
                } {
                    if ($matches.Count -gt 0) {
                        $examples = ($matches | Select-Object -First 3 | ForEach-Object { $_.Value }) -join ", "
                        $message = "Found $($matches.Count) double-quoted placeholders. Examples: $examples. Use single quotes instead: '{0}'"
                        $matches.Count | Should -Be 0 -Because $message
                    } else {
                        $matches.Count | Should -Be 0
                    }
                }
            }
        }
    }
}

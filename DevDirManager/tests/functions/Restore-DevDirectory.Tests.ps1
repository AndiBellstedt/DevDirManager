Describe "Restore-DevDirectory" -Tag "PublicFunction", "Restore" {

    Context "Parameter Contract" {

        BeforeAll {
            $command = Get-Command -Name 'Restore-DevDirectory'
            $parameters = $command.Parameters
        }

        Context "Restore-DevDirectory - Parameter: InputObject" {
            BeforeAll { $p = $parameters['InputObject'] }
            It "Exists" { $p | Should -Not -BeNullOrEmpty }
            It "Is of type [psobject[]]" { $p.ParameterType.FullName | Should -Be 'System.Management.Automation.PSObject[]' }
            It "Is Mandatory" { $p.Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -Contain $true }
            It "Has ValidateNotNull" { $p.Attributes.Where({ $_ -is [System.Management.Automation.ValidateNotNullAttribute] }) | Should -Not -BeNullOrEmpty }
            It "Accepts ValueFromPipeline" { $p.Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).ValueFromPipeline | Should -Contain $true }
            It "Accepts ValueFromPipelineByPropertyName" { $p.Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).ValueFromPipelineByPropertyName | Should -Contain $true }
        }

        Context "Restore-DevDirectory - Parameter: DestinationPath" {
            BeforeAll { $p = $parameters['DestinationPath'] }
            It "Exists" { $p | Should -Not -BeNullOrEmpty }
            It "Is of type [string]" { $p.ParameterType.FullName | Should -Be 'System.String' }
            It "Is not Mandatory" { $p.Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -Not -Contain $true }
            It "Has ValidateNotNullOrEmpty" { $p.Attributes.Where({ $_ -is [System.Management.Automation.ValidateNotNullOrEmptyAttribute] }) | Should -Not -BeNullOrEmpty }
        }

        Context "Restore-DevDirectory - Parameter: Force" {
            BeforeAll { $p = $parameters['Force'] }
            It "Exists" { $p | Should -Not -BeNullOrEmpty }
            It "Is of type [switch]" { $p.ParameterType.FullName | Should -Be 'System.Management.Automation.SwitchParameter' }
            It "Is not Mandatory" { $p.Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -Not -Contain $true }
        }

        Context "Restore-DevDirectory - Parameter: SkipExisting" {
            BeforeAll { $p = $parameters['SkipExisting'] }
            It "Exists" { $p | Should -Not -BeNullOrEmpty }
            It "Is of type [switch]" { $p.ParameterType.FullName | Should -Be 'System.Management.Automation.SwitchParameter' }
            It "Is not Mandatory" { $p.Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -Not -Contain $true }
        }

        Context "Restore-DevDirectory - Parameter: ShowGitOutput" {
            BeforeAll { $p = $parameters['ShowGitOutput'] }
            It "Exists" { $p | Should -Not -BeNullOrEmpty }
            It "Is of type [switch]" { $p.ParameterType.FullName | Should -Be 'System.Management.Automation.SwitchParameter' }
            It "Is not Mandatory" { $p.Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -Not -Contain $true }
        }

    }

    Context "Functionality" {

        BeforeAll {
            $script:TestRoot = Join-Path -Path $TestDrive -ChildPath 'RestoreTests'
            New-Item -Path $script:TestRoot -ItemType Directory -Force | Out-Null

            $script:RestoreTarget = Join-Path -Path $script:TestRoot -ChildPath 'Target'
            New-Item -Path $script:RestoreTarget -ItemType Directory -Force | Out-Null

            # --- Setup PSDrive ---
            $script:PSDriveName = "DEVDIRMGR_RESTORE_TEST"
            New-PSDrive -Name $script:PSDriveName -PSProvider FileSystem -Root $script:TestRoot -Scope Global | Out-Null

            # --- Setup Test Repos ---
            $script:TestRepos = @(
                [PSCustomObject]@{
                    PSTypeName         = 'DevDirManager.Repository'
                    RelativePath       = "AccessibleRepo"
                    RemoteUrl          = "https://github.com/PowerShell/PowerShell.git"
                    RemoteName         = "origin"
                    IsRemoteAccessible = $true
                }
                [PSCustomObject]@{
                    PSTypeName         = 'DevDirManager.Repository'
                    RelativePath       = "InaccessibleRepo"
                    RemoteUrl          = "https://github.com/nonexistent/repo.git"
                    RemoteName         = "origin"
                    IsRemoteAccessible = $false
                }
            )
        }

        AfterAll {
            if (Get-PSDrive -Name $script:PSDriveName -ErrorAction SilentlyContinue) {
                Remove-PSDrive -Name $script:PSDriveName -Force -ErrorAction SilentlyContinue
            }
        }

        Context "PSDrive Support" {

            It "Should handle PSDrive as DestinationPath with -WhatIf" {
                $psdrivePath = "$($script:PSDriveName):\Target"
                { $script:TestRepos | Restore-DevDirectory -DestinationPath $psdrivePath -WhatIf -InformationAction SilentlyContinue *>$null } | Should -Not -Throw
            }

        }

        Context "Remote Accessibility" {

            It "Should skip repositories with IsRemoteAccessible = false in WhatIf" {
                $whatIfOutput = $script:TestRepos | Restore-DevDirectory -DestinationPath $script:RestoreTarget -WhatIf -InformationVariable infoVar -InformationAction SilentlyContinue -WarningVariable warnVar -WarningAction SilentlyContinue 2>&1
                $allOutput = ($infoVar + $warnVar + $whatIfOutput) | Out-String

                $allOutput | Should -Match "AccessibleRepo"
                $allOutput | Should -Match "InaccessibleRepo"
            }

            It "Should not throw errors for inaccessible repositories" {
                { $script:TestRepos | Restore-DevDirectory -DestinationPath $script:RestoreTarget -WhatIf -ErrorAction Stop } | Should -Not -Throw
            }

        }

    }

}

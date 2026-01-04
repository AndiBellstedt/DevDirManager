Describe "Sync-DevDirectoryList" -Tag "PublicFunction", "Sync" {

    Context "Parameter Contract" {
        BeforeAll {
            $command = Get-Command -Name 'Sync-DevDirectoryList'
            $parameters = $command.Parameters
        }

        Context "Parameter: DirectoryPath" {
            BeforeAll { $p = $parameters['DirectoryPath'] }
            It "Exists" { $p | Should -Not -BeNullOrEmpty }
            It "Is of type [string]" { $p.ParameterType.FullName | Should -Be 'System.String' }
            It "Is not Mandatory" { $p.Attributes.Where({$_ -is [System.Management.Automation.ParameterAttribute]}).Mandatory | Should -Not -Contain $true }
            It "Has ValidateNotNullOrEmpty" { $p.Attributes.Where({$_ -is [System.Management.Automation.ValidateNotNullOrEmptyAttribute]}) | Should -Not -BeNullOrEmpty }
            It "Accepts ValueFromPipelineByPropertyName" { $p.Attributes.Where({$_ -is [System.Management.Automation.ParameterAttribute]}).ValueFromPipelineByPropertyName | Should -Contain $true }
        }

        Context "Parameter: RepositoryListPath" {
            BeforeAll { $p = $parameters['RepositoryListPath'] }
            It "Exists" { $p | Should -Not -BeNullOrEmpty }
            It "Is of type [string]" { $p.ParameterType.FullName | Should -Be 'System.String' }
            It "Is Mandatory" { $p.Attributes.Where({$_ -is [System.Management.Automation.ParameterAttribute]}).Mandatory | Should -Contain $true }
            It "Has ValidateNotNullOrEmpty" { $p.Attributes.Where({$_ -is [System.Management.Automation.ValidateNotNullOrEmptyAttribute]}) | Should -Not -BeNullOrEmpty }
            It "Accepts ValueFromPipelineByPropertyName" { $p.Attributes.Where({$_ -is [System.Management.Automation.ParameterAttribute]}).ValueFromPipelineByPropertyName | Should -Contain $true }
        }

        Context "Parameter: Force" {
            BeforeAll { $p = $parameters['Force'] }
            It "Exists" { $p | Should -Not -BeNullOrEmpty }
            It "Is of type [switch]" { $p.ParameterType.FullName | Should -Be 'System.Management.Automation.SwitchParameter' }
            It "Is not Mandatory" { $p.Attributes.Where({$_ -is [System.Management.Automation.ParameterAttribute]}).Mandatory | Should -Not -Contain $true }
        }

        Context "Parameter: SkipExisting" {
            BeforeAll { $p = $parameters['SkipExisting'] }
            It "Exists" { $p | Should -Not -BeNullOrEmpty }
            It "Is of type [switch]" { $p.ParameterType.FullName | Should -Be 'System.Management.Automation.SwitchParameter' }
            It "Is not Mandatory" { $p.Attributes.Where({$_ -is [System.Management.Automation.ParameterAttribute]}).Mandatory | Should -Not -Contain $true }
        }

        Context "Parameter: ShowGitOutput" {
            BeforeAll { $p = $parameters['ShowGitOutput'] }
            It "Exists" { $p | Should -Not -BeNullOrEmpty }
            It "Is of type [switch]" { $p.ParameterType.FullName | Should -Be 'System.Management.Automation.SwitchParameter' }
            It "Is not Mandatory" { $p.Attributes.Where({$_ -is [System.Management.Automation.ParameterAttribute]}).Mandatory | Should -Not -Contain $true }
        }

        Context "Parameter: PassThru" {
            BeforeAll { $p = $parameters['PassThru'] }
            It "Exists" { $p | Should -Not -BeNullOrEmpty }
            It "Is of type [switch]" { $p.ParameterType.FullName | Should -Be 'System.Management.Automation.SwitchParameter' }
            It "Is not Mandatory" { $p.Attributes.Where({$_ -is [System.Management.Automation.ParameterAttribute]}).Mandatory | Should -Not -Contain $true }
        }
    }

    BeforeAll {
        $script:TestRoot = Join-Path -Path $TestDrive -ChildPath 'SyncTests'
        New-Item -Path $script:TestRoot -ItemType Directory -Force | Out-Null

        $script:SyncRoot = Join-Path -Path $script:TestRoot -ChildPath 'SyncRoot'
        New-Item -Path $script:SyncRoot -ItemType Directory -Force | Out-Null

        # --- Setup PSDrive ---
        $script:PSDriveName = "DEVDIRMGR_SYNC_TEST"
        New-PSDrive -Name $script:PSDriveName -PSProvider FileSystem -Root $script:TestRoot -Scope Global | Out-Null

        # --- Setup Sync List ---
        $script:SyncListPath = Join-Path -Path $script:TestRoot -ChildPath "sync-list.json"
        $syncRepos = @(
            [PSCustomObject]@{
                PSTypeName         = 'DevDirManager.Repository'
                RootPath           = $script:SyncRoot
                RelativePath       = "Repo1"
                FullPath           = (Join-Path $script:SyncRoot "Repo1")
                RemoteUrl          = "https://github.com/PowerShell/PowerShell.git"
                RemoteName         = "origin"
                StatusDate         = (Get-Date)
                IsRemoteAccessible = $true
            }
            [PSCustomObject]@{
                PSTypeName         = 'DevDirManager.Repository'
                RootPath           = $script:SyncRoot
                RelativePath       = "Repo2"
                FullPath           = (Join-Path $script:SyncRoot "Repo2")
                RemoteUrl          = "https://github.com/nonexistent/repo.git"
                RemoteName         = "origin"
                StatusDate         = (Get-Date)
                IsRemoteAccessible = $false
            }
        )
        $syncRepos | Export-DevDirectoryList -Path $script:SyncListPath
    }

    AfterAll {
        if (Get-PSDrive -Name $script:PSDriveName -ErrorAction SilentlyContinue) {
            Remove-PSDrive -Name $script:PSDriveName -Force -ErrorAction SilentlyContinue
        }
    }

    Context "PSDrive Support" {

        It "Should handle PSDrive as DirectoryPath with -WhatIf" {
            $psdrivePath = "$($script:PSDriveName):\SyncRoot"
            { Sync-DevDirectoryList -DirectoryPath $psdrivePath -RepositoryListPath $script:SyncListPath -WhatIf -InformationAction SilentlyContinue } | Should -Not -Throw
        }

        It "Should handle PSDrive as RepositoryListPath with -WhatIf" {
            $psdriveListPath = "$($script:PSDriveName):\sync-list.json"
            { Sync-DevDirectoryList -DirectoryPath $script:SyncRoot -RepositoryListPath $psdriveListPath -WhatIf -InformationAction SilentlyContinue } | Should -Not -Throw
        }

    }

    Context "Remote Accessibility" {

        It "Should skip repositories with IsRemoteAccessible = false in WhatIf" {
            # Verify list file content first
            $list = Import-DevDirectoryList -Path $script:SyncListPath
            $list.Count | Should -Be 2

            $whatIfOutput = Sync-DevDirectoryList -DirectoryPath $script:SyncRoot -RepositoryListPath $script:SyncListPath -WhatIf -InformationVariable infoVar -WarningVariable warnVar -Verbose 2>&1
            $allOutput = ($infoVar + $warnVar + $whatIfOutput) | Out-String

            # Debug output if empty
            if (-not $allOutput) {
                Write-Warning "AllOutput is empty. WarnVar count: $($warnVar.Count). InfoVar count: $($infoVar.Count)."
            }

            # ShouldProcess message should indicate 1 repository to clone (Repo1)
            # The message is "Clone 1 repository/repositories from list"
            # Note: WhatIf output might not be captured in $allOutput depending on host, but the Warning should be there.
            # If we can't capture WhatIf easily, we rely on the warning for Repo2 and the absence of warning for Repo1.

            $allOutput | Should -Match "Repo2" # Warning should be present
            $allOutput | Should -Not -Match "Repo1" # Repo1 should be processed silently (or in WhatIf message which doesn't name it)

            # To be sure, we can check if warnVar contains Repo2 but not Repo1
            $warnVar | ForEach-Object { $_.ToString() } | Should -Match "Repo2"
            $warnVar | ForEach-Object { $_.ToString() } | Should -Not -Match "Repo1"
        }

    }

}

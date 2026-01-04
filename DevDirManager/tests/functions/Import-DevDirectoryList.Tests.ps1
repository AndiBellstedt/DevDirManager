Describe "Import-DevDirectoryList" -Tag "PublicFunction", "Import" {

    Context "Parameter Contract" {
        BeforeAll {
            $command = Get-Command -Name 'Import-DevDirectoryList'
            $parameters = $command.Parameters
        }

        Context "Parameter: Path" {
            BeforeAll { $p = $parameters['Path'] }
            It "Exists" { $p | Should -Not -BeNullOrEmpty }
            It "Is of type [string]" { $p.ParameterType.FullName | Should -Be 'System.String' }
            It "Is Mandatory" { $p.Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -Contain $true }
            It "Has ValidateNotNullOrEmpty" { $p.Attributes.Where({ $_ -is [System.Management.Automation.ValidateNotNullOrEmptyAttribute] }) | Should -Not -BeNullOrEmpty }
        }

        Context "Parameter: Format" {
            BeforeAll { $p = $parameters['Format'] }
            It "Exists" { $p | Should -Not -BeNullOrEmpty }
            It "Is of type [string]" { $p.ParameterType.FullName | Should -Be 'System.String' }
            It "Is not Mandatory" { $p.Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -Not -Contain $true }
            It "Has ValidateSet" {
                $set = $p.Attributes.Where({ $_ -is [System.Management.Automation.ValidateSetAttribute] })
                $set | Should -Not -BeNullOrEmpty
                $set.ValidValues | Should -Contain "CSV"
                $set.ValidValues | Should -Contain "JSON"
                $set.ValidValues | Should -Contain "XML"
            }
        }
    }

    BeforeAll {
        $script:TestRoot = Join-Path -Path $TestDrive -ChildPath 'ImportTests'
        New-Item -Path $script:TestRoot -ItemType Directory -Force | Out-Null

        # --- Setup Test Repositories for Round Trip ---
        $script:TestRepositories = @(
            [PSCustomObject]@{
                PSTypeName         = 'DevDirManager.Repository'
                RootPath           = 'C:\TestRoot1'
                RelativePath       = 'Project\Repo1'
                FullPath           = 'C:\TestRoot1\Project\Repo1'
                RemoteName         = 'origin'
                RemoteUrl          = 'https://github.com/user/repo1.git'
                UserName           = 'User1'
                UserEmail          = 'user1@test.com'
                StatusDate         = [DateTime]::Now
                IsRemoteAccessible = $true
            }
        )
        foreach ($repo in $script:TestRepositories) {
            $repo.PSObject.TypeNames.Insert(0, 'DevDirManager.Repository')
        }

        # --- Setup PSDrive ---
        $script:PSDriveName = "DEVDIRMGR_IMPORT_TEST"
        New-PSDrive -Name $script:PSDriveName -PSProvider FileSystem -Root $script:TestRoot -Scope Global | Out-Null
    }

    AfterAll {
        if (Get-PSDrive -Name $script:PSDriveName -ErrorAction SilentlyContinue) {
            Remove-PSDrive -Name $script:PSDriveName -Force -ErrorAction SilentlyContinue
        }
    }

    Context "CSV Import" {
        It "Should import from CSV and preserve properties" {
            $path = Join-Path $script:TestRoot "test.csv"
            $script:TestRepositories | Export-DevDirectoryList -Path $path -Format CSV

            $imported = @(Import-DevDirectoryList -Path $path -Format CSV)
            $imported.Count | Should -Be $script:TestRepositories.Count
            $imported[0].RemoteUrl | Should -Be $script:TestRepositories[0].RemoteUrl
        }
    }

    Context "JSON Import" {
        It "Should import from JSON and preserve properties" {
            $path = Join-Path $script:TestRoot "test.json"
            $script:TestRepositories | Export-DevDirectoryList -Path $path -Format JSON

            $imported = @(Import-DevDirectoryList -Path $path -Format JSON)
            $imported.Count | Should -Be $script:TestRepositories.Count
            $imported[0].RemoteUrl | Should -Be $script:TestRepositories[0].RemoteUrl
        }
    }

    Context "XML Import" {
        It "Should import from XML and preserve properties" {
            $path = Join-Path $script:TestRoot "test.xml"
            $script:TestRepositories | Export-DevDirectoryList -Path $path -Format XML

            $imported = @(Import-DevDirectoryList -Path $path -Format XML)
            $imported.Count | Should -Be $script:TestRepositories.Count
            $imported[0].RemoteUrl | Should -Be $script:TestRepositories[0].RemoteUrl
        }
    }

    Context "PSDrive Import" {
        It "Should import from PSDrive path" {
            $path = Join-Path $script:TestRoot "psdrive.json"
            $script:TestRepositories | Export-DevDirectoryList -Path $path

            $psdrivePath = "$($script:PSDriveName):\psdrive.json"
            $imported = @(Import-DevDirectoryList -Path $psdrivePath)
            $imported.Count | Should -Be $script:TestRepositories.Count
        }
    }

    Context "Property Preservation" {
        It "Should preserve RelativePath single backslashes" {
            $path = Join-Path $script:TestRoot "relpath.json"
            $script:TestRepositories | Export-DevDirectoryList -Path $path
            $imported = Import-DevDirectoryList -Path $path
            $imported[0].RelativePath | Should -Not -Match '\\\\\\\\'
            $imported[0].RelativePath | Should -Be $script:TestRepositories[0].RelativePath
        }

        It "Should preserve IsRemoteAccessible" {
            $path = Join-Path $script:TestRoot "remote.json"
            $script:TestRepositories | Export-DevDirectoryList -Path $path
            $imported = Import-DevDirectoryList -Path $path
            $imported[0].IsRemoteAccessible | Should -Be $true
        }

        It "Should preserve UserName, UserEmail, StatusDate" {
            $path = Join-Path $script:TestRoot "user.json"
            $script:TestRepositories | Export-DevDirectoryList -Path $path
            $imported = Import-DevDirectoryList -Path $path
            $imported[0].UserName | Should -Be $script:TestRepositories[0].UserName
            $imported[0].UserEmail | Should -Be $script:TestRepositories[0].UserEmail
            $imported[0].StatusDate | Should -BeOfType [datetime]
        }
    }

}

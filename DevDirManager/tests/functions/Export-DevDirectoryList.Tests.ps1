Describe "Export-DevDirectoryList" -Tag "PublicFunction", "Export" {

    Context "Parameter Contract" {
        BeforeAll {
            $command = Get-Command -Name 'Export-DevDirectoryList'
            $parameters = $command.Parameters
        }

        Context "Export-DevDirectoryList - Parameter: InputObject" {
            BeforeAll { $p = $parameters['InputObject'] }
            It "Exists" { $p | Should -Not -BeNullOrEmpty }
            It "Is of type [psobject]" { $p.ParameterType.FullName | Should -Be 'System.Management.Automation.PSObject' }
            It "Is Mandatory" { $p.Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -Contain $true }
            It "Has ValidateNotNull" { $p.Attributes.Where({ $_ -is [System.Management.Automation.ValidateNotNullAttribute] }) | Should -Not -BeNullOrEmpty }
            It "Accepts ValueFromPipeline" { $p.Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).ValueFromPipeline | Should -Contain $true }
            It "Accepts ValueFromPipelineByPropertyName" { $p.Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).ValueFromPipelineByPropertyName | Should -Contain $true }
        }

        Context "Export-DevDirectoryList - Parameter: Path" {
            BeforeAll { $p = $parameters['Path'] }
            It "Exists" { $p | Should -Not -BeNullOrEmpty }
            It "Is of type [string]" { $p.ParameterType.FullName | Should -Be 'System.String' }
            It "Is Mandatory" { $p.Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -Contain $true }
            It "Has ValidateNotNullOrEmpty" { $p.Attributes.Where({ $_ -is [System.Management.Automation.ValidateNotNullOrEmptyAttribute] }) | Should -Not -BeNullOrEmpty }
        }

        Context "Export-DevDirectoryList - Parameter: Format" {
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

    Context "Functionality" {

        BeforeAll {
            $script:TestRoot = Join-Path -Path $TestDrive -ChildPath 'ExportTests'
            New-Item -Path $script:TestRoot -ItemType Directory -Force | Out-Null

            # --- Setup Test Repositories ---
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
                    StatusDate         = Get-Date
                    IsRemoteAccessible = $true
                }
            )
            foreach ($repo in $script:TestRepositories) {
                $repo.PSObject.TypeNames.Insert(0, 'DevDirManager.Repository')
            }

            # --- Setup PSDrive ---
            $script:PSDriveName = "DEVDIRMGR_EXPORT_TEST"
            New-PSDrive -Name $script:PSDriveName -PSProvider FileSystem -Root $script:TestRoot -Scope Global | Out-Null
        }

        AfterAll {
            if (Get-PSDrive -Name $script:PSDriveName -ErrorAction SilentlyContinue) {
                Remove-PSDrive -Name $script:PSDriveName -Force -ErrorAction SilentlyContinue
            }
        }

        Context "CSV Export" {
            It "Should export to CSV with explicit format parameter" {
                $path = Join-Path $script:TestRoot "test.csv"
                $script:TestRepositories | Export-DevDirectoryList -Path $path -Format CSV
                $path | Should -Exist
                $content = Get-Content $path -Raw
                $content | Should -Match '^"?RootPath"?,'
            }
        }

        Context "JSON Export" {
            It "Should export to JSON with explicit format parameter" {
                $path = Join-Path $script:TestRoot "test.json"
                $script:TestRepositories | Export-DevDirectoryList -Path $path -Format JSON
                $path | Should -Exist
                $content = Get-Content $path -Raw
                $content | Should -Match '^\s*[\[\{]'
            }
        }

        Context "XML Export" {
            It "Should export to XML with explicit format parameter" {
                $path = Join-Path $script:TestRoot "test.xml"
                $script:TestRepositories | Export-DevDirectoryList -Path $path -Format XML
                $path | Should -Exist
                $content = Get-Content $path -Raw
                $content | Should -Match '^\s*<'
            }
        }

        Context "PSDrive Export" {
            It "Should export to PSDrive path without errors" {
                $exportPath = "$($script:PSDriveName):\export-psdrive.json"
                { $script:TestRepositories | Export-DevDirectoryList -Path $exportPath } | Should -Not -Throw
                Test-Path (Join-Path $script:TestRoot "export-psdrive.json") | Should -BeTrue
            }
        }

        Context "Auto-Detection" {
            It "Should auto-detect CSV format from .csv extension" {
                $path = Join-Path $script:TestRoot "auto.csv"
                $script:TestRepositories | Export-DevDirectoryList -Path $path
                Get-Content $path -Raw | Should -Match '^"?RootPath"?,'
            }

            It "Should auto-detect JSON format from .json extension" {
                $path = Join-Path $script:TestRoot "auto.json"
                $script:TestRepositories | Export-DevDirectoryList -Path $path
                Get-Content $path -Raw | Should -Match '^\s*[\[\{]'
            }
        }

    }
}

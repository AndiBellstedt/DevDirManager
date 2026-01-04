Describe "Publish-DevDirectoryList" -Tag "PublicFunction", "Publish" {

    Context "Parameter Contract" {
        BeforeAll {
            $command = Get-Command -Name 'Publish-DevDirectoryList'
            $parameters = $command.Parameters
        }

        Context "Parameter: Path" {
            BeforeAll { $p = $parameters['Path'] }
            It "Exists" { $p | Should -Not -BeNullOrEmpty }
            It "Is of type [string]" { $p.ParameterType.FullName | Should -Be 'System.String' }
            It "Is Mandatory in FromPath set" { $p.Attributes.Where({$_ -is [System.Management.Automation.ParameterAttribute]}).Mandatory | Should -Contain $true }
            It "Has ValidateNotNullOrEmpty" { $p.Attributes.Where({$_ -is [System.Management.Automation.ValidateNotNullOrEmptyAttribute]}) | Should -Not -BeNullOrEmpty }
        }

        Context "Parameter: InputObject" {
            BeforeAll { $p = $parameters['InputObject'] }
            It "Exists" { $p | Should -Not -BeNullOrEmpty }
            It "Is of type [psobject]" { $p.ParameterType.FullName | Should -Be 'System.Management.Automation.PSObject' }
            It "Is Mandatory in FromInput set" { $p.Attributes.Where({$_ -is [System.Management.Automation.ParameterAttribute]}).Mandatory | Should -Contain $true }
            It "Has ValidateNotNull" { $p.Attributes.Where({$_ -is [System.Management.Automation.ValidateNotNullAttribute]}) | Should -Not -BeNullOrEmpty }
            It "Accepts ValueFromPipeline" { $p.Attributes.Where({$_ -is [System.Management.Automation.ParameterAttribute]}).ValueFromPipeline | Should -Contain $true }
            It "Accepts ValueFromPipelineByPropertyName" { $p.Attributes.Where({$_ -is [System.Management.Automation.ParameterAttribute]}).ValueFromPipelineByPropertyName | Should -Contain $true }
        }

        Context "Parameter: AccessToken" {
            BeforeAll { $p = $parameters['AccessToken'] }
            It "Exists" { $p | Should -Not -BeNullOrEmpty }
            It "Is of type [System.Security.SecureString]" { $p.ParameterType.FullName | Should -Be 'System.Security.SecureString' }
            It "Is Mandatory" { $p.Attributes.Where({$_ -is [System.Management.Automation.ParameterAttribute]}).Mandatory | Should -Contain $true }
            It "Has ValidateNotNull" { $p.Attributes.Where({$_ -is [System.Management.Automation.ValidateNotNullAttribute]}) | Should -Not -BeNullOrEmpty }
        }

        Context "Parameter: GistId" {
            BeforeAll { $p = $parameters['GistId'] }
            It "Exists" { $p | Should -Not -BeNullOrEmpty }
            It "Is of type [string]" { $p.ParameterType.FullName | Should -Be 'System.String' }
            It "Is not Mandatory" { $p.Attributes.Where({$_ -is [System.Management.Automation.ParameterAttribute]}).Mandatory | Should -Not -Contain $true }
            It "Has ValidateNotNullOrEmpty" { $p.Attributes.Where({$_ -is [System.Management.Automation.ValidateNotNullOrEmptyAttribute]}) | Should -Not -BeNullOrEmpty }
        }

        Context "Parameter: Public" {
            BeforeAll { $p = $parameters['Public'] }
            It "Exists" { $p | Should -Not -BeNullOrEmpty }
            It "Is of type [switch]" { $p.ParameterType.FullName | Should -Be 'System.Management.Automation.SwitchParameter' }
            It "Is not Mandatory" { $p.Attributes.Where({$_ -is [System.Management.Automation.ParameterAttribute]}).Mandatory | Should -Not -Contain $true }
        }

        Context "Parameter: ApiUrl" {
            BeforeAll { $p = $parameters['ApiUrl'] }
            It "Exists" { $p | Should -Not -BeNullOrEmpty }
            It "Is of type [string]" { $p.ParameterType.FullName | Should -Be 'System.String' }
            It "Is not Mandatory" { $p.Attributes.Where({$_ -is [System.Management.Automation.ParameterAttribute]}).Mandatory | Should -Not -Contain $true }
            It "Has ValidateNotNullOrEmpty" { $p.Attributes.Where({$_ -is [System.Management.Automation.ValidateNotNullOrEmptyAttribute]}) | Should -Not -BeNullOrEmpty }
        }
    }

    BeforeAll {
        $script:TestRoot = Join-Path -Path $TestDrive -ChildPath 'PublishTests'
        New-Item -Path $script:TestRoot -ItemType Directory -Force | Out-Null

        # --- Setup PSDrive ---
        $script:PSDriveName = "DEVDIRMGR_PUBLISH_TEST"
        New-PSDrive -Name $script:PSDriveName -PSProvider FileSystem -Root $script:TestRoot -Scope Global | Out-Null

        $script:ListPath = Join-Path -Path $script:TestRoot -ChildPath "repos.json"
        $dummy = [PSCustomObject]@{
            PSTypeName   = 'DevDirManager.Repository'
            RootPath     = 'C:\Temp'
            RelativePath = 'Repo'
            FullPath     = 'C:\Temp\Repo'
            RemoteName   = 'origin'
            RemoteUrl    = 'https://github.com/test/repo.git'
            StatusDate   = (Get-Date)
        }
        @($dummy) | Export-DevDirectoryList -Path $script:ListPath
    }

    AfterAll {
        if (Get-PSDrive -Name $script:PSDriveName -ErrorAction SilentlyContinue) {
            Remove-PSDrive -Name $script:PSDriveName -Force -ErrorAction SilentlyContinue
        }
    }

    Context "PSDrive Support" {
        It "Should handle PSDrive path for input file with -WhatIf" {
            $psdrivePath = "$($script:PSDriveName):\repos.json"
            $secureToken = ConvertTo-SecureString -String "dummy-token-12345" -AsPlainText -Force

            { Publish-DevDirectoryList -Path $psdrivePath -AccessToken $secureToken -WhatIf -InformationAction SilentlyContinue } | Should -Not -Throw
        }
    }

}

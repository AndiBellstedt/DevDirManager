Describe "New-DirectoryIfNeeded" -Tag "InternalFunction", "FileSystem" {

    InModuleScope 'DevDirManager' {

        Context "Parameter Contract" {

            BeforeAll {
                $command = Get-Command -Name 'New-DirectoryIfNeeded' -ErrorAction Stop
                $parameters = $command.Parameters
            }

            It "Should have the correct parameter types" {
                $parameters['Path'].ParameterType.Name | Should -Be 'String[]'
            }

            It "Should have the correct mandatory parameters" {
                $parameters['Path'].Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -Contain $true
            }

            It "Should have the correct pipeline attributes" {
                $parameters['Path'].Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).ValueFromPipeline | Should -Contain $true
                $parameters['Path'].Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).ValueFromPipelineByPropertyName | Should -Contain $true
            }

            It "Should have the correct attributes" {
                $parameters['Path'].Attributes.TypeId.Name | Should -Contain 'ValidateNotNullOrEmptyAttribute'
            }

        }

        BeforeEach {
            $script:testDirBase = Join-Path $TestDrive "DirNeededTests"
            if (Test-Path $script:testDirBase) { Remove-Item $script:testDirBase -Recurse -Force }
        }

        AfterAll {
            if (Test-Path $script:testDirBase) {
                Remove-Item -Path $script:testDirBase -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        Context "Directory creation" {

            It "Should create directory if it doesn't exist" {
                $path = Join-Path $script:testDirBase "NewDir"
                New-DirectoryIfNeeded -Path $path
                Test-Path $path -PathType Container | Should -Be $true
            }

            It "Should create nested directories" {
                $path = Join-Path $script:testDirBase "A\B\C"
                New-DirectoryIfNeeded -Path $path
                Test-Path $path -PathType Container | Should -Be $true
            }

            It "Should not fail if directory already exists" {
                $path = Join-Path $script:testDirBase "Existing"
                New-Item -ItemType Directory -Path $path -Force | Out-Null
                { New-DirectoryIfNeeded -Path $path } | Should -Not -Throw
            }

            It "Should handle multiple paths in pipeline" {
                $paths = 'One', 'Two', 'Three' | ForEach-Object { Join-Path $script:testDirBase $_ }
                $paths | New-DirectoryIfNeeded
                foreach ($p in $paths) { Test-Path $p -PathType Container | Should -Be $true }
            }

        }

        Context "Error handling" {

            It "Should throw on empty path" {
                { New-DirectoryIfNeeded -Path '' -ErrorAction Stop } | Should -Throw
            }

        }

    }

}

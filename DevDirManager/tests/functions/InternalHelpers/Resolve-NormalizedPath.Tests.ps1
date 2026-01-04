Describe "Resolve-NormalizedPath" -Tag "InternalFunction", "Path" {

    InModuleScope 'DevDirManager' {

        Context "Parameter Contract" {

            BeforeAll {
                $command = Get-Command -Name 'Resolve-NormalizedPath' -ErrorAction Stop
                $parameters = $command.Parameters
            }

            It "Should have the correct parameter types" {
                $parameters['Path'].ParameterType.Name | Should -Be 'String'
                $parameters['EnsureTrailingBackslash'].ParameterType.Name | Should -Be 'SwitchParameter'
            }

            It "Should have the correct mandatory parameters" {
                $parameters['Path'].Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -Contain $true
                $parameters['EnsureTrailingBackslash'].Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -Not -Contain $true
            }

            It "Should have the correct attributes" {
                $parameters['Path'].Attributes.TypeId.Name | Should -Contain 'ValidateNotNullOrEmptyAttribute'
            }

        }

        BeforeAll {
            $script:pathTestDir = Join-Path $TestDrive "PathTests"
            New-Item -ItemType Directory -Path $script:pathTestDir -Force | Out-Null
        }

        AfterAll {
            if (Test-Path $script:pathTestDir) {
                Remove-Item -Path $script:pathTestDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        Context "Path resolution" {

            It "Should resolve absolute path" {
                $result = Resolve-NormalizedPath -Path $script:pathTestDir
                $result | Should -Be $script:pathTestDir
                [System.IO.Path]::IsPathRooted($result) | Should -Be $true
            }

            It "Should add trailing backslash when requested" {
                $result = Resolve-NormalizedPath -Path $script:pathTestDir -EnsureTrailingBackslash
                $result | Should -Be "$($script:pathTestDir)\"
            }

            It "Should not add double trailing backslash" {
                $withSlash = "$($script:pathTestDir)\"
                $result = Resolve-NormalizedPath -Path $withSlash -EnsureTrailingBackslash
                $result.EndsWith("\") | Should -Be $true
            }

            It "Should normalize path separators" {
                $mixed = $script:pathTestDir.Replace("\", "/")
                Resolve-NormalizedPath -Path $mixed | Should -Be $script:pathTestDir
            }

        }

        Context "Error handling" {

            It "Should throw on non-existent path" {
                $nonExist = Join-Path $TestDrive ("DoesNotExist_" + (Get-Random))
                { Resolve-NormalizedPath -Path $nonExist -ErrorAction Stop } | Should -Throw
            }

            It "Should throw on empty path" { { Resolve-NormalizedPath -Path '' -ErrorAction Stop } | Should -Throw }

            It "Should throw on whitespace-only path" { { Resolve-NormalizedPath -Path '   ' -ErrorAction Stop } | Should -Throw }

        }
    }

}

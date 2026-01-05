Describe 'Write-ConfigFileWithRetry' -Tag 'Unit', 'Internal', 'IO' {

    InModuleScope 'DevDirManager' {

        Context "Parameter Contract" {

            BeforeAll {
                $command = Get-Command -Name 'Write-ConfigFileWithRetry' -ErrorAction Stop
                $parameters = $command.Parameters
            }

            It "Should have the correct parameter types" {
                $parameters['Path'].ParameterType.Name | Should -Be 'String'
                $parameters['Content'].ParameterType.Name | Should -Be 'String'
                $parameters['MaxRetries'].ParameterType.Name | Should -Be 'Int32'
                $parameters['MinDelayMs'].ParameterType.Name | Should -Be 'Int32'
                $parameters['MaxDelayMs'].ParameterType.Name | Should -Be 'Int32'
            }

            It "Should have the correct mandatory parameters" {
                $parameters['Path'].Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -Contain $true
                $parameters['Content'].Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -Contain $true
                $parameters['MaxRetries'].Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -Not -Contain $true
                $parameters['MinDelayMs'].Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -Not -Contain $true
                $parameters['MaxDelayMs'].Attributes.Where({ $_ -is [System.Management.Automation.ParameterAttribute] }).Mandatory | Should -Not -Contain $true
            }

        }

        Context 'Functionality' {

            BeforeAll {
                # Create a temporary file for isolated testing.
                $script:tempFile = [System.IO.Path]::GetTempFileName()
            }

            AfterAll {
                # Clean up temp file.
                if (Test-Path $script:tempFile) {
                    Remove-Item $script:tempFile -Force -ErrorAction SilentlyContinue
                }
            }

            It 'Writes content to file successfully' {
                $content = 'Test Content'
                Write-ConfigFileWithRetry -Path $script:tempFile -Content $content

                Get-Content -Path $script:tempFile -Raw | Should -Be $content
            }

            It 'Overwrites existing file' {
                Set-Content -Path $script:tempFile -Value 'Old Content'
                $newContent = 'New Content'

                Write-ConfigFileWithRetry -Path $script:tempFile -Content $newContent

                Get-Content -Path $script:tempFile -Raw | Should -Be $newContent
            }

        }

    }

}

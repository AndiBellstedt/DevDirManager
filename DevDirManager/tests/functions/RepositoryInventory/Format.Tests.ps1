BeforeAll {
    # Create a temporary directory for test files
    $script:TestRoot = Join-Path -Path $TestDrive -ChildPath 'FormatTests'
    New-Item -Path $script:TestRoot -ItemType Directory -Force | Out-Null

    # Create test repository objects with all required properties
    $script:TestRepositories = @(
        [PSCustomObject]@{
            PSTypeName   = 'DevDirManager.Repository'
            RootPath     = 'C:\TestRoot1'
            RelativePath = 'Project\Repo1'
            FullPath     = 'C:\TestRoot1\Project\Repo1'
            RemoteName   = 'origin'
            RemoteUrl    = 'https://github.com/user/repo1.git'
        },
        [PSCustomObject]@{
            PSTypeName   = 'DevDirManager.Repository'
            RootPath     = 'C:\TestRoot2'
            RelativePath = 'Project\Repo2'
            FullPath     = 'C:\TestRoot2\Project\Repo2'
            RemoteName   = 'upstream'
            RemoteUrl    = 'https://github.com/org/repo2.git'
        },
        [PSCustomObject]@{
            PSTypeName   = 'DevDirManager.Repository'
            RootPath     = 'C:\TestRoot3'
            RelativePath = 'Library\Repo3'
            FullPath     = 'C:\TestRoot3\Library\Repo3'
            RemoteName   = 'origin'
            RemoteUrl    = 'git@github.com:company/repo3.git'
        }
    )

    # Add proper type information to test objects
    foreach ($repo in $script:TestRepositories) {
        $repo.PSObject.TypeNames.Insert(0, 'DevDirManager.Repository')
    }
}

Describe 'Export-DevDirectoryList and Import-DevDirectoryList Format Tests' -Tag 'Unit', 'Format' {
    Context 'CSV Format Round-Trip' {
        BeforeAll {
            $script:CsvPath = Join-Path -Path $script:TestRoot -ChildPath 'test-repos.csv'
        }

        It 'Should export to CSV with explicit format parameter' {
            $script:TestRepositories | Export-DevDirectoryList -Path $script:CsvPath -Format CSV
            $script:CsvPath | Should -Exist
        }

        It 'Should export to CSV using file extension auto-detection' {
            $autoDetectPath = Join-Path -Path $script:TestRoot -ChildPath 'autodetect.csv'
            $script:TestRepositories | Export-DevDirectoryList -Path $autoDetectPath
            $autoDetectPath | Should -Exist
            Remove-Item -Path $autoDetectPath -Force
        }

        It 'Should create CSV file with UTF8 encoding' {
            $content = Get-Content -Path $script:CsvPath -Raw
            $content | Should -Not -BeNullOrEmpty
            # CSV should start with header line
            $content | Should -Match '^"?RootPath"?,'
        }

        It 'Should import from CSV and preserve all properties' {
            $importedRepos = Import-DevDirectoryList -Path $script:CsvPath -Format CSV
            $importedRepos.Count | Should -Be $script:TestRepositories.Count

            for ($i = 0; $i -lt $importedRepos.Count; $i++) {
                $importedRepos[$i].RootPath | Should -Be $script:TestRepositories[$i].RootPath
                $importedRepos[$i].RelativePath | Should -Be $script:TestRepositories[$i].RelativePath
                $importedRepos[$i].FullPath | Should -Be $script:TestRepositories[$i].FullPath
                $importedRepos[$i].RemoteName | Should -Be $script:TestRepositories[$i].RemoteName
                $importedRepos[$i].RemoteUrl | Should -Be $script:TestRepositories[$i].RemoteUrl
            }
        }

        It 'Should import from CSV using file extension auto-detection' {
            $importedRepos = Import-DevDirectoryList -Path $script:CsvPath
            $importedRepos.Count | Should -Be $script:TestRepositories.Count
        }

        It 'Should preserve DevDirManager.Repository type after CSV import' {
            $importedRepos = Import-DevDirectoryList -Path $script:CsvPath
            foreach ($repo in $importedRepos) {
                $repo.PSObject.TypeNames | Should -Contain 'DevDirManager.Repository'
            }
        }

        It 'Should handle lowercase format parameter (CSV)' {
            $lowercasePath = Join-Path -Path $script:TestRoot -ChildPath 'lowercase.csv'
            $script:TestRepositories | Export-DevDirectoryList -Path $lowercasePath -Format csv
            $lowercasePath | Should -Exist

            $importedRepos = Import-DevDirectoryList -Path $lowercasePath -Format csv
            $importedRepos.Count | Should -Be $script:TestRepositories.Count
            Remove-Item -Path $lowercasePath -Force
        }
    }

    Context 'JSON Format Round-Trip' {
        BeforeAll {
            $script:JsonPath = Join-Path -Path $script:TestRoot -ChildPath 'test-repos.json'
        }

        It 'Should export to JSON with explicit format parameter' {
            $script:TestRepositories | Export-DevDirectoryList -Path $script:JsonPath -Format JSON
            $script:JsonPath | Should -Exist
        }

        It 'Should export to JSON using file extension auto-detection' {
            $autoDetectPath = Join-Path -Path $script:TestRoot -ChildPath 'autodetect.json'
            $script:TestRepositories | Export-DevDirectoryList -Path $autoDetectPath
            $autoDetectPath | Should -Exist
            Remove-Item -Path $autoDetectPath -Force
        }

        It 'Should create JSON file with UTF8 encoding and valid JSON structure' {
            $content = Get-Content -Path $script:JsonPath -Raw
            $content | Should -Not -BeNullOrEmpty
            # JSON should start with array bracket or object brace
            $content | Should -Match '^\s*[\[\{]'
            # Should be valid JSON (no exception when parsing)
            { $content | ConvertFrom-Json } | Should -Not -Throw
        }

        It 'Should import from JSON and preserve all properties' {
            $importedRepos = Import-DevDirectoryList -Path $script:JsonPath -Format JSON
            $importedRepos.Count | Should -Be $script:TestRepositories.Count

            for ($i = 0; $i -lt $importedRepos.Count; $i++) {
                $importedRepos[$i].RootPath | Should -Be $script:TestRepositories[$i].RootPath
                $importedRepos[$i].RelativePath | Should -Be $script:TestRepositories[$i].RelativePath
                $importedRepos[$i].FullPath | Should -Be $script:TestRepositories[$i].FullPath
                $importedRepos[$i].RemoteName | Should -Be $script:TestRepositories[$i].RemoteName
                $importedRepos[$i].RemoteUrl | Should -Be $script:TestRepositories[$i].RemoteUrl
            }
        }

        It 'Should import from JSON using file extension auto-detection' {
            $importedRepos = Import-DevDirectoryList -Path $script:JsonPath
            $importedRepos.Count | Should -Be $script:TestRepositories.Count
        }

        It 'Should preserve DevDirManager.Repository type after JSON import' {
            $importedRepos = Import-DevDirectoryList -Path $script:JsonPath
            foreach ($repo in $importedRepos) {
                $repo.PSObject.TypeNames | Should -Contain 'DevDirManager.Repository'
            }
        }

        It 'Should handle lowercase format parameter (JSON)' {
            $lowercasePath = Join-Path -Path $script:TestRoot -ChildPath 'lowercase.json'
            $script:TestRepositories | Export-DevDirectoryList -Path $lowercasePath -Format json
            $lowercasePath | Should -Exist

            $importedRepos = Import-DevDirectoryList -Path $lowercasePath -Format json
            $importedRepos.Count | Should -Be $script:TestRepositories.Count
            Remove-Item -Path $lowercasePath -Force
        }
    }

    Context 'XML Format Round-Trip' {
        BeforeAll {
            $script:XmlPath = Join-Path -Path $script:TestRoot -ChildPath 'test-repos.xml'
        }

        It 'Should export to XML with explicit format parameter' {
            $script:TestRepositories | Export-DevDirectoryList -Path $script:XmlPath -Format XML
            $script:XmlPath | Should -Exist
        }

        It 'Should export to XML using file extension auto-detection' {
            $autoDetectPath = Join-Path -Path $script:TestRoot -ChildPath 'autodetect.xml'
            $script:TestRepositories | Export-DevDirectoryList -Path $autoDetectPath
            $autoDetectPath | Should -Exist
            Remove-Item -Path $autoDetectPath -Force
        }

        It 'Should create XML file with valid XML structure' {
            $content = Get-Content -Path $script:XmlPath -Raw
            $content | Should -Not -BeNullOrEmpty
            # XML should start with XML declaration or root element
            $content | Should -Match '^\s*<'
            # Should be valid XML (no exception when parsing)
            { [xml]$content } | Should -Not -Throw
        }

        It 'Should import from XML and preserve all properties' {
            $importedRepos = Import-DevDirectoryList -Path $script:XmlPath -Format XML
            $importedRepos.Count | Should -Be $script:TestRepositories.Count

            for ($i = 0; $i -lt $importedRepos.Count; $i++) {
                $importedRepos[$i].RootPath | Should -Be $script:TestRepositories[$i].RootPath
                $importedRepos[$i].RelativePath | Should -Be $script:TestRepositories[$i].RelativePath
                $importedRepos[$i].FullPath | Should -Be $script:TestRepositories[$i].FullPath
                $importedRepos[$i].RemoteName | Should -Be $script:TestRepositories[$i].RemoteName
                $importedRepos[$i].RemoteUrl | Should -Be $script:TestRepositories[$i].RemoteUrl
            }
        }

        It 'Should import from XML using file extension auto-detection' {
            $importedRepos = Import-DevDirectoryList -Path $script:XmlPath
            $importedRepos.Count | Should -Be $script:TestRepositories.Count
        }

        It 'Should preserve DevDirManager.Repository type after XML import' {
            $importedRepos = Import-DevDirectoryList -Path $script:XmlPath
            foreach ($repo in $importedRepos) {
                $repo.PSObject.TypeNames | Should -Contain 'DevDirManager.Repository'
            }
        }

        It 'Should handle lowercase format parameter (XML)' {
            $lowercasePath = Join-Path -Path $script:TestRoot -ChildPath 'lowercase.xml'
            $script:TestRepositories | Export-DevDirectoryList -Path $lowercasePath -Format xml
            $lowercasePath | Should -Exist

            $importedRepos = Import-DevDirectoryList -Path $lowercasePath -Format xml
            $importedRepos.Count | Should -Be $script:TestRepositories.Count
            Remove-Item -Path $lowercasePath -Force
        }
    }

    Context 'Format Auto-Detection' {
        It 'Should auto-detect CSV format from .csv extension' {
            $csvFile = Join-Path -Path $script:TestRoot -ChildPath 'extension-test.csv'
            $script:TestRepositories | Export-DevDirectoryList -Path $csvFile
            $content = Get-Content -Path $csvFile -Raw
            $content | Should -Match '^"?RootPath"?,'
            Remove-Item -Path $csvFile -Force
        }

        It 'Should auto-detect JSON format from .json extension' {
            $jsonFile = Join-Path -Path $script:TestRoot -ChildPath 'extension-test.json'
            $script:TestRepositories | Export-DevDirectoryList -Path $jsonFile
            $content = Get-Content -Path $jsonFile -Raw
            $content | Should -Match '^\s*[\[\{]'
            Remove-Item -Path $jsonFile -Force
        }

        It 'Should auto-detect XML format from .xml extension' {
            $xmlFile = Join-Path -Path $script:TestRoot -ChildPath 'extension-test.xml'
            $script:TestRepositories | Export-DevDirectoryList -Path $xmlFile
            $content = Get-Content -Path $xmlFile -Raw
            $content | Should -Match '^\s*<'
            Remove-Item -Path $xmlFile -Force
        }

        It 'Should auto-detect CSV format from .CSV extension (uppercase)' {
            $csvFile = Join-Path -Path $script:TestRoot -ChildPath 'extension-test.CSV'
            $script:TestRepositories | Export-DevDirectoryList -Path $csvFile
            $content = Get-Content -Path $csvFile -Raw
            $content | Should -Match '^"?RootPath"?,'
            Remove-Item -Path $csvFile -Force
        }

        It 'Should auto-detect JSON format from .JSON extension (uppercase)' {
            $jsonFile = Join-Path -Path $script:TestRoot -ChildPath 'extension-test.JSON'
            $script:TestRepositories | Export-DevDirectoryList -Path $jsonFile
            $content = Get-Content -Path $jsonFile -Raw
            $content | Should -Match '^\s*[\[\{]'
            Remove-Item -Path $jsonFile -Force
        }

        It 'Should auto-detect XML format from .XML extension (uppercase)' {
            $xmlFile = Join-Path -Path $script:TestRoot -ChildPath 'extension-test.XML'
            $script:TestRepositories | Export-DevDirectoryList -Path $xmlFile
            $content = Get-Content -Path $xmlFile -Raw
            $content | Should -Match '^\s*<'
            Remove-Item -Path $xmlFile -Force
        }

        It 'Should auto-detect CSV format from .Csv extension (mixed case)' {
            $csvFile = Join-Path -Path $script:TestRoot -ChildPath 'extension-test.Csv'
            $script:TestRepositories | Export-DevDirectoryList -Path $csvFile
            $content = Get-Content -Path $csvFile -Raw
            $content | Should -Match '^"?RootPath"?,'
            Remove-Item -Path $csvFile -Force
        }

        It 'Should import from .CSV file (uppercase extension)' {
            $csvFile = Join-Path -Path $script:TestRoot -ChildPath 'import-test.CSV'
            $script:TestRepositories | Export-DevDirectoryList -Path $csvFile
            $importedRepos = Import-DevDirectoryList -Path $csvFile
            $importedRepos.Count | Should -Be $script:TestRepositories.Count
            Remove-Item -Path $csvFile -Force
        }

        It 'Should import from .JSON file (uppercase extension)' {
            $jsonFile = Join-Path -Path $script:TestRoot -ChildPath 'import-test.JSON'
            $script:TestRepositories | Export-DevDirectoryList -Path $jsonFile
            $importedRepos = Import-DevDirectoryList -Path $jsonFile
            $importedRepos.Count | Should -Be $script:TestRepositories.Count
            Remove-Item -Path $jsonFile -Force
        }

        It 'Should import from .XML file (uppercase extension)' {
            $xmlFile = Join-Path -Path $script:TestRoot -ChildPath 'import-test.XML'
            $script:TestRepositories | Export-DevDirectoryList -Path $xmlFile
            $importedRepos = Import-DevDirectoryList -Path $xmlFile
            $importedRepos.Count | Should -Be $script:TestRepositories.Count
            Remove-Item -Path $xmlFile -Force
        }

        It 'Should use configured default format when no extension is provided' {
            # Get current default format
            $originalDefault = Get-PSFConfigValue -FullName 'DevDirManager.DefaultOutputFormat'

            try {
                # Set default to JSON for this test
                Set-PSFConfig -FullName 'DevDirManager.DefaultOutputFormat' -Value 'JSON'

                $noExtFile = Join-Path -Path $script:TestRoot -ChildPath 'no-extension'
                $script:TestRepositories | Export-DevDirectoryList -Path $noExtFile
                $content = Get-Content -Path $noExtFile -Raw
                $content | Should -Match '^\s*[\[\{]'
                Remove-Item -Path $noExtFile -Force
            } finally {
                # Restore original default
                Set-PSFConfig -FullName 'DevDirManager.DefaultOutputFormat' -Value $originalDefault
            }
        }
    }

    Context 'Configuration System Integration' {
        It 'Should respect DefaultOutputFormat configuration setting' {
            $originalDefault = Get-PSFConfigValue -FullName 'DevDirManager.DefaultOutputFormat'

            try {
                # Test with CSV default
                Set-PSFConfig -FullName 'DevDirManager.DefaultOutputFormat' -Value 'CSV'
                $testFile1 = Join-Path -Path $script:TestRoot -ChildPath 'config-test-csv'
                $script:TestRepositories | Export-DevDirectoryList -Path $testFile1
                $content1 = Get-Content -Path $testFile1 -Raw
                $content1 | Should -Match '^"?RootPath"?,'
                Remove-Item -Path $testFile1 -Force

                # Test with XML default
                Set-PSFConfig -FullName 'DevDirManager.DefaultOutputFormat' -Value 'XML'
                $testFile2 = Join-Path -Path $script:TestRoot -ChildPath 'config-test-xml'
                $script:TestRepositories | Export-DevDirectoryList -Path $testFile2
                $content2 = Get-Content -Path $testFile2 -Raw
                $content2 | Should -Match '^\s*<'
                Remove-Item -Path $testFile2 -Force
            } finally {
                Set-PSFConfig -FullName 'DevDirManager.DefaultOutputFormat' -Value $originalDefault
            }
        }

        It 'Should have DefaultOutputFormat configuration available' {
            $config = Get-PSFConfig -FullName 'DevDirManager.DefaultOutputFormat'
            $config | Should -Not -BeNullOrEmpty
            $config.Value | Should -BeIn @('CSV', 'JSON', 'XML')
        }
    }

    Context 'UTF8 Encoding Verification' {
        It 'Should export CSV with UTF8 encoding for special characters' {
            $specialRepos = @(
                [PSCustomObject]@{
                    PSTypeName   = 'DevDirManager.Repository'
                    RootPath     = 'C:\Тест'  # Cyrillic characters
                    RelativePath = 'Проект\Репо'
                    FullPath     = 'C:\Тест\Проект\Репо'
                    RemoteName   = 'origin'
                    RemoteUrl    = 'https://github.com/user/тест.git'
                }
            )
            $specialRepos[0].PSObject.TypeNames.Insert(0, 'DevDirManager.Repository')

            $csvPath = Join-Path -Path $script:TestRoot -ChildPath 'utf8-test.csv'
            $specialRepos | Export-DevDirectoryList -Path $csvPath

            $importedRepos = Import-DevDirectoryList -Path $csvPath
            $importedRepos[0].RootPath | Should -Be 'C:\Тест'
            $importedRepos[0].RelativePath | Should -Be 'Проект\Репо'
            Remove-Item -Path $csvPath -Force
        }

        It 'Should export JSON with UTF8 encoding for special characters' {
            $specialRepos = @(
                [PSCustomObject]@{
                    PSTypeName   = 'DevDirManager.Repository'
                    RootPath     = 'C:\日本語'  # Japanese characters
                    RelativePath = 'プロジェクト\リポ'
                    FullPath     = 'C:\日本語\プロジェクト\リポ'
                    RemoteName   = 'origin'
                    RemoteUrl    = 'https://github.com/user/日本語.git'
                }
            )
            $specialRepos[0].PSObject.TypeNames.Insert(0, 'DevDirManager.Repository')

            $jsonPath = Join-Path -Path $script:TestRoot -ChildPath 'utf8-test.json'
            $specialRepos | Export-DevDirectoryList -Path $jsonPath

            $importedRepos = Import-DevDirectoryList -Path $jsonPath
            $importedRepos[0].RootPath | Should -Be 'C:\日本語'
            $importedRepos[0].RelativePath | Should -Be 'プロジェクト\リポ'
            Remove-Item -Path $jsonPath -Force
        }
    }

    Context 'Error Handling' {
        It 'Should throw error when importing non-existent file' {
            $nonExistentPath = Join-Path -Path $script:TestRoot -ChildPath 'does-not-exist.csv'
            { Import-DevDirectoryList -Path $nonExistentPath } | Should -Throw
        }

        It 'Should handle empty file path gracefully' {
            $emptyFile = Join-Path -Path $script:TestRoot -ChildPath 'empty.json'
            '' | Set-Content -Path $emptyFile -Encoding UTF8
            $result = Import-DevDirectoryList -Path $emptyFile
            $result | Should -BeNullOrEmpty
            Remove-Item -Path $emptyFile -Force
        }
    }
}

AfterAll {
    # Clean up test directory
    if (Test-Path -Path $script:TestRoot) {
        Remove-Item -Path $script:TestRoot -Recurse -Force
    }
}

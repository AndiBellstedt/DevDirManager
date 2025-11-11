Describe "New-DirectoryIfNeeded" -Tag "InternalFunction", "FileSystem" {

    BeforeEach {
        $script:testDirBase = Join-Path $TestDrive "DirNeededTests"
        if (Test-Path $script:testDirBase) { Remove-Item $script:testDirBase -Recurse -Force }
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

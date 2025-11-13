Describe "ConvertTo-NormalizedRelativePath" -Tag "InternalFunction", "Path" {

    Context "Path normalization" {
        It "Should convert forward slashes to backslashes" { ConvertTo-NormalizedRelativePath -Path "foo/bar/baz" | Should -Be "foo\\bar\\baz" }
        It "Should handle mixed slashes" { ConvertTo-NormalizedRelativePath -Path "foo\\bar/baz" | Should -Be "foo\\bar\\baz" }
        It "Should collapse double backslashes" { ConvertTo-NormalizedRelativePath -Path "foo\\bar" | Should -Be "foo\\bar" }
        It "Should remove leading slashes" { ConvertTo-NormalizedRelativePath -Path "/foo/bar" | Should -Be "foo\\bar" }
        It "Should remove trailing slashes" { ConvertTo-NormalizedRelativePath -Path "foo/bar/" | Should -Be "foo\\bar" }
        It "Should handle multiple consecutive slashes" { ConvertTo-NormalizedRelativePath -Path "foo///bar" | Should -Be "foo\\\\\\bar" }
    }

    Context "Edge cases" {
        It "Should return '.' for empty string" { ConvertTo-NormalizedRelativePath -Path "" | Should -Be "." }
        It "Should return '.' for whitespace" { ConvertTo-NormalizedRelativePath -Path "   " | Should -Be "." }
        It "Should return '.' for dot" { ConvertTo-NormalizedRelativePath -Path "." | Should -Be "." }
        It "Should handle path with only slashes" { ConvertTo-NormalizedRelativePath -Path "///" | Should -Be "." }
        It "Should trim whitespace from path" { ConvertTo-NormalizedRelativePath -Path "  foo/bar  " | Should -Be "foo\\bar" }
    }

    Context "Complex paths" {
        It "Should handle deeply nested paths" { ConvertTo-NormalizedRelativePath -Path "a/b/c/d/e/f/g" | Should -Be "a\\b\\c\\d\\e\\f\\g" }
        It "Should handle paths with spaces" { ConvertTo-NormalizedRelativePath -Path "My Projects/Test Repo" | Should -Be "My Projects\\Test Repo" }
        It "Should handle paths with special characters" { ConvertTo-NormalizedRelativePath -Path "Project-Name_v2.0/SubFolder" | Should -Be "Project-Name_v2.0\\SubFolder" }
    }
}

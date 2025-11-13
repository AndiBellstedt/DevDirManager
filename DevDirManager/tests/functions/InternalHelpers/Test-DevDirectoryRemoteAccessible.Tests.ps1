Describe "Test-DevDirectoryRemoteAccessible" -Tag "InternalFunction", "Git", "Remote" {
    Context "Input validation" {
        It "Should return false for whitespace URL" {
            $result = Test-DevDirectoryRemoteAccessible -RemoteUrl '   '
            $result | Should -BeFalse
        }
    }
    Context "Timeout unreachable remote" {
        It "Should return false for unreachable remote quickly" {
            $result = Test-DevDirectoryRemoteAccessible -RemoteUrl 'https://nonexistent.invalid/repo.git' -TimeoutSeconds 1
            $result | Should -BeFalse
        }
    }
}

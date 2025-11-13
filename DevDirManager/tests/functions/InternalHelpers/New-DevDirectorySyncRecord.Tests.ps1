Describe "New-DevDirectorySyncRecord" -Tag "InternalFunction", "Data" {
    Context "Record construction" {
        It "Should build record with all properties" {
            $record = New-DevDirectorySyncRecord -RelativePath "ProjectA" -RemoteUrl "https://example/ProjectA.git" -RemoteName "origin" -RootDirectory "C:\Repos" -UserName "User" -UserEmail "user@example.com" -StatusDate (Get-Date).Date
            $record.PSObject.TypeNames[0] | Should -Be 'DevDirManager.Repository'
            $record.FullPath | Should -Be "C:\Repos\ProjectA"
            $record.RemoteUrl | Should -Be "https://example/ProjectA.git"
            $record.UserName | Should -Be "User"
            $record.StatusDate.Date | Should -Be (Get-Date).Date
        }
        It "Should normalize empty RelativePath to '.' and set FullPath to root" {
            $record = New-DevDirectorySyncRecord -RelativePath '' -RootDirectory "C:\Root" -RemoteName 'origin'
            $record.RelativePath | Should -Be '.'
            $record.FullPath | Should -Be "C:\Root"
        }
        It "Should allow null optional values" {
            $record = New-DevDirectorySyncRecord -RelativePath 'X' -RootDirectory 'C:\Dev'
            $record.RemoteUrl | Should -BeNullOrEmpty
            $record.UserEmail | Should -BeNullOrEmpty
        }
    }
}

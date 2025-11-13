Describe "Add-RepositoryTypeName" -Tag "InternalFunction", "TypeName" {

    Context "Adding type name to objects" {
        It "Should add DevDirManager.Repository type name to a single object" {
            $obj = [PSCustomObject]@{ Name = "Test" }
            $result = $obj | Add-RepositoryTypeName

            $result.PSObject.TypeNames[0] | Should -Be 'DevDirManager.Repository'
        }

        It "Should add type name to multiple objects in pipeline" {
            $obj1 = [PSCustomObject]@{ Name = "Test1" }
            $obj2 = [PSCustomObject]@{ Name = "Test2" }

            $results = $obj1, $obj2 | Add-RepositoryTypeName

            $results.Count | Should -Be 2
            $results[0].PSObject.TypeNames[0] | Should -Be 'DevDirManager.Repository'
            $results[1].PSObject.TypeNames[0] | Should -Be 'DevDirManager.Repository'
        }

        It "Should preserve existing properties" {
            $obj = [PSCustomObject]@{
                Name  = "Test"
                Value = 42
                Path  = "C:\Test"
            }

            $result = $obj | Add-RepositoryTypeName

            $result.Name | Should -Be "Test"
            $result.Value | Should -Be 42
            $result.Path | Should -Be "C:\Test"
        }

        It "Should insert type name at position 0" {
            $obj = [PSCustomObject]@{ Name = "Test" }
            $obj.PSObject.TypeNames.Insert(0, 'CustomType')

            $result = $obj | Add-RepositoryTypeName

            $result.PSObject.TypeNames[0] | Should -Be 'DevDirManager.Repository'
            $result.PSObject.TypeNames[1] | Should -Be 'CustomType'
            $result.PSObject.TypeNames[2] | Should -Be 'System.Management.Automation.PSCustomObject'
        }

        It "Should return the same object instance" {
            $obj = [PSCustomObject]@{ Name = "Test" }
            $result = $obj | Add-RepositoryTypeName

            [object]::ReferenceEquals($obj, $result) | Should -Be $true
        }
    }
}

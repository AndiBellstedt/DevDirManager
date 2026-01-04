Describe 'Show-DevDirectoryDashboard' -Tag 'Unit', 'UI' {

    Context "Parameter Contract" {
        BeforeAll {
            $command = Get-Command -Name 'Show-DevDirectoryDashboard'
            $parameters = $command.Parameters
        }

        Context "Parameter: RootPath" {
            BeforeAll { $p = $parameters['RootPath'] }
            It "Exists" { $p | Should -Not -BeNullOrEmpty }
            It "Is of type [string]" { $p.ParameterType.FullName | Should -Be 'System.String' }
            It "Is not Mandatory" { $p.Attributes.Where({$_ -is [System.Management.Automation.ParameterAttribute]}).Mandatory | Should -Not -Contain $true }
        }

        Context "Parameter: ShowWindow" {
            BeforeAll { $p = $parameters['ShowWindow'] }
            It "Exists" { $p | Should -Not -BeNullOrEmpty }
            It "Is of type [switch]" { $p.ParameterType.FullName | Should -Be 'System.Management.Automation.SwitchParameter' }
            It "Is not Mandatory" { $p.Attributes.Where({$_ -is [System.Management.Automation.ParameterAttribute]}).Mandatory | Should -Not -Contain $true }
        }

        Context "Parameter: PassThru" {
            BeforeAll { $p = $parameters['PassThru'] }
            It "Exists" { $p | Should -Not -BeNullOrEmpty }
            It "Is of type [switch]" { $p.ParameterType.FullName | Should -Be 'System.Management.Automation.SwitchParameter' }
            It "Is not Mandatory" { $p.Attributes.Where({$_ -is [System.Management.Automation.ParameterAttribute]}).Mandatory | Should -Not -Contain $true }
        }
    }

    BeforeAll {
        $script:SkipReason = $null
        $script:DashboardResult = $null

        $osIsWindows = [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows)
        if (-not $osIsWindows) {
            $script:SkipReason = 'Show-DevDirectoryDashboard requires Windows with WPF support.'
            return
        }

        if ([System.Threading.Thread]::CurrentThread.ApartmentState -ne [System.Threading.ApartmentState]::STA) {
            $script:SkipReason = 'Show-DevDirectoryDashboard requires an STA runspace.'
            return
        }

        $script:TestRoot = Join-Path -Path $TestDrive -ChildPath 'Dashboard'
        New-Item -ItemType Directory -Path $script:TestRoot -Force | Out-Null

        $script:DashboardResult = Show-DevDirectoryDashboard -RootPath $script:TestRoot -ShowWindow:$false -PassThru
    }

    AfterAll {
        if ($script:DashboardResult -and $script:DashboardResult.Window) {
            $script:DashboardResult.Window.Close()
        }
    }

    It 'Constructs dashboard window when PassThru is used' {
        if ($script:SkipReason) {
            Set-ItResult -Skipped -Because $script:SkipReason
            return
        }

        $script:DashboardResult.Window | Should -Not -BeNullOrEmpty
        $script:DashboardResult.Window.Title | Should -Be (Get-PSFLocalizedString -Module 'DevDirManager' -Name 'ShowDevDirectoryDashboard.WindowTitle')
    }

    It 'Returns control and state references for automation' {
        if ($script:SkipReason) {
            Set-ItResult -Skipped -Because $script:SkipReason
            return
        }

        $script:DashboardResult.Controls | Should -Not -BeNull -Because 'Controls PSCustomObject should be available for automation.'
        $script:DashboardResult.Controls.PSObject.Properties.Name | Should -Contain 'MainTabControl' -Because 'MainTabControl should be exposed in the controls map.'
        $script:DashboardResult.Controls.MainTabControl | Should -Not -BeNull -Because 'The main TabControl reference should not be null.'
        $script:DashboardResult.State | Should -Not -BeNull -Because 'State PSCustomObject should be present.'
        $script:DashboardResult.State.PSObject.Properties.Name | Should -Contain 'DiscoverItems' -Because 'DiscoverItems collection should exist in state.'
        ($script:DashboardResult.State.DiscoverItems -eq $null) | Should -BeFalse -Because 'DiscoverItems collection should not be null.'
        ($script:DashboardResult.State.RestoreItems -eq $null) | Should -BeFalse -Because 'RestoreItems collection should not be null.'
    }

}

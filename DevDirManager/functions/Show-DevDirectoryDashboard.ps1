function Show-DevDirectoryDashboard {
    <#
        .SYNOPSIS
            Launches the DevDirManager dashboard UI.

        .DESCRIPTION
            Builds and displays a comprehensive WPF-based graphical user interface for managing Git repositories with DevDirManager.

            The dashboard provides a modern, theme-aware interface with automatic light/dark mode detection based on Windows system settings.
            It features three main operational tabs that consolidate all DevDirManager functionality:

            - Discover & Export: Scan directories to discover Git repositories and export their metadata to JSON, CSV, or XML files
            - Import & Restore: Load repository lists from files and restore (clone) repositories to a target destination
            - Sync: Synchronize a directory's repositories with a reference list, creating missing repositories and validating existing ones

            The dashboard includes real-time visual feedback during long-running operations, automatic path synchronization between tabs,
            and comprehensive localization support for English, Spanish, French, and German languages.

            All operations execute asynchronously to maintain UI responsiveness, and the dashboard provides detailed status messages
            and error handling throughout the workflow.

        .PARAMETER RootPath
            Optional path that pre-populates the source folder field in the Discover & Export tab when the dashboard launches.
            If specified, users can immediately scan this directory without manually browsing for it.

        .PARAMETER ShowWindow
            Controls whether the dashboard window is displayed immediately. Defaults to $true.
            Set to $false in combination with -PassThru to build the UI structure for automation scenarios without showing the window.
            This allows programmatic control of the dashboard elements through the returned object.

        .PARAMETER PassThru
            Returns an object containing the window, control references, and state collections for automation purposes.
            The returned object includes:
            - Window: The WPF Window object
            - Controls: A collection of all named UI controls for programmatic access
            - State: Observable collections containing the data displayed in grids

            When used without -ShowWindow:$false, the cmdlet blocks on the UI thread until the window closes before returning the object.

        .EXAMPLE
            PS C:\> Show-DevDirectoryDashboard

            Launches the dashboard interactively with default settings, allowing users to discover, export, import, restore, and sync repositories through the graphical interface.

        .EXAMPLE
            PS C:\> Show-DevDirectoryDashboard -RootPath "C:\Projects"

            Opens the dashboard with the Discover & Export tab pre-populated with "C:\Projects" as the source folder, ready for immediate scanning.

        .EXAMPLE
            PS C:\> $dashboard = Show-DevDirectoryDashboard -ShowWindow:$false -PassThru
            PS C:\> $dashboard.Controls.DiscoverPathBox.Text = "C:\Development"
            PS C:\> $dashboard.Controls.DiscoverScanButton.RaiseEvent([System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Button]::ClickEvent))
            PS C:\> $dashboard.Window.ShowDialog()

            Constructs the dashboard without displaying it, programmatically sets the source path to "C:\Development", triggers the scan operation, and then displays the window with results already loaded.

        .NOTES
            Version   : 1.2.1
            Author    : Andi Bellstedt, Copilot
            Date      : 2025-12-27
            Keywords  : Dashboard, UI, WPF, Repository, Management

        .LINK
            https://github.com/AndiBellstedt/DevDirManager
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$RootPath,

        [Parameter()]
        [switch]$ShowWindow,

        [Parameter()]
        [switch]$PassThru
    )

    begin {
        $showWindowResolved = $true
        if ($PSBoundParameters.ContainsKey('ShowWindow')) {
            $showWindowResolved = $ShowWindow.IsPresent
        }

        Write-PSFMessage -Level Verbose -String 'ShowDevDirectoryDashboard.Start' -StringValues @($RootPath, $showWindowResolved, $PassThru.IsPresent) -Tag 'ShowDevDirectoryDashboard', 'Lifecycle'
    }

    process {
        # Ensure we run on a Windows host that supports WPF.
        if (-not [System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows)) {
            $message = Get-PSFLocalizedString -Module 'DevDirManager' -Name 'ShowDevDirectoryDashboard.UnsupportedPlatform'
            Stop-PSFFunction -Message $message -EnableException $true -Cmdlet $PSCmdlet
            return
        }

        # WPF requires a single-threaded apartment to create UI elements.
        if ([System.Threading.Thread]::CurrentThread.ApartmentState -ne [System.Threading.ApartmentState]::STA) {
            $message = Get-PSFLocalizedString -Module 'DevDirManager' -Name 'ShowDevDirectoryDashboard.RequiresSta'
            Stop-PSFFunction -Message $message -EnableException $true -Cmdlet $PSCmdlet
            return
        }

        Add-Type -AssemblyName PresentationCore, PresentationFramework, WindowsBase
        Add-Type -AssemblyName System.Windows.Forms

        $moduleRoot = $ExecutionContext.SessionState.Module.ModuleBase
        $xamlPath = Join-Path -Path $moduleRoot -ChildPath 'internal\ui\DevDirectoryDashboard.xaml'

        if (-not (Test-Path -Path $xamlPath -PathType Leaf)) {
            Stop-PSFFunction -String 'ShowDevDirectoryDashboard.XamlMissing' -StringValues @($xamlPath) -EnableException $true -Cmdlet $PSCmdlet
            return
        }

        $xamlContent = Get-Content -Path $xamlPath -Raw -ErrorAction Stop
        $stringReader = New-Object System.IO.StringReader($xamlContent)
        $xmlReader = [System.Xml.XmlReader]::Create($stringReader)
        try {
            $window = [System.Windows.Markup.XamlReader]::Load($xmlReader)
        } finally {
            if ($xmlReader -is [System.IDisposable]) {
                $xmlReader.Dispose()
            }
            if ($stringReader -is [System.IDisposable]) {
                $stringReader.Dispose()
            }
        }

        # Apply system theme (Light/Dark) by mutating existing brushes so StaticResource bindings update
        $applyTheme = {
            param([System.Windows.Window]$w)

            $isLightTheme = $false
            try {
                $themeValue = Get-ItemPropertyValue -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name 'AppsUseLightTheme' -ErrorAction Stop
                $isLightTheme = ($themeValue -ne 0)
            } catch {
                $isLightTheme = $false
            }

            $palettes = @{
                Dark  = @{
                    'Brush.WindowBackground' = '#FF0F172A'
                    'Brush.Surface'          = '#FF182030'
                    'Brush.SurfaceAlt'       = '#FF202A3B'
                    'Brush.Border'           = '#FF394057'
                    'Brush.PrimaryText'      = '#FFF5F7FA'
                    'Brush.SecondaryText'    = '#FFA5ACBC'
                    'Brush.GridLines'        = '#FF141B2B'
                    'Brush.ButtonText'       = '#FFFFFFFF'
                    'Brush.AccentText'       = '#FFFFFFFF'
                }
                Light = @{
                    'Brush.WindowBackground' = '#FFF7F8FA'
                    'Brush.Surface'          = '#FFFFFFFF'
                    'Brush.SurfaceAlt'       = '#FFD1D5DB'
                    'Brush.Border'           = '#FFE5E7EB'
                    'Brush.PrimaryText'      = '#FF111827'
                    'Brush.SecondaryText'    = '#FF6B7280'
                    'Brush.GridLines'        = '#FFE5E7EB'
                    'Brush.ButtonText'       = '#FFFFFFFF'
                    'Brush.AccentText'       = '#FFFFFFFF'
                }
            }

            $paletteKey = if ($isLightTheme) { 'Light' } else { 'Dark' }
            $selectedPalette = $palettes[$paletteKey]

            foreach ($kvp in $selectedPalette.GetEnumerator()) {
                if ($w.Resources.Contains($kvp.Key)) {
                    $brush = $w.Resources[$kvp.Key] -as [System.Windows.Media.SolidColorBrush]
                    if ($brush) {
                        $color = [System.Windows.Media.ColorConverter]::ConvertFromString($kvp.Value)
                        # If brush is frozen, create an unfrozen clone and replace references
                        if ($brush.IsFrozen) {
                            $newBrush = [System.Windows.Media.SolidColorBrush]::new($color)
                            $w.Resources[$kvp.Key] = $newBrush
                        } else {
                            $brush.Color = $color
                        }
                    }
                }
            }

            # Accent brush based on system color for both themes
            if ($w.Resources.Contains('Brush.Accent')) {
                $accentColor = [System.Windows.SystemParameters]::WindowGlassColor
                $accentBrush = $w.Resources['Brush.Accent'] -as [System.Windows.Media.SolidColorBrush]
                if ($accentBrush) {
                    if ($accentBrush.IsFrozen) {
                        $w.Resources['Brush.Accent'] = [System.Windows.Media.SolidColorBrush]::new($accentColor)
                    } else {
                        $accentBrush.Color = $accentColor
                    }
                }
            }

            # Ensure accent foreground brushes have sufficient contrast
            if ($w.Resources.Contains('Brush.Accent')) {
                $accentBrush = $w.Resources['Brush.Accent'] -as [System.Windows.Media.SolidColorBrush]
                if ($accentBrush) {
                    $c = $accentBrush.Color
                    $luminance = (0.2126 * ($c.R / 255.0)) + (0.7152 * ($c.G / 255.0)) + (0.0722 * ($c.B / 255.0))
                    $desired = if ($luminance -gt 0.65) { [System.Windows.Media.Colors]::Black } else { [System.Windows.Media.Colors]::White }
                    foreach ($fgKey in 'Brush.ButtonText', 'Brush.AccentText') {
                        if ($w.Resources.Contains($fgKey)) {
                            $fgBrush = $w.Resources[$fgKey] -as [System.Windows.Media.SolidColorBrush]
                            if ($fgBrush) {
                                if ($fgBrush.IsFrozen) {
                                    $w.Resources[$fgKey] = [System.Windows.Media.SolidColorBrush]::new($desired)
                                } else {
                                    $fgBrush.Color = $desired
                                }
                            }
                        }
                    }
                }
            }
        }

        $applyTheme.Invoke($window) | Out-Null

        $controls = [ordered]@{
            HeaderText                       = $window.FindName('HeaderText')
            SubHeaderText                    = $window.FindName('SubHeaderText')
            HeaderLogo                       = $window.FindName('HeaderLogo')
            StatusText                       = $window.FindName('StatusText')
            MainTabControl                   = $window.FindName('MainTabControl')
            DiscoverTabHeader                = $window.FindName('DiscoverTabHeader')
            DiscoverPathLabel                = $window.FindName('DiscoverPathLabel')
            DiscoverPathBox                  = $window.FindName('DiscoverPathBox')
            DiscoverBrowseButton             = $window.FindName('DiscoverBrowseButton')
            DiscoverScanButton               = $window.FindName('DiscoverScanButton')
            DiscoverGrid                     = $window.FindName('DiscoverGrid')
            DiscoverRelativePathColumn       = $window.FindName('DiscoverRelativePathColumn')
            DiscoverRemoteNameColumn         = $window.FindName('DiscoverRemoteNameColumn')
            DiscoverRemoteUrlColumn          = $window.FindName('DiscoverRemoteUrlColumn')
            DiscoverIsRemoteAccessibleColumn = $window.FindName('DiscoverIsRemoteAccessibleColumn')
            DiscoverUserNameColumn           = $window.FindName('DiscoverUserNameColumn')
            DiscoverUserEmailColumn          = $window.FindName('DiscoverUserEmailColumn')
            DiscoverStatusDateColumn         = $window.FindName('DiscoverStatusDateColumn')
            DiscoverSummaryText              = $window.FindName('DiscoverSummaryText')
            ExportFormatLabel                = $window.FindName('ExportFormatLabel')
            ExportFormatCombo                = $window.FindName('ExportFormatCombo')
            ExportPathLabel                  = $window.FindName('ExportPathLabel')
            ExportPathBox                    = $window.FindName('ExportPathBox')
            ExportBrowseButton               = $window.FindName('ExportBrowseButton')
            ExportRunButton                  = $window.FindName('ExportRunButton')
            ImportTabHeader                  = $window.FindName('ImportTabHeader')
            ImportPathLabel                  = $window.FindName('ImportPathLabel')
            ImportPathBox                    = $window.FindName('ImportPathBox')
            ImportBrowseButton               = $window.FindName('ImportBrowseButton')
            ImportLoadButton                 = $window.FindName('ImportLoadButton')
            ImportGrid                       = $window.FindName('ImportGrid')
            ImportRelativePathColumn         = $window.FindName('ImportRelativePathColumn')
            ImportRemoteUrlColumn            = $window.FindName('ImportRemoteUrlColumn')
            ImportIsRemoteAccessibleColumn   = $window.FindName('ImportIsRemoteAccessibleColumn')
            ImportUserNameColumn             = $window.FindName('ImportUserNameColumn')
            ImportUserEmailColumn            = $window.FindName('ImportUserEmailColumn')
            ImportStatusDateColumn           = $window.FindName('ImportStatusDateColumn')
            ImportSummaryText                = $window.FindName('ImportSummaryText')
            RestoreDestinationLabel          = $window.FindName('RestoreDestinationLabel')
            RestoreDestinationBox            = $window.FindName('RestoreDestinationBox')
            RestoreDestinationBrowseButton   = $window.FindName('RestoreDestinationBrowseButton')
            RestoreRunButton                 = $window.FindName('RestoreRunButton')
            RestoreForceCheckBox             = $window.FindName('RestoreForceCheckBox')
            RestoreSkipExistingCheckBox      = $window.FindName('RestoreSkipExistingCheckBox')
            SyncTabHeader                    = $window.FindName('SyncTabHeader')
            SyncDirectoryLabel               = $window.FindName('SyncDirectoryLabel')
            SyncDirectoryBox                 = $window.FindName('SyncDirectoryBox')
            SyncDirectoryBrowseButton        = $window.FindName('SyncDirectoryBrowseButton')
            SyncListPathLabel                = $window.FindName('SyncListPathLabel')
            SyncListPathBox                  = $window.FindName('SyncListPathBox')
            SyncListBrowseButton             = $window.FindName('SyncListBrowseButton')
            SyncRunButton                    = $window.FindName('SyncRunButton')
            SyncForceCheckBox                = $window.FindName('SyncForceCheckBox')
            SyncSkipExistingCheckBox         = $window.FindName('SyncSkipExistingCheckBox')
            SyncShowGitOutputCheckBox        = $window.FindName('SyncShowGitOutputCheckBox')
            SyncWhatIfCheckBox               = $window.FindName('SyncWhatIfCheckBox')
            SyncGrid                         = $window.FindName('SyncGrid')
            SyncRelativePathColumn           = $window.FindName('SyncRelativePathColumn')
            SyncRemoteUrlColumn              = $window.FindName('SyncRemoteUrlColumn')
            SyncIsRemoteAccessibleColumn     = $window.FindName('SyncIsRemoteAccessibleColumn')
            SyncStatusDateColumn             = $window.FindName('SyncStatusDateColumn')
            SyncSummaryText                  = $window.FindName('SyncSummaryText')
        }

        $state = [ordered]@{
            DiscoverItems       = [System.Collections.ObjectModel.ObservableCollection[psobject]]::new()
            ExportPreviewItems  = [System.Collections.ObjectModel.ObservableCollection[psobject]]::new()
            ImportItems         = [System.Collections.ObjectModel.ObservableCollection[psobject]]::new()
            RestoreItems        = [System.Collections.ObjectModel.ObservableCollection[psobject]]::new()
            SyncItems           = [System.Collections.ObjectModel.ObservableCollection[psobject]]::new()
            ExportFormatOptions = [System.Collections.ObjectModel.ObservableCollection[psobject]]::new()
            SharedDataFilePath  = ''
            IsSyncingDataPath   = $false
        }

        $controls.DiscoverGrid.ItemsSource = $state.DiscoverItems
        $controls.ImportGrid.ItemsSource = $state.ImportItems
        $controls.SyncGrid.ItemsSource = $state.SyncItems
        $controls.ExportFormatCombo.ItemsSource = $state.ExportFormatOptions
        $controls.ExportFormatCombo.DisplayMemberPath = 'Display'
        $controls.ExportFormatCombo.SelectedValuePath = 'Value'

        $getLocalized = {
            param([string]$name)
            return Get-PSFLocalizedString -Module 'DevDirManager' -Name $name
        }

        $formatLocalized = {
            param(
                [string]$name,
                [object[]]$values
            )

            $template = $getLocalized.Invoke($name)[0]
            if ($null -ne $values -and $values.Count -gt 0) {
                return [string]::Format($template, $values)
            }

            return $template
        }

        $setStatus = {
            param(
                [string]$name,
                [object[]]$values
            )

            $statusText = $formatLocalized.Invoke($name, $values)[0]
            $controls.StatusText.Text = $statusText
        }

        $populateCollection = {
            param(
                [System.Collections.ObjectModel.ObservableCollection[psobject]]$collection,
                $items
            )

            $collection.Clear()
            if ($null -ne $items) {
                # Handle both single objects and collections
                if ($items -is [System.Collections.IEnumerable] -and $items -isnot [string]) {
                    foreach ($item in $items) {
                        $collection.Add($item)
                    }
                } else {
                    # Single object
                    $collection.Add($items)
                }
            }
        }

        $addFormatOption = {
            param([string]$valueKey)
            $display = $getLocalized.Invoke("ShowDevDirectoryDashboard.Format.$($valueKey)")[0]
            $state.ExportFormatOptions.Add([pscustomobject]@{
                    Display = $display
                    Value   = $valueKey
                })
        }

        foreach ($formatValue in 'JSON', 'CSV', 'XML') {
            $addFormatOption.Invoke($formatValue)[0]
        }

        $controls.ExportFormatCombo.SelectedValue = 'JSON'

        $window.Title = $getLocalized.Invoke('ShowDevDirectoryDashboard.WindowTitle')[0]
        $controls.HeaderText.Text = $getLocalized.Invoke('ShowDevDirectoryDashboard.Header')[0]
        $controls.SubHeaderText.Text = $getLocalized.Invoke('ShowDevDirectoryDashboard.SubHeader')[0]
        $controls.DiscoverTabHeader.Text = $getLocalized.Invoke('ShowDevDirectoryDashboard.DiscoverTabHeader')[0]
        $controls.DiscoverPathLabel.Text = $getLocalized.Invoke('ShowDevDirectoryDashboard.DiscoverPathLabel')[0]
        $controls.DiscoverBrowseButton.Content = $getLocalized.Invoke('ShowDevDirectoryDashboard.BrowseButton')[0]
        $controls.DiscoverScanButton.Content = $getLocalized.Invoke('ShowDevDirectoryDashboard.ScanButton')[0]
        $controls.DiscoverRelativePathColumn.Header = $getLocalized.Invoke('ShowDevDirectoryDashboard.Column.RelativePath')[0]
        $controls.DiscoverRemoteNameColumn.Header = $getLocalized.Invoke('ShowDevDirectoryDashboard.Column.RemoteName')[0]
        $controls.DiscoverRemoteUrlColumn.Header = $getLocalized.Invoke('ShowDevDirectoryDashboard.Column.RemoteUrl')[0]
        $controls.DiscoverIsRemoteAccessibleColumn.Header = $getLocalized.Invoke('ShowDevDirectoryDashboard.Column.IsRemoteAccessible')[0]
        $controls.DiscoverUserNameColumn.Header = $getLocalized.Invoke('ShowDevDirectoryDashboard.Column.UserName')[0]
        $controls.DiscoverUserEmailColumn.Header = $getLocalized.Invoke('ShowDevDirectoryDashboard.Column.UserEmail')[0]
        $controls.DiscoverStatusDateColumn.Header = $getLocalized.Invoke('ShowDevDirectoryDashboard.Column.StatusDate')[0]
        $controls.ExportFormatLabel.Text = $getLocalized.Invoke('ShowDevDirectoryDashboard.ExportFormatLabel')[0]
        $controls.ExportPathLabel.Text = $getLocalized.Invoke('ShowDevDirectoryDashboard.ExportPathLabel')[0]
        $controls.ExportBrowseButton.Content = $getLocalized.Invoke('ShowDevDirectoryDashboard.BrowseButton')[0]
        $controls.ExportRunButton.Content = $getLocalized.Invoke('ShowDevDirectoryDashboard.ExportRunButton')[0]
        $controls.ImportTabHeader.Text = $getLocalized.Invoke('ShowDevDirectoryDashboard.ImportTabHeader')[0]
        $controls.ImportPathLabel.Text = $getLocalized.Invoke('ShowDevDirectoryDashboard.ImportPathLabel')[0]
        $controls.ImportBrowseButton.Content = $getLocalized.Invoke('ShowDevDirectoryDashboard.BrowseButton')[0]
        $controls.ImportLoadButton.Content = $getLocalized.Invoke('ShowDevDirectoryDashboard.ImportLoadButton')[0]
        $controls.ImportRelativePathColumn.Header = $getLocalized.Invoke('ShowDevDirectoryDashboard.Column.RelativePath')[0]
        $controls.ImportRemoteUrlColumn.Header = $getLocalized.Invoke('ShowDevDirectoryDashboard.Column.RemoteUrl')[0]
        $controls.ImportIsRemoteAccessibleColumn.Header = $getLocalized.Invoke('ShowDevDirectoryDashboard.Column.IsRemoteAccessible')[0]
        $controls.ImportUserNameColumn.Header = $getLocalized.Invoke('ShowDevDirectoryDashboard.Column.UserName')[0]
        $controls.ImportUserEmailColumn.Header = $getLocalized.Invoke('ShowDevDirectoryDashboard.Column.UserEmail')[0]
        $controls.ImportStatusDateColumn.Header = $getLocalized.Invoke('ShowDevDirectoryDashboard.Column.StatusDate')[0]
        $controls.RestoreDestinationLabel.Text = $getLocalized.Invoke('ShowDevDirectoryDashboard.RestoreDestinationLabel')[0]
        $controls.RestoreDestinationBrowseButton.Content = $getLocalized.Invoke('ShowDevDirectoryDashboard.BrowseButton')[0]
        $controls.RestoreRunButton.Content = $getLocalized.Invoke('ShowDevDirectoryDashboard.RestoreRunButton')[0]
        $controls.RestoreForceCheckBox.Content = $getLocalized.Invoke('ShowDevDirectoryDashboard.RestoreForce')[0]
        $controls.RestoreSkipExistingCheckBox.Content = $getLocalized.Invoke('ShowDevDirectoryDashboard.RestoreSkipExisting')[0]
        $controls.SyncTabHeader.Text = $getLocalized.Invoke('ShowDevDirectoryDashboard.SyncTabHeader')[0]
        $controls.SyncDirectoryLabel.Text = $getLocalized.Invoke('ShowDevDirectoryDashboard.SyncDirectoryLabel')[0]
        $controls.SyncDirectoryBrowseButton.Content = $getLocalized.Invoke('ShowDevDirectoryDashboard.BrowseButton')[0]
        $controls.SyncListPathLabel.Text = $getLocalized.Invoke('ShowDevDirectoryDashboard.SyncListPathLabel')[0]
        $controls.SyncListBrowseButton.Content = $getLocalized.Invoke('ShowDevDirectoryDashboard.BrowseButton')[0]
        $controls.SyncRunButton.Content = $getLocalized.Invoke('ShowDevDirectoryDashboard.SyncRunButton')[0]
        $controls.SyncForceCheckBox.Content = $getLocalized.Invoke('ShowDevDirectoryDashboard.SyncForce')[0]
        $controls.SyncSkipExistingCheckBox.Content = $getLocalized.Invoke('ShowDevDirectoryDashboard.SyncSkipExisting')[0]
        $controls.SyncShowGitOutputCheckBox.Content = $getLocalized.Invoke('ShowDevDirectoryDashboard.SyncShowGitOutput')[0]
        $controls.SyncWhatIfCheckBox.Content = $getLocalized.Invoke('ShowDevDirectoryDashboard.SyncWhatIf')[0]
        $controls.SyncRelativePathColumn.Header = $getLocalized.Invoke('ShowDevDirectoryDashboard.Column.RelativePath')[0]
        $controls.SyncRemoteUrlColumn.Header = $getLocalized.Invoke('ShowDevDirectoryDashboard.Column.RemoteUrl')[0]
        $controls.SyncIsRemoteAccessibleColumn.Header = $getLocalized.Invoke('ShowDevDirectoryDashboard.Column.IsRemoteAccessible')[0]
        $controls.SyncStatusDateColumn.Header = $getLocalized.Invoke('ShowDevDirectoryDashboard.Column.StatusDate')[0]

        $setStatus.Invoke('ShowDevDirectoryDashboard.Status.Ready', @()[0])
        $controls.DiscoverSummaryText.Text = $formatLocalized.Invoke('ShowDevDirectoryDashboard.DiscoverSummaryTemplate', @(0)[0])
        $controls.ImportSummaryText.Text = $formatLocalized.Invoke('ShowDevDirectoryDashboard.ImportSummaryTemplate', @(0)[0])
        $controls.SyncSummaryText.Text = $formatLocalized.Invoke('ShowDevDirectoryDashboard.SyncSummaryTemplate', @(0)[0])

        # Bind the logo image in the banner and set the Window icon if the file exists
        try {
            $logoPath = Join-Path -Path $moduleRoot -ChildPath 'internal\ui\DevDirManager.png'
            if (Test-Path -LiteralPath $logoPath -PathType Leaf) {
                $bitmap = [System.Windows.Media.Imaging.BitmapImage]::new()
                $bitmap.BeginInit()
                $bitmap.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
                $bitmap.UriSource = [Uri]::new($logoPath)
                $bitmap.EndInit()
                if ($bitmap.CanFreeze -and -not $bitmap.IsFrozen) { $bitmap.Freeze() }

                if ($controls.HeaderLogo) { $controls.HeaderLogo.Source = $bitmap }
                $window.Icon = $bitmap
            }
        } catch {
            Write-PSFMessage -Level Warning -Message "Failed to load UI logo/icon: $($_.Exception.Message)" -Tag 'Asset', 'Logo' -PScmdlet $PSCmdlet
        }

        if ($RootPath) {
            $controls.DiscoverPathBox.Text = $RootPath
        }

        $pickFolder = {
            param([string]$seed)
            $dialog = [System.Windows.Forms.FolderBrowserDialog]::new()
            if (-not [string]::IsNullOrWhiteSpace($seed) -and [System.IO.Directory]::Exists($seed)) {
                $dialog.SelectedPath = $seed
            }

            $dialogResult = $dialog.ShowDialog()
            if ($dialogResult -eq [System.Windows.Forms.DialogResult]::OK) {
                return $dialog.SelectedPath
            }

            return $null
        }

        $pickOpenFile = {
            param([string]$seed)
            $dialog = [Microsoft.Win32.OpenFileDialog]::new()
            $dialog.Filter = 'Data files (*.json;*.csv;*.xml)|*.json;*.csv;*.xml|All files (*.*)|*.*'
            $dialog.Multiselect = $false
            if (-not [string]::IsNullOrWhiteSpace($seed)) {
                $dialog.FileName = $seed
            }

            if ($dialog.ShowDialog() -eq $true) {
                return $dialog.FileName
            }

            return $null
        }

        $pickSaveFile = {
            param(
                [string]$seedPath,
                [string]$formatValue
            )

            $dialog = [Microsoft.Win32.SaveFileDialog]::new()
            $dialog.Filter = 'JSON (*.json)|*.json|CSV (*.csv)|*.csv|XML (*.xml)|*.xml|All files (*.*)|*.*'
            switch ($formatValue) {
                'JSON' { $dialog.DefaultExt = '.json'; $dialog.FilterIndex = 1 }
                'CSV' { $dialog.DefaultExt = '.csv'; $dialog.FilterIndex = 2 }
                'XML' { $dialog.DefaultExt = '.xml'; $dialog.FilterIndex = 3 }
                default { $dialog.DefaultExt = '.json'; $dialog.FilterIndex = 1 }
            }

            if (-not [string]::IsNullOrWhiteSpace($seedPath)) {
                $dialog.FileName = $seedPath
            }

            if ($dialog.ShowDialog() -eq $true) {
                return $dialog.FileName
            }

            return $null
        }

        #region -- Data File Path Synchronization
        # Synchronize the repository list data file path across Import & Restore / Sync tabs.
        # When user selects or edits path in one tab, update all others unless already syncing.
        $syncDataPath = {
            param(
                [string]$newPath,
                [System.Windows.Controls.TextBox]$sourceBox
            )

            if ($state.IsSyncingDataPath) { return }
            if ([string]::IsNullOrWhiteSpace($newPath)) { return }

            $state.IsSyncingDataPath = $true
            try {
                $state.SharedDataFilePath = $newPath
                foreach ($tb in @($controls.ImportPathBox, $controls.SyncListPathBox)) {
                    if ($tb -ne $sourceBox -and $tb.Text -ne $newPath) {
                        $tb.Text = $newPath
                    }
                }
            } finally { $state.IsSyncingDataPath = $false }
        }

        # Attach TextChanged handlers to propagate manual edits
        foreach ($pair in @(
                @{ Box = $controls.ImportPathBox },
                @{ Box = $controls.SyncListPathBox }
            )) {
            $null = $pair.Box.Add_TextChanged({
                    $syncDataPath.Invoke($pair.Box.Text, $pair.Box)[0]
                })
        }
        #endregion -- Data File Path Synchronization

        # Helper to run operations with visual feedback
        $runAsync = {
            param(
                [System.Windows.Controls.Button]$button,
                [scriptblock]$operation
            )

            # Store original button state
            $originalContent = $button.Content
            $originalIsEnabled = $button.IsEnabled

            try {
                # Disable button and show working state
                $button.IsEnabled = $false
                $button.Content = "⏳ $originalContent"
                $window.Cursor = [System.Windows.Input.Cursors]::Wait

                # Force UI update
                $window.Dispatcher.Invoke([Action] {}, [System.Windows.Threading.DispatcherPriority]::ContextIdle)

                # Execute the operation
                & $operation

            } finally {
                # Restore button state
                $button.Content = $originalContent
                $button.IsEnabled = $originalIsEnabled
                $window.Cursor = [System.Windows.Input.Cursors]::Arrow
            }
        }

        $controls.DiscoverBrowseButton.Add_Click({
                $selected = $pickFolder.Invoke($controls.DiscoverPathBox.Text)[0]
                if ($selected) {
                    $controls.DiscoverPathBox.Text = $selected
                }
            })

        $controls.DiscoverScanButton.Add_Click({
                $runAsync.Invoke($controls.DiscoverScanButton, {
                        $targetPath = $controls.DiscoverPathBox.Text
                        if ([string]::IsNullOrWhiteSpace($targetPath)) {
                            $targetPath = (Get-Location).ProviderPath
                        }

                        try {
                            $setStatus.Invoke('ShowDevDirectoryDashboard.Status.ScanStarted', @($targetPath)[0])
                            $repositories = Get-DevDirectory -RootPath $targetPath
                            $populateCollection.Invoke($state.DiscoverItems, $repositories)
                            $populateCollection.Invoke($state.ExportPreviewItems, $repositories)
                            $controls.DiscoverSummaryText.Text = $formatLocalized.Invoke('ShowDevDirectoryDashboard.DiscoverSummaryTemplate', @($state.DiscoverItems.Count)[0])
                            $setStatus.Invoke('ShowDevDirectoryDashboard.Status.ScanComplete', @($state.DiscoverItems.Count)[0])
                            Write-PSFMessage -Level Verbose -String 'ShowDevDirectoryDashboard.ScanCompleted' -StringValues @($targetPath, $state.DiscoverItems.Count) -Tag 'ShowDevDirectoryDashboard', 'Discover'
                        } catch {
                            Write-PSFMessage -Level Error -Message $_.Exception.Message -ErrorRecord $_ -Tag 'ShowDevDirectoryDashboard', 'Discover'
                            $setStatus.Invoke('ShowDevDirectoryDashboard.Status.OperationFailed', @($_.Exception.Message)[0])
                            [System.Windows.MessageBox]::Show($window, $_.Exception.Message, $getLocalized.Invoke('ShowDevDirectoryDashboard.ErrorTitle')[0], [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error) | Out-Null
                        }
                    })[0]
            })

        $controls.ExportBrowseButton.Add_Click({
                $formatValue = [string]$controls.ExportFormatCombo.SelectedValue
                $targetPath = $pickSaveFile.Invoke($controls.ExportPathBox.Text, $formatValue)[0]
                if ($targetPath) {
                    $controls.ExportPathBox.Text = $targetPath
                }
            })

        $controls.ExportRunButton.Add_Click({
                $formatValue = [string]$controls.ExportFormatCombo.SelectedValue
                $outputPath = $controls.ExportPathBox.Text

                if ($state.ExportPreviewItems.Count -eq 0) {
                    [System.Windows.MessageBox]::Show($window, $getLocalized.Invoke('ShowDevDirectoryDashboard.Message.NoRepositories')[0], $getLocalized.Invoke('ShowDevDirectoryDashboard.InfoTitle')[0], [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
                    return
                }

                if ([string]::IsNullOrWhiteSpace($outputPath)) {
                    [System.Windows.MessageBox]::Show($window, $getLocalized.Invoke('ShowDevDirectoryDashboard.Message.ExportPathMissing')[0], $getLocalized.Invoke('ShowDevDirectoryDashboard.InfoTitle')[0], [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning) | Out-Null
                    return
                }

                $runAsync.Invoke($controls.ExportRunButton, {
                        try {
                            $setStatus.Invoke('ShowDevDirectoryDashboard.Status.ExportStarted', @($outputPath)[0])

                            $exportParams = @{
                                Path        = $outputPath
                                Format      = $formatValue
                                ErrorAction = 'Stop'
                            }

                            $state.ExportPreviewItems | Export-DevDirectoryList @exportParams

                            $setStatus.Invoke('ShowDevDirectoryDashboard.Status.ExportComplete', @($outputPath)[0])
                            [System.Windows.MessageBox]::Show($window, $formatLocalized.Invoke('ShowDevDirectoryDashboard.Message.ExportSuccess', @($outputPath)[0]), $getLocalized.Invoke('ShowDevDirectoryDashboard.InfoTitle')[0], [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
                            Write-PSFMessage -Level Verbose -String 'ShowDevDirectoryDashboard.ExportCompleted' -StringValues @($outputPath, $formatValue, $state.ExportPreviewItems.Count) -Tag 'ShowDevDirectoryDashboard', 'Export'
                        } catch {
                            Write-PSFMessage -Level Error -Message $_.Exception.Message -ErrorRecord $_ -Tag 'ShowDevDirectoryDashboard', 'Export'
                            $setStatus.Invoke('ShowDevDirectoryDashboard.Status.OperationFailed', @($_.Exception.Message)[0])
                            [System.Windows.MessageBox]::Show($window, $_.Exception.Message, $getLocalized.Invoke('ShowDevDirectoryDashboard.ErrorTitle')[0], [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error) | Out-Null
                        }
                    })[0]
            })

        $controls.ImportBrowseButton.Add_Click({
                $selected = $pickOpenFile.Invoke($controls.ImportPathBox.Text)[0]
                if ($selected) {
                    $controls.ImportPathBox.Text = $selected
                    $syncDataPath.Invoke($selected, $controls.ImportPathBox)[0]
                }
            })

        $controls.ImportLoadButton.Add_Click({
                $path = $controls.ImportPathBox.Text
                if ([string]::IsNullOrWhiteSpace($path)) {
                    [System.Windows.MessageBox]::Show($window, $getLocalized.Invoke('ShowDevDirectoryDashboard.Message.ImportPathMissing')[0], $getLocalized.Invoke('ShowDevDirectoryDashboard.InfoTitle')[0], [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning) | Out-Null
                    return
                }

                $runAsync.Invoke($controls.ImportLoadButton, {
                        try {
                            $setStatus.Invoke('ShowDevDirectoryDashboard.Status.ImportStarted', @($path)[0])
                            $imported = Import-DevDirectoryList -Path $path -ErrorAction Stop
                            $populateCollection.Invoke($state.ImportItems, $imported)
                            $populateCollection.Invoke($state.RestoreItems, $imported)
                            $populateCollection.Invoke($state.SyncItems, $imported)
                            $controls.ImportSummaryText.Text = $formatLocalized.Invoke('ShowDevDirectoryDashboard.ImportSummaryTemplate', @($state.ImportItems.Count)[0])
                            $controls.SyncSummaryText.Text = $formatLocalized.Invoke('ShowDevDirectoryDashboard.SyncSummaryTemplate', @($state.SyncItems.Count)[0])
                            $setStatus.Invoke('ShowDevDirectoryDashboard.Status.ImportComplete', @($state.ImportItems.Count)[0])
                            Write-PSFMessage -Level Verbose -String 'ShowDevDirectoryDashboard.ImportCompleted' -StringValues @($path, $state.ImportItems.Count) -Tag 'ShowDevDirectoryDashboard', 'Import'
                        } catch {
                            Write-PSFMessage -Level Error -Message $_.Exception.Message -ErrorRecord $_ -Tag 'ShowDevDirectoryDashboard', 'Import'
                            $setStatus.Invoke('ShowDevDirectoryDashboard.Status.OperationFailed', @($_.Exception.Message)[0])
                            [System.Windows.MessageBox]::Show($window, $_.Exception.Message, $getLocalized.Invoke('ShowDevDirectoryDashboard.ErrorTitle')[0], [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error) | Out-Null
                        }
                    })[0]
            })

        $controls.RestoreDestinationBrowseButton.Add_Click({
                $selected = $pickFolder.Invoke($controls.RestoreDestinationBox.Text)[0]
                if ($selected) {
                    $controls.RestoreDestinationBox.Text = $selected
                }
            })

        $controls.RestoreRunButton.Add_Click({
                $listPath = $controls.RestoreListPathBox.Text
                $listPath | Out-Null
                $destination = $controls.RestoreDestinationBox.Text

                if ($state.RestoreItems.Count -eq 0) {
                    [System.Windows.MessageBox]::Show($window, $getLocalized.Invoke('ShowDevDirectoryDashboard.Message.NoRepositories')[0], $getLocalized.Invoke('ShowDevDirectoryDashboard.InfoTitle')[0], [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
                    return
                }

                if ([string]::IsNullOrWhiteSpace($destination)) {
                    [System.Windows.MessageBox]::Show($window, $getLocalized.Invoke('ShowDevDirectoryDashboard.Message.RestorePathsMissing')[0], $getLocalized.Invoke('ShowDevDirectoryDashboard.InfoTitle')[0], [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning) | Out-Null
                    return
                }

                $runAsync.Invoke($controls.RestoreRunButton, {
                        try {
                            $setStatus.Invoke('ShowDevDirectoryDashboard.Status.RestoreStarted', @($destination)[0])

                            $restoreParams = @{
                                DestinationPath = $destination
                                ErrorAction     = 'Stop'
                            }

                            if ($controls.RestoreForceCheckBox.IsChecked) { $restoreParams.Force = $true }
                            if ($controls.RestoreSkipExistingCheckBox.IsChecked) { $restoreParams.SkipExisting = $true }

                            $state.RestoreItems | Restore-DevDirectory @restoreParams

                            $setStatus.Invoke('ShowDevDirectoryDashboard.Status.RestoreComplete', @($destination)[0])
                            Write-PSFMessage -Level Verbose -String 'ShowDevDirectoryDashboard.RestoreCompleted' -StringValues @($destination, $state.RestoreItems.Count) -Tag 'ShowDevDirectoryDashboard', 'Restore'
                        } catch {
                            Write-PSFMessage -Level Error -Message $_.Exception.Message -ErrorRecord $_ -Tag 'ShowDevDirectoryDashboard', 'Restore'
                            $setStatus.Invoke('ShowDevDirectoryDashboard.Status.OperationFailed', @($_.Exception.Message)[0])
                            [System.Windows.MessageBox]::Show($window, $_.Exception.Message, $getLocalized.Invoke('ShowDevDirectoryDashboard.ErrorTitle')[0], [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error) | Out-Null
                        }
                    })[0]
            })

        $controls.SyncDirectoryBrowseButton.Add_Click({
                $selected = $pickFolder.Invoke($controls.SyncDirectoryBox.Text)[0]
                if ($selected) {
                    $controls.SyncDirectoryBox.Text = $selected
                }
            })

        $controls.SyncListBrowseButton.Add_Click({
                $selected = $pickOpenFile.Invoke($controls.SyncListPathBox.Text)[0]
                if ($selected) {
                    $controls.SyncListPathBox.Text = $selected
                    $syncDataPath.Invoke($selected, $controls.SyncListPathBox)[0]
                    $controls.ImportLoadButton.RaiseEvent([System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Button]::ClickEvent))
                }
            })

        $controls.SyncRunButton.Add_Click({
                $directory = $controls.SyncDirectoryBox.Text
                $listPath = $controls.SyncListPathBox.Text

                if ([string]::IsNullOrWhiteSpace($directory) -or [string]::IsNullOrWhiteSpace($listPath)) {
                    [System.Windows.MessageBox]::Show($window, $getLocalized.Invoke('ShowDevDirectoryDashboard.Message.SyncPathsMissing')[0], $getLocalized.Invoke('ShowDevDirectoryDashboard.InfoTitle')[0], [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning) | Out-Null
                    return
                }

                $runAsync.Invoke($controls.SyncRunButton, {
                        try {
                            $setStatus.Invoke('ShowDevDirectoryDashboard.Status.SyncStarted', @($directory, $listPath))

                            $syncParams = @{
                                DirectoryPath      = $directory
                                RepositoryListPath = $listPath
                                PassThru           = $true
                                ErrorAction        = 'Stop'
                            }

                            $syncWhatIfEnabled = $false
                            if ($controls.SyncWhatIfCheckBox.IsChecked) {
                                $syncWhatIfEnabled = $true
                                # Capture WhatIf output (PowerShell 7+) and suppress console spam.
                                $syncParams.WhatIf = $true
                                $syncParams.InformationAction = 'SilentlyContinue'
                                $syncParams.InformationVariable = 'syncInformation'
                            }

                            if ($controls.SyncForceCheckBox.IsChecked) { $syncParams.Force = $true }
                            if ($controls.SyncSkipExistingCheckBox.IsChecked) { $syncParams.SkipExisting = $true }
                            if ($controls.SyncShowGitOutputCheckBox.IsChecked) { $syncParams.ShowGitOutput = $true }

                            $syncResult = Sync-DevDirectoryList @syncParams

                            $populateCollection.Invoke($state.SyncItems, $syncResult)
                            $controls.SyncSummaryText.Text = $formatLocalized.Invoke('ShowDevDirectoryDashboard.SyncSummaryTemplate', @($state.SyncItems.Count)[0])
                            $setStatus.Invoke('ShowDevDirectoryDashboard.Status.SyncComplete', @($state.SyncItems.Count)[0])

                            Write-PSFMessage -Level Verbose -String 'ShowDevDirectoryDashboard.SyncCompleted' -StringValues @($directory, $listPath, $state.SyncItems.Count) -Tag 'ShowDevDirectoryDashboard', 'Sync'

                            if ($syncWhatIfEnabled -and $syncInformation) {
                                $whatIfMessages = foreach ($record in $syncInformation) {
                                    if ($null -eq $record) { continue }

                                    # InformationRecord.MessageData is the formatted WhatIf string.
                                    $message = [string]$record.MessageData
                                    if ([string]::IsNullOrWhiteSpace($message)) { continue }

                                    if ($record.Tags -contains 'WhatIf' -or $message.StartsWith('What if:', [System.StringComparison]::OrdinalIgnoreCase)) {
                                        $message
                                    }
                                }

                                if ($whatIfMessages) {
                                    # Prefer the most relevant summary lines (clone/update list file) for status and UI feedback.
                                    $summaryMessages = $whatIfMessages | Where-Object {
                                        $_ -match 'Clone\s+\d+\s+repository' -or $_ -match 'Update\s+repository\s+list\s+file'
                                    }

                                    if (-not $summaryMessages) {
                                        $escapedDirectory = [regex]::Escape($directory)
                                        $escapedListPath = [regex]::Escape($listPath)
                                        $summaryMessages = $whatIfMessages | Where-Object { $_ -match $escapedDirectory -or $_ -match $escapedListPath } | Select-Object -Last 2
                                    }

                                    if (-not $summaryMessages) {
                                        $summaryMessages = $whatIfMessages | Select-Object -Last 2
                                    }

                                    # Minimum requirement: status text must show WhatIf info.
                                    if ($summaryMessages) {
                                        $controls.StatusText.Text = "$($controls.StatusText.Text)$([System.Environment]::NewLine)$($summaryMessages -join [System.Environment]::NewLine)"
                                    }

                                    if ($summaryMessages) {
                                        [System.Windows.MessageBox]::Show(
                                            $window,
                                            ($summaryMessages -join [System.Environment]::NewLine),
                                            $getLocalized.Invoke('ShowDevDirectoryDashboard.InfoTitle')[0],
                                            [System.Windows.MessageBoxButton]::OK,
                                            [System.Windows.MessageBoxImage]::Information
                                        ) | Out-Null
                                    }
                                }
                            }
                        } catch {
                            Write-PSFMessage -Level Error -Message $_.Exception.Message -ErrorRecord $_ -Tag 'ShowDevDirectoryDashboard', 'Sync'
                            $setStatus.Invoke('ShowDevDirectoryDashboard.Status.OperationFailed', @($_.Exception.Message)[0])
                            [System.Windows.MessageBox]::Show($window, $_.Exception.Message, $getLocalized.Invoke('ShowDevDirectoryDashboard.ErrorTitle')[0], [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error) | Out-Null
                        }
                    })[0]
            })

        if ($showWindowResolved) {
            $null = $window.ShowDialog()
        }

        if ($PassThru) {
            return [pscustomobject]@{
                Window   = $window
                Controls = [pscustomobject]$controls
                State    = [pscustomobject]$state
            }
        }
    }

    end {
        Write-PSFMessage -Level Debug -String 'ShowDevDirectoryDashboard.Complete' -StringValues @() -Tag 'ShowDevDirectoryDashboard', 'Complete'
    }
}

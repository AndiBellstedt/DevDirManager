function Show-DevDirectoryDashboard {
    <#
    .SYNOPSIS
        Launches the DevDirManager dashboard UI.

    .DESCRIPTION
        Builds the WPF dashboard for discovering, exporting, importing, restoring, and syncing repositories managed by DevDirManager.

    .PARAMETER RootPath
        Optional path that seeds the discovery tab when the dashboard loads.

    .PARAMETER ShowWindow
        Controls whether the dashboard window is displayed. Defaults to $true. Set to $false with PassThru to build the UI for automation.

    .PARAMETER PassThru
        Returns the window, control references, and state collections for automation without blocking on the UI.

    .EXAMPLE
        Show-DevDirectoryDashboard

        Launch the dashboard interactively using default settings.

    .EXAMPLE
        Show-DevDirectoryDashboard -RootPath 'C:\\Repositories'

        Open the dashboard with the discovery tab seeded to the provided path.

    .EXAMPLE
        Show-DevDirectoryDashboard -ShowWindow:$false -PassThru

        Construct the dashboard without showing it and return window/control references for automation.

    .NOTES
        Version   : 1.1.0
        Author    : Andi Bellstedt, Copilot
        Date      : 2025-11-11
        Keywords  : Dashboard, UI, WPF
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
                }
                Light = @{
                    'Brush.WindowBackground' = '#FFF3F4F6'
                    'Brush.Surface'          = '#FFFFFFFF'
                    'Brush.SurfaceAlt'       = '#FFE8ECF3'
                    'Brush.Border'           = '#FFD1D5DB'
                    'Brush.PrimaryText'      = '#FF1F2937'
                    'Brush.SecondaryText'    = '#FF4B5563'
                    'Brush.GridLines'        = '#FFE5E7EB'
                    'Brush.ButtonText'       = '#FFFFFFFF'
                }
            }

            $paletteKey = if ($isLightTheme) { 'Light' } else { 'Dark' }
            $selectedPalette = $palettes[$paletteKey]

            $createBrush = {
                param([string]$hex)
                $color = [System.Windows.Media.ColorConverter]::ConvertFromString($hex)
                $brush = [System.Windows.Media.SolidColorBrush]::new($color)
                if (-not $brush.IsFrozen) {
                    $brush.Freeze()
                }
                return $brush
            }

            foreach ($entry in $selectedPalette.GetEnumerator()) {
                if ($w.Resources.Contains($entry.Key)) {
                    $w.Resources[$entry.Key] = & $createBrush $entry.Value
                }
            }

            if ($w.Resources.Contains('Brush.Accent')) {
                $accentColor = [System.Windows.SystemParameters]::WindowGlassColor
                $accentBrush = [System.Windows.Media.SolidColorBrush]::new($accentColor)
                if (-not $accentBrush.IsFrozen) {
                    $accentBrush.Freeze()
                }
                $w.Resources['Brush.Accent'] = $accentBrush
            }

            if ($w.Resources.Contains('Brush.ButtonText')) {
                $accentBrush = $w.Resources['Brush.Accent']
                if ($accentBrush -is [System.Windows.Media.SolidColorBrush]) {
                    $accentColor = $accentBrush.Color
                    $luminance = (0.2126 * ($accentColor.R / 255.0)) + (0.7152 * ($accentColor.G / 255.0)) + (0.0722 * ($accentColor.B / 255.0))
                    $foregroundHex = if ($luminance -gt 0.65) { '#FF0F172A' } else { '#FFFFFFFF' }
                    $w.Resources['Brush.ButtonText'] = $createBrush.Invoke($foregroundHex)[0]
                }
            }
        }

        $applyTheme.Invoke($window)[0]

        $controls = [ordered]@{
            HeaderText                       = $window.FindName('HeaderText')
            SubHeaderText                    = $window.FindName('SubHeaderText')
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
            ImportSummaryText                = $window.FindName('ImportSummaryText')
            RestoreTabHeader                 = $window.FindName('RestoreTabHeader')
            RestoreListPathLabel             = $window.FindName('RestoreListPathLabel')
            RestoreListPathBox               = $window.FindName('RestoreListPathBox')
            RestoreListBrowseButton          = $window.FindName('RestoreListBrowseButton')
            RestoreDestinationLabel          = $window.FindName('RestoreDestinationLabel')
            RestoreDestinationBox            = $window.FindName('RestoreDestinationBox')
            RestoreDestinationBrowseButton   = $window.FindName('RestoreDestinationBrowseButton')
            RestoreRunButton                 = $window.FindName('RestoreRunButton')
            RestoreForceCheckBox             = $window.FindName('RestoreForceCheckBox')
            RestoreSkipExistingCheckBox      = $window.FindName('RestoreSkipExistingCheckBox')
            RestoreShowGitOutputCheckBox     = $window.FindName('RestoreShowGitOutputCheckBox')
            RestoreWhatIfCheckBox            = $window.FindName('RestoreWhatIfCheckBox')
            RestoreGrid                      = $window.FindName('RestoreGrid')
            RestoreRelativePathColumn        = $window.FindName('RestoreRelativePathColumn')
            RestoreRemoteUrlColumn           = $window.FindName('RestoreRemoteUrlColumn')
            RestoreIsRemoteAccessibleColumn  = $window.FindName('RestoreIsRemoteAccessibleColumn')
            RestoreStatusDateColumn          = $window.FindName('RestoreStatusDateColumn')
            RestoreSummaryText               = $window.FindName('RestoreSummaryText')
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
        }

        $controls.DiscoverGrid.ItemsSource = $state.DiscoverItems
        $controls.ImportGrid.ItemsSource = $state.ImportItems
        $controls.RestoreGrid.ItemsSource = $state.RestoreItems
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
        $controls.RestoreTabHeader.Text = $getLocalized.Invoke('ShowDevDirectoryDashboard.RestoreTabHeader')[0]
        $controls.RestoreListPathLabel.Text = $getLocalized.Invoke('ShowDevDirectoryDashboard.RestoreListPathLabel')[0]
        $controls.RestoreListBrowseButton.Content = $getLocalized.Invoke('ShowDevDirectoryDashboard.BrowseButton')[0]
        $controls.RestoreDestinationLabel.Text = $getLocalized.Invoke('ShowDevDirectoryDashboard.RestoreDestinationLabel')[0]
        $controls.RestoreDestinationBrowseButton.Content = $getLocalized.Invoke('ShowDevDirectoryDashboard.BrowseButton')[0]
        $controls.RestoreRunButton.Content = $getLocalized.Invoke('ShowDevDirectoryDashboard.RestoreRunButton')[0]
        $controls.RestoreForceCheckBox.Content = $getLocalized.Invoke('ShowDevDirectoryDashboard.RestoreForce')[0]
        $controls.RestoreSkipExistingCheckBox.Content = $getLocalized.Invoke('ShowDevDirectoryDashboard.RestoreSkipExisting')[0]
        $controls.RestoreShowGitOutputCheckBox.Content = $getLocalized.Invoke('ShowDevDirectoryDashboard.RestoreShowGitOutput')[0]
        $controls.RestoreWhatIfCheckBox.Content = $getLocalized.Invoke('ShowDevDirectoryDashboard.RestoreWhatIf')[0]
        $controls.RestoreRelativePathColumn.Header = $getLocalized.Invoke('ShowDevDirectoryDashboard.Column.RelativePath')[0]
        $controls.RestoreRemoteUrlColumn.Header = $getLocalized.Invoke('ShowDevDirectoryDashboard.Column.RemoteUrl')[0]
        $controls.RestoreIsRemoteAccessibleColumn.Header = $getLocalized.Invoke('ShowDevDirectoryDashboard.Column.IsRemoteAccessible')[0]
        $controls.RestoreStatusDateColumn.Header = $getLocalized.Invoke('ShowDevDirectoryDashboard.Column.StatusDate')[0]
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
        $controls.RestoreSummaryText.Text = $formatLocalized.Invoke('ShowDevDirectoryDashboard.RestoreSummaryTemplate', @(0)[0])
        $controls.SyncSummaryText.Text = $formatLocalized.Invoke('ShowDevDirectoryDashboard.SyncSummaryTemplate', @(0)[0])

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
                            $controls.RestoreSummaryText.Text = $formatLocalized.Invoke('ShowDevDirectoryDashboard.RestoreSummaryTemplate', @($state.RestoreItems.Count)[0])
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

        $controls.RestoreListBrowseButton.Add_Click({
                $selected = $pickOpenFile.Invoke($controls.RestoreListPathBox.Text)[0]
                if ($selected) {
                    $controls.RestoreListPathBox.Text = $selected
                    $controls.ImportPathBox.Text = $selected
                    $controls.ImportLoadButton.RaiseEvent([System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Button]::ClickEvent))
                }
            })

        $controls.RestoreDestinationBrowseButton.Add_Click({
                $selected = $pickFolder.Invoke($controls.RestoreDestinationBox.Text)[0]
                if ($selected) {
                    $controls.RestoreDestinationBox.Text = $selected
                }
            })

        $controls.RestoreRunButton.Add_Click({
                $listPath = $controls.RestoreListPathBox.Text
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
                            if ($controls.RestoreShowGitOutputCheckBox.IsChecked) { $restoreParams.ShowGitOutput = $true }
                            if ($controls.RestoreWhatIfCheckBox.IsChecked) { $restoreParams.WhatIf = $true }

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
                    $controls.ImportPathBox.Text = $selected
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
                            $setStatus.Invoke('ShowDevDirectoryDashboard.Status.SyncStarted', @($directory, $listPath)[0])

                            $syncParams = @{
                                DirectoryPath      = $directory
                                RepositoryListPath = $listPath
                                PassThru           = $true
                                ErrorAction        = 'Stop'
                            }

                            if ($controls.SyncForceCheckBox.IsChecked) { $syncParams.Force = $true }
                            if ($controls.SyncSkipExistingCheckBox.IsChecked) { $syncParams.SkipExisting = $true }
                            if ($controls.SyncShowGitOutputCheckBox.IsChecked) { $syncParams.ShowGitOutput = $true }
                            if ($controls.SyncWhatIfCheckBox.IsChecked) { $syncParams.WhatIf = $true }

                            $syncResult = Sync-DevDirectoryList @syncParams
                            $populateCollection.Invoke($state.SyncItems, $syncResult)
                            $controls.SyncSummaryText.Text = $formatLocalized.Invoke('ShowDevDirectoryDashboard.SyncSummaryTemplate', @($state.SyncItems.Count)[0])
                            $setStatus.Invoke('ShowDevDirectoryDashboard.Status.SyncComplete', @($state.SyncItems.Count)[0])
                            Write-PSFMessage -Level Verbose -String 'ShowDevDirectoryDashboard.SyncCompleted' -StringValues @($directory, $listPath, $state.SyncItems.Count) -Tag 'ShowDevDirectoryDashboard', 'Sync'
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

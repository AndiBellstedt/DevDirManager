# This is where the strings go, that are written by
# Write-PSFMessage, Stop-PSFFunction or the PSFramework validation scriptblocks
@{
    # Import-DevDirectoryList
    'ImportDevDirectoryList.Start'                                       = "Starting Import-DevDirectoryList from path: '{0}', Format: '{1}'"
    'ImportDevDirectoryList.ConfigurationFormatExplicit'                 = "Using explicitly specified format: '{0}'"
    'ImportDevDirectoryList.ConfigurationFormatDefault'                  = "Using default format from configuration: '{0}'"
    'ImportDevDirectoryList.FileNotFound'                                = "The specified repository list file '{0}' does not exist."
    'ImportDevDirectoryList.FileNotFoundWarning'                         = "Import file not found: '{0}'"
    'ImportDevDirectoryList.Import'                                      = "Reading repository list from: '{0}'"
    'ImportDevDirectoryList.InferFormatFailed'                           = "Unable to infer import format from path '{0}'. Specify the Format parameter."
    'ImportDevDirectoryList.FormatResolved'                              = "Resolved import format: '{0}'"
    'ImportDevDirectoryList.DeserializationStart'                        = "Starting deserialization from {0} format"
    'ImportDevDirectoryList.DeserializationCSV'                          = "Using Import-Csv for CSV deserialization"
    'ImportDevDirectoryList.TypeConversionCSV'                           = "Imported {0} objects from CSV, performing type conversions"
    'ImportDevDirectoryList.StatusDateParsed'                            = "Successfully parsed StatusDate: '{0}'"
    'ImportDevDirectoryList.CompleteCSV'                                 = "Successfully imported {0} repositories from CSV file"
    'ImportDevDirectoryList.DeserializationJSON'                         = "Using ConvertFrom-Json for JSON deserialization"
    'ImportDevDirectoryList.EmptyJSON'                                   = "JSON file is empty or contains only whitespace"
    'ImportDevDirectoryList.TypeConversionJSON'                          = "Imported {0} objects from JSON, adding type information"
    'ImportDevDirectoryList.CompleteJSON'                                = "Successfully imported {0} repositories from JSON file"
    'ImportDevDirectoryList.DeserializationXML'                          = "Using Import-Clixml for XML deserialization"
    'ImportDevDirectoryList.TypeConversionXML'                           = "Imported {0} objects from XML, adding type information"
    'ImportDevDirectoryList.CompleteXML'                                 = "Successfully imported {0} repositories from XML file"

    # Export-DevDirectoryList
    'ExportDevDirectoryList.Start'                                       = "Starting Export-DevDirectoryList to path: '{0}', Format: '{1}'"
    'ExportDevDirectoryList.ConfigurationFormatExplicit'                 = "Using explicitly specified format: '{0}'"
    'ExportDevDirectoryList.ConfigurationFormatDefault'                  = "Using default format from configuration: '{0}'"
    'ExportDevDirectoryList.CollectObject'                               = "Collecting repository object into export list"
    'ExportDevDirectoryList.ProcessExport'                               = "Processing export of {0} repository objects"
    'ExportDevDirectoryList.NoRepositoryEntries'                         = 'No repository entries received for export.'
    'ExportDevDirectoryList.FormatResolved'                              = "Resolved export format: '{0}'"
    'ExportDevDirectoryList.CreateOutputDirectory'                       = "Creating output directory: '{0}'"
    'ExportDevDirectoryList.ActionExport'                                = 'Export repository list as {0}'
    'ExportDevDirectoryList.ExportCanceled'                              = "Export canceled by user (WhatIf/Confirm)"
    'ExportDevDirectoryList.SerializationStart'                          = "Serializing {0} repositories to '{1}' in {2} format"
    'ExportDevDirectoryList.SerializationCSV'                            = "Using Export-Csv for CSV serialization"
    'ExportDevDirectoryList.SerializationJSON'                           = "Using ConvertTo-Json with depth 5 for JSON serialization"
    'ExportDevDirectoryList.SerializationXML'                            = "Using Export-Clixml for XML serialization"
    'ExportDevDirectoryList.Complete'                                    = "Successfully exported {0} repositories to '{1}' in {2} format"

    # Get-DevDirectory
    'GetDevDirectory.Start'                                              = "Starting Get-DevDirectory with RootPath: '{0}', SkipRemoteCheck: {1}"
    'GetDevDirectory.ConfigurationRemoteName'                            = "Using remote name '{0}' from configuration"
    'GetDevDirectory.ScanStart'                                          = "Scanning directory tree starting at: '{0}'"
    'GetDevDirectory.RepositoryFound'                                    = "Found repository at: '{0}'"
    'GetDevDirectory.RemoteCheckStart'                                   = "Checking remote accessibility for: '{0}'"
    'GetDevDirectory.RemoteCheckResult'                                  = "Remote accessibility for '{0}': {1}"
    'GetDevDirectory.RemoteCheckNoUrl'                                   = "No remote URL found for '{0}', marking as inaccessible"
    'GetDevDirectory.DirectoryEnumerationFailed'                         = 'Skipping directory {0} due to {1}.'
    'GetDevDirectory.ScanComplete'                                       = "Repository scan completed. Found {0} repositories"

    # Restore-DevDirectory
    'RestoreDevDirectory.Start'                                          = "Starting Restore-DevDirectory to destination: '{0}', Force: {1}, SkipExisting: {2}, ShowGitOutput: {3}"
    'RestoreDevDirectory.ConfigurationGitExe'                            = "Using git executable: '{0}'"
    'RestoreDevDirectory.GitExeResolved'                                 = "Git executable resolved to: '{0}'"
    'RestoreDevDirectory.GitExeNotFound'                                 = "Git executable not found: '{0}'"
    'RestoreDevDirectory.GitExecutableMissing'                           = "Unable to locate the git executable '{0}'. Ensure Git is installed and available in PATH."
    'RestoreDevDirectory.DestinationNormalized'                          = "Normalized destination path: '{0}'"
    'RestoreDevDirectory.ProcessingRepositories'                         = "Processing {0} repositories for restore"
    'RestoreDevDirectory.MissingRemoteUrl'                               = 'Skipping repository with missing RemoteUrl: {0}.'
    'RestoreDevDirectory.MissingRelativePath'                            = 'Skipping repository with missing RelativePath for remote {0}.'
    'RestoreDevDirectory.UnsafeRelativePath'                             = "Skipping repository with unsafe relative path '{0}'."
    'RestoreDevDirectory.OutOfScopePath'                                 = "Skipping repository with out-of-scope path '{0}'."
    'RestoreDevDirectory.ExistingTargetVerbose'                          = 'Skipping existing repository target {0}.'
    'RestoreDevDirectory.TargetExistsWarning'                            = 'Target directory {0} already exists. Use -Force to overwrite or -SkipExisting to ignore.'
    'RestoreDevDirectory.ActionClone'                                    = 'Clone repository from {0}'
    'RestoreDevDirectory.CloneFailed'                                    = "git clone for '{0}' failed with exit code {1}."
    'RestoreDevDirectory.ConfigFailed'                                   = "Failed to set git config {0} to '{1}' for repository at {2}. Exit code: {3}"
    'RestoreDevDirectory.InaccessibleRemoteSkipped'                      = "Skipping repository '{0}' with inaccessible remote: {1}"
    'RestoreDevDirectory.Complete'                                       = "Restore operation completed. Processed {0} repositories"

    # Sync-DevDirectoryList
    'SyncDevDirectoryList.Start'                                         = "Starting Sync-DevDirectoryList with DirectoryPath: '{0}', RepositoryListPath: '{1}', Force: {2}, SkipExisting: {3}, ShowGitOutput: {4}"
    'SyncDevDirectoryList.ConfigurationRemoteName'                       = "Using remote name '{0}' from configuration"
    'SyncDevDirectoryList.DirectoryNormalized'                           = "Normalized directory path: '{0}'"
    'SyncDevDirectoryList.SyncStart'                                     = "Starting synchronization process"
    'SyncDevDirectoryList.ImportingFromFile'                             = "Repository list file exists, importing entries from: '{0}'"
    'SyncDevDirectoryList.ActionCreateRootDirectory'                     = 'Create repository root directory'
    'SyncDevDirectoryList.ActionCloneFromList'                           = 'Clone {0} repository/repositories from list'
    'SyncDevDirectoryList.ActionCreateListDirectory'                     = 'Create directory for repository list file'
    'SyncDevDirectoryList.ActionUpdateListFile'                          = 'Update repository list file'
    'SyncDevDirectoryList.ImportFailed'                                  = 'Unable to import repository list from {0}: {1}'
    'SyncDevDirectoryList.UnsafeFileEntry'                               = 'Repository list entry with unsafe relative path {0} has been skipped.'
    'SyncDevDirectoryList.UnsafeLocalEntry'                              = 'Ignoring local repository with unsafe relative path {0}.'
    'SyncDevDirectoryList.RemoteUrlMismatch'                             = 'Remote URL mismatch for {0}. Keeping local value {1} over file value {2}.'
    'SyncDevDirectoryList.MissingRemoteUrl'                              = 'Repository list entry {0} lacks a RemoteUrl and cannot be cloned.'
    'SyncDevDirectoryList.MissingRootDirectory'                          = 'Repository root directory {0} does not exist; skipping clone operations.'
    'SyncDevDirectoryList.InaccessibleRemoteSkipped'                     = "Skipping repository '{0}' with inaccessible remote: {1}"
    'SyncDevDirectoryList.Complete'                                      = "Synchronization completed. Final repository count: {0}"

    # Publish-DevDirectoryList
    'PublishDevDirectoryList.Start'                                      = "Starting Publish-DevDirectoryList with ParameterSet: '{0}', Public: {1}, GistId: '{2}'"
    'PublishDevDirectoryList.AuthenticationDecrypt'                      = "Decrypting AccessToken for GitHub API authentication"
    'PublishDevDirectoryList.TokenEmpty'                                 = 'The provided access token is empty after conversion.'
    'PublishDevDirectoryList.TokenEmptyError'                            = "AccessToken is empty or null"
    'PublishDevDirectoryList.ConfigurationApiUrl'                        = "Configured API endpoint: '{0}'"
    'PublishDevDirectoryList.CollectPipelineObject'                      = "Collecting repository object from pipeline"
    'PublishDevDirectoryList.NoPipelineData'                             = 'No repository metadata was received from the pipeline.'
    'PublishDevDirectoryList.ConvertToJson'                              = "Converting {0} pipeline objects to JSON"
    'PublishDevDirectoryList.ReadFile'                                   = "Reading repository list from file: '{0}'"
    'PublishDevDirectoryList.FormatDetected'                             = "Detected file format: '{0}'"
    'PublishDevDirectoryList.ReadJsonDirect'                             = "File is JSON, reading directly"
    'PublishDevDirectoryList.ConvertFormat'                              = "Converting {0} to JSON"
    'PublishDevDirectoryList.EmptyContent'                               = 'The repository list content is empty. Nothing will be published.'
    'PublishDevDirectoryList.SearchGist'                                 = "Searching for existing gist with description 'GitRepositoryList'"
    'PublishDevDirectoryList.GistFound'                                  = "Found existing gist with ID: '{0}'"
    'PublishDevDirectoryList.GistNotFound'                               = "No existing gist found, will create new"
    'PublishDevDirectoryList.QueryGistFailed'                            = 'Failed to query existing gists: {0}'
    'PublishDevDirectoryList.UsingProvidedGistId'                        = "Using provided GistId: '{0}'"
    'PublishDevDirectoryList.PublishCanceled'                            = "Publish canceled by user (WhatIf/Confirm)"
    'PublishDevDirectoryList.UpdatingGist'                               = "Updating existing gist: '{0}'"
    'PublishDevDirectoryList.CreatingGist'                               = "Creating new gist"
    'PublishDevDirectoryList.Complete'                                   = "Successfully published repository list to gist. GistId: '{0}', URL: '{1}'"
    'PublishDevDirectoryList.CleanupTokens'                              = "Cleaning up authentication tokens"
    'PublishDevDirectoryList.ActionPublish'                              = 'Publish DevDirManager repository list to GitHub Gist'
    'PublishDevDirectoryList.TargetLabelCreate'                          = 'Create gist GitRepositoryList'
    'PublishDevDirectoryList.TargetLabelUpdate'                          = 'Update gist {0}'

    # Internal functions - Get-DevDirectoryRemoteUrl
    'GetDevDirectoryRemoteUrl.Start'                                     = "Extracting remote URL for '{0}' from repository: '{1}'"
    'GetDevDirectoryRemoteUrl.ConfigPath'                                = "Git config path: '{0}'"
    'GetDevDirectoryRemoteUrl.ConfigMissing'                             = 'No .git\\config file found at {0}.'
    'GetDevDirectoryRemoteUrl.ConfigNotFound'                            = "Git config file not found, returning null"
    'GetDevDirectoryRemoteUrl.ReadingConfig'                             = "Reading git config file"
    'GetDevDirectoryRemoteUrl.SearchingSection'                          = "Searching for section pattern: '{0}'"
    'GetDevDirectoryRemoteUrl.RemoteUrlFound'                            = "Remote URL for '{0}': '{1}'"
    'GetDevDirectoryRemoteUrl.RemoteNotFound'                            = "Remote '{0}' not found or has no URL configured"

    # Internal functions - Get-DevDirectoryUserInfo
    'GetDevDirectoryUserInfo.Start'                                      = "Extracting user info from repository: '{0}'"
    'GetDevDirectoryUserInfo.ConfigPath'                                 = "Git config path: '{0}'"
    'GetDevDirectoryUserInfo.ConfigMissing'                              = "No .git\\config file found at {0}."
    'GetDevDirectoryUserInfo.ConfigNotFound'                             = "Git config file not found, returning null values"
    'GetDevDirectoryUserInfo.ReadingConfig'                              = "Reading git config file"
    'GetDevDirectoryUserInfo.SectionFound'                               = "Found [user] section in git config"
    'GetDevDirectoryUserInfo.UserNameFound'                              = "Found user.name: '{0}'"
    'GetDevDirectoryUserInfo.UserEmailFound'                             = "Found user.email: '{0}'"
    'GetDevDirectoryUserInfo.Result'                                     = "User info extracted - UserName: '{0}', UserEmail: '{1}'"

    # Internal functions - Test-DevDirectoryRemoteAccessible
    'TestDevDirectoryRemoteAccessible.EmptyUrl'                          = "Remote URL is empty or whitespace; skipping remote accessibility check."
    'TestDevDirectoryRemoteAccessible.CheckingRemote'                    = "Checking remote accessibility for: {0}"
    'TestDevDirectoryRemoteAccessible.Timeout'                           = "Remote check timed out after {0} seconds for: {1}"
    'TestDevDirectoryRemoteAccessible.Accessible'                        = "Remote is accessible: {0}"
    'TestDevDirectoryRemoteAccessible.NotAccessible'                     = "Remote is not accessible (exit code {0}): {1}"
    'TestDevDirectoryRemoteAccessible.Error'                             = "Error checking remote accessibility for {0} : {1}"
    'TestDevDirectoryRemoteAccessible.ProcessStartFailed'                = "Unable to start git ls-remote for remote '{0}'. Verify the git executable path."

    # Internal functions - ConvertTo-NormalizedRelativePath
    'ConvertToNormalizedRelativePath.Start'                              = "Normalizing relative path: '{0}'"
    'ConvertToNormalizedRelativePath.EmptyPath'                          = "Path is empty, whitespace, or '.', returning '.'"
    'ConvertToNormalizedRelativePath.AfterTrim'                          = "After trim: '{0}'"
    'ConvertToNormalizedRelativePath.AfterCleanup'                       = "After slash cleanup: '{0}'"
    'ConvertToNormalizedRelativePath.BecameEmpty'                        = "Path became empty after normalization, returning '.'"
    'ConvertToNormalizedRelativePath.Result'                             = "Path normalized: '{0}' -> '{1}'"

    # Internal functions - Add-RepositoryTypeName
    'AddRepositoryTypeName.Start'                                        = "Adding DevDirManager.Repository type name to object"
    'AddRepositoryTypeName.Result'                                       = "Type name added to object"

    # Show-DevDirectoryDashboard
    'ShowDevDirectoryDashboard.Start'                                    = "Launching Show-DevDirectoryDashboard with RootPath '{0}' (ShowWindow={1}, PassThru={2})."
    'ShowDevDirectoryDashboard.Complete'                                 = "Show-DevDirectoryDashboard finished."
    'ShowDevDirectoryDashboard.UnsupportedPlatform'                      = "Show-DevDirectoryDashboard requires Windows with WPF support."
    'ShowDevDirectoryDashboard.RequiresSta'                              = "Show-DevDirectoryDashboard must run in a PowerShell session configured for STA threading."
    'ShowDevDirectoryDashboard.XamlMissing'                              = "The dashboard layout file '{0}' could not be found."
    'ShowDevDirectoryDashboard.WindowTitle'                              = "DevDirManager Dashboard"
    'ShowDevDirectoryDashboard.Header'                                   = "DevDirManager Control Center"
    'ShowDevDirectoryDashboard.SubHeader'                                = "Discover, export, restore, and sync repositories in one place."
    'ShowDevDirectoryDashboard.DiscoverTabHeader'                        = "Discover & Export"
    'ShowDevDirectoryDashboard.DiscoverPathLabel'                        = "Source folder:"
    'ShowDevDirectoryDashboard.BrowseButton'                             = "Browse"
    'ShowDevDirectoryDashboard.ScanButton'                               = "Scan"
    'ShowDevDirectoryDashboard.ExportTabHeader'                          = "Export"
    'ShowDevDirectoryDashboard.ExportFormatLabel'                        = "Format:"
    'ShowDevDirectoryDashboard.ExportPathLabel'                          = "Output file:"
    'ShowDevDirectoryDashboard.ExportRunButton'                          = "Export"
    'ShowDevDirectoryDashboard.ImportTabHeader'                          = "Import & Restore"
    'ShowDevDirectoryDashboard.ImportPathLabel'                          = "Data file:"
    'ShowDevDirectoryDashboard.ImportLoadButton'                         = "Load"
    'ShowDevDirectoryDashboard.RestoreTabHeader'                         = "Restore"
    'ShowDevDirectoryDashboard.RestoreListPathLabel'                     = "Data file:"
    'ShowDevDirectoryDashboard.RestoreDestinationLabel'                  = "Destination root:"
    'ShowDevDirectoryDashboard.RestoreRunButton'                         = "Restore"
    'ShowDevDirectoryDashboard.RestoreForce'                             = "Force replace"
    'ShowDevDirectoryDashboard.RestoreSkipExisting'                      = "Skip existing"
    'ShowDevDirectoryDashboard.RestoreShowGitOutput'                     = "Show git output"
    'ShowDevDirectoryDashboard.RestoreWhatIf'                            = "What if"
    'ShowDevDirectoryDashboard.RestoreSummaryTemplate'                   = "Repositories ready to restore: {0}"
    'ShowDevDirectoryDashboard.SyncTabHeader'                            = "Sync"
    'ShowDevDirectoryDashboard.SyncDirectoryLabel'                       = "Workspace:"
    'ShowDevDirectoryDashboard.SyncListPathLabel'                        = "Data file:"
    'ShowDevDirectoryDashboard.SyncRunButton'                            = "Sync"
    'ShowDevDirectoryDashboard.SyncForce'                                = "Force replace"
    'ShowDevDirectoryDashboard.SyncSkipExisting'                         = "Skip existing"
    'ShowDevDirectoryDashboard.SyncShowGitOutput'                        = "Show git output"
    'ShowDevDirectoryDashboard.SyncWhatIf'                               = "What if"
    'ShowDevDirectoryDashboard.SyncSummaryTemplate'                      = "Repositories available for sync: {0}"
    'ShowDevDirectoryDashboard.Format.JSON'                              = "JSON (recommended)"
    'ShowDevDirectoryDashboard.Format.CSV'                               = "CSV"
    'ShowDevDirectoryDashboard.Format.XML'                               = "XML"
    'ShowDevDirectoryDashboard.DiscoverSummaryTemplate'                  = "Repositories discovered: {0}"
    'ShowDevDirectoryDashboard.ExportSummaryTemplate'                    = "Repositories ready to export: {0}"
    'ShowDevDirectoryDashboard.ImportSummaryTemplate'                    = "Repositories imported: {0}"
    'ShowDevDirectoryDashboard.Column.RelativePath'                      = "Relative path"
    'ShowDevDirectoryDashboard.Column.RemoteName'                        = "Remote name"
    'ShowDevDirectoryDashboard.Column.RemoteUrl'                         = "Remote URL"
    'ShowDevDirectoryDashboard.Column.IsRemoteAccessible'                = "Remote accessible"
    'ShowDevDirectoryDashboard.Column.UserName'                          = "User name"
    'ShowDevDirectoryDashboard.Column.UserEmail'                         = "User email"
    'ShowDevDirectoryDashboard.Column.StatusDate'                        = "Status date"
    'ShowDevDirectoryDashboard.Status.Ready'                             = "Ready."
    'ShowDevDirectoryDashboard.Status.ScanStarted'                       = "Scanning {0} ..."
    'ShowDevDirectoryDashboard.Status.ScanComplete'                      = "Scan complete. Repositories found: {0}"
    'ShowDevDirectoryDashboard.Status.ExportStarted'                     = "Exporting to {0} ..."
    'ShowDevDirectoryDashboard.Status.ExportComplete'                    = "Export completed: {0}"
    'ShowDevDirectoryDashboard.Status.ImportStarted'                     = "Importing from {0} ..."
    'ShowDevDirectoryDashboard.Status.ImportComplete'                    = "Import completed. Repositories loaded: {0}"
    'ShowDevDirectoryDashboard.Status.RestoreStarted'                    = "Restoring repositories to {0} ..."
    'ShowDevDirectoryDashboard.Status.RestoreComplete'                   = "Restore completed to {0}"
    'ShowDevDirectoryDashboard.Status.SyncStarted'                       = "Synchronizing {0} with {1} ..."
    'ShowDevDirectoryDashboard.Status.SyncComplete'                      = "Synchronization complete. Repositories processed: {0}"
    'ShowDevDirectoryDashboard.Status.OperationFailed'                   = "Operation failed: {0}"
    'ShowDevDirectoryDashboard.Message.NoRepositories'                   = "There are no repositories to process yet. Discover or import data first."
    'ShowDevDirectoryDashboard.Message.ExportPathMissing'                = "Select an output file before exporting."
    'ShowDevDirectoryDashboard.Message.ImportPathMissing'                = "Select a data file to import."
    'ShowDevDirectoryDashboard.Message.RestorePathsMissing'              = "Select a destination path before restoring."
    'ShowDevDirectoryDashboard.Message.SyncPathsMissing'                 = "Provide both workspace and data file before running sync."
    'ShowDevDirectoryDashboard.Message.ExportSuccess'                    = "Repository list exported to {0}."
    'ShowDevDirectoryDashboard.InfoTitle'                                = "DevDirManager"
    'ShowDevDirectoryDashboard.ErrorTitle'                               = "DevDirManager error"
    'ShowDevDirectoryDashboard.ScanCompleted'                            = "Scan finished for '{0}' with {1} repositories."
    'ShowDevDirectoryDashboard.ExportCompleted'                          = "Export completed to '{0}' using format {1} with {2} repositories."
    'ShowDevDirectoryDashboard.ImportCompleted'                          = "Import completed from '{0}' with {1} repositories."
    'ShowDevDirectoryDashboard.RestoreCompleted'                         = "Restore completed to '{0}' with {1} repositories."
    'ShowDevDirectoryDashboard.SyncCompleted'                            = "Sync completed for directory '{0}' and list '{1}' with {2} repositories."

    # Get-DevDirectorySetting
    'GetDevDirectorySetting.Start'                                       = "Retrieving DevDirManager system settings"
    'GetDevDirectorySetting.FileNotFound'                                = "Configuration file not found: '{0}'. Settings have not been initialized. Run Set-DevDirectorySetting first."
    'GetDevDirectorySetting.ReadFailed'                                  = "Failed to read configuration file '{0}': {1}"
    'GetDevDirectorySetting.ReturnSingleValue'                           = "Returning single setting value: '{0}'"
    'GetDevDirectorySetting.Complete'                                    = "Retrieved system settings for computer '{0}'"
    'GetDevDirectorySetting.End'                                         = "Get-DevDirectorySetting completed"

    # Set-DevDirectorySetting
    'SetDevDirectorySetting.Start'                                       = "Configuring DevDirManager system settings"
    'SetDevDirectorySetting.PathNormalized'                              = "{0} normalized to: '{1}'"
    'SetDevDirectorySetting.PathTraversalError'                          = "{0} contains unsafe path traversal sequence (..): '{1}'"
    'SetDevDirectorySetting.PathValidation'                              = "Validating path: '{0}'"
    'SetDevDirectorySetting.PathNotFound'                                = "Warning: Path '{0}' does not exist"
    'SetDevDirectorySetting.ConfigUpdated'                               = "Configuration updated: {0} = '{1}'"
    'SetDevDirectorySetting.DirectoryCreated'                            = "Created configuration directory: '{0}'"
    'SetDevDirectorySetting.Persisted'                                   = "Settings persisted to '{0}'"
    'SetDevDirectorySetting.Complete'                                    = "System settings configured successfully. Settings persisted to '{0}'"
    'SetDevDirectorySetting.ShouldProcess.Target'                        = "DevDirManager system configuration"
    'SetDevDirectorySetting.ShouldProcess.Action'                        = "Set setting '{0}' to '{1}'"
    'SetDevDirectorySetting.ReadFailed'                                  = "Failed to read configuration file '{0}': {1}"

    # Invoke-DevDirectorySyncSchedule
    'InvokeDevDirectorySyncSchedule.Start'                               = "Starting system-configured sync for computer '{0}'"
    'InvokeDevDirectorySyncSchedule.NotConfigured.RepositoryListPath'    = "RepositoryListPath is not configured. Run Set-DevDirectorySetting first."
    'InvokeDevDirectorySyncSchedule.NotConfigured.LocalDevDirectory'     = "LocalDevDirectory is not configured. Run Set-DevDirectorySetting first."
    'InvokeDevDirectorySyncSchedule.RepositoryListNotFound'              = "Repository list file not found: '{0}'"
    'InvokeDevDirectorySyncSchedule.FilterApplied'                       = "{0} of {1} repositories match system filter for '{2}'"
    'InvokeDevDirectorySyncSchedule.NoMatchingRepositories'              = "No repositories match the system filter for computer '{0}'"
    'InvokeDevDirectorySyncSchedule.Complete'                            = "Sync completed: {0} repositories synchronized"
    'InvokeDevDirectorySyncSchedule.ConfigUpdateFailed'                  = "Failed to update configuration with error status: {0}"
    'InvokeDevDirectorySyncSchedule.ShouldProcess.Target'                = "{0} repositories from '{1}'"
    'InvokeDevDirectorySyncSchedule.ShouldProcess.Action'                = "Sync to '{0}'"
    'InvokeDevDirectorySyncSchedule.End'                                 = "Invoke-DevDirectorySyncSchedule completed"

    # Register-DevDirectoryScheduledSync
    'RegisterDevDirectoryScheduledSync.Start'                            = "Creating scheduled task '{0}'"
    'RegisterDevDirectoryScheduledSync.NotConfigured.RepositoryListPath' = "RepositoryListPath is not configured. Run Set-DevDirectorySetting first."
    'RegisterDevDirectoryScheduledSync.NotConfigured.LocalDevDirectory'  = "LocalDevDirectory is not configured. Run Set-DevDirectorySetting first."
    'RegisterDevDirectoryScheduledSync.Exists'                           = "Scheduled task '{0}' already exists. Use -Force to overwrite."
    'RegisterDevDirectoryScheduledSync.RemovingExisting'                 = "Removing existing scheduled task '{0}'"
    'RegisterDevDirectoryScheduledSync.UnregisterFailed'                 = "Failed to remove existing scheduled task '{0}'"
    'RegisterDevDirectoryScheduledSync.RegisterFailed'                   = "Failed to register scheduled task '{0}'"
    'RegisterDevDirectoryScheduledSync.TaskNotReturned'                  = "Scheduled task '{0}' was not created successfully"
    'RegisterDevDirectoryScheduledSync.Created'                          = "Scheduled task '{0}' created: runs every {1} minutes"
    'RegisterDevDirectoryScheduledSync.Complete'                         = "Scheduled task registration completed"
    'RegisterDevDirectoryScheduledSync.TaskDescription'                  = "DevDirManager automatic repository synchronization. Syncs repositories from the configured central list to the local development directory."
    'RegisterDevDirectoryScheduledSync.AutoSyncEnabled'                  = "AutoSyncEnabled setting has been set to true."
    'RegisterDevDirectoryScheduledSync.ShouldProcess.Target'             = "Scheduled Task '{0}'"
    'RegisterDevDirectoryScheduledSync.ShouldProcess.Action'             = "Register with {0} minute interval"

    # Unregister-DevDirectoryScheduledSync
    'UnregisterDevDirectoryScheduledSync.Start'                          = "Removing scheduled task '{0}'"
    'UnregisterDevDirectoryScheduledSync.NotFound'                       = "Scheduled task '{0}' not found"
    'UnregisterDevDirectoryScheduledSync.UnregisterFailed'               = "Failed to remove scheduled task '{0}'"
    'UnregisterDevDirectoryScheduledSync.Removed'                        = "Scheduled task '{0}' removed"
    'UnregisterDevDirectoryScheduledSync.Complete'                       = "Scheduled task removal completed"
    'UnregisterDevDirectoryScheduledSync.AutoSyncDisabled'               = "AutoSyncEnabled setting has been set to false."
    'UnregisterDevDirectoryScheduledSync.ShouldProcess.Target'           = "Scheduled Task '{0}'"
    'UnregisterDevDirectoryScheduledSync.ShouldProcess.Action'           = "Remove scheduled task"

    # Write-ConfigFileWithRetry (internal helper)
    'WriteConfigFileWithRetry.Start'                                     = "Writing configuration file: '{0}'"
    'WriteConfigFileWithRetry.AcquiringLock'                             = "Acquiring exclusive lock on '{0}' (attempt {1})"
    'WriteConfigFileWithRetry.LockAcquired'                              = "Exclusive lock acquired on '{0}'"
    'WriteConfigFileWithRetry.Success'                                   = "Configuration file '{0}' written successfully on attempt {1}"
    'WriteConfigFileWithRetry.IOError'                                   = "File write attempt {0} failed: {1}"
    'WriteConfigFileWithRetry.Retrying'                                  = "Retrying in {0}ms ({1} attempts remaining)"
    'WriteConfigFileWithRetry.UnexpectedError'                           = "Unexpected error during file write: {0}"
    'WriteConfigFileWithRetry.AllAttemptsFailed'                         = "Failed to write configuration file after {0} attempts. The file may be locked by another process."
    'WriteConfigFileWithRetry.Complete'                                  = "Write-ConfigFileWithRetry completed for '{0}'"

    # DevDirSettingsImport (internal script)
    'DevDirSettingsImport.ConfigLoaded'                                  = "Loaded DevDirManager configuration from '{0}'"
    'DevDirSettingsImport.ConfigLoadFailed'                              = "Failed to load configuration from '{0}': {1}"
    'DevDirSettingsImport.ConfigNotFound'                                = "No configuration file found at '{0}'. Using defaults."
    'DevDirSettingsImport.CreateDefaultConfig'                           = "Creating default configuration file at '{0}'"
    'DevDirSettingsImport.ConfigFileCreated'                             = "Configuration file created successfully at '{0}'"
    'DevDirSettingsImport.AutoSyncInconsistent.TaskMissing'              = "AutoSyncEnabled is true, but scheduled task '{0}' does not exist. Run Register-DevDirectoryScheduledSync to create it."
    'DevDirSettingsImport.AutoSyncInconsistent.TaskDisabled'             = "AutoSyncEnabled is true, but scheduled task '{0}' is disabled. Enable it or set AutoSyncEnabled to false."
    'DevDirSettingsImport.AutoSyncInconsistent.TaskExists'               = "AutoSyncEnabled is false, but scheduled task '{0}' exists and is enabled. Remove the task or set AutoSyncEnabled to true."

    # Test-DevDirectorySystemFilter
    'TestDevDirectorySystemFilter.EmptyFilter'                           = "SystemFilter is empty, matching all systems"
    'TestDevDirectorySystemFilter.WildcardFilter'                        = "SystemFilter is '*', matching all systems"
    'TestDevDirectorySystemFilter.MatchedExclusion'                      = "Computer '{0}' matches exclusion pattern '{1}'"
    'TestDevDirectorySystemFilter.MatchedInclusion'                      = "Computer '{0}' matches inclusion pattern '{1}'"
    'TestDevDirectorySystemFilter.Excluded'                              = "Computer '{0}' excluded by filter '{1}'"
    'TestDevDirectorySystemFilter.InclusionResult'                       = "Computer '{0}' inclusion check result: {1}"
    'TestDevDirectorySystemFilter.NotExcluded'                           = "Computer '{0}' not excluded, allowing"

    # Generic / Shared
    'RepositoryList.UsingDefaultFormat'                                  = "Using configured default format '{0}' for file '{1}'."
    'GetDevDirectoryStatusDate.GitFolderMissing'                         = 'No .git folder found at {0}.'
}
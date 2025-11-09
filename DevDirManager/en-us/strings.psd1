# This is where the strings go, that are written by
# Write-PSFMessage, Stop-PSFFunction or the PSFramework validation scriptblocks
@{
    'ImportDevDirectoryList.FileNotFound'            = "The specified repository list file '{0}' does not exist."
    'RepositoryList.UsingDefaultFormat'              = "Using configured default format '{0}' for file '{1}'."
    'ImportDevDirectoryList.InferFormatFailed'       = "Unable to infer import format from path '{0}'. Specify the Format parameter."

    'ExportDevDirectoryList.NoRepositoryEntries'     = 'No repository entries received for export.'
    'ExportDevDirectoryList.InferFormatFailed'       = "Unable to infer export format from path '{0}'. Specify the Format parameter."
    'ExportDevDirectoryList.ActionExport'            = 'Export repository list as {0}'

    'RestoreDevDirectory.GitExecutableMissing'       = "Unable to locate the git executable '{0}'. Ensure Git is installed and available in PATH."
    'RestoreDevDirectory.MissingRemoteUrl'           = 'Skipping repository with missing RemoteUrl: {0}.'
    'RestoreDevDirectory.MissingRelativePath'        = 'Skipping repository with missing RelativePath for remote {0}.'
    'RestoreDevDirectory.UnsafeRelativePath'         = "Skipping repository with unsafe relative path '{0}'."
    'RestoreDevDirectory.OutOfScopePath'             = "Skipping repository with out-of-scope path '{0}'."
    'RestoreDevDirectory.ExistingTargetVerbose'      = 'Skipping existing repository target {0}.'
    'RestoreDevDirectory.TargetExistsWarning'        = 'Target directory {0} already exists. Use -Force to overwrite or -SkipExisting to ignore.'
    'RestoreDevDirectory.ActionClone'                = 'Clone repository from {0}'
    'RestoreDevDirectory.CloneFailed'                = "git clone for '{0}' failed with exit code {1}."

    'SyncDevDirectoryList.ActionCreateRootDirectory' = 'Create repository root directory'
    'SyncDevDirectoryList.ActionCloneFromList'       = 'Clone {0} repository/repositories from list'
    'SyncDevDirectoryList.ActionCreateListDirectory' = 'Create directory for repository list file'
    'SyncDevDirectoryList.ActionUpdateListFile'      = 'Update repository list file'
    'SyncDevDirectoryList.ImportFailed'              = 'Unable to import repository list from {0}: {1}'
    'SyncDevDirectoryList.UnsafeFileEntry'           = 'Repository list entry with unsafe relative path {0} has been skipped.'
    'SyncDevDirectoryList.UnsafeLocalEntry'          = 'Ignoring local repository with unsafe relative path {0}.'
    'SyncDevDirectoryList.RemoteUrlMismatch'         = 'Remote URL mismatch for {0}. Keeping local value {1} over file value {2}.'
    'SyncDevDirectoryList.MissingRemoteUrl'          = 'Repository list entry {0} lacks a RemoteUrl and cannot be cloned.'
    'SyncDevDirectoryList.MissingRootDirectory'      = 'Repository root directory {0} does not exist; skipping clone operations.'

    'GetDevDirectory.DirectoryEnumerationFailed'     = 'Skipping directory {0} due to {1}.'
    'GetDevDirectoryRemoteUrl.ConfigMissing'         = 'No .git\\config file found at {0}.'
    'GetDevDirectoryUserInfo.ConfigMissing'          = 'No .git\\config file found at {0}.'
    'GetDevDirectoryStatusDate.GitFolderMissing'     = 'No .git folder found at {0}.'

    'PublishDevDirectoryList.TokenEmpty'             = 'The provided access token is empty after conversion.'
    'PublishDevDirectoryList.NoPipelineData'         = 'No repository metadata was received from the pipeline.'
    'PublishDevDirectoryList.EmptyContent'           = 'The repository list content is empty. Nothing will be published.'
    'PublishDevDirectoryList.QueryGistFailed'        = 'Failed to query existing gists: {0}'
    'PublishDevDirectoryList.ActionPublish'          = 'Publish DevDirManager repository list to GitHub Gist'
    'PublishDevDirectoryList.TargetLabelCreate'      = 'Create gist GitRepositoryList'
    'PublishDevDirectoryList.TargetLabelUpdate'      = 'Update gist {0}'
}
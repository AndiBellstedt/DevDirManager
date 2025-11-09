<#
This file defines module-wide constants that are used throughout the DevDirManager module.
These values are set at module load time and should not be modified by users.
#>

# Regex pattern to detect unsafe relative paths that could escape the intended directory
# This pattern matches paths that could cause security issues:
# - Starts with backslash (absolute path: ^\)
# - Contains colon (drive letter: :)
# - Contains ".." (path traversal: ..)
# This is a security-critical pattern and should not be user-configurable
$script:UnsafeRelativePathPattern = [regex]::new('(^\\|:|\.{2})')

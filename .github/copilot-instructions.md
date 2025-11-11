# Project specific instructions for GitHub Copilot for the project DevDirManager
- This project utilize PSFramework
- This project is based on a module template from PSFramework Collective, to understand the concept, read more about it [here](https://psframework.org/docs/PSModuleDevelopment/Templates/overview)
- This project utilize the template 'PSFProject', read the readme.md files in the various subfolders to understand how the template works
- Read the module manifest the understand what is the supported PSVersion and dependencies.
    - If there is no explicit PSVersion defined, assume the module supports PSVersion 5.1 and above
    - If there is no explicit dependencies defined, doublecheck the functions to see if there are forgotten dependencies on other modules (do not care about core functions of PS)
- Utilize the PSFramework configuration system for any configuration needs, read more about it [here](https://psframework.org/docs/PSFramework/Configuration/overview). This applies to especially for variables used across multiple functions, or for variables that should be user-configurable
- Utilize the PSFramework logging system for any logging needs
    - Read more about it [here](https://psframework.org/docs/PSFramework/Logging/overview). This applies to especially for verbose/debug/info/warning/error messages
    - Ensure that sensitive information (passwords, API keys, Tokens, etc.) are never logged
- Ensure that the module manifest includes all required fields, such as ModuleVersion, Author, CompanyName, Copyright, Description, FunctionsToExport, CompatiblePSEditions and PrivateData with -at least- tags.
    - in case the project is in a GitHub repository, the PrivateData section must include a ProjectUri field with the URL to the repository
    - in case the project is in a GitHub repository, the PrivateData section must include a LicenseUri field with the URL to the license file in the repository
    - in case the project is in a GitHub repository, the PrivateData section must include a ReleaseNotes field with a link to the releases page of the repository

# Code quality, security and compliance
- Always keep security in mind! Do no stupid things that could lead to security vulnerabilities, such as
    - utilizing plain text passwords
    - leaking sensitive information
    - code injection
    - path traversal
    - unvalidated input
    - etc.
- If module manifest specifies a minimum PSVersion, ensure that the code is compatible with that version
- If PowerShell version 5 is specified as minimum version, ensures that the code also runs on newer versions (PowerShell 7+). Complain very explicitly in the chat, when you find incompatibilities
- Ensure that the code follows best practices for PowerShell coding style and conventions
- If feasible and it compliments the functions (for example input/output) utilize types from the module's defined types
    - When there are custom types defined in the module manifest, ensure that they are used where applicable
    - Ensure there is a table and list view defined for defined types, if applicable
    - Ensure for objects/types with less properties, table should be defined first, list view second. For objects/types with many properties, list view should be defined first, table view second
    - The view definitions should give nicer output on the console (this is a creative process and depends on the type/object itself, but should compliment the user experience)
    - It should be ensure that all properties of an object is still in the table and list view definition. Only spare properties from the definitions if they are absolutely not necessary or should be hidden for very important reasons
- Do not build helper functions within public functions (nested functions), instead build private functions in the 'internal\functions' subfolder of the project


# Pester / unit tests
- the project considers two places for tests, general onces and function specific onces, read about in /tests/readme.md file
- pester excution is done via pester.ps1 in the tests folder
    - the pester.ps1 has various parameters
    - if you need to test a specific test use -Include parameter on pester.ps1 to specify what should be tested explicitly. This safes time and computing power while testing specific things.
    - When using -Include parameter, you need to specifiy the full name of the tests-file including the file extention.
- Within the project there are already some pester tests existing. The existing tests already cover basic coding compliance:
    - Standard PSScriptAnalyzer rules (proper verb usage, ...)
    - basic parameter validation (no content validation)
    - comment-based help sections for all functions
- Ensure that you do not build duplicate tests for already existing tests. Like basic coding compliance items from the template (within the general folder)
- When adding new functions, ensure that you add pester tests for the new functions, covering at least:
    - extended parameter validation (content validation as well, as long, as applicable)
    - functional tests to ensure the function works as expected
- ensure that function specific tests are placed in a file that is named like to function to have clear separation of tests. That eases the readablity and maintainability of the tests. Do not build large monolithic files that try to covers "anything"
- When modifying existing functions, ensure that you add pester tests for the modified functionality, to ensure the modified functionality works as expected
- If module manifest specifies a minimum PSVersion, ensure that the pester tests are run with that powershell version


# Documentation
## Build and maintain a comprehensive README.md for the project
- The README in the root directory must include at least the following sections:
    - Project Title (with optional logo if this exists)
    - Project description
    - Installation Instructions / How to install
    - Usage Instructions / How to use (basic examples)
- In case there is a 'assets'-folder with a 'logo'-file (e.g., png, jpg, svg), the logo should be included at the top of the README file.
    - For example:
        ```markdown
        ![Project Logo](./assets/logo_128x128.png) Project Title
        ```
- Next to project title, there has to be badges included
    - they should be as a table with two columns "Plattform" and "Information" with the following content:
        - PowerShell Gallery (if the module is published there), with version, platform and download count
        - GitHub Repository, with release version, License type, Build Status (e.g., from GitHub Actions), Code Coverage (e.g., from Codecov), open issues, last commit in "main"/"master"-branch and last commit in "development"-branch (if available)
    - When it is feasible, include other badges that provide useful information about the project

## Build and maintain a comprehensive about_%ProjectName%.help.txt file for the module
- Fetch some inspiration from other PS core modules that have such about help files
    - Fetch https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_hash_tables
    - Fetch https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_functions
- The about help file must include at least the following sections:
    - SYNOPSIS
    - SHORT DESCRIPTION
    - LONG DESCRIPTION
    - EXAMPLES (at least 3 examples showing basic and advanced usage)
    - SEE ALSO

## Build and maintain a changelog.md file for the module
- Changelog must be maintained with each release
- Follow best practices for changelogs (fetch https://keepachangelog.com/en/1.0.0/ for more information)
- Stick to the existing format of the changelog.md file and be consistent with it
- Doublecheck the module version in the module manifest to ensure that the changelog is up to date.
- Make sure that the changelog contains an entry for each released version, if not, complain very explicitly in the chat
- Consider the audience of the changelog
    - Mainly ITpro users with a basic understanding of powershell
    - Ensure that the changelog must not be considered for developers or powershell expert level

## Internal documentation
- All public functions should have comments as internal documentation in the functions, that explains the logic and flow of the function, especially for complex parts
- Comments that are of an explanatory nature, should start  with a space after the # and with a capital letter. They should be full sentences.
  - Use this format
    ```powershell
    # This is a comment.
    ```
  - Avoid this format
    ```powershell
    #This is a comment.
- Within larger scripts or functions, consider doing region blocks to have better visibility and to sub-segment the code. Please recognize the following pattern.
  - Region blocks have a special way of indentication in case they are nested. It have to look like this:
    ```powershell
    #region -- Name of the outer block

    #region -- -- Name of the innter block

    #regionend -- Name of the innter block

    #regionend Name of the outer block
    ```
  - Even if there is no nesting of region block, the region block has to look like this in any way: (I want to have the name of the region block on the same indention for begin and end block)
  ```powershell
  #region -- Name of the block
  #regionend Name of the block
  ```

# Versioning
- Follow semantic versioning for the module versioning
- Ensure that the module version in the module manifest matches the version in the changelog for each release
- Ensure internal version together with last modified date of functions are updated on any change of a function.
    - Follow the existing format for versioning in the functions
    - Follow semantic versioning for function versioning as well
    - When making breaking changes to a function, increment the major version
    - When adding new functionality in a backwards-compatible manner, increment the minor version
    - When making backwards-compatible bug fixes, increment the patch version
    - When making non functional changes (e.g., documentation updates, comment changes, formatting changes), increment the revision number

# Additional instructions
- If there are user custom instructions in the user data, you must follow these as well. In case of there are conflicting instructions between this file and the user data, the instructions from this file have higher priority and must be followed
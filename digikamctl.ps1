#!/bin/bash
# vim: tabstop=8 expandtab shiftwidth=4 softtabstop=4 foldmethod=marker
# ----------------------------------------------------------------------
# Author:   DeaDSouL (Mubarak Alrashidi)
# URL:      https://unix.cafe/wp/en/2020/08/how-to-use-multiple-photo-libraries-with-digikam/
# GitLab:   https://gitlab.com/unix.cafe/digikam-multiple-libraries
# Twitter:  https://twitter.com/_DeaDSouL_
# License:  GPLv3
# ----------------------------------------------------------------------

# -------------------------------------------------------
# Configuration:
# -------------------------------------------------------

# Where do libraries live
$repoPath = "$env:USERPROFILE\Pictures\DigiKams"

# How did you install digikam
# 1 = digikam was installed via package manager like dnf
# 2 = digikam was installed via flatpak
$edition = 2

# Functions

function Backup-DigikamRc {
    if (Test-Path "$digikamRcPath" -PathType Leaf) {
        Move-Item "$digikamRcPath" ("$digikamRcPath.bkp-" + (Get-Date -Format "yyyyMMdd_HHmmss"))
    }
}

function Get-ActiveLibrary {
    if (Test-Path "$digikamRcPath" -PathType SymbolicLink) {
        return (Resolve-Path "$digikamRcPath").Parent.Name
    }
}

function Activate-Library {
    if (Test-Path "$libraryPath") {
        Write-Host "Activating '$libraryName' library now.."
        Backup-DigikamRc
        New-Item -ItemType SymbolicLink -Path "$digikamRcPath" -Target "$libraryPath\$digikamRcFile"
        Write-Host "'$libraryName' library has been successfully activated."
    } else {
        Write-Host "[ERROR]: There is no library called '$libraryName'. You may want to create it first."
    }
}

function Open-Library {
    if ($activeLibrary -ne $libraryName) {
        Activate-Library $libraryName
    }
    Write-Host "Opening '$libraryName' library.."
    # Digikam commands (1:pkg, 2:flatpak)
    if ($edition -eq 1) {
        Start-Process "digikam" -WorkingDirectory $tempDir
    } elseif ($edition -eq 2) {
        # Equivalent to flatpak run command in Bash
        # Replace with the appropriate flatpak command for your environment
        Start-Process "flatpak" -ArgumentList "run", "--branch=stable", "--arch=x86_64", "--command=digikam", "org.kde.digikam", "-qwindowtitle", $libraryName -WorkingDirectory $tempDir
    } else {
        Write-Host '[ERROR]: Unknown Digikam edition'
    }
}

# ... (other functions like Create-Library, Remove-Library, List-Libraries, Show-Usage, Init)

# Main

# Equivalent to $1 and $2 in Bash
$action = $args[0]
$libraryName = $args[1]

# ... (main logic using the functions)
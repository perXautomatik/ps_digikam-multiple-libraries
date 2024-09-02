# Equivalent of #!/bin/bash
# Replace with a PowerShell comment or leave blank
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
$edition = 2 # 1 for package manager, 2 for flatpak

# Variables
$DATE = (Get-Date).ToString("yyyyMMdd")
$TIME = (Get-Date).ToString("HHmmss")
$DIGIKAMCTL = $MyInvocation.MyCommand.Name
$RC_FILE = "digikamrc"
$RC_TEMP = "digikamrc.template"
$RC_DST = if ($EDITION -eq 1) { "$HOME\.config\digikamrc" } else { "$HOME\.var\app\org.kde.digikam\config\digikamrc" }
$digikamRcPath = $RC_DST
$_TMPDIR = "$env:TEMP\nohups\digikam"
$CDIR = (Get-Location).Path

function Backup-DigikamRc {
    if (Test-Path $RC_DST -PathType Leaf) {
        Move-Item $RC_DST ("$RC_DST.bkp-$DATE_$TIME")
    }
}
make-alias -name bkp_rc -value Backup-DigikamRc

function Get-ActiveLibrary {
    if (Test-Path "$digikamRcPath" -PathType SymbolicLink) {
        return (Resolve-Path "$digikamRcPath").Parent.Name
    }
}

function use_lib {
    if ($null -eq $args[0]) {
        Write-Error "Missing library name to activate."
    } elseif (Test-Path "$DKLIB") {
        Write-Host "Activating '$args[0]' library now.."
        bkp_rc
        New-Item -ItemType SymbolicLink -Path $RC_DST -Target "$DKLIB\$RC_FILE"
        if ($?) {
            Write-Host "'$args[0]' library has been successfully activated."
        } else {
            Write-Error "Could not activate '$args[0]' library."
        }
    } else {
        Write-Error "There is no library called '$args[0]'. You may want to create it first."
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

function Create-Library {
    if (Test-Path "$libraryPath") {
        Write-Host "[ERROR]: The '$libraryName' library exists."
    } else {
        Write-Host "Creating '$libraryName' library now.."
        New-Item -Path "$libraryPath" -ItemType Directory
        New-Item -Path "$libraryPath\.directory" -ItemType File -Value '[Desktop Entry]\nIcon=digikam'
        Copy-Item "$repoPath\$digikamRcFile" "$libraryPath\$digikamRcFile"
        (Get-Content "$libraryPath\$digikamRcFile") | ForEach-Object {
            $_ -replace "Database Name=.*", "Database Name=$libraryPath\Database\"
        } | Set-Content "$libraryPath\$digikamRcFile"
        Write-Host "The '$libraryName' library has been successfully created.."
    }
}

function Remove-Library {
    if (Test-Path "$libraryPath") {
        Write-Host "We are going to remove the following library:"
        Write-Host "$libraryPath"
        $answer = Read-Host "Remove it? (N/y): "
        if ($answer -eq 'y') {
            Write-Host "Removing '$libraryName'.."
            Remove-Item -Path "$libraryPath" -Recurse -Force
            Write-Host "The '$libraryName' library has been successfully removed."
        } else {
            Write-Host "Keeping '$libraryName' library."
        }
    } else {
        Write-Host "[ERROR]: '$libraryName' doesn't exist or it's not a directory."
    }
}

function List-Libraries {
    Write-Host 'Available libraries:'
    Get-ChildItem "$repoPath" -Directory | ForEach-Object {
        if ($activeLibrary -eq $_.Name) {
            Write-Host " * $($_.Name)"
        } else {
            Write-Host "  $($_.Name)"
        }
    }
}

function Show-Usage {
    Write-Host "USAGE: $scriptName run <LIB> | use <LIB> | new <LIB> | rm <LIB> | ls | help"
    Write-Host "  run <LIB>       To open a library."
    Write-Host "  use <LIB>       To activate a library."
    Write-Host "  mk <LIB>        To create a library."
    Write-Host "  rm <LIB>        To remove a library."
    Write-Host "  ls              To list all available libraries."
    Write-Host "  help            To show this menu."
}

function Init {
    # Create temp dir
    if (!(Test-Path $tempDir)) {
        New-Item -Path $tempDir -ItemType Directory
    }

    # Ensure Digikam is not running
    if (Get-Process digikam) {
        Write-Host "[ERROR]: You need to close 'DigiKam' first."
        Exit
    }

    $libraryPath = "$repoPath\$libraryName"
    $activeLibrary = Get-ActiveLibrary
}
# Main

# Get the script name
$scriptName = $MyInvocation.MyCommand.Name

# Initialize the script
Init $args[1]

switch ($args[0]) {
    'run' { Open-Library $args[1] }
    'use' { Activate-Library $args[1] }
    'create' { Create-Library $args[1] }
    'mk' { Create-Library $args[1] }
    'make' { Create-Library $args[1] }
    'new' { Create-Library $args[1] }
    'rm' { Remove-Library $args[1] }
    'remove' { Remove-Library $args[1] }
    'ls' { List-Libraries }
    'list' { List-Libraries }
    'libs' { List-Libraries }
    'help' { Show-Usage }
    'h' { Show-Usage }
    default { Write-Host "Try: $scriptName help"; Exit }
}
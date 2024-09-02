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

# ... (other functions like Create-Library, Remove-Library, List-Libraries, Show-Usage, Init)

# Main
init $args[1]

switch ($args[0]) {
    'run' { open_lib $args[1] }
    'use' { use_lib $args[1] }
    'create' { mk_lib $args[1] }
    # ... (rest of the cases)
}
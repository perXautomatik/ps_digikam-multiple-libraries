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
$Global:repoPath = "$env:USERPROFILE\Pictures\DigiKams"

# How did you install digikam
# 1 = digikam was installed via package manager like dnf / or windows executable
# 2 = digikam was installed via flatpak
$global:edition = 1 # 1 for package manager, 2 for flatpak

# -------------------------------------------------------
# You don't have to change anything else below this line.
# -------------------------------------------------------

# ----------------------------------------------------------------------

# Variables #{{{
# Date & Time
$DATE = (Get-Date).ToString("yyyyMMdd")
$TIME = (Get-Date).ToString("HHmmss")

# Script name
$Global:DIGIKAMCTL = $MyInvocation.MyCommand.Name

# RC SRC
$Global:RC_FILE = "digikamrc"

# RC Template
$Global:RC_TEMP = "digikamrc.template"
# RC DST (1:pkg, 2:flatpak)
$Global:RC_DST = if ($EDITION -eq 1) { "$HOME\.config\digikamrc" } else { "$HOME\.var\app\org.kde.digikam\config\digikamrc" }
$Global:activeLibrary = $null
$global:libraries = @()
$Global:libraryPath = ""
# Temp path
$Global:_TMPDIR = "$env:TEMP\nohups\digikam"

# Current path
$global:CDIR = (Get-Location).Path
#}}}

<#
function bkp_rc() { #{{{
#>
function Backup-DigikamRc {
    if (Test-Path $Global:RC_DST -PathType Leaf) {
        Move-Item $Global:RC_DST ("$Global:RC_DST.bkp-$($DATE)_$TIME")
    }
} #}}}

<#
function used_lib() { #{{{
#>
function Get-ActiveLibrary {
    if (Test-Path -Path $Global:RC_DST -PathType Leaf -and (Get-Item $Global:RC_DST).LinkType -eq 'SymbolicLink') {
        $linkTarget = (Get-Item $Global:RC_DST).Target
        $parentDir = Split-Path -Path $linkTarget -Parent
        [System.IO.Path]::GetFileName($parentDir)
    }
} #}}}

<#
function use_lib() { #{{{
#>
function Activate-Library {
    if ($null -eq $args[0]) {
        echo "[ERROR]: Missing library name to activate."
    } elseif (Test-Path "$global:libraryPath") {
        Write-Host "Activating '$($args[0])' library now.."
        # backup original digikamrc (if it was a file instead of symlink)
        Backup-DigikamRc
        # make symbolic links
        New-Item -ItemType SymbolicLink -Path $Global:RC_DST -Target "$global:libraryPath\$Global:RC_FILE"
        if ($?) {
            Write-Host "'$($args[0])' library has been successfully activated."
        } else {
            Write-Error "[ERROR]: Could not activate '$($args[0])' library."
        }
    } else {
        Write-Error "[ERROR]: There is no library called '$($args[0])'. You may want to create it first."
    }
} #}}}

<#
function open_lib() { #{{{
#>
function Open-Library { 
    # Activating library if it wasn't
    if ($global:activeLibrary -ne $($($args[0]))) {
        Activate-Library $($($args[0]))
        if (!$?) {
            Write-Error "Since we could not activate '$($($args[0]))' library, we can not open it."
            return 1
        }
    }

    echo "Opening '${1}' library.."
    # Digikam commands (1:pkg, 2:flatpak)
    if ($global:edition -eq 1) {
        cd $Global:_TMPDIR
        Start-Process "digikam" -WorkingDirectory $Global:_TMPDIR
        cd $global:CDIR
    } elseif ($global:edition -eq 2) {
        # Equivalent to flatpak run command in Bash
        # Replace with the appropriate flatpak command for your environment
        Start-Process "flatpak" -ArgumentList "run", "--branch=stable", "--arch=x86_64", "--command=digikam", "org.kde.digikam", "-qwindowtitle", $($($args[0])) -WorkingDirectory $Global:_TMPDIR
    } else {
        echo '[ERROR]: Unknown Digikam global:edition'
        return 1
    }

    return 0
} #}}}

<#
function mk_lib() { #{{{
#>
function Create-Library {
    if ([string]::IsNullOrEmpty($($args[0]))) {
        echo "[ERROR]: Missing library name."
        return 1
    } elseif (-not (Test-Path -Path "$Global:RepoPath\$Global:Rc_Temp")) {
        Write-Error "[ERROR]: Could not find '$Global:Rc_Temp'."
        Write-Output "You need to have a copy of a digikamrc saved in: '$Global:RepoPath\$Global:Rc_Temp'"
        return 1
    } elseif (-not (Test-Path -Path $global:libraryPath)) {
        echo "Creating '$($args[0])' library now.."
        $dbfolder = New-Item -Path "$global:libraryPath\Database" -ItemType Directory -Force -passthrough
        Set-Content -Path "$global:libraryPath\.directory" -Value '[Desktop Entry]`nIcon=digikam'
        Copy-Item -Path "$Global:RepoPath\$Global:Rc_Temp" -Destination "$global:libraryPath\$global:Rc_File" -Force

        $content = Get-Content -Path "$global:libraryPath\$global:Rc_File"
        $content = $content -replace "Database Name=.*", "Database Name=$($dbfolder)"
        $content = $content -replace "Database Name Face=.*", "Database Name Face=$($dbfolder)"
        $content = $content -replace "Database Name Similarity=.*", "Database Name Similarity=$($dbfolder)"
        $content = $content -replace "Database Name Thumbnails=.*", "Database Name Thumbnails=$($dbfolder)"
        Set-Content -Path "$global:libraryPath\$global:Rc_File" -Value $content

        Write-Output "The '$($args[0])' library has been successfully created.."
        return 0
    } else {
        Write-Error "[ERROR]: The '$($args[0])' library exists."
        return 1
    }
} #}}}

<#
function rm_lib() { #{{{
#>
function Remove-Library {
    if ($null -eq $args[0]) {
        Write-Error "[ERROR]: Missing library name to remove."
        return 1
    }

    if ($global:activeLibrary -eq $($args[0])) {
        echo "[ERROR]: Can not remove an activated library '$($args[0])'."
        echo "[ERROR]: You need to activate another library first."
        return 1
    }

    if (Test-Path "$Global:libraryPath") {
        echo 'We are going to remove the following library:'
        Write-Host "$Global:libraryPath"

        $answer = Read-Host "Remove it? (N/y): "
        if ($answer -eq 'y') {
            Write-Host "Removing '$($args[0])'.."
            Remove-Item -Path "$Global:libraryPath" -Recurse -Force
            Write-Host "The '$($args[0])' library has been successfully removed."
        } else {
            echo "Keeping '$($args[0])' library."
        }
    } else {
        Write-Error "[ERROR]: '$($args[0])' doesn't exist or it's not a directory."
        return 1
    }
} #}}}

<#
function ls_libs() { #{{{
#>
function List-Libraries {
    echo 'Available libraries:'
    
    SGlobal:et-Variable -Name "libraries" -Value (Get-ChildItem "$global:repoPath" -Directory) -Scope Global 
    if ($global:libraries.Count -eq 0) {
        echo 'There are no libraries to list. You may want to create one first'
        Write-Host "  Type: $Global:DIGIKAMCTL new myLibrary"
    } else {
        foreach ($library in $global:libraries) {
            if ($global:activeLibrary -eq $library.Name) {
                Write-Host " * $($library.Name)"
            } else {
                Write-Host "  $($library.Name)"
            }
        }
    }
} #}}}

<#
function show_usage() { #{{{
#>
function Show-Usage {
    Write-Host "USAGE: $scriptName run <LIB> | use <LIB> | new <LIB> | rm <LIB> | ls | help"
    echo "    run <LIB>         To open a library."
    echo "                      Aliases: open."
    echo "    use <LIB>         To activate a library."
    echo "                      Aliases: activate."
    echo "    mk <LIB>          To create a library."
    echo "                      Aliases: create, new, make."
    echo "    rm <LIB>          To remove a library."
    echo "                      Aliases: remove."
    echo "    ls                To list all available libraries."
    echo "                      Aliases: list, libs."
    echo "    help              To show this menu."
    return 0
} #}}}

function Init {
    # Create temp dir
    if (!(Test-Path $Global:_TMPDIR)) { New-Item -Path $Global:_TMPDIR -ItemType Directory -erroraction stop }
    # make sure tmp dir exists

    # Ensure Digikam is not running
    if (Get-Process digikam -ErrorAction SilentlyContinue) {
        echo "[ERROR]: You need to close 'DigiKam' first."
        Exit
    }
    Set-Variable -Name "libraryPath"  -Value "$global:repoPath\$($args[0])" -Scope Global    
    Set-Variable -Name "activeLibrary" -Value Get-ActiveLibrary -Scope Global    

} #}}}    

<#
function e() { #{{{
    $1 "${2}"
    exit $?
} #}}}

# ----------------------------------------------------------------------
#>
# Main ($1: action, $2: library name)

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

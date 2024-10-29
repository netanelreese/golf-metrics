<#
.SYNOPSIS
    Adds entries to csv file for a new game of golf.

.DESCRIPTION
    Takes user input for data about a game of golf and uses Add-Content to append the data to the end of golf-scores.csv for pygolf to process and visualize	

.PARAMETER filePath
    Filepath that csv is located at. (Default: data/golf-scores.csv)

.PARAMETER dryRun
    Whether to write to the csv or not.
    
.EXAMPLE
    Example usage of the script:
    PS> .\Add-Game.ps1 -dryRun -filePath "C:\path\to\file.csv"

.NOTES
    Author: Nathanael G. Reese
    Created: 2024-10-29
    License: GNU GPL v3.0
#>

param (
    [string]$filePath = "../data/golf-scores.csv",
    [switch]$dryRun
)

# Define colors
$colorInfo = "Cyan"
$colorSuccess = "Green"
$colorError = "Red"
$colorWarning = "Yellow"

function Write-Info { Write-Host "[INFO] $args" -ForegroundColor $colorInfo }
function Write-Success { Write-Host "[SUCCESS] $args" -ForegroundColor $colorSuccess }
function Write-Error { Write-Host "[ERROR] $args" -ForegroundColor $colorError }
function Write-Warning { Write-Host "[WARNING] $args" -ForegroundColor $colorWarning }

# Function to check flags
function Check-Flags {
    Write-Info "File Path: $filePath"
    if ($dryRun) { Write-Warning "Dry Run Mode - No changes will be saved" }
}

# Function to prompt for game details
function Read-Game-Info {
    Write-Info "Enter the game details:"
    $global:courseName = Read-Host "Course Name"
    $global:date = Read-Host "Date (mmddyyyy)"
    $global:totalScore = Read-Host "Total Score"
    $global:coursePar = Read-Host "Course Par"
    $global:teePosition = Read-Host "Tee Position (e.g., white, blue, black)"
}

# Function to prompt for hole details
function Read-Hole-Info {
    $global:holeEntries = @()
    $holeCount = Read-Host "Enter number of holes (9 or 18)"
    
    if ($holeCount -ne 9 -and $holeCount -ne 18) {
        Write-Error "Invalid entry. Please enter either 9 or 18 for holes."
        exit
    }

    for ($i = 1; $i -le $holeCount; $i++) {
        Write-Info "Enter details for Hole $i:"
        $yardage = Read-Host "Yardage"
        $holeHandicap = Read-Host "Hole Handicap"
        $holePar = Read-Host "Hole Par"
        $holeScore = Read-Host "Hole Score"
        $hitFairway = Read-Host "Hit Fairway (True/False)"
        $greenInRegulation = Read-Host "Green in Regulation (True/False)"
        $numberOfPutts = Read-Host "Number of Putts"
        
        $holeEntry = "$i,$yardage,$holeHandicap,$holePar,$holeScore,$hitFairway,$greenInRegulation,$numberOfPutts"
        $holeEntries += $holeEntry
    }
}

# Validate all required fields are filled
function Validate-Entries {
    if (-not $courseName -or -not $date -or -not $totalScore -or -not $coursePar -or -not $teePosition) {
        Write-Error "Game entry is missing required information."
        exit
    }
    if ($holeEntries.Count -eq 0) {
        Write-Error "No hole entries found."
        exit
    }
}

# Function to write data
function Write-Data {
    $gameEntry = "$courseName,$date,$totalScore,$coursePar,$teePosition"
    
    if ($dryRun) {
        Write-Info "Dry Run: Game Entry"
        Write-Host $gameEntry
        Write-Info "Dry Run: Hole Entries"
        $holeEntries | ForEach-Object { Write-Host $_ }
    } else {
        try {
            Add-Content -Path $filePath -Value $gameEntry
            $holeEntries | ForEach-Object { Add-Content -Path $filePath -Value $_ }
            Write-Success "Entries successfully added to $filePath"
            Display-Appended-Data $gameEntry $holeEntries
        } catch {
            Write-Error "Failed to write to $filePath: $_"
        }
    }
}

# Function to display appended data
function Display-Appended-Data {
    param ($gameEntry, $holeEntries)
    Write-Info "`nAppended Game Entry: $gameEntry"
    Write-Info "`nAppended Hole Entries:"
    $holeEntries | ForEach-Object { Write-Host $_ }
}

# Main Execution
Check-Flags
Read-Game-Info
Read-Hole-Info
Validate-Entries
Write-Data

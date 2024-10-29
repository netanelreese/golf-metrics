#!/bin/bash
# -----------------------------------------------------------------------------
# Filename: add-game.sh
# Description: Adds entries to a CSV file for a new golf game}, taking all data 
#              from the user before writing. Supports dry run and file path 
#              specification. Displays appended data upon success.
# Author: Nathanael G. Reeese
# -----------------------------------------------------------------------------
###############################################################################
# Begin Variables
###############################################################################
csv_path="../data/golf-scores.csv"
dry_run=false

color_info="\033[0;36m"   # Cyan
color_success="\033[0;32m" # Green
color_error="\033[0;31m"  # Red
color_warning="\033[0;33m" # Yellow
color_reset="\033[0m"     # Reset color

###############################################################################
# Begin Functions
###############################################################################

function print_info { echo -e "${color_info}[INFO] $1${color_reset}"; }
function print_success { echo -e "${color_success}[SUCCESS] $1${color_reset}"; }
function print_error { echo -e "${color_error}[ERROR] $1${color_reset}"; }
function print_warning { echo -e "${color_warning}[WARNING] $1${color_reset}"; }

# Validates input flags.
function check_flags {
    print_info "File Path: ${csv_path}"
    if ${dry_run}; then
        print_warning "Dry Run Mode - No changes will be saved"
    fi
}

# Read game information
function read_game_info {
    print_info "Enter the game details:"
    read -p "Course Name: " course_name
    read -p "Date (mmddyyyy): " date
    read -p "Total Score: " total_score
    read -p "Course Par: " course_par
    read -p "Tee Position (e.g. white, blue, black): " tee_position
}

# Read hole information
function read_hole_info {
    hole_entries=()
    read -p "Enter number of holes (9 or 18): " hole_count
    if [[ "${hole_count}" -ne 9 && "${hole_count}" -ne 18 ]]; then
        print_error "Invalid entry. Please enter either 9 or 18 for holes."
        exit 1
    fi

    for (( i=1; i<=hole_count; i++ )); do
        print_info "Enter details for Hole ${i}:"
        read -p "Yardage: " yardage
        read -p "Hole Handicap: " hole_handicap
        read -p "Hole Par: " hole_par
        read -p "Hole Score: " hole_score
        read -p "Hit Fairway (True/False): " hit_fairway
        read -p "Green in Regulation (True/False): " green_in_regulation
        read -p "Number of Putts: " number_of_putts
        
        hole_entries+=("${i},${yardage},${hole_handicap},${hole_par},${hole_score},${hit_fairway},${green_in_regulation},${number_of_putts}")
    done
}

# Validate entries
function validate_entries {
    if [[ -z ${course_name} || -z ${date} || -z ${total_score} || -z ${course_par} || -z ${tee_position} ]]; then
        print_error "Game entry is missing required information."
        exit 1
    fi
    if [[ ${#hole_entries[@]} -eq 0 ]]; then
        print_error "No hole entries found."
        exit 1
    fi
}

# Write data to file
function write_data {
    game_entry="${course_name},${date},${total_score},${course_par},${tee_position}"

    if ${dry_run}; then
        print_info "Dry Run: Game Entry - ${game_entry}"
        print_info "Dry Run: Hole Entries"
        printf "%s\n" "${hole_entries[@]}"
    else
        echo "${game_entry}" >> "${csv_path}" && printf "%s\n" "${hole_entries[@]}" >> "${csv_path}" && \
        print_success "Entries successfully added to ${csv_path}" && display_appended_data
    fi
}

# Display appended data
function display_appended_data {
    print_info "Appended Game Entry: ${game_entry}"
    print_info "Appended Hole Entries:"
    printf "%s\n" "${hole_entries[@]}"
}

###############################################################################
# Begin Execution
###############################################################################

check_flags
read_game_info
read_hole_info
validate_entries
write_data

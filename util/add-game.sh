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
TRUE=0
FALSE=1
# Values Used For Validation
# Par, assume all holes are par 3 or par 5
MIN_PAR_9=27
MIN_PAR_18=54
MAX_PAR_9=45
MAX_PAR_18=90
MAX_PAR=0
MIN_PAR=0
# Scores, assume min is all hole-in-ones (impossible lol) and max is all triple bogeys on an all par 5 course
MAX_SCORE_9=72
MIN_SCORE_9=9
MAX_SCORE_18=144
MIN_SCORE_18=18
MAX_SCORE=0
MIN_SCORE=0
# Max yardage, arbitrary 700 yards because i am not gonna play a hole longer than that...
MAX_YARDAGE=700
# Number of strokes it takes to reach green for each par value
GIR_STROKES_3=1
GIR_STROKES_4=2
GIR_STROKES_5=3

game_id=1
csv_path="../data/golf-scores.csv"
dry_run=false
push=false

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

function print_usage {
    echo -e "${color_info}Usage: $0 [options]${color_reset}"
    echo -e "${color_info}Options:${color_reset}"
    echo -e "  -f, --file <path>       Specify a custom file path for saving golf data (default: ./golf-scores.csv)"
    echo -e "  -d, --dry-run           Enable dry run mode (no changes will be saved)"
    echo -e "  -h, --help              Display this help message and exit"
    echo -e "  -p, --push              Pushes to remote repository after adding to data file."
    echo ""
    echo -e "${color_info}Examples:${color_reset}"
    echo -e "  $0 -f /path/to/custom-file.csv   Specify a custom file for saving data"
    echo -e "  $0 -d                            Run in dry run mode"
    echo -e "  $0 -h                            Display help message"
    echo -e "  $0 -p                            Push to remote repo"
}

function parse_flags {
# Parse command-line arguments
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            -f|--file)                # -f or --file specifies a custom file path
                csv_path="$2"
                shift                  # Skip the file path after the flag
                ;;
            -d|--dry-run)              # -d or --dry-run enables dry run mode
                dry_run=true
                ;;
            -h|--help)
                print_usage
                exit 0
                ;;
            -p|--push-data)
                push=true
                ;;
            *)                         # Any unrecognized flag
                print_error "INVALID OPTION: $1"
                print_usage
                exit 1
                ;;
        esac
        shift                          # Move to the next argument
    done
}
# Validates input flags.
function check_flags {
    print_info "File Path: ${csv_path}"
    if ${dry_run}; then
        print_warning "Dry Run Mode - No changes will be saved"
    fi
}

# Sets current max and min based on num holes
function set_current_bounds {
    if [[ "${hole_count}" -eq 9 ]]; then
        MAX_SCORE=${MAX_SCORE_9}
        MIN_SCORE=${MIN_SCORE_9}
        MAX_PAR=${MAX_PAR_9}
        MIN_PAR=${MIN_PAR_9}
    elif [[ "${hole_count}" -eq 18 ]]; then
        MAX_SCORE=${MAX_SCORE_18}
        MIN_SCORE=${MIN_SCORE_18}
        MAX_PAR=${MAX_PAR_18}
        MIN_PAR=${MIN_PAR_18}
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

    read -p "Enter number of holes (9 or 18): " hole_count
    if [[ "${hole_count}" -ne 9 && "${hole_count}" -ne 18 ]]; then
        print_error "Invalid entry. Please enter either 9 or 18 for holes."
        exit 1
    fi
    set_current_bounds
    validate_game_input
}

# Read hole information
function read_hole_info {
    hole_entries=()
    for (( i=1; i<=hole_count; i++ )); do
        print_info "Enter details for Hole ${i}:"
        read -p "Yardage: " yardage
        read -p "Hole Handicap: " hole_handicap
        read -p "Hole Par: " hole_par
        read -p "Hole Score: " hole_score
        read -p "Hit Fairway (True/False): " hit_fairway
        read -p "Green in Regulation (True/False): " green_in_regulation
        read -p "Number of Putts: " number_of_putts

        validate_hole_input "${yardage}" "${hole_par}" "${hole_score}" "${green_in_regulation}" "${number_of_putts}"
        
        hole_entries+=("${i},${yardage},${hole_handicap},${hole_par},${hole_score},${hit_fairway},${green_in_regulation},${number_of_putts},${game_id}")
    done
}

# Gets highest number id from csv and sets the current id to previous + 1.
# Gets the highest number id from csv and sets the current id to previous + 1.
function get_id {
    if [[ -f "${csv_path}" && -s "${csv_path}" ]]; then
        prev_id=$(awk -F',' 'NR>1 {print $9}' "${csv_path}" | sort -nr | head -n1)
        echo "${prev_id}"
        # Check if prev_id is a valid integer
        if [[ "$prev_id" =~ ^[0-9]+$ ]]; then
            game_id=$((prev_id + 1))
        else
            print_error "Error: Could not determine previous ID from CSV."
            exit 1
        fi
    else
        print_error "Error setting game ID - CSV file not found or is empty."
        exit 1
    fi
}

function not_bounded() {
    if [[ $# -ne 3 ]]; then
        print_error "Function <NOT_BOUNDED> requires 3 parameters... (not_bounded val min max)"
        exit 1
    fi

    local val=$1
    local min=$2
    local max=$3

    if [[ ${val} -gt ${max} || ${val} -lt ${min} ]]; then
        return ${TRUE}
    else
        return ${FALSE}
    fi
}

function not_lt() {
    if [[ $# -ne 2 ]]; then
        print_error "Function <NOT_LT> requires 2 parameters... (not_lt val max)"
        exit 1
    fi

    local val=$1
    local max=$2

    if [[ ${val} -ge ${max} ]]; then
        return "${TRUE}"
    else
        return "${FALSE}"
    fi
}

function not_gt {
    if [[ $# -ne 2 ]]; then
        print_error "Function <NOT_GT> requires 2 parameters... (not_gt val min)"
        exit 1
    fi

    local val=$1
    local min=$2

    if [[ ${val} -le ${min} ]]; then
        return "${TRUE}"
    else
        return "${FALSE}"
    fi
}

function validate_game_input {
    local invalid=false

    # Checks
    if [[ $(not_bounded "${total_score}" ${MIN_SCORE} ${MAX_SCORE}) ]]; then
        print_error "INVALID SCORE: ${total_score}"
        invalid=true
    fi
    
    if [[ $(not_bounded "${course_par}" ${MIN_PAR} ${MAX_PAR}) ]]; then
        print_error "INVALID COURSE PAR: ${course_par}"
        invalid=true
    fi
    
    # Exit if the game is invalid.
    if ${invalid}; then
        print_error "GAME INPUT ERROR(S), EXITING..."
        exit 1
    fi
}

# Checks if the player did green in regulation
function not_valid_gir {
    if [[ $# -ne 4 ]]; then
        print_error "Invalid number of parameters..: $#"
        exit 1
    fi

    local score=$1
    local putts=$2
    local par=$3
    local g_reg=$4
    local ngs=$((score - putts))  # NGS = non green strokes

    # Based on par evaluate the non green strokes, if false then exit. (maybe just repeat the loop?)
    if [[ ${g_reg} -ne ${ngs} ]]; then
        print_error "Input green in regulation value is not equal to non-green strokes. ${g_reg} =/= ${ngs}"
        return ${TRUE}
    fi
    
    if [[ ${par} -eq 3 && ${ngs} -ne ${GIR_STROKES_3} ]]; then
        return ${TRUE}
    elif [[ ${par} -eq 4 && ${ngs} -ne ${GIR_STROKES_4} ]]; then
        return ${TRUE}
    elif [[ ${par} -eq 5 && ${ngs} -ne ${GIR_STROKES_5} ]]; then
        return ${TRUE}
    fi

    return ${FALSE}
}

function not_valid_hole_score {
    if [[ $# -ne 2 ]]; then
        print_error "Invalid number of parameters..: $#"
        exit 1
    fi

    local par=$1
    local score=$2
    local min=1
    local max=$((par + 3)) # Max is triple bogey for my sake, dont allow it in your head and you wont do it.

    if [[ $(not_bounded "${score}" ${min} ${max}) ]]; then
        return ${TRUE}
    fi

    return ${FALSE}
}

function validate_hole_input {
    if [[ $# -ne 5 ]]; then
        print_error "Invalid number of parameters..: $#"
        exit 1
    fi

    local ydg=$1
    local par=$2
    local scr=$3
    local g_reg=$4
    local putts=$5
    local invalid=false
    
    # Checks
    if [[ $(not_valid_hole_score "${par}" "${scr}") ]]; then
        print_error "INVALID SCORE: ${scr}"
        invalid=true
    fi

    if [[ $(not_valid_gir "${scr}" "${putts}" "${par}" "${g_reg}") ]]; then
        print_error "GREEN IN REGULATION VALUE INVALID"
        invalid=true
    fi

    if [[ ${ydg} -gt ${MAX_YARDAGE} ]]; then
        print_error "INVALID HOLE YARDAGE: ${ydg}"
        invalid=true
    fi
}

# Push data to remote repository
function push_data {
    if ${push}; then
        date_pushed=$(date)
        commit_message="Added round at ${course_name} on ${date_pushed}"
        git add -A;
        git commit -m"${commit_message}"
        git push
        print_success "Pushed data to remote repository."
    fi
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
    game_entry="${course_name},${date},${total_score},${course_par},${tee_position},${game_id}"

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
parse_flags "$@"
check_flags
get_id
read_game_info
read_hole_info
validate_entries
write_data
push_data

exit 0

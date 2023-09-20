#!/bin/bash

###
# Bash script to clone scenarios between a source and a target environment,
# e.g. to clone scenarios from production to beta or your local development environment.
# Tip! The script can also clone from and to the same environment to a quick dupicate
# of one or more scenarios in a convenient manner.
#
# Required installed binaries:
# - curl: to perform HTTP requests towards the different environments
# - jq: to parse json values



### Constants

CURL_CMD=$(which curl 2>/dev/null)
JQ_CMD=$(which jq 2>/dev/null)

B=$(tput bold)
UL=$(tput smul)
N=$(tput sgr0)
W=$(tput setaf 7)
R=$(tput setaf 1)
G=$(tput setaf 2)
ERROR_STR="${B}${R}ERROR${N}"
VALID_ENVS=(
  'p' 'pro' 'prod' 'production'
  'b' 's' 'beta' 'staging'
  'd' 'l' 'dev' 'local'
)
URL_DOMAIN_PROD='engine.energytransitionmodel.com'
URL_DOMAIN_BETA='beta.engine.energytransitionmodel.com'
URL_DOMAIN_DEV='localhost:3000'
URL_PATH_API='api/v3'
URL_PATH_SCENARIOS='scenarios'
URL_PATH_CC='custom_curves'                   # custom curves
URL_PATH_FSO='forecast_storage_order'         # user sortable: forecast storage order
URL_PATH_HNO='heat_network_order'             # user sortable: heat network order

TEMP_DIRECTORY='/tmp'
TEMP_SOURCE_SCENARIO_FILE='source_scenario_dump.json'
TEMP_CLONED_SCENARIO_FILE='new_scenario_dump.json'
TEMP_CC_FILE='scenario_cc_dump.json'   
TEMP_FSO_FILE='scenario_fso_dump.json' 
TEMP_HNO_FILE='scenario_hno_dump.json' 

DEFAULT_SOURCE_ENV='prod'
DEFAULT_TARGET_ENV='dev'


### Global variables used during execution

REQUESTED_SOURCE_ENV=''
REQUESTED_TARGET_ENV=''
REQUESTED_SCENARIO_IDS=''
SOURCE_SCENARIO_URL=''
TARGET_SCENARIO_URL=''
SCENARIO_COUNT=0
SCENARIO_IDS=()
SCENARIO_ID=''
SCENARIO_TEMP_DIR=''
CLONED_SCENARIO_ID=''
ERROR_SCENARIO_IDS=()
SOURCE_AND_CLONED_SCENARIO_IDS=()



### Function definitions

function validate_user_input () {
  [[ ! " ${VALID_ENVS[*]} " =~ " ${REQUESTED_SOURCE_ENV} " ]] && printf "'%s' is not a valid source environment. Exiting\n" "$REQUESTED_SOURCE_ENV" && exit
  [[ ! " ${VALID_ENVS[*]} " =~ " ${REQUESTED_TARGET_ENV} " ]] && printf "'%s' is not a valid target environment. Exiting\n" "$REQUESTED_TARGET_ENV" && exit
  [[ "$REQUESTED_SCENARIO_IDS" == "" ]] && printf "Please provide one or more ids for datasets to transfer. Exiting\n" && exit
  [[ ! "$REQUESTED_SCENARIO_IDS" =~ ^[0-9,[:space:]]+$ ]] && printf "'%s' is/are not valid dataset id(s). Exiting\n" "$REQUESTED_SCENARIO_IDS" && exit
}

function process_user_input () {
  # Check if one or multiple scenario ids were requested.
  # Create an array with one or multiple ids in them to be iterated over later.
  if [[ "$REQUESTED_SCENARIO_IDS" =~ "," ]]; then
    # Convert string with comma-separated values to Bash array, while trimming whitespace
    SCENARIO_IDS=($(echo $REQUESTED_SCENARIO_IDS | tr "," "\n"))
  else
    # Bash array with 1 entry
    SCENARIO_IDS=("$REQUESTED_SCENARIO_IDS")
  fi

  SCENARIO_COUNT=${#SCENARIO_IDS[@]}

  # Set source and target url + path for scenarios
  case $REQUESTED_SOURCE_ENV in
    p | pro | prod | production)  SOURCE_SCENARIO_URL="https://$URL_DOMAIN_PROD/$URL_PATH_API/$URL_PATH_SCENARIOS";;
    b | s | beta | staging)       SOURCE_SCENARIO_URL="https://$URL_DOMAIN_BETA/$URL_PATH_API/$URL_PATH_SCENARIOS";;
    d | l | dev  | local)         SOURCE_SCENARIO_URL="http://$URL_DOMAIN_DEV/$URL_PATH_API/$URL_PATH_SCENARIOS";;
  esac
  case $REQUESTED_TARGET_ENV in
    p | pro | prod | production)  TARGET_SCENARIO_URL="https://$URL_DOMAIN_PROD/$URL_PATH_API/$URL_PATH_SCENARIOS";;
    b | s | beta | staging)       TARGET_SCENARIO_URL="https://$URL_DOMAIN_BETA/$URL_PATH_API/$URL_PATH_SCENARIOS";;
    d | l | dev  | local)         TARGET_SCENARIO_URL="http://$URL_DOMAIN_DEV/$URL_PATH_API/$URL_PATH_SCENARIOS";;
  esac

  # Pre-fill variable containing info on source -> new (cloned) scenario id
  SOURCE_AND_CLONED_SCENARIO_IDS+=("$(printf "${UL}${B}source id at %s;|;cloned id at %s${N}" "${G}${REQUESTED_SOURCE_ENV}${W}" "${G}${REQUESTED_TARGET_ENV}${W}")")
}

# Get the source scenario from the source env
function get_scenario () {
  printf "\r  Obtaining scenario contents..."
  $CURL_CMD -s -o "$SCENARIO_TEMP_DIR/$TEMP_SOURCE_SCENARIO_FILE" "$SOURCE_SCENARIO_URL/$1"
  printf " Done!\n"
}

# Get custom curves for the source scenario
function get_custom_curves_for_scenario () {
  printf "\r  Obtaining custom curves..."

  # Get all custom curves for the given scenario
  $CURL_CMD -s -o "$SCENARIO_TEMP_DIR/$TEMP_CC_FILE" "$SOURCE_SCENARIO_URL/$1/$URL_PATH_CC"

  CUSTOM_CURVE_KEYS="$($JQ_CMD -r '.[].key' "$SCENARIO_TEMP_DIR/$TEMP_CC_FILE")"

  # Return if no attached custom curves were found
  if [ "$CUSTOM_CURVE_KEYS" == "" ]; then
    printf " No custom curves found.\n"
    return
  fi

  CUSTOM_CURVE_COUNT=$(echo "$CUSTOM_CURVE_KEYS" | wc -l)

  # Create a new temporary directory to store the custom curves in
  SCENARIO_TEMP_CC_DIR="$SCENARIO_TEMP_DIR/custom_curves"
  mkdir -p "$SCENARIO_TEMP_CC_DIR"

  # Download all attached custom curves
  CI=0
  echo "$CUSTOM_CURVE_KEYS" | while read -r CURVE_KEY; do
    CI=$(( CI + 1 ))
    printf "\r  Obtaining custom curves... (%d/%d)" "$CI" "$CUSTOM_CURVE_COUNT"
    $CURL_CMD -s -o "$SCENARIO_TEMP_CC_DIR/$CURVE_KEY.csv" "$SOURCE_SCENARIO_URL/$1/$URL_PATH_CC/$CURVE_KEY.csv"
  done
  printf " Done!\n"
}

# Get user sortables for the source scenario
function get_user_sortables_for_scenario () {
  printf "\r  Obtaining user sortables: %s" "${B}forecast_storage_order${N}"
  $CURL_CMD -s -o "$SCENARIO_TEMP_DIR/$TEMP_FSO_FILE" "$SOURCE_SCENARIO_URL/$1/$URL_PATH_FSO"
  printf ", %s" "${B}heat_network_order${N}"
  $CURL_CMD -s -o "$SCENARIO_TEMP_DIR/$TEMP_HNO_FILE" "$SOURCE_SCENARIO_URL/$1/$URL_PATH_HNO"
  printf ". Done!\n"
}

# Create a new 'cloned' scenario at the target env
function create_scenario () {
  printf "\r  Creating new cloned scenario..."
  $CURL_CMD -s -X POST -H "Content-Type: application/json" -d "@$SCENARIO_TEMP_DIR/$TEMP_SOURCE_SCENARIO_FILE" "$TARGET_SCENARIO_URL/" > "$SCENARIO_TEMP_DIR/$TEMP_CLONED_SCENARIO_FILE"

  CLONED_SCENARIO_ID=$($JQ_CMD -rc '.id' "$SCENARIO_TEMP_DIR/$TEMP_CLONED_SCENARIO_FILE")
  printf " %s! New scenario created with id %s\n" "${B}${G}Success${N}" "${B}${CLONED_SCENARIO_ID}${N}"
}

# Attach custom curves obtained from the source scenario to the cloned scenario
function post_custom_curves_for_scenario () {
  # Return if a custom_curve directory was not created for this scenario (meaning no attached custom curves were found)
  [ ! -d "$SCENARIO_TEMP_DIR/custom_curves" ] && return

  CUSTOM_CURVE_KEYS="$($JQ_CMD -rc '.[].key' "$SCENARIO_TEMP_DIR/$TEMP_CC_FILE")"
  CUSTOM_CURVE_COUNT=$(echo "$CUSTOM_CURVE_KEYS" | wc -l )

  # Upload all custom curves downloaded earlier for the source scenario
  CI=0
  echo "$CUSTOM_CURVE_KEYS" | while read -r CURVE_KEY; do
    CI=$(( CI + 1 ))
    printf "\r  Uploading custom curves for cloned scenario... (%d/%d)" "$CI" "$CUSTOM_CURVE_COUNT"
    $CURL_CMD -s -X PUT -F "name=$CURVE_KEY" -F "file=@$SCENARIO_TEMP_DIR/custom_curves/$CURVE_KEY.csv" "$TARGET_SCENARIO_URL/$1/$URL_PATH_CC/$CURVE_KEY" >/dev/null
  done
  printf " Done!\n"
}

# Update the sortables of the cloned scenario to match those of the source scenario
function post_user_sortables_for_scenario () {
  printf "\r  Setting user sortables: %s" "${B}forecast_storage_order${N}"
  $CURL_CMD -s -X PUT -H "Content-Type: application/json" -d "@$SCENARIO_TEMP_DIR/$TEMP_FSO_FILE" "$TARGET_SCENARIO_URL/$1/$URL_PATH_FSO" >/dev/null
  printf ", %s" "${B}heat_network_order${N}"
  $CURL_CMD -s -X PUT -H "Content-Type: application/json" -d "@$SCENARIO_TEMP_DIR/$TEMP_HNO_FILE" "$TARGET_SCENARIO_URL/$1/$URL_PATH_HNO" >/dev/null
  printf ". Done!\n"
}



### Script runtime flow


## Take and process user input

# Check if needed tools are available
[ ! -f "$CURL_CMD" ] && printf "'curl' command is missing or not found! Install or add to executable path first, then try again. Exiting\n" && exit
[ ! -f "$JQ_CMD" ] && printf "'jq' command is missing or not found! Install or add to executable path first, then try again. Exiting\n" && exit

if [ -n "$1" ] && [ -n "$2" ] && [ -n "$3" ]; then
  # The script was ran with 3 additional arguments, e.g.:
  #   scenario_cloner.sh prod beta 1,2,3
  # We assume these are the source env, target env and scenario ids, in that specific order.
  REQUESTED_SOURCE_ENV=$1
  REQUESTED_TARGET_ENV=$2
  REQUESTED_SCENARIO_IDS=$3
else
  # The script was ran without arguments. Ask the user for input.
  read -rp "Environment to import from: prod, beta or dev? (default: ${B}${DEFAULT_SOURCE_ENV}${N}): " REQUESTED_SOURCE_ENV
  read -rp "Environment to export to: prod, beta, or dev? (default: ${B}${DEFAULT_TARGET_ENV}${N}): " REQUESTED_TARGET_ENV
  read -rp "Id(s) for scenario(s) to transfer? (separate multiple ids by comma): " REQUESTED_SCENARIO_IDS

  # In case of empty source or target environment, set the default
  [ "$REQUESTED_SOURCE_ENV" == "" ] && REQUESTED_SOURCE_ENV=$DEFAULT_SOURCE_ENV
  [ "$REQUESTED_TARGET_ENV" == "" ] && REQUESTED_TARGET_ENV=$DEFAULT_TARGET_ENV
fi

# Check if user input makes sense
validate_user_input

# Process user input into usable variables
process_user_input

# Present choices made by user and ask for confirmation before actually cloning
printf "\nReady to clone from %s to %s for scenarios with the following ids:\n" "${B}${G}${REQUESTED_SOURCE_ENV}${N}" "${B}${G}${REQUESTED_TARGET_ENV}${N}"
for SCENARIO_ID in "${SCENARIO_IDS[@]}"; do
  printf "%s\n" "${B}${SCENARIO_ID}${N}"
done
read -rp "Continue? (y/n): " COMMENCE

[ ! "$COMMENCE" == "y" ] && [ ! "$COMMENCE" == "Y" ] && printf "No confirmation received! Exiting\n" && exit


## Start cloning

# Loop through given scenario id(s) and clone them
I=0
for SCENARIO_ID in "${SCENARIO_IDS[@]}"
do
  I=$(( I + 1 ))
  printf "%s Cloning scenario with id %s from %s...\n" "${B}(${I}/${SCENARIO_COUNT})${N}" "${B}${SCENARIO_ID}${N}" "${B}${G}$REQUESTED_SOURCE_ENV${N}"

  # Create a directory in the temp directory
  # to hold all information obtained from the source scenario
  SCENARIO_TEMP_DIR="$TEMP_DIRECTORY/scenario_$SCENARIO_ID"
  mkdir -p "$SCENARIO_TEMP_DIR"

  # Get all contents from the source scenario
  get_scenario "$SCENARIO_ID"
  get_custom_curves_for_scenario "$SCENARIO_ID"
  get_user_sortables_for_scenario "$SCENARIO_ID"

  printf "\n"

  # Create a new scenario at the target env with the contents of the source scenario
  create_scenario

  if [ -z "$CLONED_SCENARIO_ID" ]; then
    printf "  %s! %sNew scenario could somehow not be created! Skipping this source scenario.%s\n" "$ERROR_STR" "$B" "$N"
    ERROR_SCENARIO_IDS+=("$SCENARIO_ID")
    CLONED_SCENARIO_ID=''
    continue
  fi

  # Create additional content for the cloned scenario
  post_custom_curves_for_scenario "$CLONED_SCENARIO_ID"
  post_user_sortables_for_scenario "$CLONED_SCENARIO_ID"

  printf "\n"

  SOURCE_AND_CLONED_SCENARIO_IDS+=("$SCENARIO_ID;|;$CLONED_SCENARIO_ID")
  CLONED_SCENARIO_ID=''
done

printf "Done!\n\n"

if [ ${#ERROR_SCENARIO_IDS[@]} -gt 0 ]; then
  printf "%sErrors were encountered while cloning the following scenarios from %s:%s" "$B" "$REQUESTED_SOURCE_ENV" "$N"
  printf "%s\n" "${ERROR_SCENARIO_IDS[@]}"
fi

printf "The following scenarios were succesfully cloned:\n"
printf "%s\n" "${SOURCE_AND_CLONED_SCENARIO_IDS[@]}" | column -s";" -t

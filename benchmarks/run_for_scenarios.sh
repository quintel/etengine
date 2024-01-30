#!/bin/bash

SCENARIOS_DIR='tmp/benchmarks/scenarios'

REQUESTED_SCENARIO_IDS=''
SCENARIO_IDS=()

###
# Run benchmarks that create data-dumps for scenarios, then generate reports from these data-dumps:
# - An interactive flamegraph in HTML document form
# - A Graphviz schematic in PDF document form

REQUESTED_SCENARIO_IDS=$1

[[ "$REQUESTED_SCENARIO_IDS" == "" ]] && printf "Please provide one or more ids for scenarios to profile. Exiting\n" && exit

if [[ "$REQUESTED_SCENARIO_IDS" =~ "," ]]; then
  # Convert string with comma-separated values to Bash array, while trimming whitespace
  SCENARIO_IDS=($(echo $REQUESTED_SCENARIO_IDS | tr "," "\n"))
else
  # Bash array with 1 entry
  SCENARIO_IDS=("$REQUESTED_SCENARIO_IDS")
fi

printf "\nReady to run benchmarks for scenarios with the following ids:\n"
for SCENARIO_ID in "${SCENARIO_IDS[@]}"; do
  printf "%s\n" "${B}${SCENARIO_ID}${N}"
done
read -rp "Continue? (y/n): " COMMENCE

[ ! "$COMMENCE" == "y" ] && [ ! "$COMMENCE" == "Y" ] && printf "No confirmation received! Exiting\n" && exit

for SCENARIO_ID in "${SCENARIO_IDS[@]}"
do
  SCENARIO_DIR="${SCENARIOS_DIR}/${SCENARIO_ID}_reports"
  # Create directory for this scenario if it did not exist
  [ ! -d "$SCENARIO_DIR" ] && mkdir -p "$SCENARIO_DIR"

  # Run the scenario benchmark/profile
  ruby benchmarks/run.rb -s "$SCENARIO_ID"

  echo "-- Generating reports:"
  # Generate reports from the resulting dump:
  # - Flamegraph (HTML)
  echo "-- -- Flamegraph"
  stackprof --d3-flamegraph "${SCENARIOS_DIR}/scenario_${SCENARIO_ID}.dump" > "${SCENARIO_DIR}/scenario_${SCENARIO_ID}_flamegraph.html"
  # - Graphviz graph (PDF)
  echo "-- -- Graphviz PDF"
  stackprof --graphviz "${SCENARIOS_DIR}/scenario_${SCENARIO_ID}.dump" > "${SCENARIO_DIR}/scenario_${SCENARIO_ID}_graphviz.dot"
  dot -T pdf -o "${SCENARIO_DIR}/scenario_${SCENARIO_ID}_graph.pdf" "${SCENARIO_DIR}/scenario_${SCENARIO_ID}_graphviz.dot"
  echo "-- Done!"
done

echo "Done running benchmarks!"

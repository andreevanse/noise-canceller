FULL_PATH="$(cd "$(dirname "$1")"; pwd)/$(basename "$1")"
vsim -do "source {./dirs.tcl}; do {$FULL_PATH}"

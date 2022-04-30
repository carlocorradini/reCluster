#!/usr/bin/env sh
# MIT License
#
# Copyright (c) 2022-2022 Carlo Corradini
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Fail on error
set -o errexit
# Fail on unset var usage
set -o nounset
# Disable wildcard character expansion
set -o noglob

# Cleanup
cleanup() {
  # Restore cursor position
	tput rc
  # Cursor normal
	tput cnorm

	return 1
}

# Trap
trap cleanup INT QUIT TERM

# ================
# LOGGER
# ================
# Fatal log level. Cause exit failure
LOG_LEVEL_FATAL=100
# Error log level
LOG_LEVEL_ERROR=200
# Warning log level
LOG_LEVEL_WARN=300
# Informational log level
LOG_LEVEL_INFO=500
# Debug log level
LOG_LEVEL_DEBUG=600

# Log level
LOG_LEVEL=$LOG_LEVEL_INFO
# Log disable color flag
LOG_DISABLE_COLOR=1

# Print log message
# @param $1 Log level
# @param $2 Message
_log_print_message() {
  _log_level=$1
  shift
  _log_message=${*:-}
  _log_name=""
  _log_prefix=""
  _log_suffix="\033[0m"

  # Log level is enabled
  if [ "$_log_level" -gt "$LOG_LEVEL" ]; then return; fi

  case $_log_level in
    "$LOG_LEVEL_FATAL")
      _log_name="FATAL"
      _log_prefix="\033[41;37m"
    ;;
    "$LOG_LEVEL_ERROR")
      _log_name="ERROR"
      _log_prefix="\033[1;31m"
    ;;
    "$LOG_LEVEL_WARN")
      _log_name="WARN"
      _log_prefix="\033[1;33m"
    ;;
    "$LOG_LEVEL_INFO")
      _log_name="INFO"
      _log_prefix="\033[37m"
    ;;
    "$LOG_LEVEL_DEBUG")
      _log_name="DEBUG"
      _log_prefix="\033[1;34m"
    ;;
  esac

  # Color disable flag
  if [ "$LOG_DISABLE_COLOR" -eq 0 ]; then
    _log_prefix=""
    _log_suffix=""
  fi

  # Output to stdout
  printf '%b[%-5s] %b%b\n' "$_log_prefix" "$_log_name" "$_log_message" "$_log_suffix"
}

# Fatal log message
FATAL() { _log_print_message ${LOG_LEVEL_FATAL} "$@"; exit 1; }
# Error log message
ERROR() { _log_print_message ${LOG_LEVEL_ERROR} "$@"; }
# Warning log message
WARN() { _log_print_message ${LOG_LEVEL_WARN} "$@"; }
# Informational log message
INFO() { _log_print_message ${LOG_LEVEL_INFO} "$@"; }
# Debug log message
DEBUG() { _log_print_message ${LOG_LEVEL_DEBUG} "$@"; }

# ================
# SPINNER
# ================
# Spinner PID
SPINNER_PID=
# Spinner symbol time in seconds
SPINNER_TIME=.1
# Spinner disable flag
SPINNER_DISABLE=1

# Spinner symbols dots
SPINNER_SYMBOLS_DOTS="⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏"
# Spinner symbols greyscale
SPINNER_SYMBOLS_GREYSCALE="░░░░░░░ ▒░░░░░░ ▒▒░░░░░ ▒▒▒░░░░ ▒▒▒▒░░░ ▒▒▒▒▒░░ ▒▒▒▒▒▒░ ▒▒▒▒▒▒▒ ░▒▒▒▒▒▒ ░░▒▒▒▒▒ ░░░▒▒▒▒ ░░░░▒▒▒ ░░░░░▒▒ ░░░░░░▒"
# Spinner symbols propeller
SPINNER_SYMBOLS_PROPELLER="/ - \\ |"

# Spinner symbols
SPINNER_SYMBOLS=$SPINNER_SYMBOLS_DOTS

# Spinner logic
_spinner() {
  _spinner_message="${1:-"Loading..."}"
  # Termination flag
  _terminate=1
  # Termination signal
  trap '_terminate=0' USR1

  # Parent PID
  _spinner_ppid="$(ps -p "$$" -o ppid=)"

  while :; do
    # Cursor invisible
    tput civis

    for s in $SPINNER_SYMBOLS; do
      # Save cursor position
      tput sc
      # Symbol and message
      env printf "%s %s" "$s" "$_spinner_message"
      # Restore cursor position
      tput rc

      # Terminate
      if [ $_terminate -eq 0 ]; then
        # Clear line from position to end
        tput el
        break 2
      fi

      # Animation time
      env sleep "$SPINNER_TIME"

      # Check parent still alive
      if [ -n "$_spinner_ppid" ]; then
        # shellcheck disable=SC2086
        _spinner_parentup="$(ps --no-headers $_spinner_ppid)"
        if [ -z "$_spinner_parentup" ]; then  break 2; fi
      fi
    done
  done

  # Cursor normal
  tput cnorm
  return 0
}

# Start spinner
# @param $1 Message
# shellcheck disable=SC2120
spinner_start() {
  if [ "$SPINNER_DISABLE" -eq 0 ]; then return; fi
  if [ -n "$SPINNER_PID" ]; then FATAL "Spinner PID is already defined"; fi
  _spinner ${1:+"$1"} &
  SPINNER_PID=$!
}

# Stop spinner
spinner_stop() {
  if [ "$SPINNER_DISABLE" -eq 0 ]; then return; fi
  if [ -z "$SPINNER_PID" ]; then FATAL "Spinner PID is undefined"; fi
  kill -s USR1 "$SPINNER_PID"
  wait "$SPINNER_PID"
}

# ================
# FUNCTIONS
# ================
# Show help message
show_help() {
  cat << EOF
Usage: recluster.sh [--bench-time <TIME>] [--disable-color] [--disable-spinner]
                    [--help] [--log-level <LEVEL>] [--spinner <SPINNER>]
                    --stage <STAGE>

reCluster installation script.

Options:
  --bench-time <TIME>   Benchmark execution time in seconds
                        Default: 16
                        Values:
                          Any positive number

  --disable-color       Disable color

  --disable-spinner     Disable spinner

  --help                Show this help message and exit

  --log-level <LEVEL>   Logger level
                        Default: info
                        Values:
                          fatal    Fatal level
                          error    Error level
                          warn     Warning level
                          info     Informational level
                          debug    Debug level

  --spinner <SPINNER>   Spinner symbols
                        Default: dots
                        Values:
                          dots         $SPINNER_SYMBOLS_DOTS
                          greyscale    $SPINNER_SYMBOLS_GREYSCALE
                          propeller    $SPINNER_SYMBOLS_PROPELLER

  --stage <STAGE>       Installation stage
                        Required
                        Values:
                          0    Initial stage
EOF
}

# Assert command is installed
# @param $1 Command name
assert_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    FATAL "'$1' not found"
  fi
  DEBUG "Command '$1' found at '$(command -v "$1")'"
}

# Check if parameter is a number
# @param $1 Parameter
is_number() {
  if [ -z "${1+x}" ]; then return 1; fi
  case $1 in
    ''|*[!0-9]*) return 1 ;;
    *) return 0 ;;
  esac
}

# Parse command line arguments
# @param $# Arguments
parse_args() {
  # Parse
  while [ $# -gt 0 ]; do
    case $1 in
      --bench-time)
        # Benchmark time
        if [ -z "${2+x}" ]; then FATAL "Argument '$1' requires a non-empty value"; fi
        if ! is_number "$2" || [ "$2" -le 0 ]; then FATAL "Value '$2' of argument '$1' is not a positive number"; fi

        BENCH_TIME=$2
        shift
        shift
      ;;
      --disable-color)
        # Disable color
        LOG_DISABLE_COLOR=0
        shift
      ;;
      --disable-spinner)
        # Disable spinner
        SPINNER_DISABLE=0
        shift
      ;;
      --help)
        # Display help message and exit
        show_help
        exit 1
      ;;
      --log-level)
        # Log level
        if [ -z "${2+x}" ]; then FATAL "Argument '$1' requires a non-empty value"; fi

        case $2 in
          fatal) LOG_LEVEL=$LOG_LEVEL_FATAL ;;
          error) LOG_LEVEL=$LOG_LEVEL_ERROR ;;
          warn) LOG_LEVEL=$LOG_LEVEL_WARN ;;
          info) LOG_LEVEL=$LOG_LEVEL_INFO ;;
          debug) LOG_LEVEL=$LOG_LEVEL_DEBUG ;;
          *) FATAL "Value '$2' of argument '$1' is invalid" ;;
        esac
        shift
        shift
      ;;
      --spinner)
        if [ -z "${2+x}" ]; then FATAL "Argument '$1' requires a non-empty value"; fi

        case $2 in
          dots)
            SPINNER_SYMBOLS=$SPINNER_SYMBOLS_DOTS
          ;;
          greyscale)
            SPINNER_SYMBOLS=$SPINNER_SYMBOLS_GREYSCALE
          ;;
          propeller)
            SPINNER_SYMBOLS=$SPINNER_SYMBOLS_PROPELLER
          ;;
          *) FATAL "Value '$2' of argument '$1' is invalid"
        esac
        shift
        shift
      ;;
      --stage)
        # Installation stage
        if [ -z "${2+x}" ]; then FATAL "Argument '$1' requires a non-empty value"; fi

        case $2 in
          0) ;;
          *) FATAL "Value '$2' of argument '$1' is invalid"
        esac
        INSTALLATION_STAGE=$2
        shift
        shift
      ;;
      -*)
        # Unknown argument
        WARN "Unknown argument '$1' is ignored"
        shift
      ;;
      *)
        # No argument
        DEBUG "Skipping argument '$1'"
        shift
      ;;
    esac
  done

  # Checks
  if [ -z "$INSTALLATION_STAGE" ]; then FATAL "Argument '--stage' is required"; fi
}

# Read CPU information
read_cpu_info() {
  _cpu_info="$(lscpu --json \
              | jq '
                  .lscpu
                  | map({(.field): .data})
                  | add
                  | with_entries(if .key | endswith(":") then .key |= sub(":";"") else . end)
                  | .Flags /= " "
                  | .vulnerabilities = (to_entries | map(.key | select(startswith("Vulnerability "))[14:]))
                  | with_entries(select(.key | startswith("Vulnerability ") | not))
                  | . + {"architecture": .Architecture}
                  | . + {"flags": .Flags}
                  | . + {"cores": (."CPU(s)" | tonumber)}
                  | . + {"vendor": ."Vendor ID"}
                  | . + {"family": (."CPU family" | tonumber)}
                  | . + {"model": (.Model | tonumber)}
                  | . + {"name": ."Model name"}
                  | . + {"cache": {}}
                  | .cache += {"l1d": (."L1d cache" | split(" ") | .[0] + " " + .[1])}
                  | .cache += {"l1i": (."L1i cache" | split(" ") | .[0] + " " + .[1])}
                  | .cache += {"l2": (."L2 cache" | split(" ") | .[0] + " " + .[1])}
                  | .cache += {"l3": (."L3 cache" | split(" ") | .[0] + " " + .[1])}
                  | {architecture, flags, cores, vendor, family, model, name, cache, vulnerabilities}
                ')"

  # Convert cache to bytes
  _l1d_cache="$(echo "$_cpu_info" | jq --raw-output '.cache.l1d' | sed 's/B.*//' | sed 's/[[:space:]]*//g' | numfmt --from=iec-i)"
  _l1i_cache="$(echo "$_cpu_info" | jq --raw-output '.cache.l1i' | sed 's/B.*//' | sed 's/[[:space:]]*//g' | numfmt --from=iec-i)"
  _l2_cache="$(echo "$_cpu_info" | jq --raw-output '.cache.l2' | sed 's/B.*//' | sed 's/[[:space:]]*//g' | numfmt --from=iec-i)"
  _l3_cache="$(echo "$_cpu_info" | jq --raw-output '.cache.l3' | sed 's/B.*//' | sed 's/[[:space:]]*//g' | numfmt --from=iec-i)"

  # Update cache
  _cpu_info="$(echo "$_cpu_info" \
            | jq --arg l1d "$_l1d_cache" --arg l1i "$_l1i_cache" --arg l2 "$_l2_cache" --arg l3 "$_l3_cache" '
                .cache.l1d = ($l1d | tonumber)
                | .cache.l1i = ($l1i | tonumber)
                | .cache.l2 = ($l2 | tonumber)
                | .cache.l3 = ($l3 | tonumber)
              ')"

  # Update node facts
  NODE_FACTS="$(echo "$NODE_FACTS" \
              | jq --compact-output --sort-keys --argjson cpuinfo "$_cpu_info" '.info.cpu = $cpuinfo')"
}

# Read RAM information
read_ram_info() {
  _ram_info="$(lsmem --bytes --json \
              | jq '
                  .memory
                  | map(.size)
                  | add
                  | { "size": . }
                ')"

  # Update node facts
  NODE_FACTS="$(echo "$NODE_FACTS" \
              | jq --compact-output --sort-keys --argjson raminfo "$_ram_info" '.info.ram = $raminfo')"
}

# Read Disk(s) information
read_disks_info() {
  _disks_info="$(lsblk --bytes --json \
              | jq '
                  .blockdevices
                  | map(select(.type == "disk"))
                  | map({name, size})
                ')"

  # Update node facts
  NODE_FACTS="$(echo "$NODE_FACTS" \
              | jq --compact-output --sort-keys --argjson disksinfo "$_disks_info" '.info.disks = $disksinfo')"
}

# Read Interface(s) information
read_interfaces_info() {
  _interfaces_info="$(ip -details -json link show \
              | jq '
                  map(if .linkinfo.info_kind // .link_type == "loopback" then empty else . end)
                  | map(.name = .ifname)
                  | map({address, name})
                ')"

  # Cycle interfaces to obtain additional information
  while read -r _interface; do
    _iname="$(echo "$_interface" | jq --raw-output '.name')"

    # Speed
    _speed="$(ethtool "$_iname" | grep Speed | sed 's/Speed://g' | sed 's/[[:space:]]*//g' | sed 's/b.*//' | numfmt --from=si)"
    # Wake on Lan
    _wol="$(ethtool "$_iname" | grep 'Supports Wake-on' | sed 's/Supports Wake-on://g' | sed 's/[[:space:]]*//g')"

    # Update interfaces
    _interfaces_info="$(echo "$_interfaces_info" \
                      | jq --arg iname "$_iname" --arg speed "$_speed" --arg wol "$_wol" '
                          map(if .name == $iname then . + {"speed": $speed | tonumber, "wol": (if $wol == null or $wol == "" then null else $wol end)} else . end)
                        ')"
  done << EOF
$(echo "$_interfaces_info" | jq --compact-output '.[]')
EOF

  # Update node facts
  NODE_FACTS="$(echo "$NODE_FACTS" \
              | jq --compact-output --sort-keys --argjson interfacesinfo "$_interfaces_info" '.info.interfaces = $interfacesinfo')"
}

# Execute CPU benchmark
run_cpu_bench() {
  _single_thread="$(sysbench --validate --time="$BENCH_TIME" cpu run \
                  | grep 'events per second' \
                  | sed 's/events per second://g' \
                  | sed 's/[[:space:]]*//g' \
                  | xargs printf "%.0f")"

  _multi_thread="$(sysbench --validate --time="$BENCH_TIME" --threads="$(grep -c ^processor /proc/cpuinfo)" cpu run \
                  | grep 'events per second' \
                  | sed 's/events per second://g' \
                  | sed 's/[[:space:]]*//g' \
                  | xargs printf "%.0f")"

  _cpu_bench="$(jq --null-input --arg singlethread "$_single_thread" --arg multithread "$_multi_thread" '
                  {"single": ($singlethread|tonumber), "multi": ($multithread|tonumber)}
                ')"

  # Update node facts
  NODE_FACTS="$(echo "$NODE_FACTS" \
              | jq --compact-output --sort-keys --argjson cpubench "$_cpu_bench" '.bench.cpu = $cpubench')"
}

################################################################################################################################

# === CONFIGURATION ===
# Benchmark time in seconds
BENCH_TIME=16
# Log level
LOG_LEVEL=$LOG_LEVEL_INFO
# Node facts
NODE_FACTS="{}"
# reCluster directory
RECLUSTER_DIR="/etc/recluster"

# === ARGUMENTS ===
parse_args "$@"

# === ASSERT ===
# Sudo
if [ "$(id -u)" -ne 0 ]; then FATAL "Run as 'root' for administrative rights"; fi
# Commands
assert_cmd "ethtool"
assert_cmd "env"
assert_cmd "grep"
assert_cmd "ip"
assert_cmd "jq"
assert_cmd "lscpu"
assert_cmd "lsmem"
assert_cmd "lsblk"
assert_cmd "numfmt"
assert_cmd "ps"
assert_cmd "sed"
assert_cmd "sysbench"
assert_cmd "tput"
assert_cmd "xargs"

# === MAIN ===
case $INSTALLATION_STAGE in
  0)
    # reCluster directory
    if [ -d "$RECLUSTER_DIR" ]; then FATAL "reCluster directory '$RECLUSTER_DIR' already exists"; fi
    INFO "Creating reCluster directory '$RECLUSTER_DIR'"
    mkdir -p "$RECLUSTER_DIR"

    # === INFO ===
    # CPU info
    read_cpu_info
    DEBUG "CPU info:\n$(echo "$NODE_FACTS" | jq .info.cpu)"
    INFO "CPU is '$(echo "$NODE_FACTS" | jq --raw-output .info.cpu.name)'"
    # RAM info
    read_ram_info
    DEBUG "RAM info:\n$(echo "$NODE_FACTS" | jq .info.ram)"
    INFO "RAM is '$(echo "$NODE_FACTS" | jq --raw-output .info.ram.size)' Bytes"
    # Disk(s) info
    read_disks_info
    DEBUG "Disk(s) info:\n$(echo "$NODE_FACTS" | jq .info.disks)"
    INFO "Disk(s) found $(echo "$NODE_FACTS" | jq --raw-output '.info.disks | length'):\n $(echo "$NODE_FACTS" | jq --raw-output '.info.disks[] | "\t'\''\(.name)'\'' of '\''\(.size)'\'' Bytes"')"
    # Interface(s) info
    read_interfaces_info
    DEBUG "Interface(s) info:\n$(echo "$NODE_FACTS" | jq .info.interfaces)"
    INFO "Interface(s) found $(echo "$NODE_FACTS" | jq --raw-output '.info.interfaces | length'):\n $(echo "$NODE_FACTS" | jq --raw-output '.info.interfaces[] | "\t'\''\(.name)'\'' at '\''\(.address)'\''"')"

    # === BENCHMARK ===
    # CPU bench
    spinner_start "CPU benchmarks"
    run_cpu_bench
    spinner_stop
    DEBUG "CPU bench:\n$(echo "$NODE_FACTS" | jq .bench.cpu)"
    INFO "CPU bench:\n \tSingle-thread score '$(echo "$NODE_FACTS" | jq --raw-output .bench.cpu.single)'\n \tMulti-thread score '$(echo "$NODE_FACTS" | jq --raw-output .bench.cpu.multi)'"
  ;;
esac

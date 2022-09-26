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
# Disable wildcard character expansion
set -o noglob

# ================
# GLOBALS
# ================
# Return value
RETVAL=

# ================
# CLEANUP
# ================
cleanup() {
  # Exit code
  _exit_code=$?
  # Remove temporary directory
  if [ -n "$TMP_DIR" ]; then rm -rf "$TMP_DIR"; fi
  # Reset cursor if spinner enabled and active
  if [ "$SPINNER_ENABLE" = true ] && [ -n "$SPINNER_PID" ]; then
    # Restore cursor position
    tput rc
    # Cursor normal
    tput cnorm
  fi

  exit "$_exit_code"
}

# Trap
trap cleanup INT QUIT TERM EXIT

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

# Print log message
# @param $1 Log level
# @param $2 Message
_log_print_message() {
  _log_level=${1:-LOG_LEVEL_FATAL}
  shift
  _log_level_name=
  _log_message=${*:-}
  _log_prefix=
  _log_suffix="\033[0m"

  # Check log level
  if [ "$_log_level" -gt "$LOG_LEVEL" ]; then return; fi

  case $_log_level in
    "$LOG_LEVEL_FATAL")
      _log_level_name=FATAL
      _log_prefix="\033[41;37m"
      ;;
    "$LOG_LEVEL_ERROR")
      _log_level_name=ERROR
      _log_prefix="\033[1;31m"
      ;;
    "$LOG_LEVEL_WARN")
      _log_level_name=WARN
      _log_prefix="\033[1;33m"
      ;;
    "$LOG_LEVEL_INFO")
      _log_level_name=INFO
      _log_prefix="\033[37m"
      ;;
    "$LOG_LEVEL_DEBUG")
      _log_level_name=DEBUG
      _log_prefix="\033[1;34m"
      ;;
  esac

  # Check color flag
  if [ "$LOG_COLOR_ENABLE" = false ]; then
    _log_prefix=
    _log_suffix=
  fi

  # Log
  printf '%b[%-5s] %b%b\n' "$_log_prefix" "$_log_level_name" "$_log_message" "$_log_suffix"
}

# Fatal log message
FATAL() {
  _log_print_message ${LOG_LEVEL_FATAL} "$@" >&2
  exit 1
}
# Error log message
ERROR() { _log_print_message ${LOG_LEVEL_ERROR} "$@" >&2; }
# Warning log message
WARN() { _log_print_message ${LOG_LEVEL_WARN} "$@" >&2; }
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
# Spinner symbols dots
SPINNER_SYMBOLS_DOTS="⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏"
# Spinner symbols greyscale
SPINNER_SYMBOLS_GREYSCALE="░░░░░░░ ▒░░░░░░ ▒▒░░░░░ ▒▒▒░░░░ ▒▒▒▒░░░ ▒▒▒▒▒░░ ▒▒▒▒▒▒░ ▒▒▒▒▒▒▒ ░▒▒▒▒▒▒ ░░▒▒▒▒▒ ░░░▒▒▒▒ ░░░░▒▒▒ ░░░░░▒▒ ░░░░░░▒"
# Spinner symbols propeller
SPINNER_SYMBOLS_PROPELLER="/ - \\ |"

# Spinner logic
_spinner() {
  # Termination flag
  _terminate=false
  # Termination signal
  trap '_terminate=true' USR1
  # Message
  _spinner_message=${1:-"Loading..."}

  while :; do
    # Cursor invisible
    tput civis

    for s in $SPINNER_SYMBOLS; do
      # Save cursor position
      tput sc
      # Symbol and message
      printf "%s %s" "$s" "$_spinner_message"
      # Restore cursor position
      tput rc

      # Terminate
      if [ "$_terminate" = true ]; then
        # Clear line from position to end
        tput el
        break 2
      fi

      # Animation time
      sleep "$SPINNER_TIME"

      # Check parent still alive
      # Parent PID
      _spinner_ppid=$(ps -p "$$" -o ppid=)
      if [ -n "$_spinner_ppid" ]; then
        # shellcheck disable=SC2086
        _spinner_parentup=$(ps --no-headers $_spinner_ppid)
        if [ -z "$_spinner_parentup" ]; then break 2; fi
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
  # Print message if present
  if [ -n "$1" ]; then INFO "$1"; fi
  if [ "$SPINNER_ENABLE" = false ]; then return; fi
  if [ -n "$SPINNER_PID" ]; then FATAL "Spinner PID ($SPINNER_PID) already defined"; fi

  # Spawn spinner process
  _spinner "$1" &
  # Spinner process id
  SPINNER_PID=$!
}

# Stop spinner
spinner_stop() {
  if [ "$SPINNER_ENABLE" = false ]; then return; fi
  if [ -z "$SPINNER_PID" ]; then FATAL "Spinner PID is undefined"; fi

  # Send termination signal
  kill -s USR1 "$SPINNER_PID"
  # Wait may fail
  wait "$SPINNER_PID" || :
  # Reset pid
  SPINNER_PID=
}

# ================
# FUNCTIONS
# ================
# Show help message
show_help() {
  # Log level name
  _log_level_name=
  case $LOG_LEVEL in
    "$LOG_LEVEL_FATAL") _log_level_name=fatal ;;
    "$LOG_LEVEL_ERROR") _log_level_name=error ;;
    "$LOG_LEVEL_WARN") _log_level_name=warn ;;
    "$LOG_LEVEL_INFO") _log_level_name=info ;;
    "$LOG_LEVEL_DEBUG") _log_level_name=debug ;;
  esac

  # Config file name
  _config_file_name=$(basename "$CONFIG_FILE")

  cat << EOF
Usage: install.sh [--airgap] [--bench-device-api <URL>] [--bench-interval <TIME>]
                  [--bench-time <TIME>] [--config <PATH>] [--disable-color]
                  [--disable-spinner] [--help] [--init-cluster]
                  [--k3s-version <VERSION>] [--log-level <LEVEL>] [--node_exporter-version <VERSION>]
                  [--spinner <SPINNER>]

reCluster installation script.

Options:
  --airgap                             Perform installation in Air-Gap environment

  --bench-device-api <URL>             Benchmark device api url
                                       Default: $BENCH_DEVICE_API
                                       Values:
                                         Any valid api url

  --bench-interval <TIME>              Benchmark read interval time in seconds
                                       Default: $BENCH_INTERVAL
                                       Values:
                                         Any positive number

  --bench-time <TIME>                  Benchmark execution time in seconds
                                       Default: $BENCH_TIME
                                       Values:
                                         Any positive number

  --bench-warmup <TIME>                Benchmark warmup time in seconds
                                       Default: $BENCH_WARMUP
                                       Values:
                                         Any positive number

  --config <PATH>                      Configuration file path
                                       Default: $_config_file_name
                                       Values:
                                         Any valid configuration file path

  --disable-color                      Disable color

  --disable-spinner                    Disable spinner

  --help                               Show this help message and exit

  --init-cluster                       Initialize cluster components and logic.
                                       Enable only when bootstrapping for the first time.

  --k3s-version <VERSION>              K3s version
                                       Default: $K3S_VERSION
                                       Values:
                                         Any K3s version released

  --log-level <LEVEL>                  Logger level
                                       Default: $_log_level_name
                                       Values:
                                         fatal    Fatal level
                                         error    Error level
                                         warn     Warning level
                                         info     Informational level
                                         debug    Debug level

  --node_exporter-version <VERSION>    Node exporter version
                                       Default: $NODE_EXPORTER_VERSION

  --spinner <SPINNER>                  Spinner symbols
                                       Default: propeller
                                       Values:
                                         dots         Dots spinner
                                         greyscale    Greyscale spinner
                                         propeller    Propeller spinner
EOF
}

# Assert command is installed
# @param $1 Command name
assert_cmd() {
  command -v "$1" > /dev/null 2>&1 || FATAL "Command '$1' not found"
  DEBUG "Command '$1' found at '$(command -v "$1")'"
}

# Assert init system
assert_init_system() {
  if [ -x /sbin/openrc-run ]; then
    # OpenRC
    INIT_SYSTEM=openrc
  elif [ -x /bin/systemctl ] || type systemctl > /dev/null 2>&1; then
    # systemd
    INIT_SYSTEM=systemd
  fi

  # Init system check
  if [ -n "$INIT_SYSTEM" ]; then
    # Supported
    DEBUG "Init system is '$INIT_SYSTEM'"
  else
    # Not supported
    FATAL "No supported init system found: 'OpenRC' or 'systemd'"
  fi
}

# Assert executable downloader
assert_downloader() {
  _assert_downloader() {
    # Return failure if it doesn't exist or is no executable
    [ -x "$(command -v "$1")" ] || return 1

    # Set downloader
    DOWNLOADER=$1
    return 0
  }

  # Downloader command
  _assert_downloader curl \
    || _assert_downloader wget \
    || FATAL "No executable downloader found: 'curl' or 'wget'"
  DEBUG "Downloader '$DOWNLOADER' found at '$(command -v "$DOWNLOADER")'"
}

# Assert URL address is reachable
# @param $1 URL address
assert_url_reachability() {
  DEBUG "Testing URL address '$1' reachability"

  case $DOWNLOADER in
    curl)
      curl --fail --silent --show-error "$1" > /dev/null || FATAL "URL address '$1' is unreachable"
      ;;
    wget)
      wget --quiet --spider "$1" 2>&1 || FATAL "URL address '$1' is unreachable"
      ;;
    *) FATAL "Unknown downloader '$DOWNLOADER'" ;;
  esac
}

# Download a file
# @param $1 Output location
# @param $2 Download URL
download() {
  DEBUG "Downloading file '$2' to '$1'"

  # Download
  case $DOWNLOADER in
    curl)
      curl --fail --silent --location --output "$1" "$2" || FATAL "Download file '$2' failed"
      ;;
    wget)
      wget --quiet --output-document="$1" "$2" || FATAL "Download file '$2' failed"
      ;;
    *) FATAL "Unknown downloader '$DOWNLOADER'" ;;
  esac

  DEBUG "Successfully downloaded file '$2' to '$1'"
}

# Print downloaded content
# @param $1 Download URL
download_print() {
  # Download
  case $DOWNLOADER in
    curl)
      curl --fail --silent --location --show-error "$1" || FATAL "Download print '$1' failed"
      ;;
    wget)
      wget --quiet ---output-document=- "$1" 2>&1 || FATAL "Download print '$1' failed"
      ;;
    *) FATAL "Unknown downloader '$DOWNLOADER'" ;;
  esac
}

# Read power consumption in benchmark interval
# @param $1 Benchmark PID
read_power_consumption() {
  _read_power_consumption() {
    download_print "$BENCH_DEVICE_API" | jq --raw-output '.StatusSNS.ENERGY.Power'
  }
  _pid=$1
  _pcs="[]"

  # Warmup
  sleep "$BENCH_WARMUP"

  # Execute
  _end=$(date -ud "$BENCH_TIME second" +%s)
  while [ "$(date -u +%s)" -le "$_end" ]; do
    # Current power consumption
    _pc=$(_read_power_consumption)
    DEBUG "Reading power consumption: ${_pc}W"
    # Add current power consumption to list
    _pcs=$(echo "$_pcs" | jq --arg pc "$_pc" '. |= . + [$pc|tonumber]')
    # Sleep
    sleep "$BENCH_INTERVAL"
  done

  # Terminate benchmark
  DEBUG "Terminating benchmark process PID $_pid"
  kill -s HUP "$_pid"
  # Wait may fail
  wait "$_pid" || :

  # Check pcs length
  [ "$(echo "$_pcs" | jq --raw-output 'length')" -ge 2 ] || FATAL "Not enough power consumption readings"

  # Calculate mean
  _mean=$(
    echo "$_pcs" \
      | jq --raw-output \
        'add / length
          | . + 0.5
          | floor
        '
  )
  DEBUG "PC mean: $_mean"

  # Calculate standard deviation
  _standard_deviation=$(
    echo "$_pcs" \
      | jq --raw-output \
        '(add / length) as $mean
          | (map(. - $mean | . * .) | add) / (length - 1)
          | sqrt
        '
  )
  DEBUG "PC standard deviation: $_standard_deviation"

  # Return
  RETVAL=$(
    jq --null-input \
      --arg mean "$_mean" \
      --arg standard_deviation "$_standard_deviation" \
      '{
        "mean": $mean,
        "standardDeviation": $standard_deviation
      }'
  )
}

# Check if parameter is an integer number
# @param $1 Parameter
is_number_integer() {
  if [ -z "$1" ]; then return 1; fi
  case $1 in
    '' | *[!0-9]*) return 1 ;;
    *) return 0 ;;
  esac
}

# Read CPU information
read_cpu_info() {
  _cpu_info=$(
    lscpu --json \
      | jq \
        '.lscpu
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
          | . + {"cacheL1d": (."L1d cache" | split(" ") | .[0] + " " + .[1])}
          | . + {"cacheL1i": (."L1i cache" | split(" ") | .[0] + " " + .[1])}
          | . + {"cacheL2": (."L2 cache" | split(" ") | .[0] + " " + .[1])}
          | . + {"cacheL3": (."L3 cache" | split(" ") | .[0] + " " + .[1])}
          | {architecture, flags, cores, vendor, family, model, name, vulnerabilities, cacheL1d, cacheL1i, cacheL2, cacheL3}
        '
  )

  # Convert vendor
  _vendor=$(echo "$_cpu_info" | jq --raw-output '.vendor')
  case $_vendor in
    AuthenticAMD) _vendor=AMD ;;
    GenuineIntel) _vendor=INTEL ;;
    *) FATAL "CPU vendor '$_vendor' not supported" ;;
  esac

  # Convert cache to bytes
  _cache_l1d=$(echo "$_cpu_info" | jq --raw-output '.cacheL1d' | sed 's/B.*//' | sed 's/[[:space:]]*//g' | numfmt --from=iec-i)
  _cache_l1i=$(echo "$_cpu_info" | jq --raw-output '.cacheL1i' | sed 's/B.*//' | sed 's/[[:space:]]*//g' | numfmt --from=iec-i)
  _cache_l2=$(echo "$_cpu_info" | jq --raw-output '.cacheL2' | sed 's/B.*//' | sed 's/[[:space:]]*//g' | numfmt --from=iec-i)
  _cache_l3=$(echo "$_cpu_info" | jq --raw-output '.cacheL3' | sed 's/B.*//' | sed 's/[[:space:]]*//g' | numfmt --from=iec-i)

  # Update
  _cpu_info=$(
    echo "$_cpu_info" \
      | jq \
        --arg vendor "$_vendor" \
        --arg cachel1d "$_cache_l1d" \
        --arg cachel1i "$_cache_l1i" \
        --arg cachel2 "$_cache_l2" \
        --arg cachel3 "$_cache_l3" \
        '.vendor = $vendor
          | .cacheL1d = ($cachel1d | tonumber)
          | .cacheL1i = ($cachel1i | tonumber)
          | .cacheL2 = ($cachel2 | tonumber)
          | .cacheL3 = ($cachel3 | tonumber)
        '
  )

  # Update node facts
  NODE_FACTS=$(
    echo "$NODE_FACTS" \
      | jq --argjson cpuinfo "$_cpu_info" '.cpu = $cpuinfo'
  )
}

# Read RAM information
read_ram_info() {
  _ram_size=$(
    grep MemTotal /proc/meminfo \
      | sed 's/MemTotal://g' \
      | sed 's/[[:space:]]*//g' \
      | sed 's/B.*//' \
      | tr '[:lower:]' '[:upper:]' \
      | numfmt --from iec
  )

  _ram_info=$(
    jq --null-input --arg size "$_ram_size" \
      '{
        "size": ($size | tonumber)
      }'
  )

  # Update node facts
  NODE_FACTS=$(
    echo "$NODE_FACTS" \
      | jq --argjson raminfo "$_ram_info" '.ram = $raminfo'
  )
}

# Read Disk(s) information
read_disks_info() {
  _disks_info=$(
    lsblk --bytes --json \
      | jq \
        '.blockdevices
          | map(select(.type == "disk"))
          | map({name, size})
        '
  )

  # Update node facts
  NODE_FACTS=$(
    echo "$NODE_FACTS" \
      | jq --argjson disksinfo "$_disks_info" '.disks = $disksinfo'
  )
}

# Read Interface(s) information
read_interfaces_info() {
  _interfaces_info=$(
    ip -details -json link show \
      | jq \
        'map(if .linkinfo.info_kind // .link_type == "loopback" then empty else . end)
          | map(.name = .ifname)
          | map({address, name})
        '
  )

  # Cycle interfaces to obtain additional information
  while read -r _interface; do
    _iname=$(echo "$_interface" | jq --raw-output '.name')

    # Speed
    _speed=$($SUDO ethtool "$_iname" | grep Speed | sed 's/Speed://g' | sed 's/[[:space:]]*//g' | sed 's/b.*//' | numfmt --from=si)
    # Wake on Lan
    _wol=$($SUDO ethtool "$_iname" | grep 'Supports Wake-on' | sed 's/Supports Wake-on://g' | sed 's/[[:space:]]*//g')

    # Update interfaces
    _interfaces_info=$(
      echo "$_interfaces_info" \
        | jq \
          --arg iname "$_iname" \
          --arg speed "$_speed" \
          --arg wol "$_wol" \
          'map(if .name == $iname then . + {"speed": $speed | tonumber, "wol": ($wol | split(""))} else . end)'
    )
  done << EOF
$(echo "$_interfaces_info" | jq --compact-output '.[]')
EOF

  # Update node facts
  NODE_FACTS=$(
    echo "$NODE_FACTS" \
      | jq --argjson interfacesinfo "$_interfaces_info" '.interfaces = $interfacesinfo'
  )
}

# Execute CPU benchmark
run_cpu_bench() {
  _run_cpu_bench() {
    sysbench --time=0 --threads="$1" cpu run > /dev/null &
    read_power_consumption "$!"
  }
  _threads=$(grep -c ^processor /proc/cpuinfo)

  # Single-thread
  DEBUG "Running CPU benchmark: single-thread (1)"
  _run_cpu_bench 1
  _single_thread=$RETVAL

  # Multi-thread
  DEBUG "Running CPU benchmark: multi-thread ($_threads)"
  _run_cpu_bench "$_threads"
  _multi_thread=$RETVAL

  # Update node facts
  NODE_FACTS=$(
    echo "$NODE_FACTS" \
      | jq \
        --argjson singlethread "$_single_thread" \
        --argjson multithread "$_multi_thread" \
        '.cpu.benchmark = {
            "singleThread": $singlethread,
            "multiThread": $multithread
          }
        '
  )
}

# Execute RAM benchmark
run_ram_bench() {
  _run_ram_bench() {
    sysbench --time=0 --memory-oper="$1" --memory-access-mode="$2" memory run > /dev/null &
    read_power_consumption "$!"
  }

  # Read sequential
  DEBUG "Running RAM benchmark: read sequential"
  _run_ram_bench read seq
  _read_seq=$RETVAL
  # Read random
  DEBUG "Running RAM benchmark: read random"
  _run_ram_bench read rnd
  _read_rand=$RETVAL

  # Write sequential
  DEBUG "Running RAM benchmark: write sequential"
  _run_ram_bench write seq
  _write_seq=$RETVAL
  # Write random
  DEBUG "Running RAM benchmark: write random"
  _run_ram_bench write rnd
  _write_rand=$RETVAL

  # Update node facts
  NODE_FACTS=$(
    echo "$NODE_FACTS" \
      | jq \
        --argjson readseq "$_read_seq" \
        --argjson readrand "$_read_rand" \
        --argjson writeseq "$_write_seq" \
        --argjson writerand "$_write_rand" \
        '.ram.benchmark = {
            "read": {
            "sequential": $readseq,
            "random": $readrand
          },
          "write": {
            "sequential": $writeseq,
            "random": $writerand
          }
        }
      '
  )
}

# Execute IO benchmark
run_io_bench() {
  _run_io_bench() {
    # Io operation
    _io_opt=
    case $1 in
      read) _io_opt=$1 ;;
      write) _io_opt=written ;;
    esac

    sysbench --time=0 --file-test-mode="$2" --file-io-mode="$3" fileio run > /dev/null &
    read_power_consumption "$!"
  }

  # TODO Benchmark per disk

  # Prepare sysbench IO
  DEBUG "Preparing IO benchmark"
  sysbench fileio cleanup > /dev/null
  sysbench fileio prepare > /dev/null

  # Read sequential synchronous
  _read_seq_sync=$(_run_io_bench read seqrd sync)
  # Read sequential asynchronous
  _read_seq_async=$(_run_io_bench read seqrd async)

  # Read random synchronous
  _read_rand_sync=$(_run_io_bench read rndrd sync)
  # Read random asynchronous
  _read_rand_async=$(_run_io_bench read rndrd async)

  # Write sequential synchronous
  _write_seq_sync=$(_run_io_bench write seqwr sync)
  # Write sequential asynchronous
  _write_seq_async=$(_run_io_bench write seqwr async)

  # Write random synchronous
  _write_rand_sync=$(_run_io_bench write rndwr sync)
  # Write random asynchronous
  _write_rand_async=$(_run_io_bench write rndwr async)

  # Clean sysbench IO
  sysbench fileio cleanup > /dev/null

  DEBUG "IO bench:
    \tRead Sequential Sync '$(echo "$_read_seq_sync" | numfmt --to=si)b/s'
    \tRead Sequential Async '$(echo "$_read_seq_async" | numfmt --to=si)b/s'
    \tRead Random Sync '$(echo "$_read_rand_sync" | numfmt --to=si)b/s'
    \tRead Random Async '$(echo "$_read_rand_async" | numfmt --to=si)b/s'
    \tWrite Sequential Sync '$(echo "$_write_seq_sync" | numfmt --to=si)b/s'
    \tWrite Sequential Async '$(echo "$_write_seq_async" | numfmt --to=si)b/s'
    \tWrite Random Sync '$(echo "$_write_rand_sync" | numfmt --to=si)b/s'
    \tWrite Random Async '$(echo "$_write_rand_async" | numfmt --to=si)b/s'"
}

# Register current node
node_registration() {
  _server_url=$(echo "$CONFIG" | jq --exit-status --raw-output '.recluster.server') || FATAL "reCluster configuration requires 'server: <URL>'"
  # shellcheck disable=SC2016
  _data='{ "query": "mutation ($data: CreateNodeInput!) { createNode(data: $data) { id } }", "variables": { "data": '"$(echo "$NODE_FACTS" | jq --compact-output .)"' } }'
  _response=

  INFO "Registering node at '$_server_url'"

  # Send node registration request
  DEBUG "Sending node registration data '$_data' to '$_server_url'"
  case $DOWNLOADER in
    curl)
      _response=$(curl --fail --silent --location --show-error \
        --request POST \
        --header 'Content-Type: application/json' \
        --url "$_server_url" \
        --data "$_data") || FATAL "Error sending node registration request to '$_server_url'"
      ;;
    wget)
      _response=$(wget --quiet --output-document=- \
        --header='Content-Type: application/json' \
        --post-data="$_data" \
        "$_server_url" 2>&1) || FATAL "Error sending node registration request to '$_server_url'"
      ;;
    *) FATAL "Unknown downloader '$DOWNLOADER'" ;;
  esac
  DEBUG "Received node registration response data '$_response' from '$_server_url'"

  # Check error response
  if echo "$_response" | jq --exit-status 'has("errors")' > /dev/null 2>&1; then
    FATAL "Error registering node:\n$(echo "$_response" | jq .)"
  fi

  RECLUSTER_NODE_ID=$(echo "$_response" | jq --raw-output '.data.createNode.id')
  INFO "Node registered with id '$RECLUSTER_NODE_ID'"
}

################################################################################################################################

# Parse command line arguments
# @param $@ Arguments
parse_args() {
  _parse_args_assert_value() {
    if [ -z "$2" ]; then FATAL "Argument '$1' requires a non-empty value"; fi
  }
  _parse_args_assert_positive_number_integer() {
    if ! is_number_integer "$2" || [ "$2" -le 0 ]; then FATAL "Value '$2' of argument '$1' is not a positive number"; fi
  }
  _parse_args_invalid_value() {
    FATAL "Value '$2' of argument '$1' is invalid"
  }

  # Parse
  while [ $# -gt 0 ]; do
    case $1 in
      --airgap)
        # Airgap environment
        AIRGAP_ENV=true
        shift
        ;;
      --bench-device-api)
        # Benchmark device api url
        _parse_args_assert_value "$@"

        _bench_device_api=$2
        shift
        shift
        ;;
      --bench-interval)
        # Benchmark interval
        _parse_args_assert_value "$@"
        _parse_args_assert_positive_number_integer "$1" "$2"

        _bench_interval=$2
        shift
        shift
        ;;
      --bench-time)
        # Benchmark time
        _parse_args_assert_value "$@"
        _parse_args_assert_positive_number_integer "$1" "$2"

        _bench_time=$2
        shift
        shift
        ;;
      --bench-warmup)
        # Benchmark warmup time
        _parse_args_assert_value "$@"
        _parse_args_assert_positive_number_integer "$1" "$2"

        _bench_warmup=$2
        shift
        shift
        ;;
      --config)
        # Configuration file
        _parse_args_assert_value "$@"

        _config=$2
        shift
        shift
        ;;
      --disable-color)
        # Disable color
        LOG_COLOR_ENABLE=false
        shift
        ;;
      --disable-spinner)
        # Disable spinner
        SPINNER_ENABLE=false
        shift
        ;;
      --help)
        # Display help message and exit
        show_help
        exit 0
        ;;
      --init-cluster)
        # Initialize cluster
        INIT_CLUSTER=true
        shift
        ;;
      --k3s-version)
        # K3s version
        _parse_args_assert_value "$@"

        _k3s_version=$2
        shift
        shift
        ;;
      --log-level)
        # Log level
        _parse_args_assert_value "$@"

        case $2 in
          fatal) _log_level=$LOG_LEVEL_FATAL ;;
          error) _log_level=$LOG_LEVEL_ERROR ;;
          warn) _log_level=$LOG_LEVEL_WARN ;;
          info) _log_level=$LOG_LEVEL_INFO ;;
          debug) _log_level=$LOG_LEVEL_DEBUG ;;
          *) _parse_args_invalid_value "$1" "$2" ;;
        esac
        shift
        shift
        ;;
      --node_exporter-version)
        # Node exporter version
        _parse_args_assert_value "$@"

        _node_exporter_version=$2
        shift
        shift
        ;;
      --spinner)
        _parse_args_assert_value "$@"

        case $2 in
          dots) _spinner=$SPINNER_SYMBOLS_DOTS ;;
          greyscale) _spinner=$SPINNER_SYMBOLS_GREYSCALE ;;
          propeller) _spinner=$SPINNER_SYMBOLS_PROPELLER ;;
          *) _parse_args_invalid_value "$1" "$2" ;;
        esac
        shift
        shift
        ;;
      -*)
        # Unknown argument
        WARN "Unknown argument '$1'"
        shift
        ;;
      *)
        # No argument
        WARN "Skipping argument '$1'"
        shift
        ;;
    esac
  done

  # Benchmark device api
  if [ -n "$_bench_device_api" ]; then BENCH_DEVICE_API=$_bench_device_api; fi
  # Benchmark interval
  if [ -n "$_bench_interval" ]; then BENCH_INTERVAL=$_bench_interval; fi
  # Benchmark time
  if [ -n "$_bench_time" ]; then BENCH_TIME=$_bench_time; fi
  # Benchmark warmup time
  if [ -n "$_bench_warmup" ]; then BENCH_WARMUP=$_bench_warmup; fi
  # Configuration file
  if [ -n "$_config" ]; then CONFIG_FILE=$_config; fi
  # K3s version
  if [ -n "$_k3s_version" ]; then K3S_VERSION=$_k3s_version; fi
  # Log level
  if [ -n "$_log_level" ]; then LOG_LEVEL=$_log_level; fi
  # Node exporter version
  if [ -n "$_node_exporter_version" ]; then NODE_EXPORTER_VERSION=$_node_exporter_version; fi
  # Spinner
  if [ -n "$_spinner" ]; then SPINNER_SYMBOLS=$_spinner; fi
}

# Verify system
verify_system() {
  # Architecture
  ARCH=$(uname -m)
  case $ARCH in
    amd64 | x86_64) ARCH=amd64 ;;
    arm64 | aarch64) ARCH=arm64 ;;
    armv5*) ARCH=armv5 ;;
    armv6*) ARCH=armv6 ;;
    armv7*) ARCH=armv7 ;;
    s390x) ARCH=s390x ;;
    *) FATAL "Architecture '$ARCH' is not supported" ;;
  esac

  # Commands
  # TODO Check some command only when cluster init is 'true'
  assert_cmd cp
  assert_cmd date
  assert_cmd ethtool
  assert_cmd grep
  assert_cmd ip
  assert_cmd inotifywait
  assert_cmd jq
  assert_cmd lscpu
  assert_cmd lsblk
  assert_cmd mktemp
  assert_cmd numfmt
  assert_cmd read
  assert_cmd sed
  assert_cmd sudo
  assert_cmd sysbench
  assert_cmd tar
  assert_cmd tee
  assert_cmd tr
  assert_cmd uname
  assert_cmd yq

  # Spinner
  if [ "$SPINNER_ENABLE" = true ]; then
    # Commands
    assert_cmd ps
    assert_cmd tput
  fi

  # Init system
  assert_init_system

  # Downloader command
  assert_downloader

  # Check BENCH_DEVICE_API reachability
  assert_url_reachability "$BENCH_DEVICE_API"

  # Directories
  [ ! -d "$RECLUSTER_ETC_DIR" ] || FATAL "reCluster etc directory '$RECLUSTER_ETC_DIR' already exists"
  [ ! -d "$RECLUSTER_OPT_DIR" ] || FATAL "reCluster opt directory '$RECLUSTER_OPT_DIR' already exists"

  # Sudo
  if [ "$(id -u)" -eq 0 ]; then
    WARN "Already running as 'root'"
    SUDO=
  else
    WARN "Requesting 'root' privileges"
    SUDO=sudo
    $SUDO --reset-timestamp
    $SUDO true || FATAL "Failed to obtain 'root' privileges"
  fi
}

# Setup system
setup_system() {
  # Temporary directory
  TMP_DIR=$(mktemp --directory -t recluster.XXXXXXXX)
  DEBUG "Created temporary directory '$TMP_DIR'"

  # Configuration
  INFO "Reading configuration file '$CONFIG_FILE'"
  [ -f "$CONFIG_FILE" ] || FATAL "Configuration file '$CONFIG_FILE' not found"
  CONFIG=$(yq e --output-format=json --no-colors '.' "$CONFIG_FILE") || FATAL "Error reading configuration file '$CONFIG_FILE'"
  DEBUG "Configuration:\n$(echo "$CONFIG" | jq .)"

  # Airgap
  if [ "$AIRGAP_ENV" = true ]; then
    spinner_start "Preparing Air-Gap environment"

    # Directories
    _dep_dir="$DIRNAME/dependencies"
    _k3s_dep_dir="$_dep_dir/k3s/$K3S_VERSION"
    _node_exporter_dep_dir="$_dep_dir/node_exporter/$NODE_EXPORTER_VERSION"

    # Architecture
    _k3s_bin_suffix=
    _k3s_images_suffix=
    case $ARCH in
      amd64)
        _k3s_bin_suffix=
        _k3s_images_suffix=amd64
        ;;
      arm64)
        _k3s_bin_suffix=-arm64
        _k3s_images_suffix=arm64
        ;;
      arm*)
        _k3s_bin_suffix=-armhf
        _k3s_images_suffix=arm
        ;;
      s390x)
        _k3s_bin_suffix=-s390x
        _k3s_images_suffix=s390x
        ;;
      *) FATAL "Unknown architecture '$ARCH'" ;;
    esac

    # General
    _k3s_airgap_images_name="k3s-airgap-images-$_k3s_images_suffix"
    _node_exporter_release_name=node_exporter-$(echo "$NODE_EXPORTER_VERSION" | sed 's/^v//').linux-$ARCH

    # Globals
    AIRGAP_K3S_BIN="$TMP_DIR/k3s.bin"
    AIRGAP_K3S_IMAGES="$TMP_DIR/$_k3s_airgap_images_name.tar.gz"
    AIRGAP_NODE_EXPORTER_BIN="$TMP_DIR/node_exporter.bin"

    # Resources
    _k3s_dep_bin="$_k3s_dep_dir/k3s$_k3s_bin_suffix"
    _k3s_dep_images_tar="$_k3s_dep_dir/$_k3s_airgap_images_name.tar.gz"
    _node_exporter_dep_tar="$_node_exporter_dep_dir/$_node_exporter_release_name.tar.gz"

    # Check directories
    [ -d "$_k3s_dep_dir" ] || FATAL "K3s dependency directory '$_k3s_dep_dir' not found"
    [ -d "$_node_exporter_dep_dir" ] || FATAL "Node exporter dependency directory '$_node_exporter_dep_dir' not found"
    # Check resources
    [ -f "$_k3s_dep_bin" ] || FATAL "K3s dependency binary '$_k3s_dep_bin' not found"
    [ -f "$_k3s_dep_images_tar" ] || FATAL "K3s dependency images tar '$_k3s_dep_images_tar' not found"
    [ -f "$_node_exporter_dep_tar" ] || FATAL "Node exporter dependency tar '$_node_exporter_dep_tar' not found"

    # Extract Node exporter
    DEBUG "Extracting Node exporter archive '$_node_exporter_dep_tar'"
    tar xzf "$_node_exporter_dep_tar" -C "$TMP_DIR" --strip-components 1 "$_node_exporter_release_name/node_exporter" || FATAL "Error extracting Node exporter archive '$_node_exporter_dep_tar'"

    # Move to temporary directory
    cp "$_k3s_dep_bin" "$AIRGAP_K3S_BIN"
    cp "$_k3s_dep_images_tar" "$AIRGAP_K3S_IMAGES"
    mv "$TMP_DIR/node_exporter" "$AIRGAP_NODE_EXPORTER_BIN"

    # Permissions
    chmod 755 "$AIRGAP_K3S_BIN"
    chmod 755 "$AIRGAP_NODE_EXPORTER_BIN"
    $SUDO chown root:root "$AIRGAP_K3S_BIN"
    $SUDO chown root:root "$AIRGAP_NODE_EXPORTER_BIN"

    spinner_stop
  fi
}

# Read system information
read_system_info() {
  spinner_start "Reading system information"

  # CPU info
  read_cpu_info
  DEBUG "CPU info:\n$(echo "$NODE_FACTS" | jq .cpu)"
  INFO "CPU is '$(echo "$NODE_FACTS" | jq --raw-output .cpu.name)'"

  # RAM info
  read_ram_info
  DEBUG "RAM info:\n$(echo "$NODE_FACTS" | jq .ram)"
  INFO "RAM is '$(echo "$NODE_FACTS" | jq --raw-output .ram.size | numfmt --to=iec-i)B'"

  # Disk(s) info
  read_disks_info
  DEBUG "Disk(s) info:\n$(echo "$NODE_FACTS" | jq .disks)"
  _disks_info="Disk(s) found $(echo "$NODE_FACTS" | jq --raw-output '.disks | length'):"
  while read -r _disk_info; do
    _disks_info="$_disks_info\n\t'$(echo "$_disk_info" | jq --raw-output .name)' of '$(echo "$_disk_info" | jq --raw-output .size | numfmt --to=iec-i)B'"
  done << EOF
$(echo "$NODE_FACTS" | jq --compact-output '.disks[]')
EOF
  INFO "$_disks_info"

  # Interface(s) info
  read_interfaces_info
  DEBUG "Interface(s) info:\n$(echo "$NODE_FACTS" | jq .interfaces)"
  INFO "Interface(s) found $(echo "$NODE_FACTS" | jq --raw-output '.interfaces | length'):
    $(echo "$NODE_FACTS" | jq --raw-output '.interfaces[] | "\t'\''\(.name)'\'' at '\''\(.address)'\''"')"

  spinner_stop
}

# Execute benchmarks
run_benchmarks() {
  # CPU bench
  spinner_start "CPU benchmark"
  run_cpu_bench
  spinner_stop
  DEBUG "CPU benchmark:\n$(echo "$NODE_FACTS" | jq .cpu.benchmark)"

  # RAM bench
  spinner_start "RAM benchmark"
  run_ram_bench
  spinner_stop
  DEBUG "RAM benchmark:\n$(echo "$NODE_FACTS" | jq .ram.benchmark)"

  # IO bench
  spinner_start "IO benchmark"
  # FIXME run_io_bench
  spinner_stop
  # TODO IO benchmark
  # DEBUG "IO benchmark:\n$(echo "$NODE_FACTS" | jq .io.benchmark)"
}

# Install K3s
install_k3s() {
  _k3s_install_sh=
  _k3s_kind=
  _k3s_config_file=/etc/rancher/k3s/config.yaml
  _k3s_config=

  # Check airgap environment
  if [ "$AIRGAP_ENV" = true ]; then
    # Airgap enabled
    _k3s_install_sh="$DIRNAME/dependencies/k3s/install.sh"
    _k3s_airgap_images=/var/lib/rancher/k3s/agent/images
    # Create directory
    $SUDO mkdir -p "$_k3s_airgap_images"
    # Move
    $SUDO mv --force "$AIRGAP_K3S_BIN" /usr/local/bin/k3s
    $SUDO mv --force "$AIRGAP_K3S_IMAGES" "$_k3s_airgap_images"
  else
    # Airgap disabled
    _k3s_install_sh="$TMP_DIR/install.k3s.sh"
    # Download installer
    spinner_start "Downloading K3s installer"
    download "$_k3s_install_sh" https://get.k3s.io
    chmod 755 "$_k3s_install_sh"
    spinner_stop
  fi

  # Checks
  [ -f "$_k3s_install_sh" ] || FATAL "K3s installation script '$_k3s_install_sh' not found"
  [ -x "$_k3s_install_sh" ] || FATAL "K3s installation script '$_k3s_install_sh' is not executable"

  # Kind
  _k3s_kind=$(echo "$CONFIG" | jq --exit-status --raw-output '.k3s.kind') || FATAL "K3s configuration requires 'kind: <server|agent>'"
  [ "server" = "$_k3s_kind" ] || [ "agent" = "$_k3s_kind" ] || FATAL "K3s configuration 'kind' value must be 'server' or 'agent' but '$_k3s_kind' found"

  # Configuration
  _k3s_config=$(echo "$CONFIG" | jq --exit-status '.k3s | del(.kind)' | yq e --exit-status --prettyPrint --no-colors '.' -) || FATAL "Error reading K3s configuration"
  INFO "Writing K3s configuration to '$_k3s_config_file'"
  $SUDO mkdir -p "$(dirname "$_k3s_config_file")"
  printf "%s" "$_k3s_config" | $SUDO tee "$_k3s_config_file" > /dev/null

  # Install
  spinner_start "Installing K3s '$K3S_VERSION'"

  INSTALL_NODE_EXPORTER_SKIP_ENABLE=true \
    INSTALL_K3S_SKIP_START=true \
    INSTALL_K3S_SKIP_DOWNLOAD="$AIRGAP_ENV" \
    INSTALL_K3S_VERSION="$K3S_VERSION" \
    INSTALL_K3S_NAME=recluster \
    INSTALL_K3S_EXEC="$_k3s_kind" \
    "$_k3s_install_sh" || FATAL "Error installing K3s '$K3S_VERSION'"

  spinner_stop

  # Success
  INFO "Successfully installed K3s '$K3S_VERSION'"
}

# Install Node exporter
install_node_exporter() {
  _node_exporter_install_sh=
  _node_exporter_config=

  # Check airgap environment
  if [ "$AIRGAP_ENV" = true ]; then
    # Airgap enabled
    _node_exporter_install_sh="$DIRNAME/dependencies/node_exporter/install.sh"
    # Move
    $SUDO mv --force "$AIRGAP_NODE_EXPORTER_BIN" /usr/local/bin/node_exporter
  else
    # Airgap disabled
    _node_exporter_install_sh="$TMP_DIR/install.node_exporter.sh"
    # Download installer
    spinner_start "Downloading Node exporter installer"
    download "$_node_exporter_install_sh" https://raw.githubusercontent.com/carlocorradini/node_exporter_installer/main/install.sh
    chmod 755 "$_node_exporter_install_sh"
    spinner_stop
  fi

  # Checks
  [ -f "$_node_exporter_install_sh" ] || FATAL "Node exporter installation script '$_node_exporter_install_sh' not found"
  [ -x "$_node_exporter_install_sh" ] || FATAL "Node exporter installation script '$_node_exporter_install_sh' is not executable"

  # Configuration
  INFO "Writing Node exporter configuration"
  _node_exporter_config=$(echo "$CONFIG" | jq --raw-output '.node_exporter.collector | to_entries | map(if .value == true then ("--collector."+.key) else ("--no-collector."+.key) end) | join(" ")') || FATAL "Error reading Node exporter configuration"

  # Install
  spinner_start "Installing Node exporter '$NODE_EXPORTER_VERSION'"

  INSTALL_NODE_EXPORTER_SKIP_ENABLE=true \
    INSTALL_NODE_EXPORTER_SKIP_START=true \
    INSTALL_NODE_EXPORTER_SKIP_DOWNLOAD="$AIRGAP_ENV" \
    INSTALL_NODE_EXPORTER_VERSION="$NODE_EXPORTER_VERSION" \
    INSTALL_NODE_EXPORTER_EXEC="$_node_exporter_config" \
    "$_node_exporter_install_sh" || FATAL "Error installing Node exporter '$NODE_EXPORTER_VERSION'"

  spinner_stop

  # Success
  INFO "Successfully installed Node exporter '$NODE_EXPORTER_VERSION'"
}

# Cluster initialization
cluster_init() {
  [ "$INIT_CLUSTER" = true ] || return 0

  INFO "Cluster initialization"

  _k3s_kubeconfig_file=/etc/rancher/k3s/k3s.yaml
  _kubeconfig_file=~/.kube/config

  _wait_k3s_kubeconfig_file_creation() {
    _k3s_kubeconfig_dir=$(dirname "$_k3s_kubeconfig_file")
    _k3s_kubeconfig_file_name=$(basename "$_k3s_kubeconfig_file")

    INFO "Waiting K3s kubeconfig file at '$_k3s_kubeconfig_file'"
    inotifywait -e create,close_write,moved_to --format '%f' --quiet "$_k3s_kubeconfig_dir" --monitor \
      | while IFS= read -r file; do
        DEBUG "File '$file' notify at '$_k3s_kubeconfig_dir'"
        if [ "$file" = "$_k3s_kubeconfig_file_name" ]; then
          DEBUG "K3s kubeconfig file generated"
          break
        fi
      done
  }

  # Start and stop K3s service to generate initial configuration
  case $INIT_SYSTEM in
    openrc)
      INFO "openrc: Starting K3s service"
      $SUDO rc-service k3s-recluster start
      _wait_k3s_kubeconfig_file_creation
      INFO "openrc: Stopping K3s service"
      $SUDO rc-service k3s-recluster stop
      ;;
    systemd)
      INFO "systemd: Starting K3s service"
      $SUDO systemctl start k3s-recluster
      _wait_k3s_kubeconfig_file_creation
      INFO "systemd: Stopping K3s service"
      $SUDO systemctl stop k3s-recluster
      ;;
    *) FATAL "Unknown init system '$INIT_SYSTEM'" ;;
  esac

  # Copy kubeconfig
  if [ -f "$_kubeconfig_file" ]; then
    WARN "kubeconfig '$_kubeconfig_file' already exists, skipping copying to '$_kubeconfig_file'"
  else
    _kubeconfig_dir=$(dirname "$_kubeconfig_file")
    INFO "Copying K3s kubeconfig from '$_k3s_kubeconfig_file' to '$_kubeconfig_file'"
    [ -d "$_kubeconfig_dir" ] || mkdir "$_kubeconfig_dir"
    $SUDO cp "$_k3s_kubeconfig_file" "$_kubeconfig_file"
    $SUDO chmod 0644 "$_kubeconfig_file"
  fi

  # Read kubeconfig
  WARN "kubeconfig:"
  $SUDO yq e --prettyPrint '.' "$_k3s_kubeconfig_file"

  # TODO Server token

  # reCluster server
  # TODO Must be a service
  # TODO Wait until server URL is reachable
  WARN "Waiting you to start reCluster server"
  WARN "Press [ENTER] to continue..."
  read -r
}

# Install reCluster
install_recluster() {
  # Files
  _k3s_config_file=/etc/rancher/k3s/config.yaml
  _recluster_config_file="$RECLUSTER_ETC_DIR/config.yaml"
  _recluster_id_file="$RECLUSTER_ETC_DIR/id"
  _recluster_bootstrap_sh="$RECLUSTER_OPT_DIR/bootstrap.sh"
  # Configuration
  _recluster_node_label_id="recluster.io/id="
  _recluster_bootstrap_service_name=recluster-bootstrap

  spinner_start "Installing reCluster"

  # Directories
  INFO "Creating reCluster etc directory '$RECLUSTER_ETC_DIR'"
  $SUDO mkdir -p "$RECLUSTER_ETC_DIR"
  INFO "Creating reCluster opt directory '$RECLUSTER_OPT_DIR'"
  $SUDO mkdir -p "$RECLUSTER_OPT_DIR"

  # Configuration
  _recluster_config=$(echo "$CONFIG" | jq '.recluster' | yq e --prettyPrint --no-colors '.' -) || FATAL "Error reading reCluster configuration"
  INFO "Writing reCluster configuration to '$_recluster_config_file'"
  printf "%s" "$_recluster_config" | $SUDO tee "$_recluster_config_file" > /dev/null

  # Node registration
  node_registration
  printf "%s" "$RECLUSTER_NODE_ID" | $SUDO tee "$_recluster_id_file" > /dev/null
  _recluster_node_label_id="${_recluster_node_label_id}${RECLUSTER_NODE_ID}"
  # TODO Node token
  # INFO "Writing reCluster token '$RECLUSTER_NODE_TOKEN' to '$_recluster_token_file'"
  # printf "%s" "$RECLUSTER_NODE_TOKEN" | $SUDO tee "$_recluster_token_file" > /dev/null

  # Node label reCluster id
  DEBUG "Updating K3s configuration '$_k3s_config_file' adding 'node-label: - $_recluster_node_label_id'"
  $SUDO \
    node_label="$_recluster_node_label_id" \
    yq e '.node-label += [env(node_label)]' -i "$_k3s_config_file"

  # Bootstrap script
  $SUDO tee "$_recluster_bootstrap_sh" > /dev/null << EOF
#!/usr/bin/env sh

# Fail on error
set -o errexit
# Disable wildcard character expansion
set -o noglob

# ================
# LOGGER
# ================
# Fatal log message
FATAL() {
  printf '[FATAL] %s\n' "\$@" >&2
  exit 1
}
# Info log message
INFO() {
  printf '[INFO ] %s\n' "\$@"
}

# ================
# FUNCTIONS
# ================
read_config() {
  INFO "Reading configuration file '$_recluster_config_file'"
  [ -f $_recluster_config_file ] || FATAL "Configuration file '$_recluster_config_file' not found"
  RECLUSTER_CONFIG=\$(yq e --output-format=json --no-colors '.' $_recluster_config_file) || FATAL "Error reading configuration file '$_recluster_config_file'"
}

update_status() {
  _status=ACTIVE
  _server_url=\$(echo "\$RECLUSTER_CONFIG" | jq --exit-status --raw-output '.server') || FATAL "reCluster configuration requires 'server: <URL>'"
  # shellcheck disable=SC2016
  _data='{ "query": "mutation (\$data: UpdateNodeInput!) { updateNode(data: \$data) { id } }", "variables": { "data": { "status": "'"\$_status"'" } } }'
  _response=

  INFO "Updating node status '\$_status' at '\$_server_url'"

  # Send update request
EOF
  case $DOWNLOADER in
    curl)
      $SUDO tee -a "$_recluster_bootstrap_sh" > /dev/null << EOF
  _response=\$(curl --fail --silent --location --show-error \\
    --request POST \\
    --header 'Content-Type: application/json' \\
    --url "\$_server_url" \\
    --data "\$_data") || FATAL "Error sending update node status request to '\$_server_url'"
EOF
      ;;
    wget)
      $SUDO tee -a "$_recluster_bootstrap_sh" > /dev/null << EOF
  _response=\$(wget --quiet --output-document=- \\
    --header='Content-Type: application/json' \\
    --post-data="\$_data" \\
    "\$_server_url" 2>&1) || FATAL "Error sending update node status request to '\$_server_url'"
EOF
      ;;
    *) FATAL "Unknown downloader '$DOWNLOADER'" ;;
  esac

  $SUDO tee -a "$_recluster_bootstrap_sh" > /dev/null << EOF
  # Check error response
  if echo "\$_response" | jq --exit-status 'has("errors")' > /dev/null 2>&1; then
    FATAL "Error updating node status:\n\$(echo "\$_response" | jq .)";
  fi

  INFO "Node status '\$_status' updated"
}

start_services() {
EOF
  case $INIT_SYSTEM in
    openrc)
      $SUDO tee -a "$_recluster_bootstrap_sh" > /dev/null << EOF
  INFO "Starting Node exporter"
  rc-service node_exporter start || true
  INFO "Starting K3s"
  rc-service k3s-recluster start
EOF
      ;;
    systemd)
      $SUDO tee -a "$_recluster_bootstrap_sh" > /dev/null << EOF
  INFO "Starting Node exporter"
  systemtc start node_exporter || true
  INFO "Starting K3s"
  systemctl start k3s-recluster
EOF
      ;;
    *) FATAL "Unknown init system '$INIT_SYSTEM'" ;;
  esac

  $SUDO tee -a "$_recluster_bootstrap_sh" > /dev/null << EOF
}

# ================
# CONFIGURATION
# ================
RECLUSTER_CONFIG=

# ================
# MAIN
# ================
{
  read_config
  update_status
  start_services
}
EOF

  # Bootstrap script permissions
  $SUDO chmod 755 "$_recluster_bootstrap_sh"
  $SUDO chown root:root "$_recluster_bootstrap_sh"

  # Bootstrap service
  case $INIT_SYSTEM in
    openrc)
      _recluster_bootstrap_service_file="/etc/init.d/$_recluster_bootstrap_service_name"

      INFO "openrc: Creating reCluster bootstrap service file '$_recluster_bootstrap_service_file'"
      $SUDO tee "$_recluster_bootstrap_service_file" > /dev/null << EOF
#!/sbin/openrc-run

description="reCluster bootstrap"

depend() {
  need net
  use dns
  after firewall
}

command="$_recluster_bootstrap_sh"
EOF

      $SUDO chmod 0755 $_recluster_bootstrap_service_file

      INFO "openrc: Enabling reCluster bootstrap service '$_recluster_bootstrap_service_name' for default runlevel"
      $SUDO rc-update add "$_recluster_bootstrap_service_name" default > /dev/null
      ;;
    systemd)
      _recluster_bootstrap_service_file="/etc/systemd/system/$_recluster_bootstrap_service_name.service"

      INFO "systemd: Creating reCluster bootstrap service file '$_recluster_bootstrap_service_file'"
      $SUDO tee "$_recluster_bootstrap_service_file" > /dev/null << EOF
[Unit]
Description=reCluster bootstrap
After=network-online.target network.target
Wants=network-online.target network.target

[Install]
WantedBy=multi-user.target

[Service]
Type=oneshot
ExecStart=$_recluster_bootstrap_sh
EOF

      INFO "systemd: Enabling reCluster bootstrap service '$_recluster_bootstrap_service_name' unit"
      $SUDO systemctl enable "$_recluster_bootstrap_service_name" > /dev/null
      $SUDO systemctl daemon-reload > /dev/null
      ;;
    *) FATAL "Unknown init system '$INIT_SYSTEM'" ;;
  esac

  spinner_stop
  # Success
  INFO "Successfully installed reCluster"
}

# Start services
start_services() {
  case $INIT_SYSTEM in
    openrc)
      INFO "openrc: Starting Node exporter"
      $SUDO rc-service node_exporter start || true
      INFO "openrc: Starting K3s"
      $SUDO rc-service k3s-recluster start
      ;;
    systemd)
      INFO "systemd: Starting Node exporter"
      $SUDO systemtc start node_exporter || true
      INFO "systemd: Starting K3s"
      $SUDO systemctl start k3s-recluster
      ;;
    *) FATAL "Unknown init system '$INIT_SYSTEM'" ;;
  esac
}

# ================
# CONFIGURATION
# ================
# Current directory
# shellcheck disable=SC1007
DIRNAME=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
# Airgap environment flag
AIRGAP_ENV=false
# Benchmark device api url
BENCH_DEVICE_API="http://bench.local/cm?cmnd=status%2010"
# Benchmark interval in seconds
BENCH_INTERVAL=1
# Benchmark time in seconds
BENCH_TIME=30
# Benchmark warmup time in seconds
BENCH_WARMUP=10
# Configuration file
CONFIG_FILE="$DIRNAME/config.yaml"
# Initialize cluster
INIT_CLUSTER=false
# K3s version
K3S_VERSION=v1.23.6+k3s1
# Log color flag
LOG_COLOR_ENABLE=true
# Log level
LOG_LEVEL=$LOG_LEVEL_INFO
# Node exporter version
NODE_EXPORTER_VERSION=v1.3.1
# reCluster etc directory
RECLUSTER_ETC_DIR=/etc/recluster
# reCluster opt directory
RECLUSTER_OPT_DIR=/opt/recluster
# Spinner flag
SPINNER_ENABLE=true
# Spinner symbols
SPINNER_SYMBOLS=$SPINNER_SYMBOLS_PROPELLER
# Node facts
NODE_FACTS="{}"

# ================
# MAIN
# ================
{
  parse_args "$@"
  verify_system
  setup_system
  read_system_info
  run_benchmarks
  install_k3s
  install_node_exporter
  cluster_init
  install_recluster
  start_services
}

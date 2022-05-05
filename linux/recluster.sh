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

# Cleanup
cleanup() {
  # Exit code
  _exit_code=$?
  # Remove temporary directory
  if [ -n "$TMP_DIR" ]; then rm -rf "$TMP_DIR"; fi
  # Reset cursor if spinner is active
  if [ -n "$SPINNER_PID" ]; then
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
  _log_level=$1
  shift
  _log_message=${*:-}
  _log_name=
  _log_prefix=
  _log_suffix="\033[0m"

  # Log level enabled
  [ "$_log_level" -gt "$LOG_LEVEL" ] && return

  case $_log_level in
    "$LOG_LEVEL_FATAL")
      _log_name=FATAL
      _log_prefix="\033[41;37m"
    ;;
    "$LOG_LEVEL_ERROR")
      _log_name=ERROR
      _log_prefix="\033[1;31m"
    ;;
    "$LOG_LEVEL_WARN")
      _log_name=WARN
      _log_prefix="\033[1;33m"
    ;;
    "$LOG_LEVEL_INFO")
      _log_name=INFO
      _log_prefix="\033[37m"
    ;;
    "$LOG_LEVEL_DEBUG")
      _log_name=DEBUG
      _log_prefix="\033[1;34m"
    ;;
  esac

  # Color disable flag
  if [ "$LOG_DISABLE_COLOR" -eq 0 ]; then
    _log_prefix=
    _log_suffix=
  fi

  # Output to stdout
  printf '%b[%-5s] %b%b\n' "$_log_prefix" "$_log_name" "$_log_message" "$_log_suffix"
}

# Fatal log message
FATAL() { _log_print_message ${LOG_LEVEL_FATAL} "$@" >&2; exit 1; }
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
  _terminate=1
  # Termination signal
  trap '_terminate=0' USR1
  # Message
  _spinner_message="${1:-"Loading..."}"

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
      # Parent PID
      _spinner_ppid=$(ps -p "$$" -o ppid=)
      if [ -n "$_spinner_ppid" ]; then
        # shellcheck disable=SC2086
        _spinner_parentup=$(ps --no-headers $_spinner_ppid)
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
  # Print message if present
  if [ -n "$1" ]; then  INFO "$1"; fi
  if [ "$SPINNER_DISABLE" -eq 0 ]; then return; fi
  if [ -n "$SPINNER_PID" ]; then FATAL "Spinner PID already defined"; fi

  # Spawn spinner process
  _spinner "$1" &
  # Spinner process id
  SPINNER_PID=$!
}

# Stop spinner
spinner_stop() {
  if [ "$SPINNER_DISABLE" -eq 0 ]; then return; fi
  if [ -z "$SPINNER_PID" ]; then FATAL "Spinner PID undefined"; fi

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
  # Log level string
  _log_level=
  case $DEFAULT_LOG_LEVEL in
    "$LOG_LEVEL_FATAL") _log_level=fatal ;;
    "$LOG_LEVEL_ERROR") _log_level=error ;;
    "$LOG_LEVEL_WARN") _log_level=warn ;;
    "$LOG_LEVEL_INFO") _log_level=info ;;
    "$LOG_LEVEL_DEBUG") _log_level=debug ;;
  esac

  cat << EOF
Usage: recluster.sh [--bench-time <TIME>] [--disable-color] [--disable-spinner]
                    [--k3s-version <VERSION>] [--help] [--log-level <LEVEL>]
                    [--spinner <SPINNER>]

reCluster installation script.

Options:
  --bench-time <TIME>        Benchmark execution time in seconds
                             Default: $DEFAULT_BENCH_TIME
                             Values:
                               Any positive number

  --disable-color            Disable color

  --disable-spinner          Disable spinner

  --k3s-version <VERSION>    K3s version
                             Default: $DEFAULT_K3S_VERSION
                             Values:
                               Any K3s version released

  --help                     Show this help message and exit

  --log-level <LEVEL>        Logger level
                             Default: $_log_level
                             Values:
                               fatal    Fatal level
                               error    Error level
                               warn     Warning level
                               info     Informational level
                               debug    Debug level

  --spinner <SPINNER>        Spinner symbols
                             Default: dots
                             Values:
                               dots         Dots spinner
                               greyscale    Greyscale spinner
                               propeller    Propeller spinner
EOF
}

# Assert command is installed
# @param $1 Command name
assert_cmd() {
  command -v "$1" >/dev/null 2>&1 || FATAL "Command '$1' not found"
  DEBUG "Command '$1' found at '$(command -v "$1")'"
}

# Assert a downloader command is installed
# @param $@ Downloader commands list
downloader_cmd() {
  # Cycle downloader commands
  for _cmd in "$@"; do
    # Check if exists
    if command -v "$_cmd" >/dev/null 2>&1; then
      # Found
      DOWNLOADER=$_cmd
      DEBUG "Downloader command '$DOWNLOADER' found at '$(command -v "$_cmd")'"
      return
    fi
  done

  # Not found
  FATAL "Unable to find any downloader command in list '$*'"
}

# Download a file
# @param $1 Output location
# @param $1 Download URL
download() {
  [ $# -eq 2 ] || FATAL "Download requires exactly 2 arguments but '$#' found"

  # Download
  case $DOWNLOADER in
    curl)
      curl --fail --silent --location --output "$1" "$2" || fatal "Download '$2' failed"
    ;;
    wget)
      wget --quiet --output-document="$1" "$2" || fatal "Download '$2' failed"
    ;;
    *)
      FATAL "Unknown downloader '$DOWNLOADER'"
    ;;
  esac
}

# Check if parameter is a number
# @param $1 Parameter
is_number() {
  if [ -z "$1" ]; then return 1; fi
  case $1 in
    ''|*[!0-9]*) return 1 ;;
    *) return 0 ;;
  esac
}

# Parse command line arguments
# @param $@ Arguments
parse_args() {
  _parse_args_assert_value() {
    if [ -z "$2" ]; then FATAL "Argument '$1' requires a non-empty value"; fi
  }
  _parse_args_invalid_value() {
    FATAL "Value '$2' of argument '$1' is invalid"
  }

  # Parse
  while [ $# -gt 0 ]; do
    case $1 in
      --bench-time)
        # Benchmark time
        _parse_args_assert_value "$@"
        if ! is_number "$2" || [ "$2" -le 0 ]; then FATAL "Value '$2' of argument '$1' is not a positive number"; fi

        _bench_time=$2
        shift
        shift
      ;;
      --disable-color)
        # Disable color
        _disable_color=0
        shift
      ;;
      --disable-spinner)
        # Disable spinner
        _disable_spinner=0
        shift
      ;;
      --help)
        # Display help message and exit
        show_help
        exit 1
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
          *) _parse_args_invalid_value "$1" "$2"
        esac
        shift
        shift
      ;;
      --node-exporter-version)
        # Node exporter version
        _parse_args_assert_value "$@"

        _node_exporter_version=$2
        shift
        shift
      ;;
      --spinner)
        _parse_args_assert_value "$@"

        case $2 in
          dots)
            _spinner=$SPINNER_SYMBOLS_DOTS
          ;;
          greyscale)
            _spinner=$SPINNER_SYMBOLS_GREYSCALE
          ;;
          propeller)
            _spinner=$SPINNER_SYMBOLS_PROPELLER
          ;;
          *) _parse_args_invalid_value "$1" "$2"
        esac
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
        WARN "Skipping argument '$1'"
        shift
      ;;
    esac
  done

  # Benchmark time in seconds
  if [ -n "$_bench_time" ]; then BENCH_TIME=$_bench_time; fi
  # Disable log color
  if [ -n "$_disable_color" ]; then LOG_DISABLE_COLOR=$_disable_color; fi
  # Disable spinner
  if [ -n "$_disable_spinner" ]; then SPINNER_DISABLE=$_disable_spinner; fi
  # K3s version
  if [ -n "$_k3s_version" ]; then K3S_VERSION=$_k3s_version; fi
  # Log level
  if [ -n "$_log_level" ]; then LOG_LEVEL=$_log_level; fi
  # Node exporter version
  if [ -n "$_node_exporter_version" ]; then NODE_EXPORTER_VERSION=$_node_exporter_version; fi
  # Spinner
  if [ -n "$_spinner" ]; then SPINNER_SYMBOLS=$_spinner; fi
}

# Read CPU information
read_cpu_info() {
  _cpu_info=$(lscpu --json \
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
                ')

  # Convert cache to bytes
  _l1d_cache=$(echo "$_cpu_info" | jq --raw-output '.cache.l1d' | sed 's/B.*//' | sed 's/[[:space:]]*//g' | numfmt --from=iec-i)
  _l1i_cache=$(echo "$_cpu_info" | jq --raw-output '.cache.l1i' | sed 's/B.*//' | sed 's/[[:space:]]*//g' | numfmt --from=iec-i)
  _l2_cache=$(echo "$_cpu_info" | jq --raw-output '.cache.l2' | sed 's/B.*//' | sed 's/[[:space:]]*//g' | numfmt --from=iec-i)
  _l3_cache=$(echo "$_cpu_info" | jq --raw-output '.cache.l3' | sed 's/B.*//' | sed 's/[[:space:]]*//g' | numfmt --from=iec-i)

  # Update cache
  _cpu_info=$(echo "$_cpu_info" \
            | jq --arg l1d "$_l1d_cache" --arg l1i "$_l1i_cache" --arg l2 "$_l2_cache" --arg l3 "$_l3_cache" '
                .cache.l1d = ($l1d | tonumber)
                | .cache.l1i = ($l1i | tonumber)
                | .cache.l2 = ($l2 | tonumber)
                | .cache.l3 = ($l3 | tonumber)
              ')

  # Update node facts
  NODE_FACTS=$(echo "$NODE_FACTS" \
              | jq --argjson cpuinfo "$_cpu_info" '.info.cpu = $cpuinfo')
}

# Read RAM information
read_ram_info() {
  _ram_info=$(lsmem --bytes --json \
              | jq '
                  .memory
                  | map(.size)
                  | add
                  | { "size": . }
                ')

  # Update node facts
  NODE_FACTS=$(echo "$NODE_FACTS" \
              | jq --argjson raminfo "$_ram_info" '.info.ram = $raminfo')
}

# Read Disk(s) information
read_disks_info() {
  _disks_info=$(lsblk --bytes --json \
              | jq '
                  .blockdevices
                  | map(select(.type == "disk"))
                  | map({name, size})
                ')

  # Update node facts
  NODE_FACTS=$(echo "$NODE_FACTS" \
              | jq --argjson disksinfo "$_disks_info" '.info.disks = $disksinfo')
}

# Read Interface(s) information
read_interfaces_info() {
  _interfaces_info=$(ip -details -json link show \
              | jq '
                  map(if .linkinfo.info_kind // .link_type == "loopback" then empty else . end)
                  | map(.name = .ifname)
                  | map({address, name})
                ')

  # Cycle interfaces to obtain additional information
  while read -r _interface; do
    _iname=$(echo "$_interface" | jq --raw-output '.name')

    # Speed
    _speed=$($SUDO ethtool "$_iname" | grep Speed | sed 's/Speed://g' | sed 's/[[:space:]]*//g' | sed 's/b.*//' | numfmt --from=si)
    # Wake on Lan
    _wol=$($SUDO ethtool "$_iname" | grep 'Supports Wake-on' | sed 's/Supports Wake-on://g' | sed 's/[[:space:]]*//g')

    # Update interfaces
    _interfaces_info=$(echo "$_interfaces_info" \
                      | jq --arg iname "$_iname" --arg speed "$_speed" --arg wol "$_wol" '
                          map(if .name == $iname then . + {"speed": $speed | tonumber, "wol": (if $wol == null or $wol == "" then null else $wol end)} else . end)
                        ')
  done << EOF
$(echo "$_interfaces_info" | jq --compact-output '.[]')
EOF

  # Update node facts
  NODE_FACTS=$(echo "$NODE_FACTS" \
              | jq --argjson interfacesinfo "$_interfaces_info" '.info.interfaces = $interfacesinfo')
}

# Execute CPU benchmark
run_cpu_bench() {
  _run_cpu_bench() {
    sysbench --time="$BENCH_TIME" --threads="$1" cpu run \
                  | grep 'events per second' \
                  | sed 's/events per second://g' \
                  | sed 's/[[:space:]]*//g' \
                  | xargs --max-args=1 printf "%.0f"
  }

  # Single-thread
  _single_thread=$(_run_cpu_bench 1)
  # Multi-thread
  _multi_thread=$(_run_cpu_bench "$(grep -c ^processor /proc/cpuinfo)")

  _cpu_bench=$(jq --null-input --arg singlethread "$_single_thread" --arg multithread "$_multi_thread" '
                  {
                    "single": ($singlethread|tonumber),
                    "multi": ($multithread|tonumber)
                  }
                ')

  # Update node facts
  NODE_FACTS=$(echo "$NODE_FACTS" \
              | jq --argjson cpubench "$_cpu_bench" '.bench.cpu = $cpubench')
}

# Execute RAM benchmark
run_ram_bench() {
  _run_ram_bench() {
    _ram_output=$(sysbench --time="$BENCH_TIME" --memory-oper="$1" --memory-access-mode="$2" memory run \
                | grep 'transferred' \
                | sed 's/.*(\(.*\))/\1/' \
                | sed 's/B.*//' \
                | sed 's/[[:space:]]*//g' \
                | numfmt --from=iec-i)
    echo $((_ram_output*8))
  }

  # Read sequential
  _read_seq=$(_run_ram_bench read seq)
  # Read random
  _read_rand=$(_run_ram_bench read rnd)

  # Write sequential
  _write_seq=$(_run_ram_bench write seq)
  # Write random
  _write_rand=$(_run_ram_bench write rnd)

  _ram_bench=$(jq --null-input \
                --arg readseq "$_read_seq" --arg readrand "$_read_rand" \
                --arg writeseq "$_write_seq" --arg writerand "$_write_rand" \
                '
                  {
                    "read": {
                      "seq": ($readseq|tonumber),
                      "rand": ($readrand|tonumber)
                    },
                    "write": {
                      "seq": ($writeseq|tonumber),
                      "rand": ($writerand|tonumber)
                    }
                  }
                ')

  # Update node facts
  NODE_FACTS=$(echo "$NODE_FACTS" \
              | jq --argjson rambench "$_ram_bench" '.bench.ram = $rambench')
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

    _io_output=$(sysbench --time="$BENCH_TIME" --file-test-mode="$2" --file-io-mode="$3" fileio run | grep "$_io_opt, ")
    _io_throughput_value=$(echo "$_io_output" | sed 's/^.*: //' | sed 's/[[:space:]]*//g')
    _io_throughput_unit=$(echo "$_io_output" | sed 's/.*,\(.*\)B\/s.*/\1/' | sed 's/[[:space:]]*//g')

    _io_throughput=$(printf "%s%s\n" "$_io_throughput_value" "$_io_throughput_unit" | numfmt --from=iec-i)
    echo $((_io_throughput*8))
  }

  # Prepare sysbench IO
  sysbench fileio cleanup > /dev/null
  sysbench fileio prepare > /dev/null

  # Read sequential synchronous
  _read_seq_sync=$(_run_io_bench read seqrd sync)
  # Read sequential asynchronous
  _read_seq_async=$(_run_io_bench read seqrd async)
  # Read sequential mmap
  _read_seq_mmap=$(_run_io_bench read seqrd mmap)

  # Read random synchronous
  _read_rand_sync=$(_run_io_bench read rndrd sync)
  # Read random asynchronous
  _read_rand_async=$(_run_io_bench read rndrd async)
  # Read random mmap
  _read_rand_mmap=$(_run_io_bench read rndrd mmap)

  # Write sequential synchronous
  _write_seq_sync=$(_run_io_bench write seqwr sync)
  # Write sequential asynchronous
  _write_seq_async=$(_run_io_bench write seqwr async)
  # Write sequential mmap
  _write_seq_mmap=$(_run_io_bench write seqwr mmap)

  # Write random synchronous
  _write_rand_sync=$(_run_io_bench write rndwr sync)
  # Write random asynchronous
  _write_rand_async=$(_run_io_bench write rndwr async)
  # Write random mmap
  _write_rand_mmap=$(_run_io_bench write rndwr mmap)

  _io_bench=$(jq --null-input \
                --arg readseqsync "$_read_seq_sync" --arg readseqasync "$_read_seq_async" --arg readseqmmap "$_read_seq_mmap" \
                --arg readrandsync "$_read_rand_sync" --arg readrandasync "$_read_rand_async" --arg readrandmmap "$_read_rand_mmap" \
                --arg writeseqsync "$_write_seq_sync" --arg writeseqasync "$_write_seq_async" --arg writeseqmmap "$_write_seq_mmap" \
                --arg writerandsync "$_write_rand_sync" --arg writerandasync "$_write_rand_async" --arg writerandmmap "$_write_rand_mmap" \
                '
                  {
                    "read": {
                      "seq": {
                        "sync": ($readseqsync|tonumber),
                        "async": ($readseqasync|tonumber),
                        "mmap": ($readseqmmap|tonumber)
                      },
                      "rand": {
                        "sync": ($readrandsync|tonumber),
                        "async": ($readrandasync|tonumber),
                        "mmap": ($readrandmmap|tonumber)
                      }
                    },
                    "write": {
                      "seq": {
                        "sync": ($writeseqsync|tonumber),
                        "async": ($writeseqasync|tonumber),
                        "mmap": ($writeseqmmap|tonumber)
                      },
                      "rand": {
                        "sync": ($writerandsync|tonumber),
                        "async": ($writerandasync|tonumber),
                        "mmap": ($writerandmmap|tonumber)
                      }
                    }
                  }
                ')

  # Update node facts
  NODE_FACTS=$(echo "$NODE_FACTS" \
              | jq --argjson iobench "$_io_bench" '.bench.io = $iobench')
}

################################################################################################################################

# Verify system
verify_system() {
  # Commands
  assert_cmd "cp"
  assert_cmd "env"
  assert_cmd "ethtool"
  assert_cmd "grep"
  assert_cmd "ip"
  assert_cmd "jq"
  assert_cmd "lscpu"
  assert_cmd "lsmem"
  assert_cmd "lsblk"
  assert_cmd "mktemp"
  assert_cmd "numfmt"
  assert_cmd "ps"
  assert_cmd "read"
  assert_cmd "sed"
  assert_cmd "sudo"
  assert_cmd "sysbench"
  assert_cmd "tar"
  assert_cmd "tput"
  assert_cmd "uname"
  assert_cmd "xargs"

  # Downloader command
  downloader_cmd "curl" "wget"

  # Sudo
  if [ "$(id -u)" -eq 0 ]; then
    INFO "Already running as 'root'"
    SUDO=
  else
    INFO "Requesting 'root' privileges"
    SUDO=sudo
    $SUDO --reset-timestamp
    $SUDO true || FATAL "Failed to obtain 'root' privileges"
  fi
}

# Setup system
setup_system() {
  TMP_DIR=$(mktemp --directory -t recluster.XXXXXXXX)
  DEBUG "Temporary directory '$TMP_DIR'"
}

# Install K3s
install_k3s() {
  _k3s_installer="$TMP_DIR/k3s.installer.sh"

  # Download installer
  spinner_start "Downloading K3s installer"
  download "$_k3s_installer" https://get.k3s.io
  chmod 755 "$_k3s_installer"
  spinner_stop

  # Install
  spinner_start "Installing K3s $K3S_VERSION"
  env \
    INSTALL_K3S_SKIP_START=true \
    INSTALL_K3S_VERSION="$K3S_VERSION" \
    "$_k3s_installer" || FATAL "Error installing K3s $K3S_VERSION"
  spinner_stop

  # Success
  INFO "Successfully installed K3s $K3S_VERSION"
}

# Install Node exporter
install_node_exporter() {
  _node_exporter_installer="$TMP_DIR/node_exporter.installer.sh"

  # Download installer
  spinner_start "Downloading Node exporter installer"
  download "$_node_exporter_installer" https://raw.githubusercontent.com/carlocorradini/node_exporter_installer/main/install.sh
  chmod 755 "$_node_exporter_installer"
  spinner_stop

  # Install
  spinner_start "Installing Node exporter $NODE_EXPORTER_VERSION"
  env \
    INSTALL_NODE_EXPORTER_SKIP_START=true \
    INSTALL_NODE_EXPORTER_VERSION="$NODE_EXPORTER_VERSION" \
    "$_node_exporter_installer" || FATAL "Error installing Node exporter $NODE_EXPORTER_VERSION"
  spinner_stop

  # Success
  INFO "Successfully installed Node exporter $NODE_EXPORTER_VERSION"
}

# Read system information
read_system_info() {
  spinner_start "System Info"

  # CPU info
  read_cpu_info
  DEBUG "CPU info:\n$(echo "$NODE_FACTS" | jq .info.cpu)"
  INFO "CPU is '$(echo "$NODE_FACTS" | jq --raw-output .info.cpu.name)'"

  # RAM info
  read_ram_info
  DEBUG "RAM info:\n$(echo "$NODE_FACTS" | jq .info.ram)"
  INFO "RAM is '$(echo "$NODE_FACTS" | jq --raw-output .info.ram.size | numfmt --to=iec-i)B'"

  # Disk(s) info
  read_disks_info
  DEBUG "Disk(s) info:\n$(echo "$NODE_FACTS" | jq .info.disks)"
  _disks_info="Disk(s) found $(echo "$NODE_FACTS" | jq --raw-output '.info.disks | length'):"
  while read -r _disk_info; do
    _disks_info="$_disks_info\n\t'$(echo "$_disk_info" | jq --raw-output .name)' of '$(echo "$_disk_info" | jq --raw-output .size | numfmt --to=iec-i)B'"
  done << EOF
$(echo "$NODE_FACTS" | jq --compact-output '.info.disks[]')
EOF
  INFO "$_disks_info"

  # Interface(s) info
  read_interfaces_info
  DEBUG "Interface(s) info:\n$(echo "$NODE_FACTS" | jq .info.interfaces)"
  INFO "Interface(s) found $(echo "$NODE_FACTS" | jq --raw-output '.info.interfaces | length'):
    $(echo "$NODE_FACTS" | jq --raw-output '.info.interfaces[] | "\t'\''\(.name)'\'' at '\''\(.address)'\''"')"

  spinner_stop
}

# Execute benchmarks
run_benchmarks() {
  # CPU bench
  spinner_start "CPU benchmarks"
  run_cpu_bench
  spinner_stop
  DEBUG "CPU bench:\n$(echo "$NODE_FACTS" | jq .bench.cpu)"
  INFO "CPU bench:
    \tSingle-thread '$(echo "$NODE_FACTS" | jq --raw-output .bench.cpu.single)events/s'
    \tMulti-thread '$(echo "$NODE_FACTS" | jq --raw-output .bench.cpu.multi)events/s'"

  # RAM bench
  spinner_start "RAM benchmarks"
  run_ram_bench
  spinner_stop
  DEBUG "RAM bench:\n$(echo "$NODE_FACTS" | jq .bench.ram)"
  INFO "RAM bench:
    \tRead Sequential '$(echo "$NODE_FACTS" | jq --raw-output .bench.ram.read.seq | numfmt --to=si)b/s'
    \tRead Random '$(echo "$NODE_FACTS" | jq --raw-output .bench.ram.read.rand | numfmt --to=si)b/s'
    \tWrite Sequential '$(echo "$NODE_FACTS" | jq --raw-output .bench.ram.write.seq | numfmt --to=si)b/s'
    \tWrite Random '$(echo "$NODE_FACTS" | jq --raw-output .bench.ram.write.rand | numfmt --to=si)b/s'"

  # IO bench
  spinner_start "IO benchmarks"
  run_io_bench
  spinner_stop
  DEBUG "IO bench:\n$(echo "$NODE_FACTS" | jq .bench.io)"
  INFO "IO bench:
    \tRead Sequential Sync '$(echo "$NODE_FACTS" | jq --raw-output .bench.io.read.seq.sync | numfmt --to=si)b/s'
    \tRead Sequential Async '$(echo "$NODE_FACTS" | jq --raw-output .bench.io.read.seq.async | numfmt --to=si)b/s'
    \tRead Sequential Mmap '$(echo "$NODE_FACTS" | jq --raw-output .bench.io.read.seq.mmap | numfmt --to=si)b/s'
    \tRead Random Sync '$(echo "$NODE_FACTS" | jq --raw-output .bench.io.read.rand.sync | numfmt --to=si)b/s'
    \tRead Random Async '$(echo "$NODE_FACTS" | jq --raw-output .bench.io.read.rand.async | numfmt --to=si)b/s'
    \tRead Random Mmap '$(echo "$NODE_FACTS" | jq --raw-output .bench.io.read.rand.mmap | numfmt --to=si)b/s'
    \tWrite Sequential Sync '$(echo "$NODE_FACTS" | jq --raw-output .bench.io.write.seq.sync | numfmt --to=si)b/s'
    \tWrite Sequential Async '$(echo "$NODE_FACTS" | jq --raw-output .bench.io.write.seq.async | numfmt --to=si)b/s'
    \tWrite Sequential Mmap '$(echo "$NODE_FACTS" | jq --raw-output .bench.io.write.seq.mmap | numfmt --to=si)b/s'
    \tWrite Random Sync '$(echo "$NODE_FACTS" | jq --raw-output .bench.io.write.rand.sync | numfmt --to=si)b/s'
    \tWrite Random Async '$(echo "$NODE_FACTS" | jq --raw-output .bench.io.write.rand.async | numfmt --to=si)b/s'
    \tWrite Random Mmap '$(echo "$NODE_FACTS" | jq --raw-output .bench.io.write.rand.mmap | numfmt --to=si)b/s'"
}

# ================
# CONFIGURATION
# ================
# Benchmark time in seconds
BENCH_TIME=16
# K3s version
K3S_VERSION=v1.23.6+k3s1
# Log disable color flag
LOG_DISABLE_COLOR=1
# Log level
LOG_LEVEL=$LOG_LEVEL_INFO
# Node exporter version
NODE_EXPORTER_VERSION=v1.3.1
# Spinner disable flag
SPINNER_DISABLE=1
# Spinner symbols
SPINNER_SYMBOLS=$SPINNER_SYMBOLS_DOTS
# Node facts
NODE_FACTS={}

# ================
# MAIN
# ================
{
  parse_args "$@"
  verify_system
  setup_system
  #install_k3s
  #install_node_exporter
  read_system_info
  run_benchmarks
}

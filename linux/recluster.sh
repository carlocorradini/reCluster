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

# ================
# GLOBALS
# ================
# Node facts
NODE_FACTS=
# Installation stage
INSTALLATION_STAGE=
# Log level
LOG_LEVEL=
# reCluster directory
RECLUSTER_DIR=

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
log_print_message() {
  _log_level=$1
  shift
  _log_message=${*:-}
  _log_name=""
  _log_prefix=""
  _log_suffix="\e[0m"

  # Check log level is enabled
  if [ "$_log_level" -gt "$LOG_LEVEL" ]; then
    return
  fi

  case $_log_level in
    "$LOG_LEVEL_FATAL")
      _log_name="FATAL"
      _log_prefix="\e[41;37m"
    ;;
    "$LOG_LEVEL_ERROR")
      _log_name="ERROR"
      _log_prefix="\e[1;31m"
    ;;
    "$LOG_LEVEL_WARN")
      _log_name="WARN"
      _log_prefix="\e[1;33m"
    ;;
    "$LOG_LEVEL_INFO")
      _log_name="INFO"
      _log_prefix="\e[37m"
    ;;
    "$LOG_LEVEL_DEBUG")
      _log_name="DEBUG"
      _log_prefix="\e[1;34m"
    ;;
  esac

  # Output to stdout
  printf '%b[%-5s] %b%b\n' "$_log_prefix" "$_log_name" "$_log_message" "$_log_suffix"

  # Exit if fatal
  if [ "$_log_level" -eq "${LOG_LEVEL_FATAL}" ]; then
      exit 1
  fi
}

# Fatal log message
FATAL() { log_print_message ${LOG_LEVEL_FATAL} "$@"; }
# Error log message
ERROR() { log_print_message ${LOG_LEVEL_ERROR} "$@"; }
# Warning log message
WARN() { log_print_message ${LOG_LEVEL_WARN} "$@"; }
# Informational log message
INFO() { log_print_message ${LOG_LEVEL_INFO} "$@"; }
# Debug log message
DEBUG() { log_print_message ${LOG_LEVEL_DEBUG} "$@"; }

# ================
# FUNCTIONS
# ================
# Show help message
show_help() {
cat << EOF
Usage: recluster.sh [--help] [--log-level <LEVEL>] --stage <STAGE>

reCluster installation script.

Options:
  --help                Show this help message and exit

  --log-level <LEVEL>   Logger level
                        Default: info
                        Values:
                          fatal    Fatal
                          error    Error
                          warn     Warning
                          info     Informational
                          debug    Debug

  --stage <STAGE>       Specify installation stage
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

# Parse command line arguments
# @param $# Arguments
parse_args() {
  # Parse
  while [ $# -gt 0 ]; do
    case $1 in
      --help)
        # Display help message and exit
        show_help
        exit 1
      ;;
      --log-level)
        # Log level
        if [ -z "${2+x}" ]; then FATAL "Argument '--log-level' requires a non-empty value"; fi
        case $2 in
          fatal) LOG_LEVEL=$LOG_LEVEL_FATAL ;;
          error) LOG_LEVEL=$LOG_LEVEL_ERROR ;;
          warn) LOG_LEVEL=$LOG_LEVEL_WARN ;;
          info) LOG_LEVEL=$LOG_LEVEL_INFO ;;
          debug) LOG_LEVEL=$LOG_LEVEL_DEBUG ;;
          *) FATAL "Value '$2' of argument '--log-level' is invalid" ;;
        esac

        shift
        shift
      ;;
      --stage)
        # Installation stage
        if [ -z "${2+x}" ]; then FATAL "Argument '--stage' requires a non-empty value"; fi
        case $2 in
          0) ;;
          *) FATAL "Value '$2' of argument '--stage' is invalid"
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

# Read CPU info
read_cpu_info() {
  _cpu_info="$(lscpu --json \
              | jq --compact-output --sort-keys '
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
                '
  )"

  # Convert cache to bytes
  _l1d_cache="$(echo "$_cpu_info" | jq --raw-output '.cache.l1d' | sed 's/B.*//' | sed 's/[[:space:]]*//g' | numfmt --from=iec-i)"
  _l1i_cache="$(echo "$_cpu_info" | jq --raw-output '.cache.l1i' | sed 's/B.*//' | sed 's/[[:space:]]*//g' | numfmt --from=iec-i)"
  _l2_cache="$(echo "$_cpu_info" | jq --raw-output '.cache.l2' | sed 's/B.*//' | sed 's/[[:space:]]*//g' | numfmt --from=iec-i)"
  _l3_cache="$(echo "$_cpu_info" | jq --raw-output '.cache.l3' | sed 's/B.*//' | sed 's/[[:space:]]*//g' | numfmt --from=iec-i)"

  # Update cache
  _cpu_info="$(echo "$_cpu_info" \
            | jq --compact-output --sort-keys --arg l1d "$_l1d_cache" --arg l1i "$_l1i_cache" --arg l2 "$_l2_cache" --arg l3 "$_l3_cache" '
                .cache.l1d = ($l1d | tonumber)
                | .cache.l1i = ($l1i | tonumber)
                | .cache.l2 = ($l2 | tonumber)
                | .cache.l3 = ($l3 | tonumber)
            '
  )"

  # Update node facts
  NODE_FACTS="$(echo "$NODE_FACTS" \
              | jq --compact-output --sort-keys --argjson cpuinfo "$_cpu_info" '
                  .cpu += $cpuinfo
                '
  )"
}

# Read RAM info
read_ram_info() {
  _ram_info="$(lsmem --bytes --json \
              | jq --compact-output --sort-keys '
                  .memory
                  | map(.size)
                  | add
                  | { "size": . }
                '
  )"
  # Update node facts
  NODE_FACTS="$(echo "$NODE_FACTS" \
              | jq --compact-output --sort-keys --argjson raminfo "$_ram_info" '
                  .ram += $raminfo
                '
  )"
}

# Read Disk(s) info
read_disks_info() {
  _disks_info="$(lsblk --bytes --json \
              | jq --compact-output --sort-keys '
                  .blockdevices
                  | map(select(.type == "disk"))
                  | map({name, size})
                '
  )"

  # Update node facts
  NODE_FACTS="$(echo "$NODE_FACTS" \
              | jq --compact-output --sort-keys --argjson disksinfo "$_disks_info" '
                  .disks += $disksinfo
                '
  )"
}

# Read Interface(s) info
read_interfaces_info() {
  _interfaces_info="$(ip -details -json link show \
              | jq --compact-output --sort-keys '
                  map(if .linkinfo.info_kind // .link_type == "loopback" then empty else . end)
                  | map(.name = .ifname)
                  | map({address, name})
                '
  )"

  # Cycle interface to obtain additional information
  while read -r _interface; do
    _iname="$(echo "$_interface" | jq --raw-output '.name')"
    # Speed
    _speed="$(ethtool "$_iname" | grep Speed | sed 's/Speed://g' | sed 's/^[[:space:]]*//g' | sed 's/b.*//' | numfmt --from=si)"
    # Wake on Lan
    _wol="$(ethtool "$_iname" | grep 'Supports Wake-on' | sed 's/Supports Wake-on://g' | sed 's/[[:space:]]*//g')"
    # Update interfaces
    _interfaces_info="$(echo "$_interfaces_info" \
                      | jq --compact-output --sort-keys --arg iname "$_iname" --arg speed "$_speed" --arg wol "$_wol" '
                          map(if .name == $iname then . + {"speed": $speed | tonumber, "wol": (if $wol == null or $wol == "" then null else $wol end)} else . end)
                        '
    )"
  done << EOF
$(echo "$_interfaces_info" | jq --compact-output '.[]')
EOF

  # Update node facts
  NODE_FACTS="$(echo "$NODE_FACTS" \
              | jq --compact-output --sort-keys --argjson interfacesinfo "$_interfaces_info" '
                  .interfaces += $interfacesinfo
                '
  )"
}

################################################################################################################################

# === CONFIGURATION ===
# Log level
LOG_LEVEL=$LOG_LEVEL_INFO
# Node facts
NODE_FACTS="$(cat << 'EOF'
{
  "cpu": {},
  "ram": {},
  "disks": [],
  "interfaces": []
}
EOF
)"
# reCluster directory
RECLUSTER_DIR="/etc/recluster"

# === ARGUMENTS ===
parse_args "$@"

# === ASSERT ===
if [ "$(id -u)" -ne 0 ]; then FATAL "Run as 'root' for administrative rights"; fi
assert_cmd "ethtool"
assert_cmd "grep"
assert_cmd "ip"
assert_cmd "jq"
assert_cmd "lscpu"
assert_cmd "lsmem"
assert_cmd "lsblk"
assert_cmd "numfmt"
assert_cmd "sed"

# === MAIN ===
case $INSTALLATION_STAGE in
  0)
    # reCluster directory
    if [ -d "$RECLUSTER_DIR" ]; then FATAL "reCluster directory '$RECLUSTER_DIR' already exists"; fi
    INFO "Creating reCluster directory '$RECLUSTER_DIR'"
    mkdir -p "$RECLUSTER_DIR"

    # CPU info
    read_cpu_info
    DEBUG "CPU info:\n $(echo "$NODE_FACTS" | jq .cpu)"
    INFO "CPU is '$(echo "$NODE_FACTS" | jq --raw-output .cpu.name)'"

    # RAM info
    read_ram_info
    DEBUG "RAM info:\n $(echo "$NODE_FACTS" | jq .ram)"
    INFO "RAM is '$(echo "$NODE_FACTS" | jq --raw-output .ram.size)' Bytes"

    # Disk(s) info
    read_disks_info
    DEBUG "Disk(s) info:\n $(echo "$NODE_FACTS" | jq .disks)"
    INFO "Disk(s) found $(echo "$NODE_FACTS" | jq --raw-output '.disks | length'):\n $(echo "$NODE_FACTS" | jq --raw-output '.disks[] | "\t'\''\(.name)'\'' of '\''\(.size)'\'' Bytes"')"

    # Interface(s) info
    read_interfaces_info
    DEBUG "Interface(s) info:\n $(echo "$NODE_FACTS" | jq .interfaces)"
    INFO "Interface(s) found $(echo "$NODE_FACTS" | jq --raw-output '.interfaces | length'):\n $(echo "$NODE_FACTS" | jq --raw-output '.interfaces[] | "\t'\''\(.name)'\'' at '\''\(.address)'\''"')"
  ;;
esac

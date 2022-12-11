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

# Current directory
# shellcheck disable=SC1007
DIRNAME=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

# Load commons
# shellcheck source=scripts/__commons.sh
. "$DIRNAME/scripts/__commons.sh"

# ================
# CONFIGURATION
# ================
# Airgap environment flag
AIRGAP_ENV=false
# Autoscaler version
AUTOSCALER_VERSION=latest
# Benchmark time in seconds
BENCH_TIME=30
# Configuration file
CONFIG_FILE="configs/recluster/config.yaml"
# Initialize cluster
INIT_CLUSTER=false
# K3s configuration file
K3S_CONFIG_FILE="configs/k3s/config.yaml"
# K3s registry configuration file
K3S_REGISTRY_CONFIG_FILE="configs/k3s/registries.yaml"
# K3s version
K3S_VERSION=latest
# Node exporter configuration file
NODE_EXPORTER_CONFIG_FILE="configs/node_exporter/config.yaml"
# Node exporter version
NODE_EXPORTER_VERSION=latest
# Power consumption device api url
PC_DEVICE_API="http://pc.recluster.local/cm?cmnd=status%2010"
# Power consumption interval in seconds
PC_INTERVAL=1
# Power consumption time in seconds
PC_TIME=30
# Power consumption warmup time in seconds
PC_WARMUP=10
# reCluster etc directory
RECLUSTER_ETC_DIR="/etc/recluster"
# reCluster opt directory
RECLUSTER_OPT_DIR="/opt/recluster"
# reCluster certificates directory
RECLUSTER_CERTS_DIR="configs/certs"
# reCluster server environment file
RECLUSTER_SERVER_ENV_FILE="configs/recluster/server.env"
# SSH authorized keys file
SSH_AUTHORIZED_KEYS_FILE="configs/ssh/authorized_keys"
# SSH configuration file
SSH_CONFIG_FILE="configs/ssh/ssh_config"
# SSH server configuration file
SSHD_CONFIG_FILE="configs/ssh/sshd_config"
# User
USER="root"

# ================
# GLOBALS
# ================
# Autoscaler directory
AUTOSCALER_DIR=
# Configuration
CONFIG=
# K3s configuration
K3S_CONFIG=
# Node exporter configuration
NODE_EXPORTER_CONFIG=
# Node facts
NODE_FACTS='{}'
# Temporary directory
TMP_DIR=

# ================
# CLEANUP
# ================
cleanup() {
  # Exit code
  _exit_code=$?
  [ $_exit_code = 0 ] || WARN "Cleanup exit code $_exit_code"

  # Cleanup temporary directory
  cleanup_dir "$TMP_DIR"
  # Cleanup spinner
  cleanup_spinner

  exit "$_exit_code"
}

# Trap
trap cleanup INT QUIT TERM EXIT

# ================
# FUNCTIONS
# ================
# Show help message
show_help() {
  cat << EOF
Usage: $(basename "$0") [--airgap] [--autoscaler-version <VERSION>] [--bench-time <TIME>] [--certs-dir <DIR>] [--config-file <FILE>]
        [--help] [--init-cluster] [--k3s-config-file <FILE>] [--k3s-registry-config-file <FILE>] [--k3s-version <VERSION>]
        [--node-exporter-config-file <FILE>] [--node-exporter-version <VERSION>]
        [--pc-device-api <URL>] [--pc-interval <TIME>] [--pc-time <TIME>] [--pc-warmup <TIME>]
        [--server-env-file <FILE>] [--ssh-authorized-keys-file <FILE>] [--ssh-config-file <FILE>] [--sshd-config-file <FILE>] [--user <USER>]

$HELP_COMMONS_USAGE

reCluster installation script.

Options:
  --airgap                            Perform installation in Air-Gap environment

  --autoscaler-version <VERSION>      Autoscaler version
                                      Default: $AUTOSCALER_VERSION
                                      Values:
                                        Any Autoscaler version

  --bench-time <TIME>                 Benchmark execution time in seconds
                                      Default: $BENCH_TIME
                                      Values:
                                        Any positive number

  --certs-dir <DIR>                   Server certificates directory
                                      Default: $RECLUSTER_CERTS_DIR
                                      Values:
                                        Any valid directory

  --config-file <FILE>                Configuration file
                                      Default: $CONFIG_FILE
                                      Values:
                                        Any valid file

  --help                              Show this help message and exit

  --init-cluster                      Initialize cluster components and logic
                                        Enable only when bootstrapping for the first time

  --k3s-config-file <FILE>            K3s configuration file
                                      Default: $K3S_CONFIG_FILE
                                      Values:
                                        Any valid file

  --k3s-registry-config-file <FILE>   K3s registry configuration file
                                      Default: $K3S_REGISTRY_CONFIG_FILE
                                      Values:
                                        Any valid file

  --k3s-version <VERSION>             K3s version
                                      Default: $K3S_VERSION
                                      Values:
                                        Any K3s version

  --node-exporter-config-file <FILE>  Node exporter configuration file
                                      Default: $NODE_EXPORTER_CONFIG_FILE
                                      Values:
                                        Any valid file

  --node-exporter-version <VERSION>   Node exporter version
                                      Default: $NODE_EXPORTER_VERSION
                                      Values:
                                        Any Node exporter version

  --pc-device-api <URL>               Power consumption device api URL
                                      Default: $PC_DEVICE_API
                                      Values:
                                        Any valid URL

  --pc-interval <TIME>                Power consumption read interval time in seconds
                                      Default: $PC_INTERVAL
                                      Values:
                                        Any positive number

  --pc-time <TIME>                    Power consumption execution time in seconds
                                      Default: $PC_TIME
                                      Values:
                                        Any positive number

  --pc-warmup <TIME>                  Power consumption warmup time in seconds
                                      Default: $PC_WARMUP
                                      Values:
                                        Any positive number

  --server-env-file <FILE>            Server environment file
                                      Default: $RECLUSTER_SERVER_ENV_FILE
                                      Values:
                                        Any valid file

  --ssh-authorized-keys-file <FILE>   SSH authorized keys file
                                      Default: $SSH_AUTHORIZED_KEYS_FILE
                                      Values:
                                        Any valid file

  --ssh-config-file <FILE>            SSH configuration file
                                      Default: $SSH_CONFIG_FILE
                                      Values:
                                        Any valid file

  --sshd-config-file <FILE>           SSH server configuration file
                                      Default: $SSHD_CONFIG_FILE
                                      Values:
                                        Any valid file

  --user <USER>                       User
                                      Default: $USER
                                      Values:
                                        Any valid user

$HELP_COMMONS_OPTIONS
EOF
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

# Assert timezone
assert_timezone() {
  _timezone_file="/etc/timezone"
  _timezone="Etc/UTC"

  [ -f "$_timezone_file" ] || FATAL "Timezone file '$_timezone_file' not found"
  _current_timezone=$(cat $_timezone_file)
  [ "$_current_timezone" = "$_timezone" ] || FATAL "Timezone is not '$_timezone' but '$_current_timezone'"
}

# Assert user
assert_user() {
  id "$USER" > /dev/null 2>&1 || FATAL "User '$USER' does not exists"
}

# Home directory of user
user_home_dir() {
  _home_dir=

  case $USER in
    root) _home_dir="/root" ;;
    *) _home_dir="/home/$USER" ;;
  esac

  printf '%s\n' "$_home_dir"
}

# Create uninstall
create_uninstall() {
  _uninstall_script_file="/usr/local/bin/recluster.uninstall.sh"

  INFO "Creating uninstall script '$_uninstall_script_file'"
  $SUDO tee "$_uninstall_script_file" > /dev/null << EOF
#!/usr/bin/env sh

[ \$(id -u) -eq 0 ] || exec sudo \$0 \$@

[ -s '/etc/systemd/system/recluster.service' ] && systemctl stop recluster.service
[ -x '/etc/init.d/recluster' ] && /etc/init.d/recluster stop

[ -x '/usr/local/bin/k3s-recluster-uninstall.sh' ] && k3s-recluster-uninstall.sh
[ -x '/usr/local/bin/node_exporter.uninstall.sh' ] && node_exporter.uninstall.sh

if command -v systemctl; then
  systemctl disable recluster.server
  systemctl disable recluster
  systemctl reset-failed recluster.server
  systemctl reset-failed recluster
  systemctl daemon-reload
fi
if command -v rc-update; then
  rc-update delete recluster.server default
  rc-update delete recluster default
fi

rm -f /etc/systemd/system/recluster.server.service
rm -f /etc/init.d/recluster.server
rm -f /var/log/recluster.server.log

rm -f /etc/systemd/system/recluster.service
rm -f /etc/init.d/recluster
rm -f /var/log/recluster.log

# Certificates
rm -f /usr/local/share/ca-certificates/registry.crt
rm -f /usr/local/share/ca-certificates/registry.key
update-ca-certificates

rm -rf "$RECLUSTER_ETC_DIR"
rm -rf "$RECLUSTER_OPT_DIR"

remove_uninstall() {
  rm -f "$_uninstall_script_file"
}
trap remove_uninstall EXIT
EOF

  $SUDO chown root:root "$_uninstall_script_file"
  $SUDO chmod 754 "$_uninstall_script_file"
}

# Setup SSH
setup_ssh() {
  _ssh_config_file="/etc/ssh/ssh_config"
  _ssh_config_dir=$(dirname "$_ssh_config_file")
  _sshd_config_file="/etc/ssh/sshd_config"
  _sshd_config_dir=$(dirname "$_sshd_config_file")
  _ssh_authorized_keys_file="$(user_home_dir)/.ssh/authorized_keys"
  _ssh_authorized_keys_dir=$(dirname "$_ssh_authorized_keys_file")

  spinner_start "Setting up SSH"

  # SSH configuration
  INFO "Copying SSH configuration file from '$SSH_CONFIG_FILE' to '$_ssh_config_file'"
  [ -d "$_ssh_config_dir" ] || {
    WARN "Creating SSH configuration directory '$_ssh_config_dir'"
    $SUDO mkdir -p "$_ssh_config_dir"
    $SUDO chown root:root "$_ssh_config_dir"
    $SUDO chmod 755 "$_ssh_config_dir"
  }
  yes | $SUDO cp --force "$SSH_CONFIG_FILE" "$_ssh_config_file"
  $SUDO chown root:root "$_ssh_config_file"
  $SUDO chmod 644 "$_ssh_config_file"

  # SSH server configuration
  INFO "Copying SSH server configuration file from '$SSHD_CONFIG_FILE' to '$_sshd_config_file'"
  [ -d "$_sshd_config_dir" ] || {
    WARN "Creating SSH server configuration directory '$_sshd_config_dir'"
    $SUDO mkdir -p "$_sshd_config_dir"
    $SUDO chown root:root "$_sshd_config_dir"
    $SUDO chmod 755 "$_sshd_config_dir"
  }
  yes | $SUDO cp --force "$SSHD_CONFIG_FILE" "$_sshd_config_file"
  $SUDO chown root:root "$_sshd_config_file"
  $SUDO chmod 644 "$_sshd_config_file"

  # SSH authorized keys
  [ -d "$_ssh_authorized_keys_dir" ] || {
    WARN "Creating SSH authorized keys directory '$_ssh_authorized_keys_dir'"
    $SUDO mkdir -p "$_ssh_authorized_keys_dir"
    $SUDO chown "$USER:$USER" "$_ssh_authorized_keys_dir"
    $SUDO chmod 700 "$_ssh_authorized_keys_dir"
  }
  while read -r _ssh_authorized_key; do
    INFO "Copying SSH authorized key '$_ssh_authorized_key' to SSH authorized keys '$_ssh_authorized_keys_file'"
    printf "%s\n" "$_ssh_authorized_key" | $SUDO tee -a "$_ssh_authorized_keys_file" > /dev/null || FATAL "Error copying SSH authorized key '$_ssh_authorized_key' to SSH authorized keys '$_ssh_authorized_keys_file'"
  done << EOF
$(cat "$SSH_AUTHORIZED_KEYS_FILE")
EOF
  $SUDO chown "$USER:$USER" "$_ssh_authorized_keys_file"
  $SUDO chmod 644 "$_ssh_authorized_keys_file"

  # Restart SSH service
  case $INIT_SYSTEM in
    openrc)
      INFO "openrc: Restarting SSH"
      $SUDO rc-service sshd restart
      ;;
    systemd)
      INFO "systemd: Restarting SSH"
      $SUDO systemctl restart ssh
      ;;
    *) FATAL "Unknown init system '$INIT_SYSTEM'" ;;
  esac

  spinner_stop
}

# Setup certificates
setup_certificates() {
  _certs_dir="$RECLUSTER_ETC_DIR/certs"
  _ssh_crt_src="$DIRNAME/configs/certs/ssh.crt"
  _ssh_crt_dst="$_certs_dir/ssh.crt"
  _ssh_key_src="$DIRNAME/configs/certs/ssh.key"
  _ssh_key_dst="$_certs_dir/ssh.key"
  _token_crt_src="$DIRNAME/configs/certs/token.crt"
  _token_crt_dst="$_certs_dir/token.crt"
  _token_key_src="$DIRNAME/configs/certs/token.key"
  _token_key_dst="$_certs_dir/token.key"
  _registry_crt_src="$DIRNAME/configs/certs/registry.crt"
  _registry_crt_dst="/usr/local/share/ca-certificates/registry.crt"
  _registry_key_src="$DIRNAME/configs/certs/registry.key"
  _registry_key_dst="/usr/local/share/ca-certificates/registry.key"

  spinner_start "Setting up certificates"

  [ -f "$_ssh_crt_src" ] || FATAL "SSH certificate file '$_ssh_crt_src' does not exists"
  [ -f "$_ssh_key_src" ] || FATAL "SSH certificate file '$_ssh_key_src' does not exists"
  [ -f "$_token_crt_src" ] || FATAL "Token certificate file '$_token_crt_src' does not exists"
  [ -f "$_token_key_src" ] || FATAL "Token certificate file '$_token_key_src' does not exists"
  [ -f "$_registry_crt_src" ] || FATAL "Registry certificate file '$_registry_crt_src' does not exists"
  [ -f "$_registry_key_src" ] || FATAL "Registry certificate file '$_registry_key_src' does not exists"

  DEBUG "Creating reCluster certificates directory '$_certs_dir'"
  $SUDO rm -rf "$_certs_dir"
  $SUDO mkdir "$_certs_dir"

  DEBUG "Copying SSH certificate file '$_ssh_crt_src' to '$_ssh_crt_dst'"
  yes | $SUDO cp --force "$_ssh_crt_src" "$_ssh_crt_dst"
  DEBUG "Copying SSH certificate file '$_ssh_key_src' to '$_ssh_key_dst'"
  yes | $SUDO cp --force "$_ssh_key_src" "$_ssh_key_dst"
  DEBUG "Copying Token certificate file '$_token_crt_src' to '$_token_crt_dst'"
  yes | $SUDO cp --force "$_token_crt_src" "$_token_crt_dst"
  DEBUG "Copying Token certificate file '$_token_key_src' to '$_token_key_dst'"
  yes | $SUDO cp --force "$_token_key_src" "$_token_key_dst"
  DEBUG "Copying Registry certificate file '$_registry_crt_src' to '$_registry_crt_dst'"
  yes | $SUDO cp --force "$_registry_crt_src" "$_registry_crt_dst"
  DEBUG "Copying Registry certificate file '$_registry_key_src' to '$_registry_key_dst'"
  yes | $SUDO cp --force "$_registry_key_src" "$_registry_key_dst"

  INFO "Updating reCluster certificates directory '$_certs_dir' permissions"
  $SUDO chown --recursive root:root "$_certs_dir"
  $SUDO chmod --recursive 600 "$_certs_dir"
  INFO "Updating CA certificates"
  $SUDO update-ca-certificates

  spinner_stop
}

# Read interfaces
read_interfaces() {
  ip -details -json link show \
    | jq \
      '
          map(if .linkinfo.info_kind // .link_type == "loopback" then empty else . end)
          | map(.name = .ifname)
          | map({address, name})
        '
}

# Read power consumption
# @param $1 Benchmark PID
read_power_consumption() {
  _read_power_consumption() {
    download_print "$PC_DEVICE_API" | jq --raw-output '.StatusSNS.ENERGY.Power'
  }
  _pid=$1
  _pcs='[]'
  # Standard deviation max tolerance inclusive
  _standard_deviation_tolerance=5

  # Warmup
  sleep "$PC_WARMUP"

  # Execute
  _end=$(date -ud "$PC_TIME second" +%s)
  while [ "$(date -u +%s)" -le "$_end" ]; do
    # Current power consumption
    _pc=$(_read_power_consumption)
    DEBUG "Reading power consumption: ${_pc}W"
    # Add current power consumption to list
    _pcs=$(printf '%s\n' "$_pcs" | jq --arg pc "$_pc" '. |= . + [$pc | tonumber]')
    # Sleep
    sleep "$PC_INTERVAL"
  done

  # Terminate benchmark process
  if [ -n "$_pid" ]; then
    DEBUG "Terminating benchmark process PID $_pid"
    kill -s HUP "$_pid"
    # Wait may fail
    wait "$_pid" || :
  fi

  # Check pcs
  [ "$(printf '%s\n' "$_pcs" | jq --raw-output 'length')" -ge 2 ] || FATAL "Power consumption readings not enough data"
  [ "$(printf '%s\n' "$_pcs" | jq --raw-output 'add')" -ge 1 ] || FATAL "Power consumption readings are below 1W"

  # Calculate mean
  _mean=$(
    printf '%s\n' "$_pcs" \
      | jq \
        --raw-output \
        '
          add / length
          | . + 0.5
          | floor
        '
  )
  [ "$_mean" -ge 1 ] || FATAL "Power consumption mean is below 1W"
  DEBUG "Power consumption mean: $_mean"

  # Calculate standard deviation
  _standard_deviation=$(
    printf '%s\n' "$_pcs" \
      | jq \
        --raw-output \
        '
          (add / length) as $mean
          | (map(. - $mean | . * .) | add) / (length - 1)
          | sqrt
        '
  )
  [ "$(printf '%s <= %s' "${_standard_deviation#-}" "$_standard_deviation_tolerance" | bc)" -eq 1 ] || FATAL "Power consumption standard deviation $_standard_deviation exceeds tolerance $_standard_deviation_tolerance"
  DEBUG "Power consumption standard deviation: $_standard_deviation"

  # Return
  RETVAL=$(
    jq \
      --null-input \
      --arg mean "$_mean" \
      --arg standard_deviation "$_standard_deviation" \
      '{
        "mean": $mean,
        "standardDeviation": $standard_deviation
      }'
  )
}

# Decode JWT token
# @param $1 JWT token
decode_token() {
  _decode_token() {
    printf '%s\n' "$1" | jq --raw-input --arg idx "$2" 'gsub("-";"+") | gsub("_";"/") | split(".") | .[$idx|tonumber] | @base64d | fromjson'
  }
  _token=$1

  DEBUG "Decoding JWT token '$_token'"

  # Token header
  _token_header=$(_decode_token "$_token" 0)
  # Token payload
  _token_payload=$(_decode_token "$_token" 1)

  # Return
  RETVAL=$(
    jq \
      --null-input \
      --argjson header "$_token_header" \
      --argjson payload "$_token_payload" \
      '
        {
          "header": $header,
          "payload": $payload
        }
      '
  )
}

# Read CPU information
read_cpu_info() {
  _cpu_info=$(
    lscpu --json \
      | jq \
        '
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
          | . + {"cacheL1d": (."L1d cache" | split(" ") | .[0] + " " + .[1])}
          | . + {"cacheL1i": (."L1i cache" | split(" ") | .[0] + " " + .[1])}
          | . + {"cacheL2": (."L2 cache" | split(" ") | .[0] + " " + .[1])}
          | . + {"cacheL3": (."L3 cache" | split(" ") | .[0] + " " + .[1])}
          | {architecture, flags, cores, vendor, family, model, name, vulnerabilities, cacheL1d, cacheL1i, cacheL2, cacheL3}
        '
  )

  # Convert architecture
  _architecture=$(printf '%s\n' "$_cpu_info" | jq --raw-output '.architecture')
  case $_architecture in
    x86_64) _architecture=amd64 ;;
    aarch64) _architecture=arm64 ;;
    *) FATAL "CPU architecture '$_architecture' is not supported" ;;
  esac
  [ "$_architecture" = "$ARCH" ] || FATAL "CPU architecture '$_architecture' does not match architecture '$ARCH'"

  # Convert vendor
  _vendor=$(printf '%s\n' "$_cpu_info" | jq --raw-output '.vendor')
  case $_vendor in
    AuthenticAMD) _vendor=amd ;;
    GenuineIntel) _vendor=intel ;;
    *) FATAL "CPU vendor '$_vendor' not supported" ;;
  esac

  # Convert cache to bytes
  _cache_l1d=$(printf '%s\n' "$_cpu_info" | jq --raw-output '.cacheL1d' | sed -e 's/B.*//' -e 's/[[:space:]]*//g' | numfmt --from=iec-i)
  _cache_l1i=$(printf '%s\n' "$_cpu_info" | jq --raw-output '.cacheL1i' | sed -e 's/B.*//' -e 's/[[:space:]]*//g' | numfmt --from=iec-i)
  _cache_l2=$(printf '%s\n' "$_cpu_info" | jq --raw-output '.cacheL2' | sed -e 's/B.*//' -e 's/[[:space:]]*//g' | numfmt --from=iec-i)
  _cache_l3=$(printf '%s\n' "$_cpu_info" | jq --raw-output '.cacheL3' | sed -e 's/B.*//' -e 's/[[:space:]]*//g' | numfmt --from=iec-i)

  # Update
  _cpu_info=$(
    printf '%s\n' "$_cpu_info" \
      | jq \
        --arg architecture "$_architecture" \
        --arg vendor "$_vendor" \
        --arg cachel1d "$_cache_l1d" \
        --arg cachel1i "$_cache_l1i" \
        --arg cachel2 "$_cache_l2" \
        --arg cachel3 "$_cache_l3" \
        '
          .architecture = ($architecture | ascii_upcase)
          | .vendor = ($vendor | ascii_upcase)
          | .cacheL1d = ($cachel1d | tonumber)
          | .cacheL1i = ($cachel1i | tonumber)
          | .cacheL2 = ($cachel2 | tonumber)
          | .cacheL3 = ($cachel3 | tonumber)
        '
  )

  # Return
  RETVAL=$_cpu_info
}

# Read memory information
read_memory_info() {
  _memory_info=$(
    grep MemTotal /proc/meminfo \
      | sed -e 's/MemTotal://g' -e 's/[[:space:]]*//g' -e 's/B.*//' \
      | tr '[:lower:]' '[:upper:]' \
      | numfmt --from iec
  )

  # Return
  RETVAL=$_memory_info
}

# Read storage(s) information
read_storages_info() {
  _storages_info=$(
    lsblk --bytes --json \
      | jq \
        '
          .blockdevices
          | map(select(.type == "disk"))
          | map({name, size})
        '
  )

  # Return
  RETVAL=$_storages_info
}

# Read interface(s) information
read_interfaces_info() {
  _interfaces_info=$(read_interfaces)

  # Cycle interfaces to obtain additional information
  while read -r _interface; do
    # Name
    _iname=$(printf '%s\n' "$_interface" | jq --raw-output '.name')
    # Speed
    _speed=$($SUDO ethtool "$_iname" | grep Speed | sed -e 's/Speed://g' -e 's/[[:space:]]*//g' -e 's/b.*//' | numfmt --from=si)
    # WoL
    _wol=$($SUDO ethtool "$_iname" | grep 'Supports Wake-on' | sed -e 's/Supports Wake-on://g' -e 's/[[:space:]]*//g')

    # Update interfaces
    _interfaces_info=$(
      printf '%s\n' "$_interfaces_info" \
        | jq \
          --arg iname "$_iname" \
          --arg speed "$_speed" \
          --arg wol "$_wol" \
          'map(if .name == $iname then . + {"speed": $speed | tonumber, "wol": ($wol | split(""))} else . end)'
    )
  done << EOF
$(printf '%s\n' "$_interfaces_info" | jq --compact-output '.[]')
EOF

  # Return
  RETVAL=$_interfaces_info
}

# Execute CPU benchmark
run_cpu_bench() {
  _run_cpu_bench() {
    sysbench --time="$BENCH_TIME" --threads="$1" cpu run \
      | grep 'events per second' \
      | sed -e 's/events per second://g' -e 's/[[:space:]]*//g' \
      | xargs printf "%.0f"
  }
  _threads=$(grep -c ^processor /proc/cpuinfo)

  # Single-thread
  DEBUG "Running CPU benchmark in single-thread (1)"
  _single_thread=$(_run_cpu_bench 1)
  DEBUG "CPU benchmark in single-thread (1): $_single_thread"

  # Multi-thread
  DEBUG "Running CPU benchmark in multi-thread ($_threads)"
  _multi_thread=$(_run_cpu_bench "$_threads")
  DEBUG "CPU benchmark in multi-thread ($_threads): $_multi_thread"

  # Return
  RETVAL=$(
    jq \
      --null-input \
      --argjson singleThread "$_single_thread" \
      --argjson multiThread "$_multi_thread" \
      '
        {
          "singleThread": $singleThread,
          "multiThread": $multiThread
        }
      '
  )
}

# Execute memory benchmark
run_memory_bench() {
  _run_memory_bench() {
    _memory_output=$(sysbench --time="$BENCH_TIME" --memory-oper="$1" --memory-access-mode="$2" memory run \
      | grep 'transferred' \
      | sed -e 's/.*(\(.*\))/\1/' -e 's/B.*//' -e 's/[[:space:]]*//g' \
      | numfmt --from=iec-i)
    printf '%s\n' $((_memory_output * 8))
  }

  # Read sequential
  DEBUG "Running memory benchmark in read sequential"
  _read_seq=$(_run_memory_bench read seq)
  DEBUG "Memory benchmark in read sequential: $_read_seq"

  # Read random
  DEBUG "Running memory benchmark in read random"
  _read_rand=$(_run_memory_bench read rnd)
  DEBUG "Memory benchmark in read random: $_read_rand"

  # Write sequential
  DEBUG "Running memory benchmark in write sequential"
  _write_seq=$(_run_memory_bench write seq)
  DEBUG "Memory benchmark in write sequential: $_write_seq"
  # Write random
  DEBUG "Running memory benchmark in write random"
  _write_rand=$(_run_memory_bench write rnd)
  DEBUG "Memory benchmark in write random: $_write_rand"

  # Return
  RETVAL=$(
    jq \
      --null-input \
      --arg readSeq "$_read_seq" \
      --arg readRand "$_read_rand" \
      --arg writeSeq "$_write_seq" \
      --arg writeRand "$_write_rand" \
      '
        {
          "read": {
            "sequential": ($readSeq | tonumber),
            "random": ($readRand | tonumber)
          },
          "write": {
            "sequential": ($writeSeq | tonumber),
            "random": ($writeRand | tonumber)
          }
        }
      '
  )
}

# Execute storage(s) benchmark
run_storages_bench() {
  _run_storages_bench() {
    # Io operation
    _io_opt=
    case $1 in
      read) _io_opt=$1 ;;
      write)
        _io_opt=written
        # Prepare write benchmark
        sysbench fileio cleanup > /dev/null
        sysbench fileio prepare > /dev/null
        ;;
    esac

    _io_output=$(sysbench --time="$BENCH_TIME" --file-test-mode="$2" --file-io-mode="$3" fileio run | grep "$_io_opt, ")
    _io_throughput_value=$(printf '%s\n' "$_io_output" | sed -e 's/^.*: //' -e 's/[[:space:]]*//g')
    _io_throughput_unit=$(printf '%s\n' "$_io_output" | sed -e 's/.*,\(.*\)B\/s.*/\1/' -e 's/[[:space:]]*//g')

    _io_throughput=$(printf "%s%s\n" "$_io_throughput_value" "$_io_throughput_unit" | numfmt --from=iec-i)
    printf '%s\n' $((_io_throughput * 8))
  }

  # TODO Benchmark per storage

  # Prepare read benchmark
  DEBUG "Preparing storage(s) read benchmark"
  sysbench fileio cleanup > /dev/null
  sysbench fileio prepare > /dev/null

  # Read sequential synchronous
  DEBUG "Running storage(s) benchmark in read sequential synchronous"
  _read_seq_sync=$(_run_storages_bench read seqrd sync)
  DEBUG "Storage(s) benchmark in read sequential synchronous: $_read_seq_sync"

  # Read sequential asynchronous
  DEBUG "Running storage(s) benchmark in read sequential asynchronous"
  _read_seq_async=$(_run_storages_bench read seqrd async)
  DEBUG "Storage(s) benchmark in read sequential asynchronous: $_read_seq_async"

  # Read random synchronous
  DEBUG "Running storage(s) benchmark in read random synchronous"
  _read_rand_sync=$(_run_storages_bench read rndrd sync)
  DEBUG "Storage(s) benchmark in read random synchronous: $_read_rand_sync"

  # Read random asynchronous
  DEBUG "Running storage(s) benchmark in read random asynchronous"
  _read_rand_async=$(_run_storages_bench read rndrd async)
  DEBUG "Storage(s) benchmark in read random asynchronous: $_read_rand_async"

  # Write sequential synchronous
  DEBUG "Running storage(s) benchmark in write sequential synchronous"
  _write_seq_sync=$(_run_storages_bench write seqwr sync)
  DEBUG "Storage(s) benchmark in write sequential synchronous: $_write_seq_sync"

  # Write sequential asynchronous
  DEBUG "Running storage(s) benchmark in write sequential asynchronous"
  _write_seq_async=$(_run_storages_bench write seqwr async)
  DEBUG "Storage(s) benchmark in write sequential asynchronous: $_write_seq_async"

  # Write random synchronous
  DEBUG "Running storage(s) benchmark in write random synchronous"
  _write_rand_sync=$(_run_storages_bench write rndwr sync)
  DEBUG "Storage(s) benchmark in write random synchronous: $_write_rand_sync"

  # Write random asynchronous
  DEBUG "Running storage(s) benchmark in write random asynchronous"
  _write_rand_async=$(_run_storages_bench write rndwr async)
  DEBUG "Storage(s) benchmark in write random asynchronous: $_write_rand_async"

  # Clean
  DEBUG "Cleaning storage(s) benchmark"
  sysbench fileio cleanup > /dev/null

  # Return
  RETVAL=$(
    jq \
      --null-input \
      --arg readSeqSync "$_read_seq_sync" \
      --arg readSeqAsync "$_read_seq_async" \
      --arg readRandSync "$_read_rand_sync" \
      --arg readRandAsync "$_read_rand_async" \
      --arg writeSeqSync "$_write_seq_sync" \
      --arg writeSeqAsync "$_write_seq_async" \
      --arg writeRandSync "$_write_rand_sync" \
      --arg writeRandAsync "$_write_rand_async" \
      '
        {
          "read": {
            "sequential": {
              "synchronous": ($readSeqSync | tonumber),
              "asynchronous": ($readSeqAsync | tonumber),
            },
            "random": {
              "synchronous": ($readRandSync | tonumber),
              "asynchronous": ($readRandAsync | tonumber),
            }
          },
          "write": {
            "sequential": {
              "synchronous": ($writeSeqSync | tonumber),
              "asynchronous": ($writeSeqAsync | tonumber),
            },
            "random": {
              "synchronous": ($writeRandSync | tonumber),
              "asynchronous": ($writeRandAsync | tonumber),
            }
          }
        }
      '
  )
}

# Read CPU power consumption
read_cpu_power_consumption() {
  _run_cpu_bench() {
    sysbench --time=0 --threads="$1" cpu run > /dev/null &
    read_power_consumption "$!"
  }
  _threads=$(grep -c ^processor /proc/cpuinfo)

  # Idle
  DEBUG "Reading CPU power consumption in idle"
  read_power_consumption
  _idle=$RETVAL
  DEBUG "CPU power consumption in idle:" "$_idle"

  # Multi-thread
  DEBUG "Reading CPU power consumption in multi-thread ($_threads)"
  _run_cpu_bench "$_threads"
  _multi_thread=$RETVAL
  DEBUG "CPU power consumption in multi-thread ($_threads):" "$_multi_thread"

  # Return
  RETVAL=$(
    jq \
      --null-input \
      --argjson idle "$_idle" \
      --argjson multi "$_multi_thread" \
      '
        {
          "idle": $idle,
          "multiThread": $multi
        }
      '
  )
}

# Wait K8s reachability
wait_k8s_reachability() {
  assert_cmd kubectl

  _wait_k8s_max_attempts_default=20
  _wait_k8s_max_attempts=$_wait_k8s_max_attempts_default
  _wait_k8s_sleep=3
  _node_name=$($SUDO grep 'node-name:' /etc/rancher/k3s/config.yaml | sed -e 's/node-name://g' -e 's/[[:space:]]*//' -e 's/^"//' -e 's/"$//')

  INFO "Waiting K8s reachability"

  DEBUG "Waiting K8s control plane reachability"
  _wait_k8s_max_attempts=$_wait_k8s_max_attempts_default
  while [ "$_wait_k8s_max_attempts" -gt 0 ]; do
    if $SUDO kubectl cluster-info > /dev/null 2>&1; then
      DEBUG "K8s control plane is reachable"
      break
    fi

    DEBUG "K8s control plane is not reachable, sleeping $_wait_k8s_sleep seconds"
    sleep "$_wait_k8s_sleep"
    _wait_k8s_max_attempts=$((_wait_k8s_max_attempts = _wait_k8s_max_attempts - 1))
  done
  [ "$_wait_k8s_max_attempts" -gt 0 ] || FATAL "K8s control plane is not reachable, maximum attempts reached"

  DEBUG "Waiting K8s node '$_node_name' reachability"
  _wait_k8s_max_attempts=$_wait_k8s_max_attempts_default
  while [ "$_wait_k8s_max_attempts" -gt 0 ]; do
    if $SUDO kubectl get node "$_node_name" 2>&1 | grep -q -E "$_node_name\s+Ready\s+"; then
      DEBUG "K8s node is reachable"
      break
    fi

    DEBUG "K8s node '$_node_name' is not reachable, sleeping $_wait_k8s_sleep seconds"
    sleep "$_wait_k8s_sleep"
    _wait_k8s_max_attempts=$((_wait_k8s_max_attempts = _wait_k8s_max_attempts - 1))
  done
  [ "$_wait_k8s_max_attempts" -gt 0 ] || FATAL "K8s node '$_node_name' is not reachable, maximum attempts reached"

  DEBUG "Waiting K8s kube-dns reachability"
  _wait_k8s_max_attempts=$_wait_k8s_max_attempts_default
  while [ "$_wait_k8s_max_attempts" -gt 0 ]; do
    if $SUDO kubectl get pod --selector k8s-app=kube-dns --namespace kube-system 2>&1 | grep -q -E '\s+Running\s+'; then
      DEBUG "K8s kube-dns is reachable"
      break
    fi

    DEBUG "K8s kube-dns is not reachable, sleeping $_wait_k8s_sleep seconds"
    sleep "$_wait_k8s_sleep"
    _wait_k8s_max_attempts=$((_wait_k8s_max_attempts = _wait_k8s_max_attempts - 1))
  done
  [ "$_wait_k8s_max_attempts" -gt 0 ] || FATAL "K8s kube-dns is not reachable, maximum attempts reached"

  DEBUG "K8s is reachable"
}

# Wait database reachability
wait_database_reachability() {
  _wait_database_max_attempts=20
  _wait_database_sleep=3

  INFO "Waiting database reachability"
  while [ "$_wait_database_max_attempts" -gt 0 ]; do
    if $SUDO su postgres -c "pg_isready" > /dev/null 2>&1; then
      DEBUG "Database is reachable"
      break
    fi

    DEBUG "Database is not reachable, sleeping $_wait_database_sleep seconds"
    sleep "$_wait_database_sleep"
    _wait_database_max_attempts=$((_wait_database_max_attempts = _wait_database_max_attempts - 1))
  done
  [ "$_wait_database_max_attempts" -gt 0 ] || FATAL "Database is not reachable, maximum attempts reached"
}

# Wait server reachability
wait_server_reachability() {
  _wait_server_max_attempts=20
  _wait_server_sleep=3
  _server_url=$(printf '%s\n' "$CONFIG" | jq --exit-status --raw-output '.recluster.server')

  INFO "Waiting server reachability"
  while [ "$_wait_server_max_attempts" -gt 0 ]; do
    if assert_url_reachability "$_server_url/health" > /dev/null 2>&1; then
      DEBUG "Server is reachable"
      break
    fi

    DEBUG "Server is not reachable, sleeping $_wait_server_sleep seconds"
    sleep "$_wait_server_sleep"
    _wait_server_max_attempts=$((_wait_server_max_attempts = _wait_server_max_attempts - 1))
  done
  [ "$_wait_server_max_attempts" -gt 0 ] || FATAL "Server is not reachable, maximum attempts reached"
}

# Register current node
node_registration() {
  _server_url=$(printf '%s\n' "$CONFIG" | jq --exit-status --raw-output '.recluster.server') || FATAL "reCluster configuration requires server URL"
  _server_url="$_server_url/graphql"
  _request_data=$(
    jq \
      --null-input \
      --compact-output \
      --argjson data "$NODE_FACTS" \
      '
        {
          "query": "mutation ($data: CreateNodeInput!) { createNode(data: $data) }",
          "variables": { "data": $data }
        }
      '
  )
  _response_data=

  INFO "Registering node at '$_server_url'"

  # Send node registration request
  DEBUG "Sending node registration request data to '$_server_url'" "$_request_data"
  case $DOWNLOADER in
    curl)
      _response_data=$(
        curl --fail --silent --location --show-error \
          --request POST \
          --header 'Content-Type: application/json' \
          --data "$_request_data" \
          --url "$_server_url"
      ) || FATAL "Error sending node registration request to '$_server_url'"
      ;;
    wget)
      _response_data=$(
        wget --quiet --output-document=- \
          --header='Content-Type: application/json' \
          --post-data="$_request_data" \
          "$_server_url" 2>&1
      ) || FATAL "Error sending node registration request to '$_server_url'"
      ;;
    *) FATAL "Unknown downloader '$DOWNLOADER'" ;;
  esac
  DEBUG "Received node registration response data '$_response_data' from '$_server_url'"

  # Check error response
  if printf '%s\n' "$_response_data" | jq --exit-status 'has("errors")' > /dev/null 2>&1; then
    FATAL "Error registering node at '$_server_url':" "$_response_data"
  fi

  # Extract token
  _token=$(printf '%s\n' "$_response_data" | jq --raw-output '.data.createNode')

  # Decode token
  decode_token "$_token"
  _token_decoded=$RETVAL

  # Success
  INFO "Successfully registered node:" "$_token_decoded"

  # Return
  RETVAL=$(
    jq \
      --null-input \
      --arg token "$_token" \
      --argjson decoded "$_token_decoded" \
      '
        {
          "token": $token,
          "decoded": $decoded
        }
      '
  )
}

################################################################################################################################

# Parse command line arguments
# @param $@ Arguments
parse_args() {
  while [ $# -gt 0 ]; do
    # Number of shift
    _shifts=1

    case $1 in
      --airgap)
        # Airgap environment
        AIRGAP_ENV=true
        ;;
      --autoscaler-version)
        #Autoscaler version
        parse_args_assert_value "$@"

        AUTOSCALER_VERSION=$2
        _shifts=2
        ;;
      --bench-time)
        # Benchmark time
        parse_args_assert_value "$@"
        parse_args_assert_positive_integer "$1" "$2"

        BENCH_TIME=$2
        _shifts=2
        ;;
      --certs-dir)
        # Certificates directory
        parse_args_assert_value "$@"

        RECLUSTER_CERTS_DIR=$2
        _shifts=2
        ;;
      --config-file)
        # Configuration file
        parse_args_assert_value "$@"

        CONFIG_FILE=$2
        _shifts=2
        ;;
      --help)
        # Display help message and exit
        show_help
        exit 0
        ;;
      --init-cluster)
        # Initialize cluster
        INIT_CLUSTER=true
        ;;
      --k3s-config-file)
        # K3s configuration file
        parse_args_assert_value "$@"

        K3S_CONFIG_FILE=$2
        _shifts=2
        ;;
      --k3s-registry-config-file)
        # K3s registry configuration file
        parse_args_assert_value "$@"

        K3S_REGISTRY_CONFIG_FILE=$2
        _shifts=2
        ;;
      --k3s-version)
        # K3s version
        parse_args_assert_value "$@"

        K3S_VERSION=$2
        _shifts=2
        ;;
      --node-exporter-config-file)
        # Node exporter configuration file
        parse_args_assert_value "$@"

        NODE_EXPORTER_CONFIG_FILE=$2
        _shifts=2
        ;;
      --node-exporter-version)
        # Node exporter version
        parse_args_assert_value "$@"

        NODE_EXPORTER_VERSION=$2
        _shifts=2
        ;;
      --pc-device-api)
        # Power consumption device api url
        parse_args_assert_value "$@"

        PC_DEVICE_API=$2
        _shifts=2
        ;;
      --pc-interval)
        # Power consumption interval
        parse_args_assert_value "$@"
        parse_args_assert_positive_integer "$1" "$2"

        PC_INTERVAL=$2
        _shifts=2
        ;;
      --pc-time)
        # Power consumption time
        parse_args_assert_value "$@"
        parse_args_assert_positive_integer "$1" "$2"

        PC_TIME=$2
        _shifts=2
        ;;
      --pc-warmup)
        # Power consumption warmup time
        parse_args_assert_value "$@"
        parse_args_assert_positive_integer "$1" "$2"

        PC_WARMUP=$2
        _shifts=2
        ;;
      --server-env-file)
        # Server environment file
        parse_args_assert_value "$@"

        RECLUSTER_SERVER_ENV_FILE=$2
        _shifts=2
        ;;
      --ssh-authorized-keys-file)
        # SSH authorized keys file
        parse_args_assert_value "$@"

        SSH_AUTHORIZED_KEYS_FILE=$2
        _shifts=2
        ;;
      --ssh-config-file)
        # SSH configuration file
        parse_args_assert_value "$@"

        SSH_CONFIG_FILE=$2
        _shifts=2
        ;;
      --sshd-config-file)
        # SSH server configuration file
        parse_args_assert_value "$@"

        SSHD_CONFIG_FILE=$2
        _shifts=2
        ;;
      --user)
        # User
        parse_args_assert_value "$@"

        USER=$2
        _shifts=2
        ;;
      *)
        # Commons
        parse_args_commons "$@"
        _shifts=$RETVAL
        ;;
    esac

    # Shift arguments
    while [ "$_shifts" -gt 0 ]; do
      shift
      _shifts=$((_shifts = _shifts - 1))
    done
  done
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
  assert_cmd bc
  assert_cmd cp
  assert_cmd date
  assert_cmd ethtool
  assert_cmd grep
  assert_cmd id
  assert_cmd ip
  assert_cmd jq
  assert_cmd lscpu
  assert_cmd lsblk
  assert_cmd mktemp
  assert_cmd numfmt
  assert_cmd read
  assert_cmd sed
  assert_cmd ssh-keygen
  assert_cmd sudo
  assert_cmd sysbench
  assert_cmd tar
  assert_cmd tee
  assert_cmd tr
  assert_cmd uname
  assert_cmd yq
  if [ "$INIT_CLUSTER" = true ]; then
    assert_cmd docker
    assert_cmd inotifywait
    assert_cmd node
    assert_cmd npm
    assert_cmd pg_ctl
    assert_cmd pg_isready

    assert_user postgres
  fi
  # Spinner
  assert_spinner

  # User
  assert_user
  # Init system
  assert_init_system
  # Timezone
  assert_timezone
  # Downloader command
  assert_downloader
  # Check power consumption device reachability
  assert_url_reachability "$PC_DEVICE_API"

  # Directories
  [ ! -d "$RECLUSTER_ETC_DIR" ] || FATAL "Directory '$RECLUSTER_ETC_DIR' already exists"
  [ ! -d "$RECLUSTER_OPT_DIR" ] || FATAL "Directory '$RECLUSTER_OPT_DIR' already exists"
  # Certificates
  [ -d "$RECLUSTER_CERTS_DIR" ] || FATAL "Certificates directory '$RECLUSTER_CERTS_DIR' does not exists"

  # Server env
  [ -f "$RECLUSTER_SERVER_ENV_FILE" ] || FATAL "Server environment file '$RECLUSTER_SERVER_ENV_FILE' does not exists"

  # Configuration
  [ -f "$CONFIG_FILE" ] || FATAL "Configuration file '$CONFIG_FILE' does not exists"
  INFO "Reading configuration file '$CONFIG_FILE'"
  CONFIG=$(yq e --output-format=json --no-colors '.' "$CONFIG_FILE") || FATAL "Error reading configuration file '$CONFIG_FILE'"
  DEBUG "Configuration:" "$CONFIG"
  # Kind
  _kind=$(printf '%s\n' "$CONFIG" | jq --exit-status --raw-output '.kind') || FATAL "Configuration requires 'kind'"
  [ "$_kind" = "controller" ] || [ "$_kind" = "worker" ] || FATAL "Configuration 'kind' must be 'controller' or 'worker' but '$_kind' found"
  # reCluster server URL
  _recluster_server_url=$(printf '%s\n' "$CONFIG" | jq --exit-status --raw-output '.recluster.server') || FATAL "Configuration requires 'recluster.server'"
  [ "$INIT_CLUSTER" = true ] || assert_url_reachability "$_recluster_server_url/health"

  # K3s configuration
  [ -f "$K3S_CONFIG_FILE" ] || FATAL "K3s configuration file '$K3S_CONFIG_FILE' does not exists"
  INFO "Reading K3s configuration file '$K3S_CONFIG_FILE'"
  K3S_CONFIG=$(yq e --output-format=json --no-colors '.' "$K3S_CONFIG_FILE") || FATAL "Error reading K3s configuration file '$K3S_CONFIG_FILE'"
  DEBUG "K3s configuration:" "$K3S_CONFIG"
  # K3s requires server and token if worker or controller (no init cluster)
  if { [ "$_kind" = "worker" ] || { [ "$_kind" = "controller" ] && [ "$INIT_CLUSTER" = false ]; }; } && [ "$(printf '%s\n' "$K3S_CONFIG" | jq --raw-output 'any(select(.server and .token))')" = false ]; then
    FATAL "K3s configuration requires 'server' and 'token'"
  fi
  # K3s node name
  [ "$(printf '%s\n' "$K3S_CONFIG" | jq --raw-output 'any(.; select(."node-name"))')" = false ] || {
    WARN "K3s configuration 'node-name' must not be provided"
    K3S_CONFIG=$(printf '%s\n' "$K3S_CONFIG" | jq 'del(."node-name")')
  }
  # K3s node id
  [ "$(printf '%s\n' "$K3S_CONFIG" | jq --raw-output 'any(.; select(."with-node-id"))')" = false ] || {
    WARN "K3s configuration 'with-node-id' must not be provided"
    K3S_CONFIG=$(printf '%s\n' "$K3S_CONFIG" | jq 'del(."with-node-id")')
  }
  # K3s write-kubeconfig-mode
  [ "$(printf '%s\n' "$K3S_CONFIG" | jq --raw-output 'any(.; select(."write-kubeconfig-mode"))')" = false ] || {
    WARN "K3s configuration 'write-kubeconfig-mode' must not be provided"
    K3S_CONFIG=$(printf '%s\n' "$K3S_CONFIG" | jq 'del(."write-kubeconfig-mode")')
  }
  # K3s registry configuration file
  [ -f "$K3S_REGISTRY_CONFIG_FILE" ] || FATAL "K3s registry configuration file '$K3S_REGISTRY_CONFIG_FILE' does not exists"

  # Node exporter configuration
  [ -f "$NODE_EXPORTER_CONFIG_FILE" ] || FATAL "Node exporter configuration file '$NODE_EXPORTER_CONFIG_FILE' does not exists"
  INFO "Reading Node exporter configuration file '$NODE_EXPORTER_CONFIG_FILE'"
  NODE_EXPORTER_CONFIG=$(yq e --output-format=json --no-colors '.' "$NODE_EXPORTER_CONFIG_FILE") || FATAL "Error reading Node exporter configuration file '$NODE_EXPORTER_CONFIG_FILE'"
  DEBUG "Node exporter configuration:" "$NODE_EXPORTER_CONFIG"

  # SSH configuration file
  [ -f "$SSH_CONFIG_FILE" ] || FATAL "SSH configuration file '$SSH_CONFIG_FILE' does not exists"
  # SSH server configuration file
  [ -f "$SSHD_CONFIG_FILE" ] || FATAL "SSH server configuration file '$SSHD_CONFIG_FILE' does not exists"
  # SSH authorized keys file
  [ -f "$SSH_AUTHORIZED_KEYS_FILE" ] || FATAL "SSH authorized keys file '$SSH_AUTHORIZED_KEYS_FILE' does not exists"
  [ -s "$SSH_AUTHORIZED_KEYS_FILE" ] || FATAL "SSH authorized keys file '$SSH_AUTHORIZED_KEYS_FILE' is empty"
  while read -r _ssh_authorized_key; do
    printf '%s\n' "$_ssh_authorized_key" | ssh-keygen -l -f - > /dev/null 2>&1 || FATAL "SSH authorized key '$_ssh_authorized_key' is not valid"
  done << EOF
$(cat "$SSH_AUTHORIZED_KEYS_FILE")
EOF

  # Cluster initialization
  if [ "$INIT_CLUSTER" = true ]; then
    [ "$_kind" = controller ] || FATAL "Cluster initialization requires configuration 'kind' value 'controller' but '$_kind' found"
    [ "$(printf '%s\n' "$K3S_CONFIG" | jq --exit-status 'any(.; ."cluster-init" == true)')" = true ] || WARN "Cluster initialization K3s configuration 'cluster-init' not found or set to 'false'"
  fi

  # Airgap
  if [ "$AIRGAP_ENV" = true ]; then
    [ "$AUTOSCALER_VERSION" != latest ] || FATAL "Autoscaler version '$AUTOSCALER_VERSION' not available in Air-Gap environment"
    [ "$K3S_VERSION" != latest ] || FATAL "K3s version '$K3S_VERSION' not available in Air-Gap environment"
    [ "$NODE_EXPORTER_VERSION" != latest ] || FATAL "Node exporter version '$NODE_EXPORTER_VERSION' not available in Air-Gap environment"
  fi

  # Autoscaler
  if [ "$AUTOSCALER_VERSION" = latest ]; then
    INFO "Finding Autoscaler latest release"
    AUTOSCALER_VERSION=$(download_print 'https://api.github.com/repos/carlocorradini/autoscaler/releases/latest' | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    INFO "Autoscaler latest release is '$AUTOSCALER_VERSION'"
  fi
  AUTOSCALER_DIR="$DIRNAME/dependencies/autoscaler/$AUTOSCALER_VERSION"
  [ -d "$AUTOSCALER_DIR" ] || FATAL "Autoscaler directory '$AUTOSCALER_DIR' does not exists"

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

  # Interfaces
  _interfaces=$(read_interfaces)
  [ "$(printf '%s\n' "$_interfaces" | jq --raw-output 'length')" -ge 1 ] || FATAL "No interfaces found"
  while read -r _interface; do
    # Name
    _iname=$(printf '%s\n' "$_interface" | jq --raw-output '.name')
    # Supports WoL
    _supports_wol=$($SUDO ethtool "$_iname" | grep 'Supports Wake-on' | sed -e 's/Supports Wake-on://g' -e 's/[[:space:]]*//g')

    case $_supports_wol in
      *g*)
        # WoL supported
        _wol=$($SUDO ethtool "$_iname" | grep 'Wake-on' | grep -v 'Supports Wake-on' | sed -e 's/Wake-on://g' -e 's/[[:space:]]*//g')
        [ "$_wol" != d ] || FATAL "Interface '$_iname' Wake-on-Lan is disabled"
        ;;
      *)
        # WoL not supported
        WARN "Interface '$_iname' does not support Wake-on-Lan"
        ;;
    esac
  done << EOF
$(printf '%s\n' "$_interfaces" | jq --compact-output '.[]')
EOF
}

# Setup system
setup_system() {
  # Create uninstall
  create_uninstall

  # Temporary directory
  TMP_DIR=$(mktemp --directory -t recluster.XXXXXXXX)
  DEBUG "Created temporary directory '$TMP_DIR'"

  # Directories
  DEBUG "Creating directory '$RECLUSTER_ETC_DIR'"
  $SUDO mkdir -p "$RECLUSTER_ETC_DIR" || FATAL "Error creating directory '$RECLUSTER_ETC_DIR'"
  DEBUG "Creating directory '$RECLUSTER_OPT_DIR'"
  $SUDO mkdir -p "$RECLUSTER_OPT_DIR" || FATAL "Error creating directory '$RECLUSTER_OPT_DIR'"

  # SSH
  setup_ssh

  # Certificates
  setup_certificates

  # Cluster initialization
  if [ "$INIT_CLUSTER" = true ]; then
    spinner_start "Preparing Cluster initialization"

    # Docker
    DEBUG "Adding user '$USER' to group 'docker'"
    $SUDO addgroup "$USER" docker
    case $INIT_SYSTEM in
      openrc)
        INFO "openrc: Starting Docker service"
        $SUDO rc-service docker restart
        ;;
      systemd)
        INFO "systemd: Starting Docker service"
        $SUDO systemctl restart docker
        ;;
      *) FATAL "Unknown init system '$INIT_SYSTEM'" ;;
    esac

    spinner_stop
  fi

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
    _node_exporter_release_name=node_exporter-$(printf '%s\n' "$NODE_EXPORTER_VERSION" | sed 's/^v//').linux-$ARCH

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
    $SUDO chown root:root "$AIRGAP_K3S_BIN"
    $SUDO chmod 755 "$AIRGAP_K3S_BIN"
    $SUDO chown root:root "$AIRGAP_NODE_EXPORTER_BIN"
    $SUDO chmod 755 "$AIRGAP_NODE_EXPORTER_BIN"

    spinner_stop
  fi
}

# Read system information
read_system_info() {
  spinner_start "Reading system information"

  # CPU
  read_cpu_info
  _cpu_info=$RETVAL
  DEBUG "CPU info:" "$_cpu_info"
  INFO "CPU is '$(printf '%s\n' "$_cpu_info" | jq --raw-output .name)'"

  # Memory
  read_memory_info
  _memory_info=$RETVAL
  INFO "Memory is '$(printf '%s\n' "$_memory_info" | numfmt --to=iec-i)B'"

  # Storage(s)
  read_storages_info
  _storages_info=$RETVAL
  DEBUG "Storage(s) info:" "$_storages_info"
  _storages_info_msg="Storage(s) found $(printf '%s\n' "$_storages_info" | jq --raw-output 'length'):"
  while read -r _storage_info; do
    _storages_info_msg="$_storages_info_msg\n\t'$(printf '%s\n' "$_storage_info" | jq --raw-output .name)' of '$(printf '%s\n' "$_storage_info" | jq --raw-output .size | numfmt --to=iec-i)B'"
  done << EOF
$(printf '%s\n' "$_storages_info" | jq --compact-output '.[]')
EOF
  INFO "$_storages_info_msg"

  # Interface(s)
  read_interfaces_info
  _interfaces_info=$RETVAL
  DEBUG "Interface(s) info:" "$_interfaces_info"
  INFO "Interface(s) found $(printf '%s\n' "$_interfaces_info" | jq --raw-output 'length'):
    $(printf '%s\n' "$_interfaces_info" | jq --raw-output '.[] | "\t'\''\(.name)'\'' at '\''\(.address)'\''"')"

  spinner_stop

  # Update
  NODE_FACTS=$(
    printf '%s\n' "$NODE_FACTS" \
      | jq \
        --argjson cpu "$_cpu_info" \
        --argjson memory "$_memory_info" \
        --argjson storages "$_storages_info" \
        --argjson interfaces "$_interfaces_info" \
        '
          .cpu = $cpu
          | .memory = $memory
          | .storages = $storages
          | .interfaces = $interfaces
        '
  )
}

# Execute benchmarks
run_benchmarks() {
  spinner_start "Benchmarking"

  # CPU
  INFO "CPU benchmark"
  run_cpu_bench
  _cpu_benchmark=$RETVAL
  DEBUG "CPU benchmark:" "$_cpu_benchmark"

  # Memory
  INFO "Memory benchmark"
  run_memory_bench
  _memory_benchmark=$RETVAL
  DEBUG "Memory benchmark:" "$_memory_benchmark"

  # Storage(s)
  INFO "Storage(s) benchmark"
  # FIXME Execute
  # run_storages_bench
  # _storages_benchmark=$RETVAL
  _storages_benchmark="{}"
  DEBUG "Storage(s) benchmark:" "$_storages_benchmark"

  spinner_stop

  # Update
  NODE_FACTS=$(
    printf '%s\n' "$NODE_FACTS" \
      | jq \
        --argjson cpu "$_cpu_benchmark" \
        --argjson memory "$_memory_benchmark" \
        --argjson storages "$_storages_benchmark" \
        '
          .cpu.singleThreadScore = $cpu.singleThread
          | .cpu.multiThreadScore = $cpu.multiThread
        '
  )
}

# Read power consumptions
read_power_consumptions() {
  spinner_start "Reading power consumption"

  # CPU
  INFO "CPU power consumption"
  read_cpu_power_consumption
  _cpu_power_consumption=$RETVAL
  DEBUG "CPU power consumption:" "$_cpu_power_consumption"

  spinner_stop

  # Update
  NODE_FACTS=$(
    printf '%s\n' "$NODE_FACTS" \
      | jq \
        --argjson cpu "$_cpu_power_consumption" \
        '
          .minPowerConsumption = $cpu.idle.mean
          | .maxPowerConsumption = $cpu.multiThread.mean
        '
  )
}

# Finalize node facts
finalize_node_facts() {
  spinner_start "Finalizing node facts"

  _kind=$(printf '%s\n' "$CONFIG" | jq --raw-output '.kind')
  _has_taint_no_execute=$(printf '%s\n' "$K3S_CONFIG" | jq --raw-output 'any(select(."node-taint"); ."node-taint"[] | . == "CriticalAddonsOnly=true:NoExecute")')

  # Roles
  _roles="[]"
  if [ "$INIT_CLUSTER" = true ]; then _roles=$(printf '%s\n' "$_roles" | jq '. + ["RECLUSTER_CONTROLLER"]'); fi
  if [ "$_kind" = "controller" ]; then _roles=$(printf '%s\n' "$_roles" | jq '. + ["K8S_CONTROLLER"]'); fi
  if [ "$_kind" = "worker" ] || { [ "$_kind" = "controller" ] && [ "$_has_taint_no_execute" = false ]; }; then
    _roles=$(printf '%s\n' "$_roles" | jq '. + ["K8S_WORKER"]')
  fi
  DEBUG "Node roles:" "$_roles"

  NODE_FACTS=$(
    printf '%s\n' "$NODE_FACTS" \
      | jq \
        --argjson roles "$_roles" \
        '
          .roles = $roles
        '
  )

  spinner_stop

  DEBUG "Node facts:" "$NODE_FACTS"
}

# Install K3s
install_k3s() {
  _k3s_version="$K3S_VERSION"
  _k3s_install_sh=
  _k3s_etc_dir=/etc/rancher/k3s
  _k3s_config_file="$_k3s_etc_dir/config.yaml"
  _k3s_registry_config_file="$_k3s_etc_dir/registries.yaml"
  _k3s_kind=

  spinner_start "Installing K3s '$K3S_VERSION'"

  # Uninstall
  if [ -x /usr/local/bin/k3s-recluster-uninstall.sh ]; then
    DEBUG "Uninstalling K3s"
    $SUDO /usr/local/bin/k3s-recluster-uninstall.sh
  fi

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
    if [ "$_k3s_version" = latest ]; then _k3s_version=; fi
    _k3s_install_sh="$TMP_DIR/install.k3s.sh"
    # Download installer
    DEBUG "Downloading K3s installer"
    download "$_k3s_install_sh" https://get.k3s.io
    chmod 755 "$_k3s_install_sh"
  fi

  # Checks
  { [ -f "$_k3s_install_sh" ] && [ -x "$_k3s_install_sh" ]; } || FATAL "K3s installation script '$_k3s_install_sh' not found or not executable"

  # Kind
  _kind=$(printf '%s\n' "$CONFIG" | jq --raw-output '.kind')
  case $_kind in
    controller) _k3s_kind=server ;;
    worker) _k3s_kind=agent ;;
    *) FATAL "Unknown kind '$_kind'" ;;
  esac

  # Etc directory
  [ -d "$_k3s_etc_dir" ] || $SUDO mkdir -p "$_k3s_etc_dir"

  # Write configuration
  INFO "Writing K3s configuration to '$_k3s_config_file'"
  printf '%s\n' "$K3S_CONFIG" \
    | yq e --no-colors --prettyPrint - \
    | yq e --no-colors '(.. | select(tag == "!!str")) style="double"' - \
    | $SUDO tee "$_k3s_config_file" > /dev/null
  $SUDO chown root:root "$_k3s_config_file"
  $SUDO chmod 644 "$_k3s_config_file"

  # Registry configuration
  INFO "Copying K3s registry configuration file from '$K3S_REGISTRY_CONFIG_FILE' to '$_k3s_registry_config_file'"
  yes | $SUDO cp --force "$K3S_REGISTRY_CONFIG_FILE" "$_k3s_registry_config_file"
  $SUDO chown root:root "$_k3s_config_file"
  $SUDO chmod 644 "$_k3s_config_file"

  # Install
  INSTALL_K3S_SKIP_ENABLE=true \
    INSTALL_K3S_SKIP_START=true \
    INSTALL_K3S_SKIP_DOWNLOAD="$AIRGAP_ENV" \
    INSTALL_K3S_VERSION="$_k3s_version" \
    INSTALL_K3S_NAME=recluster \
    INSTALL_K3S_EXEC="$_k3s_kind" \
    "$_k3s_install_sh" || FATAL "Error installing K3s '$K3S_VERSION'"

  spinner_stop

  # Success
  INFO "Successfully installed K3s '$K3S_VERSION'"
}

# Install Node exporter
install_node_exporter() {
  _node_exporter_version="$NODE_EXPORTER_VERSION"
  _node_exporter_install_sh=
  _node_exporter_config=

  spinner_start "Installing Node exporter '$NODE_EXPORTER_VERSION'"

  # Uninstall
  if [ -x /usr/local/bin/node_exporter.uninstall.sh ]; then
    DEBUG "Uninstalling Node exporter"
    $SUDO /usr/local/bin/node_exporter.uninstall.sh
  fi

  # Check airgap environment
  if [ "$AIRGAP_ENV" = true ]; then
    # Airgap enabled
    _node_exporter_install_sh="$DIRNAME/dependencies/node_exporter/install.sh"
    # Move
    $SUDO mv --force "$AIRGAP_NODE_EXPORTER_BIN" /usr/local/bin/node_exporter
  else
    # Airgap disabled
    if [ "$_node_exporter_version" = latest ]; then _node_exporter_version=; fi
    _node_exporter_install_sh="$TMP_DIR/install.node_exporter.sh"
    # Download installer
    DEBUG "Downloading Node exporter installer"
    download "$_node_exporter_install_sh" https://raw.githubusercontent.com/carlocorradini/node_exporter_installer/main/install.sh
    chmod 755 "$_node_exporter_install_sh"
  fi

  # Checks
  { [ -f "$_node_exporter_install_sh" ] && [ -x "$_node_exporter_install_sh" ]; } || FATAL "Node exporter installation script '$_node_exporter_install_sh' not found or not executable"

  # Configuration
  INFO "Writing Node exporter configuration"
  _node_exporter_config=$(
    printf '%s\n' "$NODE_EXPORTER_CONFIG" \
      | jq \
        --raw-output \
        '
          .collector
          | to_entries
          | map(if .value == true then ("--collector."+.key) else ("--no-collector."+.key) end)
          | join(" ")
        '
  ) || FATAL "Error reading Node exporter configuration"

  # Install
  INSTALL_NODE_EXPORTER_SKIP_ENABLE=true \
    INSTALL_NODE_EXPORTER_SKIP_START=true \
    INSTALL_NODE_EXPORTER_SKIP_DOWNLOAD="$AIRGAP_ENV" \
    INSTALL_NODE_EXPORTER_VERSION="$_node_exporter_version" \
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

  _k3s_kubeconfig_file="/etc/rancher/k3s/k3s.yaml"
  _kubeconfig_file="$(user_home_dir)/.kube/config"
  _certs_dir="$RECLUSTER_ETC_DIR/certs"
  _server_service_name=recluster.server
  _server_env_file="$RECLUSTER_ETC_DIR/server.env"
  _server_dir="$RECLUSTER_OPT_DIR/server"

  _wait_k3s_kubeconfig_file_creation() {
    _k3s_kubeconfig_dir=$(dirname "$_k3s_kubeconfig_file")
    _k3s_kubeconfig_file_name=$(basename "$_k3s_kubeconfig_file")

    if [ -f "$_k3s_kubeconfig_file" ]; then
      # kubeconfig already exists
      INFO "K3s kubeconfig file already generated at '$_k3s_kubeconfig_file'"
    else
      # kubeconfig wait generation
      INFO "Waiting K3s kubeconfig file at '$_k3s_kubeconfig_file'"

      _k3s_kubeconfig_generated=false
      while [ "$_k3s_kubeconfig_generated" = false ]; do
        read -r _dir _action _file << EOF
$(inotifywait -e create,close_write,moved_to --quiet "$_k3s_kubeconfig_dir")
EOF
        DEBUG "File '$_file' notify '$_action' at '$_dir'"
        if [ "$_file" = "$_k3s_kubeconfig_file_name" ]; then
          DEBUG "K3s kubeconfig file generated"
          _k3s_kubeconfig_generated=true
        fi
      done
    fi
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
  INFO "Copying K3s kubeconfig from '$_k3s_kubeconfig_file' to '$_kubeconfig_file'"
  _kubeconfig_dir=$(dirname "$_kubeconfig_file")
  [ -d "$_kubeconfig_dir" ] || $SUDO mkdir "$_kubeconfig_dir"
  yes | $SUDO cp --force "$_k3s_kubeconfig_file" "$_kubeconfig_file"
  $SUDO chown "$USER:$USER" "$_kubeconfig_file"
  $SUDO chmod 644 "$_kubeconfig_file"

  # Setup database
  INFO "Setting up database"
  DEBUG "Stopping database"
  case $INIT_SYSTEM in
    openrc) $SUDO rc-service postgresql stop > /dev/null 2>&1 || $SUDO rc-service postgresql zap > /dev/null 2>&1 || : ;;
    systemd) $SUDO systemctl stop postgresql > /dev/null 2>&1 || $SUDO systemctl kill postgresql > /dev/null 2>&1 || : ;;
    *) FATAL "Unknown init system '$INIT_SYSTEM'" ;;
  esac

  DEBUG "Removing PostgreSQL data directory"
  $SUDO rm -rf /var/lib/postgresql

  case $INIT_SYSTEM in
    openrc)
      INFO "openrc: Creating PostgreSQL database cluster"
      $SUDO rc-service postgresql setup

      INFO "openrc: Starting database"
      $SUDO rc-service postgresql start
      wait_database_reachability
      ;;
    systemd)
      INFO "systemd: Creating PostgreSQL database cluster"
      # TODO
      FATAL "systemd: Creating PostgreSQL database cluster not implemented"

      INFO "systemd: Starting database"
      $SUDO systemctl start postgresql
      wait_database_reachability
      ;;
    *) FATAL "Unknown init system '$INIT_SYSTEM'" ;;
  esac

  DEBUG "Removing database 'recluster'"
  $SUDO su postgres -c 'psql -c "DROP DATABASE IF EXISTS recluster;"'
  DEBUG "Removing user 'recluster'"
  $SUDO su postgres -c 'psql -c "DROP USER IF EXISTS recluster;"'
  DEBUG "Creating database 'recluster'"
  $SUDO su postgres -c 'psql -c "CREATE DATABASE recluster;"'
  DEBUG "Creating user 'recluster'"
  $SUDO su postgres -c 'psql -c "CREATE USER recluster WITH PASSWORD '\''password'\'';"'
  DEBUG "Defining access privileges for 'recluster'"
  $SUDO su postgres -c 'psql -c "GRANT ALL PRIVILEGES ON DATABASE recluster TO recluster;"'
  $SUDO su postgres -c 'psql -c "GRANT ALL PRIVILEGES ON SCHEMA public TO recluster;"'
  $SUDO su postgres -c 'psql -c "ALTER USER recluster SUPERUSER;"'
  $SUDO su postgres -c 'psql -c "ALTER USER recluster CREATEDB"'

  # Copy server
  INFO "Copying server from '$DIRNAME/server' to '$_server_dir'"
  [ -d "$_server_dir" ] || $SUDO mkdir -p "$_server_dir"
  yes | $SUDO cp --force --archive "$DIRNAME/server/." "$_server_dir"
  $SUDO chown --recursive root:root "$_server_dir"
  $SUDO chmod --recursive 755 "$_server_dir"

  # Copy server env file
  INFO "Copying server environment file from '$RECLUSTER_SERVER_ENV_FILE' to '$_server_env_file'"
  yes | $SUDO cp --force "$RECLUSTER_SERVER_ENV_FILE" "$_server_env_file"
  $SUDO chown root:root "$_server_env_file"
  $SUDO chmod 600 "$_server_env_file"

  # Setup server
  INFO "Setting up server"
  DEBUG "Installing server dependencies"
  $SUDO npm --prefix "$_server_dir" ci --ignore-scripts
  yes | $SUDO cp --force "$_server_env_file" "$_server_dir/.env"
  DEBUG "Generating database assets"
  $SUDO npm --prefix "$_server_dir" run db:generate
  INFO "Applying migrations to production database"
  $SUDO npm --prefix "$_server_dir" run db:deploy
  DEBUG "Removing development dependencies"
  $SUDO npm --prefix "$_server_dir" prune --production
  $SUDO rm -rf "$_server_dir/prisma"
  $SUDO rm -f "$_server_dir/.env"

  # Server service
  INFO "Constructing server service '$_server_service_name'"
  case $INIT_SYSTEM in
    openrc)
      _openrc_server_service_file="/etc/init.d/$_server_service_name"
      _openrc_server_log_file="/var/log/$_server_service_name.log"

      INFO "openrc: Constructing server service file '$_openrc_server_service_file'"
      $SUDO tee $_openrc_server_service_file > /dev/null << EOF
#!/sbin/openrc-run

description="reCluster server"

depend() {
  after network-online
}

supervisor=supervise-daemon
name=recluster.server
command="/usr/bin/node $_server_dir/build/main.js"

output_log=$_openrc_server_log_file
error_log=$_openrc_server_log_file

pidfile=/var/run/recluster.server.pid
respawn_delay=3
respawn_max=0

set -o allexport
# inline skip
source $_server_env_file
set +o allexport
EOF
      $SUDO chown root:root $_openrc_server_service_file
      $SUDO chmod 755 $_openrc_server_service_file

      $SUDO tee "/etc/logrotate.d/$_server_service_name" > /dev/null << EOF
$_openrc_server_log_file {
	missingok
	notifempty
	copytruncate
}
EOF

      INFO "openrc: Starting server"
      $SUDO rc-service recluster.server restart
      wait_server_reachability
      ;;
    systemd)
      _systemd_server_service_file="/etc/systemd/system/$_server_service_name.service"

      INFO "systemd: Constructing server service file '$_systemd_server_service_file'"
      $SUDO tee $_systemd_server_service_file > /dev/null << EOF
[Unit]
Description=reCluster server
After=network-online.target network.target
Wants=network-online.target network.target

[Service]
Type=simple
EnvironmentFile=$_server_env_file
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity
TimeoutStartSec=0
Restart=always
RestartSec=3s
ExecStart=/usr/bin/node $_server_dir/build/main.js
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=recluster.server

[Install]
WantedBy=multi-user.target
EOF
      $SUDO chown root:root $_systemd_server_service_file
      $SUDO chmod 755 $_systemd_server_service_file

      $SUDO systemctl daemon-reload > /dev/null

      INFO "systemd: Starting server"
      $SUDO systemctl restart recluster.server
      wait_server_reachability
      ;;
    *) FATAL "Unknown init system '$INIT_SYSTEM'" ;;
  esac
}

# Install reCluster
install_recluster() {
  # Files
  _k3s_config_file=/etc/rancher/k3s/config.yaml
  _recluster_config_file="$RECLUSTER_ETC_DIR/config.yaml"
  _node_token_file="$RECLUSTER_ETC_DIR/token"
  _commons_script_file="$RECLUSTER_OPT_DIR/__commons.sh"
  _bootstrap_script_file="$RECLUSTER_OPT_DIR/bootstrap.sh"
  _shutdown_script_file="$RECLUSTER_OPT_DIR/shutdown.sh"
  # Configuration
  _node_label_id="recluster.io/id="
  _service_name=recluster
  # Registration data
  _registration_data=
  _node_token=
  _node_id=
  _node_name=

  spinner_start "Installing reCluster"

  # Write configuration
  printf '%s\n' "$CONFIG" \
    | jq '.recluster' \
    | yq e --no-colors --prettyPrint - \
    | yq e --no-colors '(.. | select(tag == "!!str")) style="double"' - \
    | $SUDO tee "$_recluster_config_file" > /dev/null
  $SUDO chown root:root "$_recluster_config_file"
  $SUDO chmod 600 "$_recluster_config_file"

  # Register node
  node_registration
  _registration_data=$RETVAL
  _node_token=$(printf '%s\n' "$_registration_data" | jq --raw-output '.token')
  _node_id=$(printf '%s\n' "$_registration_data" | jq --raw-output '.decoded.payload.id')

  # Write node token
  printf '%s\n' "$_node_token" | $SUDO tee "$_node_token_file" > /dev/null
  $SUDO chown root:root "$_node_token_file"
  $SUDO chmod 600 "$_node_token_file"

  # K3s node name
  _kind=$(printf '%s\n' "$CONFIG" | jq --raw-output '.kind')
  case $_kind in
    controller | worker) _node_name="$_kind.$_node_id" ;;
    *) FATAL "Unknown kind '$_kind'" ;;
  esac

  # K3s label
  _node_label_id="${_node_label_id}${_node_id}"

  # Update K3s configuration
  INFO "Updating K3s configuration '$_k3s_config_file'"
  $SUDO yq e '.node-name = "'"$_node_name"'" | .node-label += ["'"$_node_label_id"'"] | (.. | select(tag == "!!str")) style="double"' -i "$_k3s_config_file"

  #
  # Scripts
  #
  # Commons script
  INFO "Constructing '$(basename "$_commons_script_file")' script"
  $SUDO tee "$_commons_script_file" > /dev/null << EOF
#!/usr/bin/env sh

# Fail on error
set -o errexit
# Disable wildcard character expansion
set -o noglob

# ================
# CONFIGURATION
# ================
# Configuration file
RECLUSTER_CONFIG_FILE="$_recluster_config_file"
# Node token file
RECLUSTER_NODE_TOKEN_FILE="$_node_token_file"

# ================
# GLOBALS
# ================
# Config
RECLUSTER_CONFIG=
# Node token
RECLUSTER_NODE_TOKEN=

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
# Debug log message
DEBUG() {
  printf '[DEBUG] %s\n' "\$@"
}

# ================
# FUNCTIONS
# ================
# Read configuration file
read_config() {
  [ -z "\$RECLUSTER_CONFIG" ] || return 0

  DEBUG "Reading reCluster configuration file '\$RECLUSTER_CONFIG_FILE'"
  [ -f \$RECLUSTER_CONFIG_FILE ] || FATAL "reCluster configuration file '\$RECLUSTER_CONFIG_FILE' not found"
  RECLUSTER_CONFIG=\$(yq e --output-format=json --no-colors '.' "\$RECLUSTER_CONFIG_FILE") || FATAL "Error reading reCluster configuration file '\$RECLUSTER_CONFIG_FILE'"
}

# Read node token file
read_node_token() {
  [ -z "\$RECLUSTER_NODE_TOKEN" ] || return 0

  DEBUG "Reading node token file '\$RECLUSTER_NODE_TOKEN_FILE'"
  [ -f \$RECLUSTER_NODE_TOKEN_FILE ] || FATAL "Node token file '\$RECLUSTER_NODE_TOKEN_FILE' not found"
  RECLUSTER_NODE_TOKEN=\$(cat "\$RECLUSTER_NODE_TOKEN_FILE") || FATAL "Error reading node token file '\$RECLUSTER_NODE_TOKEN_FILE'"
}

# Update node status
# @param \$1 Status
update_node_status() {
  read_config
  read_node_token

  _status=\$1
  _server_url=\$(printf '%s\n' "\$RECLUSTER_CONFIG" | jq --exit-status --raw-output '.server') || FATAL "reCluster configuration requires server URL"
  _server_url="\$_server_url/graphql"
  _request_data=\$(
    jq \\
      --null-input \\
      --compact-output \\
      --arg status "\$_status" \\
      '
        {
          "query": "mutation (\$data: UpdateStatusInput!){ updateStatus(data: \$data) { id } }",
          "variables": { "data": { "status": \$status } }
        }
      '
  )
  _response_data=

  DEBUG "Updating node status '\$_status' at '\$_server_url'"

  # Send update request
EOF

  case $DOWNLOADER in
    curl)
      $SUDO tee -a "$_commons_script_file" > /dev/null << EOF
      _response_data=\$(
        curl --fail --silent --location --show-error \\
          --request POST \\
          --header 'Content-Type: application/json' \\
          --header 'Authorization: Bearer '"\$RECLUSTER_NODE_TOKEN"'' \\
          --url "\$_server_url" \\
          --data "\$_request_data"
      ) || FATAL "Error sending update node status request to '\$_server_url'"
EOF
      ;;
    wget)
      $SUDO tee -a "$_commons_script_file" > /dev/null << EOF
      _response_data=\$(
        wget --quiet --output-document=- \\
          --header='Content-Type: application/json' \\
          --header 'Authorization: Bearer '"\$RECLUSTER_NODE_TOKEN"'' \\
          --post-data="\$_request_data" \\
          "\$_server_url" 2>&1
      ) || FATAL "Error sending update node status request to '\$_server_url'"
EOF
      ;;
    *) FATAL "Unknown downloader '$DOWNLOADER'" ;;
  esac

  $SUDO tee -a "$_commons_script_file" > /dev/null << EOF
  # Check error response
  if printf '%s\n' "\$_response_data" | jq --exit-status 'has("errors")' > /dev/null 2>&1; then
    FATAL "Error updating node status at '\$_server_url':\\n\$(printf '%s\n' "\$_response_data" | jq .)"
  fi
}

# Assert URL is reachable
# @param \$1 URL address
# @param \$2 Timeout in seconds
assert_url_reachability() {
  # URL address
  _url_address=\$1
  # Timeout in seconds
  _timeout=\${2:-10}

  DEBUG "Testing URL '\$_url_address' reachability"
EOF

  case $DOWNLOADER in
    curl)
      $SUDO tee -a "$_commons_script_file" > /dev/null << EOF
  curl --fail --silent --show-error --max-time "\$_timeout" "\$_url_address" > /dev/null || FATAL "URL address '\$_url_address' is unreachable"
EOF
      ;;
    wget)
      $SUDO tee -a "$_commons_script_file" > /dev/null << EOF
  wget --quiet --spider --timeout="\$_timeout" --tries=1 "\$_url_address" 2>&1 || FATAL "URL address '\$_url_address' is unreachable"
EOF
      ;;
    *) FATAL "Unknown downloader '$DOWNLOADER'" ;;
  esac

  $SUDO tee -a "$_commons_script_file" > /dev/null << EOF
}

# Wait database reachability
wait_database_reachability() {
  _wait_database_max_attempts=3
  _wait_database_sleep=3

  INFO "Waiting database reachability"
  while [ "\$_wait_database_max_attempts" -gt 0 ]; do
    if (su postgres -c "pg_isready"); then
      DEBUG "Database is reachable"
      break
    fi

    DEBUG "Database is not reachable, sleeping \$_wait_database_sleep seconds"
    sleep "\_wait_database_sleep"
    _wait_database_max_attempts=\$((_wait_database_max_attempts = _wait_database_max_attempts - 1))
  done
  [ "\$_wait_database_max_attempts" -gt 0 ] || FATAL "Database is not reachable, maximum attempts reached"
}

# Wait server reachability
wait_server_reachability() {
  read_config

  _wait_server_max_attempts=3
  _wait_server_sleep=3
  _server_url=\$(printf '%s\n' "\$RECLUSTER_CONFIG" | jq --exit-status --raw-output '.server') || FATAL "reCluster configuration requires server URL"
  _server_url="\$_server_url/health"

  INFO "Waiting server reachability"
  while [ "\$_wait_server_max_attempts" -gt 0 ]; do
    if (assert_url_reachability "\$_server_url" > /dev/null 2>&1); then
      DEBUG "Server is reachable"
      break
    fi

    DEBUG "Server is not reachable, sleeping \$_wait_server_sleep seconds"
    sleep "\$_wait_server_sleep"
    _wait_server_max_attempts=\$((_wait_server_max_attempts = _wait_server_max_attempts - 1))
  done
  [ "\$_wait_server_max_attempts" -gt 0 ] || FATAL "Server is not reachable, maximum attempts reached"
}

# Manage services
# @param \$1 Operation
manage_services() {
  _op=\$1
  _op_message=

  case \$_op in
    start) _op_message="Starting" ;;
    stop) _op_message="Stopping" ;;
    restart) _op_message="Restarting" ;;
    * ) FATAL "Unknown operation '\$_op'"
  esac
EOF

  case $INIT_SYSTEM in
    openrc)
      if [ "$INIT_CLUSTER" = true ]; then
        $SUDO tee -a "$_commons_script_file" > /dev/null << EOF
  INFO "openrc: \$_op_message Database"
  rc-service postgresql \$_op
  { [ "\$_op" = start ] || [ "\$_op" = restart ]; } && wait_database_reachability
  INFO "openrc: \$_op_message Server"
  rc-service recluster.server \$_op
  { [ "\$_op" = start ] || [ "\$_op" = restart ]; } && wait_server_reachability
EOF
      fi
      $SUDO tee -a "$_commons_script_file" > /dev/null << EOF
  INFO "openrc: \$_op_message Node exporter"
  rc-service node_exporter \$_op
  INFO "openrc: \$_op_message K3s"
  rc-service k3s-recluster \$_op
EOF
      ;;
    systemd)
      if [ "$INIT_CLUSTER" = true ]; then
        $SUDO tee -a "$_commons_script_file" > /dev/null << EOF
  INFO "systemd: \$_op_message Database"
  systemctl \$_op postgresql
  { [ "\$_op" = start ] || [ "\$_op" = restart ]; } && wait_database_reachability
  INFO "systemd: \$_op_message Server"
  systemctl \$_op recluster.server
  { [ "\$_op" = start ] || [ "\$_op" = restart ]; } && wait_server_reachability
EOF
      fi
      $SUDO tee -a "$_commons_script_file" > /dev/null << EOF
  INFO "systemd: \$_op_message Node exporter"
  systemctl \$_op node_exporter
  INFO "systemd: \$_op_message K3s"
  systemctl \$_op k3s-recluster
EOF
      ;;
    *) FATAL "Unknown init system '$INIT_SYSTEM'" ;;
  esac

  $SUDO tee -a "$_commons_script_file" > /dev/null << EOF
}
EOF
  $SUDO chown root:root "$_commons_script_file"
  $SUDO chmod 755 "$_commons_script_file"

  # Bootstrap script
  INFO "Constructing '$(basename "$_bootstrap_script_file")' script"
  $SUDO tee "$_bootstrap_script_file" > /dev/null << EOF
#!/usr/bin/env sh

# Load commons
# inline skip
. "$_commons_script_file"

# ================
# MAIN
# ================
{
EOF
  if [ "$INIT_CLUSTER" = true ]; then
    $SUDO tee -a "$_bootstrap_script_file" > /dev/null << EOF
  manage_services start
  update_node_status ACTIVE
EOF
  else
    $SUDO tee -a "$_bootstrap_script_file" > /dev/null << EOF
  update_node_status ACTIVE
  manage_services start
EOF
  fi
  $SUDO tee -a "$_bootstrap_script_file" > /dev/null << EOF
}
EOF
  $SUDO chown root:root "$_bootstrap_script_file"
  $SUDO chmod 755 "$_bootstrap_script_file"

  # Shutdown script
  INFO "Constructing '$(basename "$_shutdown_script_file")' script"
  $SUDO tee "$_shutdown_script_file" > /dev/null << EOF
#!/usr/bin/env sh

# Load commons
# inline skip
. "$_commons_script_file"

# ================
# MAIN
# ================
{
  update_node_status INACTIVE
  manage_services stop
}
EOF
  $SUDO chown root:root "$_shutdown_script_file"
  $SUDO chmod 755 "$_shutdown_script_file"

  #
  # Services
  #
  # reCluster service
  INFO "Constructing reCluster service '$_service_name'"
  case $INIT_SYSTEM in
    openrc)
      _openrc_service_file="/etc/init.d/$_service_name"

      INFO "openrc: Constructing reCluster service file '$_openrc_service_file'"
      $SUDO tee "$_openrc_service_file" > /dev/null << EOF
#!/sbin/openrc-run

description="reCluster"

depend() {
  need net
  use dns
  after firewall
  after network-online
  want cgroups
}

start() {
  /usr/bin/env sh $_bootstrap_script_file
}

stop() {
  /usr/bin/env sh $_shutdown_script_file
}
EOF
      $SUDO chown root:root "$_openrc_service_file"
      $SUDO chmod 0755 "$_openrc_service_file"

      INFO "openrc: Enabling reCluster service '$_service_name' at startup"
      $SUDO rc-update add "$_service_name" default > /dev/null
      ;;
    systemd)
      _systemd_service_file="/etc/systemd/system/$_service_name.service"

      INFO "systemd: Constructing reCluster service file '$_systemd_service_file'"
      $SUDO tee "$_systemd_service_file" > /dev/null << EOF
[Unit]
Description=reCluster
After=network-online.target network.target
Wants=network-online.target network.target

[Service]
Type=oneshot
ExecStart=/usr/bin/env sh $_bootstrap_script_file
ExecStop=/usr/bin/env sh $_shutdown_script_file

[Install]
WantedBy=multi-user.target
EOF
      $SUDO chown root:root "$_systemd_service_file"
      $SUDO chmod 0755 "$_systemd_service_file"

      INFO "systemd: Enabling reCluster service '$_service_name' at startup"
      $SUDO systemctl enable "$_service_name" > /dev/null
      $SUDO systemctl daemon-reload > /dev/null
      ;;
    *) FATAL "Unknown init system '$INIT_SYSTEM'" ;;
  esac

  spinner_stop

  # Success
  INFO "Successfully installed reCluster"
}

# Start recluster
start_recluster() {
  spinner_start "Starting reCluster"

  case $INIT_SYSTEM in
    openrc)
      INFO "openrc: Starting reCluster"
      $SUDO rc-service recluster restart
      ;;
    systemd)
      INFO "systemd: Starting reCluster"
      $SUDO systemctl restart recluster.service
      ;;
    *) FATAL "Unknown init system '$INIT_SYSTEM'" ;;
  esac

  spinner_stop
}

# Configure K8s
configure_k8s() {
  [ "$INIT_CLUSTER" = true ] || return 0
  _k8s_timeout="2m"
  _etc_hosts="/etc/hosts"
  _loadbalancer_dir="$DIRNAME/configs/k8s/loadbalancer"
  _loadbalancer_deployment="$_loadbalancer_dir/deployment.yaml"
  _loadbalancer_config="$_loadbalancer_dir/config.yaml"
  _registry_dir="$DIRNAME/configs/k8s/registry"
  _registry_deployment="$_registry_dir/deployment.yaml"
  _registry_k3s="$DIRNAME/configs/k3s/registries.yaml"
  _autoscaler_ca_dir="$DIRNAME/configs/k8s/autoscaler/ca"
  _autoscaler_ca_deployment="$_autoscaler_ca_dir/deployment.yaml"
  _autoscaler_ca_archive="$AUTOSCALER_DIR/cluster-autoscaler.$ARCH.tar.gz"

  assert_cmd kubectl
  [ -f "$_loadbalancer_deployment" ] || "Load Balancer deployment file '$_loadbalancer_deployment' does not exists"
  [ -f "$_loadbalancer_config" ] || FATAL "Load Balancer configuration file '$_loadbalancer_config' does not exists"
  [ -f "$_registry_deployment" ] || FATAL "Registry deployment file '$_registry_deployment' does not exists"
  [ -f "$_registry_k3s" ] || FATAL "Registry K3s file '$_registry_k3s' does not exists"
  [ -f "$_autoscaler_ca_deployment" ] || FATAL "Autoscaler CA deployment file '$_autoscaler_ca_deployment' does not exists"
  [ -f "$_autoscaler_ca_archive" ] || FATAL "Autoscaler CA archive file '$_autoscaler_ca_archive' does not exists"

  _registry_mirror=$($SUDO yq e --no-colors '.mirrors | to_entries | .[0].key' "$_registry_k3s") || FATAL "Error reading Registry mirror from '$_registry_k3s'"
  _registry_mirror_host=$(printf '%s\n' "$_registry_mirror" | sed 's/\([^:/]*\).*/\1/')
  _registry_endpoint_host=$($SUDO yq e --no-colors '.mirrors | to_entries | .[0].value.endpoint[0]' "$_registry_k3s" | sed 's/[^/]*\/\/\([^@]*@\)\?\([^:/]*\).*/\2/') || FATAL "Error reading Registry endpoint from '$_registry_k3s'"
  _registry_etc_host="$_registry_endpoint_host $_registry_mirror_host"
  _autoscaler_ca_tag="$_registry_mirror/recluster/cluster-autoscaler"
  _autoscaler_ca_tag_version="$_autoscaler_ca_tag:$AUTOSCALER_VERSION"
  _autoscaler_ca_tag_latest="$_autoscaler_ca_tag:latest"

  spinner_start "Configuring K8s"

  # Hosts add
  DEBUG "Adding host entry '$_registry_etc_host' to '$_etc_hosts'"
  printf '%s\n' "$_registry_etc_host" | $SUDO tee -a "$_etc_hosts" > /dev/null

  # K8s
  wait_k8s_reachability

  # Load Balancer
  INFO "Applying Load Balancer deployment '$_loadbalancer_deployment'"
  $SUDO kubectl apply -f "$_loadbalancer_deployment"
  INFO "Waiting Load Balancer is ready"
  $SUDO kubectl wait \
    --namespace metallb-system \
    --for=condition=ready pod \
    --selector=app=metallb \
    "--timeout=$_k8s_timeout"
  INFO "Applying Load Balancer configuration '$_loadbalancer_config'"
  $SUDO kubectl apply -f "$_loadbalancer_config"

  # Registry
  INFO "Applying Registry deployment '$_registry_deployment'"
  $SUDO kubectl apply -f "$_registry_deployment"
  INFO "Waiting Registry is ready"
  $SUDO kubectl wait \
    --namespace registry-system \
    --for=condition=ready pod \
    --selector=app=registry \
    "--timeout=$_k8s_timeout"

  # Autoscaler CA
  # TODO Do for all images
  INFO "Loading Autoscaler CA image '$_autoscaler_ca_archive'"
  $SUDO docker load --input "$_autoscaler_ca_archive"
  INFO "Tagging Autoscaler CA image '$_autoscaler_ca_tag_version'"
  $SUDO docker tag "recluster/cluster-autoscaler:latest" "$_autoscaler_ca_tag_version"
  INFO "Tagging Autoscaler CA image '$_autoscaler_ca_tag_latest'"
  $SUDO docker tag "recluster/cluster-autoscaler:latest" "$_autoscaler_ca_tag_latest"
  INFO "Pushing Autoscaler CA image(s) '$_autoscaler_ca_tag'"
  $SUDO docker push --all-tags "$_autoscaler_ca_tag"
  INFO "Applying Autoscaler CA deployment '$_autoscaler_ca_deployment'"
  $SUDO kubectl apply -f "$_autoscaler_ca_deployment"
  INFO "Waiting Autoscaler CA is ready"
  $SUDO kubectl wait \
    --namespace kube-system \
    --for=condition=ready pod \
    --selector=app=cluster-autoscaler \
    "--timeout=$_k8s_timeout"

  # Hosts remove
  DEBUG "Removing host entry '$_registry_etc_host' from '$_etc_hosts'"
  $SUDO sed -i "/$_registry_etc_host/d" "$_etc_hosts"

  spinner_stop
}

# ================
# MAIN
# ================
{
  parse_args "$@"
  verify_system
  setup_system
  read_system_info
  run_benchmarks
  read_power_consumptions
  finalize_node_facts
  install_k3s
  install_node_exporter
  cluster_init
  install_recluster
  start_recluster
  configure_k8s
  INFO "--> SUCCESS <--"
}

# Installation

reCluster installation.

## Requirements

See [Installation requirements](./installation_requirements.md) for more information.

## Steps

1. Download the most recent `recluster.tar.gz` from [GitHub release](https://github.com/carlocorradini/reCluster/releases/latest)

   ```sh
   wget https://github.com/carlocorradini/reCluster/releases/latest/download/recluster.tar.gz
   ```

1. Unzip `recluster.tar.gz`

   ```sh
   tar -xvzf recluster.tar.gz
   ```

1. Generate certificates

   > **Info**: See [certs](../scripts/README.md#📑-certssh) for more information

   ```sh
   _registry_ip="10.0.0.100" # TODO Change
   _out_dir="configs/certs"
   
   # Create certs directory
   mkdir "$_out_dir"
   # Generate certificates
   ./scripts/certs.sh \
     --registry-ip "$_registry_ip" \
     --out-dir "$_out_dir"
   ```

1. Copy the text from `configs/certs/ssh.crt` and put it in the `ssh_authorized_keys` property of `configs/config.yaml` (`ssh-ed25519 ...`)

   > **Warning**: All files from `configs/certs` should be copied and saved in a well known and secure place

1. Start a PostgreSQL database instance

   > **Note**: Visit <https://www.postgresql.org> for more information

1. Edit [configuration files](../configs/) to match your environment

   > **Note**: Remember to change `DATABASE_URL` in [`server.env`](../configs/server.env)

1. Place all files and directories on a flash drive

   > **Note**: See <https://askubuntu.com/a/802675/1149269> for more information

1. Install [Alpine Linux](../distributions/alpine/) distribution

   > **Note**: Other [distributions](../distributions/) are available

   > **Note**: For further information on how to install a distribution, see its accompanying `README.md` file

   > **Note**: Remember to connect the Power Consumption device

1. For every node

   1. Mount the flash drive on the node

   1. Launch `install.sh` installation script

      > See [Installation script](./installation_script.md) for more information

      - Controller

        > **Warning**: Argument `--init-cluster` and `cluster-init: true` property of [`configs/k3s.controller.yaml`](../configs/k3s.controller.yaml) must be set only for the first controller

        > **Note**: `kind` property of [`configs/config.yaml`](../configs/config.yaml) must be set to `controller`

        Controller installation.

        ```sh
        ./install.sh \
          --k3s-config-file configs/k3s.controller.yaml \
          --init-cluster \
          ...
        ```

      - Worker

        > **Note**: `kind` property of [`configs/config.yaml`](../configs/config.yaml) must be set to to `worker`

        Worker installation.

        ```sh
        ./install.sh \
          --k3s-config-file configs/k3s.worker.yaml \
          ...
        ```

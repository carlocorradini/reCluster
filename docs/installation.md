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

   > **Warning**: Change `_ssh_passphrase` and `_token_passphrase` passphrase

   > **Info**: See [certs](../scripts/README.md#📑-certssh) for more information

   ```sh
   _ssh_passphrase="password"
   _token_passphrase="password"
   _out_dir="configs/certs"
   
   # Create certs directory
   mkdir "$_out_dir"
   # Generate certificates
   ./scripts/certs.sh \
     --ssh-passphrase "$_ssh_passphrase" \
     --token-passphrase "$_token_passphrase" \
     --out-dir "$_out_dir"
   ```

1. Copy the text from `configs/certs/ssh.pub` and put it in the `ssh_authorized_keys` property of `configs/config.yaml` (`ssh-ed25519 ...`)

   > **Warning**: All files from `configs/certs` should be copied and saved in a well known and secure place

1. Start a PostgreSQL database instance

   > **Note**: Visit <https://www.postgresql.org> for more information

1. Edit [configuration files](../configs/) to match your environment

   > **Note**: Remember to change `DATABASE_URL` in [`server.env`](../configs/server.env)

1. Place all files and directories on a flash drive

   > **Note**: See <https://askubuntu.com/a/802675/1149269> for more information

1. Pick a Linux distribution from [`distributions`](../distributions/) and install it

   > **Note**: For further information on how to install a distribution, see its accompanying `README.md` file

   > **Note**: Remember to connect the Power Consumption device

1. Mount the flash drive on the node

1. Launch `install.sh` installation script

   > See [Installation script](./installation_script.md) for more information

1. Congratulations! You have successfully installed reCluster

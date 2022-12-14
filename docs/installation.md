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
   _out_dir="/tmp/recluster"
   
   mkdir "$_out_dir"
   tar -xvzf recluster.tar.gz -C "$_out_dir"
   ```

1. Change working directory

   ```sh
   _cwd="/tmp/recluster"
   
   cd "$_cwd"
   ```

1. Generate certificates

   > **Info**: See [certs](../scripts/README.md#📑-certssh) for more information

   ```sh
   _registry_ip='192.168.0.202' # TODO Change
   _out_dir='configs/certs'
   
   ./scripts/certs.sh \
     --registry-ip "$_registry_ip" \
     --out-dir "$_out_dir"
   ```

1. Edit [`scripts/configs.config.yaml`](../scripts/configs.config.yaml) to match your environment

1. Generate configurations

   > **Info**: See [configs](../scripts/README.md#📑-configssh) for more information

   ```sh
   _config_file='./scripts/configs.config.yaml'
   
   ./scripts/configs.sh \
     --config-file "$_config_file" \
     --overwrite
   ```

1. Copy all files and directories on a flash drive

   1. Mount the flash drive

      1. Find flash drive name

         ```sh
         fdisk -l
         ```

      1. Create mount directory

         ```sh
         _mnt="/mnt/usb"
         
         mkdir "$_mnt"
         ```

      1. Mount flash drive

         ```sh
         _dev="/dev/sdX"
         _mnt="/mnt/usb"
         
         mount "$_dev" "$_mnt"
         ```

   1. Copy files

      ```sh
      _recluster="/tmp/recluster"
      _mnt="/mnt/usb"
      
      cp --archive "$_recluster/." "$_mnt"
      ```

   1. Unmount the flash drive

      ```sh
      _dev="/dev/sdX"
      _mnt="/mnt/usb"
      
      umount "$_mnt"
      umount "$_dev"
      ```

1. Install [Alpine Linux](../distributions/alpine/) distribution

   > **Note**: Other [distributions](../distributions/) are available

   > **Note**: For further information on how to install a distribution, see its accompanying `README.md` file

   > **Note**: See [Installation requirements](./installation_requirements.md) for more information

1. For every node

   1. Mount the flash drive

      1. Find flash drive name

         ```sh
         fdisk -l
         ```

      1. Create mount directory

         ```sh
         _mnt="/mnt/usb"
         
         mkdir "$_mnt"
         ```

      1. Mount flash drive

         ```sh
         _dev="/dev/sdX"
         _mnt="/mnt/usb"
         
         mount "$_dev" "$_mnt"
         ```

   1. Change working directory

      ```sh
      _cwd="/mnt/usb"
      
      cd "$_cwd"
      ```

   1. Launch `install.sh` installation script

      > **Note**: See [Installation script](./installation_script.md) for more information

      - Controller

        > **Warning**: Argument `--init-cluster` and `cluster-init: true` property of [`configs/k3s/config.controller.yaml`](../configs/k3s/config.controller.yaml) must be set only for the first controller

        > **Note**: `kind` property of [`configs/recluster/config.controller.yaml`](../configs/configs/recluster/config.controller.yaml) must be set to `controller`

        Controller installation.

        ```sh
        ./install.sh \
          --config configs/recluster/config.controller.yaml \
          --k3s-config-file configs/k3s/config.controller.yaml \
          --init-cluster \
          ...
        ```

      - Worker

        > **Note**: `kind` property of [`configs/recluster/config.worker.yaml`](../configs/configs/recluster/config.worker.yaml) must be set to `worker`

        Worker installation.

        ```sh
        ./install.sh \
          --config configs/recluster/config.worker.yaml \
          --k3s-config-file configs/k3s.worker.yaml \
          ...
        ```

   1. Unmount the flash drive

      ```sh
      _dev="/dev/sdX"
      _mnt="/mnt/usb"
      
      umount "$_mnt"
      umount "$_dev"
      ```

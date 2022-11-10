# reCluster dependencies

## :warning: Warning

### Do not create/update/delete any files or folders manually except for [dependencies.yml](./dependencies.yml)

### For any dependency management, use [dependencies.sh](./dependencies.sh) script

## :clipboard: Workflow

> **Note**: Type `--help` for more information

1. Edit [dependencies.yml](./dependencies.yml)

2. Synchronize

   ```sh
   ./dependencies.sh \
     --sync
   ```

# reCluster scripts

reCluster scripts.

## :bookmark_tabs: [`certificates.sh`](./certificates.sh)

reCluster certificates script.

```sh
_ssh_passphrase="password"
_token_passphrase="password"

./certificates.sh \
  --ssh-passphrase "$_ssh_passphrase" \
  --token-passphrase "$_token_passphrase"
```

### Arguments

> **Note**: Type `--help` for more information

| **Name**                          | **Description**            |
| --------------------------------- | -------------------------- |
| `--help`                          | Show help message and exit |
| `--out-dir <DIRECTORY>`           | Output directory           |
| `--ssh-name <NAME>`               | SSH key name               |
| `--ssh-passphrase <PASSPHRARE>`   | SSH passphrase             |
| `--token-name <NAME>`             | Token key name             |
| `--token-passphrase <PASSPHRARE>` | Token passphrase           |

# reCluster

[![ci](https://github.com/carlocorradini/reCluster/actions/workflows/ci.yml/badge.svg)](https://github.com/carlocorradini/reCluster/actions/workflows/ci.yml)
[![codeql](https://github.com/carlocorradini/reCluster/actions/workflows/codeql.yml/badge.svg)](https://github.com/carlocorradini/reCluster/actions/workflows/codeql.yml)
[![Snyk](https://snyk.io/test/github/carlocorradini/reCluster/badge.svg)](https://snyk.io/test/github/carlocorradini/reCluster)
[![Codacy](https://app.codacy.com/project/badge/Grade/b95665f300d743de9f714530f764d126)](https://www.codacy.com/gh/carlocorradini/reCluster/dashboard?utm_source=github.com&utm_medium=referral&utm_content=carlocorradini/reCluster&utm_campaign=Badge_Grade)
[![semantic-release: angular](https://img.shields.io/badge/semantic--release-angular-e10079?logo=semantic-release)](https://github.com/semantic-release/semantic-release)
[![FOSSA](https://app.fossa.com/api/projects/git%2Bgithub.com%2Fcarlocorradini%2FreCluster.svg?type=small)](https://app.fossa.com/projects/git%2Bgithub.com%2Fcarlocorradini%2FreCluster?ref=badge_small)

reCluster is an architecture for a data center that actively reduces its impact and minimizes its resource utilization.

## :busts_in_silhouette: Members

| Name  |  Surname  |     Username     |    MAT     |
| :---: | :-------: | :--------------: | :--------: |
| Carlo | Corradini | `carlocorradini` | **223811** |

## :books: Documentation

See [docs](./docs/) directory for more information.

## :file_folder: Directories

> **Note**: Refer to the `README.md` of each directory for more information

| **Name**                            | **Description**                                                   |
| ----------------------------------- | ----------------------------------------------------------------- |
| [`.github`](./.github/)             | [GitHub](https://github.com) configuration                        |
| [`.husky`](./.husky/)               | [husky](https://typicode.github.io/husky) configuration           |
| [`.vscode`](./.vscode/)             | [Visual Studio Code](https://code.visualstudio.com) configuration |
| [`configs`](./configs/)             | Configuration files                                               |
| [`dependencies`](./dependencies/)   | Dependencies                                                      |
| [`distributions`](./distributions/) | Distributions                                                     |
| [`docs`](./docs/)                   | Documentation                                                     |
| [`scripts`](./scripts/)             | `Shell` scripts                                                   |
| [`server`](./server/)               | `reCluster` server                                                |

## :computer: Development

### Requirements

| **Name**  | **Homepage**             |
| --------- | ------------------------ |
| `Docker`  | <https://www.docker.com> |
| `K3d`     | <https://k3d.io>         |
| `Node.js` | <https://nodejs.org>     |
| `npm`     | <https://www.npmjs.com>  |

### Preparation

1. Clone

   ```sh
   git clone https://github.com/carlocorradini/reCluster.git
   cd reCluster
   ```

1. Scripts permissions

   ```sh
   find . -type f -name "*.sh" -print0 | xargs -0 chmod u+x
   ```

1. Execute [initialization](./scripts/init.sh) script

   ```sh
   ./scripts/init.sh
   ```

### Scripts

> **Note**: Execute with `npm run <NAME>`

| **Name** | **Description**  |
| -------- | ---------------- |
| `check`  | Check for errors |
| `fix`    | Fix errors       |

## License

This project is licensed under the [MIT](https://opensource.org/licenses/MIT) License. \
See [LICENSE](./LICENSE) file for details.

[![FOSSA](https://app.fossa.com/api/projects/git%2Bgithub.com%2Fcarlocorradini%2FreCluster.svg?type=large)](https://app.fossa.com/projects/git%2Bgithub.com%2Fcarlocorradini%2FreCluster?ref=badge_large)

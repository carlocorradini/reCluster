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

## :fountain_pen: References

- [_Conceptualising Resources-aware Higher Education Digital Infrastructure through Self-hosting: a Multi-disciplinary View_](https://doi.org/10.21428/bf6fb269.8b989f2c) \
  Angeli Lorenzo, Okur Özge, Corradini Carlo, Stolin Marcel, Huang Yilin, Brazier Frances and Marchese Maurizio \
  [Eighth Workshop on Computing within Limits 2022](https://computingwithinlimits.org/2022) \
  `doi:10.21428/bf6fb269.8b989f2c`

- [_reCluster: A resource-aware Kubernetes architecture for heterogeneous clusters_](https://github.com/carlocorradini/thesis/releases/download/v1.0.0/corradini_carlo_computer_science_2021_2022.pdf) \
  Carlo Corradini \
  Master's Thesis in Computer Science at the [University of Trento](https://www.unitn.it)

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

import config from '../.lintstagedrc.js';

module.exports = {
  ...config,
  '*.ts': 'eslint --fix'
};

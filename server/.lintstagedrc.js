const config = require('../.lintstagedrc.js');

module.exports = {
  ...config,
  '*.ts': ['eslint --fix', 'prettier --write']
};

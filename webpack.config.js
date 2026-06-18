'use strict';

const path = require('path');

module.exports = {
  mode: 'production',
  target: 'node',
  entry: path.resolve(__dirname, 'src/typed_i18n.bs.js'),
  output: {
    path: path.resolve(__dirname, 'lib'),
    filename: 'bundle.bs.js',
  },
  // The CLI is shipped as a single bundle, so inline everything.
  optimization: {
    // Keep variable names readable enough for debugging stack traces.
    minimize: true,
  },
};

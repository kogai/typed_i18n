#!/usr/bin/env node

'use strict';

const path = require('path');
const spawn = require('child_process').spawn;

const args = process.argv.slice(2);
const bin = path.join(__dirname, 'src/typed_i18n.bs.js');

spawn("node", [bin].concat(args), {
    stdio: 'inherit'
  })
  .on('exit', process.exit);

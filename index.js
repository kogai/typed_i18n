#!/usr/bin/env node 

'use strict';

const path = require('path');
const spawn = require('child_process').spawn;

const args = process.argv.slice(2);
const bin = path.join(__dirname, 'bin', `typed_i18n.${process.platform.charAt(0).toUpperCase() + process.platform.slice(1)}`);

spawn(bin, args, {stdio: 'inherit'})
  .on('exit', process.exit);
  
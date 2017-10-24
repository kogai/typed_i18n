#!/usr/bin/env node 

'use strict';

const path = require('path');
const spawn = require('child_process').spawn;

const input = process.argv.slice(2);
const bin = path.join(__dirname, './bin/typed_i18n');

console.log(bin);

spawn(bin, input, {stdio: 'inherit'})
  .on('exit', process.exit);
  
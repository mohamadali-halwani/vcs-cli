#!/usr/bin/env node

import chalk from "chalk";
import { program } from "commander";
import { basics, modes } from "./options.js";

console.log(chalk.bgBlue("✌️ Vim Cheat Sheet for Noobs"));

program
  .option("-b, --basics [term]", "Basic commands")
  .option("-m, --modes [term]", "Mode selections")
  .parse();

const options = program.opts();

if (!Object.keys(options).length) {
  basics();
  modes();
}

if (options.basics) basics(options.basics);
if (options.modes) modes(options.modes);

#!/usr/bin/env node

import chalk from "chalk";
import { program } from "commander";
import { basics, modes } from "./options.js";
import { printLines, searchEverything } from "./helpers.js";

console.log(chalk.bgBlue("✌️ Vim Cheat Sheet for Noobs"));

program
  .option("-b, --basics [term]", "Basic commands")
  .option("-m, --modes [term]", "Mode selections")
  .parse();

const options = program.opts();

if (!Object.keys(options).length) {
  if (program.args.length) {
    console.log(`
  Commands with "${program.args[0]}":

    ${printLines(searchEverything(program.args[0]))}`);
  } else {
    basics();
    modes();
  }
}

if (options.basics) basics(options.basics);
if (options.modes) modes(options.modes);

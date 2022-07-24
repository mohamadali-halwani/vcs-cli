import { printLines, searchWithin } from "./helpers.js";
import * as data from "./data.js";

export function basics(term) {
  if (typeof term === "string") {
    return console.log(`
  Commands with "${term}" in Basics:

    ${printLines(searchWithin(data.basics, term))}`);
  }

  return console.log(`
  Basics:
  
    ${printLines(data.basics)}`);
}

export function modes(term) {
  if (typeof term === "string") {
    return console.log(`
  Commands with "${term}" in Modes:

    ${printLines(searchWithin(data.modes, term))}`);
  }

  return console.log(`
  Modes:  

    ${printLines(data.modes)}`);
}

import { printLines, searchWithin } from "./helpers.js";

const basicData = {
  ":w": "write / save",
  ":q": "quit / exit",
  ":wq": "write and quit",
  ":q!": "quit without saving",
  esc: "(escape key) cancels a multi-character command",
};

const modesData = {
  i: "insert mode",
  v: "visual mode",
  V: "line visual mode (selected an entire line at a time)",
  "^v": "(crtl v) block visual mode (select code column by column)",
  R: "replace mode",
  esc: "(escape key) exit from current mode",
};

export function basics(term) {
  if (typeof term === "string") {
    return console.log(`
  Commands with "${term}" in Basics:

    ${printLines(searchWithin(basicData, term))}`);
  }

  return console.log(`
  Basics:
  
    ${printLines(basicData)}`);
}

export function modes(term) {
  if (typeof term === "string") {
    return console.log(`
  Commands with "${term}" in Modes:

    ${printLines(searchWithin(modesData, term))}`);
  }

  return console.log(`
  Modes:  

    ${printLines(modesData)}`);
}

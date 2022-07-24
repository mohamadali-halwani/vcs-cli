import chalk from "chalk";

function line(keys, description) {
  return `${chalk.bgGray(` ${keys} `)} ${description}`;
}

function printLines(data) {
  return Object.entries(data)
    .map(([key, value]) => line(key, value))
    .join(`\n    `);
}

function searchWithin(data, term) {
  return Object.fromEntries(
    Object.entries(data).filter(
      ([key, value]) => key.includes(term) || value.includes(term)
    )
  );
}

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

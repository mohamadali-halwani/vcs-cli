import chalk from "chalk";

export function line(keys, description) {
  return `${chalk.bgGray(` ${keys} `)} ${description}`;
}

export function printLines(data) {
  return Object.entries(data)
    .map(([key, value]) => line(key, value))
    .join(`\n    `);
}

export function searchWithin(data, term) {
  return Object.fromEntries(
    Object.entries(data).filter(
      ([key, value]) => key.includes(term) || value.includes(term)
    )
  );
}

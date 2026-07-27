// Fixed-order categorical palette — validated with the dataviz skill's
// scripts/validate_palette.js against this app's card surfaces. Never cycle
// or reassign by rank; a category always gets the same slot by index.
export const CATEGORICAL_PALETTE = [
  "#2a78d6", // blue
  "#eb6834", // orange
  "#1baf7a", // aqua
  "#eda100", // yellow
  "#e87ba4", // magenta
  "#008300", // green
  "#4a3aa7", // violet
  "#e34948", // red
] as const;

export const OTHER_SLOT_COLOR = "#898781";

export const INCOME_COLOR = "#1E9C6B";
export const EXPENSE_COLOR = "#C4573B";

export const CHART_GRID_COLOR = "#DFE6E1";
export const CHART_AXIS_COLOR = "#93A69B";

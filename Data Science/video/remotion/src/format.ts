/**
 * Prints a number with `d` decimals the way Python's format() does for the explorer page: the exact binary value is
 * rounded, and an exact tie goes to the even digit (JavaScript rounds a tie up, so 2.5 would otherwise read 3).
 * A negative zero prints without its sign. tests/test_number_parity.py compares this with Python on every finding.
 */
export const num = (v: number, d = 0): string => {
  const abs = Math.abs(v);
  const exact = abs.toFixed(d + 25);
  const beyond = exact.slice(exact.length - 25);
  let text = abs.toFixed(d);
  if (/^50*$/.test(beyond)) {
    const kept = exact.slice(0, exact.length - 25).replace(/\.$/, "");
    if (Number(kept.slice(-1)) % 2 === 0) text = kept;
  }
  const [whole, fraction] = text.split(".");
  const grouped = whole.replace(/\B(?=(\d{3})+(?!\d))/g, ",");
  const isZero = /^[0.]*$/.test(text);
  return `${v < 0 && !isZero ? "-" : ""}${grouped}${fraction ? `.${fraction}` : ""}`;
};

export const pct = (v: number, d = 1): string => `${num(v, d)}%`;

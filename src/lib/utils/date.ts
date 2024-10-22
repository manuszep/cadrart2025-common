export function dateToMysqlDate(d: Date): string {
  return d.toISOString().slice(0, 19).replace('T', ' ');
}

export function addWeeks(d: Date, weeks: number): Date {
  d.setDate(d.getDate() + weeks * 7);

  return d;
}

export function resetDateHMS(d: Date, endOfDay = false): Date {
  if (endOfDay) {
    d.setHours(23, 59, 59, 999);

    return d;
  }

  d.setHours(0, 0, 0, 0);

  return d;
}

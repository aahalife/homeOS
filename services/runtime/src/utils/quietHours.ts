export interface QuietHoursWindow {
  start: string;
  end: string;
}

export function isWithinQuietHours(now: Date, window: QuietHoursWindow): boolean {
  const startMinutes = parseMinutes(window.start);
  const endMinutes = parseMinutes(window.end);
  const nowMinutes = now.getHours() * 60 + now.getMinutes();

  if (startMinutes === endMinutes) {
    return false;
  }

  if (startMinutes < endMinutes) {
    return nowMinutes >= startMinutes && nowMinutes < endMinutes;
  }

  return nowMinutes >= startMinutes || nowMinutes < endMinutes;
}

export function nextQuietHoursEnd(now: Date, window: QuietHoursWindow): Date {
  const startMinutes = parseMinutes(window.start);
  const endMinutes = parseMinutes(window.end);
  const nowMinutes = now.getHours() * 60 + now.getMinutes();

  const endDate = new Date(now);
  endDate.setSeconds(0, 0);

  if (startMinutes < endMinutes) {
    if (nowMinutes < endMinutes) {
      endDate.setHours(Math.floor(endMinutes / 60), endMinutes % 60, 0, 0);
      return endDate;
    }
    endDate.setDate(endDate.getDate() + 1);
    endDate.setHours(Math.floor(endMinutes / 60), endMinutes % 60, 0, 0);
    return endDate;
  }

  if (nowMinutes < endMinutes) {
    endDate.setHours(Math.floor(endMinutes / 60), endMinutes % 60, 0, 0);
    return endDate;
  }

  endDate.setDate(endDate.getDate() + 1);
  endDate.setHours(Math.floor(endMinutes / 60), endMinutes % 60, 0, 0);
  return endDate;
}

function parseMinutes(value: string): number {
  const [hour, minute] = value.split(':').map((part) => parseInt(part, 10));
  if (Number.isNaN(hour) || Number.isNaN(minute)) {
    return 0;
  }
  return hour * 60 + minute;
}

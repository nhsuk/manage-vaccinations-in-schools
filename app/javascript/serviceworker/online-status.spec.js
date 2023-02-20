import {
  isOnline,
  setOfflineMode,
  setOnlineMode,
  toggleOnlineStatus,
} from "./online-status";

describe("isOnline", () => {
  test("works", () => {
    expect(isOnline()).toBe(true);
  });
});

describe("toggleOnlineStatus", () => {
  test("works", () => {
    toggleOnlineStatus();
    expect(isOnline()).toBe(false);
    toggleOnlineStatus();
    expect(isOnline()).toBe(true);
  });
});

describe("setOfflineMode", () => {
  test("works", () => {
    setOfflineMode();
    expect(isOnline()).toBe(false);
  });
});

describe("setOnlineMode", () => {
  test("works", () => {
    setOfflineMode();
    setOnlineMode();
    expect(isOnline()).toBe(true);
  });
});

import {
  checkOnlineStatus,
  setOfflineMode,
  setOnlineMode,
  toggleOnlineStatus,
} from "./online-status";

describe("checkOnlineStatus", () => {
  test("works", () => {
    expect(checkOnlineStatus()).toBe(true);
  });
});

describe("toggleOnlineStatus", () => {
  test("works", () => {
    toggleOnlineStatus();
    expect(checkOnlineStatus()).toBe(false);
    toggleOnlineStatus();
    expect(checkOnlineStatus()).toBe(true);
  });
});

describe("setOfflineMode", () => {
  test("works", () => {
    setOfflineMode();
    expect(checkOnlineStatus()).toBe(false);
  });
});

describe("setOnlineMode", () => {
  test("works", () => {
    setOfflineMode();
    setOnlineMode();
    expect(checkOnlineStatus()).toBe(true);
  });
});

require("jest-fetch-mock").enableMocks();
import {
  isOnline,
  setOfflineMode,
  setOnlineMode,
  toggleOnlineStatus,
  refreshOnlineStatus,
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

describe("refreshOnlineStatus", () => {
  const cb = jest.fn();

  beforeAll(() => {
    jest.useFakeTimers();
  });

  test("works", async () => {
    refreshOnlineStatus(cb);

    jest.advanceTimersToNextTimer(2);
    await Promise.resolve();
    expect(cb).toHaveBeenCalledTimes(2);

    fetch.mockReject(new Error("Offline"));

    jest.advanceTimersToNextTimer(2);
    await Promise.resolve();
    expect(cb).toHaveBeenCalledTimes(2);
  });
});

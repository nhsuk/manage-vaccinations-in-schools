require("jest-fetch-mock").enableMocks();
import {
  isOnline,
  setOfflineMode,
  setOnlineMode,
  toggleOnlineStatus,
  refreshOnlineStatus,
  fetchWithTimeout,
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

describe("fetchWithTimeout", () => {
  test("works if request is shorter than timeout", async () => {
    fetch.mockResponseOnce(
      () =>
        new Promise((resolve) => setTimeout(() => resolve({ body: "ok" }), 1))
    );
    await expect(fetchWithTimeout("/")).resolves.not.toThrow();
  });

  test("times out if request takes longer than timeout", async () => {
    fetch.mockResponseOnce(
      () =>
        new Promise((resolve) => setTimeout(() => resolve({ body: "ok" }), 2))
    );
    await expect(fetchWithTimeout("/", { timeout: 1 })).rejects.toThrow();
  });
});

describe("refreshOnlineStatus", () => {
  const cb = jest.fn();

  const tick = async () => {
    jest.advanceTimersToNextTimer(1); // Wait the sleep
    await Promise.resolve(); // Resolve the fetchWithTimeout
    await Promise.resolve(); // Resolve the fetch
    await Promise.resolve(); // Resolve the cb
  };

  beforeAll(() => {
    jest.useFakeTimers();
  });

  test("works", async () => {
    refreshOnlineStatus(cb);

    expect(cb).toHaveBeenCalledTimes(0);

    await tick();
    expect(cb).toHaveBeenCalledTimes(1);

    await tick();
    expect(cb).toHaveBeenCalledTimes(2);

    fetch.mockReject(new Error("Offline"));

    await tick();
    expect(cb).toHaveBeenCalledTimes(2);
  });
});

require("jest-fetch-mock").enableMocks();
import { cacheOnly, networkFirst } from "./network";

const mockCache = {
  match: jest.fn(() => "test"),
  put: jest.fn(),
};

const mockCaches = {
  open: jest.fn().mockResolvedValue(mockCache),
};

global.caches = mockCaches as any;

describe("cacheOnly", () => {
  test("returns cached response if available", async () => {
    const request = new Request("https://example.com/test");
    const response = await cacheOnly(request);

    expect(mockCaches.open).toHaveBeenCalled();
    expect(mockCache.match).toHaveBeenCalledWith(request, { ignoreVary: true });
    expect(response).toEqual("test");
  });
});

describe("networkFirst", () => {
  test("returns network response if available", async () => {
    const request = new Request("https://example.com/test");
    const response = await networkFirst(request);

    expect(mockCaches.open).toHaveBeenCalled();
    expect(mockCache.put).toHaveBeenCalled();
    expect(response).toHaveProperty("status", 200);
  });

  test("returns cached response if network request fails", async () => {
    // @ts-ignore
    fetch.mockRejectedValueOnce(new Error("test"));

    const request = new Request("https://example.com/test");
    const response = await networkFirst(request);

    expect(mockCaches.open).toHaveBeenCalled();
    expect(mockCache.match).toHaveBeenCalledWith(request, { ignoreVary: true });
    expect(response).toEqual("test");
  });
});

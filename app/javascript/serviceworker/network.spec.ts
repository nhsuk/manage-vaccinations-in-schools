require("jest-fetch-mock").enableMocks();
import { cacheOnly, networkFirst } from "./network";
import { match, put } from "./cache";

jest.mock("./cache");

describe("cacheOnly", () => {
  test("returns cached response if available", async () => {
    (match as jest.Mock).mockReturnValueOnce("test");
    const request = new Request("https://example.com/test");
    const response = await cacheOnly(request);

    expect(match).toHaveBeenCalledWith(request);
    expect(response).toEqual("test");
  });
});

describe("networkFirst", () => {
  test("returns network response if available", async () => {
    const request = new Request("https://example.com/test");
    const response = await networkFirst(request);

    expect(put).toHaveBeenCalled();
    expect(response).toHaveProperty("status", 200);
  });

  test("returns cached response if network request fails", async () => {
    (fetch as jest.Mock).mockRejectedValueOnce(new Error("test"));
    (match as jest.Mock).mockReturnValueOnce("test");

    const request = new Request("https://example.com/test");
    const response = await networkFirst(request);

    expect(match).toHaveBeenCalledWith(request);
    expect(response).toEqual("test");
  });
});

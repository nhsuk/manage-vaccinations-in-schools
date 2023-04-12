require("jest-fetch-mock").enableMocks();
import { addAll, match, put } from "./cache";
import { add, getByUrl } from "./store";

jest.mock("./store");

describe("addAll", () => {
  test("works", async () => {
    const urls = ["https://example.com/test", "https://example.com/test2"];
    const firstResponse = new Response("foo");
    const firstBlob = await firstResponse.clone().blob();
    const secondResponse = new Response("bar");
    const secondBlob = await secondResponse.clone().blob();

    (fetch as jest.Mock)
      .mockResolvedValueOnce(firstResponse)
      .mockResolvedValueOnce(secondResponse);
    await addAll(urls);

    expect(add).toHaveBeenCalledWith("cachedResponses", urls[0], firstBlob);
    expect(add).toHaveBeenCalledWith("cachedResponses", urls[1], secondBlob);
  });
});

describe("match", () => {
  test("works", async () => {
    const request = new Request("https://example.com/test");
    const response = new Response("foo");
    (getByUrl as jest.Mock).mockResolvedValueOnce({ body: "foo" });

    const result = await match(request);
    expect(result).toEqual(response);
  });

  test("returns undefined if no match", async () => {
    (getByUrl as jest.Mock).mockResolvedValueOnce(undefined);

    const result = await match("test");
    expect(result).toBeUndefined();
  });
});

describe("put", () => {
  test("caches to the store", async () => {
    const first = "https://example.com/test";
    const second = "https://example.com/test2";

    const response = new Response();
    const body = await response.clone().blob();

    await put(first, response);
    await put(new Request(second), response);

    expect(add).toHaveBeenCalledWith("cachedResponses", first, body);
    expect(add).toHaveBeenCalledWith("cachedResponses", second, body);
  });
});

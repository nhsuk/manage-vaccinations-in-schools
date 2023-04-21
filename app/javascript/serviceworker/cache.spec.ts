require("jest-fetch-mock").enableMocks();
import { addAll, match, put } from "./cache";
import { add, getByUrl } from "./store";

jest.mock("./store");
jest.mock("./simple-crypto");

describe("addAll", () => {
  test("fetches and adds all the passed in requests", async () => {
    const urls = ["https://example.com/test", "https://example.com/test2"];

    await addAll(urls);

    expect(add).toHaveBeenCalledWith("cachedResponses", urls[0], new Blob());
    expect(add).toHaveBeenCalledWith("cachedResponses", urls[1], new Blob());
  });
});

describe("match", () => {
  test("matches a request with its response", async () => {
    (getByUrl as jest.Mock).mockResolvedValueOnce({
      body: new Response("foo"),
    });

    const result = await match("test");

    expect(result).toEqual(new Response(new Blob()));
  });

  test("returns undefined if no match", async () => {
    (getByUrl as jest.Mock).mockResolvedValueOnce(undefined);

    const result = await match("test");

    expect(result).toBeUndefined();
  });
});

describe("put", () => {
  test("caches to the store", async () => {
    const url = "https://example.com/test";

    const response = new Response();

    await put(url, response);

    expect(add).toHaveBeenCalledWith("cachedResponses", url, new Blob());
  });
});

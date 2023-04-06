require("jest-fetch-mock").enableMocks();
import { addAll, match, put } from "./cache";
import { add } from "./store";

jest.mock("./store");

const addAllMock = jest.fn();
const matchMock = jest.fn();
const putMock = jest.fn();
global.caches = {
  open: jest.fn(() => ({
    addAll: addAllMock,
    match: matchMock,
    put: putMock,
  })),
} as any;

jest.mock("./store");

describe("addAll", () => {
  test("works", async () => {
    await addAll(["foo"]);
    expect(addAllMock).toHaveBeenCalledWith(["foo"]);
  });
});

describe("match", () => {
  test("works", async () => {
    await match("foo");
    expect(matchMock).toHaveBeenCalledWith("foo", {});
  });
});

describe("put", () => {
  test("caches to the Cache API", async () => {
    const response = new Response();
    await put("foo", response);
    expect(putMock).toHaveBeenCalledWith("foo", response);
  });

  test("caches to the store", async () => {
    const request = new Request("https://example.com/test");
    const response = new Response();
    await put(request, response);

    const body = await response.clone().blob();
    expect(add).toHaveBeenCalledWith("cachedResponses", request.url, body);
  });
});

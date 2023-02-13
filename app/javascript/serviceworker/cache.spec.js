import { addAll, match, put } from "./cache";

const addAllMock = jest.fn();
const matchMock = jest.fn();
const putMock = jest.fn();
global.caches = {
  open: jest.fn(() => ({
    addAll: addAllMock,
    match: matchMock,
    put: putMock,
  })),
};

describe("addAll", () => {
  test("works", async () => {
    await addAll(["foo"]);
    expect(addAllMock).toHaveBeenCalledWith(["foo"]);
  });
});

describe("match", () => {
  test("works", async () => {
    await match("foo");
    expect(matchMock).toHaveBeenCalledWith("foo");
  });
});

describe("put", () => {
  test("works", async () => {
    await put("foo", "bar");
    expect(putMock).toHaveBeenCalledWith("foo", "bar");
  });
});

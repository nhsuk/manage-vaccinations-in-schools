import "fake-indexeddb/auto";
import FDBFactory from "fake-indexeddb/lib/FDBFactory";
import { add, getAll, destroy } from "./store";

beforeEach(() => {
  // Reset database https://github.com/dumbmatter/fakeIndexedDB/issues/40
  indexedDB = new FDBFactory();
});

describe("saveRequest and getAllRequests", () => {
  it("save and get the requests", async () => {
    await add("delayedRequests", "/api", { name: "John" });

    const requests = await getAll("delayedRequests");

    expect(requests).toMatchInlineSnapshot(`
      [
        {
          "body": {
            "name": "John",
          },
          "id": 1,
          "url": "/api",
        },
      ]
    `);
  });
});

describe("deleteRequest", () => {
  it("delete a request", async () => {
    await add("delayedRequests", "/api", { name: "John" });

    await destroy("delayedRequests", 1);

    const requests = await getAll("delayedRequests");

    expect(requests).toMatchInlineSnapshot(`[]`);
  });
});

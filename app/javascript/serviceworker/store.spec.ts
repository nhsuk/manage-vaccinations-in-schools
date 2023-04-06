import "fake-indexeddb/auto";
import FDBFactory from "fake-indexeddb/lib/FDBFactory";
import { add, destroy, getByUrl, getAll } from "./store";

beforeEach(() => {
  // Reset database https://github.com/dumbmatter/fakeIndexedDB/issues/40
  indexedDB = new FDBFactory();
});

describe("add", () => {
  it("saves the request", async () => {
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

  it("dedupes requests by url", async () => {
    await add("cachedResponses", "/api", { name: "John" });
    await add("cachedResponses", "/api", { name: "John" });

    const requests = await getAll("cachedResponses");

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

describe("getAll", () => {
  it("returns all requests", async () => {
    let requests = await getAll("delayedRequests");

    expect(requests).toMatchInlineSnapshot(`[]`);

    await add("delayedRequests", "/api", { name: "John" });

    requests = await getAll("delayedRequests");

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

describe("getByUrl", () => {
  it("gets a request by url", async () => {
    await add("delayedRequests", "/api", { name: "John" });

    const request = await getByUrl("delayedRequests", "/api");

    expect(request).toMatchInlineSnapshot(`
      {
        "body": {
          "name": "John",
        },
        "id": 1,
        "url": "/api",
      }
    `);
  });
});

describe("destroy", () => {
  it("deletes a request", async () => {
    await add("delayedRequests", "/api", { name: "John" });

    await destroy("delayedRequests", 1);

    const requests = await getAll("delayedRequests");

    expect(requests).toMatchInlineSnapshot(`[]`);
  });
});

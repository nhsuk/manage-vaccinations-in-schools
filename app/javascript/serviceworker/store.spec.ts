import "fake-indexeddb/auto";
import FDBFactory from "fake-indexeddb/lib/FDBFactory";
import { saveRequest, getAllRequests, deleteRequest } from "./store";

beforeEach(() => {
  // Reset database https://github.com/dumbmatter/fakeIndexedDB/issues/40
  indexedDB = new FDBFactory();
});

describe("saveRequest and getAllRequests", () => {
  it("save and get the requests", async () => {
    await saveRequest("/api", { name: "John" });

    const requests = await getAllRequests();

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
    await saveRequest("/api", { name: "John" });

    await deleteRequest(1);

    const requests = await getAllRequests();

    expect(requests).toMatchInlineSnapshot(`[]`);
  });
});

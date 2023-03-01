import "jest-fetch-mock";
import "fake-indexeddb/auto";
import FDBFactory from "fake-indexeddb/lib/FDBFactory";
import { saveRequest, getAllRequests, deleteRequest } from "./store";

const formDataMock = jest.fn(() => {
  const form = new FormData();
  form.append("name", "John");
  return Promise.resolve(form);
});

beforeEach(() => {
  // Reset database https://github.com/dumbmatter/fakeIndexedDB/issues/40
  indexedDB = new FDBFactory();
});

describe("saveRequest and getAllRequests", () => {
  it("save and get the requests", async () => {
    const request = new Request("/api", {
      method: "POST",
      body: JSON.stringify({ name: "John" }),
    });

    request.formData = formDataMock;

    await saveRequest(request.url, request);

    const requests = await getAllRequests();

    expect(requests).toMatchInlineSnapshot(`
      [
        {
          "data": {
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
    const request = new Request("/api", {
      method: "POST",
      body: JSON.stringify({ name: "John" }),
    });

    request.formData = formDataMock;

    await saveRequest(request.url, request);

    await deleteRequest(1);

    const requests = await getAllRequests();

    expect(requests).toMatchInlineSnapshot(`[]`);
  });
});

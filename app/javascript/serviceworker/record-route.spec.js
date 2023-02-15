import { match } from "./cache";
import { setOfflineMode } from "./online-status";
import { recordRoute, recordRouteHandler } from "./record-route";

jest.mock("./cache");

describe("recordRoute", () => {
  test("matches correctly", () => {
    expect(recordRoute.exec("/campaigns/1/children/2/record"))
      .toMatchInlineSnapshot(`
      [
        "/campaigns/1/children/2/record",
        "1",
        "2",
      ]
    `);
  });
});

const url = "/campaigns/1/children/2/record";

describe("recordRouteHandler", () => {
  test("returns response when fetch works", async () => {
    global.fetch = jest.fn(() => Promise.resolve("foo"));

    expect(await recordRouteHandler({ request: { url } })).toBe("foo");
  });

  test("saves request for later when fetch fails", async () => {
    global.fetch = jest.fn(() => {
      throw new NetworkError("I'm too lazy to connect, yawn");
    });
    match.mockResolvedValue("foo");

    expect(await recordRouteHandler({ request: { url } })).toBe("foo");
  });

  test("saves request for later when offline", async () => {
    setOfflineMode();
    match.mockResolvedValue("foo");

    expect(await recordRouteHandler({ request: { url } })).toBe("foo");
  });
});

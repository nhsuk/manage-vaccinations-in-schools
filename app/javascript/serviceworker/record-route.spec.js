require("jest-fetch-mock").enableMocks();
import { match } from "./cache";
import { setOfflineMode } from "./online-status";
import { recordRoute, recordRouteHandler } from "./record-route";

jest.mock("./cache");
jest.mock("./store");

const url = "/campaigns/1/children/2/record";
const request = new Request(url);
request.formData = () => Promise.resolve("foo");

describe("recordRoute", () => {
  test("matches correctly", () => {
    expect(recordRoute.exec(url)).toMatchInlineSnapshot(`
      [
        "/campaigns/1/children/2/record",
        "1",
        "2",
      ]
    `);
  });
});

describe("recordRouteHandler", () => {
  test("returns response when fetch works", async () => {
    fetch.mockResolvedValue("foo");

    expect(await recordRouteHandler({ request })).toBe("foo");
  });

  test("saves request for later when fetch fails", async () => {
    fetch.mockRejectedValue("I'm too lazy to connect, yawn");
    match.mockResolvedValue("foo");

    expect(await recordRouteHandler({ request })).toBe("foo");
  });

  test("saves request for later when offline", async () => {
    setOfflineMode();
    match.mockResolvedValue("foo");

    expect(await recordRouteHandler({ request })).toBe("foo");
  });
});

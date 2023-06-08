import { match } from "./cache";
import { setOfflineMode } from "./online-status";
import { childRoute, childRouteHandler } from "./child-route";

jest.mock("./cache");

describe("childRoute", () => {
  test("matches correctly", () => {
    expect(childRoute.exec("/sessions/1/vaccinations/2"))
      .toMatchInlineSnapshot(`
      [
        "/sessions/1/vaccinations/2",
        "1",
        "2",
      ]
    `);
  });
});

const url = "/sessions/1/vaccinations/2";

describe("childRouteHandler", () => {
  test("returns response when fetch works", async () => {
    const response = { clone: jest.fn() };
    global.fetch = jest.fn(() => Promise.resolve(response));

    expect(await childRouteHandler({ request: { url } })).toBe(response);
  });

  test("returns cached response when fetch fails", async () => {
    global.fetch = jest.fn(() => {
      throw new NetworkError("I'm too lazy to connect, yawn");
    });
    match.mockResolvedValue("foo");

    expect(await childRouteHandler({ request: { url } })).toBe("foo");
  });

  test("returns cached response when offline", async () => {
    setOfflineMode();
    match.mockResolvedValue("foo");

    expect(await childRouteHandler({ request: { url } })).toBe("foo");
  });
});

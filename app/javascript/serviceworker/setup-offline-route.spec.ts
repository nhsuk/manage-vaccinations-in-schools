import { init as initCache, addAll } from "./cache";
import {
  setupOfflineRoute,
  setupOfflineRouteHandler,
} from "./setup-offline-route";

jest.mock("./cache");

const url = "/sessions/1/setup-offline";

afterEach(() => {
  jest.clearAllMocks();
});

describe("setupOfflineRoute", () => {
  test("matches correctly", () => {
    expect(setupOfflineRoute.exec(url)).toMatchInlineSnapshot(`
      [
        "/sessions/1/setup-offline",
        "1",
      ]
    `);
  });
});

describe("setupOfflineRouteHandler", () => {
  test("sets up offline working when fetch works", async () => {
    const request = {
      url,
      clone: jest.fn(() => request),
      formData: jest.fn(() =>
        Promise.resolve([
          ["offline_password[assets_css]", "/css"],
          ["offline_password[assets_js]", "/js"],
          ["offline_password[password]", "password"],
        ]),
      ),
    };
    const response = { type: "opaqueredirect" };
    global.fetch = jest.fn(() => Promise.resolve(response)) as any;

    expect(await setupOfflineRouteHandler({ request })).toBe(response);
    expect(initCache).toHaveBeenCalledWith("password");
    expect((addAll as any).mock.calls).toMatchInlineSnapshot(`
      [
        [
          [
            "/css",
            "/js",
            "/favicon.ico",
            "/start",
            "/dashboard",
            "/sessions/1",
            "/sessions/1/vaccinations",
            "/sessions/1/vaccinations.json",
            "/sessions/1/vaccinations/record-template",
            "/sessions/1/vaccinations/show-template",
          ],
        ],
      ]
    `);
  });

  test("does not set up offline working when fetch fails", async () => {
    const request = {
      url,
      clone: jest.fn(() => request),
    };
    const response = { type: "error" };
    global.fetch = jest.fn(() => Promise.resolve(response)) as any;

    expect(await setupOfflineRouteHandler({ request })).toBe(response);
    expect(initCache).not.toHaveBeenCalled();
    expect(addAll).not.toHaveBeenCalled();
  });
});

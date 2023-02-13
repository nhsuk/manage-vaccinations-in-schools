import { addAll } from "./cache";
import { toggleOnlineStatus, checkOnlineStatus } from "./online-status";
import { handler } from "./messages";

jest.mock("./online-status");
jest.mock("./cache");

const postMessage = jest.fn();
const event = (type, payload) => ({
  data: { type, payload },
  ports: [{ postMessage }],
});

describe("messageHandler", () => {
  describe("TOGGLE_CONNECTION", () => {
    test("works", () => {
      toggleOnlineStatus.mockReturnValue("toggled online status");
      handler(event("TOGGLE_CONNECTION"));
      expect(toggleOnlineStatus).toHaveBeenCalled();
      expect(postMessage).toHaveBeenCalledWith("toggled online status");
    });
  });

  describe("GET_CONNECTION_STATUS", () => {
    test("works", () => {
      checkOnlineStatus.mockReturnValue("online status");
      handler(event("GET_CONNECTION_STATUS"));
      expect(checkOnlineStatus).toHaveBeenCalled();
      expect(postMessage).toHaveBeenCalledWith("online status");
    });
  });

  describe("SAVE_CAMPAIGN_FOR_OFFLINE", () => {
    test("works", () => {
      handler(event("SAVE_CAMPAIGN_FOR_OFFLINE", ["1"]));
      expect(addAll.mock.calls[0][0]).toMatchInlineSnapshot(`
        [
          "/campaigns/undefined/children",
          "/campaigns/undefined/children.json",
          "/campaigns/undefined/children/show-template",
        ]
      `);
    });
  });
});

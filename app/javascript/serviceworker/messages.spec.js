import { addAll } from "./cache";
import { toggleOnlineStatus, isOnline } from "./online-status";
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
      isOnline.mockReturnValue("online status");
      handler(event("GET_CONNECTION_STATUS"));
      expect(isOnline).toHaveBeenCalled();
      expect(postMessage).toHaveBeenCalledWith("online status");
    });
  });

  describe("SAVE_CAMPAIGN_FOR_OFFLINE", () => {
    test("works", () => {
      handler(
        event("SAVE_CAMPAIGN_FOR_OFFLINE", {
          campaignId: 1,
          additionalItems: ["/assets/application.js"],
        })
      );
      expect(addAll.mock.calls[0][0]).toMatchInlineSnapshot(`
        [
          "/assets/application.js",
          "/favicon.ico",
          "/dashboard",
          "/campaigns/1",
          "/campaigns/1/children",
          "/campaigns/1/children.json",
          "/campaigns/1/children/record-template",
          "/campaigns/1/children/show-template",
        ]
      `);
    });
  });
});

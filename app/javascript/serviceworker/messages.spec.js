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
});

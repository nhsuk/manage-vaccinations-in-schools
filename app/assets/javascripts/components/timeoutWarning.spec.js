import fs from "fs";
import path from "path";
import fetchMock from "jest-fetch-mock";

import { TimeoutWarning } from "./timeoutWarning.js";

fetchMock.enableMocks();

describe("TimeoutWarning", () => {
  const html = fs.readFileSync(
    path.join(__dirname, "../../../views/layouts/_timeout_warning.html"),
    "utf8",
  );

  beforeAll(() => {
    // JSDOM doesn't support the dialog element, so we need to mock it
    HTMLDialogElement.prototype.showModal = jest.fn(function () {
      this.open = true;
    });
    HTMLDialogElement.prototype.close = jest.fn(function () {
      this.open = false;
      this.dispatchEvent(new CustomEvent("close"));
    });
  });

  beforeEach(() => {
    document.body.innerHTML = html;
    document.body.classList.add("nhsuk-frontend-supported");
    fetchMock.resetMocks();
  });

  it("should not show the timeout warning when the time remaining is more than 2 minutes", async () => {
    fetchMock.mockResponseOnce(
      JSON.stringify({
        time_remaining_seconds: 300,
      }),
    );

    const timeoutWarning = new TimeoutWarning(document.querySelector("dialog"));
    await new Promise(process.nextTick);

    // wait for one second to pass
    await new Promise((resolve) => setTimeout(resolve, 1000));

    expect(fetchMock.mock.calls[0][0]).toBe("/users/sessions/time-remaining");
    expect(timeoutWarning.dialogElement.open).toBe(false);
  });

  it("should show the timeout warning when the time remaining is less than 2 minutes", async () => {
    fetchMock.mockResponseOnce(
      JSON.stringify({
        time_remaining_seconds: 90,
      }),
    );

    const timeoutWarning = new TimeoutWarning(document.querySelector("dialog"));
    await new Promise(process.nextTick);

    // Make sure the modal is visible without waiting for
    // a second to pass
    timeoutWarning.toggleModalVisibility();

    expect(fetchMock.mock.calls[0][0]).toBe("/users/sessions/time-remaining");
    expect(timeoutWarning.dialogElement.open).toBe(true);
  });

  it("should close the dialog when the button is clicked", async () => {
    document.head.innerHTML = '<meta name="csrf-token" content="test-token">';

    fetchMock.mockResponses(
      JSON.stringify({ time_remaining_seconds: 90 }),
      JSON.stringify({ time_remaining_seconds: 300 }),
    );

    const timeoutWarning = new TimeoutWarning(document.querySelector("dialog"));
    await new Promise(process.nextTick);
    const refreshSpy = jest.spyOn(timeoutWarning, "refreshSession");

    // Make sure the modal is visible without waiting for
    // a second to pass
    timeoutWarning.toggleModalVisibility();

    timeoutWarning.button.click();
    await new Promise(process.nextTick);
    timeoutWarning.toggleModalVisibility();

    expect(refreshSpy).toHaveBeenCalledTimes(1);
    expect(timeoutWarning.dialogElement.open).toBe(false);
  });

  it("should close the dialog when escape key is pressed", async () => {
    document.head.innerHTML = '<meta name="csrf-token" content="test-token">';

    fetchMock.mockResponses(
      JSON.stringify({ time_remaining_seconds: 90 }),
      JSON.stringify({ time_remaining_seconds: 300 }),
    );

    const timeoutWarning = new TimeoutWarning(document.querySelector("dialog"));
    await new Promise(process.nextTick);
    const refreshSpy = jest.spyOn(timeoutWarning, "refreshSession");

    // Make sure the modal is visible without waiting for
    // a second to pass
    timeoutWarning.toggleModalVisibility();

    timeoutWarning.dialogElement.dispatchEvent(
      new KeyboardEvent("keydown", { key: "Escape" }),
    );
    await new Promise(process.nextTick);
    timeoutWarning.toggleModalVisibility();

    expect(refreshSpy).toHaveBeenCalledTimes(1);
    expect(timeoutWarning.dialogElement.open).toBe(false);
  });

  it("should update the timer elements when the time remaining is updated", async () => {
    fetchMock.mockResponseOnce(
      JSON.stringify({
        time_remaining_seconds: 90,
      }),
    );

    const timeoutWarning = new TimeoutWarning(document.querySelector("dialog"));
    await new Promise(process.nextTick);
    timeoutWarning.toggleModalVisibility();
    timeoutWarning.updateTimerElements();

    expect(timeoutWarning.timerElement.textContent).toBe(
      "1 minute and 30 seconds",
    );
    expect(timeoutWarning.timerElementAccessible.textContent).toBe(
      "1 minute and 30 seconds",
    );
  });

  it("should format the time remaining correctly", () => {
    expect(TimeoutWarning.formatTimeRemaining(0)).toBe("0 seconds");
    expect(TimeoutWarning.formatTimeRemaining(1)).toBe("1 second");
    expect(TimeoutWarning.formatTimeRemaining(2)).toBe("2 seconds");
    expect(TimeoutWarning.formatTimeRemaining(60)).toBe(
      "1 minute and 0 seconds",
    );
    expect(TimeoutWarning.formatTimeRemaining(61)).toBe(
      "1 minute and 1 second",
    );
    expect(TimeoutWarning.formatTimeRemaining(105)).toBe(
      "1 minute and 45 seconds",
    );
  });
});

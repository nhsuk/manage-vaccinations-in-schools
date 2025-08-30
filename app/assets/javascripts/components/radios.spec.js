import { UpgradedRadios } from "./radios.js";

jest.mock("nhsuk-frontend/packages/components/radios/radios");

document.body.innerHTML = `
  <div data-module="nhsuk-radios">
    <input type="radio" data-aria-controls="target-id" />
    <div id="target-id" class="nhsuk-radios__conditional"></div>
  </div>
  <div data-module="nhsuk-radios">
    <input type="radio" />
  </div>
`;

describe("UpgradedRadios", () => {
  beforeEach(() => {
    const $radios = document.querySelector('[data-module="nhsuk-radios"]');
    return new UpgradedRadios($radios);
  });

  test("should call UpgradedRadios", () => {
    expect(UpgradedRadios).toHaveBeenCalledTimes(1);
  });

  test("should promote 'data-aria-controls' to 'aria-controls'", () => {
    const radioInput = document.querySelector('input[type="radio"]');
    expect(radioInput.getAttribute("aria-controls")).toEqual("target-id");
    expect(radioInput.getAttribute("data-aria-controls")).toBeNull();
  });
});

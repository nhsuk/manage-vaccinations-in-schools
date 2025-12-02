import { UpgradedCheckboxes } from "./checkboxes.js";

jest.mock("nhsuk-frontend/packages/components/checkboxes/checkboxes");

document.body.innerHTML = `
  <div data-module="nhsuk-checkboxes">
    <input type="checkbox" data-aria-controls="target-id" />
    <div id="target-id" class="nhsuk-checkboxes__conditional"></div>
  </div>
  <div data-module="nhsuk-checkboxes">
    <input type="checkbox" />
  </div>
`;

describe("UpgradedCheckboxes", () => {
  beforeEach(() => {
    const $checkboxes = document.querySelector(
      '[data-module="nhsuk-checkboxes"]',
    );
    return new UpgradedCheckboxes($checkboxes);
  });

  test("should call UpgradedCheckboxes", () => {
    expect(UpgradedCheckboxes).toHaveBeenCalledTimes(1);
  });

  test("should promote 'data-aria-controls' to 'aria-controls'", () => {
    const checkboxInput = document.querySelector('input[type="checkbox"]');
    expect(checkboxInput.getAttribute("aria-controls")).toEqual("target-id");
    expect(checkboxInput.getAttribute("data-aria-controls")).toBeNull();
  });
});

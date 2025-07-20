import { application } from "./application";
import NhsukRadiosController from "./nhsuk_radios_controller";

jest.mock("nhsuk-frontend");

// Creating HTML body structure
document.body.innerHTML = `
  <div data-module="nhsuk-radios">
    <input type="radio" data-aria-controls="target-id" />
    <div id="target-id" class="nhsuk-radios__conditional"></div>
  </div>
  <div data-module="nhsuk-radios">
    <input type="radio" />
  </div>
`;

describe("NhsukRadiosController", () => {
  beforeEach(() => {
    application.register("nhsuk-radios", NhsukRadiosController);
  });

  test("should promote 'data-aria-controls' to 'aria-controls'", () => {
    const radios = document.querySelector('input[type="radio"]');
    // @ts-ignore
    expect(radios.getAttribute("aria-controls")).toEqual("target-id");
    // @ts-ignore
    expect(radios.getAttribute("data-aria-controls")).toBeNull();
  });
});

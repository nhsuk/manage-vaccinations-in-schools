import { application } from "./application";
import NhsukRadiosController from "./nhsuk_radios_controller";
import { initRadios } from "nhsuk-frontend";

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

  test("should call NhsukRadios", () => {
    expect(initRadios).toHaveBeenCalledTimes(2);
  });

  test("should add 'nhsuk-radios--conditional' class", () => {
    const elements = document.querySelectorAll('[data-module="nhsuk-radios"]');
    expect(elements[0].classList).toContain("nhsuk-radios--conditional");
    expect(elements[1].classList).not.toContain("nhsuk-radios--conditional");
  });

  test("should promote 'data-aria-controls' to 'aria-controls'", () => {
    const radios = document.querySelector('input[type="radio"]');
    initRadios();
    // @ts-ignore
    expect(radios.getAttribute("aria-controls")).toEqual("target-id");
    // @ts-ignore
    expect(radios.getAttribute("data-aria-controls")).toBeNull();
  });
});

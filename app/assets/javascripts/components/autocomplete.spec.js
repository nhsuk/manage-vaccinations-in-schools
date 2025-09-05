import { Autocomplete } from "./autocomplete.js";

document.body.classList.add("nhsuk-frontend-supported");
document.body.innerHTML = `
  <select id="fruit" name="fruit" data-module="app-autocomplete">
    <option value=""></option>
    <option data-hint="Red" data-append="Sliced">Apple</option>
    <option data-hint="Yellow" data-append="Peeled">Banana</option>
    <option data-hint="Orange" data-append="Squeezed">Orange</option>
  </select>
`;

describe("Autocomplete", () => {
  beforeAll(() => {
    const $select = document.querySelector('[data-module="app-autocomplete"]');
    return new Autocomplete($select);
  });

  test("should enhance select", () => {
    const select = document.querySelector("select");
    expect(window.getComputedStyle(select).display).toBe("none");

    const autocomplete = document.querySelector(".app-autocomplete__wrapper");
    expect(autocomplete).toBeTruthy();

    const input = document.querySelector(".app-autocomplete__wrapper input");
    expect(input.getAttribute("aria-controls")).toEqual("fruit__listbox");
  });

  test("should show matching options when a value is entered", async () => {
    const input = document.querySelector('[aria-controls="fruit__listbox"]');
    const listbox = document.querySelector("#fruit__listbox");

    // Initially, the listbox should be hidden
    expect(listbox.classList).toContain("app-autocomplete__menu--hidden");

    // Simulate typing "a" in the input
    input.focus();
    input.value = "a";
    input.dispatchEvent(new Event("input", { bubbles: true }));
    await new Promise((resolve) => setTimeout(resolve, 100));

    // The listbox should now be visible
    expect(listbox.classList).toContain("app-autocomplete__menu--visible");

    // Check that matching options are shown
    const visibleOptions = listbox.querySelectorAll("li");
    expect(visibleOptions.length).toEqual(3);

    // Check that options display hint and appended text
    expect(visibleOptions[0].innerHTML.trim()).toEqual(
      `Apple – Sliced<br><span class="app-autocomplete__option-hint">Red</span>`,
    );

    // Simulate clicking first option
    visibleOptions[0].click();
    await new Promise((resolve) => setTimeout(resolve, 50));

    // Check that selected options is saved
    expect(input.value).toBe("Apple");
  });

  test("should shows a message if no values found", async () => {
    const input = document.querySelector('[aria-controls="fruit__listbox"]');
    const listbox = document.querySelector("#fruit__listbox");

    // Simulate typing "z" in the input
    input.focus();
    input.value = "z";
    input.dispatchEvent(new Event("input", { bubbles: true }));
    await new Promise((resolve) => setTimeout(resolve, 100));

    // Check that matching options are shown
    const visibleOptions = listbox.querySelectorAll("li");
    console.log(visibleOptions[0].innerHTML.trim());
    expect(visibleOptions.length).toEqual(1);

    // Option display hint text
    expect(visibleOptions[0].innerHTML.trim()).toEqual("No results found");
  });
});

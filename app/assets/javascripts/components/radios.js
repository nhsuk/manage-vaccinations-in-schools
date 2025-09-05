import { Radios } from "nhsuk-frontend";

export class UpgradedRadios extends Radios {
  constructor($root) {
    // Promote data-aria-controls attribute to a aria-controls attribute as per
    // https://github.com/alphagov/govuk-frontend/blob/88fea750b5eb9c9d9f661405e68bfb59e59754b2/packages/govuk-frontend/src/govuk/components/radios/radios.mjs#L33-L34
    const $inputs = $root.querySelectorAll('input[type="radio"]');

    $inputs.forEach(($input) => {
      const targetId = $input.getAttribute("data-aria-controls");

      // Skip radios without data-aria-controls attributes, or where the
      // target element does not exist.
      if (!targetId || !document.getElementById(targetId)) {
        return;
      }

      // Promote the data-aria-controls attribute to a aria-controls attribute
      // so that the relationship is exposed in the AOM
      $input.setAttribute("aria-controls", targetId);
      $input.removeAttribute("data-aria-controls");
    });

    super($root);
  }
}

import { Controller } from "@hotwired/stimulus";

// Connects to data-module="check-all"
export default class extends Controller {
  static targets = ["checkAll", "item"];

  connect() {
    const $container = this.checkAllTarget;
    $container.hidden = false;

    const $checkAll = $container.querySelector("input");
    const $items = this.itemTargets;

    $checkAll.addEventListener("change", (event) => {
      $items.forEach(($el) => ($el.checked = event.target.checked));
    });

    $items.forEach(($item) => {
      $item.addEventListener("click", () => {
        $checkAll.checked = $items.every(($el) => $el.checked);
      });
    });
  }
}

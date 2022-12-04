import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="select-with-message"
export default class extends Controller {
  static targets = ["select", "output"];

  connect() {
    this.change();
  }

  change(event) {
    const selected = Array.from(this.selectTarget.querySelectorAll("option")).find(
      (option) => option.selected
    );

    if (selected) {
      this.outputTarget.innerHTML = selected.dataset.message;
    }
  }
}

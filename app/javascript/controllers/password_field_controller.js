import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "showButton", "hideButton"];

  connect() {
    this.element.classList.remove("hidden");
  }

  toggle() {
    const input = this.element.parentElement.querySelector("input");

    if (input.type === "password") {
      this.show(input);
    } else {
      this.hide(input);
    }
  }

  show(input) {
    input.type = "text";
    this.showButtonTarget.style.display = "none";
    this.hideButtonTarget.style.display = "block";
  }

  hide(input) {
    input.type = "password";
    this.showButtonTarget.style.display = "block";
    this.hideButtonTarget.style.display = "none";
  }
}

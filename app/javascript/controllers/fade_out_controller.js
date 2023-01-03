import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="fade-out"
export default class extends Controller {
  connect() {
    this.element.classList.add("transition");
    this.element.classList.add("transition-duration-500");

    window.setTimeout(this.fadeOut.bind(this), 3000);
  }

  fadeOut() {
    if (!this.element) {
      return;
    }

    this.element.classList.add("opacity-0");

    this.element.addEventListener("transitionend", (event) => {
      if (event.target === this.element) {
        this.element.remove();
      }
    });
  }
}

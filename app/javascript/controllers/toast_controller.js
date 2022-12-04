import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="toast"
export default class extends Controller {
  connect() {
    // Show the toast for one second per ten characters, minimum of 5 and max of 10.
    const showFor = this.element.textContent.replace(/\s+/g, " ").trim().length * 100;
    this.desiredExit = new Date().getTime() + Math.min(10000, Math.max(5000, showFor));

    this.mouseout();
  }

  disconnect() {
    this.clearTimeout();
  }

  mouseover() {
    this.clearTimeout();
  }

  mouseout(event) {
    if (event && event.target !== this.element) {
      return;
    }

    this.clearTimeout();

    // Set the timeout to be 5 seconds from when the toast was created, or two seconds from now,
    // whichever is later.
    const timeout = Math.max(this.desiredExit - new Date().getTime(), 2000);

    this.timeout = window.setTimeout(this.close.bind(this), timeout);
  }

  clearTimeout() {
    this.timeout && window.clearTimeout(this.timeout);
  }

  close() {
    this.element.style.opacity = 0;
    this.element.classList.add("translate-y-2");
    this.element.style.pointerEvents = "none";

    this.element.addEventListener("transitionend", (event) => {
      if (event.target === this.element) {
        this.element.remove();
      }
    });
  }
}

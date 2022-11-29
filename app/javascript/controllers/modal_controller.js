import { Controller } from "@hotwired/stimulus";
import { createFocusTrap } from "focus-trap";

// Connects to data-controller="modal"
export default class extends Controller {
  static targets = ["backdrop", "dialog"];

  connect() {
    document.querySelector("body").style.overflow = "hidden";
    document.querySelector("body").style.marginRight = "15px";

    this.focusTrap = createFocusTrap(this.element);
    this.focusTrap.activate();
  }

  disconnect() {
    this.focusTrap.deactivate();

    document.querySelector("body").style.overflow = null;
    document.querySelector("body").style.marginRight = null;
  }

  close(event) {
    event?.preventDefault();

    this.dialogTarget.classList.add("modal-leave");
    this.backdropTarget.classList.add("modal-backdrop-leave");

    this.dialogTarget.addEventListener("animationend", () => {
      // Removing the el will call disconnect.
      this.element.remove();

      const modalFrame = document.getElementById("modal");

      modalFrame.removeAttribute("src");
      modalFrame.removeAttribute("complete");
    });
  }

  closeWithBackdrop(event) {
    if (event && this.dialogTarget.contains(event.target)) {
      return;
    }

    // Only if both mousedown and up are on the backdrop will the modal be dismissed.
    window.addEventListener(
      "mouseup",
      (upEvent) => {
        if (upEvent && this.dialogTarget.contains(upEvent.target)) {
          return;
        }

        this.close();
      },
      { once: true }
    );
  }

  closeWithKeyboard(event) {
    if (event.code === "Escape") {
      this.close();
    }
  }
}

import { TransitionController, useClickOutside } from "stimulus-use";
import { createFocusTrap } from "focus-trap";

export default class extends TransitionController {
  static targets = ["content"];

  constructor(...args) {
    super(...args);
    this.closeWithKeyboard = this.closeWithKeyboard.bind(this);
  }

  connect() {
    useClickOutside(this);
    this.focusTrap = createFocusTrap(this.element, { allowOutsideClick: true });
  }

  clickOutside(event) {
    this.close();
  }

  open() {
    this.enter();
    this.focusTrap.activate();
    window.addEventListener("keyup", this.closeWithKeyboard);
  }

  close() {
    this.leave();
    this.focusTrap.deactivate();
    window.removeEventListener("keyup", this.closeWithKeyboard);
  }

  closeWithKeyboard(event) {
    if (event.code === "Escape") {
      this.close();
    }
  }

  toggle() {
    this.transitioned ? this.close() : this.open();
  }
}

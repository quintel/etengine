import { TransitionController, useClickOutside } from "stimulus-use";

export default class extends TransitionController {
  static targets = ["content"];

  connect() {
    useClickOutside(this);
  }

  clickOutside(event) {
    this.leave();
  }

  toggle() {
    this.toggleTransition();
  }
}

import { useTransition } from "stimulus-use";
import { Controller } from "@hotwired/stimulus";

// https://github.com/stimulus-components/stimulus-clipboard/blob/master/src/index.ts
// MIT Licensed
export default class extends Controller {
  static targets = ["button", "notice", "source"];

  static values = {
    successDuration: { type: Number, default: 5000 },
  };

  connect() {
    if (this.hasNoticeTarget) {
      useTransition(this, {
        element: this.noticeTarget,
        enterActive: "transition ease-out duration-100",
        enterFrom: "transform opacity-0",
        enterTo: "transform opacity-100",
        leaveActive: "transition ease-in duration-150",
        leaveFrom: "transform opacity-100",
        leaveTo: "transform opacity-0",
        transitioned: false,
      });
    }
  }

  copy(event) {
    event.preventDefault();

    const text = this.sourceTarget.innerText || this.sourceTarget.value;
    navigator.clipboard.writeText(text).then(() => this.copied());
  }

  copied() {
    if (!this.hasNoticeTarget) return;

    if (this.timeout) {
      clearTimeout(this.timeout);
    }

    this.buttonTarget.disabled = true;
    this.enter();

    this.timeout = setTimeout(() => {
      this.buttonTarget.disabled = false;
      this.leave();
    }, this.successDurationValue);
  }
}

import { Controller } from '@hotwired/stimulus';

// Connects to data-controller="autosubmit"
export default class extends Controller {
  static targets = ['field'];

  connect() {
    if (this.fieldTargets.length === 0) {
      return;
    }

    if (this.fieldTargets.every((field) => field.value !== '')) {
      this.element.submit();
    }
  }
}

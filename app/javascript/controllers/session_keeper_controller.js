import { Controller } from "@hotwired/stimulus";
import { startSessionKeeper } from "identity/session_keeper";

// Connects to data-controller="session-keeper" on <body>. Mounted unconditionally (not gated on a
// logged-in user): the session-keeper's whole job is to recover a session whose access cookie lapsed,
// a state in which the server sees no current_user. The shared logic guards against guest reload
// loops, so an unconditional mount is safe. See identity/session_keeper in the identity gem.
export default class extends Controller {
  static values = { idpUrl: String };

  connect() {
    this.teardown = startSessionKeeper({ idpUrl: this.idpUrlValue });
  }

  disconnect() {
    this.teardown?.();
  }
}

import { Controller } from "@hotwired/stimulus";
import { startSessionKeeper } from "identity/session_keeper";

// Connects to data-controller="session-keeper" on <body>. Mounted unconditionally (not gated on a
// logged-in user): the session-keeper's whole job is to recover a session whose access cookie lapsed,
// a state in which the server sees no current_user. The shared logic guards against guest reload
// loops, so an unconditional mount is safe. See identity/session_keeper in the identity gem.
export default class extends Controller {
  // expCookie names the hint cookie the keeper times off; suffixed on deployments that share a
  // cookie domain, so it comes from the server (Identity::ApplicationHelper) rather than assumed.
  static values = {
    idpUrl: String,
    expCookie: { type: String, default: "etm_session_exp" },
  };

  connect() {
    this.teardown = startSessionKeeper({
      idpUrl: this.idpUrlValue,
      expCookieName: this.expCookieValue,
    });
  }

  disconnect() {
    this.teardown?.();
  }
}

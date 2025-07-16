import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["select", "idsField"]

    connect() {
        this.toggleIdsField()
    }

    /**
     * Toggles the visibility of the scenario IDs input field based on the selected dump type.
     * Shows the field when "ids" is selected, hides it for all other options.
     */
    toggleIdsField() {
        if (this.selectTarget.value === "ids") {
            this.idsFieldTarget.style.display = ""
        } else {
            this.idsFieldTarget.style.display = "none"
        }
    }
}

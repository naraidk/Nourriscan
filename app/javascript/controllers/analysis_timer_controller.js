import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["value"]

  connect() {
    this.seconds = 0
    this.interval = setInterval(() => {
      this.seconds++
      this.valueTarget.textContent = this.formatTime(this.seconds)
    }, 1000)
  }

  disconnect() {
    clearInterval(this.interval)
  }

  formatTime(totalSeconds) {
    const minutes = String(Math.floor(totalSeconds / 60)).padStart(2, "0")
    const seconds = String(totalSeconds % 60).padStart(2, "0")
    return `${minutes}:${seconds}`
  }
}

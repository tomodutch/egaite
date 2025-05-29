import JSConfetti from 'js-confetti'

let ConfettiOnMount = {
    mounted() {
        // Create a single confetti instance per hook
        this.jsConfetti = new JSConfetti()

        // Blow confetti on mount
        this.jsConfetti.addConfetti()

        // Handle button clicks
        this.el.addEventListener("click", (e) => {
            if (e.target.matches("[data-confetti-button]")) {
                this.jsConfetti.addConfetti()
            }
        })
    }
}

export default ConfettiOnMount
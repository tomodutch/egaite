const ClearChatInputAfterSubmit= {
    mounted() {
        this.el.addEventListener("submit", () => {
            this.el.querySelector("input[name=body]").value = ""
        })
    }
}

export default { ClearChatInputAfterSubmit };
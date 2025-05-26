const AutoScroll = {
    mounted() {
        this.scrollToBottom();
    },
    updated() {
        this.scrollToBottom();
    },
    scrollToBottom() {
        const el = this.el;
        el.scrollTop = el.scrollHeight;
    }
};

export default AutoScroll;
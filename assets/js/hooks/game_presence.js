import channelSocket from "../user_socket";

let GamePresence = {
  mounted() {
    const gameId = this.el.dataset.gameId
    const playerId = this.el.dataset.playerId
    const playerName = this.el.dataset.playerName

    if (!gameId || !playerId || !playerName) {
      console.error("Missing game or player info for Presence")
      return
    }

    // Join the Phoenix channel
    const gameChannel = channelSocket.channel(`game:${gameId}`, {
      player_id: playerId,
      player_name: playerName,
    });

    gameChannel.join()
      .receive("ok", (resp) => {
        console.log("Joined game channel", resp)
      })
      .receive("error", (err) => {
        console.error("Unable to join game channel", err)
      });

    // Optional: handle Presence sync later
    gameChannel.on("presence_diff", (diff) => {
      console.log("Presence diff", diff)
    })

    // Cleanup on unmount
    this.handleCleanup = () => {
      if (gameChannel) {
        gameChannel.leave()
      }
    }
    window.addEventListener("beforeunload", this.handleCleanup);
  },

  destroyed() {
    this.handleCleanup?.()
    window.removeEventListener("beforeunload", this.handleCleanup)
  }
}

export default GamePresence
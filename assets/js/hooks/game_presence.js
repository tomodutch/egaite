import channelSocket from "../user_socket";

let GamePresence = {
  mounted() {
    const gameId = this.el.dataset.gameid
    const playerId = this.el.dataset.playerid

    if (!gameId || !playerId) {
      console.error("Missing game or player info for Presence")
      return
    }

    // Join the Phoenix channel
    const gameChannel = channelSocket.channel(`game_presence:${gameId}`, {
      player_id: playerId,
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
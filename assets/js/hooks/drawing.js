import channelSocket from "../user_socket";

const Drawing = {
    mounted() {
        const canvas = document.getElementById("drawingCanvas");
        const ctx = canvas.getContext("2d");

        const resizeCanvas = () => {
            const rect = canvas.getBoundingClientRect();
            canvas.width = rect.width;
            canvas.height = rect.height;
            // Redraw logic goes here if you store and re-render history
        };

        window.addEventListener("resize", resizeCanvas);

        const gameId = this.el.dataset.gameId;
        const playerId = this.el.dataset.playerId;
        const playerName = this.el.dataset.playerName;

        if (!gameId || !playerId || !playerName) {
            console.error("Missing game or player info for Drawing");
            return;
        }

        const drawingChannel = channelSocket.channel(`drawing:${gameId}`, {
            player_id: playerId,
            player_name: playerName,
        });

        drawingChannel
            .join()
            .receive("ok", (resp) => console.log("Joined drawing channel", resp))
            .receive("error", (err) => console.error("Unable to join drawing channel", err));

        let lastX = 0;
        let lastY = 0;
        let isDrawing = false;
        let strokeColor = "#000000";

        const pointQueue = [];

        const getRandomColor = () => {
            const letters = "0123456789ABCDEF";
            return "#" + Array.from({ length: 6 }, () => letters[Math.floor(Math.random() * 16)]).join("");
        };

        const getCanvasPos = (e) => {
            const rect = canvas.getBoundingClientRect();
            let x, y;
            if (e.touches && e.touches.length > 0) {
                x = (e.touches[0].clientX - rect.left) / rect.width;
                y = (e.touches[0].clientY - rect.top) / rect.height;
            } else {
                x = e.offsetX / rect.width;
                y = e.offsetY / rect.height;
            }
            return { x, y };
        };

        const toAbsolute = (rel, canvas) => ({
            x: rel.x * canvas.width,
            y: rel.y * canvas.height
        });

        const startDrawing = (e) => {
            isDrawing = true;
            strokeColor = getRandomColor();
            const pos = getCanvasPos(e);
            lastX = pos.x;
            lastY = pos.y;
        };

        const stopDrawing = () => {
            isDrawing = false;
        };

        const draw = (e) => {
            if (!isDrawing) return;
            e.preventDefault();

            const pos = getCanvasPos(e);
            const newX = pos.x;
            const newY = pos.y;

            // Draw on local canvas using absolute values
            const absFrom = toAbsolute({ x: lastX, y: lastY }, canvas);
            const absTo = toAbsolute({ x: newX, y: newY }, canvas);

            ctx.strokeStyle = strokeColor;
            ctx.lineWidth = 2;
            ctx.lineCap = "round";

            ctx.beginPath();
            ctx.moveTo(absFrom.x, absFrom.y);
            ctx.lineTo(absTo.x, absTo.y);
            ctx.stroke();

            pointQueue.push({
                from: { x: lastX, y: lastY },
                to: { x: newX, y: newY },
                color: strokeColor,
            });

            lastX = newX;
            lastY = newY;
        };

        // Mouse events
        canvas.addEventListener("mousedown", startDrawing);
        canvas.addEventListener("mousemove", draw);
        canvas.addEventListener("mouseup", stopDrawing);
        canvas.addEventListener("mouseleave", stopDrawing);

        // Touch events
        canvas.addEventListener("touchstart", startDrawing, { passive: false });
        canvas.addEventListener("touchmove", draw, { passive: false });
        canvas.addEventListener("touchend", stopDrawing);
        canvas.addEventListener("touchcancel", stopDrawing);

        // Send batched points every 250ms
        setInterval(() => {
            if (pointQueue.length > 0) {
                drawingChannel.push("draw_batch", {
                    points: pointQueue.splice(0),
                });
            }
        }, 250);

        // Receive and render drawings
        drawingChannel.on("draw_batch", ({ points }) => {
            points.forEach(({ from, to, color }) => {
                const absFrom = toAbsolute(from, canvas);
                const absTo = toAbsolute(to, canvas);

                ctx.strokeStyle = color;
                ctx.lineWidth = 2;
                ctx.lineCap = "round";

                ctx.beginPath();
                ctx.moveTo(absFrom.x, absFrom.y);
                ctx.lineTo(absTo.x, absTo.y);
                ctx.stroke();
            });
        });

        resizeCanvas();
    }
};

export default Drawing;

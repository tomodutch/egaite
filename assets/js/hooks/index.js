import GamePresence from "./game_presence";
import Drawing from "./drawing";
import Helpers from "./form_helpers";
import AutoScroll from "./auto_scroll";
import ConfettiOnMount from "./confetti";

const Hooks = {
  GamePresence,
  Drawing,
  AutoScroll,
  ConfettiOnMount,
  ...Helpers
}

export default Hooks
import GamePresence from "./game_presence";
import Drawing from "./drawing";
import Helpers from "./form_helpers";
import AutoScroll from "./auto_scroll";

const Hooks = {
  GamePresence,
  Drawing,
  AutoScroll,
  ...Helpers
}

export default Hooks
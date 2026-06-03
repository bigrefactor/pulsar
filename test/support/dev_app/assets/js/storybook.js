// Injects Pulsar's colocated hooks into PhoenixStorybook's LiveSocket so
// JS-driven components (Popover, Menu, Modal, Tooltip, …) are interactive in the
// storybook. PSB loads this file (via `js_path`) before its own script and reads
// `window.storybook.Hooks`.
import { hooks } from "phoenix-colocated/pulsar";

(function () {
  window.storybook = { Hooks: hooks };
})();

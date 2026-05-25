import { Socket } from "phoenix";
import { LiveSocket } from "phoenix_live_view";
import { hooks } from "phoenix-colocated/pulsar";

const csrfToken = document
  .querySelector("meta[name='csrf-token']")
  ?.getAttribute("content");

const liveSocket = new LiveSocket("/live", Socket, {
  hooks,
  params: { _csrf_token: csrfToken },
});

liveSocket.connect();
window.liveSocket = liveSocket;

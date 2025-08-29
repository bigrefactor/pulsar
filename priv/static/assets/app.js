// deps/phoenix_html/priv/static/phoenix_html.js
(function() {
  var PolyfillEvent = eventConstructor();
  function eventConstructor() {
    if (typeof window.CustomEvent === "function") return window.CustomEvent;
    function CustomEvent2(event, params) {
      params = params || { bubbles: false, cancelable: false, detail: void 0 };
      var evt = document.createEvent("CustomEvent");
      evt.initCustomEvent(event, params.bubbles, params.cancelable, params.detail);
      return evt;
    }
    CustomEvent2.prototype = window.Event.prototype;
    return CustomEvent2;
  }
  function buildHiddenInput(name, value) {
    var input = document.createElement("input");
    input.type = "hidden";
    input.name = name;
    input.value = value;
    return input;
  }
  function handleClick(element, targetModifierKey) {
    var to = element.getAttribute("data-to"), method = buildHiddenInput("_method", element.getAttribute("data-method")), csrf = buildHiddenInput("_csrf_token", element.getAttribute("data-csrf")), form = document.createElement("form"), submit = document.createElement("input"), target = element.getAttribute("target");
    form.method = element.getAttribute("data-method") === "get" ? "get" : "post";
    form.action = to;
    form.style.display = "none";
    if (target) form.target = target;
    else if (targetModifierKey) form.target = "_blank";
    form.appendChild(csrf);
    form.appendChild(method);
    document.body.appendChild(form);
    submit.type = "submit";
    form.appendChild(submit);
    submit.click();
  }
  window.addEventListener("click", function(e) {
    var element = e.target;
    if (e.defaultPrevented) return;
    while (element && element.getAttribute) {
      var phoenixLinkEvent = new PolyfillEvent("phoenix.link.click", {
        "bubbles": true,
        "cancelable": true
      });
      if (!element.dispatchEvent(phoenixLinkEvent)) {
        e.preventDefault();
        e.stopImmediatePropagation();
        return false;
      }
      if (element.getAttribute("data-method") && element.getAttribute("data-to")) {
        handleClick(element, e.metaKey || e.shiftKey);
        e.preventDefault();
        return false;
      } else {
        element = element.parentNode;
      }
    }
  }, false);
  window.addEventListener("phoenix.link.click", function(e) {
    var message = e.target.getAttribute("data-confirm");
    if (message && !window.confirm(message)) {
      e.preventDefault();
    }
  }, false);
})();

// deps/phoenix/priv/static/phoenix.mjs
var closure = (value) => {
  if (typeof value === "function") {
    return value;
  } else {
    let closure22 = function() {
      return value;
    };
    return closure22;
  }
};
var globalSelf = typeof self !== "undefined" ? self : null;
var phxWindow = typeof window !== "undefined" ? window : null;
var global = globalSelf || phxWindow || globalThis;
var DEFAULT_VSN = "2.0.0";
var SOCKET_STATES = { connecting: 0, open: 1, closing: 2, closed: 3 };
var DEFAULT_TIMEOUT = 1e4;
var WS_CLOSE_NORMAL = 1e3;
var CHANNEL_STATES = {
  closed: "closed",
  errored: "errored",
  joined: "joined",
  joining: "joining",
  leaving: "leaving"
};
var CHANNEL_EVENTS = {
  close: "phx_close",
  error: "phx_error",
  join: "phx_join",
  reply: "phx_reply",
  leave: "phx_leave"
};
var TRANSPORTS = {
  longpoll: "longpoll",
  websocket: "websocket"
};
var XHR_STATES = {
  complete: 4
};
var AUTH_TOKEN_PREFIX = "base64url.bearer.phx.";
var Push = class {
  constructor(channel, event, payload, timeout) {
    this.channel = channel;
    this.event = event;
    this.payload = payload || function() {
      return {};
    };
    this.receivedResp = null;
    this.timeout = timeout;
    this.timeoutTimer = null;
    this.recHooks = [];
    this.sent = false;
  }
  /**
   *
   * @param {number} timeout
   */
  resend(timeout) {
    this.timeout = timeout;
    this.reset();
    this.send();
  }
  /**
   *
   */
  send() {
    if (this.hasReceived("timeout")) {
      return;
    }
    this.startTimeout();
    this.sent = true;
    this.channel.socket.push({
      topic: this.channel.topic,
      event: this.event,
      payload: this.payload(),
      ref: this.ref,
      join_ref: this.channel.joinRef()
    });
  }
  /**
   *
   * @param {*} status
   * @param {*} callback
   */
  receive(status, callback) {
    if (this.hasReceived(status)) {
      callback(this.receivedResp.response);
    }
    this.recHooks.push({ status, callback });
    return this;
  }
  /**
   * @private
   */
  reset() {
    this.cancelRefEvent();
    this.ref = null;
    this.refEvent = null;
    this.receivedResp = null;
    this.sent = false;
  }
  /**
   * @private
   */
  matchReceive({ status, response, _ref }) {
    this.recHooks.filter((h) => h.status === status).forEach((h) => h.callback(response));
  }
  /**
   * @private
   */
  cancelRefEvent() {
    if (!this.refEvent) {
      return;
    }
    this.channel.off(this.refEvent);
  }
  /**
   * @private
   */
  cancelTimeout() {
    clearTimeout(this.timeoutTimer);
    this.timeoutTimer = null;
  }
  /**
   * @private
   */
  startTimeout() {
    if (this.timeoutTimer) {
      this.cancelTimeout();
    }
    this.ref = this.channel.socket.makeRef();
    this.refEvent = this.channel.replyEventName(this.ref);
    this.channel.on(this.refEvent, (payload) => {
      this.cancelRefEvent();
      this.cancelTimeout();
      this.receivedResp = payload;
      this.matchReceive(payload);
    });
    this.timeoutTimer = setTimeout(() => {
      this.trigger("timeout", {});
    }, this.timeout);
  }
  /**
   * @private
   */
  hasReceived(status) {
    return this.receivedResp && this.receivedResp.status === status;
  }
  /**
   * @private
   */
  trigger(status, response) {
    this.channel.trigger(this.refEvent, { status, response });
  }
};
var Timer = class {
  constructor(callback, timerCalc) {
    this.callback = callback;
    this.timerCalc = timerCalc;
    this.timer = null;
    this.tries = 0;
  }
  reset() {
    this.tries = 0;
    clearTimeout(this.timer);
  }
  /**
   * Cancels any previous scheduleTimeout and schedules callback
   */
  scheduleTimeout() {
    clearTimeout(this.timer);
    this.timer = setTimeout(() => {
      this.tries = this.tries + 1;
      this.callback();
    }, this.timerCalc(this.tries + 1));
  }
};
var Channel = class {
  constructor(topic, params, socket) {
    this.state = CHANNEL_STATES.closed;
    this.topic = topic;
    this.params = closure(params || {});
    this.socket = socket;
    this.bindings = [];
    this.bindingRef = 0;
    this.timeout = this.socket.timeout;
    this.joinedOnce = false;
    this.joinPush = new Push(this, CHANNEL_EVENTS.join, this.params, this.timeout);
    this.pushBuffer = [];
    this.stateChangeRefs = [];
    this.rejoinTimer = new Timer(() => {
      if (this.socket.isConnected()) {
        this.rejoin();
      }
    }, this.socket.rejoinAfterMs);
    this.stateChangeRefs.push(this.socket.onError(() => this.rejoinTimer.reset()));
    this.stateChangeRefs.push(
      this.socket.onOpen(() => {
        this.rejoinTimer.reset();
        if (this.isErrored()) {
          this.rejoin();
        }
      })
    );
    this.joinPush.receive("ok", () => {
      this.state = CHANNEL_STATES.joined;
      this.rejoinTimer.reset();
      this.pushBuffer.forEach((pushEvent) => pushEvent.send());
      this.pushBuffer = [];
    });
    this.joinPush.receive("error", () => {
      this.state = CHANNEL_STATES.errored;
      if (this.socket.isConnected()) {
        this.rejoinTimer.scheduleTimeout();
      }
    });
    this.onClose(() => {
      this.rejoinTimer.reset();
      if (this.socket.hasLogger())
        this.socket.log("channel", `close ${this.topic} ${this.joinRef()}`);
      this.state = CHANNEL_STATES.closed;
      this.socket.remove(this);
    });
    this.onError((reason) => {
      if (this.socket.hasLogger())
        this.socket.log("channel", `error ${this.topic}`, reason);
      if (this.isJoining()) {
        this.joinPush.reset();
      }
      this.state = CHANNEL_STATES.errored;
      if (this.socket.isConnected()) {
        this.rejoinTimer.scheduleTimeout();
      }
    });
    this.joinPush.receive("timeout", () => {
      if (this.socket.hasLogger())
        this.socket.log("channel", `timeout ${this.topic} (${this.joinRef()})`, this.joinPush.timeout);
      let leavePush = new Push(this, CHANNEL_EVENTS.leave, closure({}), this.timeout);
      leavePush.send();
      this.state = CHANNEL_STATES.errored;
      this.joinPush.reset();
      if (this.socket.isConnected()) {
        this.rejoinTimer.scheduleTimeout();
      }
    });
    this.on(CHANNEL_EVENTS.reply, (payload, ref) => {
      this.trigger(this.replyEventName(ref), payload);
    });
  }
  /**
   * Join the channel
   * @param {integer} timeout
   * @returns {Push}
   */
  join(timeout = this.timeout) {
    if (this.joinedOnce) {
      throw new Error("tried to join multiple times. 'join' can only be called a single time per channel instance");
    } else {
      this.timeout = timeout;
      this.joinedOnce = true;
      this.rejoin();
      return this.joinPush;
    }
  }
  /**
   * Hook into channel close
   * @param {Function} callback
   */
  onClose(callback) {
    this.on(CHANNEL_EVENTS.close, callback);
  }
  /**
   * Hook into channel errors
   * @param {Function} callback
   */
  onError(callback) {
    return this.on(CHANNEL_EVENTS.error, (reason) => callback(reason));
  }
  /**
   * Subscribes on channel events
   *
   * Subscription returns a ref counter, which can be used later to
   * unsubscribe the exact event listener
   *
   * @example
   * const ref1 = channel.on("event", do_stuff)
   * const ref2 = channel.on("event", do_other_stuff)
   * channel.off("event", ref1)
   * // Since unsubscription, do_stuff won't fire,
   * // while do_other_stuff will keep firing on the "event"
   *
   * @param {string} event
   * @param {Function} callback
   * @returns {integer} ref
   */
  on(event, callback) {
    let ref = this.bindingRef++;
    this.bindings.push({ event, ref, callback });
    return ref;
  }
  /**
   * Unsubscribes off of channel events
   *
   * Use the ref returned from a channel.on() to unsubscribe one
   * handler, or pass nothing for the ref to unsubscribe all
   * handlers for the given event.
   *
   * @example
   * // Unsubscribe the do_stuff handler
   * const ref1 = channel.on("event", do_stuff)
   * channel.off("event", ref1)
   *
   * // Unsubscribe all handlers from event
   * channel.off("event")
   *
   * @param {string} event
   * @param {integer} ref
   */
  off(event, ref) {
    this.bindings = this.bindings.filter((bind) => {
      return !(bind.event === event && (typeof ref === "undefined" || ref === bind.ref));
    });
  }
  /**
   * @private
   */
  canPush() {
    return this.socket.isConnected() && this.isJoined();
  }
  /**
   * Sends a message `event` to phoenix with the payload `payload`.
   * Phoenix receives this in the `handle_in(event, payload, socket)`
   * function. if phoenix replies or it times out (default 10000ms),
   * then optionally the reply can be received.
   *
   * @example
   * channel.push("event")
   *   .receive("ok", payload => console.log("phoenix replied:", payload))
   *   .receive("error", err => console.log("phoenix errored", err))
   *   .receive("timeout", () => console.log("timed out pushing"))
   * @param {string} event
   * @param {Object} payload
   * @param {number} [timeout]
   * @returns {Push}
   */
  push(event, payload, timeout = this.timeout) {
    payload = payload || {};
    if (!this.joinedOnce) {
      throw new Error(`tried to push '${event}' to '${this.topic}' before joining. Use channel.join() before pushing events`);
    }
    let pushEvent = new Push(this, event, function() {
      return payload;
    }, timeout);
    if (this.canPush()) {
      pushEvent.send();
    } else {
      pushEvent.startTimeout();
      this.pushBuffer.push(pushEvent);
    }
    return pushEvent;
  }
  /** Leaves the channel
   *
   * Unsubscribes from server events, and
   * instructs channel to terminate on server
   *
   * Triggers onClose() hooks
   *
   * To receive leave acknowledgements, use the `receive`
   * hook to bind to the server ack, ie:
   *
   * @example
   * channel.leave().receive("ok", () => alert("left!") )
   *
   * @param {integer} timeout
   * @returns {Push}
   */
  leave(timeout = this.timeout) {
    this.rejoinTimer.reset();
    this.joinPush.cancelTimeout();
    this.state = CHANNEL_STATES.leaving;
    let onClose = () => {
      if (this.socket.hasLogger())
        this.socket.log("channel", `leave ${this.topic}`);
      this.trigger(CHANNEL_EVENTS.close, "leave");
    };
    let leavePush = new Push(this, CHANNEL_EVENTS.leave, closure({}), timeout);
    leavePush.receive("ok", () => onClose()).receive("timeout", () => onClose());
    leavePush.send();
    if (!this.canPush()) {
      leavePush.trigger("ok", {});
    }
    return leavePush;
  }
  /**
   * Overridable message hook
   *
   * Receives all events for specialized message handling
   * before dispatching to the channel callbacks.
   *
   * Must return the payload, modified or unmodified
   * @param {string} event
   * @param {Object} payload
   * @param {integer} ref
   * @returns {Object}
   */
  onMessage(_event, payload, _ref) {
    return payload;
  }
  /**
   * @private
   */
  isMember(topic, event, payload, joinRef) {
    if (this.topic !== topic) {
      return false;
    }
    if (joinRef && joinRef !== this.joinRef()) {
      if (this.socket.hasLogger())
        this.socket.log("channel", "dropping outdated message", { topic, event, payload, joinRef });
      return false;
    } else {
      return true;
    }
  }
  /**
   * @private
   */
  joinRef() {
    return this.joinPush.ref;
  }
  /**
   * @private
   */
  rejoin(timeout = this.timeout) {
    if (this.isLeaving()) {
      return;
    }
    this.socket.leaveOpenTopic(this.topic);
    this.state = CHANNEL_STATES.joining;
    this.joinPush.resend(timeout);
  }
  /**
   * @private
   */
  trigger(event, payload, ref, joinRef) {
    let handledPayload = this.onMessage(event, payload, ref, joinRef);
    if (payload && !handledPayload) {
      throw new Error("channel onMessage callbacks must return the payload, modified or unmodified");
    }
    let eventBindings = this.bindings.filter((bind) => bind.event === event);
    for (let i = 0; i < eventBindings.length; i++) {
      let bind = eventBindings[i];
      bind.callback(handledPayload, ref, joinRef || this.joinRef());
    }
  }
  /**
   * @private
   */
  replyEventName(ref) {
    return `chan_reply_${ref}`;
  }
  /**
   * @private
   */
  isClosed() {
    return this.state === CHANNEL_STATES.closed;
  }
  /**
   * @private
   */
  isErrored() {
    return this.state === CHANNEL_STATES.errored;
  }
  /**
   * @private
   */
  isJoined() {
    return this.state === CHANNEL_STATES.joined;
  }
  /**
   * @private
   */
  isJoining() {
    return this.state === CHANNEL_STATES.joining;
  }
  /**
   * @private
   */
  isLeaving() {
    return this.state === CHANNEL_STATES.leaving;
  }
};
var Ajax = class {
  static request(method, endPoint, headers, body, timeout, ontimeout, callback) {
    if (global.XDomainRequest) {
      let req = new global.XDomainRequest();
      return this.xdomainRequest(req, method, endPoint, body, timeout, ontimeout, callback);
    } else if (global.XMLHttpRequest) {
      let req = new global.XMLHttpRequest();
      return this.xhrRequest(req, method, endPoint, headers, body, timeout, ontimeout, callback);
    } else if (global.fetch && global.AbortController) {
      return this.fetchRequest(method, endPoint, headers, body, timeout, ontimeout, callback);
    } else {
      throw new Error("No suitable XMLHttpRequest implementation found");
    }
  }
  static fetchRequest(method, endPoint, headers, body, timeout, ontimeout, callback) {
    let options = {
      method,
      headers,
      body
    };
    let controller = null;
    if (timeout) {
      controller = new AbortController();
      const _timeoutId = setTimeout(() => controller.abort(), timeout);
      options.signal = controller.signal;
    }
    global.fetch(endPoint, options).then((response) => response.text()).then((data) => this.parseJSON(data)).then((data) => callback && callback(data)).catch((err) => {
      if (err.name === "AbortError" && ontimeout) {
        ontimeout();
      } else {
        callback && callback(null);
      }
    });
    return controller;
  }
  static xdomainRequest(req, method, endPoint, body, timeout, ontimeout, callback) {
    req.timeout = timeout;
    req.open(method, endPoint);
    req.onload = () => {
      let response = this.parseJSON(req.responseText);
      callback && callback(response);
    };
    if (ontimeout) {
      req.ontimeout = ontimeout;
    }
    req.onprogress = () => {
    };
    req.send(body);
    return req;
  }
  static xhrRequest(req, method, endPoint, headers, body, timeout, ontimeout, callback) {
    req.open(method, endPoint, true);
    req.timeout = timeout;
    for (let [key, value] of Object.entries(headers)) {
      req.setRequestHeader(key, value);
    }
    req.onerror = () => callback && callback(null);
    req.onreadystatechange = () => {
      if (req.readyState === XHR_STATES.complete && callback) {
        let response = this.parseJSON(req.responseText);
        callback(response);
      }
    };
    if (ontimeout) {
      req.ontimeout = ontimeout;
    }
    req.send(body);
    return req;
  }
  static parseJSON(resp) {
    if (!resp || resp === "") {
      return null;
    }
    try {
      return JSON.parse(resp);
    } catch {
      console && console.log("failed to parse JSON response", resp);
      return null;
    }
  }
  static serialize(obj, parentKey) {
    let queryStr = [];
    for (var key in obj) {
      if (!Object.prototype.hasOwnProperty.call(obj, key)) {
        continue;
      }
      let paramKey = parentKey ? `${parentKey}[${key}]` : key;
      let paramVal = obj[key];
      if (typeof paramVal === "object") {
        queryStr.push(this.serialize(paramVal, paramKey));
      } else {
        queryStr.push(encodeURIComponent(paramKey) + "=" + encodeURIComponent(paramVal));
      }
    }
    return queryStr.join("&");
  }
  static appendParams(url, params) {
    if (Object.keys(params).length === 0) {
      return url;
    }
    let prefix = url.match(/\?/) ? "&" : "?";
    return `${url}${prefix}${this.serialize(params)}`;
  }
};
var arrayBufferToBase64 = (buffer) => {
  let binary = "";
  let bytes = new Uint8Array(buffer);
  let len = bytes.byteLength;
  for (let i = 0; i < len; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  return btoa(binary);
};
var LongPoll = class {
  constructor(endPoint, protocols) {
    if (protocols && protocols.length === 2 && protocols[1].startsWith(AUTH_TOKEN_PREFIX)) {
      this.authToken = atob(protocols[1].slice(AUTH_TOKEN_PREFIX.length));
    }
    this.endPoint = null;
    this.token = null;
    this.skipHeartbeat = true;
    this.reqs = /* @__PURE__ */ new Set();
    this.awaitingBatchAck = false;
    this.currentBatch = null;
    this.currentBatchTimer = null;
    this.batchBuffer = [];
    this.onopen = function() {
    };
    this.onerror = function() {
    };
    this.onmessage = function() {
    };
    this.onclose = function() {
    };
    this.pollEndpoint = this.normalizeEndpoint(endPoint);
    this.readyState = SOCKET_STATES.connecting;
    setTimeout(() => this.poll(), 0);
  }
  normalizeEndpoint(endPoint) {
    return endPoint.replace("ws://", "http://").replace("wss://", "https://").replace(new RegExp("(.*)/" + TRANSPORTS.websocket), "$1/" + TRANSPORTS.longpoll);
  }
  endpointURL() {
    return Ajax.appendParams(this.pollEndpoint, { token: this.token });
  }
  closeAndRetry(code, reason, wasClean) {
    this.close(code, reason, wasClean);
    this.readyState = SOCKET_STATES.connecting;
  }
  ontimeout() {
    this.onerror("timeout");
    this.closeAndRetry(1005, "timeout", false);
  }
  isActive() {
    return this.readyState === SOCKET_STATES.open || this.readyState === SOCKET_STATES.connecting;
  }
  poll() {
    const headers = { "Accept": "application/json" };
    if (this.authToken) {
      headers["X-Phoenix-AuthToken"] = this.authToken;
    }
    this.ajax("GET", headers, null, () => this.ontimeout(), (resp) => {
      if (resp) {
        var { status, token, messages } = resp;
        this.token = token;
      } else {
        status = 0;
      }
      switch (status) {
        case 200:
          messages.forEach((msg) => {
            setTimeout(() => this.onmessage({ data: msg }), 0);
          });
          this.poll();
          break;
        case 204:
          this.poll();
          break;
        case 410:
          this.readyState = SOCKET_STATES.open;
          this.onopen({});
          this.poll();
          break;
        case 403:
          this.onerror(403);
          this.close(1008, "forbidden", false);
          break;
        case 0:
        case 500:
          this.onerror(500);
          this.closeAndRetry(1011, "internal server error", 500);
          break;
        default:
          throw new Error(`unhandled poll status ${status}`);
      }
    });
  }
  // we collect all pushes within the current event loop by
  // setTimeout 0, which optimizes back-to-back procedural
  // pushes against an empty buffer
  send(body) {
    if (typeof body !== "string") {
      body = arrayBufferToBase64(body);
    }
    if (this.currentBatch) {
      this.currentBatch.push(body);
    } else if (this.awaitingBatchAck) {
      this.batchBuffer.push(body);
    } else {
      this.currentBatch = [body];
      this.currentBatchTimer = setTimeout(() => {
        this.batchSend(this.currentBatch);
        this.currentBatch = null;
      }, 0);
    }
  }
  batchSend(messages) {
    this.awaitingBatchAck = true;
    this.ajax("POST", { "Content-Type": "application/x-ndjson" }, messages.join("\n"), () => this.onerror("timeout"), (resp) => {
      this.awaitingBatchAck = false;
      if (!resp || resp.status !== 200) {
        this.onerror(resp && resp.status);
        this.closeAndRetry(1011, "internal server error", false);
      } else if (this.batchBuffer.length > 0) {
        this.batchSend(this.batchBuffer);
        this.batchBuffer = [];
      }
    });
  }
  close(code, reason, wasClean) {
    for (let req of this.reqs) {
      req.abort();
    }
    this.readyState = SOCKET_STATES.closed;
    let opts = Object.assign({ code: 1e3, reason: void 0, wasClean: true }, { code, reason, wasClean });
    this.batchBuffer = [];
    clearTimeout(this.currentBatchTimer);
    this.currentBatchTimer = null;
    if (typeof CloseEvent !== "undefined") {
      this.onclose(new CloseEvent("close", opts));
    } else {
      this.onclose(opts);
    }
  }
  ajax(method, headers, body, onCallerTimeout, callback) {
    let req;
    let ontimeout = () => {
      this.reqs.delete(req);
      onCallerTimeout();
    };
    req = Ajax.request(method, this.endpointURL(), headers, body, this.timeout, ontimeout, (resp) => {
      this.reqs.delete(req);
      if (this.isActive()) {
        callback(resp);
      }
    });
    this.reqs.add(req);
  }
};
var serializer_default = {
  HEADER_LENGTH: 1,
  META_LENGTH: 4,
  KINDS: { push: 0, reply: 1, broadcast: 2 },
  encode(msg, callback) {
    if (msg.payload.constructor === ArrayBuffer) {
      return callback(this.binaryEncode(msg));
    } else {
      let payload = [msg.join_ref, msg.ref, msg.topic, msg.event, msg.payload];
      return callback(JSON.stringify(payload));
    }
  },
  decode(rawPayload, callback) {
    if (rawPayload.constructor === ArrayBuffer) {
      return callback(this.binaryDecode(rawPayload));
    } else {
      let [join_ref, ref, topic, event, payload] = JSON.parse(rawPayload);
      return callback({ join_ref, ref, topic, event, payload });
    }
  },
  // private
  binaryEncode(message) {
    let { join_ref, ref, event, topic, payload } = message;
    let metaLength = this.META_LENGTH + join_ref.length + ref.length + topic.length + event.length;
    let header = new ArrayBuffer(this.HEADER_LENGTH + metaLength);
    let view = new DataView(header);
    let offset = 0;
    view.setUint8(offset++, this.KINDS.push);
    view.setUint8(offset++, join_ref.length);
    view.setUint8(offset++, ref.length);
    view.setUint8(offset++, topic.length);
    view.setUint8(offset++, event.length);
    Array.from(join_ref, (char) => view.setUint8(offset++, char.charCodeAt(0)));
    Array.from(ref, (char) => view.setUint8(offset++, char.charCodeAt(0)));
    Array.from(topic, (char) => view.setUint8(offset++, char.charCodeAt(0)));
    Array.from(event, (char) => view.setUint8(offset++, char.charCodeAt(0)));
    var combined = new Uint8Array(header.byteLength + payload.byteLength);
    combined.set(new Uint8Array(header), 0);
    combined.set(new Uint8Array(payload), header.byteLength);
    return combined.buffer;
  },
  binaryDecode(buffer) {
    let view = new DataView(buffer);
    let kind = view.getUint8(0);
    let decoder = new TextDecoder();
    switch (kind) {
      case this.KINDS.push:
        return this.decodePush(buffer, view, decoder);
      case this.KINDS.reply:
        return this.decodeReply(buffer, view, decoder);
      case this.KINDS.broadcast:
        return this.decodeBroadcast(buffer, view, decoder);
    }
  },
  decodePush(buffer, view, decoder) {
    let joinRefSize = view.getUint8(1);
    let topicSize = view.getUint8(2);
    let eventSize = view.getUint8(3);
    let offset = this.HEADER_LENGTH + this.META_LENGTH - 1;
    let joinRef = decoder.decode(buffer.slice(offset, offset + joinRefSize));
    offset = offset + joinRefSize;
    let topic = decoder.decode(buffer.slice(offset, offset + topicSize));
    offset = offset + topicSize;
    let event = decoder.decode(buffer.slice(offset, offset + eventSize));
    offset = offset + eventSize;
    let data = buffer.slice(offset, buffer.byteLength);
    return { join_ref: joinRef, ref: null, topic, event, payload: data };
  },
  decodeReply(buffer, view, decoder) {
    let joinRefSize = view.getUint8(1);
    let refSize = view.getUint8(2);
    let topicSize = view.getUint8(3);
    let eventSize = view.getUint8(4);
    let offset = this.HEADER_LENGTH + this.META_LENGTH;
    let joinRef = decoder.decode(buffer.slice(offset, offset + joinRefSize));
    offset = offset + joinRefSize;
    let ref = decoder.decode(buffer.slice(offset, offset + refSize));
    offset = offset + refSize;
    let topic = decoder.decode(buffer.slice(offset, offset + topicSize));
    offset = offset + topicSize;
    let event = decoder.decode(buffer.slice(offset, offset + eventSize));
    offset = offset + eventSize;
    let data = buffer.slice(offset, buffer.byteLength);
    let payload = { status: event, response: data };
    return { join_ref: joinRef, ref, topic, event: CHANNEL_EVENTS.reply, payload };
  },
  decodeBroadcast(buffer, view, decoder) {
    let topicSize = view.getUint8(1);
    let eventSize = view.getUint8(2);
    let offset = this.HEADER_LENGTH + 2;
    let topic = decoder.decode(buffer.slice(offset, offset + topicSize));
    offset = offset + topicSize;
    let event = decoder.decode(buffer.slice(offset, offset + eventSize));
    offset = offset + eventSize;
    let data = buffer.slice(offset, buffer.byteLength);
    return { join_ref: null, ref: null, topic, event, payload: data };
  }
};
var Socket = class {
  constructor(endPoint, opts = {}) {
    this.stateChangeCallbacks = { open: [], close: [], error: [], message: [] };
    this.channels = [];
    this.sendBuffer = [];
    this.ref = 0;
    this.timeout = opts.timeout || DEFAULT_TIMEOUT;
    this.transport = opts.transport || global.WebSocket || LongPoll;
    this.primaryPassedHealthCheck = false;
    this.longPollFallbackMs = opts.longPollFallbackMs;
    this.fallbackTimer = null;
    this.sessionStore = opts.sessionStorage || global && global.sessionStorage;
    this.establishedConnections = 0;
    this.defaultEncoder = serializer_default.encode.bind(serializer_default);
    this.defaultDecoder = serializer_default.decode.bind(serializer_default);
    this.closeWasClean = false;
    this.disconnecting = false;
    this.binaryType = opts.binaryType || "arraybuffer";
    this.connectClock = 1;
    if (this.transport !== LongPoll) {
      this.encode = opts.encode || this.defaultEncoder;
      this.decode = opts.decode || this.defaultDecoder;
    } else {
      this.encode = this.defaultEncoder;
      this.decode = this.defaultDecoder;
    }
    let awaitingConnectionOnPageShow = null;
    if (phxWindow && phxWindow.addEventListener) {
      phxWindow.addEventListener("pagehide", (_e) => {
        if (this.conn) {
          this.disconnect();
          awaitingConnectionOnPageShow = this.connectClock;
        }
      });
      phxWindow.addEventListener("pageshow", (_e) => {
        if (awaitingConnectionOnPageShow === this.connectClock) {
          awaitingConnectionOnPageShow = null;
          this.connect();
        }
      });
    }
    this.heartbeatIntervalMs = opts.heartbeatIntervalMs || 3e4;
    this.rejoinAfterMs = (tries) => {
      if (opts.rejoinAfterMs) {
        return opts.rejoinAfterMs(tries);
      } else {
        return [1e3, 2e3, 5e3][tries - 1] || 1e4;
      }
    };
    this.reconnectAfterMs = (tries) => {
      if (opts.reconnectAfterMs) {
        return opts.reconnectAfterMs(tries);
      } else {
        return [10, 50, 100, 150, 200, 250, 500, 1e3, 2e3][tries - 1] || 5e3;
      }
    };
    this.logger = opts.logger || null;
    if (!this.logger && opts.debug) {
      this.logger = (kind, msg, data) => {
        console.log(`${kind}: ${msg}`, data);
      };
    }
    this.longpollerTimeout = opts.longpollerTimeout || 2e4;
    this.params = closure(opts.params || {});
    this.endPoint = `${endPoint}/${TRANSPORTS.websocket}`;
    this.vsn = opts.vsn || DEFAULT_VSN;
    this.heartbeatTimeoutTimer = null;
    this.heartbeatTimer = null;
    this.pendingHeartbeatRef = null;
    this.reconnectTimer = new Timer(() => {
      this.teardown(() => this.connect());
    }, this.reconnectAfterMs);
    this.authToken = opts.authToken;
  }
  /**
   * Returns the LongPoll transport reference
   */
  getLongPollTransport() {
    return LongPoll;
  }
  /**
   * Disconnects and replaces the active transport
   *
   * @param {Function} newTransport - The new transport class to instantiate
   *
   */
  replaceTransport(newTransport) {
    this.connectClock++;
    this.closeWasClean = true;
    clearTimeout(this.fallbackTimer);
    this.reconnectTimer.reset();
    if (this.conn) {
      this.conn.close();
      this.conn = null;
    }
    this.transport = newTransport;
  }
  /**
   * Returns the socket protocol
   *
   * @returns {string}
   */
  protocol() {
    return location.protocol.match(/^https/) ? "wss" : "ws";
  }
  /**
   * The fully qualified socket url
   *
   * @returns {string}
   */
  endPointURL() {
    let uri = Ajax.appendParams(
      Ajax.appendParams(this.endPoint, this.params()),
      { vsn: this.vsn }
    );
    if (uri.charAt(0) !== "/") {
      return uri;
    }
    if (uri.charAt(1) === "/") {
      return `${this.protocol()}:${uri}`;
    }
    return `${this.protocol()}://${location.host}${uri}`;
  }
  /**
   * Disconnects the socket
   *
   * See https://developer.mozilla.org/en-US/docs/Web/API/CloseEvent#Status_codes for valid status codes.
   *
   * @param {Function} callback - Optional callback which is called after socket is disconnected.
   * @param {integer} code - A status code for disconnection (Optional).
   * @param {string} reason - A textual description of the reason to disconnect. (Optional)
   */
  disconnect(callback, code, reason) {
    this.connectClock++;
    this.disconnecting = true;
    this.closeWasClean = true;
    clearTimeout(this.fallbackTimer);
    this.reconnectTimer.reset();
    this.teardown(() => {
      this.disconnecting = false;
      callback && callback();
    }, code, reason);
  }
  /**
   *
   * @param {Object} params - The params to send when connecting, for example `{user_id: userToken}`
   *
   * Passing params to connect is deprecated; pass them in the Socket constructor instead:
   * `new Socket("/socket", {params: {user_id: userToken}})`.
   */
  connect(params) {
    if (params) {
      console && console.log("passing params to connect is deprecated. Instead pass :params to the Socket constructor");
      this.params = closure(params);
    }
    if (this.conn && !this.disconnecting) {
      return;
    }
    if (this.longPollFallbackMs && this.transport !== LongPoll) {
      this.connectWithFallback(LongPoll, this.longPollFallbackMs);
    } else {
      this.transportConnect();
    }
  }
  /**
   * Logs the message. Override `this.logger` for specialized logging. noops by default
   * @param {string} kind
   * @param {string} msg
   * @param {Object} data
   */
  log(kind, msg, data) {
    this.logger && this.logger(kind, msg, data);
  }
  /**
   * Returns true if a logger has been set on this socket.
   */
  hasLogger() {
    return this.logger !== null;
  }
  /**
   * Registers callbacks for connection open events
   *
   * @example socket.onOpen(function(){ console.info("the socket was opened") })
   *
   * @param {Function} callback
   */
  onOpen(callback) {
    let ref = this.makeRef();
    this.stateChangeCallbacks.open.push([ref, callback]);
    return ref;
  }
  /**
   * Registers callbacks for connection close events
   * @param {Function} callback
   */
  onClose(callback) {
    let ref = this.makeRef();
    this.stateChangeCallbacks.close.push([ref, callback]);
    return ref;
  }
  /**
   * Registers callbacks for connection error events
   *
   * @example socket.onError(function(error){ alert("An error occurred") })
   *
   * @param {Function} callback
   */
  onError(callback) {
    let ref = this.makeRef();
    this.stateChangeCallbacks.error.push([ref, callback]);
    return ref;
  }
  /**
   * Registers callbacks for connection message events
   * @param {Function} callback
   */
  onMessage(callback) {
    let ref = this.makeRef();
    this.stateChangeCallbacks.message.push([ref, callback]);
    return ref;
  }
  /**
   * Pings the server and invokes the callback with the RTT in milliseconds
   * @param {Function} callback
   *
   * Returns true if the ping was pushed or false if unable to be pushed.
   */
  ping(callback) {
    if (!this.isConnected()) {
      return false;
    }
    let ref = this.makeRef();
    let startTime = Date.now();
    this.push({ topic: "phoenix", event: "heartbeat", payload: {}, ref });
    let onMsgRef = this.onMessage((msg) => {
      if (msg.ref === ref) {
        this.off([onMsgRef]);
        callback(Date.now() - startTime);
      }
    });
    return true;
  }
  /**
   * @private
   */
  transportConnect() {
    this.connectClock++;
    this.closeWasClean = false;
    let protocols = void 0;
    if (this.authToken) {
      protocols = ["phoenix", `${AUTH_TOKEN_PREFIX}${btoa(this.authToken).replace(/=/g, "")}`];
    }
    this.conn = new this.transport(this.endPointURL(), protocols);
    this.conn.binaryType = this.binaryType;
    this.conn.timeout = this.longpollerTimeout;
    this.conn.onopen = () => this.onConnOpen();
    this.conn.onerror = (error) => this.onConnError(error);
    this.conn.onmessage = (event) => this.onConnMessage(event);
    this.conn.onclose = (event) => this.onConnClose(event);
  }
  getSession(key) {
    return this.sessionStore && this.sessionStore.getItem(key);
  }
  storeSession(key, val) {
    this.sessionStore && this.sessionStore.setItem(key, val);
  }
  connectWithFallback(fallbackTransport, fallbackThreshold = 2500) {
    clearTimeout(this.fallbackTimer);
    let established = false;
    let primaryTransport = true;
    let openRef, errorRef;
    let fallback = (reason) => {
      this.log("transport", `falling back to ${fallbackTransport.name}...`, reason);
      this.off([openRef, errorRef]);
      primaryTransport = false;
      this.replaceTransport(fallbackTransport);
      this.transportConnect();
    };
    if (this.getSession(`phx:fallback:${fallbackTransport.name}`)) {
      return fallback("memorized");
    }
    this.fallbackTimer = setTimeout(fallback, fallbackThreshold);
    errorRef = this.onError((reason) => {
      this.log("transport", "error", reason);
      if (primaryTransport && !established) {
        clearTimeout(this.fallbackTimer);
        fallback(reason);
      }
    });
    this.onOpen(() => {
      established = true;
      if (!primaryTransport) {
        if (!this.primaryPassedHealthCheck) {
          this.storeSession(`phx:fallback:${fallbackTransport.name}`, "true");
        }
        return this.log("transport", `established ${fallbackTransport.name} fallback`);
      }
      clearTimeout(this.fallbackTimer);
      this.fallbackTimer = setTimeout(fallback, fallbackThreshold);
      this.ping((rtt) => {
        this.log("transport", "connected to primary after", rtt);
        this.primaryPassedHealthCheck = true;
        clearTimeout(this.fallbackTimer);
      });
    });
    this.transportConnect();
  }
  clearHeartbeats() {
    clearTimeout(this.heartbeatTimer);
    clearTimeout(this.heartbeatTimeoutTimer);
  }
  onConnOpen() {
    if (this.hasLogger())
      this.log("transport", `${this.transport.name} connected to ${this.endPointURL()}`);
    this.closeWasClean = false;
    this.disconnecting = false;
    this.establishedConnections++;
    this.flushSendBuffer();
    this.reconnectTimer.reset();
    this.resetHeartbeat();
    this.stateChangeCallbacks.open.forEach(([, callback]) => callback());
  }
  /**
   * @private
   */
  heartbeatTimeout() {
    if (this.pendingHeartbeatRef) {
      this.pendingHeartbeatRef = null;
      if (this.hasLogger()) {
        this.log("transport", "heartbeat timeout. Attempting to re-establish connection");
      }
      this.triggerChanError();
      this.closeWasClean = false;
      this.teardown(() => this.reconnectTimer.scheduleTimeout(), WS_CLOSE_NORMAL, "heartbeat timeout");
    }
  }
  resetHeartbeat() {
    if (this.conn && this.conn.skipHeartbeat) {
      return;
    }
    this.pendingHeartbeatRef = null;
    this.clearHeartbeats();
    this.heartbeatTimer = setTimeout(() => this.sendHeartbeat(), this.heartbeatIntervalMs);
  }
  teardown(callback, code, reason) {
    if (!this.conn) {
      return callback && callback();
    }
    let connectClock = this.connectClock;
    this.waitForBufferDone(() => {
      if (connectClock !== this.connectClock) {
        return;
      }
      if (this.conn) {
        if (code) {
          this.conn.close(code, reason || "");
        } else {
          this.conn.close();
        }
      }
      this.waitForSocketClosed(() => {
        if (connectClock !== this.connectClock) {
          return;
        }
        if (this.conn) {
          this.conn.onopen = function() {
          };
          this.conn.onerror = function() {
          };
          this.conn.onmessage = function() {
          };
          this.conn.onclose = function() {
          };
          this.conn = null;
        }
        callback && callback();
      });
    });
  }
  waitForBufferDone(callback, tries = 1) {
    if (tries === 5 || !this.conn || !this.conn.bufferedAmount) {
      callback();
      return;
    }
    setTimeout(() => {
      this.waitForBufferDone(callback, tries + 1);
    }, 150 * tries);
  }
  waitForSocketClosed(callback, tries = 1) {
    if (tries === 5 || !this.conn || this.conn.readyState === SOCKET_STATES.closed) {
      callback();
      return;
    }
    setTimeout(() => {
      this.waitForSocketClosed(callback, tries + 1);
    }, 150 * tries);
  }
  onConnClose(event) {
    let closeCode = event && event.code;
    if (this.hasLogger())
      this.log("transport", "close", event);
    this.triggerChanError();
    this.clearHeartbeats();
    if (!this.closeWasClean && closeCode !== 1e3) {
      this.reconnectTimer.scheduleTimeout();
    }
    this.stateChangeCallbacks.close.forEach(([, callback]) => callback(event));
  }
  /**
   * @private
   */
  onConnError(error) {
    if (this.hasLogger())
      this.log("transport", error);
    let transportBefore = this.transport;
    let establishedBefore = this.establishedConnections;
    this.stateChangeCallbacks.error.forEach(([, callback]) => {
      callback(error, transportBefore, establishedBefore);
    });
    if (transportBefore === this.transport || establishedBefore > 0) {
      this.triggerChanError();
    }
  }
  /**
   * @private
   */
  triggerChanError() {
    this.channels.forEach((channel) => {
      if (!(channel.isErrored() || channel.isLeaving() || channel.isClosed())) {
        channel.trigger(CHANNEL_EVENTS.error);
      }
    });
  }
  /**
   * @returns {string}
   */
  connectionState() {
    switch (this.conn && this.conn.readyState) {
      case SOCKET_STATES.connecting:
        return "connecting";
      case SOCKET_STATES.open:
        return "open";
      case SOCKET_STATES.closing:
        return "closing";
      default:
        return "closed";
    }
  }
  /**
   * @returns {boolean}
   */
  isConnected() {
    return this.connectionState() === "open";
  }
  /**
   * @private
   *
   * @param {Channel}
   */
  remove(channel) {
    this.off(channel.stateChangeRefs);
    this.channels = this.channels.filter((c) => c !== channel);
  }
  /**
   * Removes `onOpen`, `onClose`, `onError,` and `onMessage` registrations.
   *
   * @param {refs} - list of refs returned by calls to
   *                 `onOpen`, `onClose`, `onError,` and `onMessage`
   */
  off(refs) {
    for (let key in this.stateChangeCallbacks) {
      this.stateChangeCallbacks[key] = this.stateChangeCallbacks[key].filter(([ref]) => {
        return refs.indexOf(ref) === -1;
      });
    }
  }
  /**
   * Initiates a new channel for the given topic
   *
   * @param {string} topic
   * @param {Object} chanParams - Parameters for the channel
   * @returns {Channel}
   */
  channel(topic, chanParams = {}) {
    let chan = new Channel(topic, chanParams, this);
    this.channels.push(chan);
    return chan;
  }
  /**
   * @param {Object} data
   */
  push(data) {
    if (this.hasLogger()) {
      let { topic, event, payload, ref, join_ref } = data;
      this.log("push", `${topic} ${event} (${join_ref}, ${ref})`, payload);
    }
    if (this.isConnected()) {
      this.encode(data, (result) => this.conn.send(result));
    } else {
      this.sendBuffer.push(() => this.encode(data, (result) => this.conn.send(result)));
    }
  }
  /**
   * Return the next message ref, accounting for overflows
   * @returns {string}
   */
  makeRef() {
    let newRef = this.ref + 1;
    if (newRef === this.ref) {
      this.ref = 0;
    } else {
      this.ref = newRef;
    }
    return this.ref.toString();
  }
  sendHeartbeat() {
    if (this.pendingHeartbeatRef && !this.isConnected()) {
      return;
    }
    this.pendingHeartbeatRef = this.makeRef();
    this.push({ topic: "phoenix", event: "heartbeat", payload: {}, ref: this.pendingHeartbeatRef });
    this.heartbeatTimeoutTimer = setTimeout(() => this.heartbeatTimeout(), this.heartbeatIntervalMs);
  }
  flushSendBuffer() {
    if (this.isConnected() && this.sendBuffer.length > 0) {
      this.sendBuffer.forEach((callback) => callback());
      this.sendBuffer = [];
    }
  }
  onConnMessage(rawMessage) {
    this.decode(rawMessage.data, (msg) => {
      let { topic, event, payload, ref, join_ref } = msg;
      if (ref && ref === this.pendingHeartbeatRef) {
        this.clearHeartbeats();
        this.pendingHeartbeatRef = null;
        this.heartbeatTimer = setTimeout(() => this.sendHeartbeat(), this.heartbeatIntervalMs);
      }
      if (this.hasLogger())
        this.log("receive", `${payload.status || ""} ${topic} ${event} ${ref && "(" + ref + ")" || ""}`, payload);
      for (let i = 0; i < this.channels.length; i++) {
        const channel = this.channels[i];
        if (!channel.isMember(topic, event, payload, join_ref)) {
          continue;
        }
        channel.trigger(event, payload, ref, join_ref);
      }
      for (let i = 0; i < this.stateChangeCallbacks.message.length; i++) {
        let [, callback] = this.stateChangeCallbacks.message[i];
        callback(msg);
      }
    });
  }
  leaveOpenTopic(topic) {
    let dupChannel = this.channels.find((c) => c.topic === topic && (c.isJoined() || c.isJoining()));
    if (dupChannel) {
      if (this.hasLogger())
        this.log("transport", `leaving duplicate topic "${topic}"`);
      dupChannel.leave();
    }
  }
};

// deps/phoenix_live_view/priv/static/phoenix_live_view.esm.js
var CONSECUTIVE_RELOADS = "consecutive-reloads";
var MAX_RELOADS = 10;
var RELOAD_JITTER_MIN = 5e3;
var RELOAD_JITTER_MAX = 1e4;
var FAILSAFE_JITTER = 3e4;
var PHX_EVENT_CLASSES = [
  "phx-click-loading",
  "phx-change-loading",
  "phx-submit-loading",
  "phx-keydown-loading",
  "phx-keyup-loading",
  "phx-blur-loading",
  "phx-focus-loading",
  "phx-hook-loading"
];
var PHX_COMPONENT = "data-phx-component";
var PHX_VIEW_REF = "data-phx-view";
var PHX_LIVE_LINK = "data-phx-link";
var PHX_TRACK_STATIC = "track-static";
var PHX_LINK_STATE = "data-phx-link-state";
var PHX_REF_LOADING = "data-phx-ref-loading";
var PHX_REF_SRC = "data-phx-ref-src";
var PHX_REF_LOCK = "data-phx-ref-lock";
var PHX_PENDING_REFS = "phx-pending-refs";
var PHX_TRACK_UPLOADS = "track-uploads";
var PHX_UPLOAD_REF = "data-phx-upload-ref";
var PHX_PREFLIGHTED_REFS = "data-phx-preflighted-refs";
var PHX_DONE_REFS = "data-phx-done-refs";
var PHX_DROP_TARGET = "drop-target";
var PHX_ACTIVE_ENTRY_REFS = "data-phx-active-refs";
var PHX_LIVE_FILE_UPDATED = "phx:live-file:updated";
var PHX_SKIP = "data-phx-skip";
var PHX_MAGIC_ID = "data-phx-id";
var PHX_PRUNE = "data-phx-prune";
var PHX_CONNECTED_CLASS = "phx-connected";
var PHX_LOADING_CLASS = "phx-loading";
var PHX_ERROR_CLASS = "phx-error";
var PHX_CLIENT_ERROR_CLASS = "phx-client-error";
var PHX_SERVER_ERROR_CLASS = "phx-server-error";
var PHX_PARENT_ID = "data-phx-parent-id";
var PHX_MAIN = "data-phx-main";
var PHX_ROOT_ID = "data-phx-root-id";
var PHX_VIEWPORT_TOP = "viewport-top";
var PHX_VIEWPORT_BOTTOM = "viewport-bottom";
var PHX_TRIGGER_ACTION = "trigger-action";
var PHX_HAS_FOCUSED = "phx-has-focused";
var FOCUSABLE_INPUTS = [
  "text",
  "textarea",
  "number",
  "email",
  "password",
  "search",
  "tel",
  "url",
  "date",
  "time",
  "datetime-local",
  "color",
  "range"
];
var CHECKABLE_INPUTS = ["checkbox", "radio"];
var PHX_HAS_SUBMITTED = "phx-has-submitted";
var PHX_SESSION = "data-phx-session";
var PHX_VIEW_SELECTOR = `[${PHX_SESSION}]`;
var PHX_STICKY = "data-phx-sticky";
var PHX_STATIC = "data-phx-static";
var PHX_READONLY = "data-phx-readonly";
var PHX_DISABLED = "data-phx-disabled";
var PHX_DISABLE_WITH = "disable-with";
var PHX_DISABLE_WITH_RESTORE = "data-phx-disable-with-restore";
var PHX_HOOK = "hook";
var PHX_DEBOUNCE = "debounce";
var PHX_THROTTLE = "throttle";
var PHX_UPDATE = "update";
var PHX_STREAM = "stream";
var PHX_STREAM_REF = "data-phx-stream";
var PHX_PORTAL = "data-phx-portal";
var PHX_TELEPORTED_REF = "data-phx-teleported";
var PHX_TELEPORTED_SRC = "data-phx-teleported-src";
var PHX_RUNTIME_HOOK = "data-phx-runtime-hook";
var PHX_LV_PID = "data-phx-pid";
var PHX_KEY = "key";
var PHX_PRIVATE = "phxPrivate";
var PHX_AUTO_RECOVER = "auto-recover";
var PHX_LV_DEBUG = "phx:live-socket:debug";
var PHX_LV_PROFILE = "phx:live-socket:profiling";
var PHX_LV_LATENCY_SIM = "phx:live-socket:latency-sim";
var PHX_LV_HISTORY_POSITION = "phx:nav-history-position";
var PHX_PROGRESS = "progress";
var PHX_MOUNTED = "mounted";
var PHX_RELOAD_STATUS = "__phoenix_reload_status__";
var LOADER_TIMEOUT = 1;
var MAX_CHILD_JOIN_ATTEMPTS = 3;
var BEFORE_UNLOAD_LOADER_TIMEOUT = 200;
var DISCONNECTED_TIMEOUT = 500;
var BINDING_PREFIX = "phx-";
var PUSH_TIMEOUT = 3e4;
var DEBOUNCE_TRIGGER = "debounce-trigger";
var THROTTLED = "throttled";
var DEBOUNCE_PREV_KEY = "debounce-prev-key";
var DEFAULTS = {
  debounce: 300,
  throttle: 300
};
var PHX_PENDING_ATTRS = [PHX_REF_LOADING, PHX_REF_SRC, PHX_REF_LOCK];
var STATIC = "s";
var ROOT = "r";
var COMPONENTS = "c";
var KEYED = "k";
var KEYED_COUNT = "kc";
var EVENTS = "e";
var REPLY = "r";
var TITLE = "t";
var TEMPLATES = "p";
var STREAM = "stream";
var EntryUploader = class {
  constructor(entry, config, liveSocket2) {
    const { chunk_size, chunk_timeout } = config;
    this.liveSocket = liveSocket2;
    this.entry = entry;
    this.offset = 0;
    this.chunkSize = chunk_size;
    this.chunkTimeout = chunk_timeout;
    this.chunkTimer = null;
    this.errored = false;
    this.uploadChannel = liveSocket2.channel(`lvu:${entry.ref}`, {
      token: entry.metadata()
    });
  }
  error(reason) {
    if (this.errored) {
      return;
    }
    this.uploadChannel.leave();
    this.errored = true;
    clearTimeout(this.chunkTimer);
    this.entry.error(reason);
  }
  upload() {
    this.uploadChannel.onError((reason) => this.error(reason));
    this.uploadChannel.join().receive("ok", (_data) => this.readNextChunk()).receive("error", (reason) => this.error(reason));
  }
  isDone() {
    return this.offset >= this.entry.file.size;
  }
  readNextChunk() {
    const reader = new window.FileReader();
    const blob = this.entry.file.slice(
      this.offset,
      this.chunkSize + this.offset
    );
    reader.onload = (e) => {
      if (e.target.error === null) {
        this.offset += /** @type {ArrayBuffer} */
        e.target.result.byteLength;
        this.pushChunk(
          /** @type {ArrayBuffer} */
          e.target.result
        );
      } else {
        return logError("Read error: " + e.target.error);
      }
    };
    reader.readAsArrayBuffer(blob);
  }
  pushChunk(chunk) {
    if (!this.uploadChannel.isJoined()) {
      return;
    }
    this.uploadChannel.push("chunk", chunk, this.chunkTimeout).receive("ok", () => {
      this.entry.progress(this.offset / this.entry.file.size * 100);
      if (!this.isDone()) {
        this.chunkTimer = setTimeout(
          () => this.readNextChunk(),
          this.liveSocket.getLatencySim() || 0
        );
      }
    }).receive("error", ({ reason }) => this.error(reason));
  }
};
var logError = (msg, obj) => console.error && console.error(msg, obj);
var isCid = (cid) => {
  const type = typeof cid;
  return type === "number" || type === "string" && /^(0|[1-9]\d*)$/.test(cid);
};
function detectDuplicateIds() {
  const ids = /* @__PURE__ */ new Set();
  const elems = document.querySelectorAll("*[id]");
  for (let i = 0, len = elems.length; i < len; i++) {
    if (ids.has(elems[i].id)) {
      console.error(
        `Multiple IDs detected: ${elems[i].id}. Ensure unique element ids.`
      );
    } else {
      ids.add(elems[i].id);
    }
  }
}
function detectInvalidStreamInserts(inserts) {
  const errors = /* @__PURE__ */ new Set();
  Object.keys(inserts).forEach((id) => {
    const streamEl = document.getElementById(id);
    if (streamEl && streamEl.parentElement && streamEl.parentElement.getAttribute("phx-update") !== "stream") {
      errors.add(
        `The stream container with id "${streamEl.parentElement.id}" is missing the phx-update="stream" attribute. Ensure it is set for streams to work properly.`
      );
    }
  });
  errors.forEach((error) => console.error(error));
}
var debug = (view, kind, msg, obj) => {
  if (view.liveSocket.isDebugEnabled()) {
    console.log(`${view.id} ${kind}: ${msg} - `, obj);
  }
};
var closure2 = (val) => typeof val === "function" ? val : function() {
  return val;
};
var clone = (obj) => {
  return JSON.parse(JSON.stringify(obj));
};
var closestPhxBinding = (el, binding, borderEl) => {
  do {
    if (el.matches(`[${binding}]`) && !el.disabled) {
      return el;
    }
    el = el.parentElement || el.parentNode;
  } while (el !== null && el.nodeType === 1 && !(borderEl && borderEl.isSameNode(el) || el.matches(PHX_VIEW_SELECTOR)));
  return null;
};
var isObject = (obj) => {
  return obj !== null && typeof obj === "object" && !(obj instanceof Array);
};
var isEqualObj = (obj1, obj2) => JSON.stringify(obj1) === JSON.stringify(obj2);
var isEmpty = (obj) => {
  for (const x in obj) {
    return false;
  }
  return true;
};
var maybe = (el, callback) => el && callback(el);
var channelUploader = function(entries, onError, resp, liveSocket2) {
  entries.forEach((entry) => {
    const entryUploader = new EntryUploader(entry, resp.config, liveSocket2);
    entryUploader.upload();
  });
};
var Browser = {
  canPushState() {
    return typeof history.pushState !== "undefined";
  },
  dropLocal(localStorage2, namespace, subkey) {
    return localStorage2.removeItem(this.localKey(namespace, subkey));
  },
  updateLocal(localStorage2, namespace, subkey, initial, func) {
    const current = this.getLocal(localStorage2, namespace, subkey);
    const key = this.localKey(namespace, subkey);
    const newVal = current === null ? initial : func(current);
    localStorage2.setItem(key, JSON.stringify(newVal));
    return newVal;
  },
  getLocal(localStorage2, namespace, subkey) {
    return JSON.parse(localStorage2.getItem(this.localKey(namespace, subkey)));
  },
  updateCurrentState(callback) {
    if (!this.canPushState()) {
      return;
    }
    history.replaceState(
      callback(history.state || {}),
      "",
      window.location.href
    );
  },
  pushState(kind, meta, to) {
    if (this.canPushState()) {
      if (to !== window.location.href) {
        if (meta.type == "redirect" && meta.scroll) {
          const currentState = history.state || {};
          currentState.scroll = meta.scroll;
          history.replaceState(currentState, "", window.location.href);
        }
        delete meta.scroll;
        history[kind + "State"](meta, "", to || null);
        window.requestAnimationFrame(() => {
          const hashEl = this.getHashTargetEl(window.location.hash);
          if (hashEl) {
            hashEl.scrollIntoView();
          } else if (meta.type === "redirect") {
            window.scroll(0, 0);
          }
        });
      }
    } else {
      this.redirect(to);
    }
  },
  setCookie(name, value, maxAgeSeconds) {
    const expires = typeof maxAgeSeconds === "number" ? ` max-age=${maxAgeSeconds};` : "";
    document.cookie = `${name}=${value};${expires} path=/`;
  },
  getCookie(name) {
    return document.cookie.replace(
      new RegExp(`(?:(?:^|.*;s*)${name}s*=s*([^;]*).*$)|^.*$`),
      "$1"
    );
  },
  deleteCookie(name) {
    document.cookie = `${name}=; max-age=-1; path=/`;
  },
  redirect(toURL, flash, navigate = (url) => {
    window.location.href = url;
  }) {
    if (flash) {
      this.setCookie("__phoenix_flash__", flash, 60);
    }
    navigate(toURL);
  },
  localKey(namespace, subkey) {
    return `${namespace}-${subkey}`;
  },
  getHashTargetEl(maybeHash) {
    const hash = maybeHash.toString().substring(1);
    if (hash === "") {
      return;
    }
    return document.getElementById(hash) || document.querySelector(`a[name="${hash}"]`);
  }
};
var browser_default = Browser;
var DOM = {
  byId(id) {
    return document.getElementById(id) || logError(`no id found for ${id}`);
  },
  removeClass(el, className) {
    el.classList.remove(className);
    if (el.classList.length === 0) {
      el.removeAttribute("class");
    }
  },
  all(node, query, callback) {
    if (!node) {
      return [];
    }
    const array = Array.from(node.querySelectorAll(query));
    if (callback) {
      array.forEach(callback);
    }
    return array;
  },
  childNodeLength(html) {
    const template = document.createElement("template");
    template.innerHTML = html;
    return template.content.childElementCount;
  },
  isUploadInput(el) {
    return el.type === "file" && el.getAttribute(PHX_UPLOAD_REF) !== null;
  },
  isAutoUpload(inputEl) {
    return inputEl.hasAttribute("data-phx-auto-upload");
  },
  findUploadInputs(node) {
    const formId = node.id;
    const inputsOutsideForm = this.all(
      document,
      `input[type="file"][${PHX_UPLOAD_REF}][form="${formId}"]`
    );
    return this.all(node, `input[type="file"][${PHX_UPLOAD_REF}]`).concat(
      inputsOutsideForm
    );
  },
  findComponentNodeList(viewId, cid, doc2 = document) {
    return this.all(
      doc2,
      `[${PHX_VIEW_REF}="${viewId}"][${PHX_COMPONENT}="${cid}"]`
    );
  },
  isPhxDestroyed(node) {
    return node.id && DOM.private(node, "destroyed") ? true : false;
  },
  wantsNewTab(e) {
    const wantsNewTab = e.ctrlKey || e.shiftKey || e.metaKey || e.button && e.button === 1;
    const isDownload = e.target instanceof HTMLAnchorElement && e.target.hasAttribute("download");
    const isTargetBlank = e.target.hasAttribute("target") && e.target.getAttribute("target").toLowerCase() === "_blank";
    const isTargetNamedTab = e.target.hasAttribute("target") && !e.target.getAttribute("target").startsWith("_");
    return wantsNewTab || isTargetBlank || isDownload || isTargetNamedTab;
  },
  isUnloadableFormSubmit(e) {
    const isDialogSubmit = e.target && e.target.getAttribute("method") === "dialog" || e.submitter && e.submitter.getAttribute("formmethod") === "dialog";
    if (isDialogSubmit) {
      return false;
    } else {
      return !e.defaultPrevented && !this.wantsNewTab(e);
    }
  },
  isNewPageClick(e, currentLocation) {
    const href = e.target instanceof HTMLAnchorElement ? e.target.getAttribute("href") : null;
    let url;
    if (e.defaultPrevented || href === null || this.wantsNewTab(e)) {
      return false;
    }
    if (href.startsWith("mailto:") || href.startsWith("tel:")) {
      return false;
    }
    if (e.target.isContentEditable) {
      return false;
    }
    try {
      url = new URL(href);
    } catch {
      try {
        url = new URL(href, currentLocation);
      } catch {
        return true;
      }
    }
    if (url.host === currentLocation.host && url.protocol === currentLocation.protocol) {
      if (url.pathname === currentLocation.pathname && url.search === currentLocation.search) {
        return url.hash === "" && !url.href.endsWith("#");
      }
    }
    return url.protocol.startsWith("http");
  },
  markPhxChildDestroyed(el) {
    if (this.isPhxChild(el)) {
      el.setAttribute(PHX_SESSION, "");
    }
    this.putPrivate(el, "destroyed", true);
  },
  findPhxChildrenInFragment(html, parentId) {
    const template = document.createElement("template");
    template.innerHTML = html;
    return this.findPhxChildren(template.content, parentId);
  },
  isIgnored(el, phxUpdate) {
    return (el.getAttribute(phxUpdate) || el.getAttribute("data-phx-update")) === "ignore";
  },
  isPhxUpdate(el, phxUpdate, updateTypes) {
    return el.getAttribute && updateTypes.indexOf(el.getAttribute(phxUpdate)) >= 0;
  },
  findPhxSticky(el) {
    return this.all(el, `[${PHX_STICKY}]`);
  },
  findPhxChildren(el, parentId) {
    return this.all(el, `${PHX_VIEW_SELECTOR}[${PHX_PARENT_ID}="${parentId}"]`);
  },
  findExistingParentCIDs(viewId, cids) {
    const parentCids = /* @__PURE__ */ new Set();
    const childrenCids = /* @__PURE__ */ new Set();
    cids.forEach((cid) => {
      this.all(
        document,
        `[${PHX_VIEW_REF}="${viewId}"][${PHX_COMPONENT}="${cid}"]`
      ).forEach((parent) => {
        parentCids.add(cid);
        this.all(parent, `[${PHX_VIEW_REF}="${viewId}"][${PHX_COMPONENT}]`).map((el) => parseInt(el.getAttribute(PHX_COMPONENT))).forEach((childCID) => childrenCids.add(childCID));
      });
    });
    childrenCids.forEach((childCid) => parentCids.delete(childCid));
    return parentCids;
  },
  private(el, key) {
    return el[PHX_PRIVATE] && el[PHX_PRIVATE][key];
  },
  deletePrivate(el, key) {
    el[PHX_PRIVATE] && delete el[PHX_PRIVATE][key];
  },
  putPrivate(el, key, value) {
    if (!el[PHX_PRIVATE]) {
      el[PHX_PRIVATE] = {};
    }
    el[PHX_PRIVATE][key] = value;
  },
  updatePrivate(el, key, defaultVal, updateFunc) {
    const existing = this.private(el, key);
    if (existing === void 0) {
      this.putPrivate(el, key, updateFunc(defaultVal));
    } else {
      this.putPrivate(el, key, updateFunc(existing));
    }
  },
  syncPendingAttrs(fromEl, toEl) {
    if (!fromEl.hasAttribute(PHX_REF_SRC)) {
      return;
    }
    PHX_EVENT_CLASSES.forEach((className) => {
      fromEl.classList.contains(className) && toEl.classList.add(className);
    });
    PHX_PENDING_ATTRS.filter((attr) => fromEl.hasAttribute(attr)).forEach(
      (attr) => {
        toEl.setAttribute(attr, fromEl.getAttribute(attr));
      }
    );
  },
  copyPrivates(target, source) {
    if (source[PHX_PRIVATE]) {
      target[PHX_PRIVATE] = source[PHX_PRIVATE];
    }
  },
  putTitle(str) {
    const titleEl = document.querySelector("title");
    if (titleEl) {
      const { prefix, suffix, default: defaultTitle } = titleEl.dataset;
      const isEmpty2 = typeof str !== "string" || str.trim() === "";
      if (isEmpty2 && typeof defaultTitle !== "string") {
        return;
      }
      const inner = isEmpty2 ? defaultTitle : str;
      document.title = `${prefix || ""}${inner || ""}${suffix || ""}`;
    } else {
      document.title = str;
    }
  },
  debounce(el, event, phxDebounce, defaultDebounce, phxThrottle, defaultThrottle, asyncFilter, callback) {
    let debounce = el.getAttribute(phxDebounce);
    let throttle = el.getAttribute(phxThrottle);
    if (debounce === "") {
      debounce = defaultDebounce;
    }
    if (throttle === "") {
      throttle = defaultThrottle;
    }
    const value = debounce || throttle;
    switch (value) {
      case null:
        return callback();
      case "blur":
        this.incCycle(el, "debounce-blur-cycle", () => {
          if (asyncFilter()) {
            callback();
          }
        });
        if (this.once(el, "debounce-blur")) {
          el.addEventListener(
            "blur",
            () => this.triggerCycle(el, "debounce-blur-cycle")
          );
        }
        return;
      default:
        const timeout = parseInt(value);
        const trigger = () => throttle ? this.deletePrivate(el, THROTTLED) : callback();
        const currentCycle = this.incCycle(el, DEBOUNCE_TRIGGER, trigger);
        if (isNaN(timeout)) {
          return logError(`invalid throttle/debounce value: ${value}`);
        }
        if (throttle) {
          let newKeyDown = false;
          if (event.type === "keydown") {
            const prevKey = this.private(el, DEBOUNCE_PREV_KEY);
            this.putPrivate(el, DEBOUNCE_PREV_KEY, event.key);
            newKeyDown = prevKey !== event.key;
          }
          if (!newKeyDown && this.private(el, THROTTLED)) {
            return false;
          } else {
            callback();
            const t = setTimeout(() => {
              if (asyncFilter()) {
                this.triggerCycle(el, DEBOUNCE_TRIGGER);
              }
            }, timeout);
            this.putPrivate(el, THROTTLED, t);
          }
        } else {
          setTimeout(() => {
            if (asyncFilter()) {
              this.triggerCycle(el, DEBOUNCE_TRIGGER, currentCycle);
            }
          }, timeout);
        }
        const form = el.form;
        if (form && this.once(form, "bind-debounce")) {
          form.addEventListener("submit", () => {
            Array.from(new FormData(form).entries(), ([name]) => {
              const input = form.querySelector(`[name="${name}"]`);
              this.incCycle(input, DEBOUNCE_TRIGGER);
              this.deletePrivate(input, THROTTLED);
            });
          });
        }
        if (this.once(el, "bind-debounce")) {
          el.addEventListener("blur", () => {
            clearTimeout(this.private(el, THROTTLED));
            this.triggerCycle(el, DEBOUNCE_TRIGGER);
          });
        }
    }
  },
  triggerCycle(el, key, currentCycle) {
    const [cycle, trigger] = this.private(el, key);
    if (!currentCycle) {
      currentCycle = cycle;
    }
    if (currentCycle === cycle) {
      this.incCycle(el, key);
      trigger();
    }
  },
  once(el, key) {
    if (this.private(el, key) === true) {
      return false;
    }
    this.putPrivate(el, key, true);
    return true;
  },
  incCycle(el, key, trigger = function() {
  }) {
    let [currentCycle] = this.private(el, key) || [0, trigger];
    currentCycle++;
    this.putPrivate(el, key, [currentCycle, trigger]);
    return currentCycle;
  },
  // maintains or adds privately used hook information
  // fromEl and toEl can be the same element in the case of a newly added node
  // fromEl and toEl can be any HTML node type, so we need to check if it's an element node
  maintainPrivateHooks(fromEl, toEl, phxViewportTop, phxViewportBottom) {
    if (fromEl.hasAttribute && fromEl.hasAttribute("data-phx-hook") && !toEl.hasAttribute("data-phx-hook")) {
      toEl.setAttribute("data-phx-hook", fromEl.getAttribute("data-phx-hook"));
    }
    if (toEl.hasAttribute && (toEl.hasAttribute(phxViewportTop) || toEl.hasAttribute(phxViewportBottom))) {
      toEl.setAttribute("data-phx-hook", "Phoenix.InfiniteScroll");
    }
  },
  putCustomElHook(el, hook) {
    if (el.isConnected) {
      el.setAttribute("data-phx-hook", "");
    } else {
      console.error(`
        hook attached to non-connected DOM element
        ensure you are calling createHook within your connectedCallback. ${el.outerHTML}
      `);
    }
    this.putPrivate(el, "custom-el-hook", hook);
  },
  getCustomElHook(el) {
    return this.private(el, "custom-el-hook");
  },
  isUsedInput(el) {
    return el.nodeType === Node.ELEMENT_NODE && (this.private(el, PHX_HAS_FOCUSED) || this.private(el, PHX_HAS_SUBMITTED));
  },
  resetForm(form) {
    Array.from(form.elements).forEach((input) => {
      this.deletePrivate(input, PHX_HAS_FOCUSED);
      this.deletePrivate(input, PHX_HAS_SUBMITTED);
    });
  },
  isPhxChild(node) {
    return node.getAttribute && node.getAttribute(PHX_PARENT_ID);
  },
  isPhxSticky(node) {
    return node.getAttribute && node.getAttribute(PHX_STICKY) !== null;
  },
  isChildOfAny(el, parents) {
    return !!parents.find((parent) => parent.contains(el));
  },
  firstPhxChild(el) {
    return this.isPhxChild(el) ? el : this.all(el, `[${PHX_PARENT_ID}]`)[0];
  },
  isPortalTemplate(el) {
    return el.tagName === "TEMPLATE" && el.hasAttribute(PHX_PORTAL);
  },
  closestViewEl(el) {
    const portalOrViewEl = el.closest(
      `[${PHX_TELEPORTED_REF}],${PHX_VIEW_SELECTOR}`
    );
    if (!portalOrViewEl) {
      return null;
    }
    if (portalOrViewEl.hasAttribute(PHX_TELEPORTED_REF)) {
      return this.byId(portalOrViewEl.getAttribute(PHX_TELEPORTED_REF));
    } else if (portalOrViewEl.hasAttribute(PHX_SESSION)) {
      return portalOrViewEl;
    }
    return null;
  },
  dispatchEvent(target, name, opts = {}) {
    let defaultBubble = true;
    const isUploadTarget = target.nodeName === "INPUT" && target.type === "file";
    if (isUploadTarget && name === "click") {
      defaultBubble = false;
    }
    const bubbles = opts.bubbles === void 0 ? defaultBubble : !!opts.bubbles;
    const eventOpts = {
      bubbles,
      cancelable: true,
      detail: opts.detail || {}
    };
    const event = name === "click" ? new MouseEvent("click", eventOpts) : new CustomEvent(name, eventOpts);
    target.dispatchEvent(event);
  },
  cloneNode(node, html) {
    if (typeof html === "undefined") {
      return node.cloneNode(true);
    } else {
      const cloned = node.cloneNode(false);
      cloned.innerHTML = html;
      return cloned;
    }
  },
  // merge attributes from source to target
  // if an element is ignored, we only merge data attributes
  // including removing data attributes that are no longer in the source
  mergeAttrs(target, source, opts = {}) {
    const exclude = new Set(opts.exclude || []);
    const isIgnored = opts.isIgnored;
    const sourceAttrs = source.attributes;
    for (let i = sourceAttrs.length - 1; i >= 0; i--) {
      const name = sourceAttrs[i].name;
      if (!exclude.has(name)) {
        const sourceValue = source.getAttribute(name);
        if (target.getAttribute(name) !== sourceValue && (!isIgnored || isIgnored && name.startsWith("data-"))) {
          target.setAttribute(name, sourceValue);
        }
      } else {
        if (name === "value") {
          const sourceValue = source.value ?? source.getAttribute(name);
          if (target.value === sourceValue) {
            target.setAttribute("value", source.getAttribute(name));
          }
        }
      }
    }
    const targetAttrs = target.attributes;
    for (let i = targetAttrs.length - 1; i >= 0; i--) {
      const name = targetAttrs[i].name;
      if (isIgnored) {
        if (name.startsWith("data-") && !source.hasAttribute(name) && !PHX_PENDING_ATTRS.includes(name)) {
          target.removeAttribute(name);
        }
      } else {
        if (!source.hasAttribute(name)) {
          target.removeAttribute(name);
        }
      }
    }
  },
  mergeFocusedInput(target, source) {
    if (!(target instanceof HTMLSelectElement)) {
      DOM.mergeAttrs(target, source, { exclude: ["value"] });
    }
    if (source.readOnly) {
      target.setAttribute("readonly", true);
    } else {
      target.removeAttribute("readonly");
    }
  },
  hasSelectionRange(el) {
    return el.setSelectionRange && (el.type === "text" || el.type === "textarea");
  },
  restoreFocus(focused, selectionStart, selectionEnd) {
    if (focused instanceof HTMLSelectElement) {
      focused.focus();
    }
    if (!DOM.isTextualInput(focused)) {
      return;
    }
    const wasFocused = focused.matches(":focus");
    if (!wasFocused) {
      focused.focus();
    }
    if (this.hasSelectionRange(focused)) {
      focused.setSelectionRange(selectionStart, selectionEnd);
    }
  },
  isFormInput(el) {
    if (el.localName && customElements.get(el.localName)) {
      return customElements.get(el.localName)[`formAssociated`];
    }
    return /^(?:input|select|textarea)$/i.test(el.tagName) && el.type !== "button";
  },
  syncAttrsToProps(el) {
    if (el instanceof HTMLInputElement && CHECKABLE_INPUTS.indexOf(el.type.toLocaleLowerCase()) >= 0) {
      el.checked = el.getAttribute("checked") !== null;
    }
  },
  isTextualInput(el) {
    return FOCUSABLE_INPUTS.indexOf(el.type) >= 0;
  },
  isNowTriggerFormExternal(el, phxTriggerExternal) {
    return el.getAttribute && el.getAttribute(phxTriggerExternal) !== null && document.body.contains(el);
  },
  cleanChildNodes(container, phxUpdate) {
    if (DOM.isPhxUpdate(container, phxUpdate, ["append", "prepend", PHX_STREAM])) {
      const toRemove = [];
      container.childNodes.forEach((childNode) => {
        if (!childNode.id) {
          const isEmptyTextNode = childNode.nodeType === Node.TEXT_NODE && childNode.nodeValue.trim() === "";
          if (!isEmptyTextNode && childNode.nodeType !== Node.COMMENT_NODE) {
            logError(
              `only HTML element tags with an id are allowed inside containers with phx-update.

removing illegal node: "${(childNode.outerHTML || childNode.nodeValue).trim()}"

`
            );
          }
          toRemove.push(childNode);
        }
      });
      toRemove.forEach((childNode) => childNode.remove());
    }
  },
  replaceRootContainer(container, tagName, attrs) {
    const retainedAttrs = /* @__PURE__ */ new Set([
      "id",
      PHX_SESSION,
      PHX_STATIC,
      PHX_MAIN,
      PHX_ROOT_ID
    ]);
    if (container.tagName.toLowerCase() === tagName.toLowerCase()) {
      Array.from(container.attributes).filter((attr) => !retainedAttrs.has(attr.name.toLowerCase())).forEach((attr) => container.removeAttribute(attr.name));
      Object.keys(attrs).filter((name) => !retainedAttrs.has(name.toLowerCase())).forEach((attr) => container.setAttribute(attr, attrs[attr]));
      return container;
    } else {
      const newContainer = document.createElement(tagName);
      Object.keys(attrs).forEach(
        (attr) => newContainer.setAttribute(attr, attrs[attr])
      );
      retainedAttrs.forEach(
        (attr) => newContainer.setAttribute(attr, container.getAttribute(attr))
      );
      newContainer.innerHTML = container.innerHTML;
      container.replaceWith(newContainer);
      return newContainer;
    }
  },
  getSticky(el, name, defaultVal) {
    const op = (DOM.private(el, "sticky") || []).find(
      ([existingName]) => name === existingName
    );
    if (op) {
      const [_name, _op, stashedResult] = op;
      return stashedResult;
    } else {
      return typeof defaultVal === "function" ? defaultVal() : defaultVal;
    }
  },
  deleteSticky(el, name) {
    this.updatePrivate(el, "sticky", [], (ops) => {
      return ops.filter(([existingName, _]) => existingName !== name);
    });
  },
  putSticky(el, name, op) {
    const stashedResult = op(el);
    this.updatePrivate(el, "sticky", [], (ops) => {
      const existingIndex = ops.findIndex(
        ([existingName]) => name === existingName
      );
      if (existingIndex >= 0) {
        ops[existingIndex] = [name, op, stashedResult];
      } else {
        ops.push([name, op, stashedResult]);
      }
      return ops;
    });
  },
  applyStickyOperations(el) {
    const ops = DOM.private(el, "sticky");
    if (!ops) {
      return;
    }
    ops.forEach(([name, op, _stashed]) => this.putSticky(el, name, op));
  },
  isLocked(el) {
    return el.hasAttribute && el.hasAttribute(PHX_REF_LOCK);
  }
};
var dom_default = DOM;
var UploadEntry = class {
  static isActive(fileEl, file) {
    const isNew = file._phxRef === void 0;
    const activeRefs = fileEl.getAttribute(PHX_ACTIVE_ENTRY_REFS).split(",");
    const isActive = activeRefs.indexOf(LiveUploader.genFileRef(file)) >= 0;
    return file.size > 0 && (isNew || isActive);
  }
  static isPreflighted(fileEl, file) {
    const preflightedRefs = fileEl.getAttribute(PHX_PREFLIGHTED_REFS).split(",");
    const isPreflighted = preflightedRefs.indexOf(LiveUploader.genFileRef(file)) >= 0;
    return isPreflighted && this.isActive(fileEl, file);
  }
  static isPreflightInProgress(file) {
    return file._preflightInProgress === true;
  }
  static markPreflightInProgress(file) {
    file._preflightInProgress = true;
  }
  constructor(fileEl, file, view, autoUpload) {
    this.ref = LiveUploader.genFileRef(file);
    this.fileEl = fileEl;
    this.file = file;
    this.view = view;
    this.meta = null;
    this._isCancelled = false;
    this._isDone = false;
    this._progress = 0;
    this._lastProgressSent = -1;
    this._onDone = function() {
    };
    this._onElUpdated = this.onElUpdated.bind(this);
    this.fileEl.addEventListener(PHX_LIVE_FILE_UPDATED, this._onElUpdated);
    this.autoUpload = autoUpload;
  }
  metadata() {
    return this.meta;
  }
  progress(progress) {
    this._progress = Math.floor(progress);
    if (this._progress > this._lastProgressSent) {
      if (this._progress >= 100) {
        this._progress = 100;
        this._lastProgressSent = 100;
        this._isDone = true;
        this.view.pushFileProgress(this.fileEl, this.ref, 100, () => {
          LiveUploader.untrackFile(this.fileEl, this.file);
          this._onDone();
        });
      } else {
        this._lastProgressSent = this._progress;
        this.view.pushFileProgress(this.fileEl, this.ref, this._progress);
      }
    }
  }
  isCancelled() {
    return this._isCancelled;
  }
  cancel() {
    this.file._preflightInProgress = false;
    this._isCancelled = true;
    this._isDone = true;
    this._onDone();
  }
  isDone() {
    return this._isDone;
  }
  error(reason = "failed") {
    this.fileEl.removeEventListener(PHX_LIVE_FILE_UPDATED, this._onElUpdated);
    this.view.pushFileProgress(this.fileEl, this.ref, { error: reason });
    if (!this.isAutoUpload()) {
      LiveUploader.clearFiles(this.fileEl);
    }
  }
  isAutoUpload() {
    return this.autoUpload;
  }
  //private
  onDone(callback) {
    this._onDone = () => {
      this.fileEl.removeEventListener(PHX_LIVE_FILE_UPDATED, this._onElUpdated);
      callback();
    };
  }
  onElUpdated() {
    const activeRefs = this.fileEl.getAttribute(PHX_ACTIVE_ENTRY_REFS).split(",");
    if (activeRefs.indexOf(this.ref) === -1) {
      LiveUploader.untrackFile(this.fileEl, this.file);
      this.cancel();
    }
  }
  toPreflightPayload() {
    return {
      last_modified: this.file.lastModified,
      name: this.file.name,
      relative_path: this.file.webkitRelativePath,
      size: this.file.size,
      type: this.file.type,
      ref: this.ref,
      meta: typeof this.file.meta === "function" ? this.file.meta() : void 0
    };
  }
  uploader(uploaders) {
    if (this.meta.uploader) {
      const callback = uploaders[this.meta.uploader] || logError(`no uploader configured for ${this.meta.uploader}`);
      return { name: this.meta.uploader, callback };
    } else {
      return { name: "channel", callback: channelUploader };
    }
  }
  zipPostFlight(resp) {
    this.meta = resp.entries[this.ref];
    if (!this.meta) {
      logError(`no preflight upload response returned with ref ${this.ref}`, {
        input: this.fileEl,
        response: resp
      });
    }
  }
};
var liveUploaderFileRef = 0;
var LiveUploader = class _LiveUploader {
  static genFileRef(file) {
    const ref = file._phxRef;
    if (ref !== void 0) {
      return ref;
    } else {
      file._phxRef = (liveUploaderFileRef++).toString();
      return file._phxRef;
    }
  }
  static getEntryDataURL(inputEl, ref, callback) {
    const file = this.activeFiles(inputEl).find(
      (file2) => this.genFileRef(file2) === ref
    );
    callback(URL.createObjectURL(file));
  }
  static hasUploadsInProgress(formEl) {
    let active = 0;
    dom_default.findUploadInputs(formEl).forEach((input) => {
      if (input.getAttribute(PHX_PREFLIGHTED_REFS) !== input.getAttribute(PHX_DONE_REFS)) {
        active++;
      }
    });
    return active > 0;
  }
  static serializeUploads(inputEl) {
    const files = this.activeFiles(inputEl);
    const fileData = {};
    files.forEach((file) => {
      const entry = { path: inputEl.name };
      const uploadRef = inputEl.getAttribute(PHX_UPLOAD_REF);
      fileData[uploadRef] = fileData[uploadRef] || [];
      entry.ref = this.genFileRef(file);
      entry.last_modified = file.lastModified;
      entry.name = file.name || entry.ref;
      entry.relative_path = file.webkitRelativePath;
      entry.type = file.type;
      entry.size = file.size;
      if (typeof file.meta === "function") {
        entry.meta = file.meta();
      }
      fileData[uploadRef].push(entry);
    });
    return fileData;
  }
  static clearFiles(inputEl) {
    inputEl.value = null;
    inputEl.removeAttribute(PHX_UPLOAD_REF);
    dom_default.putPrivate(inputEl, "files", []);
  }
  static untrackFile(inputEl, file) {
    dom_default.putPrivate(
      inputEl,
      "files",
      dom_default.private(inputEl, "files").filter((f) => !Object.is(f, file))
    );
  }
  /**
   * @param {HTMLInputElement} inputEl
   * @param {Array<File|Blob>} files
   * @param {DataTransfer} [dataTransfer]
   */
  static trackFiles(inputEl, files, dataTransfer) {
    if (inputEl.getAttribute("multiple") !== null) {
      const newFiles = files.filter(
        (file) => !this.activeFiles(inputEl).find((f) => Object.is(f, file))
      );
      dom_default.updatePrivate(
        inputEl,
        "files",
        [],
        (existing) => existing.concat(newFiles)
      );
      inputEl.value = null;
    } else {
      if (dataTransfer && dataTransfer.files.length > 0) {
        inputEl.files = dataTransfer.files;
      }
      dom_default.putPrivate(inputEl, "files", files);
    }
  }
  static activeFileInputs(formEl) {
    const fileInputs = dom_default.findUploadInputs(formEl);
    return Array.from(fileInputs).filter(
      (el) => el.files && this.activeFiles(el).length > 0
    );
  }
  static activeFiles(input) {
    return (dom_default.private(input, "files") || []).filter(
      (f) => UploadEntry.isActive(input, f)
    );
  }
  static inputsAwaitingPreflight(formEl) {
    const fileInputs = dom_default.findUploadInputs(formEl);
    return Array.from(fileInputs).filter(
      (input) => this.filesAwaitingPreflight(input).length > 0
    );
  }
  static filesAwaitingPreflight(input) {
    return this.activeFiles(input).filter(
      (f) => !UploadEntry.isPreflighted(input, f) && !UploadEntry.isPreflightInProgress(f)
    );
  }
  static markPreflightInProgress(entries) {
    entries.forEach((entry) => UploadEntry.markPreflightInProgress(entry.file));
  }
  constructor(inputEl, view, onComplete) {
    this.autoUpload = dom_default.isAutoUpload(inputEl);
    this.view = view;
    this.onComplete = onComplete;
    this._entries = Array.from(
      _LiveUploader.filesAwaitingPreflight(inputEl) || []
    ).map((file) => new UploadEntry(inputEl, file, view, this.autoUpload));
    _LiveUploader.markPreflightInProgress(this._entries);
    this.numEntriesInProgress = this._entries.length;
  }
  isAutoUpload() {
    return this.autoUpload;
  }
  entries() {
    return this._entries;
  }
  initAdapterUpload(resp, onError, liveSocket2) {
    this._entries = this._entries.map((entry) => {
      if (entry.isCancelled()) {
        this.numEntriesInProgress--;
        if (this.numEntriesInProgress === 0) {
          this.onComplete();
        }
      } else {
        entry.zipPostFlight(resp);
        entry.onDone(() => {
          this.numEntriesInProgress--;
          if (this.numEntriesInProgress === 0) {
            this.onComplete();
          }
        });
      }
      return entry;
    });
    const groupedEntries = this._entries.reduce((acc, entry) => {
      if (!entry.meta) {
        return acc;
      }
      const { name, callback } = entry.uploader(liveSocket2.uploaders);
      acc[name] = acc[name] || { callback, entries: [] };
      acc[name].entries.push(entry);
      return acc;
    }, {});
    for (const name in groupedEntries) {
      const { callback, entries } = groupedEntries[name];
      callback(entries, onError, resp, liveSocket2);
    }
  }
};
var ARIA = {
  anyOf(instance, classes) {
    return classes.find((name) => instance instanceof name);
  },
  isFocusable(el, interactiveOnly) {
    return el instanceof HTMLAnchorElement && el.rel !== "ignore" || el instanceof HTMLAreaElement && el.href !== void 0 || !el.disabled && this.anyOf(el, [
      HTMLInputElement,
      HTMLSelectElement,
      HTMLTextAreaElement,
      HTMLButtonElement
    ]) || el instanceof HTMLIFrameElement || el.tabIndex >= 0 && el.getAttribute("aria-hidden") !== "true" || !interactiveOnly && el.getAttribute("tabindex") !== null && el.getAttribute("aria-hidden") !== "true";
  },
  attemptFocus(el, interactiveOnly) {
    if (this.isFocusable(el, interactiveOnly)) {
      try {
        el.focus();
      } catch {
      }
    }
    return !!document.activeElement && document.activeElement.isSameNode(el);
  },
  focusFirstInteractive(el) {
    let child = el.firstElementChild;
    while (child) {
      if (this.attemptFocus(child, true) || this.focusFirstInteractive(child)) {
        return true;
      }
      child = child.nextElementSibling;
    }
  },
  focusFirst(el) {
    let child = el.firstElementChild;
    while (child) {
      if (this.attemptFocus(child) || this.focusFirst(child)) {
        return true;
      }
      child = child.nextElementSibling;
    }
  },
  focusLast(el) {
    let child = el.lastElementChild;
    while (child) {
      if (this.attemptFocus(child) || this.focusLast(child)) {
        return true;
      }
      child = child.previousElementSibling;
    }
  }
};
var aria_default = ARIA;
var Hooks = {
  LiveFileUpload: {
    activeRefs() {
      return this.el.getAttribute(PHX_ACTIVE_ENTRY_REFS);
    },
    preflightedRefs() {
      return this.el.getAttribute(PHX_PREFLIGHTED_REFS);
    },
    mounted() {
      this.preflightedWas = this.preflightedRefs();
    },
    updated() {
      const newPreflights = this.preflightedRefs();
      if (this.preflightedWas !== newPreflights) {
        this.preflightedWas = newPreflights;
        if (newPreflights === "") {
          this.__view().cancelSubmit(this.el.form);
        }
      }
      if (this.activeRefs() === "") {
        this.el.value = null;
      }
      this.el.dispatchEvent(new CustomEvent(PHX_LIVE_FILE_UPDATED));
    }
  },
  LiveImgPreview: {
    mounted() {
      this.ref = this.el.getAttribute("data-phx-entry-ref");
      this.inputEl = document.getElementById(
        this.el.getAttribute(PHX_UPLOAD_REF)
      );
      LiveUploader.getEntryDataURL(this.inputEl, this.ref, (url) => {
        this.url = url;
        this.el.src = url;
      });
    },
    destroyed() {
      URL.revokeObjectURL(this.url);
    }
  },
  FocusWrap: {
    mounted() {
      this.focusStart = this.el.firstElementChild;
      this.focusEnd = this.el.lastElementChild;
      this.focusStart.addEventListener("focus", (e) => {
        if (!e.relatedTarget || !this.el.contains(e.relatedTarget)) {
          const nextFocus = e.target.nextElementSibling;
          aria_default.attemptFocus(nextFocus) || aria_default.focusFirst(nextFocus);
        } else {
          aria_default.focusLast(this.el);
        }
      });
      this.focusEnd.addEventListener("focus", (e) => {
        if (!e.relatedTarget || !this.el.contains(e.relatedTarget)) {
          const nextFocus = e.target.previousElementSibling;
          aria_default.attemptFocus(nextFocus) || aria_default.focusLast(nextFocus);
        } else {
          aria_default.focusFirst(this.el);
        }
      });
      if (!this.el.contains(document.activeElement)) {
        this.el.addEventListener("phx:show-end", () => this.el.focus());
        if (window.getComputedStyle(this.el).display !== "none") {
          aria_default.focusFirst(this.el);
        }
      }
    }
  }
};
var findScrollContainer = (el) => {
  if (["HTML", "BODY"].indexOf(el.nodeName.toUpperCase()) >= 0)
    return null;
  if (["scroll", "auto"].indexOf(getComputedStyle(el).overflowY) >= 0)
    return el;
  return findScrollContainer(el.parentElement);
};
var scrollTop = (scrollContainer) => {
  if (scrollContainer) {
    return scrollContainer.scrollTop;
  } else {
    return document.documentElement.scrollTop || document.body.scrollTop;
  }
};
var bottom = (scrollContainer) => {
  if (scrollContainer) {
    return scrollContainer.getBoundingClientRect().bottom;
  } else {
    return window.innerHeight || document.documentElement.clientHeight;
  }
};
var top = (scrollContainer) => {
  if (scrollContainer) {
    return scrollContainer.getBoundingClientRect().top;
  } else {
    return 0;
  }
};
var isAtViewportTop = (el, scrollContainer) => {
  const rect = el.getBoundingClientRect();
  return Math.ceil(rect.top) >= top(scrollContainer) && Math.ceil(rect.left) >= 0 && Math.floor(rect.top) <= bottom(scrollContainer);
};
var isAtViewportBottom = (el, scrollContainer) => {
  const rect = el.getBoundingClientRect();
  return Math.ceil(rect.bottom) >= top(scrollContainer) && Math.ceil(rect.left) >= 0 && Math.floor(rect.bottom) <= bottom(scrollContainer);
};
var isWithinViewport = (el, scrollContainer) => {
  const rect = el.getBoundingClientRect();
  return Math.ceil(rect.top) >= top(scrollContainer) && Math.ceil(rect.left) >= 0 && Math.floor(rect.top) <= bottom(scrollContainer);
};
Hooks.InfiniteScroll = {
  mounted() {
    this.scrollContainer = findScrollContainer(this.el);
    let scrollBefore = scrollTop(this.scrollContainer);
    let topOverran = false;
    const throttleInterval = 500;
    let pendingOp = null;
    const onTopOverrun = this.throttle(
      throttleInterval,
      (topEvent, firstChild) => {
        pendingOp = () => true;
        this.liveSocket.js().push(this.el, topEvent, {
          value: { id: firstChild.id, _overran: true },
          callback: () => {
            pendingOp = null;
          }
        });
      }
    );
    const onFirstChildAtTop = this.throttle(
      throttleInterval,
      (topEvent, firstChild) => {
        pendingOp = () => firstChild.scrollIntoView({ block: "start" });
        this.liveSocket.js().push(this.el, topEvent, {
          value: { id: firstChild.id },
          callback: () => {
            pendingOp = null;
            window.requestAnimationFrame(() => {
              if (!isWithinViewport(firstChild, this.scrollContainer)) {
                firstChild.scrollIntoView({ block: "start" });
              }
            });
          }
        });
      }
    );
    const onLastChildAtBottom = this.throttle(
      throttleInterval,
      (bottomEvent, lastChild) => {
        pendingOp = () => lastChild.scrollIntoView({ block: "end" });
        this.liveSocket.js().push(this.el, bottomEvent, {
          value: { id: lastChild.id },
          callback: () => {
            pendingOp = null;
            window.requestAnimationFrame(() => {
              if (!isWithinViewport(lastChild, this.scrollContainer)) {
                lastChild.scrollIntoView({ block: "end" });
              }
            });
          }
        });
      }
    );
    this.onScroll = (_e) => {
      const scrollNow = scrollTop(this.scrollContainer);
      if (pendingOp) {
        scrollBefore = scrollNow;
        return pendingOp();
      }
      const rect = this.el.getBoundingClientRect();
      const topEvent = this.el.getAttribute(
        this.liveSocket.binding("viewport-top")
      );
      const bottomEvent = this.el.getAttribute(
        this.liveSocket.binding("viewport-bottom")
      );
      const lastChild = this.el.lastElementChild;
      const firstChild = this.el.firstElementChild;
      const isScrollingUp = scrollNow < scrollBefore;
      const isScrollingDown = scrollNow > scrollBefore;
      if (isScrollingUp && topEvent && !topOverran && rect.top >= 0) {
        topOverran = true;
        onTopOverrun(topEvent, firstChild);
      } else if (isScrollingDown && topOverran && rect.top <= 0) {
        topOverran = false;
      }
      if (topEvent && isScrollingUp && isAtViewportTop(firstChild, this.scrollContainer)) {
        onFirstChildAtTop(topEvent, firstChild);
      } else if (bottomEvent && isScrollingDown && isAtViewportBottom(lastChild, this.scrollContainer)) {
        onLastChildAtBottom(bottomEvent, lastChild);
      }
      scrollBefore = scrollNow;
    };
    if (this.scrollContainer) {
      this.scrollContainer.addEventListener("scroll", this.onScroll);
    } else {
      window.addEventListener("scroll", this.onScroll);
    }
  },
  destroyed() {
    if (this.scrollContainer) {
      this.scrollContainer.removeEventListener("scroll", this.onScroll);
    } else {
      window.removeEventListener("scroll", this.onScroll);
    }
  },
  throttle(interval, callback) {
    let lastCallAt = 0;
    let timer;
    return (...args) => {
      const now = Date.now();
      const remainingTime = interval - (now - lastCallAt);
      if (remainingTime <= 0 || remainingTime > interval) {
        if (timer) {
          clearTimeout(timer);
          timer = null;
        }
        lastCallAt = now;
        callback(...args);
      } else if (!timer) {
        timer = setTimeout(() => {
          lastCallAt = Date.now();
          timer = null;
          callback(...args);
        }, remainingTime);
      }
    };
  }
};
var hooks_default = Hooks;
var ElementRef = class {
  static onUnlock(el, callback) {
    if (!dom_default.isLocked(el) && !el.closest(`[${PHX_REF_LOCK}]`)) {
      return callback();
    }
    const closestLock = el.closest(`[${PHX_REF_LOCK}]`);
    const ref = closestLock.closest(`[${PHX_REF_LOCK}]`).getAttribute(PHX_REF_LOCK);
    closestLock.addEventListener(
      `phx:undo-lock:${ref}`,
      () => {
        callback();
      },
      { once: true }
    );
  }
  constructor(el) {
    this.el = el;
    this.loadingRef = el.hasAttribute(PHX_REF_LOADING) ? parseInt(el.getAttribute(PHX_REF_LOADING), 10) : null;
    this.lockRef = el.hasAttribute(PHX_REF_LOCK) ? parseInt(el.getAttribute(PHX_REF_LOCK), 10) : null;
  }
  // public
  maybeUndo(ref, phxEvent, eachCloneCallback) {
    if (!this.isWithin(ref)) {
      dom_default.updatePrivate(this.el, PHX_PENDING_REFS, [], (pendingRefs) => {
        pendingRefs.push(ref);
        return pendingRefs;
      });
      return;
    }
    this.undoLocks(ref, phxEvent, eachCloneCallback);
    this.undoLoading(ref, phxEvent);
    dom_default.updatePrivate(this.el, PHX_PENDING_REFS, [], (pendingRefs) => {
      return pendingRefs.filter((pendingRef) => {
        let opts = {
          detail: { ref: pendingRef, event: phxEvent },
          bubbles: true,
          cancelable: false
        };
        if (this.loadingRef && this.loadingRef > pendingRef) {
          this.el.dispatchEvent(
            new CustomEvent(`phx:undo-loading:${pendingRef}`, opts)
          );
        }
        if (this.lockRef && this.lockRef > pendingRef) {
          this.el.dispatchEvent(
            new CustomEvent(`phx:undo-lock:${pendingRef}`, opts)
          );
        }
        return pendingRef > ref;
      });
    });
    if (this.isFullyResolvedBy(ref)) {
      this.el.removeAttribute(PHX_REF_SRC);
    }
  }
  // private
  isWithin(ref) {
    return !(this.loadingRef !== null && this.loadingRef > ref && this.lockRef !== null && this.lockRef > ref);
  }
  // Check for cloned PHX_REF_LOCK element that has been morphed behind
  // the scenes while this element was locked in the DOM.
  // When we apply the cloned tree to the active DOM element, we must
  //
  //   1. execute pending mounted hooks for nodes now in the DOM
  //   2. undo any ref inside the cloned tree that has since been ack'd
  undoLocks(ref, phxEvent, eachCloneCallback) {
    if (!this.isLockUndoneBy(ref)) {
      return;
    }
    const clonedTree = dom_default.private(this.el, PHX_REF_LOCK);
    if (clonedTree) {
      eachCloneCallback(clonedTree);
      dom_default.deletePrivate(this.el, PHX_REF_LOCK);
    }
    this.el.removeAttribute(PHX_REF_LOCK);
    const opts = {
      detail: { ref, event: phxEvent },
      bubbles: true,
      cancelable: false
    };
    this.el.dispatchEvent(
      new CustomEvent(`phx:undo-lock:${this.lockRef}`, opts)
    );
  }
  undoLoading(ref, phxEvent) {
    if (!this.isLoadingUndoneBy(ref)) {
      if (this.canUndoLoading(ref) && this.el.classList.contains("phx-submit-loading")) {
        this.el.classList.remove("phx-change-loading");
      }
      return;
    }
    if (this.canUndoLoading(ref)) {
      this.el.removeAttribute(PHX_REF_LOADING);
      const disabledVal = this.el.getAttribute(PHX_DISABLED);
      const readOnlyVal = this.el.getAttribute(PHX_READONLY);
      if (readOnlyVal !== null) {
        this.el.readOnly = readOnlyVal === "true" ? true : false;
        this.el.removeAttribute(PHX_READONLY);
      }
      if (disabledVal !== null) {
        this.el.disabled = disabledVal === "true" ? true : false;
        this.el.removeAttribute(PHX_DISABLED);
      }
      const disableRestore = this.el.getAttribute(PHX_DISABLE_WITH_RESTORE);
      if (disableRestore !== null) {
        this.el.innerText = disableRestore;
        this.el.removeAttribute(PHX_DISABLE_WITH_RESTORE);
      }
      const opts = {
        detail: { ref, event: phxEvent },
        bubbles: true,
        cancelable: false
      };
      this.el.dispatchEvent(
        new CustomEvent(`phx:undo-loading:${this.loadingRef}`, opts)
      );
    }
    PHX_EVENT_CLASSES.forEach((name) => {
      if (name !== "phx-submit-loading" || this.canUndoLoading(ref)) {
        dom_default.removeClass(this.el, name);
      }
    });
  }
  isLoadingUndoneBy(ref) {
    return this.loadingRef === null ? false : this.loadingRef <= ref;
  }
  isLockUndoneBy(ref) {
    return this.lockRef === null ? false : this.lockRef <= ref;
  }
  isFullyResolvedBy(ref) {
    return (this.loadingRef === null || this.loadingRef <= ref) && (this.lockRef === null || this.lockRef <= ref);
  }
  // only remove the phx-submit-loading class if we are not locked
  canUndoLoading(ref) {
    return this.lockRef === null || this.lockRef <= ref;
  }
};
var DOMPostMorphRestorer = class {
  constructor(containerBefore, containerAfter, updateType) {
    const idsBefore = /* @__PURE__ */ new Set();
    const idsAfter = new Set(
      [...containerAfter.children].map((child) => child.id)
    );
    const elementsToModify = [];
    Array.from(containerBefore.children).forEach((child) => {
      if (child.id) {
        idsBefore.add(child.id);
        if (idsAfter.has(child.id)) {
          const previousElementId = child.previousElementSibling && child.previousElementSibling.id;
          elementsToModify.push({
            elementId: child.id,
            previousElementId
          });
        }
      }
    });
    this.containerId = containerAfter.id;
    this.updateType = updateType;
    this.elementsToModify = elementsToModify;
    this.elementIdsToAdd = [...idsAfter].filter((id) => !idsBefore.has(id));
  }
  // We do the following to optimize append/prepend operations:
  //   1) Track ids of modified elements & of new elements
  //   2) All the modified elements are put back in the correct position in the DOM tree
  //      by storing the id of their previous sibling
  //   3) New elements are going to be put in the right place by morphdom during append.
  //      For prepend, we move them to the first position in the container
  perform() {
    const container = dom_default.byId(this.containerId);
    if (!container) {
      return;
    }
    this.elementsToModify.forEach((elementToModify) => {
      if (elementToModify.previousElementId) {
        maybe(
          document.getElementById(elementToModify.previousElementId),
          (previousElem) => {
            maybe(
              document.getElementById(elementToModify.elementId),
              (elem) => {
                const isInRightPlace = elem.previousElementSibling && elem.previousElementSibling.id == previousElem.id;
                if (!isInRightPlace) {
                  previousElem.insertAdjacentElement("afterend", elem);
                }
              }
            );
          }
        );
      } else {
        maybe(document.getElementById(elementToModify.elementId), (elem) => {
          const isInRightPlace = elem.previousElementSibling == null;
          if (!isInRightPlace) {
            container.insertAdjacentElement("afterbegin", elem);
          }
        });
      }
    });
    if (this.updateType == "prepend") {
      this.elementIdsToAdd.reverse().forEach((elemId) => {
        maybe(
          document.getElementById(elemId),
          (elem) => container.insertAdjacentElement("afterbegin", elem)
        );
      });
    }
  }
};
var DOCUMENT_FRAGMENT_NODE = 11;
function morphAttrs(fromNode, toNode) {
  var toNodeAttrs = toNode.attributes;
  var attr;
  var attrName;
  var attrNamespaceURI;
  var attrValue;
  var fromValue;
  if (toNode.nodeType === DOCUMENT_FRAGMENT_NODE || fromNode.nodeType === DOCUMENT_FRAGMENT_NODE) {
    return;
  }
  for (var i = toNodeAttrs.length - 1; i >= 0; i--) {
    attr = toNodeAttrs[i];
    attrName = attr.name;
    attrNamespaceURI = attr.namespaceURI;
    attrValue = attr.value;
    if (attrNamespaceURI) {
      attrName = attr.localName || attrName;
      fromValue = fromNode.getAttributeNS(attrNamespaceURI, attrName);
      if (fromValue !== attrValue) {
        if (attr.prefix === "xmlns") {
          attrName = attr.name;
        }
        fromNode.setAttributeNS(attrNamespaceURI, attrName, attrValue);
      }
    } else {
      fromValue = fromNode.getAttribute(attrName);
      if (fromValue !== attrValue) {
        fromNode.setAttribute(attrName, attrValue);
      }
    }
  }
  var fromNodeAttrs = fromNode.attributes;
  for (var d = fromNodeAttrs.length - 1; d >= 0; d--) {
    attr = fromNodeAttrs[d];
    attrName = attr.name;
    attrNamespaceURI = attr.namespaceURI;
    if (attrNamespaceURI) {
      attrName = attr.localName || attrName;
      if (!toNode.hasAttributeNS(attrNamespaceURI, attrName)) {
        fromNode.removeAttributeNS(attrNamespaceURI, attrName);
      }
    } else {
      if (!toNode.hasAttribute(attrName)) {
        fromNode.removeAttribute(attrName);
      }
    }
  }
}
var range;
var NS_XHTML = "http://www.w3.org/1999/xhtml";
var doc = typeof document === "undefined" ? void 0 : document;
var HAS_TEMPLATE_SUPPORT = !!doc && "content" in doc.createElement("template");
var HAS_RANGE_SUPPORT = !!doc && doc.createRange && "createContextualFragment" in doc.createRange();
function createFragmentFromTemplate(str) {
  var template = doc.createElement("template");
  template.innerHTML = str;
  return template.content.childNodes[0];
}
function createFragmentFromRange(str) {
  if (!range) {
    range = doc.createRange();
    range.selectNode(doc.body);
  }
  var fragment = range.createContextualFragment(str);
  return fragment.childNodes[0];
}
function createFragmentFromWrap(str) {
  var fragment = doc.createElement("body");
  fragment.innerHTML = str;
  return fragment.childNodes[0];
}
function toElement(str) {
  str = str.trim();
  if (HAS_TEMPLATE_SUPPORT) {
    return createFragmentFromTemplate(str);
  } else if (HAS_RANGE_SUPPORT) {
    return createFragmentFromRange(str);
  }
  return createFragmentFromWrap(str);
}
function compareNodeNames(fromEl, toEl) {
  var fromNodeName = fromEl.nodeName;
  var toNodeName = toEl.nodeName;
  var fromCodeStart, toCodeStart;
  if (fromNodeName === toNodeName) {
    return true;
  }
  fromCodeStart = fromNodeName.charCodeAt(0);
  toCodeStart = toNodeName.charCodeAt(0);
  if (fromCodeStart <= 90 && toCodeStart >= 97) {
    return fromNodeName === toNodeName.toUpperCase();
  } else if (toCodeStart <= 90 && fromCodeStart >= 97) {
    return toNodeName === fromNodeName.toUpperCase();
  } else {
    return false;
  }
}
function createElementNS(name, namespaceURI) {
  return !namespaceURI || namespaceURI === NS_XHTML ? doc.createElement(name) : doc.createElementNS(namespaceURI, name);
}
function moveChildren(fromEl, toEl) {
  var curChild = fromEl.firstChild;
  while (curChild) {
    var nextChild = curChild.nextSibling;
    toEl.appendChild(curChild);
    curChild = nextChild;
  }
  return toEl;
}
function syncBooleanAttrProp(fromEl, toEl, name) {
  if (fromEl[name] !== toEl[name]) {
    fromEl[name] = toEl[name];
    if (fromEl[name]) {
      fromEl.setAttribute(name, "");
    } else {
      fromEl.removeAttribute(name);
    }
  }
}
var specialElHandlers = {
  OPTION: function(fromEl, toEl) {
    var parentNode = fromEl.parentNode;
    if (parentNode) {
      var parentName = parentNode.nodeName.toUpperCase();
      if (parentName === "OPTGROUP") {
        parentNode = parentNode.parentNode;
        parentName = parentNode && parentNode.nodeName.toUpperCase();
      }
      if (parentName === "SELECT" && !parentNode.hasAttribute("multiple")) {
        if (fromEl.hasAttribute("selected") && !toEl.selected) {
          fromEl.setAttribute("selected", "selected");
          fromEl.removeAttribute("selected");
        }
        parentNode.selectedIndex = -1;
      }
    }
    syncBooleanAttrProp(fromEl, toEl, "selected");
  },
  /**
   * The "value" attribute is special for the <input> element since it sets
   * the initial value. Changing the "value" attribute without changing the
   * "value" property will have no effect since it is only used to the set the
   * initial value.  Similar for the "checked" attribute, and "disabled".
   */
  INPUT: function(fromEl, toEl) {
    syncBooleanAttrProp(fromEl, toEl, "checked");
    syncBooleanAttrProp(fromEl, toEl, "disabled");
    if (fromEl.value !== toEl.value) {
      fromEl.value = toEl.value;
    }
    if (!toEl.hasAttribute("value")) {
      fromEl.removeAttribute("value");
    }
  },
  TEXTAREA: function(fromEl, toEl) {
    var newValue = toEl.value;
    if (fromEl.value !== newValue) {
      fromEl.value = newValue;
    }
    var firstChild = fromEl.firstChild;
    if (firstChild) {
      var oldValue = firstChild.nodeValue;
      if (oldValue == newValue || !newValue && oldValue == fromEl.placeholder) {
        return;
      }
      firstChild.nodeValue = newValue;
    }
  },
  SELECT: function(fromEl, toEl) {
    if (!toEl.hasAttribute("multiple")) {
      var selectedIndex = -1;
      var i = 0;
      var curChild = fromEl.firstChild;
      var optgroup;
      var nodeName;
      while (curChild) {
        nodeName = curChild.nodeName && curChild.nodeName.toUpperCase();
        if (nodeName === "OPTGROUP") {
          optgroup = curChild;
          curChild = optgroup.firstChild;
          if (!curChild) {
            curChild = optgroup.nextSibling;
            optgroup = null;
          }
        } else {
          if (nodeName === "OPTION") {
            if (curChild.hasAttribute("selected")) {
              selectedIndex = i;
              break;
            }
            i++;
          }
          curChild = curChild.nextSibling;
          if (!curChild && optgroup) {
            curChild = optgroup.nextSibling;
            optgroup = null;
          }
        }
      }
      fromEl.selectedIndex = selectedIndex;
    }
  }
};
var ELEMENT_NODE = 1;
var DOCUMENT_FRAGMENT_NODE$1 = 11;
var TEXT_NODE = 3;
var COMMENT_NODE = 8;
function noop() {
}
function defaultGetNodeKey(node) {
  if (node) {
    return node.getAttribute && node.getAttribute("id") || node.id;
  }
}
function morphdomFactory(morphAttrs2) {
  return function morphdom2(fromNode, toNode, options) {
    if (!options) {
      options = {};
    }
    if (typeof toNode === "string") {
      if (fromNode.nodeName === "#document" || fromNode.nodeName === "HTML" || fromNode.nodeName === "BODY") {
        var toNodeHtml = toNode;
        toNode = doc.createElement("html");
        toNode.innerHTML = toNodeHtml;
      } else {
        toNode = toElement(toNode);
      }
    } else if (toNode.nodeType === DOCUMENT_FRAGMENT_NODE$1) {
      toNode = toNode.firstElementChild;
    }
    var getNodeKey = options.getNodeKey || defaultGetNodeKey;
    var onBeforeNodeAdded = options.onBeforeNodeAdded || noop;
    var onNodeAdded = options.onNodeAdded || noop;
    var onBeforeElUpdated = options.onBeforeElUpdated || noop;
    var onElUpdated = options.onElUpdated || noop;
    var onBeforeNodeDiscarded = options.onBeforeNodeDiscarded || noop;
    var onNodeDiscarded = options.onNodeDiscarded || noop;
    var onBeforeElChildrenUpdated = options.onBeforeElChildrenUpdated || noop;
    var skipFromChildren = options.skipFromChildren || noop;
    var addChild = options.addChild || function(parent, child) {
      return parent.appendChild(child);
    };
    var childrenOnly = options.childrenOnly === true;
    var fromNodesLookup = /* @__PURE__ */ Object.create(null);
    var keyedRemovalList = [];
    function addKeyedRemoval(key) {
      keyedRemovalList.push(key);
    }
    function walkDiscardedChildNodes(node, skipKeyedNodes) {
      if (node.nodeType === ELEMENT_NODE) {
        var curChild = node.firstChild;
        while (curChild) {
          var key = void 0;
          if (skipKeyedNodes && (key = getNodeKey(curChild))) {
            addKeyedRemoval(key);
          } else {
            onNodeDiscarded(curChild);
            if (curChild.firstChild) {
              walkDiscardedChildNodes(curChild, skipKeyedNodes);
            }
          }
          curChild = curChild.nextSibling;
        }
      }
    }
    function removeNode(node, parentNode, skipKeyedNodes) {
      if (onBeforeNodeDiscarded(node) === false) {
        return;
      }
      if (parentNode) {
        parentNode.removeChild(node);
      }
      onNodeDiscarded(node);
      walkDiscardedChildNodes(node, skipKeyedNodes);
    }
    function indexTree(node) {
      if (node.nodeType === ELEMENT_NODE || node.nodeType === DOCUMENT_FRAGMENT_NODE$1) {
        var curChild = node.firstChild;
        while (curChild) {
          var key = getNodeKey(curChild);
          if (key) {
            fromNodesLookup[key] = curChild;
          }
          indexTree(curChild);
          curChild = curChild.nextSibling;
        }
      }
    }
    indexTree(fromNode);
    function handleNodeAdded(el) {
      onNodeAdded(el);
      var curChild = el.firstChild;
      while (curChild) {
        var nextSibling = curChild.nextSibling;
        var key = getNodeKey(curChild);
        if (key) {
          var unmatchedFromEl = fromNodesLookup[key];
          if (unmatchedFromEl && compareNodeNames(curChild, unmatchedFromEl)) {
            curChild.parentNode.replaceChild(unmatchedFromEl, curChild);
            morphEl(unmatchedFromEl, curChild);
          } else {
            handleNodeAdded(curChild);
          }
        } else {
          handleNodeAdded(curChild);
        }
        curChild = nextSibling;
      }
    }
    function cleanupFromEl(fromEl, curFromNodeChild, curFromNodeKey) {
      while (curFromNodeChild) {
        var fromNextSibling = curFromNodeChild.nextSibling;
        if (curFromNodeKey = getNodeKey(curFromNodeChild)) {
          addKeyedRemoval(curFromNodeKey);
        } else {
          removeNode(
            curFromNodeChild,
            fromEl,
            true
            /* skip keyed nodes */
          );
        }
        curFromNodeChild = fromNextSibling;
      }
    }
    function morphEl(fromEl, toEl, childrenOnly2) {
      var toElKey = getNodeKey(toEl);
      if (toElKey) {
        delete fromNodesLookup[toElKey];
      }
      if (!childrenOnly2) {
        var beforeUpdateResult = onBeforeElUpdated(fromEl, toEl);
        if (beforeUpdateResult === false) {
          return;
        } else if (beforeUpdateResult instanceof HTMLElement) {
          fromEl = beforeUpdateResult;
          indexTree(fromEl);
        }
        morphAttrs2(fromEl, toEl);
        onElUpdated(fromEl);
        if (onBeforeElChildrenUpdated(fromEl, toEl) === false) {
          return;
        }
      }
      if (fromEl.nodeName !== "TEXTAREA") {
        morphChildren(fromEl, toEl);
      } else {
        specialElHandlers.TEXTAREA(fromEl, toEl);
      }
    }
    function morphChildren(fromEl, toEl) {
      var skipFrom = skipFromChildren(fromEl, toEl);
      var curToNodeChild = toEl.firstChild;
      var curFromNodeChild = fromEl.firstChild;
      var curToNodeKey;
      var curFromNodeKey;
      var fromNextSibling;
      var toNextSibling;
      var matchingFromEl;
      outer:
        while (curToNodeChild) {
          toNextSibling = curToNodeChild.nextSibling;
          curToNodeKey = getNodeKey(curToNodeChild);
          while (!skipFrom && curFromNodeChild) {
            fromNextSibling = curFromNodeChild.nextSibling;
            if (curToNodeChild.isSameNode && curToNodeChild.isSameNode(curFromNodeChild)) {
              curToNodeChild = toNextSibling;
              curFromNodeChild = fromNextSibling;
              continue outer;
            }
            curFromNodeKey = getNodeKey(curFromNodeChild);
            var curFromNodeType = curFromNodeChild.nodeType;
            var isCompatible = void 0;
            if (curFromNodeType === curToNodeChild.nodeType) {
              if (curFromNodeType === ELEMENT_NODE) {
                if (curToNodeKey) {
                  if (curToNodeKey !== curFromNodeKey) {
                    if (matchingFromEl = fromNodesLookup[curToNodeKey]) {
                      if (fromNextSibling === matchingFromEl) {
                        isCompatible = false;
                      } else {
                        fromEl.insertBefore(matchingFromEl, curFromNodeChild);
                        if (curFromNodeKey) {
                          addKeyedRemoval(curFromNodeKey);
                        } else {
                          removeNode(
                            curFromNodeChild,
                            fromEl,
                            true
                            /* skip keyed nodes */
                          );
                        }
                        curFromNodeChild = matchingFromEl;
                        curFromNodeKey = getNodeKey(curFromNodeChild);
                      }
                    } else {
                      isCompatible = false;
                    }
                  }
                } else if (curFromNodeKey) {
                  isCompatible = false;
                }
                isCompatible = isCompatible !== false && compareNodeNames(curFromNodeChild, curToNodeChild);
                if (isCompatible) {
                  morphEl(curFromNodeChild, curToNodeChild);
                }
              } else if (curFromNodeType === TEXT_NODE || curFromNodeType == COMMENT_NODE) {
                isCompatible = true;
                if (curFromNodeChild.nodeValue !== curToNodeChild.nodeValue) {
                  curFromNodeChild.nodeValue = curToNodeChild.nodeValue;
                }
              }
            }
            if (isCompatible) {
              curToNodeChild = toNextSibling;
              curFromNodeChild = fromNextSibling;
              continue outer;
            }
            if (curFromNodeKey) {
              addKeyedRemoval(curFromNodeKey);
            } else {
              removeNode(
                curFromNodeChild,
                fromEl,
                true
                /* skip keyed nodes */
              );
            }
            curFromNodeChild = fromNextSibling;
          }
          if (curToNodeKey && (matchingFromEl = fromNodesLookup[curToNodeKey]) && compareNodeNames(matchingFromEl, curToNodeChild)) {
            if (!skipFrom) {
              addChild(fromEl, matchingFromEl);
            }
            morphEl(matchingFromEl, curToNodeChild);
          } else {
            var onBeforeNodeAddedResult = onBeforeNodeAdded(curToNodeChild);
            if (onBeforeNodeAddedResult !== false) {
              if (onBeforeNodeAddedResult) {
                curToNodeChild = onBeforeNodeAddedResult;
              }
              if (curToNodeChild.actualize) {
                curToNodeChild = curToNodeChild.actualize(fromEl.ownerDocument || doc);
              }
              addChild(fromEl, curToNodeChild);
              handleNodeAdded(curToNodeChild);
            }
          }
          curToNodeChild = toNextSibling;
          curFromNodeChild = fromNextSibling;
        }
      cleanupFromEl(fromEl, curFromNodeChild, curFromNodeKey);
      var specialElHandler = specialElHandlers[fromEl.nodeName];
      if (specialElHandler) {
        specialElHandler(fromEl, toEl);
      }
    }
    var morphedNode = fromNode;
    var morphedNodeType = morphedNode.nodeType;
    var toNodeType = toNode.nodeType;
    if (!childrenOnly) {
      if (morphedNodeType === ELEMENT_NODE) {
        if (toNodeType === ELEMENT_NODE) {
          if (!compareNodeNames(fromNode, toNode)) {
            onNodeDiscarded(fromNode);
            morphedNode = moveChildren(fromNode, createElementNS(toNode.nodeName, toNode.namespaceURI));
          }
        } else {
          morphedNode = toNode;
        }
      } else if (morphedNodeType === TEXT_NODE || morphedNodeType === COMMENT_NODE) {
        if (toNodeType === morphedNodeType) {
          if (morphedNode.nodeValue !== toNode.nodeValue) {
            morphedNode.nodeValue = toNode.nodeValue;
          }
          return morphedNode;
        } else {
          morphedNode = toNode;
        }
      }
    }
    if (morphedNode === toNode) {
      onNodeDiscarded(fromNode);
    } else {
      if (toNode.isSameNode && toNode.isSameNode(morphedNode)) {
        return;
      }
      morphEl(morphedNode, toNode, childrenOnly);
      if (keyedRemovalList) {
        for (var i = 0, len = keyedRemovalList.length; i < len; i++) {
          var elToRemove = fromNodesLookup[keyedRemovalList[i]];
          if (elToRemove) {
            removeNode(elToRemove, elToRemove.parentNode, false);
          }
        }
      }
    }
    if (!childrenOnly && morphedNode !== fromNode && fromNode.parentNode) {
      if (morphedNode.actualize) {
        morphedNode = morphedNode.actualize(fromNode.ownerDocument || doc);
      }
      fromNode.parentNode.replaceChild(morphedNode, fromNode);
    }
    return morphedNode;
  };
}
var morphdom = morphdomFactory(morphAttrs);
var morphdom_esm_default = morphdom;
var DOMPatch = class {
  constructor(view, container, id, html, streams, targetCID, opts = {}) {
    this.view = view;
    this.liveSocket = view.liveSocket;
    this.container = container;
    this.id = id;
    this.rootID = view.root.id;
    this.html = html;
    this.streams = streams;
    this.streamInserts = {};
    this.streamComponentRestore = {};
    this.targetCID = targetCID;
    this.cidPatch = isCid(this.targetCID);
    this.pendingRemoves = [];
    this.phxRemove = this.liveSocket.binding("remove");
    this.targetContainer = this.isCIDPatch() ? this.targetCIDContainer(html) : container;
    this.callbacks = {
      beforeadded: [],
      beforeupdated: [],
      beforephxChildAdded: [],
      afteradded: [],
      afterupdated: [],
      afterdiscarded: [],
      afterphxChildAdded: [],
      aftertransitionsDiscarded: []
    };
    this.withChildren = opts.withChildren || opts.undoRef || false;
    this.undoRef = opts.undoRef;
  }
  before(kind, callback) {
    this.callbacks[`before${kind}`].push(callback);
  }
  after(kind, callback) {
    this.callbacks[`after${kind}`].push(callback);
  }
  trackBefore(kind, ...args) {
    this.callbacks[`before${kind}`].forEach((callback) => callback(...args));
  }
  trackAfter(kind, ...args) {
    this.callbacks[`after${kind}`].forEach((callback) => callback(...args));
  }
  markPrunableContentForRemoval() {
    const phxUpdate = this.liveSocket.binding(PHX_UPDATE);
    dom_default.all(
      this.container,
      `[${phxUpdate}=append] > *, [${phxUpdate}=prepend] > *`,
      (el) => {
        el.setAttribute(PHX_PRUNE, "");
      }
    );
  }
  perform(isJoinPatch) {
    const { view, liveSocket: liveSocket2, html, container } = this;
    let targetContainer = this.targetContainer;
    if (this.isCIDPatch() && !this.targetContainer) {
      return;
    }
    if (this.isCIDPatch()) {
      const closestLock = targetContainer.closest(`[${PHX_REF_LOCK}]`);
      if (closestLock) {
        const clonedTree = dom_default.private(closestLock, PHX_REF_LOCK);
        if (clonedTree) {
          targetContainer = clonedTree.querySelector(
            `[data-phx-component="${this.targetCID}"]`
          );
        }
      }
    }
    const focused = liveSocket2.getActiveElement();
    const { selectionStart, selectionEnd } = focused && dom_default.hasSelectionRange(focused) ? focused : {};
    const phxUpdate = liveSocket2.binding(PHX_UPDATE);
    const phxViewportTop = liveSocket2.binding(PHX_VIEWPORT_TOP);
    const phxViewportBottom = liveSocket2.binding(PHX_VIEWPORT_BOTTOM);
    const phxTriggerExternal = liveSocket2.binding(PHX_TRIGGER_ACTION);
    const added = [];
    const updates = [];
    const appendPrependUpdates = [];
    const portalCallbacks = [];
    let externalFormTriggered = null;
    const morph = (targetContainer2, source, withChildren = this.withChildren) => {
      const morphCallbacks = {
        // normally, we are running with childrenOnly, as the patch HTML for a LV
        // does not include the LV attrs (data-phx-session, etc.)
        // when we are patching a live component, we do want to patch the root element as well;
        // another case is the recursive patch of a stream item that was kept on reset (-> onBeforeNodeAdded)
        childrenOnly: targetContainer2.getAttribute(PHX_COMPONENT) === null && !withChildren,
        getNodeKey: (node) => {
          if (dom_default.isPhxDestroyed(node)) {
            return null;
          }
          if (isJoinPatch) {
            return node.id;
          }
          return node.id || node.getAttribute && node.getAttribute(PHX_MAGIC_ID);
        },
        // skip indexing from children when container is stream
        skipFromChildren: (from) => {
          return from.getAttribute(phxUpdate) === PHX_STREAM;
        },
        // tell morphdom how to add a child
        addChild: (parent, child) => {
          const { ref, streamAt } = this.getStreamInsert(child);
          if (ref === void 0) {
            return parent.appendChild(child);
          }
          this.setStreamRef(child, ref);
          if (streamAt === 0) {
            parent.insertAdjacentElement("afterbegin", child);
          } else if (streamAt === -1) {
            const lastChild = parent.lastElementChild;
            if (lastChild && !lastChild.hasAttribute(PHX_STREAM_REF)) {
              const nonStreamChild = Array.from(parent.children).find(
                (c) => !c.hasAttribute(PHX_STREAM_REF)
              );
              parent.insertBefore(child, nonStreamChild);
            } else {
              parent.appendChild(child);
            }
          } else if (streamAt > 0) {
            const sibling = Array.from(parent.children)[streamAt];
            parent.insertBefore(child, sibling);
          }
        },
        onBeforeNodeAdded: (el) => {
          if (this.getStreamInsert(el)?.updateOnly && !this.streamComponentRestore[el.id]) {
            return false;
          }
          dom_default.maintainPrivateHooks(el, el, phxViewportTop, phxViewportBottom);
          this.trackBefore("added", el);
          let morphedEl = el;
          if (this.streamComponentRestore[el.id]) {
            morphedEl = this.streamComponentRestore[el.id];
            delete this.streamComponentRestore[el.id];
            morph(morphedEl, el, true);
          }
          return morphedEl;
        },
        onNodeAdded: (el) => {
          if (el.getAttribute) {
            this.maybeReOrderStream(el, true);
          }
          if (dom_default.isPortalTemplate(el)) {
            portalCallbacks.push(() => this.teleport(el, morph));
          }
          if (el instanceof HTMLImageElement && el.srcset) {
            el.srcset = el.srcset;
          } else if (el instanceof HTMLVideoElement && el.autoplay) {
            el.play();
          }
          if (dom_default.isNowTriggerFormExternal(el, phxTriggerExternal)) {
            externalFormTriggered = el;
          }
          if (dom_default.isPhxChild(el) && view.ownsElement(el) || dom_default.isPhxSticky(el) && view.ownsElement(el.parentNode)) {
            this.trackAfter("phxChildAdded", el);
          }
          if (el.nodeName === "SCRIPT" && el.hasAttribute(PHX_RUNTIME_HOOK)) {
            this.handleRuntimeHook(el, source);
          }
          added.push(el);
        },
        onNodeDiscarded: (el) => this.onNodeDiscarded(el),
        onBeforeNodeDiscarded: (el) => {
          if (el.getAttribute && el.getAttribute(PHX_PRUNE) !== null) {
            return true;
          }
          if (el.parentElement !== null && el.id && dom_default.isPhxUpdate(el.parentElement, phxUpdate, [
            PHX_STREAM,
            "append",
            "prepend"
          ])) {
            return false;
          }
          if (el.getAttribute && el.getAttribute(PHX_TELEPORTED_REF)) {
            return false;
          }
          if (this.maybePendingRemove(el)) {
            return false;
          }
          if (this.skipCIDSibling(el)) {
            return false;
          }
          if (dom_default.isPortalTemplate(el)) {
            const teleportedEl = document.getElementById(
              el.content.firstElementChild.id
            );
            if (teleportedEl) {
              teleportedEl.remove();
              morphCallbacks.onNodeDiscarded(teleportedEl);
              this.view.dropPortalElementId(teleportedEl.id);
            }
          }
          return true;
        },
        onElUpdated: (el) => {
          if (dom_default.isNowTriggerFormExternal(el, phxTriggerExternal)) {
            externalFormTriggered = el;
          }
          updates.push(el);
          this.maybeReOrderStream(el, false);
        },
        onBeforeElUpdated: (fromEl, toEl) => {
          if (fromEl.id && fromEl.isSameNode(targetContainer2) && fromEl.id !== toEl.id) {
            morphCallbacks.onNodeDiscarded(fromEl);
            fromEl.replaceWith(toEl);
            return morphCallbacks.onNodeAdded(toEl);
          }
          dom_default.syncPendingAttrs(fromEl, toEl);
          dom_default.maintainPrivateHooks(
            fromEl,
            toEl,
            phxViewportTop,
            phxViewportBottom
          );
          dom_default.cleanChildNodes(toEl, phxUpdate);
          if (this.skipCIDSibling(toEl)) {
            this.maybeReOrderStream(fromEl);
            return false;
          }
          if (dom_default.isPhxSticky(fromEl)) {
            [PHX_SESSION, PHX_STATIC, PHX_ROOT_ID].map((attr) => [
              attr,
              fromEl.getAttribute(attr),
              toEl.getAttribute(attr)
            ]).forEach(([attr, fromVal, toVal]) => {
              if (toVal && fromVal !== toVal) {
                fromEl.setAttribute(attr, toVal);
              }
            });
            return false;
          }
          if (dom_default.isIgnored(fromEl, phxUpdate) || fromEl.form && fromEl.form.isSameNode(externalFormTriggered)) {
            this.trackBefore("updated", fromEl, toEl);
            dom_default.mergeAttrs(fromEl, toEl, {
              isIgnored: dom_default.isIgnored(fromEl, phxUpdate)
            });
            updates.push(fromEl);
            dom_default.applyStickyOperations(fromEl);
            return false;
          }
          if (fromEl.type === "number" && fromEl.validity && fromEl.validity.badInput) {
            return false;
          }
          const isFocusedFormEl = focused && fromEl.isSameNode(focused) && dom_default.isFormInput(fromEl);
          const focusedSelectChanged = isFocusedFormEl && this.isChangedSelect(fromEl, toEl);
          if (fromEl.hasAttribute(PHX_REF_SRC)) {
            const ref = new ElementRef(fromEl);
            if (ref.lockRef && (!this.undoRef || !ref.isLockUndoneBy(this.undoRef))) {
              if (dom_default.isUploadInput(fromEl)) {
                dom_default.mergeAttrs(fromEl, toEl, { isIgnored: true });
                this.trackBefore("updated", fromEl, toEl);
                updates.push(fromEl);
              }
              dom_default.applyStickyOperations(fromEl);
              const isLocked = fromEl.hasAttribute(PHX_REF_LOCK);
              const clone2 = isLocked ? dom_default.private(fromEl, PHX_REF_LOCK) || fromEl.cloneNode(true) : null;
              if (clone2) {
                dom_default.putPrivate(fromEl, PHX_REF_LOCK, clone2);
                if (!isFocusedFormEl) {
                  fromEl = clone2;
                }
              }
            }
          }
          if (dom_default.isPhxChild(toEl)) {
            const prevSession = fromEl.getAttribute(PHX_SESSION);
            dom_default.mergeAttrs(fromEl, toEl, { exclude: [PHX_STATIC] });
            if (prevSession !== "") {
              fromEl.setAttribute(PHX_SESSION, prevSession);
            }
            fromEl.setAttribute(PHX_ROOT_ID, this.rootID);
            dom_default.applyStickyOperations(fromEl);
            return false;
          }
          if (this.undoRef && dom_default.private(toEl, PHX_REF_LOCK)) {
            dom_default.putPrivate(
              fromEl,
              PHX_REF_LOCK,
              dom_default.private(toEl, PHX_REF_LOCK)
            );
          }
          dom_default.copyPrivates(toEl, fromEl);
          if (dom_default.isPortalTemplate(toEl)) {
            portalCallbacks.push(() => this.teleport(toEl, morph));
            return false;
          }
          if (isFocusedFormEl && fromEl.type !== "hidden" && !focusedSelectChanged) {
            this.trackBefore("updated", fromEl, toEl);
            dom_default.mergeFocusedInput(fromEl, toEl);
            dom_default.syncAttrsToProps(fromEl);
            updates.push(fromEl);
            dom_default.applyStickyOperations(fromEl);
            return false;
          } else {
            if (focusedSelectChanged) {
              fromEl.blur();
            }
            if (dom_default.isPhxUpdate(toEl, phxUpdate, ["append", "prepend"])) {
              appendPrependUpdates.push(
                new DOMPostMorphRestorer(
                  fromEl,
                  toEl,
                  toEl.getAttribute(phxUpdate)
                )
              );
            }
            dom_default.syncAttrsToProps(toEl);
            dom_default.applyStickyOperations(toEl);
            this.trackBefore("updated", fromEl, toEl);
            return fromEl;
          }
        }
      };
      morphdom_esm_default(targetContainer2, source, morphCallbacks);
    };
    this.trackBefore("added", container);
    this.trackBefore("updated", container, container);
    liveSocket2.time("morphdom", () => {
      this.streams.forEach(([ref, inserts, deleteIds, reset]) => {
        inserts.forEach(([key, streamAt, limit, updateOnly]) => {
          this.streamInserts[key] = { ref, streamAt, limit, reset, updateOnly };
        });
        if (reset !== void 0) {
          dom_default.all(container, `[${PHX_STREAM_REF}="${ref}"]`, (child) => {
            this.removeStreamChildElement(child);
          });
        }
        deleteIds.forEach((id) => {
          const child = container.querySelector(`[id="${id}"]`);
          if (child) {
            this.removeStreamChildElement(child);
          }
        });
      });
      if (isJoinPatch) {
        dom_default.all(this.container, `[${phxUpdate}=${PHX_STREAM}]`).filter((el) => this.view.ownsElement(el)).forEach((el) => {
          Array.from(el.children).forEach((child) => {
            this.removeStreamChildElement(child, true);
          });
        });
      }
      morph(targetContainer, html);
      portalCallbacks.forEach((callback) => callback());
      this.view.portalElementIds.forEach((id) => {
        const el = document.getElementById(id);
        if (el) {
          const source = document.getElementById(
            el.getAttribute(PHX_TELEPORTED_SRC)
          );
          if (!source) {
            el.remove();
            this.onNodeDiscarded(el);
            this.view.dropPortalElementId(id);
          }
        }
      });
    });
    if (liveSocket2.isDebugEnabled()) {
      detectDuplicateIds();
      detectInvalidStreamInserts(this.streamInserts);
      Array.from(document.querySelectorAll("input[name=id]")).forEach(
        (node) => {
          if (node instanceof HTMLInputElement && node.form) {
            console.error(
              'Detected an input with name="id" inside a form! This will cause problems when patching the DOM.\n',
              node
            );
          }
        }
      );
    }
    if (appendPrependUpdates.length > 0) {
      liveSocket2.time("post-morph append/prepend restoration", () => {
        appendPrependUpdates.forEach((update) => update.perform());
      });
    }
    liveSocket2.silenceEvents(
      () => dom_default.restoreFocus(focused, selectionStart, selectionEnd)
    );
    dom_default.dispatchEvent(document, "phx:update");
    added.forEach((el) => this.trackAfter("added", el));
    updates.forEach((el) => this.trackAfter("updated", el));
    this.transitionPendingRemoves();
    if (externalFormTriggered) {
      liveSocket2.unload();
      const submitter = dom_default.private(externalFormTriggered, "submitter");
      if (submitter && submitter.name && targetContainer.contains(submitter)) {
        const input = document.createElement("input");
        input.type = "hidden";
        const formId = submitter.getAttribute("form");
        if (formId) {
          input.setAttribute("form", formId);
        }
        input.name = submitter.name;
        input.value = submitter.value;
        submitter.parentElement.insertBefore(input, submitter);
      }
      Object.getPrototypeOf(externalFormTriggered).submit.call(
        externalFormTriggered
      );
    }
    return true;
  }
  onNodeDiscarded(el) {
    if (dom_default.isPhxChild(el) || dom_default.isPhxSticky(el)) {
      this.liveSocket.destroyViewByEl(el);
    }
    this.trackAfter("discarded", el);
  }
  maybePendingRemove(node) {
    if (node.getAttribute && node.getAttribute(this.phxRemove) !== null) {
      this.pendingRemoves.push(node);
      return true;
    } else {
      return false;
    }
  }
  removeStreamChildElement(child, force = false) {
    if (!force && !this.view.ownsElement(child)) {
      return;
    }
    if (this.streamInserts[child.id]) {
      this.streamComponentRestore[child.id] = child;
      child.remove();
    } else {
      if (!this.maybePendingRemove(child)) {
        child.remove();
        this.onNodeDiscarded(child);
      }
    }
  }
  getStreamInsert(el) {
    const insert = el.id ? this.streamInserts[el.id] : {};
    return insert || {};
  }
  setStreamRef(el, ref) {
    dom_default.putSticky(
      el,
      PHX_STREAM_REF,
      (el2) => el2.setAttribute(PHX_STREAM_REF, ref)
    );
  }
  maybeReOrderStream(el, isNew) {
    const { ref, streamAt, reset } = this.getStreamInsert(el);
    if (streamAt === void 0) {
      return;
    }
    this.setStreamRef(el, ref);
    if (!reset && !isNew) {
      return;
    }
    if (!el.parentElement) {
      return;
    }
    if (streamAt === 0) {
      el.parentElement.insertBefore(el, el.parentElement.firstElementChild);
    } else if (streamAt > 0) {
      const children = Array.from(el.parentElement.children);
      const oldIndex = children.indexOf(el);
      if (streamAt >= children.length - 1) {
        el.parentElement.appendChild(el);
      } else {
        const sibling = children[streamAt];
        if (oldIndex > streamAt) {
          el.parentElement.insertBefore(el, sibling);
        } else {
          el.parentElement.insertBefore(el, sibling.nextElementSibling);
        }
      }
    }
    this.maybeLimitStream(el);
  }
  maybeLimitStream(el) {
    const { limit } = this.getStreamInsert(el);
    const children = limit !== null && Array.from(el.parentElement.children);
    if (limit && limit < 0 && children.length > limit * -1) {
      children.slice(0, children.length + limit).forEach((child) => this.removeStreamChildElement(child));
    } else if (limit && limit >= 0 && children.length > limit) {
      children.slice(limit).forEach((child) => this.removeStreamChildElement(child));
    }
  }
  transitionPendingRemoves() {
    const { pendingRemoves, liveSocket: liveSocket2 } = this;
    if (pendingRemoves.length > 0) {
      liveSocket2.transitionRemoves(pendingRemoves, () => {
        pendingRemoves.forEach((el) => {
          const child = dom_default.firstPhxChild(el);
          if (child) {
            liveSocket2.destroyViewByEl(child);
          }
          el.remove();
        });
        this.trackAfter("transitionsDiscarded", pendingRemoves);
      });
    }
  }
  isChangedSelect(fromEl, toEl) {
    if (!(fromEl instanceof HTMLSelectElement) || fromEl.multiple) {
      return false;
    }
    if (fromEl.options.length !== toEl.options.length) {
      return true;
    }
    toEl.value = fromEl.value;
    return !fromEl.isEqualNode(toEl);
  }
  isCIDPatch() {
    return this.cidPatch;
  }
  skipCIDSibling(el) {
    return el.nodeType === Node.ELEMENT_NODE && el.hasAttribute(PHX_SKIP);
  }
  targetCIDContainer(html) {
    if (!this.isCIDPatch()) {
      return;
    }
    const [first, ...rest] = dom_default.findComponentNodeList(
      this.view.id,
      this.targetCID
    );
    if (rest.length === 0 && dom_default.childNodeLength(html) === 1) {
      return first;
    } else {
      return first && first.parentNode;
    }
  }
  indexOf(parent, child) {
    return Array.from(parent.children).indexOf(child);
  }
  teleport(el, morph) {
    const targetSelector = el.getAttribute(PHX_PORTAL);
    const portalContainer = document.querySelector(targetSelector);
    if (!portalContainer) {
      throw new Error(
        "portal target with selector " + targetSelector + " not found"
      );
    }
    const toTeleport = el.content.firstElementChild;
    if (this.skipCIDSibling(toTeleport)) {
      return;
    }
    if (!toTeleport?.id) {
      throw new Error(
        "phx-portal template must have a single root element with ID!"
      );
    }
    const existing = document.getElementById(toTeleport.id);
    let portalTarget;
    if (existing) {
      if (!portalContainer.contains(existing)) {
        portalContainer.appendChild(existing);
      }
      portalTarget = existing;
    } else {
      portalTarget = document.createElement(toTeleport.tagName);
      portalContainer.appendChild(portalTarget);
    }
    toTeleport.setAttribute(PHX_TELEPORTED_REF, this.view.id);
    toTeleport.setAttribute(PHX_TELEPORTED_SRC, el.id);
    morph(portalTarget, toTeleport, true);
    toTeleport.removeAttribute(PHX_TELEPORTED_REF);
    toTeleport.removeAttribute(PHX_TELEPORTED_SRC);
    this.view.pushPortalElementId(toTeleport.id);
  }
  handleRuntimeHook(el, source) {
    const name = el.getAttribute(PHX_RUNTIME_HOOK);
    let nonce = el.hasAttribute("nonce") ? el.getAttribute("nonce") : null;
    if (el.hasAttribute("nonce")) {
      const template = document.createElement("template");
      template.innerHTML = source;
      nonce = template.content.querySelector(`script[${PHX_RUNTIME_HOOK}="${CSS.escape(name)}"]`).getAttribute("nonce");
    }
    const script = document.createElement("script");
    script.textContent = el.textContent;
    dom_default.mergeAttrs(script, el, { isIgnored: false });
    if (nonce) {
      script.nonce = nonce;
    }
    el.replaceWith(script);
    el = script;
  }
};
var VOID_TAGS = /* @__PURE__ */ new Set([
  "area",
  "base",
  "br",
  "col",
  "command",
  "embed",
  "hr",
  "img",
  "input",
  "keygen",
  "link",
  "meta",
  "param",
  "source",
  "track",
  "wbr"
]);
var quoteChars = /* @__PURE__ */ new Set(["'", '"']);
var modifyRoot = (html, attrs, clearInnerHTML) => {
  let i = 0;
  let insideComment = false;
  let beforeTag, afterTag, tag, tagNameEndsAt, id, newHTML;
  const lookahead = html.match(/^(\s*(?:<!--.*?-->\s*)*)<([^\s\/>]+)/);
  if (lookahead === null) {
    throw new Error(`malformed html ${html}`);
  }
  i = lookahead[0].length;
  beforeTag = lookahead[1];
  tag = lookahead[2];
  tagNameEndsAt = i;
  for (i; i < html.length; i++) {
    if (html.charAt(i) === ">") {
      break;
    }
    if (html.charAt(i) === "=") {
      const isId = html.slice(i - 3, i) === " id";
      i++;
      const char = html.charAt(i);
      if (quoteChars.has(char)) {
        const attrStartsAt = i;
        i++;
        for (i; i < html.length; i++) {
          if (html.charAt(i) === char) {
            break;
          }
        }
        if (isId) {
          id = html.slice(attrStartsAt + 1, i);
          break;
        }
      }
    }
  }
  let closeAt = html.length - 1;
  insideComment = false;
  while (closeAt >= beforeTag.length + tag.length) {
    const char = html.charAt(closeAt);
    if (insideComment) {
      if (char === "-" && html.slice(closeAt - 3, closeAt) === "<!-") {
        insideComment = false;
        closeAt -= 4;
      } else {
        closeAt -= 1;
      }
    } else if (char === ">" && html.slice(closeAt - 2, closeAt) === "--") {
      insideComment = true;
      closeAt -= 3;
    } else if (char === ">") {
      break;
    } else {
      closeAt -= 1;
    }
  }
  afterTag = html.slice(closeAt + 1, html.length);
  const attrsStr = Object.keys(attrs).map((attr) => attrs[attr] === true ? attr : `${attr}="${attrs[attr]}"`).join(" ");
  if (clearInnerHTML) {
    const idAttrStr = id ? ` id="${id}"` : "";
    if (VOID_TAGS.has(tag)) {
      newHTML = `<${tag}${idAttrStr}${attrsStr === "" ? "" : " "}${attrsStr}/>`;
    } else {
      newHTML = `<${tag}${idAttrStr}${attrsStr === "" ? "" : " "}${attrsStr}></${tag}>`;
    }
  } else {
    const rest = html.slice(tagNameEndsAt, closeAt + 1);
    newHTML = `<${tag}${attrsStr === "" ? "" : " "}${attrsStr}${rest}`;
  }
  return [newHTML, beforeTag, afterTag];
};
var Rendered = class {
  static extract(diff) {
    const { [REPLY]: reply, [EVENTS]: events, [TITLE]: title } = diff;
    delete diff[REPLY];
    delete diff[EVENTS];
    delete diff[TITLE];
    return { diff, title, reply: reply || null, events: events || [] };
  }
  constructor(viewId, rendered) {
    this.viewId = viewId;
    this.rendered = {};
    this.magicId = 0;
    this.mergeDiff(rendered);
  }
  parentViewId() {
    return this.viewId;
  }
  toString(onlyCids) {
    const { buffer: str, streams } = this.recursiveToString(
      this.rendered,
      this.rendered[COMPONENTS],
      onlyCids,
      true,
      {}
    );
    return { buffer: str, streams };
  }
  recursiveToString(rendered, components = rendered[COMPONENTS], onlyCids, changeTracking, rootAttrs) {
    onlyCids = onlyCids ? new Set(onlyCids) : null;
    const output = {
      buffer: "",
      components,
      onlyCids,
      streams: /* @__PURE__ */ new Set()
    };
    this.toOutputBuffer(rendered, null, output, changeTracking, rootAttrs);
    return { buffer: output.buffer, streams: output.streams };
  }
  componentCIDs(diff) {
    return Object.keys(diff[COMPONENTS] || {}).map((i) => parseInt(i));
  }
  isComponentOnlyDiff(diff) {
    if (!diff[COMPONENTS]) {
      return false;
    }
    return Object.keys(diff).length === 1;
  }
  getComponent(diff, cid) {
    return diff[COMPONENTS][cid];
  }
  resetRender(cid) {
    if (this.rendered[COMPONENTS][cid]) {
      this.rendered[COMPONENTS][cid].reset = true;
    }
  }
  mergeDiff(diff) {
    const newc = diff[COMPONENTS];
    const cache = {};
    delete diff[COMPONENTS];
    this.rendered = this.mutableMerge(this.rendered, diff);
    this.rendered[COMPONENTS] = this.rendered[COMPONENTS] || {};
    if (newc) {
      const oldc = this.rendered[COMPONENTS];
      for (const cid in newc) {
        newc[cid] = this.cachedFindComponent(cid, newc[cid], oldc, newc, cache);
      }
      for (const cid in newc) {
        oldc[cid] = newc[cid];
      }
      diff[COMPONENTS] = newc;
    }
  }
  cachedFindComponent(cid, cdiff, oldc, newc, cache) {
    if (cache[cid]) {
      return cache[cid];
    } else {
      let ndiff, stat, scid = cdiff[STATIC];
      if (isCid(scid)) {
        let tdiff;
        if (scid > 0) {
          tdiff = this.cachedFindComponent(scid, newc[scid], oldc, newc, cache);
        } else {
          tdiff = oldc[-scid];
        }
        stat = tdiff[STATIC];
        ndiff = this.cloneMerge(tdiff, cdiff, true);
        ndiff[STATIC] = stat;
      } else {
        ndiff = cdiff[STATIC] !== void 0 || oldc[cid] === void 0 ? cdiff : this.cloneMerge(oldc[cid], cdiff, false);
      }
      cache[cid] = ndiff;
      return ndiff;
    }
  }
  mutableMerge(target, source) {
    if (source[STATIC] !== void 0) {
      return source;
    } else {
      this.doMutableMerge(target, source);
      return target;
    }
  }
  doMutableMerge(target, source) {
    if (source[KEYED]) {
      this.mergeKeyed(target, source);
    } else {
      for (const key in source) {
        const val = source[key];
        const targetVal = target[key];
        const isObjVal = isObject(val);
        if (isObjVal && val[STATIC] === void 0 && isObject(targetVal)) {
          this.doMutableMerge(targetVal, val);
        } else {
          target[key] = val;
        }
      }
    }
    if (target[ROOT]) {
      target.newRender = true;
    }
  }
  clone(diff) {
    if ("structuredClone" in window) {
      return structuredClone(diff);
    } else {
      return JSON.parse(JSON.stringify(diff));
    }
  }
  // keyed comprehensions
  mergeKeyed(target, source) {
    const clonedTarget = this.clone(target);
    Object.entries(source[KEYED]).forEach(([i, entry]) => {
      if (i === KEYED_COUNT) {
        return;
      }
      if (Array.isArray(entry)) {
        const [old_idx, diff] = entry;
        target[KEYED][i] = clonedTarget[KEYED][old_idx];
        this.doMutableMerge(target[KEYED][i], diff);
      } else if (typeof entry === "number") {
        const old_idx = entry;
        target[KEYED][i] = clonedTarget[KEYED][old_idx];
      } else if (typeof entry === "object") {
        if (!target[KEYED][i]) {
          target[KEYED][i] = {};
        }
        this.doMutableMerge(target[KEYED][i], entry);
      }
    });
    if (source[KEYED][KEYED_COUNT] < target[KEYED][KEYED_COUNT]) {
      for (let i = source[KEYED][KEYED_COUNT]; i < target[KEYED][KEYED_COUNT]; i++) {
        delete target[KEYED][i];
      }
    }
    target[KEYED][KEYED_COUNT] = source[KEYED][KEYED_COUNT];
    if (source[STREAM]) {
      target[STREAM] = source[STREAM];
    }
    if (source[TEMPLATES]) {
      target[TEMPLATES] = source[TEMPLATES];
    }
  }
  // Merges cid trees together, copying statics from source tree.
  //
  // The `pruneMagicId` is passed to control pruning the magicId of the
  // target. We must always prune the magicId when we are sharing statics
  // from another component. If not pruning, we replicate the logic from
  // mutableMerge, where we set newRender to true if there is a root
  // (effectively forcing the new version to be rendered instead of skipped)
  //
  cloneMerge(target, source, pruneMagicId) {
    const merged = { ...target, ...source };
    for (const key in merged) {
      const val = source[key];
      const targetVal = target[key];
      if (isObject(val) && val[STATIC] === void 0 && isObject(targetVal)) {
        merged[key] = this.cloneMerge(targetVal, val, pruneMagicId);
      } else if (val === void 0 && isObject(targetVal)) {
        merged[key] = this.cloneMerge(targetVal, {}, pruneMagicId);
      }
    }
    if (pruneMagicId) {
      delete merged.magicId;
      delete merged.newRender;
    } else if (target[ROOT]) {
      merged.newRender = true;
    }
    return merged;
  }
  componentToString(cid) {
    const { buffer: str, streams } = this.recursiveCIDToString(
      this.rendered[COMPONENTS],
      cid,
      null
    );
    const [strippedHTML, _before, _after] = modifyRoot(str, {});
    return { buffer: strippedHTML, streams };
  }
  pruneCIDs(cids) {
    cids.forEach((cid) => delete this.rendered[COMPONENTS][cid]);
  }
  // private
  get() {
    return this.rendered;
  }
  isNewFingerprint(diff = {}) {
    return !!diff[STATIC];
  }
  templateStatic(part, templates) {
    if (typeof part === "number") {
      return templates[part];
    } else {
      return part;
    }
  }
  nextMagicID() {
    this.magicId++;
    return `m${this.magicId}-${this.parentViewId()}`;
  }
  // Converts rendered tree to output buffer.
  //
  // changeTracking controls if we can apply the PHX_SKIP optimization.
  toOutputBuffer(rendered, templates, output, changeTracking, rootAttrs = {}) {
    if (rendered[KEYED]) {
      return this.comprehensionToBuffer(
        rendered,
        templates,
        output,
        changeTracking
      );
    }
    if (rendered[TEMPLATES]) {
      templates = rendered[TEMPLATES];
      delete rendered[TEMPLATES];
    }
    let { [STATIC]: statics } = rendered;
    statics = this.templateStatic(statics, templates);
    rendered[STATIC] = statics;
    const isRoot = rendered[ROOT];
    const prevBuffer = output.buffer;
    if (isRoot) {
      output.buffer = "";
    }
    if (changeTracking && isRoot && !rendered.magicId) {
      rendered.newRender = true;
      rendered.magicId = this.nextMagicID();
    }
    output.buffer += statics[0];
    for (let i = 1; i < statics.length; i++) {
      this.dynamicToBuffer(rendered[i - 1], templates, output, changeTracking);
      output.buffer += statics[i];
    }
    if (isRoot) {
      let skip = false;
      let attrs;
      if (changeTracking || rendered.magicId) {
        skip = changeTracking && !rendered.newRender;
        attrs = { [PHX_MAGIC_ID]: rendered.magicId, ...rootAttrs };
      } else {
        attrs = rootAttrs;
      }
      if (skip) {
        attrs[PHX_SKIP] = true;
      }
      const [newRoot, commentBefore, commentAfter] = modifyRoot(
        output.buffer,
        attrs,
        skip
      );
      rendered.newRender = false;
      output.buffer = prevBuffer + commentBefore + newRoot + commentAfter;
    }
  }
  comprehensionToBuffer(rendered, templates, output, changeTracking) {
    const keyedTemplates = templates || rendered[TEMPLATES];
    const statics = this.templateStatic(rendered[STATIC], templates);
    rendered[STATIC] = statics;
    delete rendered[TEMPLATES];
    for (let i = 0; i < rendered[KEYED][KEYED_COUNT]; i++) {
      output.buffer += statics[0];
      for (let j = 1; j < statics.length; j++) {
        this.dynamicToBuffer(
          rendered[KEYED][i][j - 1],
          keyedTemplates,
          output,
          changeTracking
        );
        output.buffer += statics[j];
      }
    }
    if (rendered[STREAM]) {
      const stream = rendered[STREAM];
      const [_ref, _inserts, deleteIds, reset] = stream || [null, {}, [], null];
      if (stream !== void 0 && (rendered[KEYED][KEYED_COUNT] > 0 || deleteIds.length > 0 || reset)) {
        delete rendered[STREAM];
        rendered[KEYED] = {
          [KEYED_COUNT]: 0
        };
        output.streams.add(stream);
      }
    }
  }
  dynamicToBuffer(rendered, templates, output, changeTracking) {
    if (typeof rendered === "number") {
      const { buffer: str, streams } = this.recursiveCIDToString(
        output.components,
        rendered,
        output.onlyCids
      );
      output.buffer += str;
      output.streams = /* @__PURE__ */ new Set([...output.streams, ...streams]);
    } else if (isObject(rendered)) {
      this.toOutputBuffer(rendered, templates, output, changeTracking, {});
    } else {
      output.buffer += rendered;
    }
  }
  recursiveCIDToString(components, cid, onlyCids) {
    const component = components[cid] || logError(`no component for CID ${cid}`, components);
    const attrs = { [PHX_COMPONENT]: cid, [PHX_VIEW_REF]: this.viewId };
    const skip = onlyCids && !onlyCids.has(cid);
    component.newRender = !skip;
    component.magicId = `c${cid}-${this.parentViewId()}`;
    const changeTracking = !component.reset;
    const { buffer: html, streams } = this.recursiveToString(
      component,
      components,
      onlyCids,
      changeTracking,
      attrs
    );
    delete component.reset;
    return { buffer: html, streams };
  }
};
var focusStack = [];
var default_transition_time = 200;
var JS = {
  // private
  exec(e, eventType, phxEvent, view, sourceEl, defaults) {
    const [defaultKind, defaultArgs] = defaults || [
      null,
      { callback: defaults && defaults.callback }
    ];
    const commands = phxEvent.charAt(0) === "[" ? JSON.parse(phxEvent) : [[defaultKind, defaultArgs]];
    commands.forEach(([kind, args]) => {
      if (kind === defaultKind) {
        args = { ...defaultArgs, ...args };
        args.callback = args.callback || defaultArgs.callback;
      }
      this.filterToEls(view.liveSocket, sourceEl, args).forEach((el) => {
        this[`exec_${kind}`](e, eventType, phxEvent, view, sourceEl, el, args);
      });
    });
  },
  isVisible(el) {
    return !!(el.offsetWidth || el.offsetHeight || el.getClientRects().length > 0);
  },
  // returns true if any part of the element is inside the viewport
  isInViewport(el) {
    const rect = el.getBoundingClientRect();
    const windowHeight = window.innerHeight || document.documentElement.clientHeight;
    const windowWidth = window.innerWidth || document.documentElement.clientWidth;
    return rect.right > 0 && rect.bottom > 0 && rect.left < windowWidth && rect.top < windowHeight;
  },
  // private
  // commands
  exec_exec(e, eventType, phxEvent, view, sourceEl, el, { attr, to }) {
    const encodedJS = el.getAttribute(attr);
    if (!encodedJS) {
      throw new Error(`expected ${attr} to contain JS command on "${to}"`);
    }
    view.liveSocket.execJS(el, encodedJS, eventType);
  },
  exec_dispatch(e, eventType, phxEvent, view, sourceEl, el, { event, detail, bubbles, blocking }) {
    detail = detail || {};
    detail.dispatcher = sourceEl;
    if (blocking) {
      const promise = new Promise((resolve, _reject) => {
        detail.done = resolve;
      });
      view.liveSocket.asyncTransition(promise);
    }
    dom_default.dispatchEvent(el, event, { detail, bubbles });
  },
  exec_push(e, eventType, phxEvent, view, sourceEl, el, args) {
    const {
      event,
      data,
      target,
      page_loading,
      loading,
      value,
      dispatcher,
      callback
    } = args;
    const pushOpts = {
      loading,
      value,
      target,
      page_loading: !!page_loading,
      originalEvent: e
    };
    const targetSrc = eventType === "change" && dispatcher ? dispatcher : sourceEl;
    const phxTarget = target || targetSrc.getAttribute(view.binding("target")) || targetSrc;
    const handler = (targetView, targetCtx) => {
      if (!targetView.isConnected()) {
        return;
      }
      if (eventType === "change") {
        let { newCid, _target } = args;
        _target = _target || (dom_default.isFormInput(sourceEl) ? sourceEl.name : void 0);
        if (_target) {
          pushOpts._target = _target;
        }
        targetView.pushInput(
          sourceEl,
          targetCtx,
          newCid,
          event || phxEvent,
          pushOpts,
          callback
        );
      } else if (eventType === "submit") {
        const { submitter } = args;
        targetView.submitForm(
          sourceEl,
          targetCtx,
          event || phxEvent,
          submitter,
          pushOpts,
          callback
        );
      } else {
        targetView.pushEvent(
          eventType,
          sourceEl,
          targetCtx,
          event || phxEvent,
          data,
          pushOpts,
          callback
        );
      }
    };
    if (args.targetView && args.targetCtx) {
      handler(args.targetView, args.targetCtx);
    } else {
      view.withinTargets(phxTarget, handler);
    }
  },
  exec_navigate(e, eventType, phxEvent, view, sourceEl, el, { href, replace }) {
    view.liveSocket.historyRedirect(
      e,
      href,
      replace ? "replace" : "push",
      null,
      sourceEl
    );
  },
  exec_patch(e, eventType, phxEvent, view, sourceEl, el, { href, replace }) {
    view.liveSocket.pushHistoryPatch(
      e,
      href,
      replace ? "replace" : "push",
      sourceEl
    );
  },
  exec_focus(e, eventType, phxEvent, view, sourceEl, el) {
    aria_default.attemptFocus(el);
    window.requestAnimationFrame(() => {
      window.requestAnimationFrame(() => aria_default.attemptFocus(el));
    });
  },
  exec_focus_first(e, eventType, phxEvent, view, sourceEl, el) {
    aria_default.focusFirstInteractive(el) || aria_default.focusFirst(el);
    window.requestAnimationFrame(() => {
      window.requestAnimationFrame(
        () => aria_default.focusFirstInteractive(el) || aria_default.focusFirst(el)
      );
    });
  },
  exec_push_focus(e, eventType, phxEvent, view, sourceEl, el) {
    focusStack.push(el || sourceEl);
  },
  exec_pop_focus(_e, _eventType, _phxEvent, _view, _sourceEl, _el) {
    const el = focusStack.pop();
    if (el) {
      el.focus();
      window.requestAnimationFrame(() => {
        window.requestAnimationFrame(() => el.focus());
      });
    }
  },
  exec_add_class(e, eventType, phxEvent, view, sourceEl, el, { names, transition, time, blocking }) {
    this.addOrRemoveClasses(el, names, [], transition, time, view, blocking);
  },
  exec_remove_class(e, eventType, phxEvent, view, sourceEl, el, { names, transition, time, blocking }) {
    this.addOrRemoveClasses(el, [], names, transition, time, view, blocking);
  },
  exec_toggle_class(e, eventType, phxEvent, view, sourceEl, el, { names, transition, time, blocking }) {
    this.toggleClasses(el, names, transition, time, view, blocking);
  },
  exec_toggle_attr(e, eventType, phxEvent, view, sourceEl, el, { attr: [attr, val1, val2] }) {
    this.toggleAttr(el, attr, val1, val2);
  },
  exec_ignore_attrs(e, eventType, phxEvent, view, sourceEl, el, { attrs }) {
    this.ignoreAttrs(el, attrs);
  },
  exec_transition(e, eventType, phxEvent, view, sourceEl, el, { time, transition, blocking }) {
    this.addOrRemoveClasses(el, [], [], transition, time, view, blocking);
  },
  exec_toggle(e, eventType, phxEvent, view, sourceEl, el, { display, ins, outs, time, blocking }) {
    this.toggle(eventType, view, el, display, ins, outs, time, blocking);
  },
  exec_show(e, eventType, phxEvent, view, sourceEl, el, { display, transition, time, blocking }) {
    this.show(eventType, view, el, display, transition, time, blocking);
  },
  exec_hide(e, eventType, phxEvent, view, sourceEl, el, { display, transition, time, blocking }) {
    this.hide(eventType, view, el, display, transition, time, blocking);
  },
  exec_set_attr(e, eventType, phxEvent, view, sourceEl, el, { attr: [attr, val] }) {
    this.setOrRemoveAttrs(el, [[attr, val]], []);
  },
  exec_remove_attr(e, eventType, phxEvent, view, sourceEl, el, { attr }) {
    this.setOrRemoveAttrs(el, [], [attr]);
  },
  ignoreAttrs(el, attrs) {
    dom_default.putPrivate(el, "JS:ignore_attrs", {
      apply: (fromEl, toEl) => {
        Array.from(fromEl.attributes).forEach((attr) => {
          if (attrs.some(
            (toIgnore) => attr.name == toIgnore || toIgnore.includes("*") && attr.name.match(toIgnore) != null
          )) {
            toEl.setAttribute(attr.name, attr.value);
          }
        });
      }
    });
  },
  onBeforeElUpdated(fromEl, toEl) {
    const ignoreAttrs = dom_default.private(fromEl, "JS:ignore_attrs");
    if (ignoreAttrs) {
      ignoreAttrs.apply(fromEl, toEl);
    }
  },
  // utils for commands
  show(eventType, view, el, display, transition, time, blocking) {
    if (!this.isVisible(el)) {
      this.toggle(
        eventType,
        view,
        el,
        display,
        transition,
        null,
        time,
        blocking
      );
    }
  },
  hide(eventType, view, el, display, transition, time, blocking) {
    if (this.isVisible(el)) {
      this.toggle(
        eventType,
        view,
        el,
        display,
        null,
        transition,
        time,
        blocking
      );
    }
  },
  toggle(eventType, view, el, display, ins, outs, time, blocking) {
    time = time || default_transition_time;
    const [inClasses, inStartClasses, inEndClasses] = ins || [[], [], []];
    const [outClasses, outStartClasses, outEndClasses] = outs || [[], [], []];
    if (inClasses.length > 0 || outClasses.length > 0) {
      if (this.isVisible(el)) {
        const onStart = () => {
          this.addOrRemoveClasses(
            el,
            outStartClasses,
            inClasses.concat(inStartClasses).concat(inEndClasses)
          );
          window.requestAnimationFrame(() => {
            this.addOrRemoveClasses(el, outClasses, []);
            window.requestAnimationFrame(
              () => this.addOrRemoveClasses(el, outEndClasses, outStartClasses)
            );
          });
        };
        const onEnd = () => {
          this.addOrRemoveClasses(el, [], outClasses.concat(outEndClasses));
          dom_default.putSticky(
            el,
            "toggle",
            (currentEl) => currentEl.style.display = "none"
          );
          el.dispatchEvent(new Event("phx:hide-end"));
        };
        el.dispatchEvent(new Event("phx:hide-start"));
        if (blocking === false) {
          onStart();
          setTimeout(onEnd, time);
        } else {
          view.transition(time, onStart, onEnd);
        }
      } else {
        if (eventType === "remove") {
          return;
        }
        const onStart = () => {
          this.addOrRemoveClasses(
            el,
            inStartClasses,
            outClasses.concat(outStartClasses).concat(outEndClasses)
          );
          const stickyDisplay = display || this.defaultDisplay(el);
          window.requestAnimationFrame(() => {
            this.addOrRemoveClasses(el, inClasses, []);
            window.requestAnimationFrame(() => {
              dom_default.putSticky(
                el,
                "toggle",
                (currentEl) => currentEl.style.display = stickyDisplay
              );
              this.addOrRemoveClasses(el, inEndClasses, inStartClasses);
            });
          });
        };
        const onEnd = () => {
          this.addOrRemoveClasses(el, [], inClasses.concat(inEndClasses));
          el.dispatchEvent(new Event("phx:show-end"));
        };
        el.dispatchEvent(new Event("phx:show-start"));
        if (blocking === false) {
          onStart();
          setTimeout(onEnd, time);
        } else {
          view.transition(time, onStart, onEnd);
        }
      }
    } else {
      if (this.isVisible(el)) {
        window.requestAnimationFrame(() => {
          el.dispatchEvent(new Event("phx:hide-start"));
          dom_default.putSticky(
            el,
            "toggle",
            (currentEl) => currentEl.style.display = "none"
          );
          el.dispatchEvent(new Event("phx:hide-end"));
        });
      } else {
        window.requestAnimationFrame(() => {
          el.dispatchEvent(new Event("phx:show-start"));
          const stickyDisplay = display || this.defaultDisplay(el);
          dom_default.putSticky(
            el,
            "toggle",
            (currentEl) => currentEl.style.display = stickyDisplay
          );
          el.dispatchEvent(new Event("phx:show-end"));
        });
      }
    }
  },
  toggleClasses(el, classes, transition, time, view, blocking) {
    window.requestAnimationFrame(() => {
      const [prevAdds, prevRemoves] = dom_default.getSticky(el, "classes", [[], []]);
      const newAdds = classes.filter(
        (name) => prevAdds.indexOf(name) < 0 && !el.classList.contains(name)
      );
      const newRemoves = classes.filter(
        (name) => prevRemoves.indexOf(name) < 0 && el.classList.contains(name)
      );
      this.addOrRemoveClasses(
        el,
        newAdds,
        newRemoves,
        transition,
        time,
        view,
        blocking
      );
    });
  },
  toggleAttr(el, attr, val1, val2) {
    if (el.hasAttribute(attr)) {
      if (val2 !== void 0) {
        if (el.getAttribute(attr) === val1) {
          this.setOrRemoveAttrs(el, [[attr, val2]], []);
        } else {
          this.setOrRemoveAttrs(el, [[attr, val1]], []);
        }
      } else {
        this.setOrRemoveAttrs(el, [], [attr]);
      }
    } else {
      this.setOrRemoveAttrs(el, [[attr, val1]], []);
    }
  },
  addOrRemoveClasses(el, adds, removes, transition, time, view, blocking) {
    time = time || default_transition_time;
    const [transitionRun, transitionStart, transitionEnd] = transition || [
      [],
      [],
      []
    ];
    if (transitionRun.length > 0) {
      const onStart = () => {
        this.addOrRemoveClasses(
          el,
          transitionStart,
          [].concat(transitionRun).concat(transitionEnd)
        );
        window.requestAnimationFrame(() => {
          this.addOrRemoveClasses(el, transitionRun, []);
          window.requestAnimationFrame(
            () => this.addOrRemoveClasses(el, transitionEnd, transitionStart)
          );
        });
      };
      const onDone = () => this.addOrRemoveClasses(
        el,
        adds.concat(transitionEnd),
        removes.concat(transitionRun).concat(transitionStart)
      );
      if (blocking === false) {
        onStart();
        setTimeout(onDone, time);
      } else {
        view.transition(time, onStart, onDone);
      }
      return;
    }
    window.requestAnimationFrame(() => {
      const [prevAdds, prevRemoves] = dom_default.getSticky(el, "classes", [[], []]);
      const keepAdds = adds.filter(
        (name) => prevAdds.indexOf(name) < 0 && !el.classList.contains(name)
      );
      const keepRemoves = removes.filter(
        (name) => prevRemoves.indexOf(name) < 0 && el.classList.contains(name)
      );
      const newAdds = prevAdds.filter((name) => removes.indexOf(name) < 0).concat(keepAdds);
      const newRemoves = prevRemoves.filter((name) => adds.indexOf(name) < 0).concat(keepRemoves);
      dom_default.putSticky(el, "classes", (currentEl) => {
        currentEl.classList.remove(...newRemoves);
        currentEl.classList.add(...newAdds);
        return [newAdds, newRemoves];
      });
    });
  },
  setOrRemoveAttrs(el, sets, removes) {
    const [prevSets, prevRemoves] = dom_default.getSticky(el, "attrs", [[], []]);
    const alteredAttrs = sets.map(([attr, _val]) => attr).concat(removes);
    const newSets = prevSets.filter(([attr, _val]) => !alteredAttrs.includes(attr)).concat(sets);
    const newRemoves = prevRemoves.filter((attr) => !alteredAttrs.includes(attr)).concat(removes);
    dom_default.putSticky(el, "attrs", (currentEl) => {
      newRemoves.forEach((attr) => currentEl.removeAttribute(attr));
      newSets.forEach(([attr, val]) => currentEl.setAttribute(attr, val));
      return [newSets, newRemoves];
    });
  },
  hasAllClasses(el, classes) {
    return classes.every((name) => el.classList.contains(name));
  },
  isToggledOut(el, outClasses) {
    return !this.isVisible(el) || this.hasAllClasses(el, outClasses);
  },
  filterToEls(liveSocket2, sourceEl, { to }) {
    const defaultQuery = () => {
      if (typeof to === "string") {
        return document.querySelectorAll(to);
      } else if (to.closest) {
        const toEl = sourceEl.closest(to.closest);
        return toEl ? [toEl] : [];
      } else if (to.inner) {
        return sourceEl.querySelectorAll(to.inner);
      }
    };
    return to ? liveSocket2.jsQuerySelectorAll(sourceEl, to, defaultQuery) : [sourceEl];
  },
  defaultDisplay(el) {
    return { tr: "table-row", td: "table-cell" }[el.tagName.toLowerCase()] || "block";
  },
  transitionClasses(val) {
    if (!val) {
      return null;
    }
    let [trans, tStart, tEnd] = Array.isArray(val) ? val : [val.split(" "), [], []];
    trans = Array.isArray(trans) ? trans : trans.split(" ");
    tStart = Array.isArray(tStart) ? tStart : tStart.split(" ");
    tEnd = Array.isArray(tEnd) ? tEnd : tEnd.split(" ");
    return [trans, tStart, tEnd];
  }
};
var js_default = JS;
var js_commands_default = (liveSocket2, eventType) => {
  return {
    exec(el, encodedJS) {
      liveSocket2.execJS(el, encodedJS, eventType);
    },
    show(el, opts = {}) {
      const owner = liveSocket2.owner(el);
      js_default.show(
        eventType,
        owner,
        el,
        opts.display,
        js_default.transitionClasses(opts.transition),
        opts.time,
        opts.blocking
      );
    },
    hide(el, opts = {}) {
      const owner = liveSocket2.owner(el);
      js_default.hide(
        eventType,
        owner,
        el,
        null,
        js_default.transitionClasses(opts.transition),
        opts.time,
        opts.blocking
      );
    },
    toggle(el, opts = {}) {
      const owner = liveSocket2.owner(el);
      const inTransition = js_default.transitionClasses(opts.in);
      const outTransition = js_default.transitionClasses(opts.out);
      js_default.toggle(
        eventType,
        owner,
        el,
        opts.display,
        inTransition,
        outTransition,
        opts.time,
        opts.blocking
      );
    },
    addClass(el, names, opts = {}) {
      const classNames = Array.isArray(names) ? names : names.split(" ");
      const owner = liveSocket2.owner(el);
      js_default.addOrRemoveClasses(
        el,
        classNames,
        [],
        js_default.transitionClasses(opts.transition),
        opts.time,
        owner,
        opts.blocking
      );
    },
    removeClass(el, names, opts = {}) {
      const classNames = Array.isArray(names) ? names : names.split(" ");
      const owner = liveSocket2.owner(el);
      js_default.addOrRemoveClasses(
        el,
        [],
        classNames,
        js_default.transitionClasses(opts.transition),
        opts.time,
        owner,
        opts.blocking
      );
    },
    toggleClass(el, names, opts = {}) {
      const classNames = Array.isArray(names) ? names : names.split(" ");
      const owner = liveSocket2.owner(el);
      js_default.toggleClasses(
        el,
        classNames,
        js_default.transitionClasses(opts.transition),
        opts.time,
        owner,
        opts.blocking
      );
    },
    transition(el, transition, opts = {}) {
      const owner = liveSocket2.owner(el);
      js_default.addOrRemoveClasses(
        el,
        [],
        [],
        js_default.transitionClasses(transition),
        opts.time,
        owner,
        opts.blocking
      );
    },
    setAttribute(el, attr, val) {
      js_default.setOrRemoveAttrs(el, [[attr, val]], []);
    },
    removeAttribute(el, attr) {
      js_default.setOrRemoveAttrs(el, [], [attr]);
    },
    toggleAttribute(el, attr, val1, val2) {
      js_default.toggleAttr(el, attr, val1, val2);
    },
    push(el, type, opts = {}) {
      liveSocket2.withinOwners(el, (view) => {
        const data = opts.value || {};
        delete opts.value;
        let e = new CustomEvent("phx:exec", { detail: { sourceElement: el } });
        js_default.exec(e, eventType, type, view, el, ["push", { data, ...opts }]);
      });
    },
    navigate(href, opts = {}) {
      const customEvent = new CustomEvent("phx:exec");
      liveSocket2.historyRedirect(
        customEvent,
        href,
        opts.replace ? "replace" : "push",
        null,
        null
      );
    },
    patch(href, opts = {}) {
      const customEvent = new CustomEvent("phx:exec");
      liveSocket2.pushHistoryPatch(
        customEvent,
        href,
        opts.replace ? "replace" : "push",
        null
      );
    },
    ignoreAttributes(el, attrs) {
      js_default.ignoreAttrs(el, Array.isArray(attrs) ? attrs : [attrs]);
    }
  };
};
var HOOK_ID = "hookId";
var viewHookID = 1;
var ViewHook = class _ViewHook {
  static makeID() {
    return viewHookID++;
  }
  static elementID(el) {
    return dom_default.private(el, HOOK_ID);
  }
  constructor(view, el, callbacks) {
    this.el = el;
    this.__attachView(view);
    this.__listeners = /* @__PURE__ */ new Set();
    this.__isDisconnected = false;
    dom_default.putPrivate(this.el, HOOK_ID, _ViewHook.makeID());
    if (callbacks) {
      const protectedProps = /* @__PURE__ */ new Set([
        "el",
        "liveSocket",
        "__view",
        "__listeners",
        "__isDisconnected",
        "constructor",
        // Standard object properties
        // Core ViewHook API methods
        "js",
        "pushEvent",
        "pushEventTo",
        "handleEvent",
        "removeHandleEvent",
        "upload",
        "uploadTo",
        // Internal lifecycle callers
        "__mounted",
        "__updated",
        "__beforeUpdate",
        "__destroyed",
        "__reconnected",
        "__disconnected",
        "__cleanup__"
      ]);
      for (const key in callbacks) {
        if (Object.prototype.hasOwnProperty.call(callbacks, key)) {
          this[key] = callbacks[key];
          if (protectedProps.has(key)) {
            console.warn(
              `Hook object for element #${el.id} overwrites core property '${key}'!`
            );
          }
        }
      }
      const lifecycleMethods = [
        "mounted",
        "beforeUpdate",
        "updated",
        "destroyed",
        "disconnected",
        "reconnected"
      ];
      lifecycleMethods.forEach((methodName) => {
        if (callbacks[methodName] && typeof callbacks[methodName] === "function") {
          this[methodName] = callbacks[methodName];
        }
      });
    }
  }
  /** @internal */
  __attachView(view) {
    if (view) {
      this.__view = () => view;
      this.liveSocket = view.liveSocket;
    } else {
      this.__view = () => {
        throw new Error(
          `hook not yet attached to a live view: ${this.el.outerHTML}`
        );
      };
      this.liveSocket = null;
    }
  }
  // Default lifecycle methods
  mounted() {
  }
  beforeUpdate() {
  }
  updated() {
  }
  destroyed() {
  }
  disconnected() {
  }
  reconnected() {
  }
  // Internal lifecycle callers - called by the View
  /** @internal */
  __mounted() {
    this.mounted();
  }
  /** @internal */
  __updated() {
    this.updated();
  }
  /** @internal */
  __beforeUpdate() {
    this.beforeUpdate();
  }
  /** @internal */
  __destroyed() {
    this.destroyed();
    dom_default.deletePrivate(this.el, HOOK_ID);
  }
  /** @internal */
  __reconnected() {
    if (this.__isDisconnected) {
      this.__isDisconnected = false;
      this.reconnected();
    }
  }
  /** @internal */
  __disconnected() {
    this.__isDisconnected = true;
    this.disconnected();
  }
  js() {
    return {
      ...js_commands_default(this.__view().liveSocket, "hook"),
      exec: (encodedJS) => {
        this.__view().liveSocket.execJS(this.el, encodedJS, "hook");
      }
    };
  }
  pushEvent(event, payload, onReply) {
    const promise = this.__view().pushHookEvent(
      this.el,
      null,
      event,
      payload || {}
    );
    if (onReply === void 0) {
      return promise.then(({ reply }) => reply);
    }
    promise.then(({ reply, ref }) => onReply(reply, ref)).catch(() => {
    });
    return;
  }
  pushEventTo(selectorOrTarget, event, payload, onReply) {
    if (onReply === void 0) {
      const targetPair = [];
      this.__view().withinTargets(selectorOrTarget, (view, targetCtx) => {
        targetPair.push({ view, targetCtx });
      });
      const promises = targetPair.map(({ view, targetCtx }) => {
        return view.pushHookEvent(this.el, targetCtx, event, payload || {});
      });
      return Promise.allSettled(promises);
    }
    this.__view().withinTargets(selectorOrTarget, (view, targetCtx) => {
      view.pushHookEvent(this.el, targetCtx, event, payload || {}).then(({ reply, ref }) => onReply(reply, ref)).catch(() => {
      });
    });
    return;
  }
  handleEvent(event, callback) {
    const callbackRef = {
      event,
      callback: (customEvent) => callback(customEvent.detail)
    };
    window.addEventListener(
      `phx:${event}`,
      callbackRef.callback
    );
    this.__listeners.add(callbackRef);
    return callbackRef;
  }
  removeHandleEvent(ref) {
    window.removeEventListener(
      `phx:${ref.event}`,
      ref.callback
    );
    this.__listeners.delete(ref);
  }
  upload(name, files) {
    return this.__view().dispatchUploads(null, name, files);
  }
  uploadTo(selectorOrTarget, name, files) {
    return this.__view().withinTargets(selectorOrTarget, (view, targetCtx) => {
      view.dispatchUploads(targetCtx, name, files);
    });
  }
  /** @internal */
  __cleanup__() {
    this.__listeners.forEach(
      (callbackRef) => this.removeHandleEvent(callbackRef)
    );
  }
};
var prependFormDataKey = (key, prefix) => {
  const isArray = key.endsWith("[]");
  let baseKey = isArray ? key.slice(0, -2) : key;
  baseKey = baseKey.replace(/([^\[\]]+)(\]?$)/, `${prefix}$1$2`);
  if (isArray) {
    baseKey += "[]";
  }
  return baseKey;
};
var serializeForm = (form, opts, onlyNames = []) => {
  const { submitter } = opts;
  let injectedElement;
  if (submitter && submitter.name) {
    const input = document.createElement("input");
    input.type = "hidden";
    const formId = submitter.getAttribute("form");
    if (formId) {
      input.setAttribute("form", formId);
    }
    input.name = submitter.name;
    input.value = submitter.value;
    submitter.parentElement.insertBefore(input, submitter);
    injectedElement = input;
  }
  const formData = new FormData(form);
  const toRemove = [];
  formData.forEach((val, key, _index) => {
    if (val instanceof File) {
      toRemove.push(key);
    }
  });
  toRemove.forEach((key) => formData.delete(key));
  const params = new URLSearchParams();
  const { inputsUnused, onlyHiddenInputs } = Array.from(form.elements).reduce(
    (acc, input) => {
      const { inputsUnused: inputsUnused2, onlyHiddenInputs: onlyHiddenInputs2 } = acc;
      const key = input.name;
      if (!key) {
        return acc;
      }
      if (inputsUnused2[key] === void 0) {
        inputsUnused2[key] = true;
      }
      if (onlyHiddenInputs2[key] === void 0) {
        onlyHiddenInputs2[key] = true;
      }
      const isUsed = dom_default.private(input, PHX_HAS_FOCUSED) || dom_default.private(input, PHX_HAS_SUBMITTED);
      const isHidden = input.type === "hidden";
      inputsUnused2[key] = inputsUnused2[key] && !isUsed;
      onlyHiddenInputs2[key] = onlyHiddenInputs2[key] && isHidden;
      return acc;
    },
    { inputsUnused: {}, onlyHiddenInputs: {} }
  );
  for (const [key, val] of formData.entries()) {
    if (onlyNames.length === 0 || onlyNames.indexOf(key) >= 0) {
      const isUnused = inputsUnused[key];
      const hidden = onlyHiddenInputs[key];
      if (isUnused && !(submitter && submitter.name == key) && !hidden) {
        params.append(prependFormDataKey(key, "_unused_"), "");
      }
      if (typeof val === "string") {
        params.append(key, val);
      }
    }
  }
  if (submitter && injectedElement) {
    submitter.parentElement.removeChild(injectedElement);
  }
  return params.toString();
};
var View = class _View {
  static closestView(el) {
    const liveViewEl = el.closest(PHX_VIEW_SELECTOR);
    return liveViewEl ? dom_default.private(liveViewEl, "view") : null;
  }
  constructor(el, liveSocket2, parentView, flash, liveReferer) {
    this.isDead = false;
    this.liveSocket = liveSocket2;
    this.flash = flash;
    this.parent = parentView;
    this.root = parentView ? parentView.root : this;
    this.el = el;
    const boundView = dom_default.private(this.el, "view");
    if (boundView !== void 0 && boundView.isDead !== true) {
      logError(
        `The DOM element for this view has already been bound to a view.

        An element can only ever be associated with a single view!
        Please ensure that you are not trying to initialize multiple LiveSockets on the same page.
        This could happen if you're accidentally trying to render your root layout more than once.
        Ensure that the template set on the LiveView is different than the root layout.
      `,
        { view: boundView }
      );
      throw new Error("Cannot bind multiple views to the same DOM element.");
    }
    dom_default.putPrivate(this.el, "view", this);
    this.id = this.el.id;
    this.ref = 0;
    this.lastAckRef = null;
    this.childJoins = 0;
    this.loaderTimer = null;
    this.disconnectedTimer = null;
    this.pendingDiffs = [];
    this.pendingForms = /* @__PURE__ */ new Set();
    this.redirect = false;
    this.href = null;
    this.joinCount = this.parent ? this.parent.joinCount - 1 : 0;
    this.joinAttempts = 0;
    this.joinPending = true;
    this.destroyed = false;
    this.joinCallback = function(onDone) {
      onDone && onDone();
    };
    this.stopCallback = function() {
    };
    this.pendingJoinOps = this.parent ? null : [];
    this.viewHooks = {};
    this.formSubmits = [];
    this.children = this.parent ? null : {};
    this.root.children[this.id] = {};
    this.formsForRecovery = {};
    this.channel = this.liveSocket.channel(`lv:${this.id}`, () => {
      const url = this.href && this.expandURL(this.href);
      return {
        redirect: this.redirect ? url : void 0,
        url: this.redirect ? void 0 : url || void 0,
        params: this.connectParams(liveReferer),
        session: this.getSession(),
        static: this.getStatic(),
        flash: this.flash,
        sticky: this.el.hasAttribute(PHX_STICKY)
      };
    });
    this.portalElementIds = /* @__PURE__ */ new Set();
  }
  setHref(href) {
    this.href = href;
  }
  setRedirect(href) {
    this.redirect = true;
    this.href = href;
  }
  isMain() {
    return this.el.hasAttribute(PHX_MAIN);
  }
  connectParams(liveReferer) {
    const params = this.liveSocket.params(this.el);
    const manifest = dom_default.all(document, `[${this.binding(PHX_TRACK_STATIC)}]`).map((node) => node.src || node.href).filter((url) => typeof url === "string");
    if (manifest.length > 0) {
      params["_track_static"] = manifest;
    }
    params["_mounts"] = this.joinCount;
    params["_mount_attempts"] = this.joinAttempts;
    params["_live_referer"] = liveReferer;
    this.joinAttempts++;
    return params;
  }
  isConnected() {
    return this.channel.canPush();
  }
  getSession() {
    return this.el.getAttribute(PHX_SESSION);
  }
  getStatic() {
    const val = this.el.getAttribute(PHX_STATIC);
    return val === "" ? null : val;
  }
  destroy(callback = function() {
  }) {
    this.destroyAllChildren();
    this.destroyPortalElements();
    this.destroyed = true;
    dom_default.deletePrivate(this.el, "view");
    delete this.root.children[this.id];
    if (this.parent) {
      delete this.root.children[this.parent.id][this.id];
    }
    clearTimeout(this.loaderTimer);
    const onFinished = () => {
      callback();
      for (const id in this.viewHooks) {
        this.destroyHook(this.viewHooks[id]);
      }
    };
    dom_default.markPhxChildDestroyed(this.el);
    this.log("destroyed", () => ["the child has been removed from the parent"]);
    this.channel.leave().receive("ok", onFinished).receive("error", onFinished).receive("timeout", onFinished);
  }
  setContainerClasses(...classes) {
    this.el.classList.remove(
      PHX_CONNECTED_CLASS,
      PHX_LOADING_CLASS,
      PHX_ERROR_CLASS,
      PHX_CLIENT_ERROR_CLASS,
      PHX_SERVER_ERROR_CLASS
    );
    this.el.classList.add(...classes);
  }
  showLoader(timeout) {
    clearTimeout(this.loaderTimer);
    if (timeout) {
      this.loaderTimer = setTimeout(() => this.showLoader(), timeout);
    } else {
      for (const id in this.viewHooks) {
        this.viewHooks[id].__disconnected();
      }
      this.setContainerClasses(PHX_LOADING_CLASS);
    }
  }
  execAll(binding) {
    dom_default.all(
      this.el,
      `[${binding}]`,
      (el) => this.liveSocket.execJS(el, el.getAttribute(binding))
    );
  }
  hideLoader() {
    clearTimeout(this.loaderTimer);
    clearTimeout(this.disconnectedTimer);
    this.setContainerClasses(PHX_CONNECTED_CLASS);
    this.execAll(this.binding("connected"));
  }
  triggerReconnected() {
    for (const id in this.viewHooks) {
      this.viewHooks[id].__reconnected();
    }
  }
  log(kind, msgCallback) {
    this.liveSocket.log(this, kind, msgCallback);
  }
  transition(time, onStart, onDone = function() {
  }) {
    this.liveSocket.transition(time, onStart, onDone);
  }
  // calls the callback with the view and target element for the given phxTarget
  // targets can be:
  //  * an element itself, then it is simply passed to liveSocket.owner;
  //  * a CID (Component ID), then we first search the component's element in the DOM
  //  * a selector, then we search the selector in the DOM and call the callback
  //    for each element found with the corresponding owner view
  withinTargets(phxTarget, callback, dom = document) {
    if (phxTarget instanceof HTMLElement || phxTarget instanceof SVGElement) {
      return this.liveSocket.owner(
        phxTarget,
        (view) => callback(view, phxTarget)
      );
    }
    if (isCid(phxTarget)) {
      const targets = dom_default.findComponentNodeList(this.id, phxTarget, dom);
      if (targets.length === 0) {
        logError(`no component found matching phx-target of ${phxTarget}`);
      } else {
        callback(this, parseInt(phxTarget));
      }
    } else {
      const targets = Array.from(dom.querySelectorAll(phxTarget));
      if (targets.length === 0) {
        logError(
          `nothing found matching the phx-target selector "${phxTarget}"`
        );
      }
      targets.forEach(
        (target) => this.liveSocket.owner(target, (view) => callback(view, target))
      );
    }
  }
  applyDiff(type, rawDiff, callback) {
    this.log(type, () => ["", clone(rawDiff)]);
    const { diff, reply, events, title } = Rendered.extract(rawDiff);
    callback({ diff, reply, events });
    if (typeof title === "string" || type == "mount") {
      window.requestAnimationFrame(() => dom_default.putTitle(title));
    }
  }
  onJoin(resp) {
    const { rendered, container, liveview_version, pid } = resp;
    if (container) {
      const [tag, attrs] = container;
      this.el = dom_default.replaceRootContainer(this.el, tag, attrs);
    }
    this.childJoins = 0;
    this.joinPending = true;
    this.flash = null;
    if (this.root === this) {
      this.formsForRecovery = this.getFormsForRecovery();
    }
    if (this.isMain() && window.history.state === null) {
      browser_default.pushState("replace", {
        type: "patch",
        id: this.id,
        position: this.liveSocket.currentHistoryPosition
      });
    }
    if (liveview_version !== this.liveSocket.version()) {
      console.error(
        `LiveView asset version mismatch. JavaScript version ${this.liveSocket.version()} vs. server ${liveview_version}. To avoid issues, please ensure that your assets use the same version as the server.`
      );
    }
    if (pid) {
      this.el.setAttribute(PHX_LV_PID, pid);
    }
    browser_default.dropLocal(
      this.liveSocket.localStorage,
      window.location.pathname,
      CONSECUTIVE_RELOADS
    );
    this.applyDiff("mount", rendered, ({ diff, events }) => {
      this.rendered = new Rendered(this.id, diff);
      const [html, streams] = this.renderContainer(null, "join");
      this.dropPendingRefs();
      this.joinCount++;
      this.joinAttempts = 0;
      this.maybeRecoverForms(html, () => {
        this.onJoinComplete(resp, html, streams, events);
      });
    });
  }
  dropPendingRefs() {
    dom_default.all(document, `[${PHX_REF_SRC}="${this.refSrc()}"]`, (el) => {
      el.removeAttribute(PHX_REF_LOADING);
      el.removeAttribute(PHX_REF_SRC);
      el.removeAttribute(PHX_REF_LOCK);
    });
  }
  onJoinComplete({ live_patch }, html, streams, events) {
    if (this.joinCount > 1 || this.parent && !this.parent.isJoinPending()) {
      return this.applyJoinPatch(live_patch, html, streams, events);
    }
    const newChildren = dom_default.findPhxChildrenInFragment(html, this.id).filter(
      (toEl) => {
        const fromEl = toEl.id && this.el.querySelector(`[id="${toEl.id}"]`);
        const phxStatic = fromEl && fromEl.getAttribute(PHX_STATIC);
        if (phxStatic) {
          toEl.setAttribute(PHX_STATIC, phxStatic);
        }
        if (fromEl) {
          fromEl.setAttribute(PHX_ROOT_ID, this.root.id);
        }
        return this.joinChild(toEl);
      }
    );
    if (newChildren.length === 0) {
      if (this.parent) {
        this.root.pendingJoinOps.push([
          this,
          () => this.applyJoinPatch(live_patch, html, streams, events)
        ]);
        this.parent.ackJoin(this);
      } else {
        this.onAllChildJoinsComplete();
        this.applyJoinPatch(live_patch, html, streams, events);
      }
    } else {
      this.root.pendingJoinOps.push([
        this,
        () => this.applyJoinPatch(live_patch, html, streams, events)
      ]);
    }
  }
  attachTrueDocEl() {
    this.el = dom_default.byId(this.id);
    this.el.setAttribute(PHX_ROOT_ID, this.root.id);
  }
  // this is invoked for dead and live views, so we must filter by
  // by owner to ensure we aren't duplicating hooks across disconnect
  // and connected states. This also handles cases where hooks exist
  // in a root layout with a LV in the body
  execNewMounted(parent = document) {
    let phxViewportTop = this.binding(PHX_VIEWPORT_TOP);
    let phxViewportBottom = this.binding(PHX_VIEWPORT_BOTTOM);
    this.all(
      parent,
      `[${phxViewportTop}], [${phxViewportBottom}]`,
      (hookEl) => {
        dom_default.maintainPrivateHooks(
          hookEl,
          hookEl,
          phxViewportTop,
          phxViewportBottom
        );
        this.maybeAddNewHook(hookEl);
      }
    );
    this.all(
      parent,
      `[${this.binding(PHX_HOOK)}], [data-phx-${PHX_HOOK}]`,
      (hookEl) => {
        this.maybeAddNewHook(hookEl);
      }
    );
    this.all(parent, `[${this.binding(PHX_MOUNTED)}]`, (el) => {
      this.maybeMounted(el);
    });
  }
  all(parent, selector, callback) {
    dom_default.all(parent, selector, (el) => {
      if (this.ownsElement(el)) {
        callback(el);
      }
    });
  }
  applyJoinPatch(live_patch, html, streams, events) {
    this.attachTrueDocEl();
    const patch = new DOMPatch(this, this.el, this.id, html, streams, null);
    patch.markPrunableContentForRemoval();
    this.performPatch(patch, false, true);
    this.joinNewChildren();
    this.execNewMounted();
    this.joinPending = false;
    this.liveSocket.dispatchEvents(events);
    this.applyPendingUpdates();
    if (live_patch) {
      const { kind, to } = live_patch;
      this.liveSocket.historyPatch(to, kind);
    }
    this.hideLoader();
    if (this.joinCount > 1) {
      this.triggerReconnected();
    }
    this.stopCallback();
  }
  triggerBeforeUpdateHook(fromEl, toEl) {
    this.liveSocket.triggerDOM("onBeforeElUpdated", [fromEl, toEl]);
    const hook = this.getHook(fromEl);
    const isIgnored = hook && dom_default.isIgnored(fromEl, this.binding(PHX_UPDATE));
    if (hook && !fromEl.isEqualNode(toEl) && !(isIgnored && isEqualObj(fromEl.dataset, toEl.dataset))) {
      hook.__beforeUpdate();
      return hook;
    }
  }
  maybeMounted(el) {
    const phxMounted = el.getAttribute(this.binding(PHX_MOUNTED));
    const hasBeenInvoked = phxMounted && dom_default.private(el, "mounted");
    if (phxMounted && !hasBeenInvoked) {
      this.liveSocket.execJS(el, phxMounted);
      dom_default.putPrivate(el, "mounted", true);
    }
  }
  maybeAddNewHook(el) {
    const newHook = this.addHook(el);
    if (newHook) {
      newHook.__mounted();
    }
  }
  performPatch(patch, pruneCids, isJoinPatch = false) {
    const removedEls = [];
    let phxChildrenAdded = false;
    const updatedHookIds = /* @__PURE__ */ new Set();
    this.liveSocket.triggerDOM("onPatchStart", [patch.targetContainer]);
    patch.after("added", (el) => {
      this.liveSocket.triggerDOM("onNodeAdded", [el]);
      const phxViewportTop = this.binding(PHX_VIEWPORT_TOP);
      const phxViewportBottom = this.binding(PHX_VIEWPORT_BOTTOM);
      dom_default.maintainPrivateHooks(el, el, phxViewportTop, phxViewportBottom);
      this.maybeAddNewHook(el);
      if (el.getAttribute) {
        this.maybeMounted(el);
      }
    });
    patch.after("phxChildAdded", (el) => {
      if (dom_default.isPhxSticky(el)) {
        this.liveSocket.joinRootViews();
      } else {
        phxChildrenAdded = true;
      }
    });
    patch.before("updated", (fromEl, toEl) => {
      const hook = this.triggerBeforeUpdateHook(fromEl, toEl);
      if (hook) {
        updatedHookIds.add(fromEl.id);
      }
      js_default.onBeforeElUpdated(fromEl, toEl);
    });
    patch.after("updated", (el) => {
      if (updatedHookIds.has(el.id)) {
        this.getHook(el).__updated();
      }
    });
    patch.after("discarded", (el) => {
      if (el.nodeType === Node.ELEMENT_NODE) {
        removedEls.push(el);
      }
    });
    patch.after(
      "transitionsDiscarded",
      (els) => this.afterElementsRemoved(els, pruneCids)
    );
    patch.perform(isJoinPatch);
    this.afterElementsRemoved(removedEls, pruneCids);
    this.liveSocket.triggerDOM("onPatchEnd", [patch.targetContainer]);
    return phxChildrenAdded;
  }
  afterElementsRemoved(elements, pruneCids) {
    const destroyedCIDs = [];
    elements.forEach((parent) => {
      const components = dom_default.all(
        parent,
        `[${PHX_VIEW_REF}="${this.id}"][${PHX_COMPONENT}]`
      );
      const hooks2 = dom_default.all(
        parent,
        `[${this.binding(PHX_HOOK)}], [data-phx-hook]`
      );
      components.concat(parent).forEach((el) => {
        const cid = this.componentID(el);
        if (isCid(cid) && destroyedCIDs.indexOf(cid) === -1 && el.getAttribute(PHX_VIEW_REF) === this.id) {
          destroyedCIDs.push(cid);
        }
      });
      hooks2.concat(parent).forEach((hookEl) => {
        const hook = this.getHook(hookEl);
        hook && this.destroyHook(hook);
      });
    });
    if (pruneCids) {
      this.maybePushComponentsDestroyed(destroyedCIDs);
    }
  }
  joinNewChildren() {
    dom_default.findPhxChildren(document, this.id).forEach((el) => this.joinChild(el));
  }
  maybeRecoverForms(html, callback) {
    const phxChange = this.binding("change");
    const oldForms = this.root.formsForRecovery;
    const template = document.createElement("template");
    template.innerHTML = html;
    const rootEl = template.content.firstElementChild;
    rootEl.id = this.id;
    rootEl.setAttribute(PHX_ROOT_ID, this.root.id);
    rootEl.setAttribute(PHX_SESSION, this.getSession());
    rootEl.setAttribute(PHX_STATIC, this.getStatic());
    rootEl.setAttribute(PHX_PARENT_ID, this.parent ? this.parent.id : null);
    const formsToRecover = (
      // we go over all forms in the new DOM; because this is only the HTML for the current
      // view, we can be sure that all forms are owned by this view:
      dom_default.all(template.content, "form").filter((newForm) => newForm.id && oldForms[newForm.id]).filter((newForm) => !this.pendingForms.has(newForm.id)).filter(
        (newForm) => oldForms[newForm.id].getAttribute(phxChange) === newForm.getAttribute(phxChange)
      ).map((newForm) => {
        return [oldForms[newForm.id], newForm];
      })
    );
    if (formsToRecover.length === 0) {
      return callback();
    }
    formsToRecover.forEach(([oldForm, newForm], i) => {
      this.pendingForms.add(newForm.id);
      this.pushFormRecovery(
        oldForm,
        newForm,
        template.content.firstElementChild,
        () => {
          this.pendingForms.delete(newForm.id);
          if (i === formsToRecover.length - 1) {
            callback();
          }
        }
      );
    });
  }
  getChildById(id) {
    return this.root.children[this.id][id];
  }
  getDescendentByEl(el) {
    if (el.id === this.id) {
      return this;
    } else {
      return this.children[el.getAttribute(PHX_PARENT_ID)]?.[el.id];
    }
  }
  destroyDescendent(id) {
    for (const parentId in this.root.children) {
      for (const childId in this.root.children[parentId]) {
        if (childId === id) {
          return this.root.children[parentId][childId].destroy();
        }
      }
    }
  }
  joinChild(el) {
    const child = this.getChildById(el.id);
    if (!child) {
      const view = new _View(el, this.liveSocket, this);
      this.root.children[this.id][view.id] = view;
      view.join();
      this.childJoins++;
      return true;
    }
  }
  isJoinPending() {
    return this.joinPending;
  }
  ackJoin(_child) {
    this.childJoins--;
    if (this.childJoins === 0) {
      if (this.parent) {
        this.parent.ackJoin(this);
      } else {
        this.onAllChildJoinsComplete();
      }
    }
  }
  onAllChildJoinsComplete() {
    this.pendingForms.clear();
    this.formsForRecovery = {};
    this.joinCallback(() => {
      this.pendingJoinOps.forEach(([view, op]) => {
        if (!view.isDestroyed()) {
          op();
        }
      });
      this.pendingJoinOps = [];
    });
  }
  update(diff, events, isPending = false) {
    if (this.isJoinPending() || this.liveSocket.hasPendingLink() && this.root.isMain()) {
      if (!isPending) {
        this.pendingDiffs.push({ diff, events });
      }
      return false;
    }
    this.rendered.mergeDiff(diff);
    let phxChildrenAdded = false;
    if (this.rendered.isComponentOnlyDiff(diff)) {
      this.liveSocket.time("component patch complete", () => {
        const parentCids = dom_default.findExistingParentCIDs(
          this.id,
          this.rendered.componentCIDs(diff)
        );
        parentCids.forEach((parentCID) => {
          if (this.componentPatch(
            this.rendered.getComponent(diff, parentCID),
            parentCID
          )) {
            phxChildrenAdded = true;
          }
        });
      });
    } else if (!isEmpty(diff)) {
      this.liveSocket.time("full patch complete", () => {
        const [html, streams] = this.renderContainer(diff, "update");
        const patch = new DOMPatch(this, this.el, this.id, html, streams, null);
        phxChildrenAdded = this.performPatch(patch, true);
      });
    }
    this.liveSocket.dispatchEvents(events);
    if (phxChildrenAdded) {
      this.joinNewChildren();
    }
    return true;
  }
  renderContainer(diff, kind) {
    return this.liveSocket.time(`toString diff (${kind})`, () => {
      const tag = this.el.tagName;
      const cids = diff ? this.rendered.componentCIDs(diff) : null;
      const { buffer: html, streams } = this.rendered.toString(cids);
      return [`<${tag}>${html}</${tag}>`, streams];
    });
  }
  componentPatch(diff, cid) {
    if (isEmpty(diff))
      return false;
    const { buffer: html, streams } = this.rendered.componentToString(cid);
    const patch = new DOMPatch(this, this.el, this.id, html, streams, cid);
    const childrenAdded = this.performPatch(patch, true);
    return childrenAdded;
  }
  getHook(el) {
    return this.viewHooks[ViewHook.elementID(el)];
  }
  addHook(el) {
    const hookElId = ViewHook.elementID(el);
    if (el.getAttribute && !this.ownsElement(el)) {
      return;
    }
    if (hookElId && !this.viewHooks[hookElId]) {
      const hook = dom_default.getCustomElHook(el) || logError(`no hook found for custom element: ${el.id}`);
      this.viewHooks[hookElId] = hook;
      hook.__attachView(this);
      return hook;
    } else if (hookElId || !el.getAttribute) {
      return;
    } else {
      const hookName = el.getAttribute(`data-phx-${PHX_HOOK}`) || el.getAttribute(this.binding(PHX_HOOK));
      if (!hookName) {
        return;
      }
      const hookDefinition = this.liveSocket.getHookDefinition(hookName);
      if (hookDefinition) {
        if (!el.id) {
          logError(
            `no DOM ID for hook "${hookName}". Hooks require a unique ID on each element.`,
            el
          );
          return;
        }
        let hookInstance;
        try {
          if (typeof hookDefinition === "function" && hookDefinition.prototype instanceof ViewHook) {
            hookInstance = new hookDefinition(this, el);
          } else if (typeof hookDefinition === "object" && hookDefinition !== null) {
            hookInstance = new ViewHook(this, el, hookDefinition);
          } else {
            logError(
              `Invalid hook definition for "${hookName}". Expected a class extending ViewHook or an object definition.`,
              el
            );
            return;
          }
        } catch (e) {
          const errorMessage = e instanceof Error ? e.message : String(e);
          logError(`Failed to create hook "${hookName}": ${errorMessage}`, el);
          return;
        }
        this.viewHooks[ViewHook.elementID(hookInstance.el)] = hookInstance;
        return hookInstance;
      } else if (hookName !== null) {
        logError(`unknown hook found for "${hookName}"`, el);
      }
    }
  }
  destroyHook(hook) {
    const hookId = ViewHook.elementID(hook.el);
    hook.__destroyed();
    hook.__cleanup__();
    delete this.viewHooks[hookId];
  }
  applyPendingUpdates() {
    this.pendingDiffs = this.pendingDiffs.filter(
      ({ diff, events }) => !this.update(diff, events, true)
    );
    this.eachChild((child) => child.applyPendingUpdates());
  }
  eachChild(callback) {
    const children = this.root.children[this.id] || {};
    for (const id in children) {
      callback(this.getChildById(id));
    }
  }
  onChannel(event, cb) {
    this.liveSocket.onChannel(this.channel, event, (resp) => {
      if (this.isJoinPending()) {
        this.root.pendingJoinOps.push([this, () => cb(resp)]);
      } else {
        this.liveSocket.requestDOMUpdate(() => cb(resp));
      }
    });
  }
  bindChannel() {
    this.liveSocket.onChannel(this.channel, "diff", (rawDiff) => {
      this.liveSocket.requestDOMUpdate(() => {
        this.applyDiff(
          "update",
          rawDiff,
          ({ diff, events }) => this.update(diff, events)
        );
      });
    });
    this.onChannel(
      "redirect",
      ({ to, flash }) => this.onRedirect({ to, flash })
    );
    this.onChannel("live_patch", (redir) => this.onLivePatch(redir));
    this.onChannel("live_redirect", (redir) => this.onLiveRedirect(redir));
    this.channel.onError((reason) => this.onError(reason));
    this.channel.onClose((reason) => this.onClose(reason));
  }
  destroyAllChildren() {
    this.eachChild((child) => child.destroy());
  }
  onLiveRedirect(redir) {
    const { to, kind, flash } = redir;
    const url = this.expandURL(to);
    const e = new CustomEvent("phx:server-navigate", {
      detail: { to, kind, flash }
    });
    this.liveSocket.historyRedirect(e, url, kind, flash);
  }
  onLivePatch(redir) {
    const { to, kind } = redir;
    this.href = this.expandURL(to);
    this.liveSocket.historyPatch(to, kind);
  }
  expandURL(to) {
    return to.startsWith("/") ? `${window.location.protocol}//${window.location.host}${to}` : to;
  }
  /**
   * @param {{to: string, flash?: string, reloadToken?: string}} redirect
   */
  onRedirect({ to, flash, reloadToken }) {
    this.liveSocket.redirect(to, flash, reloadToken);
  }
  isDestroyed() {
    return this.destroyed;
  }
  joinDead() {
    this.isDead = true;
  }
  joinPush() {
    this.joinPush = this.joinPush || this.channel.join();
    return this.joinPush;
  }
  join(callback) {
    this.showLoader(this.liveSocket.loaderTimeout);
    this.bindChannel();
    if (this.isMain()) {
      this.stopCallback = this.liveSocket.withPageLoading({
        to: this.href,
        kind: "initial"
      });
    }
    this.joinCallback = (onDone) => {
      onDone = onDone || function() {
      };
      callback ? callback(this.joinCount, onDone) : onDone();
    };
    this.wrapPush(() => this.channel.join(), {
      ok: (resp) => this.liveSocket.requestDOMUpdate(() => this.onJoin(resp)),
      error: (error) => this.onJoinError(error),
      timeout: () => this.onJoinError({ reason: "timeout" })
    });
  }
  onJoinError(resp) {
    if (resp.reason === "reload") {
      this.log("error", () => [
        `failed mount with ${resp.status}. Falling back to page reload`,
        resp
      ]);
      this.onRedirect({ to: this.root.href, reloadToken: resp.token });
      return;
    } else if (resp.reason === "unauthorized" || resp.reason === "stale") {
      this.log("error", () => [
        "unauthorized live_redirect. Falling back to page request",
        resp
      ]);
      this.onRedirect({ to: this.root.href, flash: this.flash });
      return;
    }
    if (resp.redirect || resp.live_redirect) {
      this.joinPending = false;
      this.channel.leave();
    }
    if (resp.redirect) {
      return this.onRedirect(resp.redirect);
    }
    if (resp.live_redirect) {
      return this.onLiveRedirect(resp.live_redirect);
    }
    this.log("error", () => ["unable to join", resp]);
    if (this.isMain()) {
      this.displayError([
        PHX_LOADING_CLASS,
        PHX_ERROR_CLASS,
        PHX_SERVER_ERROR_CLASS
      ]);
      if (this.liveSocket.isConnected()) {
        this.liveSocket.reloadWithJitter(this);
      }
    } else {
      if (this.joinAttempts >= MAX_CHILD_JOIN_ATTEMPTS) {
        this.root.displayError([
          PHX_LOADING_CLASS,
          PHX_ERROR_CLASS,
          PHX_SERVER_ERROR_CLASS
        ]);
        this.log("error", () => [
          `giving up trying to mount after ${MAX_CHILD_JOIN_ATTEMPTS} tries`,
          resp
        ]);
        this.destroy();
      }
      const trueChildEl = dom_default.byId(this.el.id);
      if (trueChildEl) {
        dom_default.mergeAttrs(trueChildEl, this.el);
        this.displayError([
          PHX_LOADING_CLASS,
          PHX_ERROR_CLASS,
          PHX_SERVER_ERROR_CLASS
        ]);
        this.el = trueChildEl;
      } else {
        this.destroy();
      }
    }
  }
  onClose(reason) {
    if (this.isDestroyed()) {
      return;
    }
    if (this.isMain() && this.liveSocket.hasPendingLink() && reason !== "leave") {
      return this.liveSocket.reloadWithJitter(this);
    }
    this.destroyAllChildren();
    this.liveSocket.dropActiveElement(this);
    if (this.liveSocket.isUnloaded()) {
      this.showLoader(BEFORE_UNLOAD_LOADER_TIMEOUT);
    }
  }
  onError(reason) {
    this.onClose(reason);
    if (this.liveSocket.isConnected()) {
      this.log("error", () => ["view crashed", reason]);
    }
    if (!this.liveSocket.isUnloaded()) {
      if (this.liveSocket.isConnected()) {
        this.displayError([
          PHX_LOADING_CLASS,
          PHX_ERROR_CLASS,
          PHX_SERVER_ERROR_CLASS
        ]);
      } else {
        this.displayError([
          PHX_LOADING_CLASS,
          PHX_ERROR_CLASS,
          PHX_CLIENT_ERROR_CLASS
        ]);
      }
    }
  }
  displayError(classes) {
    if (this.isMain()) {
      dom_default.dispatchEvent(window, "phx:page-loading-start", {
        detail: { to: this.href, kind: "error" }
      });
    }
    this.showLoader();
    this.setContainerClasses(...classes);
    this.delayedDisconnected();
  }
  delayedDisconnected() {
    this.disconnectedTimer = setTimeout(() => {
      this.execAll(this.binding("disconnected"));
    }, this.liveSocket.disconnectedTimeout);
  }
  wrapPush(callerPush, receives) {
    const latency = this.liveSocket.getLatencySim();
    const withLatency = latency ? (cb) => setTimeout(() => !this.isDestroyed() && cb(), latency) : (cb) => !this.isDestroyed() && cb();
    withLatency(() => {
      callerPush().receive(
        "ok",
        (resp) => withLatency(() => receives.ok && receives.ok(resp))
      ).receive(
        "error",
        (reason) => withLatency(() => receives.error && receives.error(reason))
      ).receive(
        "timeout",
        () => withLatency(() => receives.timeout && receives.timeout())
      );
    });
  }
  pushWithReply(refGenerator, event, payload) {
    if (!this.isConnected()) {
      return Promise.reject(new Error("no connection"));
    }
    const [ref, [el], opts] = refGenerator ? refGenerator({ payload }) : [null, [], {}];
    const oldJoinCount = this.joinCount;
    let onLoadingDone = function() {
    };
    if (opts.page_loading) {
      onLoadingDone = this.liveSocket.withPageLoading({
        kind: "element",
        target: el
      });
    }
    if (typeof payload.cid !== "number") {
      delete payload.cid;
    }
    return new Promise((resolve, reject) => {
      this.wrapPush(() => this.channel.push(event, payload, PUSH_TIMEOUT), {
        ok: (resp) => {
          if (ref !== null) {
            this.lastAckRef = ref;
          }
          const finish = (hookReply) => {
            if (resp.redirect) {
              this.onRedirect(resp.redirect);
            }
            if (resp.live_patch) {
              this.onLivePatch(resp.live_patch);
            }
            if (resp.live_redirect) {
              this.onLiveRedirect(resp.live_redirect);
            }
            onLoadingDone();
            resolve({ resp, reply: hookReply, ref });
          };
          if (resp.diff) {
            this.liveSocket.requestDOMUpdate(() => {
              this.applyDiff("update", resp.diff, ({ diff, reply, events }) => {
                if (ref !== null) {
                  this.undoRefs(ref, payload.event);
                }
                this.update(diff, events);
                finish(reply);
              });
            });
          } else {
            if (ref !== null) {
              this.undoRefs(ref, payload.event);
            }
            finish(null);
          }
        },
        error: (reason) => reject(new Error(`failed with reason: ${reason}`)),
        timeout: () => {
          reject(new Error("timeout"));
          if (this.joinCount === oldJoinCount) {
            this.liveSocket.reloadWithJitter(this, () => {
              this.log("timeout", () => [
                "received timeout while communicating with server. Falling back to hard refresh for recovery"
              ]);
            });
          }
        }
      });
    });
  }
  undoRefs(ref, phxEvent, onlyEls) {
    if (!this.isConnected()) {
      return;
    }
    const selector = `[${PHX_REF_SRC}="${this.refSrc()}"]`;
    if (onlyEls) {
      onlyEls = new Set(onlyEls);
      dom_default.all(document, selector, (parent) => {
        if (onlyEls && !onlyEls.has(parent)) {
          return;
        }
        dom_default.all(
          parent,
          selector,
          (child) => this.undoElRef(child, ref, phxEvent)
        );
        this.undoElRef(parent, ref, phxEvent);
      });
    } else {
      dom_default.all(document, selector, (el) => this.undoElRef(el, ref, phxEvent));
    }
  }
  undoElRef(el, ref, phxEvent) {
    const elRef = new ElementRef(el);
    elRef.maybeUndo(ref, phxEvent, (clonedTree) => {
      const patch = new DOMPatch(this, el, this.id, clonedTree, [], null, {
        undoRef: ref
      });
      const phxChildrenAdded = this.performPatch(patch, true);
      dom_default.all(
        el,
        `[${PHX_REF_SRC}="${this.refSrc()}"]`,
        (child) => this.undoElRef(child, ref, phxEvent)
      );
      if (phxChildrenAdded) {
        this.joinNewChildren();
      }
    });
  }
  refSrc() {
    return this.el.id;
  }
  putRef(elements, phxEvent, eventType, opts = {}) {
    const newRef = this.ref++;
    const disableWith = this.binding(PHX_DISABLE_WITH);
    if (opts.loading) {
      const loadingEls = dom_default.all(document, opts.loading).map((el) => {
        return { el, lock: true, loading: true };
      });
      elements = elements.concat(loadingEls);
    }
    for (const { el, lock, loading } of elements) {
      if (!lock && !loading) {
        throw new Error("putRef requires lock or loading");
      }
      el.setAttribute(PHX_REF_SRC, this.refSrc());
      if (loading) {
        el.setAttribute(PHX_REF_LOADING, newRef);
      }
      if (lock) {
        el.setAttribute(PHX_REF_LOCK, newRef);
      }
      if (!loading || opts.submitter && !(el === opts.submitter || el === opts.form)) {
        continue;
      }
      const lockCompletePromise = new Promise((resolve) => {
        el.addEventListener(`phx:undo-lock:${newRef}`, () => resolve(detail), {
          once: true
        });
      });
      const loadingCompletePromise = new Promise((resolve) => {
        el.addEventListener(
          `phx:undo-loading:${newRef}`,
          () => resolve(detail),
          { once: true }
        );
      });
      el.classList.add(`phx-${eventType}-loading`);
      const disableText = el.getAttribute(disableWith);
      if (disableText !== null) {
        if (!el.getAttribute(PHX_DISABLE_WITH_RESTORE)) {
          el.setAttribute(PHX_DISABLE_WITH_RESTORE, el.innerText);
        }
        if (disableText !== "") {
          el.innerText = disableText;
        }
        el.setAttribute(
          PHX_DISABLED,
          el.getAttribute(PHX_DISABLED) || el.disabled
        );
        el.setAttribute("disabled", "");
      }
      const detail = {
        event: phxEvent,
        eventType,
        ref: newRef,
        isLoading: loading,
        isLocked: lock,
        lockElements: elements.filter(({ lock: lock2 }) => lock2).map(({ el: el2 }) => el2),
        loadingElements: elements.filter(({ loading: loading2 }) => loading2).map(({ el: el2 }) => el2),
        unlock: (els) => {
          els = Array.isArray(els) ? els : [els];
          this.undoRefs(newRef, phxEvent, els);
        },
        lockComplete: lockCompletePromise,
        loadingComplete: loadingCompletePromise,
        lock: (lockEl) => {
          return new Promise((resolve) => {
            if (this.isAcked(newRef)) {
              return resolve(detail);
            }
            lockEl.setAttribute(PHX_REF_LOCK, newRef);
            lockEl.setAttribute(PHX_REF_SRC, this.refSrc());
            lockEl.addEventListener(
              `phx:lock-stop:${newRef}`,
              () => resolve(detail),
              { once: true }
            );
          });
        }
      };
      if (opts.payload) {
        detail["payload"] = opts.payload;
      }
      if (opts.target) {
        detail["target"] = opts.target;
      }
      if (opts.originalEvent) {
        detail["originalEvent"] = opts.originalEvent;
      }
      el.dispatchEvent(
        new CustomEvent("phx:push", {
          detail,
          bubbles: true,
          cancelable: false
        })
      );
      if (phxEvent) {
        el.dispatchEvent(
          new CustomEvent(`phx:push:${phxEvent}`, {
            detail,
            bubbles: true,
            cancelable: false
          })
        );
      }
    }
    return [newRef, elements.map(({ el }) => el), opts];
  }
  isAcked(ref) {
    return this.lastAckRef !== null && this.lastAckRef >= ref;
  }
  componentID(el) {
    const cid = el.getAttribute && el.getAttribute(PHX_COMPONENT);
    return cid ? parseInt(cid) : null;
  }
  targetComponentID(target, targetCtx, opts = {}) {
    if (isCid(targetCtx)) {
      return targetCtx;
    }
    const cidOrSelector = opts.target || target.getAttribute(this.binding("target"));
    if (isCid(cidOrSelector)) {
      return parseInt(cidOrSelector);
    } else if (targetCtx && (cidOrSelector !== null || opts.target)) {
      return this.closestComponentID(targetCtx);
    } else {
      return null;
    }
  }
  closestComponentID(targetCtx) {
    if (isCid(targetCtx)) {
      return targetCtx;
    } else if (targetCtx) {
      return maybe(
        targetCtx.closest(`[${PHX_COMPONENT}]`),
        (el) => this.ownsElement(el) && this.componentID(el)
      );
    } else {
      return null;
    }
  }
  pushHookEvent(el, targetCtx, event, payload) {
    if (!this.isConnected()) {
      this.log("hook", () => [
        "unable to push hook event. LiveView not connected",
        event,
        payload
      ]);
      return Promise.reject(
        new Error("unable to push hook event. LiveView not connected")
      );
    }
    const refGenerator = () => this.putRef([{ el, loading: true, lock: true }], event, "hook", {
      payload,
      target: targetCtx
    });
    return this.pushWithReply(refGenerator, "event", {
      type: "hook",
      event,
      value: payload,
      cid: this.closestComponentID(targetCtx)
    }).then(({ resp: _resp, reply, ref }) => ({ reply, ref }));
  }
  extractMeta(el, meta, value) {
    const prefix = this.binding("value-");
    for (let i = 0; i < el.attributes.length; i++) {
      if (!meta) {
        meta = {};
      }
      const name = el.attributes[i].name;
      if (name.startsWith(prefix)) {
        meta[name.replace(prefix, "")] = el.getAttribute(name);
      }
    }
    if (el.value !== void 0 && !(el instanceof HTMLFormElement)) {
      if (!meta) {
        meta = {};
      }
      meta.value = el.value;
      if (el.tagName === "INPUT" && CHECKABLE_INPUTS.indexOf(el.type) >= 0 && !el.checked) {
        delete meta.value;
      }
    }
    if (value) {
      if (!meta) {
        meta = {};
      }
      for (const key in value) {
        meta[key] = value[key];
      }
    }
    return meta;
  }
  pushEvent(type, el, targetCtx, phxEvent, meta, opts = {}, onReply) {
    this.pushWithReply(
      (maybePayload) => this.putRef([{ el, loading: true, lock: true }], phxEvent, type, {
        ...opts,
        payload: maybePayload?.payload
      }),
      "event",
      {
        type,
        event: phxEvent,
        value: this.extractMeta(el, meta, opts.value),
        cid: this.targetComponentID(el, targetCtx, opts)
      }
    ).then(({ reply }) => onReply && onReply(reply)).catch((error) => logError("Failed to push event", error));
  }
  pushFileProgress(fileEl, entryRef, progress, onReply = function() {
  }) {
    this.liveSocket.withinOwners(fileEl.form, (view, targetCtx) => {
      view.pushWithReply(null, "progress", {
        event: fileEl.getAttribute(view.binding(PHX_PROGRESS)),
        ref: fileEl.getAttribute(PHX_UPLOAD_REF),
        entry_ref: entryRef,
        progress,
        cid: view.targetComponentID(fileEl.form, targetCtx)
      }).then(() => onReply()).catch((error) => logError("Failed to push file progress", error));
    });
  }
  pushInput(inputEl, targetCtx, forceCid, phxEvent, opts, callback) {
    if (!inputEl.form) {
      throw new Error("form events require the input to be inside a form");
    }
    let uploads;
    const cid = isCid(forceCid) ? forceCid : this.targetComponentID(inputEl.form, targetCtx, opts);
    const refGenerator = (maybePayload) => {
      return this.putRef(
        [
          { el: inputEl, loading: true, lock: true },
          { el: inputEl.form, loading: true, lock: true }
        ],
        phxEvent,
        "change",
        { ...opts, payload: maybePayload?.payload }
      );
    };
    let formData;
    const meta = this.extractMeta(inputEl.form, {}, opts.value);
    const serializeOpts = {};
    if (inputEl instanceof HTMLButtonElement) {
      serializeOpts.submitter = inputEl;
    }
    if (inputEl.getAttribute(this.binding("change"))) {
      formData = serializeForm(inputEl.form, serializeOpts, [inputEl.name]);
    } else {
      formData = serializeForm(inputEl.form, serializeOpts);
    }
    if (dom_default.isUploadInput(inputEl) && inputEl.files && inputEl.files.length > 0) {
      LiveUploader.trackFiles(inputEl, Array.from(inputEl.files));
    }
    uploads = LiveUploader.serializeUploads(inputEl);
    const event = {
      type: "form",
      event: phxEvent,
      value: formData,
      meta: {
        // no target was implicitly sent as "undefined" in LV <= 1.0.5, therefore
        // we have to keep it. In 1.0.6 we switched from passing meta as URL encoded data
        // to passing it directly in the event, but the JSON encode would drop keys with
        // undefined values.
        _target: opts._target || "undefined",
        ...meta
      },
      uploads,
      cid
    };
    this.pushWithReply(refGenerator, "event", event).then(({ resp }) => {
      if (dom_default.isUploadInput(inputEl) && dom_default.isAutoUpload(inputEl)) {
        ElementRef.onUnlock(inputEl, () => {
          if (LiveUploader.filesAwaitingPreflight(inputEl).length > 0) {
            const [ref, _els] = refGenerator();
            this.undoRefs(ref, phxEvent, [inputEl.form]);
            this.uploadFiles(
              inputEl.form,
              phxEvent,
              targetCtx,
              ref,
              cid,
              (_uploads) => {
                callback && callback(resp);
                this.triggerAwaitingSubmit(inputEl.form, phxEvent);
                this.undoRefs(ref, phxEvent);
              }
            );
          }
        });
      } else {
        callback && callback(resp);
      }
    }).catch((error) => logError("Failed to push input event", error));
  }
  triggerAwaitingSubmit(formEl, phxEvent) {
    const awaitingSubmit = this.getScheduledSubmit(formEl);
    if (awaitingSubmit) {
      const [_el, _ref, _opts, callback] = awaitingSubmit;
      this.cancelSubmit(formEl, phxEvent);
      callback();
    }
  }
  getScheduledSubmit(formEl) {
    return this.formSubmits.find(
      ([el, _ref, _opts, _callback]) => el.isSameNode(formEl)
    );
  }
  scheduleSubmit(formEl, ref, opts, callback) {
    if (this.getScheduledSubmit(formEl)) {
      return true;
    }
    this.formSubmits.push([formEl, ref, opts, callback]);
  }
  cancelSubmit(formEl, phxEvent) {
    this.formSubmits = this.formSubmits.filter(
      ([el, ref, _opts, _callback]) => {
        if (el.isSameNode(formEl)) {
          this.undoRefs(ref, phxEvent);
          return false;
        } else {
          return true;
        }
      }
    );
  }
  disableForm(formEl, phxEvent, opts = {}) {
    const filterIgnored = (el) => {
      const userIgnored = closestPhxBinding(
        el,
        `${this.binding(PHX_UPDATE)}=ignore`,
        el.form
      );
      return !(userIgnored || closestPhxBinding(el, "data-phx-update=ignore", el.form));
    };
    const filterDisables = (el) => {
      return el.hasAttribute(this.binding(PHX_DISABLE_WITH));
    };
    const filterButton = (el) => el.tagName == "BUTTON";
    const filterInput = (el) => ["INPUT", "TEXTAREA", "SELECT"].includes(el.tagName);
    const formElements = Array.from(formEl.elements);
    const disables = formElements.filter(filterDisables);
    const buttons = formElements.filter(filterButton).filter(filterIgnored);
    const inputs = formElements.filter(filterInput).filter(filterIgnored);
    buttons.forEach((button) => {
      button.setAttribute(PHX_DISABLED, button.disabled);
      button.disabled = true;
    });
    inputs.forEach((input) => {
      input.setAttribute(PHX_READONLY, input.readOnly);
      input.readOnly = true;
      if (input.files) {
        input.setAttribute(PHX_DISABLED, input.disabled);
        input.disabled = true;
      }
    });
    const formEls = disables.concat(buttons).concat(inputs).map((el) => {
      return { el, loading: true, lock: true };
    });
    const els = [{ el: formEl, loading: true, lock: false }].concat(formEls).reverse();
    return this.putRef(els, phxEvent, "submit", opts);
  }
  pushFormSubmit(formEl, targetCtx, phxEvent, submitter, opts, onReply) {
    const refGenerator = (maybePayload) => this.disableForm(formEl, phxEvent, {
      ...opts,
      form: formEl,
      payload: maybePayload?.payload,
      submitter
    });
    dom_default.putPrivate(formEl, "submitter", submitter);
    const cid = this.targetComponentID(formEl, targetCtx);
    if (LiveUploader.hasUploadsInProgress(formEl)) {
      const [ref, _els] = refGenerator();
      const push = () => this.pushFormSubmit(
        formEl,
        targetCtx,
        phxEvent,
        submitter,
        opts,
        onReply
      );
      return this.scheduleSubmit(formEl, ref, opts, push);
    } else if (LiveUploader.inputsAwaitingPreflight(formEl).length > 0) {
      const [ref, els] = refGenerator();
      const proxyRefGen = () => [ref, els, opts];
      this.uploadFiles(formEl, phxEvent, targetCtx, ref, cid, (_uploads) => {
        if (LiveUploader.inputsAwaitingPreflight(formEl).length > 0) {
          return this.undoRefs(ref, phxEvent);
        }
        const meta = this.extractMeta(formEl, {}, opts.value);
        const formData = serializeForm(formEl, { submitter });
        this.pushWithReply(proxyRefGen, "event", {
          type: "form",
          event: phxEvent,
          value: formData,
          meta,
          cid
        }).then(({ resp }) => onReply(resp)).catch((error) => logError("Failed to push form submit", error));
      });
    } else if (!(formEl.hasAttribute(PHX_REF_SRC) && formEl.classList.contains("phx-submit-loading"))) {
      const meta = this.extractMeta(formEl, {}, opts.value);
      const formData = serializeForm(formEl, { submitter });
      this.pushWithReply(refGenerator, "event", {
        type: "form",
        event: phxEvent,
        value: formData,
        meta,
        cid
      }).then(({ resp }) => onReply(resp)).catch((error) => logError("Failed to push form submit", error));
    }
  }
  uploadFiles(formEl, phxEvent, targetCtx, ref, cid, onComplete) {
    const joinCountAtUpload = this.joinCount;
    const inputEls = LiveUploader.activeFileInputs(formEl);
    let numFileInputsInProgress = inputEls.length;
    inputEls.forEach((inputEl) => {
      const uploader = new LiveUploader(inputEl, this, () => {
        numFileInputsInProgress--;
        if (numFileInputsInProgress === 0) {
          onComplete();
        }
      });
      const entries = uploader.entries().map((entry) => entry.toPreflightPayload());
      if (entries.length === 0) {
        numFileInputsInProgress--;
        return;
      }
      const payload = {
        ref: inputEl.getAttribute(PHX_UPLOAD_REF),
        entries,
        cid: this.targetComponentID(inputEl.form, targetCtx)
      };
      this.log("upload", () => ["sending preflight request", payload]);
      this.pushWithReply(null, "allow_upload", payload).then(({ resp }) => {
        this.log("upload", () => ["got preflight response", resp]);
        uploader.entries().forEach((entry) => {
          if (resp.entries && !resp.entries[entry.ref]) {
            this.handleFailedEntryPreflight(
              entry.ref,
              "failed preflight",
              uploader
            );
          }
        });
        if (resp.error || Object.keys(resp.entries).length === 0) {
          this.undoRefs(ref, phxEvent);
          const errors = resp.error || [];
          errors.map(([entry_ref, reason]) => {
            this.handleFailedEntryPreflight(entry_ref, reason, uploader);
          });
        } else {
          const onError = (callback) => {
            this.channel.onError(() => {
              if (this.joinCount === joinCountAtUpload) {
                callback();
              }
            });
          };
          uploader.initAdapterUpload(resp, onError, this.liveSocket);
        }
      }).catch((error) => logError("Failed to push upload", error));
    });
  }
  handleFailedEntryPreflight(uploadRef, reason, uploader) {
    if (uploader.isAutoUpload()) {
      const entry = uploader.entries().find((entry2) => entry2.ref === uploadRef.toString());
      if (entry) {
        entry.cancel();
      }
    } else {
      uploader.entries().map((entry) => entry.cancel());
    }
    this.log("upload", () => [`error for entry ${uploadRef}`, reason]);
  }
  dispatchUploads(targetCtx, name, filesOrBlobs) {
    const targetElement = this.targetCtxElement(targetCtx) || this.el;
    const inputs = dom_default.findUploadInputs(targetElement).filter(
      (el) => el.name === name
    );
    if (inputs.length === 0) {
      logError(`no live file inputs found matching the name "${name}"`);
    } else if (inputs.length > 1) {
      logError(`duplicate live file inputs found matching the name "${name}"`);
    } else {
      dom_default.dispatchEvent(inputs[0], PHX_TRACK_UPLOADS, {
        detail: { files: filesOrBlobs }
      });
    }
  }
  targetCtxElement(targetCtx) {
    if (isCid(targetCtx)) {
      const [target] = dom_default.findComponentNodeList(this.id, targetCtx);
      return target;
    } else if (targetCtx) {
      return targetCtx;
    } else {
      return null;
    }
  }
  pushFormRecovery(oldForm, newForm, templateDom, callback) {
    const phxChange = this.binding("change");
    const phxTarget = newForm.getAttribute(this.binding("target")) || newForm;
    const phxEvent = newForm.getAttribute(this.binding(PHX_AUTO_RECOVER)) || newForm.getAttribute(this.binding("change"));
    const inputs = Array.from(oldForm.elements).filter(
      (el) => dom_default.isFormInput(el) && el.name && !el.hasAttribute(phxChange)
    );
    if (inputs.length === 0) {
      callback();
      return;
    }
    inputs.forEach(
      (input2) => input2.hasAttribute(PHX_UPLOAD_REF) && LiveUploader.clearFiles(input2)
    );
    const input = inputs.find((el) => el.type !== "hidden") || inputs[0];
    let pending = 0;
    this.withinTargets(
      phxTarget,
      (targetView, targetCtx) => {
        const cid = this.targetComponentID(newForm, targetCtx);
        pending++;
        let e = new CustomEvent("phx:form-recovery", {
          detail: { sourceElement: oldForm }
        });
        js_default.exec(e, "change", phxEvent, this, input, [
          "push",
          {
            _target: input.name,
            targetView,
            targetCtx,
            newCid: cid,
            callback: () => {
              pending--;
              if (pending === 0) {
                callback();
              }
            }
          }
        ]);
      },
      templateDom
    );
  }
  pushLinkPatch(e, href, targetEl, callback) {
    const linkRef = this.liveSocket.setPendingLink(href);
    const loading = e.isTrusted && e.type !== "popstate";
    const refGen = targetEl ? () => this.putRef(
      [{ el: targetEl, loading, lock: true }],
      null,
      "click"
    ) : null;
    const fallback = () => this.liveSocket.redirect(window.location.href);
    const url = href.startsWith("/") ? `${location.protocol}//${location.host}${href}` : href;
    this.pushWithReply(refGen, "live_patch", { url }).then(
      ({ resp }) => {
        this.liveSocket.requestDOMUpdate(() => {
          if (resp.link_redirect) {
            this.liveSocket.replaceMain(href, null, callback, linkRef);
          } else {
            if (this.liveSocket.commitPendingLink(linkRef)) {
              this.href = href;
            }
            this.applyPendingUpdates();
            callback && callback(linkRef);
          }
        });
      },
      ({ error: _error, timeout: _timeout }) => fallback()
    );
  }
  getFormsForRecovery() {
    if (this.joinCount === 0) {
      return {};
    }
    const phxChange = this.binding("change");
    return dom_default.all(this.el, `form[${phxChange}]`).filter((form) => form.id).filter((form) => form.elements.length > 0).filter(
      (form) => form.getAttribute(this.binding(PHX_AUTO_RECOVER)) !== "ignore"
    ).map((form) => {
      const clonedForm = form.cloneNode(true);
      morphdom_esm_default(clonedForm, form, {
        onBeforeElUpdated: (fromEl, toEl) => {
          dom_default.copyPrivates(fromEl, toEl);
          return true;
        }
      });
      const externalElements = document.querySelectorAll(
        `[form="${form.id}"]`
      );
      Array.from(externalElements).forEach((el) => {
        if (form.contains(el)) {
          return;
        }
        const clonedEl = el.cloneNode(true);
        morphdom_esm_default(clonedEl, el);
        dom_default.copyPrivates(clonedEl, el);
        clonedForm.appendChild(clonedEl);
      });
      return clonedForm;
    }).reduce((acc, form) => {
      acc[form.id] = form;
      return acc;
    }, {});
  }
  maybePushComponentsDestroyed(destroyedCIDs) {
    let willDestroyCIDs = destroyedCIDs.filter((cid) => {
      return dom_default.findComponentNodeList(this.el, cid).length === 0;
    });
    const onError = (error) => {
      if (!this.isDestroyed()) {
        logError("Failed to push components destroyed", error);
      }
    };
    if (willDestroyCIDs.length > 0) {
      willDestroyCIDs.forEach((cid) => this.rendered.resetRender(cid));
      this.pushWithReply(null, "cids_will_destroy", { cids: willDestroyCIDs }).then(() => {
        this.liveSocket.requestDOMUpdate(() => {
          let completelyDestroyCIDs = willDestroyCIDs.filter((cid) => {
            return dom_default.findComponentNodeList(this.el, cid).length === 0;
          });
          if (completelyDestroyCIDs.length > 0) {
            this.pushWithReply(null, "cids_destroyed", {
              cids: completelyDestroyCIDs
            }).then(({ resp }) => {
              this.rendered.pruneCIDs(resp.cids);
            }).catch(onError);
          }
        });
      }).catch(onError);
    }
  }
  ownsElement(el) {
    let parentViewEl = dom_default.closestViewEl(el);
    return el.getAttribute(PHX_PARENT_ID) === this.id || parentViewEl && parentViewEl.id === this.id || !parentViewEl && this.isDead;
  }
  submitForm(form, targetCtx, phxEvent, submitter, opts = {}) {
    dom_default.putPrivate(form, PHX_HAS_SUBMITTED, true);
    const inputs = Array.from(form.elements);
    inputs.forEach((input) => dom_default.putPrivate(input, PHX_HAS_SUBMITTED, true));
    this.liveSocket.blurActiveElement(this);
    this.pushFormSubmit(form, targetCtx, phxEvent, submitter, opts, () => {
      this.liveSocket.restorePreviouslyActiveFocus();
    });
  }
  binding(kind) {
    return this.liveSocket.binding(kind);
  }
  // phx-portal
  pushPortalElementId(id) {
    this.portalElementIds.add(id);
  }
  dropPortalElementId(id) {
    this.portalElementIds.delete(id);
  }
  destroyPortalElements() {
    this.portalElementIds.forEach((id) => {
      const el = document.getElementById(id);
      if (el) {
        el.remove();
      }
    });
  }
};
var LiveSocket = class {
  constructor(url, phxSocket, opts = {}) {
    this.unloaded = false;
    if (!phxSocket || phxSocket.constructor.name === "Object") {
      throw new Error(`
      a phoenix Socket must be provided as the second argument to the LiveSocket constructor. For example:

          import {Socket} from "phoenix"
          import {LiveSocket} from "phoenix_live_view"
          let liveSocket = new LiveSocket("/live", Socket, {...})
      `);
    }
    this.socket = new phxSocket(url, opts);
    this.bindingPrefix = opts.bindingPrefix || BINDING_PREFIX;
    this.opts = opts;
    this.params = closure2(opts.params || {});
    this.viewLogger = opts.viewLogger;
    this.metadataCallbacks = opts.metadata || {};
    this.defaults = Object.assign(clone(DEFAULTS), opts.defaults || {});
    this.prevActive = null;
    this.silenced = false;
    this.main = null;
    this.outgoingMainEl = null;
    this.clickStartedAtTarget = null;
    this.linkRef = 1;
    this.roots = {};
    this.href = window.location.href;
    this.pendingLink = null;
    this.currentLocation = clone(window.location);
    this.hooks = opts.hooks || {};
    this.uploaders = opts.uploaders || {};
    this.loaderTimeout = opts.loaderTimeout || LOADER_TIMEOUT;
    this.disconnectedTimeout = opts.disconnectedTimeout || DISCONNECTED_TIMEOUT;
    this.reloadWithJitterTimer = null;
    this.maxReloads = opts.maxReloads || MAX_RELOADS;
    this.reloadJitterMin = opts.reloadJitterMin || RELOAD_JITTER_MIN;
    this.reloadJitterMax = opts.reloadJitterMax || RELOAD_JITTER_MAX;
    this.failsafeJitter = opts.failsafeJitter || FAILSAFE_JITTER;
    this.localStorage = opts.localStorage || window.localStorage;
    this.sessionStorage = opts.sessionStorage || window.sessionStorage;
    this.boundTopLevelEvents = false;
    this.boundEventNames = /* @__PURE__ */ new Set();
    this.blockPhxChangeWhileComposing = opts.blockPhxChangeWhileComposing || false;
    this.serverCloseRef = null;
    this.domCallbacks = Object.assign(
      {
        jsQuerySelectorAll: null,
        onPatchStart: closure2(),
        onPatchEnd: closure2(),
        onNodeAdded: closure2(),
        onBeforeElUpdated: closure2()
      },
      opts.dom || {}
    );
    this.transitions = new TransitionSet();
    this.currentHistoryPosition = parseInt(this.sessionStorage.getItem(PHX_LV_HISTORY_POSITION)) || 0;
    window.addEventListener("pagehide", (_e) => {
      this.unloaded = true;
    });
    this.socket.onOpen(() => {
      if (this.isUnloaded()) {
        window.location.reload();
      }
    });
  }
  // public
  version() {
    return "1.1.8";
  }
  isProfileEnabled() {
    return this.sessionStorage.getItem(PHX_LV_PROFILE) === "true";
  }
  isDebugEnabled() {
    return this.sessionStorage.getItem(PHX_LV_DEBUG) === "true";
  }
  isDebugDisabled() {
    return this.sessionStorage.getItem(PHX_LV_DEBUG) === "false";
  }
  enableDebug() {
    this.sessionStorage.setItem(PHX_LV_DEBUG, "true");
  }
  enableProfiling() {
    this.sessionStorage.setItem(PHX_LV_PROFILE, "true");
  }
  disableDebug() {
    this.sessionStorage.setItem(PHX_LV_DEBUG, "false");
  }
  disableProfiling() {
    this.sessionStorage.removeItem(PHX_LV_PROFILE);
  }
  enableLatencySim(upperBoundMs) {
    this.enableDebug();
    console.log(
      "latency simulator enabled for the duration of this browser session. Call disableLatencySim() to disable"
    );
    this.sessionStorage.setItem(PHX_LV_LATENCY_SIM, upperBoundMs);
  }
  disableLatencySim() {
    this.sessionStorage.removeItem(PHX_LV_LATENCY_SIM);
  }
  getLatencySim() {
    const str = this.sessionStorage.getItem(PHX_LV_LATENCY_SIM);
    return str ? parseInt(str) : null;
  }
  getSocket() {
    return this.socket;
  }
  connect() {
    if (window.location.hostname === "localhost" && !this.isDebugDisabled()) {
      this.enableDebug();
    }
    const doConnect = () => {
      this.resetReloadStatus();
      if (this.joinRootViews()) {
        this.bindTopLevelEvents();
        this.socket.connect();
      } else if (this.main) {
        this.socket.connect();
      } else {
        this.bindTopLevelEvents({ dead: true });
      }
      this.joinDeadView();
    };
    if (["complete", "loaded", "interactive"].indexOf(document.readyState) >= 0) {
      doConnect();
    } else {
      document.addEventListener("DOMContentLoaded", () => doConnect());
    }
  }
  disconnect(callback) {
    clearTimeout(this.reloadWithJitterTimer);
    if (this.serverCloseRef) {
      this.socket.off(this.serverCloseRef);
      this.serverCloseRef = null;
    }
    this.socket.disconnect(callback);
  }
  replaceTransport(transport) {
    clearTimeout(this.reloadWithJitterTimer);
    this.socket.replaceTransport(transport);
    this.connect();
  }
  execJS(el, encodedJS, eventType = null) {
    const e = new CustomEvent("phx:exec", { detail: { sourceElement: el } });
    this.owner(el, (view) => js_default.exec(e, eventType, encodedJS, view, el));
  }
  /**
   * Returns an object with methods to manipluate the DOM and execute JavaScript.
   * The applied changes integrate with server DOM patching.
   *
   * @returns {import("./js_commands").LiveSocketJSCommands}
   */
  js() {
    return js_commands_default(this, "js");
  }
  // private
  unload() {
    if (this.unloaded) {
      return;
    }
    if (this.main && this.isConnected()) {
      this.log(this.main, "socket", () => ["disconnect for page nav"]);
    }
    this.unloaded = true;
    this.destroyAllViews();
    this.disconnect();
  }
  triggerDOM(kind, args) {
    this.domCallbacks[kind](...args);
  }
  time(name, func) {
    if (!this.isProfileEnabled() || !console.time) {
      return func();
    }
    console.time(name);
    const result = func();
    console.timeEnd(name);
    return result;
  }
  log(view, kind, msgCallback) {
    if (this.viewLogger) {
      const [msg, obj] = msgCallback();
      this.viewLogger(view, kind, msg, obj);
    } else if (this.isDebugEnabled()) {
      const [msg, obj] = msgCallback();
      debug(view, kind, msg, obj);
    }
  }
  requestDOMUpdate(callback) {
    this.transitions.after(callback);
  }
  asyncTransition(promise) {
    this.transitions.addAsyncTransition(promise);
  }
  transition(time, onStart, onDone = function() {
  }) {
    this.transitions.addTransition(time, onStart, onDone);
  }
  onChannel(channel, event, cb) {
    channel.on(event, (data) => {
      const latency = this.getLatencySim();
      if (!latency) {
        cb(data);
      } else {
        setTimeout(() => cb(data), latency);
      }
    });
  }
  reloadWithJitter(view, log) {
    clearTimeout(this.reloadWithJitterTimer);
    this.disconnect();
    const minMs = this.reloadJitterMin;
    const maxMs = this.reloadJitterMax;
    let afterMs = Math.floor(Math.random() * (maxMs - minMs + 1)) + minMs;
    const tries = browser_default.updateLocal(
      this.localStorage,
      window.location.pathname,
      CONSECUTIVE_RELOADS,
      0,
      (count) => count + 1
    );
    if (tries >= this.maxReloads) {
      afterMs = this.failsafeJitter;
    }
    this.reloadWithJitterTimer = setTimeout(() => {
      if (view.isDestroyed() || view.isConnected()) {
        return;
      }
      view.destroy();
      log ? log() : this.log(view, "join", () => [
        `encountered ${tries} consecutive reloads`
      ]);
      if (tries >= this.maxReloads) {
        this.log(view, "join", () => [
          `exceeded ${this.maxReloads} consecutive reloads. Entering failsafe mode`
        ]);
      }
      if (this.hasPendingLink()) {
        window.location = this.pendingLink;
      } else {
        window.location.reload();
      }
    }, afterMs);
  }
  getHookDefinition(name) {
    if (!name) {
      return;
    }
    return this.maybeInternalHook(name) || this.hooks[name] || this.maybeRuntimeHook(name);
  }
  maybeInternalHook(name) {
    return name && name.startsWith("Phoenix.") && hooks_default[name.split(".")[1]];
  }
  maybeRuntimeHook(name) {
    const runtimeHook = document.querySelector(
      `script[${PHX_RUNTIME_HOOK}="${CSS.escape(name)}"]`
    );
    if (!runtimeHook) {
      return;
    }
    let callbacks = window[`phx_hook_${name}`];
    if (!callbacks || typeof callbacks !== "function") {
      logError("a runtime hook must be a function", runtimeHook);
      return;
    }
    const hookDefiniton = callbacks();
    if (hookDefiniton && (typeof hookDefiniton === "object" || typeof hookDefiniton === "function")) {
      return hookDefiniton;
    }
    logError(
      "runtime hook must return an object with hook callbacks or an instance of ViewHook",
      runtimeHook
    );
  }
  isUnloaded() {
    return this.unloaded;
  }
  isConnected() {
    return this.socket.isConnected();
  }
  getBindingPrefix() {
    return this.bindingPrefix;
  }
  binding(kind) {
    return `${this.getBindingPrefix()}${kind}`;
  }
  channel(topic, params) {
    return this.socket.channel(topic, params);
  }
  joinDeadView() {
    const body = document.body;
    if (body && !this.isPhxView(body) && !this.isPhxView(document.firstElementChild)) {
      const view = this.newRootView(body);
      view.setHref(this.getHref());
      view.joinDead();
      if (!this.main) {
        this.main = view;
      }
      window.requestAnimationFrame(() => {
        view.execNewMounted();
        this.maybeScroll(history.state?.scroll);
      });
    }
  }
  joinRootViews() {
    let rootsFound = false;
    dom_default.all(
      document,
      `${PHX_VIEW_SELECTOR}:not([${PHX_PARENT_ID}])`,
      (rootEl) => {
        if (!this.getRootById(rootEl.id)) {
          const view = this.newRootView(rootEl);
          if (!dom_default.isPhxSticky(rootEl)) {
            view.setHref(this.getHref());
          }
          view.join();
          if (rootEl.hasAttribute(PHX_MAIN)) {
            this.main = view;
          }
        }
        rootsFound = true;
      }
    );
    return rootsFound;
  }
  redirect(to, flash, reloadToken) {
    if (reloadToken) {
      browser_default.setCookie(PHX_RELOAD_STATUS, reloadToken, 60);
    }
    this.unload();
    browser_default.redirect(to, flash);
  }
  replaceMain(href, flash, callback = null, linkRef = this.setPendingLink(href)) {
    const liveReferer = this.currentLocation.href;
    this.outgoingMainEl = this.outgoingMainEl || this.main.el;
    const stickies = dom_default.findPhxSticky(document) || [];
    const removeEls = dom_default.all(
      this.outgoingMainEl,
      `[${this.binding("remove")}]`
    ).filter((el) => !dom_default.isChildOfAny(el, stickies));
    const newMainEl = dom_default.cloneNode(this.outgoingMainEl, "");
    this.main.showLoader(this.loaderTimeout);
    this.main.destroy();
    this.main = this.newRootView(newMainEl, flash, liveReferer);
    this.main.setRedirect(href);
    this.transitionRemoves(removeEls);
    this.main.join((joinCount, onDone) => {
      if (joinCount === 1 && this.commitPendingLink(linkRef)) {
        this.requestDOMUpdate(() => {
          removeEls.forEach((el) => el.remove());
          stickies.forEach((el) => newMainEl.appendChild(el));
          this.outgoingMainEl.replaceWith(newMainEl);
          this.outgoingMainEl = null;
          callback && callback(linkRef);
          onDone();
        });
      }
    });
  }
  transitionRemoves(elements, callback) {
    const removeAttr = this.binding("remove");
    const silenceEvents = (e) => {
      e.preventDefault();
      e.stopImmediatePropagation();
    };
    elements.forEach((el) => {
      for (const event of this.boundEventNames) {
        el.addEventListener(event, silenceEvents, true);
      }
      this.execJS(el, el.getAttribute(removeAttr), "remove");
    });
    this.requestDOMUpdate(() => {
      elements.forEach((el) => {
        for (const event of this.boundEventNames) {
          el.removeEventListener(event, silenceEvents, true);
        }
      });
      callback && callback();
    });
  }
  isPhxView(el) {
    return el.getAttribute && el.getAttribute(PHX_SESSION) !== null;
  }
  newRootView(el, flash, liveReferer) {
    const view = new View(el, this, null, flash, liveReferer);
    this.roots[view.id] = view;
    return view;
  }
  owner(childEl, callback) {
    let view;
    const viewEl = dom_default.closestViewEl(childEl);
    if (viewEl) {
      view = this.getViewByEl(viewEl);
    } else {
      view = this.main;
    }
    return view && callback ? callback(view) : view;
  }
  withinOwners(childEl, callback) {
    this.owner(childEl, (view) => callback(view, childEl));
  }
  getViewByEl(el) {
    const rootId = el.getAttribute(PHX_ROOT_ID);
    return maybe(
      this.getRootById(rootId),
      (root) => root.getDescendentByEl(el)
    );
  }
  getRootById(id) {
    return this.roots[id];
  }
  destroyAllViews() {
    for (const id in this.roots) {
      this.roots[id].destroy();
      delete this.roots[id];
    }
    this.main = null;
  }
  destroyViewByEl(el) {
    const root = this.getRootById(el.getAttribute(PHX_ROOT_ID));
    if (root && root.id === el.id) {
      root.destroy();
      delete this.roots[root.id];
    } else if (root) {
      root.destroyDescendent(el.id);
    }
  }
  getActiveElement() {
    return document.activeElement;
  }
  dropActiveElement(view) {
    if (this.prevActive && view.ownsElement(this.prevActive)) {
      this.prevActive = null;
    }
  }
  restorePreviouslyActiveFocus() {
    if (this.prevActive && this.prevActive !== document.body && this.prevActive instanceof HTMLElement) {
      this.prevActive.focus();
    }
  }
  blurActiveElement() {
    this.prevActive = this.getActiveElement();
    if (this.prevActive !== document.body && this.prevActive instanceof HTMLElement) {
      this.prevActive.blur();
    }
  }
  /**
   * @param {{dead?: boolean}} [options={}]
   */
  bindTopLevelEvents({ dead } = {}) {
    if (this.boundTopLevelEvents) {
      return;
    }
    this.boundTopLevelEvents = true;
    this.serverCloseRef = this.socket.onClose((event) => {
      if (event && event.code === 1e3 && this.main) {
        return this.reloadWithJitter(this.main);
      }
    });
    document.body.addEventListener("click", function() {
    });
    window.addEventListener(
      "pageshow",
      (e) => {
        if (e.persisted) {
          this.getSocket().disconnect();
          this.withPageLoading({ to: window.location.href, kind: "redirect" });
          window.location.reload();
        }
      },
      true
    );
    if (!dead) {
      this.bindNav();
    }
    this.bindClicks();
    if (!dead) {
      this.bindForms();
    }
    this.bind(
      { keyup: "keyup", keydown: "keydown" },
      (e, type, view, targetEl, phxEvent, _phxTarget) => {
        const matchKey = targetEl.getAttribute(this.binding(PHX_KEY));
        const pressedKey = e.key && e.key.toLowerCase();
        if (matchKey && matchKey.toLowerCase() !== pressedKey) {
          return;
        }
        const data = { key: e.key, ...this.eventMeta(type, e, targetEl) };
        js_default.exec(e, type, phxEvent, view, targetEl, ["push", { data }]);
      }
    );
    this.bind(
      { blur: "focusout", focus: "focusin" },
      (e, type, view, targetEl, phxEvent, phxTarget) => {
        if (!phxTarget) {
          const data = { key: e.key, ...this.eventMeta(type, e, targetEl) };
          js_default.exec(e, type, phxEvent, view, targetEl, ["push", { data }]);
        }
      }
    );
    this.bind(
      { blur: "blur", focus: "focus" },
      (e, type, view, targetEl, phxEvent, phxTarget) => {
        if (phxTarget === "window") {
          const data = this.eventMeta(type, e, targetEl);
          js_default.exec(e, type, phxEvent, view, targetEl, ["push", { data }]);
        }
      }
    );
    this.on("dragover", (e) => e.preventDefault());
    this.on("drop", (e) => {
      e.preventDefault();
      const dropTargetId = maybe(
        closestPhxBinding(e.target, this.binding(PHX_DROP_TARGET)),
        (trueTarget) => {
          return trueTarget.getAttribute(this.binding(PHX_DROP_TARGET));
        }
      );
      const dropTarget = dropTargetId && document.getElementById(dropTargetId);
      const files = Array.from(e.dataTransfer.files || []);
      if (!dropTarget || !(dropTarget instanceof HTMLInputElement) || dropTarget.disabled || files.length === 0 || !(dropTarget.files instanceof FileList)) {
        return;
      }
      LiveUploader.trackFiles(dropTarget, files, e.dataTransfer);
      dropTarget.dispatchEvent(new Event("input", { bubbles: true }));
    });
    this.on(PHX_TRACK_UPLOADS, (e) => {
      const uploadTarget = e.target;
      if (!dom_default.isUploadInput(uploadTarget)) {
        return;
      }
      const files = Array.from(e.detail.files || []).filter(
        (f) => f instanceof File || f instanceof Blob
      );
      LiveUploader.trackFiles(uploadTarget, files);
      uploadTarget.dispatchEvent(new Event("input", { bubbles: true }));
    });
  }
  eventMeta(eventName, e, targetEl) {
    const callback = this.metadataCallbacks[eventName];
    return callback ? callback(e, targetEl) : {};
  }
  setPendingLink(href) {
    this.linkRef++;
    this.pendingLink = href;
    this.resetReloadStatus();
    return this.linkRef;
  }
  // anytime we are navigating or connecting, drop reload cookie in case
  // we issue the cookie but the next request was interrupted and the server never dropped it
  resetReloadStatus() {
    browser_default.deleteCookie(PHX_RELOAD_STATUS);
  }
  commitPendingLink(linkRef) {
    if (this.linkRef !== linkRef) {
      return false;
    } else {
      this.href = this.pendingLink;
      this.pendingLink = null;
      return true;
    }
  }
  getHref() {
    return this.href;
  }
  hasPendingLink() {
    return !!this.pendingLink;
  }
  bind(events, callback) {
    for (const event in events) {
      const browserEventName = events[event];
      this.on(browserEventName, (e) => {
        const binding = this.binding(event);
        const windowBinding = this.binding(`window-${event}`);
        const targetPhxEvent = e.target.getAttribute && e.target.getAttribute(binding);
        if (targetPhxEvent) {
          this.debounce(e.target, e, browserEventName, () => {
            this.withinOwners(e.target, (view) => {
              callback(e, event, view, e.target, targetPhxEvent, null);
            });
          });
        } else {
          dom_default.all(document, `[${windowBinding}]`, (el) => {
            const phxEvent = el.getAttribute(windowBinding);
            this.debounce(el, e, browserEventName, () => {
              this.withinOwners(el, (view) => {
                callback(e, event, view, el, phxEvent, "window");
              });
            });
          });
        }
      });
    }
  }
  bindClicks() {
    this.on("mousedown", (e) => this.clickStartedAtTarget = e.target);
    this.bindClick("click", "click");
  }
  bindClick(eventName, bindingName) {
    const click = this.binding(bindingName);
    window.addEventListener(
      eventName,
      (e) => {
        let target = null;
        if (e.detail === 0)
          this.clickStartedAtTarget = e.target;
        const clickStartedAtTarget = this.clickStartedAtTarget || e.target;
        target = closestPhxBinding(e.target, click);
        this.dispatchClickAway(e, clickStartedAtTarget);
        this.clickStartedAtTarget = null;
        const phxEvent = target && target.getAttribute(click);
        if (!phxEvent) {
          if (dom_default.isNewPageClick(e, window.location)) {
            this.unload();
          }
          return;
        }
        if (target.getAttribute("href") === "#") {
          e.preventDefault();
        }
        if (target.hasAttribute(PHX_REF_SRC)) {
          return;
        }
        this.debounce(target, e, "click", () => {
          this.withinOwners(target, (view) => {
            js_default.exec(e, "click", phxEvent, view, target, [
              "push",
              { data: this.eventMeta("click", e, target) }
            ]);
          });
        });
      },
      false
    );
  }
  dispatchClickAway(e, clickStartedAt) {
    const phxClickAway = this.binding("click-away");
    dom_default.all(document, `[${phxClickAway}]`, (el) => {
      if (!(el.isSameNode(clickStartedAt) || el.contains(clickStartedAt))) {
        this.withinOwners(el, (view) => {
          const phxEvent = el.getAttribute(phxClickAway);
          if (js_default.isVisible(el) && js_default.isInViewport(el)) {
            js_default.exec(e, "click", phxEvent, view, el, [
              "push",
              { data: this.eventMeta("click", e, e.target) }
            ]);
          }
        });
      }
    });
  }
  bindNav() {
    if (!browser_default.canPushState()) {
      return;
    }
    if (history.scrollRestoration) {
      history.scrollRestoration = "manual";
    }
    let scrollTimer = null;
    window.addEventListener("scroll", (_e) => {
      clearTimeout(scrollTimer);
      scrollTimer = setTimeout(() => {
        browser_default.updateCurrentState(
          (state) => Object.assign(state, { scroll: window.scrollY })
        );
      }, 100);
    });
    window.addEventListener(
      "popstate",
      (event) => {
        if (!this.registerNewLocation(window.location)) {
          return;
        }
        const { type, backType, id, scroll, position } = event.state || {};
        const href = window.location.href;
        const isForward = position > this.currentHistoryPosition;
        const navType = isForward ? type : backType || type;
        this.currentHistoryPosition = position || 0;
        this.sessionStorage.setItem(
          PHX_LV_HISTORY_POSITION,
          this.currentHistoryPosition.toString()
        );
        dom_default.dispatchEvent(window, "phx:navigate", {
          detail: {
            href,
            patch: navType === "patch",
            pop: true,
            direction: isForward ? "forward" : "backward"
          }
        });
        this.requestDOMUpdate(() => {
          const callback = () => {
            this.maybeScroll(scroll);
          };
          if (this.main.isConnected() && navType === "patch" && id === this.main.id) {
            this.main.pushLinkPatch(event, href, null, callback);
          } else {
            this.replaceMain(href, null, callback);
          }
        });
      },
      false
    );
    window.addEventListener(
      "click",
      (e) => {
        const target = closestPhxBinding(e.target, PHX_LIVE_LINK);
        const type = target && target.getAttribute(PHX_LIVE_LINK);
        if (!type || !this.isConnected() || !this.main || dom_default.wantsNewTab(e)) {
          return;
        }
        const href = target.href instanceof SVGAnimatedString ? target.href.baseVal : target.href;
        const linkState = target.getAttribute(PHX_LINK_STATE);
        e.preventDefault();
        e.stopImmediatePropagation();
        if (this.pendingLink === href) {
          return;
        }
        this.requestDOMUpdate(() => {
          if (type === "patch") {
            this.pushHistoryPatch(e, href, linkState, target);
          } else if (type === "redirect") {
            this.historyRedirect(e, href, linkState, null, target);
          } else {
            throw new Error(
              `expected ${PHX_LIVE_LINK} to be "patch" or "redirect", got: ${type}`
            );
          }
          const phxClick = target.getAttribute(this.binding("click"));
          if (phxClick) {
            this.requestDOMUpdate(() => this.execJS(target, phxClick, "click"));
          }
        });
      },
      false
    );
  }
  maybeScroll(scroll) {
    if (typeof scroll === "number") {
      requestAnimationFrame(() => {
        window.scrollTo(0, scroll);
      });
    }
  }
  dispatchEvent(event, payload = {}) {
    dom_default.dispatchEvent(window, `phx:${event}`, { detail: payload });
  }
  dispatchEvents(events) {
    events.forEach(([event, payload]) => this.dispatchEvent(event, payload));
  }
  withPageLoading(info, callback) {
    dom_default.dispatchEvent(window, "phx:page-loading-start", { detail: info });
    const done = () => dom_default.dispatchEvent(window, "phx:page-loading-stop", { detail: info });
    return callback ? callback(done) : done;
  }
  pushHistoryPatch(e, href, linkState, targetEl) {
    if (!this.isConnected() || !this.main.isMain()) {
      return browser_default.redirect(href);
    }
    this.withPageLoading({ to: href, kind: "patch" }, (done) => {
      this.main.pushLinkPatch(e, href, targetEl, (linkRef) => {
        this.historyPatch(href, linkState, linkRef);
        done();
      });
    });
  }
  historyPatch(href, linkState, linkRef = this.setPendingLink(href)) {
    if (!this.commitPendingLink(linkRef)) {
      return;
    }
    this.currentHistoryPosition++;
    this.sessionStorage.setItem(
      PHX_LV_HISTORY_POSITION,
      this.currentHistoryPosition.toString()
    );
    browser_default.updateCurrentState((state) => ({ ...state, backType: "patch" }));
    browser_default.pushState(
      linkState,
      {
        type: "patch",
        id: this.main.id,
        position: this.currentHistoryPosition
      },
      href
    );
    dom_default.dispatchEvent(window, "phx:navigate", {
      detail: { patch: true, href, pop: false, direction: "forward" }
    });
    this.registerNewLocation(window.location);
  }
  historyRedirect(e, href, linkState, flash, targetEl) {
    const clickLoading = targetEl && e.isTrusted && e.type !== "popstate";
    if (clickLoading) {
      targetEl.classList.add("phx-click-loading");
    }
    if (!this.isConnected() || !this.main.isMain()) {
      return browser_default.redirect(href, flash);
    }
    if (/^\/$|^\/[^\/]+.*$/.test(href)) {
      const { protocol, host } = window.location;
      href = `${protocol}//${host}${href}`;
    }
    const scroll = window.scrollY;
    this.withPageLoading({ to: href, kind: "redirect" }, (done) => {
      this.replaceMain(href, flash, (linkRef) => {
        if (linkRef === this.linkRef) {
          this.currentHistoryPosition++;
          this.sessionStorage.setItem(
            PHX_LV_HISTORY_POSITION,
            this.currentHistoryPosition.toString()
          );
          browser_default.updateCurrentState((state) => ({
            ...state,
            backType: "redirect"
          }));
          browser_default.pushState(
            linkState,
            {
              type: "redirect",
              id: this.main.id,
              scroll,
              position: this.currentHistoryPosition
            },
            href
          );
          dom_default.dispatchEvent(window, "phx:navigate", {
            detail: { href, patch: false, pop: false, direction: "forward" }
          });
          this.registerNewLocation(window.location);
        }
        if (clickLoading) {
          targetEl.classList.remove("phx-click-loading");
        }
        done();
      });
    });
  }
  registerNewLocation(newLocation) {
    const { pathname, search } = this.currentLocation;
    if (pathname + search === newLocation.pathname + newLocation.search) {
      return false;
    } else {
      this.currentLocation = clone(newLocation);
      return true;
    }
  }
  bindForms() {
    let iterations = 0;
    let externalFormSubmitted = false;
    this.on("submit", (e) => {
      const phxSubmit = e.target.getAttribute(this.binding("submit"));
      const phxChange = e.target.getAttribute(this.binding("change"));
      if (!externalFormSubmitted && phxChange && !phxSubmit) {
        externalFormSubmitted = true;
        e.preventDefault();
        this.withinOwners(e.target, (view) => {
          view.disableForm(e.target);
          window.requestAnimationFrame(() => {
            if (dom_default.isUnloadableFormSubmit(e)) {
              this.unload();
            }
            e.target.submit();
          });
        });
      }
    });
    this.on("submit", (e) => {
      const phxEvent = e.target.getAttribute(this.binding("submit"));
      if (!phxEvent) {
        if (dom_default.isUnloadableFormSubmit(e)) {
          this.unload();
        }
        return;
      }
      e.preventDefault();
      e.target.disabled = true;
      this.withinOwners(e.target, (view) => {
        js_default.exec(e, "submit", phxEvent, view, e.target, [
          "push",
          { submitter: e.submitter }
        ]);
      });
    });
    for (const type of ["change", "input"]) {
      this.on(type, (e) => {
        if (e instanceof CustomEvent && (e.target instanceof HTMLInputElement || e.target instanceof HTMLSelectElement || e.target instanceof HTMLTextAreaElement) && e.target.form === void 0) {
          if (e.detail && e.detail.dispatcher) {
            throw new Error(
              `dispatching a custom ${type} event is only supported on input elements inside a form`
            );
          }
          return;
        }
        const phxChange = this.binding("change");
        const input = e.target;
        if (this.blockPhxChangeWhileComposing && e.isComposing) {
          const key = `composition-listener-${type}`;
          if (!dom_default.private(input, key)) {
            dom_default.putPrivate(input, key, true);
            input.addEventListener(
              "compositionend",
              () => {
                input.dispatchEvent(new Event(type, { bubbles: true }));
                dom_default.deletePrivate(input, key);
              },
              { once: true }
            );
          }
          return;
        }
        const inputEvent = input.getAttribute(phxChange);
        const formEvent = input.form && input.form.getAttribute(phxChange);
        const phxEvent = inputEvent || formEvent;
        if (!phxEvent) {
          return;
        }
        if (input.type === "number" && input.validity && input.validity.badInput) {
          return;
        }
        const dispatcher = inputEvent ? input : input.form;
        const currentIterations = iterations;
        iterations++;
        const { at, type: lastType } = dom_default.private(input, "prev-iteration") || {};
        if (at === currentIterations - 1 && type === "change" && lastType === "input") {
          return;
        }
        dom_default.putPrivate(input, "prev-iteration", {
          at: currentIterations,
          type
        });
        this.debounce(input, e, type, () => {
          this.withinOwners(dispatcher, (view) => {
            dom_default.putPrivate(input, PHX_HAS_FOCUSED, true);
            js_default.exec(e, "change", phxEvent, view, input, [
              "push",
              { _target: e.target.name, dispatcher }
            ]);
          });
        });
      });
    }
    this.on("reset", (e) => {
      const form = e.target;
      dom_default.resetForm(form);
      const input = Array.from(form.elements).find((el) => el.type === "reset");
      if (input) {
        window.requestAnimationFrame(() => {
          input.dispatchEvent(
            new Event("input", { bubbles: true, cancelable: false })
          );
        });
      }
    });
  }
  debounce(el, event, eventType, callback) {
    if (eventType === "blur" || eventType === "focusout") {
      return callback();
    }
    const phxDebounce = this.binding(PHX_DEBOUNCE);
    const phxThrottle = this.binding(PHX_THROTTLE);
    const defaultDebounce = this.defaults.debounce.toString();
    const defaultThrottle = this.defaults.throttle.toString();
    this.withinOwners(el, (view) => {
      const asyncFilter = () => !view.isDestroyed() && document.body.contains(el);
      dom_default.debounce(
        el,
        event,
        phxDebounce,
        defaultDebounce,
        phxThrottle,
        defaultThrottle,
        asyncFilter,
        () => {
          callback();
        }
      );
    });
  }
  silenceEvents(callback) {
    this.silenced = true;
    callback();
    this.silenced = false;
  }
  on(event, callback) {
    this.boundEventNames.add(event);
    window.addEventListener(event, (e) => {
      if (!this.silenced) {
        callback(e);
      }
    });
  }
  jsQuerySelectorAll(sourceEl, query, defaultQuery) {
    const all = this.domCallbacks.jsQuerySelectorAll;
    return all ? all(sourceEl, query, defaultQuery) : defaultQuery();
  }
};
var TransitionSet = class {
  constructor() {
    this.transitions = /* @__PURE__ */ new Set();
    this.promises = /* @__PURE__ */ new Set();
    this.pendingOps = [];
  }
  reset() {
    this.transitions.forEach((timer) => {
      clearTimeout(timer);
      this.transitions.delete(timer);
    });
    this.promises.clear();
    this.flushPendingOps();
  }
  after(callback) {
    if (this.size() === 0) {
      callback();
    } else {
      this.pushPendingOp(callback);
    }
  }
  addTransition(time, onStart, onDone) {
    onStart();
    const timer = setTimeout(() => {
      this.transitions.delete(timer);
      onDone();
      this.flushPendingOps();
    }, time);
    this.transitions.add(timer);
  }
  addAsyncTransition(promise) {
    this.promises.add(promise);
    promise.then(() => {
      this.promises.delete(promise);
      this.flushPendingOps();
    });
  }
  pushPendingOp(op) {
    this.pendingOps.push(op);
  }
  size() {
    return this.transitions.size + this.promises.size;
  }
  flushPendingOps() {
    if (this.size() > 0) {
      return;
    }
    const op = this.pendingOps.shift();
    if (op) {
      op();
      this.flushPendingOps();
    }
  }
};
var LiveSocket2 = LiveSocket;

// assets/js/app.js
var ThemeToggle = {
  mounted() {
    this.initializeTheme();
    this.handleEvent("toggle_theme", ({ dark }) => {
      this.setTheme(dark ? "dark" : "light");
    });
  },
  initializeTheme() {
    const theme = localStorage.theme === "dark" || !("theme" in localStorage) && window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
    this.applyTheme(theme === "dark");
  },
  setTheme(theme) {
    localStorage.theme = theme;
    this.applyTheme(theme === "dark");
  },
  applyTheme(isDark) {
    if (isDark) {
      document.documentElement.setAttribute("data-theme", "dark");
    } else {
      document.documentElement.removeAttribute("data-theme");
    }
  }
};
var hooks = { ThemeToggle };
try {
  const colocatedHooks = await import("phoenix-colocated/pulsar");
  hooks = { ...hooks, ...colocatedHooks.hooks };
} catch (e) {
}
var csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");
var liveSocket = new LiveSocket2("/live", Socket, {
  longPollFallbackMs: 2500,
  params: { _csrf_token: csrfToken },
  hooks
});
liveSocket.connect();
window.liveSocket = liveSocket;
//# sourceMappingURL=data:application/json;base64,ewogICJ2ZXJzaW9uIjogMywKICAic291cmNlcyI6IFsiLi4vLi4vLi4vZGVwcy9waG9lbml4X2h0bWwvcHJpdi9zdGF0aWMvcGhvZW5peF9odG1sLmpzIiwgIi4uLy4uLy4uL2RlcHMvcGhvZW5peC9hc3NldHMvanMvcGhvZW5peC91dGlscy5qcyIsICIuLi8uLi8uLi9kZXBzL3Bob2VuaXgvYXNzZXRzL2pzL3Bob2VuaXgvY29uc3RhbnRzLmpzIiwgIi4uLy4uLy4uL2RlcHMvcGhvZW5peC9hc3NldHMvanMvcGhvZW5peC9wdXNoLmpzIiwgIi4uLy4uLy4uL2RlcHMvcGhvZW5peC9hc3NldHMvanMvcGhvZW5peC90aW1lci5qcyIsICIuLi8uLi8uLi9kZXBzL3Bob2VuaXgvYXNzZXRzL2pzL3Bob2VuaXgvY2hhbm5lbC5qcyIsICIuLi8uLi8uLi9kZXBzL3Bob2VuaXgvYXNzZXRzL2pzL3Bob2VuaXgvYWpheC5qcyIsICIuLi8uLi8uLi9kZXBzL3Bob2VuaXgvYXNzZXRzL2pzL3Bob2VuaXgvbG9uZ3BvbGwuanMiLCAiLi4vLi4vLi4vZGVwcy9waG9lbml4L2Fzc2V0cy9qcy9waG9lbml4L3ByZXNlbmNlLmpzIiwgIi4uLy4uLy4uL2RlcHMvcGhvZW5peC9hc3NldHMvanMvcGhvZW5peC9zZXJpYWxpemVyLmpzIiwgIi4uLy4uLy4uL2RlcHMvcGhvZW5peC9hc3NldHMvanMvcGhvZW5peC9zb2NrZXQuanMiLCAiLi4vLi4vLi4vZGVwcy9waG9lbml4X2xpdmVfdmlldy9hc3NldHMvanMvcGhvZW5peF9saXZlX3ZpZXcvY29uc3RhbnRzLmpzIiwgIi4uLy4uLy4uL2RlcHMvcGhvZW5peF9saXZlX3ZpZXcvYXNzZXRzL2pzL3Bob2VuaXhfbGl2ZV92aWV3L2VudHJ5X3VwbG9hZGVyLmpzIiwgIi4uLy4uLy4uL2RlcHMvcGhvZW5peF9saXZlX3ZpZXcvYXNzZXRzL2pzL3Bob2VuaXhfbGl2ZV92aWV3L3V0aWxzLmpzIiwgIi4uLy4uLy4uL2RlcHMvcGhvZW5peF9saXZlX3ZpZXcvYXNzZXRzL2pzL3Bob2VuaXhfbGl2ZV92aWV3L2Jyb3dzZXIuanMiLCAiLi4vLi4vLi4vZGVwcy9waG9lbml4X2xpdmVfdmlldy9hc3NldHMvanMvcGhvZW5peF9saXZlX3ZpZXcvZG9tLmpzIiwgIi4uLy4uLy4uL2RlcHMvcGhvZW5peF9saXZlX3ZpZXcvYXNzZXRzL2pzL3Bob2VuaXhfbGl2ZV92aWV3L3VwbG9hZF9lbnRyeS5qcyIsICIuLi8uLi8uLi9kZXBzL3Bob2VuaXhfbGl2ZV92aWV3L2Fzc2V0cy9qcy9waG9lbml4X2xpdmVfdmlldy9saXZlX3VwbG9hZGVyLmpzIiwgIi4uLy4uLy4uL2RlcHMvcGhvZW5peF9saXZlX3ZpZXcvYXNzZXRzL2pzL3Bob2VuaXhfbGl2ZV92aWV3L2FyaWEuanMiLCAiLi4vLi4vLi4vZGVwcy9waG9lbml4X2xpdmVfdmlldy9hc3NldHMvanMvcGhvZW5peF9saXZlX3ZpZXcvaG9va3MuanMiLCAiLi4vLi4vLi4vZGVwcy9waG9lbml4X2xpdmVfdmlldy9hc3NldHMvanMvcGhvZW5peF9saXZlX3ZpZXcvZWxlbWVudF9yZWYuanMiLCAiLi4vLi4vLi4vZGVwcy9waG9lbml4X2xpdmVfdmlldy9hc3NldHMvanMvcGhvZW5peF9saXZlX3ZpZXcvZG9tX3Bvc3RfbW9ycGhfcmVzdG9yZXIuanMiLCAiLi4vLi4vLi4vZGVwcy9waG9lbml4X2xpdmVfdmlldy9ub2RlX21vZHVsZXMvbW9ycGhkb20vZGlzdC9tb3JwaGRvbS1lc20uanMiLCAiLi4vLi4vLi4vZGVwcy9waG9lbml4X2xpdmVfdmlldy9hc3NldHMvanMvcGhvZW5peF9saXZlX3ZpZXcvZG9tX3BhdGNoLmpzIiwgIi4uLy4uLy4uL2RlcHMvcGhvZW5peF9saXZlX3ZpZXcvYXNzZXRzL2pzL3Bob2VuaXhfbGl2ZV92aWV3L3JlbmRlcmVkLmpzIiwgIi4uLy4uLy4uL2RlcHMvcGhvZW5peF9saXZlX3ZpZXcvYXNzZXRzL2pzL3Bob2VuaXhfbGl2ZV92aWV3L2pzLmpzIiwgIi4uLy4uLy4uL2RlcHMvcGhvZW5peF9saXZlX3ZpZXcvYXNzZXRzL2pzL3Bob2VuaXhfbGl2ZV92aWV3L2pzX2NvbW1hbmRzLnRzIiwgIi4uLy4uLy4uL2RlcHMvcGhvZW5peF9saXZlX3ZpZXcvYXNzZXRzL2pzL3Bob2VuaXhfbGl2ZV92aWV3L3ZpZXdfaG9vay50cyIsICIuLi8uLi8uLi9kZXBzL3Bob2VuaXhfbGl2ZV92aWV3L2Fzc2V0cy9qcy9waG9lbml4X2xpdmVfdmlldy92aWV3LmpzIiwgIi4uLy4uLy4uL2RlcHMvcGhvZW5peF9saXZlX3ZpZXcvYXNzZXRzL2pzL3Bob2VuaXhfbGl2ZV92aWV3L2xpdmVfc29ja2V0LmpzIiwgIi4uLy4uLy4uL2RlcHMvcGhvZW5peF9saXZlX3ZpZXcvYXNzZXRzL2pzL3Bob2VuaXhfbGl2ZV92aWV3L2luZGV4LnRzIiwgIi4uLy4uLy4uL2Fzc2V0cy9qcy9hcHAuanMiXSwKICAic291cmNlc0NvbnRlbnQiOiBbIlwidXNlIHN0cmljdFwiO1xuXG4oZnVuY3Rpb24oKSB7XG4gIHZhciBQb2x5ZmlsbEV2ZW50ID0gZXZlbnRDb25zdHJ1Y3RvcigpO1xuXG4gIGZ1bmN0aW9uIGV2ZW50Q29uc3RydWN0b3IoKSB7XG4gICAgaWYgKHR5cGVvZiB3aW5kb3cuQ3VzdG9tRXZlbnQgPT09IFwiZnVuY3Rpb25cIikgcmV0dXJuIHdpbmRvdy5DdXN0b21FdmVudDtcbiAgICAvLyBJRTw9OSBTdXBwb3J0XG4gICAgZnVuY3Rpb24gQ3VzdG9tRXZlbnQoZXZlbnQsIHBhcmFtcykge1xuICAgICAgcGFyYW1zID0gcGFyYW1zIHx8IHtidWJibGVzOiBmYWxzZSwgY2FuY2VsYWJsZTogZmFsc2UsIGRldGFpbDogdW5kZWZpbmVkfTtcbiAgICAgIHZhciBldnQgPSBkb2N1bWVudC5jcmVhdGVFdmVudCgnQ3VzdG9tRXZlbnQnKTtcbiAgICAgIGV2dC5pbml0Q3VzdG9tRXZlbnQoZXZlbnQsIHBhcmFtcy5idWJibGVzLCBwYXJhbXMuY2FuY2VsYWJsZSwgcGFyYW1zLmRldGFpbCk7XG4gICAgICByZXR1cm4gZXZ0O1xuICAgIH1cbiAgICBDdXN0b21FdmVudC5wcm90b3R5cGUgPSB3aW5kb3cuRXZlbnQucHJvdG90eXBlO1xuICAgIHJldHVybiBDdXN0b21FdmVudDtcbiAgfVxuXG4gIGZ1bmN0aW9uIGJ1aWxkSGlkZGVuSW5wdXQobmFtZSwgdmFsdWUpIHtcbiAgICB2YXIgaW5wdXQgPSBkb2N1bWVudC5jcmVhdGVFbGVtZW50KFwiaW5wdXRcIik7XG4gICAgaW5wdXQudHlwZSA9IFwiaGlkZGVuXCI7XG4gICAgaW5wdXQubmFtZSA9IG5hbWU7XG4gICAgaW5wdXQudmFsdWUgPSB2YWx1ZTtcbiAgICByZXR1cm4gaW5wdXQ7XG4gIH1cblxuICBmdW5jdGlvbiBoYW5kbGVDbGljayhlbGVtZW50LCB0YXJnZXRNb2RpZmllcktleSkge1xuICAgIHZhciB0byA9IGVsZW1lbnQuZ2V0QXR0cmlidXRlKFwiZGF0YS10b1wiKSxcbiAgICAgICAgbWV0aG9kID0gYnVpbGRIaWRkZW5JbnB1dChcIl9tZXRob2RcIiwgZWxlbWVudC5nZXRBdHRyaWJ1dGUoXCJkYXRhLW1ldGhvZFwiKSksXG4gICAgICAgIGNzcmYgPSBidWlsZEhpZGRlbklucHV0KFwiX2NzcmZfdG9rZW5cIiwgZWxlbWVudC5nZXRBdHRyaWJ1dGUoXCJkYXRhLWNzcmZcIikpLFxuICAgICAgICBmb3JtID0gZG9jdW1lbnQuY3JlYXRlRWxlbWVudChcImZvcm1cIiksXG4gICAgICAgIHN1Ym1pdCA9IGRvY3VtZW50LmNyZWF0ZUVsZW1lbnQoXCJpbnB1dFwiKSxcbiAgICAgICAgdGFyZ2V0ID0gZWxlbWVudC5nZXRBdHRyaWJ1dGUoXCJ0YXJnZXRcIik7XG5cbiAgICBmb3JtLm1ldGhvZCA9IChlbGVtZW50LmdldEF0dHJpYnV0ZShcImRhdGEtbWV0aG9kXCIpID09PSBcImdldFwiKSA/IFwiZ2V0XCIgOiBcInBvc3RcIjtcbiAgICBmb3JtLmFjdGlvbiA9IHRvO1xuICAgIGZvcm0uc3R5bGUuZGlzcGxheSA9IFwibm9uZVwiO1xuXG4gICAgaWYgKHRhcmdldCkgZm9ybS50YXJnZXQgPSB0YXJnZXQ7XG4gICAgZWxzZSBpZiAodGFyZ2V0TW9kaWZpZXJLZXkpIGZvcm0udGFyZ2V0ID0gXCJfYmxhbmtcIjtcblxuICAgIGZvcm0uYXBwZW5kQ2hpbGQoY3NyZik7XG4gICAgZm9ybS5hcHBlbmRDaGlsZChtZXRob2QpO1xuICAgIGRvY3VtZW50LmJvZHkuYXBwZW5kQ2hpbGQoZm9ybSk7XG5cbiAgICAvLyBJbnNlcnQgYSBidXR0b24gYW5kIGNsaWNrIGl0IGluc3RlYWQgb2YgdXNpbmcgYGZvcm0uc3VibWl0YFxuICAgIC8vIGJlY2F1c2UgdGhlIGBzdWJtaXRgIGZ1bmN0aW9uIGRvZXMgbm90IGVtaXQgYSBgc3VibWl0YCBldmVudC5cbiAgICBzdWJtaXQudHlwZSA9IFwic3VibWl0XCI7XG4gICAgZm9ybS5hcHBlbmRDaGlsZChzdWJtaXQpO1xuICAgIHN1Ym1pdC5jbGljaygpO1xuICB9XG5cbiAgd2luZG93LmFkZEV2ZW50TGlzdGVuZXIoXCJjbGlja1wiLCBmdW5jdGlvbihlKSB7XG4gICAgdmFyIGVsZW1lbnQgPSBlLnRhcmdldDtcbiAgICBpZiAoZS5kZWZhdWx0UHJldmVudGVkKSByZXR1cm47XG5cbiAgICB3aGlsZSAoZWxlbWVudCAmJiBlbGVtZW50LmdldEF0dHJpYnV0ZSkge1xuICAgICAgdmFyIHBob2VuaXhMaW5rRXZlbnQgPSBuZXcgUG9seWZpbGxFdmVudCgncGhvZW5peC5saW5rLmNsaWNrJywge1xuICAgICAgICBcImJ1YmJsZXNcIjogdHJ1ZSwgXCJjYW5jZWxhYmxlXCI6IHRydWVcbiAgICAgIH0pO1xuXG4gICAgICBpZiAoIWVsZW1lbnQuZGlzcGF0Y2hFdmVudChwaG9lbml4TGlua0V2ZW50KSkge1xuICAgICAgICBlLnByZXZlbnREZWZhdWx0KCk7XG4gICAgICAgIGUuc3RvcEltbWVkaWF0ZVByb3BhZ2F0aW9uKCk7XG4gICAgICAgIHJldHVybiBmYWxzZTtcbiAgICAgIH1cblxuICAgICAgaWYgKGVsZW1lbnQuZ2V0QXR0cmlidXRlKFwiZGF0YS1tZXRob2RcIikgJiYgZWxlbWVudC5nZXRBdHRyaWJ1dGUoXCJkYXRhLXRvXCIpKSB7XG4gICAgICAgIGhhbmRsZUNsaWNrKGVsZW1lbnQsIGUubWV0YUtleSB8fCBlLnNoaWZ0S2V5KTtcbiAgICAgICAgZS5wcmV2ZW50RGVmYXVsdCgpO1xuICAgICAgICByZXR1cm4gZmFsc2U7XG4gICAgICB9IGVsc2Uge1xuICAgICAgICBlbGVtZW50ID0gZWxlbWVudC5wYXJlbnROb2RlO1xuICAgICAgfVxuICAgIH1cbiAgfSwgZmFsc2UpO1xuXG4gIHdpbmRvdy5hZGRFdmVudExpc3RlbmVyKCdwaG9lbml4LmxpbmsuY2xpY2snLCBmdW5jdGlvbiAoZSkge1xuICAgIHZhciBtZXNzYWdlID0gZS50YXJnZXQuZ2V0QXR0cmlidXRlKFwiZGF0YS1jb25maXJtXCIpO1xuICAgIGlmKG1lc3NhZ2UgJiYgIXdpbmRvdy5jb25maXJtKG1lc3NhZ2UpKSB7XG4gICAgICBlLnByZXZlbnREZWZhdWx0KCk7XG4gICAgfVxuICB9LCBmYWxzZSk7XG59KSgpO1xuIiwgIi8vIHdyYXBzIHZhbHVlIGluIGNsb3N1cmUgb3IgcmV0dXJucyBjbG9zdXJlXG5leHBvcnQgbGV0IGNsb3N1cmUgPSAodmFsdWUpID0+IHtcbiAgaWYodHlwZW9mIHZhbHVlID09PSBcImZ1bmN0aW9uXCIpe1xuICAgIHJldHVybiB2YWx1ZVxuICB9IGVsc2Uge1xuICAgIGxldCBjbG9zdXJlID0gZnVuY3Rpb24gKCl7IHJldHVybiB2YWx1ZSB9XG4gICAgcmV0dXJuIGNsb3N1cmVcbiAgfVxufVxuIiwgImV4cG9ydCBjb25zdCBnbG9iYWxTZWxmID0gdHlwZW9mIHNlbGYgIT09IFwidW5kZWZpbmVkXCIgPyBzZWxmIDogbnVsbFxuZXhwb3J0IGNvbnN0IHBoeFdpbmRvdyA9IHR5cGVvZiB3aW5kb3cgIT09IFwidW5kZWZpbmVkXCIgPyB3aW5kb3cgOiBudWxsXG5leHBvcnQgY29uc3QgZ2xvYmFsID0gZ2xvYmFsU2VsZiB8fCBwaHhXaW5kb3cgfHwgZ2xvYmFsVGhpc1xuZXhwb3J0IGNvbnN0IERFRkFVTFRfVlNOID0gXCIyLjAuMFwiXG5leHBvcnQgY29uc3QgU09DS0VUX1NUQVRFUyA9IHtjb25uZWN0aW5nOiAwLCBvcGVuOiAxLCBjbG9zaW5nOiAyLCBjbG9zZWQ6IDN9XG5leHBvcnQgY29uc3QgREVGQVVMVF9USU1FT1VUID0gMTAwMDBcbmV4cG9ydCBjb25zdCBXU19DTE9TRV9OT1JNQUwgPSAxMDAwXG5leHBvcnQgY29uc3QgQ0hBTk5FTF9TVEFURVMgPSB7XG4gIGNsb3NlZDogXCJjbG9zZWRcIixcbiAgZXJyb3JlZDogXCJlcnJvcmVkXCIsXG4gIGpvaW5lZDogXCJqb2luZWRcIixcbiAgam9pbmluZzogXCJqb2luaW5nXCIsXG4gIGxlYXZpbmc6IFwibGVhdmluZ1wiLFxufVxuZXhwb3J0IGNvbnN0IENIQU5ORUxfRVZFTlRTID0ge1xuICBjbG9zZTogXCJwaHhfY2xvc2VcIixcbiAgZXJyb3I6IFwicGh4X2Vycm9yXCIsXG4gIGpvaW46IFwicGh4X2pvaW5cIixcbiAgcmVwbHk6IFwicGh4X3JlcGx5XCIsXG4gIGxlYXZlOiBcInBoeF9sZWF2ZVwiXG59XG5cbmV4cG9ydCBjb25zdCBUUkFOU1BPUlRTID0ge1xuICBsb25ncG9sbDogXCJsb25ncG9sbFwiLFxuICB3ZWJzb2NrZXQ6IFwid2Vic29ja2V0XCJcbn1cbmV4cG9ydCBjb25zdCBYSFJfU1RBVEVTID0ge1xuICBjb21wbGV0ZTogNFxufVxuZXhwb3J0IGNvbnN0IEFVVEhfVE9LRU5fUFJFRklYID0gXCJiYXNlNjR1cmwuYmVhcmVyLnBoeC5cIlxuIiwgIi8qKlxuICogSW5pdGlhbGl6ZXMgdGhlIFB1c2hcbiAqIEBwYXJhbSB7Q2hhbm5lbH0gY2hhbm5lbCAtIFRoZSBDaGFubmVsXG4gKiBAcGFyYW0ge3N0cmluZ30gZXZlbnQgLSBUaGUgZXZlbnQsIGZvciBleGFtcGxlIGBcInBoeF9qb2luXCJgXG4gKiBAcGFyYW0ge09iamVjdH0gcGF5bG9hZCAtIFRoZSBwYXlsb2FkLCBmb3IgZXhhbXBsZSBge3VzZXJfaWQ6IDEyM31gXG4gKiBAcGFyYW0ge251bWJlcn0gdGltZW91dCAtIFRoZSBwdXNoIHRpbWVvdXQgaW4gbWlsbGlzZWNvbmRzXG4gKi9cbmV4cG9ydCBkZWZhdWx0IGNsYXNzIFB1c2gge1xuICBjb25zdHJ1Y3RvcihjaGFubmVsLCBldmVudCwgcGF5bG9hZCwgdGltZW91dCl7XG4gICAgdGhpcy5jaGFubmVsID0gY2hhbm5lbFxuICAgIHRoaXMuZXZlbnQgPSBldmVudFxuICAgIHRoaXMucGF5bG9hZCA9IHBheWxvYWQgfHwgZnVuY3Rpb24gKCl7IHJldHVybiB7fSB9XG4gICAgdGhpcy5yZWNlaXZlZFJlc3AgPSBudWxsXG4gICAgdGhpcy50aW1lb3V0ID0gdGltZW91dFxuICAgIHRoaXMudGltZW91dFRpbWVyID0gbnVsbFxuICAgIHRoaXMucmVjSG9va3MgPSBbXVxuICAgIHRoaXMuc2VudCA9IGZhbHNlXG4gIH1cblxuICAvKipcbiAgICpcbiAgICogQHBhcmFtIHtudW1iZXJ9IHRpbWVvdXRcbiAgICovXG4gIHJlc2VuZCh0aW1lb3V0KXtcbiAgICB0aGlzLnRpbWVvdXQgPSB0aW1lb3V0XG4gICAgdGhpcy5yZXNldCgpXG4gICAgdGhpcy5zZW5kKClcbiAgfVxuXG4gIC8qKlxuICAgKlxuICAgKi9cbiAgc2VuZCgpe1xuICAgIGlmKHRoaXMuaGFzUmVjZWl2ZWQoXCJ0aW1lb3V0XCIpKXsgcmV0dXJuIH1cbiAgICB0aGlzLnN0YXJ0VGltZW91dCgpXG4gICAgdGhpcy5zZW50ID0gdHJ1ZVxuICAgIHRoaXMuY2hhbm5lbC5zb2NrZXQucHVzaCh7XG4gICAgICB0b3BpYzogdGhpcy5jaGFubmVsLnRvcGljLFxuICAgICAgZXZlbnQ6IHRoaXMuZXZlbnQsXG4gICAgICBwYXlsb2FkOiB0aGlzLnBheWxvYWQoKSxcbiAgICAgIHJlZjogdGhpcy5yZWYsXG4gICAgICBqb2luX3JlZjogdGhpcy5jaGFubmVsLmpvaW5SZWYoKVxuICAgIH0pXG4gIH1cblxuICAvKipcbiAgICpcbiAgICogQHBhcmFtIHsqfSBzdGF0dXNcbiAgICogQHBhcmFtIHsqfSBjYWxsYmFja1xuICAgKi9cbiAgcmVjZWl2ZShzdGF0dXMsIGNhbGxiYWNrKXtcbiAgICBpZih0aGlzLmhhc1JlY2VpdmVkKHN0YXR1cykpe1xuICAgICAgY2FsbGJhY2sodGhpcy5yZWNlaXZlZFJlc3AucmVzcG9uc2UpXG4gICAgfVxuXG4gICAgdGhpcy5yZWNIb29rcy5wdXNoKHtzdGF0dXMsIGNhbGxiYWNrfSlcbiAgICByZXR1cm4gdGhpc1xuICB9XG5cbiAgLyoqXG4gICAqIEBwcml2YXRlXG4gICAqL1xuICByZXNldCgpe1xuICAgIHRoaXMuY2FuY2VsUmVmRXZlbnQoKVxuICAgIHRoaXMucmVmID0gbnVsbFxuICAgIHRoaXMucmVmRXZlbnQgPSBudWxsXG4gICAgdGhpcy5yZWNlaXZlZFJlc3AgPSBudWxsXG4gICAgdGhpcy5zZW50ID0gZmFsc2VcbiAgfVxuXG4gIC8qKlxuICAgKiBAcHJpdmF0ZVxuICAgKi9cbiAgbWF0Y2hSZWNlaXZlKHtzdGF0dXMsIHJlc3BvbnNlLCBfcmVmfSl7XG4gICAgdGhpcy5yZWNIb29rcy5maWx0ZXIoaCA9PiBoLnN0YXR1cyA9PT0gc3RhdHVzKVxuICAgICAgLmZvckVhY2goaCA9PiBoLmNhbGxiYWNrKHJlc3BvbnNlKSlcbiAgfVxuXG4gIC8qKlxuICAgKiBAcHJpdmF0ZVxuICAgKi9cbiAgY2FuY2VsUmVmRXZlbnQoKXtcbiAgICBpZighdGhpcy5yZWZFdmVudCl7IHJldHVybiB9XG4gICAgdGhpcy5jaGFubmVsLm9mZih0aGlzLnJlZkV2ZW50KVxuICB9XG5cbiAgLyoqXG4gICAqIEBwcml2YXRlXG4gICAqL1xuICBjYW5jZWxUaW1lb3V0KCl7XG4gICAgY2xlYXJUaW1lb3V0KHRoaXMudGltZW91dFRpbWVyKVxuICAgIHRoaXMudGltZW91dFRpbWVyID0gbnVsbFxuICB9XG5cbiAgLyoqXG4gICAqIEBwcml2YXRlXG4gICAqL1xuICBzdGFydFRpbWVvdXQoKXtcbiAgICBpZih0aGlzLnRpbWVvdXRUaW1lcil7IHRoaXMuY2FuY2VsVGltZW91dCgpIH1cbiAgICB0aGlzLnJlZiA9IHRoaXMuY2hhbm5lbC5zb2NrZXQubWFrZVJlZigpXG4gICAgdGhpcy5yZWZFdmVudCA9IHRoaXMuY2hhbm5lbC5yZXBseUV2ZW50TmFtZSh0aGlzLnJlZilcblxuICAgIHRoaXMuY2hhbm5lbC5vbih0aGlzLnJlZkV2ZW50LCBwYXlsb2FkID0+IHtcbiAgICAgIHRoaXMuY2FuY2VsUmVmRXZlbnQoKVxuICAgICAgdGhpcy5jYW5jZWxUaW1lb3V0KClcbiAgICAgIHRoaXMucmVjZWl2ZWRSZXNwID0gcGF5bG9hZFxuICAgICAgdGhpcy5tYXRjaFJlY2VpdmUocGF5bG9hZClcbiAgICB9KVxuXG4gICAgdGhpcy50aW1lb3V0VGltZXIgPSBzZXRUaW1lb3V0KCgpID0+IHtcbiAgICAgIHRoaXMudHJpZ2dlcihcInRpbWVvdXRcIiwge30pXG4gICAgfSwgdGhpcy50aW1lb3V0KVxuICB9XG5cbiAgLyoqXG4gICAqIEBwcml2YXRlXG4gICAqL1xuICBoYXNSZWNlaXZlZChzdGF0dXMpe1xuICAgIHJldHVybiB0aGlzLnJlY2VpdmVkUmVzcCAmJiB0aGlzLnJlY2VpdmVkUmVzcC5zdGF0dXMgPT09IHN0YXR1c1xuICB9XG5cbiAgLyoqXG4gICAqIEBwcml2YXRlXG4gICAqL1xuICB0cmlnZ2VyKHN0YXR1cywgcmVzcG9uc2Upe1xuICAgIHRoaXMuY2hhbm5lbC50cmlnZ2VyKHRoaXMucmVmRXZlbnQsIHtzdGF0dXMsIHJlc3BvbnNlfSlcbiAgfVxufVxuIiwgIi8qKlxuICpcbiAqIENyZWF0ZXMgYSB0aW1lciB0aGF0IGFjY2VwdHMgYSBgdGltZXJDYWxjYCBmdW5jdGlvbiB0byBwZXJmb3JtXG4gKiBjYWxjdWxhdGVkIHRpbWVvdXQgcmV0cmllcywgc3VjaCBhcyBleHBvbmVudGlhbCBiYWNrb2ZmLlxuICpcbiAqIEBleGFtcGxlXG4gKiBsZXQgcmVjb25uZWN0VGltZXIgPSBuZXcgVGltZXIoKCkgPT4gdGhpcy5jb25uZWN0KCksIGZ1bmN0aW9uKHRyaWVzKXtcbiAqICAgcmV0dXJuIFsxMDAwLCA1MDAwLCAxMDAwMF1bdHJpZXMgLSAxXSB8fCAxMDAwMFxuICogfSlcbiAqIHJlY29ubmVjdFRpbWVyLnNjaGVkdWxlVGltZW91dCgpIC8vIGZpcmVzIGFmdGVyIDEwMDBcbiAqIHJlY29ubmVjdFRpbWVyLnNjaGVkdWxlVGltZW91dCgpIC8vIGZpcmVzIGFmdGVyIDUwMDBcbiAqIHJlY29ubmVjdFRpbWVyLnJlc2V0KClcbiAqIHJlY29ubmVjdFRpbWVyLnNjaGVkdWxlVGltZW91dCgpIC8vIGZpcmVzIGFmdGVyIDEwMDBcbiAqXG4gKiBAcGFyYW0ge0Z1bmN0aW9ufSBjYWxsYmFja1xuICogQHBhcmFtIHtGdW5jdGlvbn0gdGltZXJDYWxjXG4gKi9cbmV4cG9ydCBkZWZhdWx0IGNsYXNzIFRpbWVyIHtcbiAgY29uc3RydWN0b3IoY2FsbGJhY2ssIHRpbWVyQ2FsYyl7XG4gICAgdGhpcy5jYWxsYmFjayA9IGNhbGxiYWNrXG4gICAgdGhpcy50aW1lckNhbGMgPSB0aW1lckNhbGNcbiAgICB0aGlzLnRpbWVyID0gbnVsbFxuICAgIHRoaXMudHJpZXMgPSAwXG4gIH1cblxuICByZXNldCgpe1xuICAgIHRoaXMudHJpZXMgPSAwXG4gICAgY2xlYXJUaW1lb3V0KHRoaXMudGltZXIpXG4gIH1cblxuICAvKipcbiAgICogQ2FuY2VscyBhbnkgcHJldmlvdXMgc2NoZWR1bGVUaW1lb3V0IGFuZCBzY2hlZHVsZXMgY2FsbGJhY2tcbiAgICovXG4gIHNjaGVkdWxlVGltZW91dCgpe1xuICAgIGNsZWFyVGltZW91dCh0aGlzLnRpbWVyKVxuXG4gICAgdGhpcy50aW1lciA9IHNldFRpbWVvdXQoKCkgPT4ge1xuICAgICAgdGhpcy50cmllcyA9IHRoaXMudHJpZXMgKyAxXG4gICAgICB0aGlzLmNhbGxiYWNrKClcbiAgICB9LCB0aGlzLnRpbWVyQ2FsYyh0aGlzLnRyaWVzICsgMSkpXG4gIH1cbn1cbiIsICJpbXBvcnQge2Nsb3N1cmV9IGZyb20gXCIuL3V0aWxzXCJcbmltcG9ydCB7XG4gIENIQU5ORUxfRVZFTlRTLFxuICBDSEFOTkVMX1NUQVRFUyxcbn0gZnJvbSBcIi4vY29uc3RhbnRzXCJcblxuaW1wb3J0IFB1c2ggZnJvbSBcIi4vcHVzaFwiXG5pbXBvcnQgVGltZXIgZnJvbSBcIi4vdGltZXJcIlxuXG4vKipcbiAqXG4gKiBAcGFyYW0ge3N0cmluZ30gdG9waWNcbiAqIEBwYXJhbSB7KE9iamVjdHxmdW5jdGlvbil9IHBhcmFtc1xuICogQHBhcmFtIHtTb2NrZXR9IHNvY2tldFxuICovXG5leHBvcnQgZGVmYXVsdCBjbGFzcyBDaGFubmVsIHtcbiAgY29uc3RydWN0b3IodG9waWMsIHBhcmFtcywgc29ja2V0KXtcbiAgICB0aGlzLnN0YXRlID0gQ0hBTk5FTF9TVEFURVMuY2xvc2VkXG4gICAgdGhpcy50b3BpYyA9IHRvcGljXG4gICAgdGhpcy5wYXJhbXMgPSBjbG9zdXJlKHBhcmFtcyB8fCB7fSlcbiAgICB0aGlzLnNvY2tldCA9IHNvY2tldFxuICAgIHRoaXMuYmluZGluZ3MgPSBbXVxuICAgIHRoaXMuYmluZGluZ1JlZiA9IDBcbiAgICB0aGlzLnRpbWVvdXQgPSB0aGlzLnNvY2tldC50aW1lb3V0XG4gICAgdGhpcy5qb2luZWRPbmNlID0gZmFsc2VcbiAgICB0aGlzLmpvaW5QdXNoID0gbmV3IFB1c2godGhpcywgQ0hBTk5FTF9FVkVOVFMuam9pbiwgdGhpcy5wYXJhbXMsIHRoaXMudGltZW91dClcbiAgICB0aGlzLnB1c2hCdWZmZXIgPSBbXVxuICAgIHRoaXMuc3RhdGVDaGFuZ2VSZWZzID0gW11cblxuICAgIHRoaXMucmVqb2luVGltZXIgPSBuZXcgVGltZXIoKCkgPT4ge1xuICAgICAgaWYodGhpcy5zb2NrZXQuaXNDb25uZWN0ZWQoKSl7IHRoaXMucmVqb2luKCkgfVxuICAgIH0sIHRoaXMuc29ja2V0LnJlam9pbkFmdGVyTXMpXG4gICAgdGhpcy5zdGF0ZUNoYW5nZVJlZnMucHVzaCh0aGlzLnNvY2tldC5vbkVycm9yKCgpID0+IHRoaXMucmVqb2luVGltZXIucmVzZXQoKSkpXG4gICAgdGhpcy5zdGF0ZUNoYW5nZVJlZnMucHVzaCh0aGlzLnNvY2tldC5vbk9wZW4oKCkgPT4ge1xuICAgICAgdGhpcy5yZWpvaW5UaW1lci5yZXNldCgpXG4gICAgICBpZih0aGlzLmlzRXJyb3JlZCgpKXsgdGhpcy5yZWpvaW4oKSB9XG4gICAgfSlcbiAgICApXG4gICAgdGhpcy5qb2luUHVzaC5yZWNlaXZlKFwib2tcIiwgKCkgPT4ge1xuICAgICAgdGhpcy5zdGF0ZSA9IENIQU5ORUxfU1RBVEVTLmpvaW5lZFxuICAgICAgdGhpcy5yZWpvaW5UaW1lci5yZXNldCgpXG4gICAgICB0aGlzLnB1c2hCdWZmZXIuZm9yRWFjaChwdXNoRXZlbnQgPT4gcHVzaEV2ZW50LnNlbmQoKSlcbiAgICAgIHRoaXMucHVzaEJ1ZmZlciA9IFtdXG4gICAgfSlcbiAgICB0aGlzLmpvaW5QdXNoLnJlY2VpdmUoXCJlcnJvclwiLCAoKSA9PiB7XG4gICAgICB0aGlzLnN0YXRlID0gQ0hBTk5FTF9TVEFURVMuZXJyb3JlZFxuICAgICAgaWYodGhpcy5zb2NrZXQuaXNDb25uZWN0ZWQoKSl7IHRoaXMucmVqb2luVGltZXIuc2NoZWR1bGVUaW1lb3V0KCkgfVxuICAgIH0pXG4gICAgdGhpcy5vbkNsb3NlKCgpID0+IHtcbiAgICAgIHRoaXMucmVqb2luVGltZXIucmVzZXQoKVxuICAgICAgaWYodGhpcy5zb2NrZXQuaGFzTG9nZ2VyKCkpIHRoaXMuc29ja2V0LmxvZyhcImNoYW5uZWxcIiwgYGNsb3NlICR7dGhpcy50b3BpY30gJHt0aGlzLmpvaW5SZWYoKX1gKVxuICAgICAgdGhpcy5zdGF0ZSA9IENIQU5ORUxfU1RBVEVTLmNsb3NlZFxuICAgICAgdGhpcy5zb2NrZXQucmVtb3ZlKHRoaXMpXG4gICAgfSlcbiAgICB0aGlzLm9uRXJyb3IocmVhc29uID0+IHtcbiAgICAgIGlmKHRoaXMuc29ja2V0Lmhhc0xvZ2dlcigpKSB0aGlzLnNvY2tldC5sb2coXCJjaGFubmVsXCIsIGBlcnJvciAke3RoaXMudG9waWN9YCwgcmVhc29uKVxuICAgICAgaWYodGhpcy5pc0pvaW5pbmcoKSl7IHRoaXMuam9pblB1c2gucmVzZXQoKSB9XG4gICAgICB0aGlzLnN0YXRlID0gQ0hBTk5FTF9TVEFURVMuZXJyb3JlZFxuICAgICAgaWYodGhpcy5zb2NrZXQuaXNDb25uZWN0ZWQoKSl7IHRoaXMucmVqb2luVGltZXIuc2NoZWR1bGVUaW1lb3V0KCkgfVxuICAgIH0pXG4gICAgdGhpcy5qb2luUHVzaC5yZWNlaXZlKFwidGltZW91dFwiLCAoKSA9PiB7XG4gICAgICBpZih0aGlzLnNvY2tldC5oYXNMb2dnZXIoKSkgdGhpcy5zb2NrZXQubG9nKFwiY2hhbm5lbFwiLCBgdGltZW91dCAke3RoaXMudG9waWN9ICgke3RoaXMuam9pblJlZigpfSlgLCB0aGlzLmpvaW5QdXNoLnRpbWVvdXQpXG4gICAgICBsZXQgbGVhdmVQdXNoID0gbmV3IFB1c2godGhpcywgQ0hBTk5FTF9FVkVOVFMubGVhdmUsIGNsb3N1cmUoe30pLCB0aGlzLnRpbWVvdXQpXG4gICAgICBsZWF2ZVB1c2guc2VuZCgpXG4gICAgICB0aGlzLnN0YXRlID0gQ0hBTk5FTF9TVEFURVMuZXJyb3JlZFxuICAgICAgdGhpcy5qb2luUHVzaC5yZXNldCgpXG4gICAgICBpZih0aGlzLnNvY2tldC5pc0Nvbm5lY3RlZCgpKXsgdGhpcy5yZWpvaW5UaW1lci5zY2hlZHVsZVRpbWVvdXQoKSB9XG4gICAgfSlcbiAgICB0aGlzLm9uKENIQU5ORUxfRVZFTlRTLnJlcGx5LCAocGF5bG9hZCwgcmVmKSA9PiB7XG4gICAgICB0aGlzLnRyaWdnZXIodGhpcy5yZXBseUV2ZW50TmFtZShyZWYpLCBwYXlsb2FkKVxuICAgIH0pXG4gIH1cblxuICAvKipcbiAgICogSm9pbiB0aGUgY2hhbm5lbFxuICAgKiBAcGFyYW0ge2ludGVnZXJ9IHRpbWVvdXRcbiAgICogQHJldHVybnMge1B1c2h9XG4gICAqL1xuICBqb2luKHRpbWVvdXQgPSB0aGlzLnRpbWVvdXQpe1xuICAgIGlmKHRoaXMuam9pbmVkT25jZSl7XG4gICAgICB0aHJvdyBuZXcgRXJyb3IoXCJ0cmllZCB0byBqb2luIG11bHRpcGxlIHRpbWVzLiAnam9pbicgY2FuIG9ubHkgYmUgY2FsbGVkIGEgc2luZ2xlIHRpbWUgcGVyIGNoYW5uZWwgaW5zdGFuY2VcIilcbiAgICB9IGVsc2Uge1xuICAgICAgdGhpcy50aW1lb3V0ID0gdGltZW91dFxuICAgICAgdGhpcy5qb2luZWRPbmNlID0gdHJ1ZVxuICAgICAgdGhpcy5yZWpvaW4oKVxuICAgICAgcmV0dXJuIHRoaXMuam9pblB1c2hcbiAgICB9XG4gIH1cblxuICAvKipcbiAgICogSG9vayBpbnRvIGNoYW5uZWwgY2xvc2VcbiAgICogQHBhcmFtIHtGdW5jdGlvbn0gY2FsbGJhY2tcbiAgICovXG4gIG9uQ2xvc2UoY2FsbGJhY2spe1xuICAgIHRoaXMub24oQ0hBTk5FTF9FVkVOVFMuY2xvc2UsIGNhbGxiYWNrKVxuICB9XG5cbiAgLyoqXG4gICAqIEhvb2sgaW50byBjaGFubmVsIGVycm9yc1xuICAgKiBAcGFyYW0ge0Z1bmN0aW9ufSBjYWxsYmFja1xuICAgKi9cbiAgb25FcnJvcihjYWxsYmFjayl7XG4gICAgcmV0dXJuIHRoaXMub24oQ0hBTk5FTF9FVkVOVFMuZXJyb3IsIHJlYXNvbiA9PiBjYWxsYmFjayhyZWFzb24pKVxuICB9XG5cbiAgLyoqXG4gICAqIFN1YnNjcmliZXMgb24gY2hhbm5lbCBldmVudHNcbiAgICpcbiAgICogU3Vic2NyaXB0aW9uIHJldHVybnMgYSByZWYgY291bnRlciwgd2hpY2ggY2FuIGJlIHVzZWQgbGF0ZXIgdG9cbiAgICogdW5zdWJzY3JpYmUgdGhlIGV4YWN0IGV2ZW50IGxpc3RlbmVyXG4gICAqXG4gICAqIEBleGFtcGxlXG4gICAqIGNvbnN0IHJlZjEgPSBjaGFubmVsLm9uKFwiZXZlbnRcIiwgZG9fc3R1ZmYpXG4gICAqIGNvbnN0IHJlZjIgPSBjaGFubmVsLm9uKFwiZXZlbnRcIiwgZG9fb3RoZXJfc3R1ZmYpXG4gICAqIGNoYW5uZWwub2ZmKFwiZXZlbnRcIiwgcmVmMSlcbiAgICogLy8gU2luY2UgdW5zdWJzY3JpcHRpb24sIGRvX3N0dWZmIHdvbid0IGZpcmUsXG4gICAqIC8vIHdoaWxlIGRvX290aGVyX3N0dWZmIHdpbGwga2VlcCBmaXJpbmcgb24gdGhlIFwiZXZlbnRcIlxuICAgKlxuICAgKiBAcGFyYW0ge3N0cmluZ30gZXZlbnRcbiAgICogQHBhcmFtIHtGdW5jdGlvbn0gY2FsbGJhY2tcbiAgICogQHJldHVybnMge2ludGVnZXJ9IHJlZlxuICAgKi9cbiAgb24oZXZlbnQsIGNhbGxiYWNrKXtcbiAgICBsZXQgcmVmID0gdGhpcy5iaW5kaW5nUmVmKytcbiAgICB0aGlzLmJpbmRpbmdzLnB1c2goe2V2ZW50LCByZWYsIGNhbGxiYWNrfSlcbiAgICByZXR1cm4gcmVmXG4gIH1cblxuICAvKipcbiAgICogVW5zdWJzY3JpYmVzIG9mZiBvZiBjaGFubmVsIGV2ZW50c1xuICAgKlxuICAgKiBVc2UgdGhlIHJlZiByZXR1cm5lZCBmcm9tIGEgY2hhbm5lbC5vbigpIHRvIHVuc3Vic2NyaWJlIG9uZVxuICAgKiBoYW5kbGVyLCBvciBwYXNzIG5vdGhpbmcgZm9yIHRoZSByZWYgdG8gdW5zdWJzY3JpYmUgYWxsXG4gICAqIGhhbmRsZXJzIGZvciB0aGUgZ2l2ZW4gZXZlbnQuXG4gICAqXG4gICAqIEBleGFtcGxlXG4gICAqIC8vIFVuc3Vic2NyaWJlIHRoZSBkb19zdHVmZiBoYW5kbGVyXG4gICAqIGNvbnN0IHJlZjEgPSBjaGFubmVsLm9uKFwiZXZlbnRcIiwgZG9fc3R1ZmYpXG4gICAqIGNoYW5uZWwub2ZmKFwiZXZlbnRcIiwgcmVmMSlcbiAgICpcbiAgICogLy8gVW5zdWJzY3JpYmUgYWxsIGhhbmRsZXJzIGZyb20gZXZlbnRcbiAgICogY2hhbm5lbC5vZmYoXCJldmVudFwiKVxuICAgKlxuICAgKiBAcGFyYW0ge3N0cmluZ30gZXZlbnRcbiAgICogQHBhcmFtIHtpbnRlZ2VyfSByZWZcbiAgICovXG4gIG9mZihldmVudCwgcmVmKXtcbiAgICB0aGlzLmJpbmRpbmdzID0gdGhpcy5iaW5kaW5ncy5maWx0ZXIoKGJpbmQpID0+IHtcbiAgICAgIHJldHVybiAhKGJpbmQuZXZlbnQgPT09IGV2ZW50ICYmICh0eXBlb2YgcmVmID09PSBcInVuZGVmaW5lZFwiIHx8IHJlZiA9PT0gYmluZC5yZWYpKVxuICAgIH0pXG4gIH1cblxuICAvKipcbiAgICogQHByaXZhdGVcbiAgICovXG4gIGNhblB1c2goKXsgcmV0dXJuIHRoaXMuc29ja2V0LmlzQ29ubmVjdGVkKCkgJiYgdGhpcy5pc0pvaW5lZCgpIH1cblxuICAvKipcbiAgICogU2VuZHMgYSBtZXNzYWdlIGBldmVudGAgdG8gcGhvZW5peCB3aXRoIHRoZSBwYXlsb2FkIGBwYXlsb2FkYC5cbiAgICogUGhvZW5peCByZWNlaXZlcyB0aGlzIGluIHRoZSBgaGFuZGxlX2luKGV2ZW50LCBwYXlsb2FkLCBzb2NrZXQpYFxuICAgKiBmdW5jdGlvbi4gaWYgcGhvZW5peCByZXBsaWVzIG9yIGl0IHRpbWVzIG91dCAoZGVmYXVsdCAxMDAwMG1zKSxcbiAgICogdGhlbiBvcHRpb25hbGx5IHRoZSByZXBseSBjYW4gYmUgcmVjZWl2ZWQuXG4gICAqXG4gICAqIEBleGFtcGxlXG4gICAqIGNoYW5uZWwucHVzaChcImV2ZW50XCIpXG4gICAqICAgLnJlY2VpdmUoXCJva1wiLCBwYXlsb2FkID0+IGNvbnNvbGUubG9nKFwicGhvZW5peCByZXBsaWVkOlwiLCBwYXlsb2FkKSlcbiAgICogICAucmVjZWl2ZShcImVycm9yXCIsIGVyciA9PiBjb25zb2xlLmxvZyhcInBob2VuaXggZXJyb3JlZFwiLCBlcnIpKVxuICAgKiAgIC5yZWNlaXZlKFwidGltZW91dFwiLCAoKSA9PiBjb25zb2xlLmxvZyhcInRpbWVkIG91dCBwdXNoaW5nXCIpKVxuICAgKiBAcGFyYW0ge3N0cmluZ30gZXZlbnRcbiAgICogQHBhcmFtIHtPYmplY3R9IHBheWxvYWRcbiAgICogQHBhcmFtIHtudW1iZXJ9IFt0aW1lb3V0XVxuICAgKiBAcmV0dXJucyB7UHVzaH1cbiAgICovXG4gIHB1c2goZXZlbnQsIHBheWxvYWQsIHRpbWVvdXQgPSB0aGlzLnRpbWVvdXQpe1xuICAgIHBheWxvYWQgPSBwYXlsb2FkIHx8IHt9XG4gICAgaWYoIXRoaXMuam9pbmVkT25jZSl7XG4gICAgICB0aHJvdyBuZXcgRXJyb3IoYHRyaWVkIHRvIHB1c2ggJyR7ZXZlbnR9JyB0byAnJHt0aGlzLnRvcGljfScgYmVmb3JlIGpvaW5pbmcuIFVzZSBjaGFubmVsLmpvaW4oKSBiZWZvcmUgcHVzaGluZyBldmVudHNgKVxuICAgIH1cbiAgICBsZXQgcHVzaEV2ZW50ID0gbmV3IFB1c2godGhpcywgZXZlbnQsIGZ1bmN0aW9uICgpeyByZXR1cm4gcGF5bG9hZCB9LCB0aW1lb3V0KVxuICAgIGlmKHRoaXMuY2FuUHVzaCgpKXtcbiAgICAgIHB1c2hFdmVudC5zZW5kKClcbiAgICB9IGVsc2Uge1xuICAgICAgcHVzaEV2ZW50LnN0YXJ0VGltZW91dCgpXG4gICAgICB0aGlzLnB1c2hCdWZmZXIucHVzaChwdXNoRXZlbnQpXG4gICAgfVxuXG4gICAgcmV0dXJuIHB1c2hFdmVudFxuICB9XG5cbiAgLyoqIExlYXZlcyB0aGUgY2hhbm5lbFxuICAgKlxuICAgKiBVbnN1YnNjcmliZXMgZnJvbSBzZXJ2ZXIgZXZlbnRzLCBhbmRcbiAgICogaW5zdHJ1Y3RzIGNoYW5uZWwgdG8gdGVybWluYXRlIG9uIHNlcnZlclxuICAgKlxuICAgKiBUcmlnZ2VycyBvbkNsb3NlKCkgaG9va3NcbiAgICpcbiAgICogVG8gcmVjZWl2ZSBsZWF2ZSBhY2tub3dsZWRnZW1lbnRzLCB1c2UgdGhlIGByZWNlaXZlYFxuICAgKiBob29rIHRvIGJpbmQgdG8gdGhlIHNlcnZlciBhY2ssIGllOlxuICAgKlxuICAgKiBAZXhhbXBsZVxuICAgKiBjaGFubmVsLmxlYXZlKCkucmVjZWl2ZShcIm9rXCIsICgpID0+IGFsZXJ0KFwibGVmdCFcIikgKVxuICAgKlxuICAgKiBAcGFyYW0ge2ludGVnZXJ9IHRpbWVvdXRcbiAgICogQHJldHVybnMge1B1c2h9XG4gICAqL1xuICBsZWF2ZSh0aW1lb3V0ID0gdGhpcy50aW1lb3V0KXtcbiAgICB0aGlzLnJlam9pblRpbWVyLnJlc2V0KClcbiAgICB0aGlzLmpvaW5QdXNoLmNhbmNlbFRpbWVvdXQoKVxuXG4gICAgdGhpcy5zdGF0ZSA9IENIQU5ORUxfU1RBVEVTLmxlYXZpbmdcbiAgICBsZXQgb25DbG9zZSA9ICgpID0+IHtcbiAgICAgIGlmKHRoaXMuc29ja2V0Lmhhc0xvZ2dlcigpKSB0aGlzLnNvY2tldC5sb2coXCJjaGFubmVsXCIsIGBsZWF2ZSAke3RoaXMudG9waWN9YClcbiAgICAgIHRoaXMudHJpZ2dlcihDSEFOTkVMX0VWRU5UUy5jbG9zZSwgXCJsZWF2ZVwiKVxuICAgIH1cbiAgICBsZXQgbGVhdmVQdXNoID0gbmV3IFB1c2godGhpcywgQ0hBTk5FTF9FVkVOVFMubGVhdmUsIGNsb3N1cmUoe30pLCB0aW1lb3V0KVxuICAgIGxlYXZlUHVzaC5yZWNlaXZlKFwib2tcIiwgKCkgPT4gb25DbG9zZSgpKVxuICAgICAgLnJlY2VpdmUoXCJ0aW1lb3V0XCIsICgpID0+IG9uQ2xvc2UoKSlcbiAgICBsZWF2ZVB1c2guc2VuZCgpXG4gICAgaWYoIXRoaXMuY2FuUHVzaCgpKXsgbGVhdmVQdXNoLnRyaWdnZXIoXCJva1wiLCB7fSkgfVxuXG4gICAgcmV0dXJuIGxlYXZlUHVzaFxuICB9XG5cbiAgLyoqXG4gICAqIE92ZXJyaWRhYmxlIG1lc3NhZ2UgaG9va1xuICAgKlxuICAgKiBSZWNlaXZlcyBhbGwgZXZlbnRzIGZvciBzcGVjaWFsaXplZCBtZXNzYWdlIGhhbmRsaW5nXG4gICAqIGJlZm9yZSBkaXNwYXRjaGluZyB0byB0aGUgY2hhbm5lbCBjYWxsYmFja3MuXG4gICAqXG4gICAqIE11c3QgcmV0dXJuIHRoZSBwYXlsb2FkLCBtb2RpZmllZCBvciB1bm1vZGlmaWVkXG4gICAqIEBwYXJhbSB7c3RyaW5nfSBldmVudFxuICAgKiBAcGFyYW0ge09iamVjdH0gcGF5bG9hZFxuICAgKiBAcGFyYW0ge2ludGVnZXJ9IHJlZlxuICAgKiBAcmV0dXJucyB7T2JqZWN0fVxuICAgKi9cbiAgb25NZXNzYWdlKF9ldmVudCwgcGF5bG9hZCwgX3JlZil7IHJldHVybiBwYXlsb2FkIH1cblxuICAvKipcbiAgICogQHByaXZhdGVcbiAgICovXG4gIGlzTWVtYmVyKHRvcGljLCBldmVudCwgcGF5bG9hZCwgam9pblJlZil7XG4gICAgaWYodGhpcy50b3BpYyAhPT0gdG9waWMpeyByZXR1cm4gZmFsc2UgfVxuXG4gICAgaWYoam9pblJlZiAmJiBqb2luUmVmICE9PSB0aGlzLmpvaW5SZWYoKSl7XG4gICAgICBpZih0aGlzLnNvY2tldC5oYXNMb2dnZXIoKSkgdGhpcy5zb2NrZXQubG9nKFwiY2hhbm5lbFwiLCBcImRyb3BwaW5nIG91dGRhdGVkIG1lc3NhZ2VcIiwge3RvcGljLCBldmVudCwgcGF5bG9hZCwgam9pblJlZn0pXG4gICAgICByZXR1cm4gZmFsc2VcbiAgICB9IGVsc2Uge1xuICAgICAgcmV0dXJuIHRydWVcbiAgICB9XG4gIH1cblxuICAvKipcbiAgICogQHByaXZhdGVcbiAgICovXG4gIGpvaW5SZWYoKXsgcmV0dXJuIHRoaXMuam9pblB1c2gucmVmIH1cblxuICAvKipcbiAgICogQHByaXZhdGVcbiAgICovXG4gIHJlam9pbih0aW1lb3V0ID0gdGhpcy50aW1lb3V0KXtcbiAgICBpZih0aGlzLmlzTGVhdmluZygpKXsgcmV0dXJuIH1cbiAgICB0aGlzLnNvY2tldC5sZWF2ZU9wZW5Ub3BpYyh0aGlzLnRvcGljKVxuICAgIHRoaXMuc3RhdGUgPSBDSEFOTkVMX1NUQVRFUy5qb2luaW5nXG4gICAgdGhpcy5qb2luUHVzaC5yZXNlbmQodGltZW91dClcbiAgfVxuXG4gIC8qKlxuICAgKiBAcHJpdmF0ZVxuICAgKi9cbiAgdHJpZ2dlcihldmVudCwgcGF5bG9hZCwgcmVmLCBqb2luUmVmKXtcbiAgICBsZXQgaGFuZGxlZFBheWxvYWQgPSB0aGlzLm9uTWVzc2FnZShldmVudCwgcGF5bG9hZCwgcmVmLCBqb2luUmVmKVxuICAgIGlmKHBheWxvYWQgJiYgIWhhbmRsZWRQYXlsb2FkKXsgdGhyb3cgbmV3IEVycm9yKFwiY2hhbm5lbCBvbk1lc3NhZ2UgY2FsbGJhY2tzIG11c3QgcmV0dXJuIHRoZSBwYXlsb2FkLCBtb2RpZmllZCBvciB1bm1vZGlmaWVkXCIpIH1cblxuICAgIGxldCBldmVudEJpbmRpbmdzID0gdGhpcy5iaW5kaW5ncy5maWx0ZXIoYmluZCA9PiBiaW5kLmV2ZW50ID09PSBldmVudClcblxuICAgIGZvcihsZXQgaSA9IDA7IGkgPCBldmVudEJpbmRpbmdzLmxlbmd0aDsgaSsrKXtcbiAgICAgIGxldCBiaW5kID0gZXZlbnRCaW5kaW5nc1tpXVxuICAgICAgYmluZC5jYWxsYmFjayhoYW5kbGVkUGF5bG9hZCwgcmVmLCBqb2luUmVmIHx8IHRoaXMuam9pblJlZigpKVxuICAgIH1cbiAgfVxuXG4gIC8qKlxuICAgKiBAcHJpdmF0ZVxuICAgKi9cbiAgcmVwbHlFdmVudE5hbWUocmVmKXsgcmV0dXJuIGBjaGFuX3JlcGx5XyR7cmVmfWAgfVxuXG4gIC8qKlxuICAgKiBAcHJpdmF0ZVxuICAgKi9cbiAgaXNDbG9zZWQoKXsgcmV0dXJuIHRoaXMuc3RhdGUgPT09IENIQU5ORUxfU1RBVEVTLmNsb3NlZCB9XG5cbiAgLyoqXG4gICAqIEBwcml2YXRlXG4gICAqL1xuICBpc0Vycm9yZWQoKXsgcmV0dXJuIHRoaXMuc3RhdGUgPT09IENIQU5ORUxfU1RBVEVTLmVycm9yZWQgfVxuXG4gIC8qKlxuICAgKiBAcHJpdmF0ZVxuICAgKi9cbiAgaXNKb2luZWQoKXsgcmV0dXJuIHRoaXMuc3RhdGUgPT09IENIQU5ORUxfU1RBVEVTLmpvaW5lZCB9XG5cbiAgLyoqXG4gICAqIEBwcml2YXRlXG4gICAqL1xuICBpc0pvaW5pbmcoKXsgcmV0dXJuIHRoaXMuc3RhdGUgPT09IENIQU5ORUxfU1RBVEVTLmpvaW5pbmcgfVxuXG4gIC8qKlxuICAgKiBAcHJpdmF0ZVxuICAgKi9cbiAgaXNMZWF2aW5nKCl7IHJldHVybiB0aGlzLnN0YXRlID09PSBDSEFOTkVMX1NUQVRFUy5sZWF2aW5nIH1cbn1cbiIsICJpbXBvcnQge1xuICBnbG9iYWwsXG4gIFhIUl9TVEFURVNcbn0gZnJvbSBcIi4vY29uc3RhbnRzXCJcblxuZXhwb3J0IGRlZmF1bHQgY2xhc3MgQWpheCB7XG5cbiAgc3RhdGljIHJlcXVlc3QobWV0aG9kLCBlbmRQb2ludCwgaGVhZGVycywgYm9keSwgdGltZW91dCwgb250aW1lb3V0LCBjYWxsYmFjayl7XG4gICAgaWYoZ2xvYmFsLlhEb21haW5SZXF1ZXN0KXtcbiAgICAgIGxldCByZXEgPSBuZXcgZ2xvYmFsLlhEb21haW5SZXF1ZXN0KCkgLy8gSUU4LCBJRTlcbiAgICAgIHJldHVybiB0aGlzLnhkb21haW5SZXF1ZXN0KHJlcSwgbWV0aG9kLCBlbmRQb2ludCwgYm9keSwgdGltZW91dCwgb250aW1lb3V0LCBjYWxsYmFjaylcbiAgICB9IGVsc2UgaWYoZ2xvYmFsLlhNTEh0dHBSZXF1ZXN0KXtcbiAgICAgIGxldCByZXEgPSBuZXcgZ2xvYmFsLlhNTEh0dHBSZXF1ZXN0KCkgLy8gSUU3KywgRmlyZWZveCwgQ2hyb21lLCBPcGVyYSwgU2FmYXJpXG4gICAgICByZXR1cm4gdGhpcy54aHJSZXF1ZXN0KHJlcSwgbWV0aG9kLCBlbmRQb2ludCwgaGVhZGVycywgYm9keSwgdGltZW91dCwgb250aW1lb3V0LCBjYWxsYmFjaylcbiAgICB9IGVsc2UgaWYoZ2xvYmFsLmZldGNoICYmIGdsb2JhbC5BYm9ydENvbnRyb2xsZXIpe1xuICAgICAgLy8gRmV0Y2ggd2l0aCBBYm9ydENvbnRyb2xsZXIgZm9yIG1vZGVybiBicm93c2Vyc1xuICAgICAgcmV0dXJuIHRoaXMuZmV0Y2hSZXF1ZXN0KG1ldGhvZCwgZW5kUG9pbnQsIGhlYWRlcnMsIGJvZHksIHRpbWVvdXQsIG9udGltZW91dCwgY2FsbGJhY2spXG4gICAgfSBlbHNlIHtcbiAgICAgIHRocm93IG5ldyBFcnJvcihcIk5vIHN1aXRhYmxlIFhNTEh0dHBSZXF1ZXN0IGltcGxlbWVudGF0aW9uIGZvdW5kXCIpXG4gICAgfVxuICB9XG5cbiAgc3RhdGljIGZldGNoUmVxdWVzdChtZXRob2QsIGVuZFBvaW50LCBoZWFkZXJzLCBib2R5LCB0aW1lb3V0LCBvbnRpbWVvdXQsIGNhbGxiYWNrKXtcbiAgICBsZXQgb3B0aW9ucyA9IHtcbiAgICAgIG1ldGhvZCxcbiAgICAgIGhlYWRlcnMsXG4gICAgICBib2R5LFxuICAgIH1cbiAgICBsZXQgY29udHJvbGxlciA9IG51bGxcbiAgICBpZih0aW1lb3V0KXtcbiAgICAgIGNvbnRyb2xsZXIgPSBuZXcgQWJvcnRDb250cm9sbGVyKClcbiAgICAgIGNvbnN0IF90aW1lb3V0SWQgPSBzZXRUaW1lb3V0KCgpID0+IGNvbnRyb2xsZXIuYWJvcnQoKSwgdGltZW91dClcbiAgICAgIG9wdGlvbnMuc2lnbmFsID0gY29udHJvbGxlci5zaWduYWxcbiAgICB9XG4gICAgZ2xvYmFsLmZldGNoKGVuZFBvaW50LCBvcHRpb25zKVxuICAgICAgLnRoZW4ocmVzcG9uc2UgPT4gcmVzcG9uc2UudGV4dCgpKVxuICAgICAgLnRoZW4oZGF0YSA9PiB0aGlzLnBhcnNlSlNPTihkYXRhKSlcbiAgICAgIC50aGVuKGRhdGEgPT4gY2FsbGJhY2sgJiYgY2FsbGJhY2soZGF0YSkpXG4gICAgICAuY2F0Y2goZXJyID0+IHtcbiAgICAgICAgaWYoZXJyLm5hbWUgPT09IFwiQWJvcnRFcnJvclwiICYmIG9udGltZW91dCl7XG4gICAgICAgICAgb250aW1lb3V0KClcbiAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICBjYWxsYmFjayAmJiBjYWxsYmFjayhudWxsKVxuICAgICAgICB9XG4gICAgICB9KVxuICAgIHJldHVybiBjb250cm9sbGVyXG4gIH1cblxuICBzdGF0aWMgeGRvbWFpblJlcXVlc3QocmVxLCBtZXRob2QsIGVuZFBvaW50LCBib2R5LCB0aW1lb3V0LCBvbnRpbWVvdXQsIGNhbGxiYWNrKXtcbiAgICByZXEudGltZW91dCA9IHRpbWVvdXRcbiAgICByZXEub3BlbihtZXRob2QsIGVuZFBvaW50KVxuICAgIHJlcS5vbmxvYWQgPSAoKSA9PiB7XG4gICAgICBsZXQgcmVzcG9uc2UgPSB0aGlzLnBhcnNlSlNPTihyZXEucmVzcG9uc2VUZXh0KVxuICAgICAgY2FsbGJhY2sgJiYgY2FsbGJhY2socmVzcG9uc2UpXG4gICAgfVxuICAgIGlmKG9udGltZW91dCl7IHJlcS5vbnRpbWVvdXQgPSBvbnRpbWVvdXQgfVxuXG4gICAgLy8gV29yayBhcm91bmQgYnVnIGluIElFOSB0aGF0IHJlcXVpcmVzIGFuIGF0dGFjaGVkIG9ucHJvZ3Jlc3MgaGFuZGxlclxuICAgIHJlcS5vbnByb2dyZXNzID0gKCkgPT4geyB9XG5cbiAgICByZXEuc2VuZChib2R5KVxuICAgIHJldHVybiByZXFcbiAgfVxuXG4gIHN0YXRpYyB4aHJSZXF1ZXN0KHJlcSwgbWV0aG9kLCBlbmRQb2ludCwgaGVhZGVycywgYm9keSwgdGltZW91dCwgb250aW1lb3V0LCBjYWxsYmFjayl7XG4gICAgcmVxLm9wZW4obWV0aG9kLCBlbmRQb2ludCwgdHJ1ZSlcbiAgICByZXEudGltZW91dCA9IHRpbWVvdXRcbiAgICBmb3IobGV0IFtrZXksIHZhbHVlXSBvZiBPYmplY3QuZW50cmllcyhoZWFkZXJzKSl7XG4gICAgICByZXEuc2V0UmVxdWVzdEhlYWRlcihrZXksIHZhbHVlKVxuICAgIH1cbiAgICByZXEub25lcnJvciA9ICgpID0+IGNhbGxiYWNrICYmIGNhbGxiYWNrKG51bGwpXG4gICAgcmVxLm9ucmVhZHlzdGF0ZWNoYW5nZSA9ICgpID0+IHtcbiAgICAgIGlmKHJlcS5yZWFkeVN0YXRlID09PSBYSFJfU1RBVEVTLmNvbXBsZXRlICYmIGNhbGxiYWNrKXtcbiAgICAgICAgbGV0IHJlc3BvbnNlID0gdGhpcy5wYXJzZUpTT04ocmVxLnJlc3BvbnNlVGV4dClcbiAgICAgICAgY2FsbGJhY2socmVzcG9uc2UpXG4gICAgICB9XG4gICAgfVxuICAgIGlmKG9udGltZW91dCl7IHJlcS5vbnRpbWVvdXQgPSBvbnRpbWVvdXQgfVxuXG4gICAgcmVxLnNlbmQoYm9keSlcbiAgICByZXR1cm4gcmVxXG4gIH1cblxuICBzdGF0aWMgcGFyc2VKU09OKHJlc3Ape1xuICAgIGlmKCFyZXNwIHx8IHJlc3AgPT09IFwiXCIpeyByZXR1cm4gbnVsbCB9XG5cbiAgICB0cnkge1xuICAgICAgcmV0dXJuIEpTT04ucGFyc2UocmVzcClcbiAgICB9IGNhdGNoIHtcbiAgICAgIGNvbnNvbGUgJiYgY29uc29sZS5sb2coXCJmYWlsZWQgdG8gcGFyc2UgSlNPTiByZXNwb25zZVwiLCByZXNwKVxuICAgICAgcmV0dXJuIG51bGxcbiAgICB9XG4gIH1cblxuICBzdGF0aWMgc2VyaWFsaXplKG9iaiwgcGFyZW50S2V5KXtcbiAgICBsZXQgcXVlcnlTdHIgPSBbXVxuICAgIGZvcih2YXIga2V5IGluIG9iail7XG4gICAgICBpZighT2JqZWN0LnByb3RvdHlwZS5oYXNPd25Qcm9wZXJ0eS5jYWxsKG9iaiwga2V5KSl7IGNvbnRpbnVlIH1cbiAgICAgIGxldCBwYXJhbUtleSA9IHBhcmVudEtleSA/IGAke3BhcmVudEtleX1bJHtrZXl9XWAgOiBrZXlcbiAgICAgIGxldCBwYXJhbVZhbCA9IG9ialtrZXldXG4gICAgICBpZih0eXBlb2YgcGFyYW1WYWwgPT09IFwib2JqZWN0XCIpe1xuICAgICAgICBxdWVyeVN0ci5wdXNoKHRoaXMuc2VyaWFsaXplKHBhcmFtVmFsLCBwYXJhbUtleSkpXG4gICAgICB9IGVsc2Uge1xuICAgICAgICBxdWVyeVN0ci5wdXNoKGVuY29kZVVSSUNvbXBvbmVudChwYXJhbUtleSkgKyBcIj1cIiArIGVuY29kZVVSSUNvbXBvbmVudChwYXJhbVZhbCkpXG4gICAgICB9XG4gICAgfVxuICAgIHJldHVybiBxdWVyeVN0ci5qb2luKFwiJlwiKVxuICB9XG5cbiAgc3RhdGljIGFwcGVuZFBhcmFtcyh1cmwsIHBhcmFtcyl7XG4gICAgaWYoT2JqZWN0LmtleXMocGFyYW1zKS5sZW5ndGggPT09IDApeyByZXR1cm4gdXJsIH1cblxuICAgIGxldCBwcmVmaXggPSB1cmwubWF0Y2goL1xcPy8pID8gXCImXCIgOiBcIj9cIlxuICAgIHJldHVybiBgJHt1cmx9JHtwcmVmaXh9JHt0aGlzLnNlcmlhbGl6ZShwYXJhbXMpfWBcbiAgfVxufVxuIiwgImltcG9ydCB7XG4gIFNPQ0tFVF9TVEFURVMsXG4gIFRSQU5TUE9SVFMsXG4gIEFVVEhfVE9LRU5fUFJFRklYXG59IGZyb20gXCIuL2NvbnN0YW50c1wiXG5cbmltcG9ydCBBamF4IGZyb20gXCIuL2FqYXhcIlxuXG5sZXQgYXJyYXlCdWZmZXJUb0Jhc2U2NCA9IChidWZmZXIpID0+IHtcbiAgbGV0IGJpbmFyeSA9IFwiXCJcbiAgbGV0IGJ5dGVzID0gbmV3IFVpbnQ4QXJyYXkoYnVmZmVyKVxuICBsZXQgbGVuID0gYnl0ZXMuYnl0ZUxlbmd0aFxuICBmb3IobGV0IGkgPSAwOyBpIDwgbGVuOyBpKyspeyBiaW5hcnkgKz0gU3RyaW5nLmZyb21DaGFyQ29kZShieXRlc1tpXSkgfVxuICByZXR1cm4gYnRvYShiaW5hcnkpXG59XG5cbmV4cG9ydCBkZWZhdWx0IGNsYXNzIExvbmdQb2xsIHtcblxuICBjb25zdHJ1Y3RvcihlbmRQb2ludCwgcHJvdG9jb2xzKXtcbiAgICAvLyB3ZSBvbmx5IHN1cHBvcnQgc3VicHJvdG9jb2xzIGZvciBhdXRoVG9rZW5cbiAgICAvLyBbXCJwaG9lbml4XCIsIFwiYmFzZTY0dXJsLmJlYXJlci5waHguQkFTRTY0X0VOQ09ERURfVE9LRU5cIl1cbiAgICBpZihwcm90b2NvbHMgJiYgcHJvdG9jb2xzLmxlbmd0aCA9PT0gMiAmJiBwcm90b2NvbHNbMV0uc3RhcnRzV2l0aChBVVRIX1RPS0VOX1BSRUZJWCkpe1xuICAgICAgdGhpcy5hdXRoVG9rZW4gPSBhdG9iKHByb3RvY29sc1sxXS5zbGljZShBVVRIX1RPS0VOX1BSRUZJWC5sZW5ndGgpKVxuICAgIH1cbiAgICB0aGlzLmVuZFBvaW50ID0gbnVsbFxuICAgIHRoaXMudG9rZW4gPSBudWxsXG4gICAgdGhpcy5za2lwSGVhcnRiZWF0ID0gdHJ1ZVxuICAgIHRoaXMucmVxcyA9IG5ldyBTZXQoKVxuICAgIHRoaXMuYXdhaXRpbmdCYXRjaEFjayA9IGZhbHNlXG4gICAgdGhpcy5jdXJyZW50QmF0Y2ggPSBudWxsXG4gICAgdGhpcy5jdXJyZW50QmF0Y2hUaW1lciA9IG51bGxcbiAgICB0aGlzLmJhdGNoQnVmZmVyID0gW11cbiAgICB0aGlzLm9ub3BlbiA9IGZ1bmN0aW9uICgpeyB9IC8vIG5vb3BcbiAgICB0aGlzLm9uZXJyb3IgPSBmdW5jdGlvbiAoKXsgfSAvLyBub29wXG4gICAgdGhpcy5vbm1lc3NhZ2UgPSBmdW5jdGlvbiAoKXsgfSAvLyBub29wXG4gICAgdGhpcy5vbmNsb3NlID0gZnVuY3Rpb24gKCl7IH0gLy8gbm9vcFxuICAgIHRoaXMucG9sbEVuZHBvaW50ID0gdGhpcy5ub3JtYWxpemVFbmRwb2ludChlbmRQb2ludClcbiAgICB0aGlzLnJlYWR5U3RhdGUgPSBTT0NLRVRfU1RBVEVTLmNvbm5lY3RpbmdcbiAgICAvLyB3ZSBtdXN0IHdhaXQgZm9yIHRoZSBjYWxsZXIgdG8gZmluaXNoIHNldHRpbmcgdXAgb3VyIGNhbGxiYWNrcyBhbmQgdGltZW91dCBwcm9wZXJ0aWVzXG4gICAgc2V0VGltZW91dCgoKSA9PiB0aGlzLnBvbGwoKSwgMClcbiAgfVxuXG4gIG5vcm1hbGl6ZUVuZHBvaW50KGVuZFBvaW50KXtcbiAgICByZXR1cm4gKGVuZFBvaW50XG4gICAgICAucmVwbGFjZShcIndzOi8vXCIsIFwiaHR0cDovL1wiKVxuICAgICAgLnJlcGxhY2UoXCJ3c3M6Ly9cIiwgXCJodHRwczovL1wiKVxuICAgICAgLnJlcGxhY2UobmV3IFJlZ0V4cChcIiguKilcXC9cIiArIFRSQU5TUE9SVFMud2Vic29ja2V0KSwgXCIkMS9cIiArIFRSQU5TUE9SVFMubG9uZ3BvbGwpKVxuICB9XG5cbiAgZW5kcG9pbnRVUkwoKXtcbiAgICByZXR1cm4gQWpheC5hcHBlbmRQYXJhbXModGhpcy5wb2xsRW5kcG9pbnQsIHt0b2tlbjogdGhpcy50b2tlbn0pXG4gIH1cblxuICBjbG9zZUFuZFJldHJ5KGNvZGUsIHJlYXNvbiwgd2FzQ2xlYW4pe1xuICAgIHRoaXMuY2xvc2UoY29kZSwgcmVhc29uLCB3YXNDbGVhbilcbiAgICB0aGlzLnJlYWR5U3RhdGUgPSBTT0NLRVRfU1RBVEVTLmNvbm5lY3RpbmdcbiAgfVxuXG4gIG9udGltZW91dCgpe1xuICAgIHRoaXMub25lcnJvcihcInRpbWVvdXRcIilcbiAgICB0aGlzLmNsb3NlQW5kUmV0cnkoMTAwNSwgXCJ0aW1lb3V0XCIsIGZhbHNlKVxuICB9XG5cbiAgaXNBY3RpdmUoKXsgcmV0dXJuIHRoaXMucmVhZHlTdGF0ZSA9PT0gU09DS0VUX1NUQVRFUy5vcGVuIHx8IHRoaXMucmVhZHlTdGF0ZSA9PT0gU09DS0VUX1NUQVRFUy5jb25uZWN0aW5nIH1cblxuICBwb2xsKCl7XG4gICAgY29uc3QgaGVhZGVycyA9IHtcIkFjY2VwdFwiOiBcImFwcGxpY2F0aW9uL2pzb25cIn1cbiAgICBpZih0aGlzLmF1dGhUb2tlbil7XG4gICAgICBoZWFkZXJzW1wiWC1QaG9lbml4LUF1dGhUb2tlblwiXSA9IHRoaXMuYXV0aFRva2VuXG4gICAgfVxuICAgIHRoaXMuYWpheChcIkdFVFwiLCBoZWFkZXJzLCBudWxsLCAoKSA9PiB0aGlzLm9udGltZW91dCgpLCByZXNwID0+IHtcbiAgICAgIGlmKHJlc3Ape1xuICAgICAgICB2YXIge3N0YXR1cywgdG9rZW4sIG1lc3NhZ2VzfSA9IHJlc3BcbiAgICAgICAgdGhpcy50b2tlbiA9IHRva2VuXG4gICAgICB9IGVsc2Uge1xuICAgICAgICBzdGF0dXMgPSAwXG4gICAgICB9XG5cbiAgICAgIHN3aXRjaChzdGF0dXMpe1xuICAgICAgICBjYXNlIDIwMDpcbiAgICAgICAgICBtZXNzYWdlcy5mb3JFYWNoKG1zZyA9PiB7XG4gICAgICAgICAgICAvLyBUYXNrcyBhcmUgd2hhdCB0aGluZ3MgbGlrZSBldmVudCBoYW5kbGVycywgc2V0VGltZW91dCBjYWxsYmFja3MsXG4gICAgICAgICAgICAvLyBwcm9taXNlIHJlc29sdmVzIGFuZCBtb3JlIGFyZSBydW4gd2l0aGluLlxuICAgICAgICAgICAgLy8gSW4gbW9kZXJuIGJyb3dzZXJzLCB0aGVyZSBhcmUgdHdvIGRpZmZlcmVudCBraW5kcyBvZiB0YXNrcyxcbiAgICAgICAgICAgIC8vIG1pY3JvdGFza3MgYW5kIG1hY3JvdGFza3MuXG4gICAgICAgICAgICAvLyBNaWNyb3Rhc2tzIGFyZSBtYWlubHkgdXNlZCBmb3IgUHJvbWlzZXMsIHdoaWxlIG1hY3JvdGFza3MgYXJlXG4gICAgICAgICAgICAvLyB1c2VkIGZvciBldmVyeXRoaW5nIGVsc2UuXG4gICAgICAgICAgICAvLyBNaWNyb3Rhc2tzIGFsd2F5cyBoYXZlIHByaW9yaXR5IG92ZXIgbWFjcm90YXNrcy4gSWYgdGhlIEpTIGVuZ2luZVxuICAgICAgICAgICAgLy8gaXMgbG9va2luZyBmb3IgYSB0YXNrIHRvIHJ1biwgaXQgd2lsbCBhbHdheXMgdHJ5IHRvIGVtcHR5IHRoZVxuICAgICAgICAgICAgLy8gbWljcm90YXNrIHF1ZXVlIGJlZm9yZSBhdHRlbXB0aW5nIHRvIHJ1biBhbnl0aGluZyBmcm9tIHRoZVxuICAgICAgICAgICAgLy8gbWFjcm90YXNrIHF1ZXVlLlxuICAgICAgICAgICAgLy9cbiAgICAgICAgICAgIC8vIEZvciB0aGUgV2ViU29ja2V0IHRyYW5zcG9ydCwgbWVzc2FnZXMgYWx3YXlzIGFycml2ZSBpbiB0aGVpciBvd25cbiAgICAgICAgICAgIC8vIGV2ZW50LiBUaGlzIG1lYW5zIHRoYXQgaWYgYW55IHByb21pc2VzIGFyZSByZXNvbHZlZCBmcm9tIHdpdGhpbixcbiAgICAgICAgICAgIC8vIHRoZWlyIGNhbGxiYWNrcyB3aWxsIGFsd2F5cyBmaW5pc2ggZXhlY3V0aW9uIGJ5IHRoZSB0aW1lIHRoZVxuICAgICAgICAgICAgLy8gbmV4dCBtZXNzYWdlIGV2ZW50IGhhbmRsZXIgaXMgcnVuLlxuICAgICAgICAgICAgLy9cbiAgICAgICAgICAgIC8vIEluIG9yZGVyIHRvIGVtdWxhdGUgdGhpcyBiZWhhdmlvdXIsIHdlIG5lZWQgdG8gbWFrZSBzdXJlIGVhY2hcbiAgICAgICAgICAgIC8vIG9ubWVzc2FnZSBoYW5kbGVyIGlzIHJ1biB3aXRoaW4gaXRzIG93biBtYWNyb3Rhc2suXG4gICAgICAgICAgICBzZXRUaW1lb3V0KCgpID0+IHRoaXMub25tZXNzYWdlKHtkYXRhOiBtc2d9KSwgMClcbiAgICAgICAgICB9KVxuICAgICAgICAgIHRoaXMucG9sbCgpXG4gICAgICAgICAgYnJlYWtcbiAgICAgICAgY2FzZSAyMDQ6XG4gICAgICAgICAgdGhpcy5wb2xsKClcbiAgICAgICAgICBicmVha1xuICAgICAgICBjYXNlIDQxMDpcbiAgICAgICAgICB0aGlzLnJlYWR5U3RhdGUgPSBTT0NLRVRfU1RBVEVTLm9wZW5cbiAgICAgICAgICB0aGlzLm9ub3Blbih7fSlcbiAgICAgICAgICB0aGlzLnBvbGwoKVxuICAgICAgICAgIGJyZWFrXG4gICAgICAgIGNhc2UgNDAzOlxuICAgICAgICAgIHRoaXMub25lcnJvcig0MDMpXG4gICAgICAgICAgdGhpcy5jbG9zZSgxMDA4LCBcImZvcmJpZGRlblwiLCBmYWxzZSlcbiAgICAgICAgICBicmVha1xuICAgICAgICBjYXNlIDA6XG4gICAgICAgIGNhc2UgNTAwOlxuICAgICAgICAgIHRoaXMub25lcnJvcig1MDApXG4gICAgICAgICAgdGhpcy5jbG9zZUFuZFJldHJ5KDEwMTEsIFwiaW50ZXJuYWwgc2VydmVyIGVycm9yXCIsIDUwMClcbiAgICAgICAgICBicmVha1xuICAgICAgICBkZWZhdWx0OiB0aHJvdyBuZXcgRXJyb3IoYHVuaGFuZGxlZCBwb2xsIHN0YXR1cyAke3N0YXR1c31gKVxuICAgICAgfVxuICAgIH0pXG4gIH1cblxuICAvLyB3ZSBjb2xsZWN0IGFsbCBwdXNoZXMgd2l0aGluIHRoZSBjdXJyZW50IGV2ZW50IGxvb3AgYnlcbiAgLy8gc2V0VGltZW91dCAwLCB3aGljaCBvcHRpbWl6ZXMgYmFjay10by1iYWNrIHByb2NlZHVyYWxcbiAgLy8gcHVzaGVzIGFnYWluc3QgYW4gZW1wdHkgYnVmZmVyXG5cbiAgc2VuZChib2R5KXtcbiAgICBpZih0eXBlb2YoYm9keSkgIT09IFwic3RyaW5nXCIpeyBib2R5ID0gYXJyYXlCdWZmZXJUb0Jhc2U2NChib2R5KSB9XG4gICAgaWYodGhpcy5jdXJyZW50QmF0Y2gpe1xuICAgICAgdGhpcy5jdXJyZW50QmF0Y2gucHVzaChib2R5KVxuICAgIH0gZWxzZSBpZih0aGlzLmF3YWl0aW5nQmF0Y2hBY2spe1xuICAgICAgdGhpcy5iYXRjaEJ1ZmZlci5wdXNoKGJvZHkpXG4gICAgfSBlbHNlIHtcbiAgICAgIHRoaXMuY3VycmVudEJhdGNoID0gW2JvZHldXG4gICAgICB0aGlzLmN1cnJlbnRCYXRjaFRpbWVyID0gc2V0VGltZW91dCgoKSA9PiB7XG4gICAgICAgIHRoaXMuYmF0Y2hTZW5kKHRoaXMuY3VycmVudEJhdGNoKVxuICAgICAgICB0aGlzLmN1cnJlbnRCYXRjaCA9IG51bGxcbiAgICAgIH0sIDApXG4gICAgfVxuICB9XG5cbiAgYmF0Y2hTZW5kKG1lc3NhZ2VzKXtcbiAgICB0aGlzLmF3YWl0aW5nQmF0Y2hBY2sgPSB0cnVlXG4gICAgdGhpcy5hamF4KFwiUE9TVFwiLCB7XCJDb250ZW50LVR5cGVcIjogXCJhcHBsaWNhdGlvbi94LW5kanNvblwifSwgbWVzc2FnZXMuam9pbihcIlxcblwiKSwgKCkgPT4gdGhpcy5vbmVycm9yKFwidGltZW91dFwiKSwgcmVzcCA9PiB7XG4gICAgICB0aGlzLmF3YWl0aW5nQmF0Y2hBY2sgPSBmYWxzZVxuICAgICAgaWYoIXJlc3AgfHwgcmVzcC5zdGF0dXMgIT09IDIwMCl7XG4gICAgICAgIHRoaXMub25lcnJvcihyZXNwICYmIHJlc3Auc3RhdHVzKVxuICAgICAgICB0aGlzLmNsb3NlQW5kUmV0cnkoMTAxMSwgXCJpbnRlcm5hbCBzZXJ2ZXIgZXJyb3JcIiwgZmFsc2UpXG4gICAgICB9IGVsc2UgaWYodGhpcy5iYXRjaEJ1ZmZlci5sZW5ndGggPiAwKXtcbiAgICAgICAgdGhpcy5iYXRjaFNlbmQodGhpcy5iYXRjaEJ1ZmZlcilcbiAgICAgICAgdGhpcy5iYXRjaEJ1ZmZlciA9IFtdXG4gICAgICB9XG4gICAgfSlcbiAgfVxuXG4gIGNsb3NlKGNvZGUsIHJlYXNvbiwgd2FzQ2xlYW4pe1xuICAgIGZvcihsZXQgcmVxIG9mIHRoaXMucmVxcyl7IHJlcS5hYm9ydCgpIH1cbiAgICB0aGlzLnJlYWR5U3RhdGUgPSBTT0NLRVRfU1RBVEVTLmNsb3NlZFxuICAgIGxldCBvcHRzID0gT2JqZWN0LmFzc2lnbih7Y29kZTogMTAwMCwgcmVhc29uOiB1bmRlZmluZWQsIHdhc0NsZWFuOiB0cnVlfSwge2NvZGUsIHJlYXNvbiwgd2FzQ2xlYW59KVxuICAgIHRoaXMuYmF0Y2hCdWZmZXIgPSBbXVxuICAgIGNsZWFyVGltZW91dCh0aGlzLmN1cnJlbnRCYXRjaFRpbWVyKVxuICAgIHRoaXMuY3VycmVudEJhdGNoVGltZXIgPSBudWxsXG4gICAgaWYodHlwZW9mKENsb3NlRXZlbnQpICE9PSBcInVuZGVmaW5lZFwiKXtcbiAgICAgIHRoaXMub25jbG9zZShuZXcgQ2xvc2VFdmVudChcImNsb3NlXCIsIG9wdHMpKVxuICAgIH0gZWxzZSB7XG4gICAgICB0aGlzLm9uY2xvc2Uob3B0cylcbiAgICB9XG4gIH1cblxuICBhamF4KG1ldGhvZCwgaGVhZGVycywgYm9keSwgb25DYWxsZXJUaW1lb3V0LCBjYWxsYmFjayl7XG4gICAgbGV0IHJlcVxuICAgIGxldCBvbnRpbWVvdXQgPSAoKSA9PiB7XG4gICAgICB0aGlzLnJlcXMuZGVsZXRlKHJlcSlcbiAgICAgIG9uQ2FsbGVyVGltZW91dCgpXG4gICAgfVxuICAgIHJlcSA9IEFqYXgucmVxdWVzdChtZXRob2QsIHRoaXMuZW5kcG9pbnRVUkwoKSwgaGVhZGVycywgYm9keSwgdGhpcy50aW1lb3V0LCBvbnRpbWVvdXQsIHJlc3AgPT4ge1xuICAgICAgdGhpcy5yZXFzLmRlbGV0ZShyZXEpXG4gICAgICBpZih0aGlzLmlzQWN0aXZlKCkpeyBjYWxsYmFjayhyZXNwKSB9XG4gICAgfSlcbiAgICB0aGlzLnJlcXMuYWRkKHJlcSlcbiAgfVxufVxuIiwgIi8qKlxuICogSW5pdGlhbGl6ZXMgdGhlIFByZXNlbmNlXG4gKiBAcGFyYW0ge0NoYW5uZWx9IGNoYW5uZWwgLSBUaGUgQ2hhbm5lbFxuICogQHBhcmFtIHtPYmplY3R9IG9wdHMgLSBUaGUgb3B0aW9ucyxcbiAqICAgICAgICBmb3IgZXhhbXBsZSBge2V2ZW50czoge3N0YXRlOiBcInN0YXRlXCIsIGRpZmY6IFwiZGlmZlwifX1gXG4gKi9cbmV4cG9ydCBkZWZhdWx0IGNsYXNzIFByZXNlbmNlIHtcblxuICBjb25zdHJ1Y3RvcihjaGFubmVsLCBvcHRzID0ge30pe1xuICAgIGxldCBldmVudHMgPSBvcHRzLmV2ZW50cyB8fCB7c3RhdGU6IFwicHJlc2VuY2Vfc3RhdGVcIiwgZGlmZjogXCJwcmVzZW5jZV9kaWZmXCJ9XG4gICAgdGhpcy5zdGF0ZSA9IHt9XG4gICAgdGhpcy5wZW5kaW5nRGlmZnMgPSBbXVxuICAgIHRoaXMuY2hhbm5lbCA9IGNoYW5uZWxcbiAgICB0aGlzLmpvaW5SZWYgPSBudWxsXG4gICAgdGhpcy5jYWxsZXIgPSB7XG4gICAgICBvbkpvaW46IGZ1bmN0aW9uICgpeyB9LFxuICAgICAgb25MZWF2ZTogZnVuY3Rpb24gKCl7IH0sXG4gICAgICBvblN5bmM6IGZ1bmN0aW9uICgpeyB9XG4gICAgfVxuXG4gICAgdGhpcy5jaGFubmVsLm9uKGV2ZW50cy5zdGF0ZSwgbmV3U3RhdGUgPT4ge1xuICAgICAgbGV0IHtvbkpvaW4sIG9uTGVhdmUsIG9uU3luY30gPSB0aGlzLmNhbGxlclxuXG4gICAgICB0aGlzLmpvaW5SZWYgPSB0aGlzLmNoYW5uZWwuam9pblJlZigpXG4gICAgICB0aGlzLnN0YXRlID0gUHJlc2VuY2Uuc3luY1N0YXRlKHRoaXMuc3RhdGUsIG5ld1N0YXRlLCBvbkpvaW4sIG9uTGVhdmUpXG5cbiAgICAgIHRoaXMucGVuZGluZ0RpZmZzLmZvckVhY2goZGlmZiA9PiB7XG4gICAgICAgIHRoaXMuc3RhdGUgPSBQcmVzZW5jZS5zeW5jRGlmZih0aGlzLnN0YXRlLCBkaWZmLCBvbkpvaW4sIG9uTGVhdmUpXG4gICAgICB9KVxuICAgICAgdGhpcy5wZW5kaW5nRGlmZnMgPSBbXVxuICAgICAgb25TeW5jKClcbiAgICB9KVxuXG4gICAgdGhpcy5jaGFubmVsLm9uKGV2ZW50cy5kaWZmLCBkaWZmID0+IHtcbiAgICAgIGxldCB7b25Kb2luLCBvbkxlYXZlLCBvblN5bmN9ID0gdGhpcy5jYWxsZXJcblxuICAgICAgaWYodGhpcy5pblBlbmRpbmdTeW5jU3RhdGUoKSl7XG4gICAgICAgIHRoaXMucGVuZGluZ0RpZmZzLnB1c2goZGlmZilcbiAgICAgIH0gZWxzZSB7XG4gICAgICAgIHRoaXMuc3RhdGUgPSBQcmVzZW5jZS5zeW5jRGlmZih0aGlzLnN0YXRlLCBkaWZmLCBvbkpvaW4sIG9uTGVhdmUpXG4gICAgICAgIG9uU3luYygpXG4gICAgICB9XG4gICAgfSlcbiAgfVxuXG4gIG9uSm9pbihjYWxsYmFjayl7IHRoaXMuY2FsbGVyLm9uSm9pbiA9IGNhbGxiYWNrIH1cblxuICBvbkxlYXZlKGNhbGxiYWNrKXsgdGhpcy5jYWxsZXIub25MZWF2ZSA9IGNhbGxiYWNrIH1cblxuICBvblN5bmMoY2FsbGJhY2speyB0aGlzLmNhbGxlci5vblN5bmMgPSBjYWxsYmFjayB9XG5cbiAgbGlzdChieSl7IHJldHVybiBQcmVzZW5jZS5saXN0KHRoaXMuc3RhdGUsIGJ5KSB9XG5cbiAgaW5QZW5kaW5nU3luY1N0YXRlKCl7XG4gICAgcmV0dXJuICF0aGlzLmpvaW5SZWYgfHwgKHRoaXMuam9pblJlZiAhPT0gdGhpcy5jaGFubmVsLmpvaW5SZWYoKSlcbiAgfVxuXG4gIC8vIGxvd2VyLWxldmVsIHB1YmxpYyBzdGF0aWMgQVBJXG5cbiAgLyoqXG4gICAqIFVzZWQgdG8gc3luYyB0aGUgbGlzdCBvZiBwcmVzZW5jZXMgb24gdGhlIHNlcnZlclxuICAgKiB3aXRoIHRoZSBjbGllbnQncyBzdGF0ZS4gQW4gb3B0aW9uYWwgYG9uSm9pbmAgYW5kIGBvbkxlYXZlYCBjYWxsYmFjayBjYW5cbiAgICogYmUgcHJvdmlkZWQgdG8gcmVhY3QgdG8gY2hhbmdlcyBpbiB0aGUgY2xpZW50J3MgbG9jYWwgcHJlc2VuY2VzIGFjcm9zc1xuICAgKiBkaXNjb25uZWN0cyBhbmQgcmVjb25uZWN0cyB3aXRoIHRoZSBzZXJ2ZXIuXG4gICAqXG4gICAqIEByZXR1cm5zIHtQcmVzZW5jZX1cbiAgICovXG4gIHN0YXRpYyBzeW5jU3RhdGUoY3VycmVudFN0YXRlLCBuZXdTdGF0ZSwgb25Kb2luLCBvbkxlYXZlKXtcbiAgICBsZXQgc3RhdGUgPSB0aGlzLmNsb25lKGN1cnJlbnRTdGF0ZSlcbiAgICBsZXQgam9pbnMgPSB7fVxuICAgIGxldCBsZWF2ZXMgPSB7fVxuXG4gICAgdGhpcy5tYXAoc3RhdGUsIChrZXksIHByZXNlbmNlKSA9PiB7XG4gICAgICBpZighbmV3U3RhdGVba2V5XSl7XG4gICAgICAgIGxlYXZlc1trZXldID0gcHJlc2VuY2VcbiAgICAgIH1cbiAgICB9KVxuICAgIHRoaXMubWFwKG5ld1N0YXRlLCAoa2V5LCBuZXdQcmVzZW5jZSkgPT4ge1xuICAgICAgbGV0IGN1cnJlbnRQcmVzZW5jZSA9IHN0YXRlW2tleV1cbiAgICAgIGlmKGN1cnJlbnRQcmVzZW5jZSl7XG4gICAgICAgIGxldCBuZXdSZWZzID0gbmV3UHJlc2VuY2UubWV0YXMubWFwKG0gPT4gbS5waHhfcmVmKVxuICAgICAgICBsZXQgY3VyUmVmcyA9IGN1cnJlbnRQcmVzZW5jZS5tZXRhcy5tYXAobSA9PiBtLnBoeF9yZWYpXG4gICAgICAgIGxldCBqb2luZWRNZXRhcyA9IG5ld1ByZXNlbmNlLm1ldGFzLmZpbHRlcihtID0+IGN1clJlZnMuaW5kZXhPZihtLnBoeF9yZWYpIDwgMClcbiAgICAgICAgbGV0IGxlZnRNZXRhcyA9IGN1cnJlbnRQcmVzZW5jZS5tZXRhcy5maWx0ZXIobSA9PiBuZXdSZWZzLmluZGV4T2YobS5waHhfcmVmKSA8IDApXG4gICAgICAgIGlmKGpvaW5lZE1ldGFzLmxlbmd0aCA+IDApe1xuICAgICAgICAgIGpvaW5zW2tleV0gPSBuZXdQcmVzZW5jZVxuICAgICAgICAgIGpvaW5zW2tleV0ubWV0YXMgPSBqb2luZWRNZXRhc1xuICAgICAgICB9XG4gICAgICAgIGlmKGxlZnRNZXRhcy5sZW5ndGggPiAwKXtcbiAgICAgICAgICBsZWF2ZXNba2V5XSA9IHRoaXMuY2xvbmUoY3VycmVudFByZXNlbmNlKVxuICAgICAgICAgIGxlYXZlc1trZXldLm1ldGFzID0gbGVmdE1ldGFzXG4gICAgICAgIH1cbiAgICAgIH0gZWxzZSB7XG4gICAgICAgIGpvaW5zW2tleV0gPSBuZXdQcmVzZW5jZVxuICAgICAgfVxuICAgIH0pXG4gICAgcmV0dXJuIHRoaXMuc3luY0RpZmYoc3RhdGUsIHtqb2luczogam9pbnMsIGxlYXZlczogbGVhdmVzfSwgb25Kb2luLCBvbkxlYXZlKVxuICB9XG5cbiAgLyoqXG4gICAqXG4gICAqIFVzZWQgdG8gc3luYyBhIGRpZmYgb2YgcHJlc2VuY2Ugam9pbiBhbmQgbGVhdmVcbiAgICogZXZlbnRzIGZyb20gdGhlIHNlcnZlciwgYXMgdGhleSBoYXBwZW4uIExpa2UgYHN5bmNTdGF0ZWAsIGBzeW5jRGlmZmBcbiAgICogYWNjZXB0cyBvcHRpb25hbCBgb25Kb2luYCBhbmQgYG9uTGVhdmVgIGNhbGxiYWNrcyB0byByZWFjdCB0byBhIHVzZXJcbiAgICogam9pbmluZyBvciBsZWF2aW5nIGZyb20gYSBkZXZpY2UuXG4gICAqXG4gICAqIEByZXR1cm5zIHtQcmVzZW5jZX1cbiAgICovXG4gIHN0YXRpYyBzeW5jRGlmZihzdGF0ZSwgZGlmZiwgb25Kb2luLCBvbkxlYXZlKXtcbiAgICBsZXQge2pvaW5zLCBsZWF2ZXN9ID0gdGhpcy5jbG9uZShkaWZmKVxuICAgIGlmKCFvbkpvaW4peyBvbkpvaW4gPSBmdW5jdGlvbiAoKXsgfSB9XG4gICAgaWYoIW9uTGVhdmUpeyBvbkxlYXZlID0gZnVuY3Rpb24gKCl7IH0gfVxuXG4gICAgdGhpcy5tYXAoam9pbnMsIChrZXksIG5ld1ByZXNlbmNlKSA9PiB7XG4gICAgICBsZXQgY3VycmVudFByZXNlbmNlID0gc3RhdGVba2V5XVxuICAgICAgc3RhdGVba2V5XSA9IHRoaXMuY2xvbmUobmV3UHJlc2VuY2UpXG4gICAgICBpZihjdXJyZW50UHJlc2VuY2Upe1xuICAgICAgICBsZXQgam9pbmVkUmVmcyA9IHN0YXRlW2tleV0ubWV0YXMubWFwKG0gPT4gbS5waHhfcmVmKVxuICAgICAgICBsZXQgY3VyTWV0YXMgPSBjdXJyZW50UHJlc2VuY2UubWV0YXMuZmlsdGVyKG0gPT4gam9pbmVkUmVmcy5pbmRleE9mKG0ucGh4X3JlZikgPCAwKVxuICAgICAgICBzdGF0ZVtrZXldLm1ldGFzLnVuc2hpZnQoLi4uY3VyTWV0YXMpXG4gICAgICB9XG4gICAgICBvbkpvaW4oa2V5LCBjdXJyZW50UHJlc2VuY2UsIG5ld1ByZXNlbmNlKVxuICAgIH0pXG4gICAgdGhpcy5tYXAobGVhdmVzLCAoa2V5LCBsZWZ0UHJlc2VuY2UpID0+IHtcbiAgICAgIGxldCBjdXJyZW50UHJlc2VuY2UgPSBzdGF0ZVtrZXldXG4gICAgICBpZighY3VycmVudFByZXNlbmNlKXsgcmV0dXJuIH1cbiAgICAgIGxldCByZWZzVG9SZW1vdmUgPSBsZWZ0UHJlc2VuY2UubWV0YXMubWFwKG0gPT4gbS5waHhfcmVmKVxuICAgICAgY3VycmVudFByZXNlbmNlLm1ldGFzID0gY3VycmVudFByZXNlbmNlLm1ldGFzLmZpbHRlcihwID0+IHtcbiAgICAgICAgcmV0dXJuIHJlZnNUb1JlbW92ZS5pbmRleE9mKHAucGh4X3JlZikgPCAwXG4gICAgICB9KVxuICAgICAgb25MZWF2ZShrZXksIGN1cnJlbnRQcmVzZW5jZSwgbGVmdFByZXNlbmNlKVxuICAgICAgaWYoY3VycmVudFByZXNlbmNlLm1ldGFzLmxlbmd0aCA9PT0gMCl7XG4gICAgICAgIGRlbGV0ZSBzdGF0ZVtrZXldXG4gICAgICB9XG4gICAgfSlcbiAgICByZXR1cm4gc3RhdGVcbiAgfVxuXG4gIC8qKlxuICAgKiBSZXR1cm5zIHRoZSBhcnJheSBvZiBwcmVzZW5jZXMsIHdpdGggc2VsZWN0ZWQgbWV0YWRhdGEuXG4gICAqXG4gICAqIEBwYXJhbSB7T2JqZWN0fSBwcmVzZW5jZXNcbiAgICogQHBhcmFtIHtGdW5jdGlvbn0gY2hvb3NlclxuICAgKlxuICAgKiBAcmV0dXJucyB7UHJlc2VuY2V9XG4gICAqL1xuICBzdGF0aWMgbGlzdChwcmVzZW5jZXMsIGNob29zZXIpe1xuICAgIGlmKCFjaG9vc2VyKXsgY2hvb3NlciA9IGZ1bmN0aW9uIChrZXksIHByZXMpeyByZXR1cm4gcHJlcyB9IH1cblxuICAgIHJldHVybiB0aGlzLm1hcChwcmVzZW5jZXMsIChrZXksIHByZXNlbmNlKSA9PiB7XG4gICAgICByZXR1cm4gY2hvb3NlcihrZXksIHByZXNlbmNlKVxuICAgIH0pXG4gIH1cblxuICAvLyBwcml2YXRlXG5cbiAgc3RhdGljIG1hcChvYmosIGZ1bmMpe1xuICAgIHJldHVybiBPYmplY3QuZ2V0T3duUHJvcGVydHlOYW1lcyhvYmopLm1hcChrZXkgPT4gZnVuYyhrZXksIG9ialtrZXldKSlcbiAgfVxuXG4gIHN0YXRpYyBjbG9uZShvYmopeyByZXR1cm4gSlNPTi5wYXJzZShKU09OLnN0cmluZ2lmeShvYmopKSB9XG59XG4iLCAiLyogVGhlIGRlZmF1bHQgc2VyaWFsaXplciBmb3IgZW5jb2RpbmcgYW5kIGRlY29kaW5nIG1lc3NhZ2VzICovXG5pbXBvcnQge1xuICBDSEFOTkVMX0VWRU5UU1xufSBmcm9tIFwiLi9jb25zdGFudHNcIlxuXG5leHBvcnQgZGVmYXVsdCB7XG4gIEhFQURFUl9MRU5HVEg6IDEsXG4gIE1FVEFfTEVOR1RIOiA0LFxuICBLSU5EUzoge3B1c2g6IDAsIHJlcGx5OiAxLCBicm9hZGNhc3Q6IDJ9LFxuXG4gIGVuY29kZShtc2csIGNhbGxiYWNrKXtcbiAgICBpZihtc2cucGF5bG9hZC5jb25zdHJ1Y3RvciA9PT0gQXJyYXlCdWZmZXIpe1xuICAgICAgcmV0dXJuIGNhbGxiYWNrKHRoaXMuYmluYXJ5RW5jb2RlKG1zZykpXG4gICAgfSBlbHNlIHtcbiAgICAgIGxldCBwYXlsb2FkID0gW21zZy5qb2luX3JlZiwgbXNnLnJlZiwgbXNnLnRvcGljLCBtc2cuZXZlbnQsIG1zZy5wYXlsb2FkXVxuICAgICAgcmV0dXJuIGNhbGxiYWNrKEpTT04uc3RyaW5naWZ5KHBheWxvYWQpKVxuICAgIH1cbiAgfSxcblxuICBkZWNvZGUocmF3UGF5bG9hZCwgY2FsbGJhY2spe1xuICAgIGlmKHJhd1BheWxvYWQuY29uc3RydWN0b3IgPT09IEFycmF5QnVmZmVyKXtcbiAgICAgIHJldHVybiBjYWxsYmFjayh0aGlzLmJpbmFyeURlY29kZShyYXdQYXlsb2FkKSlcbiAgICB9IGVsc2Uge1xuICAgICAgbGV0IFtqb2luX3JlZiwgcmVmLCB0b3BpYywgZXZlbnQsIHBheWxvYWRdID0gSlNPTi5wYXJzZShyYXdQYXlsb2FkKVxuICAgICAgcmV0dXJuIGNhbGxiYWNrKHtqb2luX3JlZiwgcmVmLCB0b3BpYywgZXZlbnQsIHBheWxvYWR9KVxuICAgIH1cbiAgfSxcblxuICAvLyBwcml2YXRlXG5cbiAgYmluYXJ5RW5jb2RlKG1lc3NhZ2Upe1xuICAgIGxldCB7am9pbl9yZWYsIHJlZiwgZXZlbnQsIHRvcGljLCBwYXlsb2FkfSA9IG1lc3NhZ2VcbiAgICBsZXQgbWV0YUxlbmd0aCA9IHRoaXMuTUVUQV9MRU5HVEggKyBqb2luX3JlZi5sZW5ndGggKyByZWYubGVuZ3RoICsgdG9waWMubGVuZ3RoICsgZXZlbnQubGVuZ3RoXG4gICAgbGV0IGhlYWRlciA9IG5ldyBBcnJheUJ1ZmZlcih0aGlzLkhFQURFUl9MRU5HVEggKyBtZXRhTGVuZ3RoKVxuICAgIGxldCB2aWV3ID0gbmV3IERhdGFWaWV3KGhlYWRlcilcbiAgICBsZXQgb2Zmc2V0ID0gMFxuXG4gICAgdmlldy5zZXRVaW50OChvZmZzZXQrKywgdGhpcy5LSU5EUy5wdXNoKSAvLyBraW5kXG4gICAgdmlldy5zZXRVaW50OChvZmZzZXQrKywgam9pbl9yZWYubGVuZ3RoKVxuICAgIHZpZXcuc2V0VWludDgob2Zmc2V0KyssIHJlZi5sZW5ndGgpXG4gICAgdmlldy5zZXRVaW50OChvZmZzZXQrKywgdG9waWMubGVuZ3RoKVxuICAgIHZpZXcuc2V0VWludDgob2Zmc2V0KyssIGV2ZW50Lmxlbmd0aClcbiAgICBBcnJheS5mcm9tKGpvaW5fcmVmLCBjaGFyID0+IHZpZXcuc2V0VWludDgob2Zmc2V0KyssIGNoYXIuY2hhckNvZGVBdCgwKSkpXG4gICAgQXJyYXkuZnJvbShyZWYsIGNoYXIgPT4gdmlldy5zZXRVaW50OChvZmZzZXQrKywgY2hhci5jaGFyQ29kZUF0KDApKSlcbiAgICBBcnJheS5mcm9tKHRvcGljLCBjaGFyID0+IHZpZXcuc2V0VWludDgob2Zmc2V0KyssIGNoYXIuY2hhckNvZGVBdCgwKSkpXG4gICAgQXJyYXkuZnJvbShldmVudCwgY2hhciA9PiB2aWV3LnNldFVpbnQ4KG9mZnNldCsrLCBjaGFyLmNoYXJDb2RlQXQoMCkpKVxuXG4gICAgdmFyIGNvbWJpbmVkID0gbmV3IFVpbnQ4QXJyYXkoaGVhZGVyLmJ5dGVMZW5ndGggKyBwYXlsb2FkLmJ5dGVMZW5ndGgpXG4gICAgY29tYmluZWQuc2V0KG5ldyBVaW50OEFycmF5KGhlYWRlciksIDApXG4gICAgY29tYmluZWQuc2V0KG5ldyBVaW50OEFycmF5KHBheWxvYWQpLCBoZWFkZXIuYnl0ZUxlbmd0aClcblxuICAgIHJldHVybiBjb21iaW5lZC5idWZmZXJcbiAgfSxcblxuICBiaW5hcnlEZWNvZGUoYnVmZmVyKXtcbiAgICBsZXQgdmlldyA9IG5ldyBEYXRhVmlldyhidWZmZXIpXG4gICAgbGV0IGtpbmQgPSB2aWV3LmdldFVpbnQ4KDApXG4gICAgbGV0IGRlY29kZXIgPSBuZXcgVGV4dERlY29kZXIoKVxuICAgIHN3aXRjaChraW5kKXtcbiAgICAgIGNhc2UgdGhpcy5LSU5EUy5wdXNoOiByZXR1cm4gdGhpcy5kZWNvZGVQdXNoKGJ1ZmZlciwgdmlldywgZGVjb2RlcilcbiAgICAgIGNhc2UgdGhpcy5LSU5EUy5yZXBseTogcmV0dXJuIHRoaXMuZGVjb2RlUmVwbHkoYnVmZmVyLCB2aWV3LCBkZWNvZGVyKVxuICAgICAgY2FzZSB0aGlzLktJTkRTLmJyb2FkY2FzdDogcmV0dXJuIHRoaXMuZGVjb2RlQnJvYWRjYXN0KGJ1ZmZlciwgdmlldywgZGVjb2RlcilcbiAgICB9XG4gIH0sXG5cbiAgZGVjb2RlUHVzaChidWZmZXIsIHZpZXcsIGRlY29kZXIpe1xuICAgIGxldCBqb2luUmVmU2l6ZSA9IHZpZXcuZ2V0VWludDgoMSlcbiAgICBsZXQgdG9waWNTaXplID0gdmlldy5nZXRVaW50OCgyKVxuICAgIGxldCBldmVudFNpemUgPSB2aWV3LmdldFVpbnQ4KDMpXG4gICAgbGV0IG9mZnNldCA9IHRoaXMuSEVBREVSX0xFTkdUSCArIHRoaXMuTUVUQV9MRU5HVEggLSAxIC8vIHB1c2hlcyBoYXZlIG5vIHJlZlxuICAgIGxldCBqb2luUmVmID0gZGVjb2Rlci5kZWNvZGUoYnVmZmVyLnNsaWNlKG9mZnNldCwgb2Zmc2V0ICsgam9pblJlZlNpemUpKVxuICAgIG9mZnNldCA9IG9mZnNldCArIGpvaW5SZWZTaXplXG4gICAgbGV0IHRvcGljID0gZGVjb2Rlci5kZWNvZGUoYnVmZmVyLnNsaWNlKG9mZnNldCwgb2Zmc2V0ICsgdG9waWNTaXplKSlcbiAgICBvZmZzZXQgPSBvZmZzZXQgKyB0b3BpY1NpemVcbiAgICBsZXQgZXZlbnQgPSBkZWNvZGVyLmRlY29kZShidWZmZXIuc2xpY2Uob2Zmc2V0LCBvZmZzZXQgKyBldmVudFNpemUpKVxuICAgIG9mZnNldCA9IG9mZnNldCArIGV2ZW50U2l6ZVxuICAgIGxldCBkYXRhID0gYnVmZmVyLnNsaWNlKG9mZnNldCwgYnVmZmVyLmJ5dGVMZW5ndGgpXG4gICAgcmV0dXJuIHtqb2luX3JlZjogam9pblJlZiwgcmVmOiBudWxsLCB0b3BpYzogdG9waWMsIGV2ZW50OiBldmVudCwgcGF5bG9hZDogZGF0YX1cbiAgfSxcblxuICBkZWNvZGVSZXBseShidWZmZXIsIHZpZXcsIGRlY29kZXIpe1xuICAgIGxldCBqb2luUmVmU2l6ZSA9IHZpZXcuZ2V0VWludDgoMSlcbiAgICBsZXQgcmVmU2l6ZSA9IHZpZXcuZ2V0VWludDgoMilcbiAgICBsZXQgdG9waWNTaXplID0gdmlldy5nZXRVaW50OCgzKVxuICAgIGxldCBldmVudFNpemUgPSB2aWV3LmdldFVpbnQ4KDQpXG4gICAgbGV0IG9mZnNldCA9IHRoaXMuSEVBREVSX0xFTkdUSCArIHRoaXMuTUVUQV9MRU5HVEhcbiAgICBsZXQgam9pblJlZiA9IGRlY29kZXIuZGVjb2RlKGJ1ZmZlci5zbGljZShvZmZzZXQsIG9mZnNldCArIGpvaW5SZWZTaXplKSlcbiAgICBvZmZzZXQgPSBvZmZzZXQgKyBqb2luUmVmU2l6ZVxuICAgIGxldCByZWYgPSBkZWNvZGVyLmRlY29kZShidWZmZXIuc2xpY2Uob2Zmc2V0LCBvZmZzZXQgKyByZWZTaXplKSlcbiAgICBvZmZzZXQgPSBvZmZzZXQgKyByZWZTaXplXG4gICAgbGV0IHRvcGljID0gZGVjb2Rlci5kZWNvZGUoYnVmZmVyLnNsaWNlKG9mZnNldCwgb2Zmc2V0ICsgdG9waWNTaXplKSlcbiAgICBvZmZzZXQgPSBvZmZzZXQgKyB0b3BpY1NpemVcbiAgICBsZXQgZXZlbnQgPSBkZWNvZGVyLmRlY29kZShidWZmZXIuc2xpY2Uob2Zmc2V0LCBvZmZzZXQgKyBldmVudFNpemUpKVxuICAgIG9mZnNldCA9IG9mZnNldCArIGV2ZW50U2l6ZVxuICAgIGxldCBkYXRhID0gYnVmZmVyLnNsaWNlKG9mZnNldCwgYnVmZmVyLmJ5dGVMZW5ndGgpXG4gICAgbGV0IHBheWxvYWQgPSB7c3RhdHVzOiBldmVudCwgcmVzcG9uc2U6IGRhdGF9XG4gICAgcmV0dXJuIHtqb2luX3JlZjogam9pblJlZiwgcmVmOiByZWYsIHRvcGljOiB0b3BpYywgZXZlbnQ6IENIQU5ORUxfRVZFTlRTLnJlcGx5LCBwYXlsb2FkOiBwYXlsb2FkfVxuICB9LFxuXG4gIGRlY29kZUJyb2FkY2FzdChidWZmZXIsIHZpZXcsIGRlY29kZXIpe1xuICAgIGxldCB0b3BpY1NpemUgPSB2aWV3LmdldFVpbnQ4KDEpXG4gICAgbGV0IGV2ZW50U2l6ZSA9IHZpZXcuZ2V0VWludDgoMilcbiAgICBsZXQgb2Zmc2V0ID0gdGhpcy5IRUFERVJfTEVOR1RIICsgMlxuICAgIGxldCB0b3BpYyA9IGRlY29kZXIuZGVjb2RlKGJ1ZmZlci5zbGljZShvZmZzZXQsIG9mZnNldCArIHRvcGljU2l6ZSkpXG4gICAgb2Zmc2V0ID0gb2Zmc2V0ICsgdG9waWNTaXplXG4gICAgbGV0IGV2ZW50ID0gZGVjb2Rlci5kZWNvZGUoYnVmZmVyLnNsaWNlKG9mZnNldCwgb2Zmc2V0ICsgZXZlbnRTaXplKSlcbiAgICBvZmZzZXQgPSBvZmZzZXQgKyBldmVudFNpemVcbiAgICBsZXQgZGF0YSA9IGJ1ZmZlci5zbGljZShvZmZzZXQsIGJ1ZmZlci5ieXRlTGVuZ3RoKVxuXG4gICAgcmV0dXJuIHtqb2luX3JlZjogbnVsbCwgcmVmOiBudWxsLCB0b3BpYzogdG9waWMsIGV2ZW50OiBldmVudCwgcGF5bG9hZDogZGF0YX1cbiAgfVxufVxuIiwgImltcG9ydCB7XG4gIGdsb2JhbCxcbiAgcGh4V2luZG93LFxuICBDSEFOTkVMX0VWRU5UUyxcbiAgREVGQVVMVF9USU1FT1VULFxuICBERUZBVUxUX1ZTTixcbiAgU09DS0VUX1NUQVRFUyxcbiAgVFJBTlNQT1JUUyxcbiAgV1NfQ0xPU0VfTk9STUFMLFxuICBBVVRIX1RPS0VOX1BSRUZJWFxufSBmcm9tIFwiLi9jb25zdGFudHNcIlxuXG5pbXBvcnQge1xuICBjbG9zdXJlXG59IGZyb20gXCIuL3V0aWxzXCJcblxuaW1wb3J0IEFqYXggZnJvbSBcIi4vYWpheFwiXG5pbXBvcnQgQ2hhbm5lbCBmcm9tIFwiLi9jaGFubmVsXCJcbmltcG9ydCBMb25nUG9sbCBmcm9tIFwiLi9sb25ncG9sbFwiXG5pbXBvcnQgU2VyaWFsaXplciBmcm9tIFwiLi9zZXJpYWxpemVyXCJcbmltcG9ydCBUaW1lciBmcm9tIFwiLi90aW1lclwiXG5cbi8qKiBJbml0aWFsaXplcyB0aGUgU29ja2V0ICpcbiAqXG4gKiBGb3IgSUU4IHN1cHBvcnQgdXNlIGFuIEVTNS1zaGltIChodHRwczovL2dpdGh1Yi5jb20vZXMtc2hpbXMvZXM1LXNoaW0pXG4gKlxuICogQHBhcmFtIHtzdHJpbmd9IGVuZFBvaW50IC0gVGhlIHN0cmluZyBXZWJTb2NrZXQgZW5kcG9pbnQsIGllLCBgXCJ3czovL2V4YW1wbGUuY29tL3NvY2tldFwiYCxcbiAqICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBgXCJ3c3M6Ly9leGFtcGxlLmNvbVwiYFxuICogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGBcIi9zb2NrZXRcImAgKGluaGVyaXRlZCBob3N0ICYgcHJvdG9jb2wpXG4gKiBAcGFyYW0ge09iamVjdH0gW29wdHNdIC0gT3B0aW9uYWwgY29uZmlndXJhdGlvblxuICogQHBhcmFtIHtGdW5jdGlvbn0gW29wdHMudHJhbnNwb3J0XSAtIFRoZSBXZWJzb2NrZXQgVHJhbnNwb3J0LCBmb3IgZXhhbXBsZSBXZWJTb2NrZXQgb3IgUGhvZW5peC5Mb25nUG9sbC5cbiAqXG4gKiBEZWZhdWx0cyB0byBXZWJTb2NrZXQgd2l0aCBhdXRvbWF0aWMgTG9uZ1BvbGwgZmFsbGJhY2sgaWYgV2ViU29ja2V0IGlzIG5vdCBkZWZpbmVkLlxuICogVG8gZmFsbGJhY2sgdG8gTG9uZ1BvbGwgd2hlbiBXZWJTb2NrZXQgYXR0ZW1wdHMgZmFpbCwgdXNlIGBsb25nUG9sbEZhbGxiYWNrTXM6IDI1MDBgLlxuICpcbiAqIEBwYXJhbSB7bnVtYmVyfSBbb3B0cy5sb25nUG9sbEZhbGxiYWNrTXNdIC0gVGhlIG1pbGxpc2Vjb25kIHRpbWUgdG8gYXR0ZW1wdCB0aGUgcHJpbWFyeSB0cmFuc3BvcnRcbiAqIGJlZm9yZSBmYWxsaW5nIGJhY2sgdG8gdGhlIExvbmdQb2xsIHRyYW5zcG9ydC4gRGlzYWJsZWQgYnkgZGVmYXVsdC5cbiAqXG4gKiBAcGFyYW0ge2Jvb2xlYW59IFtvcHRzLmRlYnVnXSAtIFdoZW4gdHJ1ZSwgZW5hYmxlcyBkZWJ1ZyBsb2dnaW5nLiBEZWZhdWx0IGZhbHNlLlxuICpcbiAqIEBwYXJhbSB7RnVuY3Rpb259IFtvcHRzLmVuY29kZV0gLSBUaGUgZnVuY3Rpb24gdG8gZW5jb2RlIG91dGdvaW5nIG1lc3NhZ2VzLlxuICpcbiAqIERlZmF1bHRzIHRvIEpTT04gZW5jb2Rlci5cbiAqXG4gKiBAcGFyYW0ge0Z1bmN0aW9ufSBbb3B0cy5kZWNvZGVdIC0gVGhlIGZ1bmN0aW9uIHRvIGRlY29kZSBpbmNvbWluZyBtZXNzYWdlcy5cbiAqXG4gKiBEZWZhdWx0cyB0byBKU09OOlxuICpcbiAqIGBgYGphdmFzY3JpcHRcbiAqIChwYXlsb2FkLCBjYWxsYmFjaykgPT4gY2FsbGJhY2soSlNPTi5wYXJzZShwYXlsb2FkKSlcbiAqIGBgYFxuICpcbiAqIEBwYXJhbSB7bnVtYmVyfSBbb3B0cy50aW1lb3V0XSAtIFRoZSBkZWZhdWx0IHRpbWVvdXQgaW4gbWlsbGlzZWNvbmRzIHRvIHRyaWdnZXIgcHVzaCB0aW1lb3V0cy5cbiAqXG4gKiBEZWZhdWx0cyBgREVGQVVMVF9USU1FT1VUYFxuICogQHBhcmFtIHtudW1iZXJ9IFtvcHRzLmhlYXJ0YmVhdEludGVydmFsTXNdIC0gVGhlIG1pbGxpc2VjIGludGVydmFsIHRvIHNlbmQgYSBoZWFydGJlYXQgbWVzc2FnZVxuICogQHBhcmFtIHtGdW5jdGlvbn0gW29wdHMucmVjb25uZWN0QWZ0ZXJNc10gLSBUaGUgb3B0aW9uYWwgZnVuY3Rpb24gdGhhdCByZXR1cm5zIHRoZVxuICogc29ja2V0IHJlY29ubmVjdCBpbnRlcnZhbCwgaW4gbWlsbGlzZWNvbmRzLlxuICpcbiAqIERlZmF1bHRzIHRvIHN0ZXBwZWQgYmFja29mZiBvZjpcbiAqXG4gKiBgYGBqYXZhc2NyaXB0XG4gKiBmdW5jdGlvbih0cmllcyl7XG4gKiAgIHJldHVybiBbMTAsIDUwLCAxMDAsIDE1MCwgMjAwLCAyNTAsIDUwMCwgMTAwMCwgMjAwMF1bdHJpZXMgLSAxXSB8fCA1MDAwXG4gKiB9XG4gKiBgYGBgXG4gKlxuICogQHBhcmFtIHtGdW5jdGlvbn0gW29wdHMucmVqb2luQWZ0ZXJNc10gLSBUaGUgb3B0aW9uYWwgZnVuY3Rpb24gdGhhdCByZXR1cm5zIHRoZSBtaWxsaXNlY1xuICogcmVqb2luIGludGVydmFsIGZvciBpbmRpdmlkdWFsIGNoYW5uZWxzLlxuICpcbiAqIGBgYGphdmFzY3JpcHRcbiAqIGZ1bmN0aW9uKHRyaWVzKXtcbiAqICAgcmV0dXJuIFsxMDAwLCAyMDAwLCA1MDAwXVt0cmllcyAtIDFdIHx8IDEwMDAwXG4gKiB9XG4gKiBgYGBgXG4gKlxuICogQHBhcmFtIHtGdW5jdGlvbn0gW29wdHMubG9nZ2VyXSAtIFRoZSBvcHRpb25hbCBmdW5jdGlvbiBmb3Igc3BlY2lhbGl6ZWQgbG9nZ2luZywgaWU6XG4gKlxuICogYGBgamF2YXNjcmlwdFxuICogZnVuY3Rpb24oa2luZCwgbXNnLCBkYXRhKSB7XG4gKiAgIGNvbnNvbGUubG9nKGAke2tpbmR9OiAke21zZ31gLCBkYXRhKVxuICogfVxuICogYGBgXG4gKlxuICogQHBhcmFtIHtudW1iZXJ9IFtvcHRzLmxvbmdwb2xsZXJUaW1lb3V0XSAtIFRoZSBtYXhpbXVtIHRpbWVvdXQgb2YgYSBsb25nIHBvbGwgQUpBWCByZXF1ZXN0LlxuICpcbiAqIERlZmF1bHRzIHRvIDIwcyAoZG91YmxlIHRoZSBzZXJ2ZXIgbG9uZyBwb2xsIHRpbWVyKS5cbiAqXG4gKiBAcGFyYW0geyhPYmplY3R8ZnVuY3Rpb24pfSBbb3B0cy5wYXJhbXNdIC0gVGhlIG9wdGlvbmFsIHBhcmFtcyB0byBwYXNzIHdoZW4gY29ubmVjdGluZ1xuICogQHBhcmFtIHtzdHJpbmd9IFtvcHRzLmF1dGhUb2tlbl0gLSB0aGUgb3B0aW9uYWwgYXV0aGVudGljYXRpb24gdG9rZW4gdG8gYmUgZXhwb3NlZCBvbiB0aGUgc2VydmVyXG4gKiB1bmRlciB0aGUgYDphdXRoX3Rva2VuYCBjb25uZWN0X2luZm8ga2V5LlxuICogQHBhcmFtIHtzdHJpbmd9IFtvcHRzLmJpbmFyeVR5cGVdIC0gVGhlIGJpbmFyeSB0eXBlIHRvIHVzZSBmb3IgYmluYXJ5IFdlYlNvY2tldCBmcmFtZXMuXG4gKlxuICogRGVmYXVsdHMgdG8gXCJhcnJheWJ1ZmZlclwiXG4gKlxuICogQHBhcmFtIHt2c259IFtvcHRzLnZzbl0gLSBUaGUgc2VyaWFsaXplcidzIHByb3RvY29sIHZlcnNpb24gdG8gc2VuZCBvbiBjb25uZWN0LlxuICpcbiAqIERlZmF1bHRzIHRvIERFRkFVTFRfVlNOLlxuICpcbiAqIEBwYXJhbSB7T2JqZWN0fSBbb3B0cy5zZXNzaW9uU3RvcmFnZV0gLSBBbiBvcHRpb25hbCBTdG9yYWdlIGNvbXBhdGlibGUgb2JqZWN0XG4gKiBQaG9lbml4IHVzZXMgc2Vzc2lvblN0b3JhZ2UgZm9yIGxvbmdwb2xsIGZhbGxiYWNrIGhpc3RvcnkuIE92ZXJyaWRpbmcgdGhlIHN0b3JlIGlzXG4gKiB1c2VmdWwgd2hlbiBQaG9lbml4IHdvbid0IGhhdmUgYWNjZXNzIHRvIGBzZXNzaW9uU3RvcmFnZWAuIEZvciBleGFtcGxlLCBUaGlzIGNvdWxkXG4gKiBoYXBwZW4gaWYgYSBzaXRlIGxvYWRzIGEgY3Jvc3MtZG9tYWluIGNoYW5uZWwgaW4gYW4gaWZyYW1lLiBFeGFtcGxlIHVzYWdlOlxuICpcbiAqICAgICBjbGFzcyBJbk1lbW9yeVN0b3JhZ2Uge1xuICogICAgICAgY29uc3RydWN0b3IoKSB7IHRoaXMuc3RvcmFnZSA9IHt9IH1cbiAqICAgICAgIGdldEl0ZW0oa2V5TmFtZSkgeyByZXR1cm4gdGhpcy5zdG9yYWdlW2tleU5hbWVdIHx8IG51bGwgfVxuICogICAgICAgcmVtb3ZlSXRlbShrZXlOYW1lKSB7IGRlbGV0ZSB0aGlzLnN0b3JhZ2Vba2V5TmFtZV0gfVxuICogICAgICAgc2V0SXRlbShrZXlOYW1lLCBrZXlWYWx1ZSkgeyB0aGlzLnN0b3JhZ2Vba2V5TmFtZV0gPSBrZXlWYWx1ZSB9XG4gKiAgICAgfVxuICpcbiovXG5leHBvcnQgZGVmYXVsdCBjbGFzcyBTb2NrZXQge1xuICBjb25zdHJ1Y3RvcihlbmRQb2ludCwgb3B0cyA9IHt9KXtcbiAgICB0aGlzLnN0YXRlQ2hhbmdlQ2FsbGJhY2tzID0ge29wZW46IFtdLCBjbG9zZTogW10sIGVycm9yOiBbXSwgbWVzc2FnZTogW119XG4gICAgdGhpcy5jaGFubmVscyA9IFtdXG4gICAgdGhpcy5zZW5kQnVmZmVyID0gW11cbiAgICB0aGlzLnJlZiA9IDBcbiAgICB0aGlzLnRpbWVvdXQgPSBvcHRzLnRpbWVvdXQgfHwgREVGQVVMVF9USU1FT1VUXG4gICAgdGhpcy50cmFuc3BvcnQgPSBvcHRzLnRyYW5zcG9ydCB8fCBnbG9iYWwuV2ViU29ja2V0IHx8IExvbmdQb2xsXG4gICAgdGhpcy5wcmltYXJ5UGFzc2VkSGVhbHRoQ2hlY2sgPSBmYWxzZVxuICAgIHRoaXMubG9uZ1BvbGxGYWxsYmFja01zID0gb3B0cy5sb25nUG9sbEZhbGxiYWNrTXNcbiAgICB0aGlzLmZhbGxiYWNrVGltZXIgPSBudWxsXG4gICAgdGhpcy5zZXNzaW9uU3RvcmUgPSBvcHRzLnNlc3Npb25TdG9yYWdlIHx8IChnbG9iYWwgJiYgZ2xvYmFsLnNlc3Npb25TdG9yYWdlKVxuICAgIHRoaXMuZXN0YWJsaXNoZWRDb25uZWN0aW9ucyA9IDBcbiAgICB0aGlzLmRlZmF1bHRFbmNvZGVyID0gU2VyaWFsaXplci5lbmNvZGUuYmluZChTZXJpYWxpemVyKVxuICAgIHRoaXMuZGVmYXVsdERlY29kZXIgPSBTZXJpYWxpemVyLmRlY29kZS5iaW5kKFNlcmlhbGl6ZXIpXG4gICAgdGhpcy5jbG9zZVdhc0NsZWFuID0gZmFsc2VcbiAgICB0aGlzLmRpc2Nvbm5lY3RpbmcgPSBmYWxzZVxuICAgIHRoaXMuYmluYXJ5VHlwZSA9IG9wdHMuYmluYXJ5VHlwZSB8fCBcImFycmF5YnVmZmVyXCJcbiAgICB0aGlzLmNvbm5lY3RDbG9jayA9IDFcbiAgICBpZih0aGlzLnRyYW5zcG9ydCAhPT0gTG9uZ1BvbGwpe1xuICAgICAgdGhpcy5lbmNvZGUgPSBvcHRzLmVuY29kZSB8fCB0aGlzLmRlZmF1bHRFbmNvZGVyXG4gICAgICB0aGlzLmRlY29kZSA9IG9wdHMuZGVjb2RlIHx8IHRoaXMuZGVmYXVsdERlY29kZXJcbiAgICB9IGVsc2Uge1xuICAgICAgdGhpcy5lbmNvZGUgPSB0aGlzLmRlZmF1bHRFbmNvZGVyXG4gICAgICB0aGlzLmRlY29kZSA9IHRoaXMuZGVmYXVsdERlY29kZXJcbiAgICB9XG4gICAgbGV0IGF3YWl0aW5nQ29ubmVjdGlvbk9uUGFnZVNob3cgPSBudWxsXG4gICAgaWYocGh4V2luZG93ICYmIHBoeFdpbmRvdy5hZGRFdmVudExpc3RlbmVyKXtcbiAgICAgIHBoeFdpbmRvdy5hZGRFdmVudExpc3RlbmVyKFwicGFnZWhpZGVcIiwgX2UgPT4ge1xuICAgICAgICBpZih0aGlzLmNvbm4pe1xuICAgICAgICAgIHRoaXMuZGlzY29ubmVjdCgpXG4gICAgICAgICAgYXdhaXRpbmdDb25uZWN0aW9uT25QYWdlU2hvdyA9IHRoaXMuY29ubmVjdENsb2NrXG4gICAgICAgIH1cbiAgICAgIH0pXG4gICAgICBwaHhXaW5kb3cuYWRkRXZlbnRMaXN0ZW5lcihcInBhZ2VzaG93XCIsIF9lID0+IHtcbiAgICAgICAgaWYoYXdhaXRpbmdDb25uZWN0aW9uT25QYWdlU2hvdyA9PT0gdGhpcy5jb25uZWN0Q2xvY2spe1xuICAgICAgICAgIGF3YWl0aW5nQ29ubmVjdGlvbk9uUGFnZVNob3cgPSBudWxsXG4gICAgICAgICAgdGhpcy5jb25uZWN0KClcbiAgICAgICAgfVxuICAgICAgfSlcbiAgICB9XG4gICAgdGhpcy5oZWFydGJlYXRJbnRlcnZhbE1zID0gb3B0cy5oZWFydGJlYXRJbnRlcnZhbE1zIHx8IDMwMDAwXG4gICAgdGhpcy5yZWpvaW5BZnRlck1zID0gKHRyaWVzKSA9PiB7XG4gICAgICBpZihvcHRzLnJlam9pbkFmdGVyTXMpe1xuICAgICAgICByZXR1cm4gb3B0cy5yZWpvaW5BZnRlck1zKHRyaWVzKVxuICAgICAgfSBlbHNlIHtcbiAgICAgICAgcmV0dXJuIFsxMDAwLCAyMDAwLCA1MDAwXVt0cmllcyAtIDFdIHx8IDEwMDAwXG4gICAgICB9XG4gICAgfVxuICAgIHRoaXMucmVjb25uZWN0QWZ0ZXJNcyA9ICh0cmllcykgPT4ge1xuICAgICAgaWYob3B0cy5yZWNvbm5lY3RBZnRlck1zKXtcbiAgICAgICAgcmV0dXJuIG9wdHMucmVjb25uZWN0QWZ0ZXJNcyh0cmllcylcbiAgICAgIH0gZWxzZSB7XG4gICAgICAgIHJldHVybiBbMTAsIDUwLCAxMDAsIDE1MCwgMjAwLCAyNTAsIDUwMCwgMTAwMCwgMjAwMF1bdHJpZXMgLSAxXSB8fCA1MDAwXG4gICAgICB9XG4gICAgfVxuICAgIHRoaXMubG9nZ2VyID0gb3B0cy5sb2dnZXIgfHwgbnVsbFxuICAgIGlmKCF0aGlzLmxvZ2dlciAmJiBvcHRzLmRlYnVnKXtcbiAgICAgIHRoaXMubG9nZ2VyID0gKGtpbmQsIG1zZywgZGF0YSkgPT4geyBjb25zb2xlLmxvZyhgJHtraW5kfTogJHttc2d9YCwgZGF0YSkgfVxuICAgIH1cbiAgICB0aGlzLmxvbmdwb2xsZXJUaW1lb3V0ID0gb3B0cy5sb25ncG9sbGVyVGltZW91dCB8fCAyMDAwMFxuICAgIHRoaXMucGFyYW1zID0gY2xvc3VyZShvcHRzLnBhcmFtcyB8fCB7fSlcbiAgICB0aGlzLmVuZFBvaW50ID0gYCR7ZW5kUG9pbnR9LyR7VFJBTlNQT1JUUy53ZWJzb2NrZXR9YFxuICAgIHRoaXMudnNuID0gb3B0cy52c24gfHwgREVGQVVMVF9WU05cbiAgICB0aGlzLmhlYXJ0YmVhdFRpbWVvdXRUaW1lciA9IG51bGxcbiAgICB0aGlzLmhlYXJ0YmVhdFRpbWVyID0gbnVsbFxuICAgIHRoaXMucGVuZGluZ0hlYXJ0YmVhdFJlZiA9IG51bGxcbiAgICB0aGlzLnJlY29ubmVjdFRpbWVyID0gbmV3IFRpbWVyKCgpID0+IHtcbiAgICAgIHRoaXMudGVhcmRvd24oKCkgPT4gdGhpcy5jb25uZWN0KCkpXG4gICAgfSwgdGhpcy5yZWNvbm5lY3RBZnRlck1zKVxuICAgIHRoaXMuYXV0aFRva2VuID0gb3B0cy5hdXRoVG9rZW5cbiAgfVxuXG4gIC8qKlxuICAgKiBSZXR1cm5zIHRoZSBMb25nUG9sbCB0cmFuc3BvcnQgcmVmZXJlbmNlXG4gICAqL1xuICBnZXRMb25nUG9sbFRyYW5zcG9ydCgpeyByZXR1cm4gTG9uZ1BvbGwgfVxuXG4gIC8qKlxuICAgKiBEaXNjb25uZWN0cyBhbmQgcmVwbGFjZXMgdGhlIGFjdGl2ZSB0cmFuc3BvcnRcbiAgICpcbiAgICogQHBhcmFtIHtGdW5jdGlvbn0gbmV3VHJhbnNwb3J0IC0gVGhlIG5ldyB0cmFuc3BvcnQgY2xhc3MgdG8gaW5zdGFudGlhdGVcbiAgICpcbiAgICovXG4gIHJlcGxhY2VUcmFuc3BvcnQobmV3VHJhbnNwb3J0KXtcbiAgICB0aGlzLmNvbm5lY3RDbG9jaysrXG4gICAgdGhpcy5jbG9zZVdhc0NsZWFuID0gdHJ1ZVxuICAgIGNsZWFyVGltZW91dCh0aGlzLmZhbGxiYWNrVGltZXIpXG4gICAgdGhpcy5yZWNvbm5lY3RUaW1lci5yZXNldCgpXG4gICAgaWYodGhpcy5jb25uKXtcbiAgICAgIHRoaXMuY29ubi5jbG9zZSgpXG4gICAgICB0aGlzLmNvbm4gPSBudWxsXG4gICAgfVxuICAgIHRoaXMudHJhbnNwb3J0ID0gbmV3VHJhbnNwb3J0XG4gIH1cblxuICAvKipcbiAgICogUmV0dXJucyB0aGUgc29ja2V0IHByb3RvY29sXG4gICAqXG4gICAqIEByZXR1cm5zIHtzdHJpbmd9XG4gICAqL1xuICBwcm90b2NvbCgpeyByZXR1cm4gbG9jYXRpb24ucHJvdG9jb2wubWF0Y2goL15odHRwcy8pID8gXCJ3c3NcIiA6IFwid3NcIiB9XG5cbiAgLyoqXG4gICAqIFRoZSBmdWxseSBxdWFsaWZpZWQgc29ja2V0IHVybFxuICAgKlxuICAgKiBAcmV0dXJucyB7c3RyaW5nfVxuICAgKi9cbiAgZW5kUG9pbnRVUkwoKXtcbiAgICBsZXQgdXJpID0gQWpheC5hcHBlbmRQYXJhbXMoXG4gICAgICBBamF4LmFwcGVuZFBhcmFtcyh0aGlzLmVuZFBvaW50LCB0aGlzLnBhcmFtcygpKSwge3ZzbjogdGhpcy52c259KVxuICAgIGlmKHVyaS5jaGFyQXQoMCkgIT09IFwiL1wiKXsgcmV0dXJuIHVyaSB9XG4gICAgaWYodXJpLmNoYXJBdCgxKSA9PT0gXCIvXCIpeyByZXR1cm4gYCR7dGhpcy5wcm90b2NvbCgpfToke3VyaX1gIH1cblxuICAgIHJldHVybiBgJHt0aGlzLnByb3RvY29sKCl9Oi8vJHtsb2NhdGlvbi5ob3N0fSR7dXJpfWBcbiAgfVxuXG4gIC8qKlxuICAgKiBEaXNjb25uZWN0cyB0aGUgc29ja2V0XG4gICAqXG4gICAqIFNlZSBodHRwczovL2RldmVsb3Blci5tb3ppbGxhLm9yZy9lbi1VUy9kb2NzL1dlYi9BUEkvQ2xvc2VFdmVudCNTdGF0dXNfY29kZXMgZm9yIHZhbGlkIHN0YXR1cyBjb2Rlcy5cbiAgICpcbiAgICogQHBhcmFtIHtGdW5jdGlvbn0gY2FsbGJhY2sgLSBPcHRpb25hbCBjYWxsYmFjayB3aGljaCBpcyBjYWxsZWQgYWZ0ZXIgc29ja2V0IGlzIGRpc2Nvbm5lY3RlZC5cbiAgICogQHBhcmFtIHtpbnRlZ2VyfSBjb2RlIC0gQSBzdGF0dXMgY29kZSBmb3IgZGlzY29ubmVjdGlvbiAoT3B0aW9uYWwpLlxuICAgKiBAcGFyYW0ge3N0cmluZ30gcmVhc29uIC0gQSB0ZXh0dWFsIGRlc2NyaXB0aW9uIG9mIHRoZSByZWFzb24gdG8gZGlzY29ubmVjdC4gKE9wdGlvbmFsKVxuICAgKi9cbiAgZGlzY29ubmVjdChjYWxsYmFjaywgY29kZSwgcmVhc29uKXtcbiAgICB0aGlzLmNvbm5lY3RDbG9jaysrXG4gICAgdGhpcy5kaXNjb25uZWN0aW5nID0gdHJ1ZVxuICAgIHRoaXMuY2xvc2VXYXNDbGVhbiA9IHRydWVcbiAgICBjbGVhclRpbWVvdXQodGhpcy5mYWxsYmFja1RpbWVyKVxuICAgIHRoaXMucmVjb25uZWN0VGltZXIucmVzZXQoKVxuICAgIHRoaXMudGVhcmRvd24oKCkgPT4ge1xuICAgICAgdGhpcy5kaXNjb25uZWN0aW5nID0gZmFsc2VcbiAgICAgIGNhbGxiYWNrICYmIGNhbGxiYWNrKClcbiAgICB9LCBjb2RlLCByZWFzb24pXG4gIH1cblxuICAvKipcbiAgICpcbiAgICogQHBhcmFtIHtPYmplY3R9IHBhcmFtcyAtIFRoZSBwYXJhbXMgdG8gc2VuZCB3aGVuIGNvbm5lY3RpbmcsIGZvciBleGFtcGxlIGB7dXNlcl9pZDogdXNlclRva2VufWBcbiAgICpcbiAgICogUGFzc2luZyBwYXJhbXMgdG8gY29ubmVjdCBpcyBkZXByZWNhdGVkOyBwYXNzIHRoZW0gaW4gdGhlIFNvY2tldCBjb25zdHJ1Y3RvciBpbnN0ZWFkOlxuICAgKiBgbmV3IFNvY2tldChcIi9zb2NrZXRcIiwge3BhcmFtczoge3VzZXJfaWQ6IHVzZXJUb2tlbn19KWAuXG4gICAqL1xuICBjb25uZWN0KHBhcmFtcyl7XG4gICAgaWYocGFyYW1zKXtcbiAgICAgIGNvbnNvbGUgJiYgY29uc29sZS5sb2coXCJwYXNzaW5nIHBhcmFtcyB0byBjb25uZWN0IGlzIGRlcHJlY2F0ZWQuIEluc3RlYWQgcGFzcyA6cGFyYW1zIHRvIHRoZSBTb2NrZXQgY29uc3RydWN0b3JcIilcbiAgICAgIHRoaXMucGFyYW1zID0gY2xvc3VyZShwYXJhbXMpXG4gICAgfVxuICAgIGlmKHRoaXMuY29ubiAmJiAhdGhpcy5kaXNjb25uZWN0aW5nKXsgcmV0dXJuIH1cbiAgICBpZih0aGlzLmxvbmdQb2xsRmFsbGJhY2tNcyAmJiB0aGlzLnRyYW5zcG9ydCAhPT0gTG9uZ1BvbGwpe1xuICAgICAgdGhpcy5jb25uZWN0V2l0aEZhbGxiYWNrKExvbmdQb2xsLCB0aGlzLmxvbmdQb2xsRmFsbGJhY2tNcylcbiAgICB9IGVsc2Uge1xuICAgICAgdGhpcy50cmFuc3BvcnRDb25uZWN0KClcbiAgICB9XG4gIH1cblxuICAvKipcbiAgICogTG9ncyB0aGUgbWVzc2FnZS4gT3ZlcnJpZGUgYHRoaXMubG9nZ2VyYCBmb3Igc3BlY2lhbGl6ZWQgbG9nZ2luZy4gbm9vcHMgYnkgZGVmYXVsdFxuICAgKiBAcGFyYW0ge3N0cmluZ30ga2luZFxuICAgKiBAcGFyYW0ge3N0cmluZ30gbXNnXG4gICAqIEBwYXJhbSB7T2JqZWN0fSBkYXRhXG4gICAqL1xuICBsb2coa2luZCwgbXNnLCBkYXRhKXsgdGhpcy5sb2dnZXIgJiYgdGhpcy5sb2dnZXIoa2luZCwgbXNnLCBkYXRhKSB9XG5cbiAgLyoqXG4gICAqIFJldHVybnMgdHJ1ZSBpZiBhIGxvZ2dlciBoYXMgYmVlbiBzZXQgb24gdGhpcyBzb2NrZXQuXG4gICAqL1xuICBoYXNMb2dnZXIoKXsgcmV0dXJuIHRoaXMubG9nZ2VyICE9PSBudWxsIH1cblxuICAvKipcbiAgICogUmVnaXN0ZXJzIGNhbGxiYWNrcyBmb3IgY29ubmVjdGlvbiBvcGVuIGV2ZW50c1xuICAgKlxuICAgKiBAZXhhbXBsZSBzb2NrZXQub25PcGVuKGZ1bmN0aW9uKCl7IGNvbnNvbGUuaW5mbyhcInRoZSBzb2NrZXQgd2FzIG9wZW5lZFwiKSB9KVxuICAgKlxuICAgKiBAcGFyYW0ge0Z1bmN0aW9ufSBjYWxsYmFja1xuICAgKi9cbiAgb25PcGVuKGNhbGxiYWNrKXtcbiAgICBsZXQgcmVmID0gdGhpcy5tYWtlUmVmKClcbiAgICB0aGlzLnN0YXRlQ2hhbmdlQ2FsbGJhY2tzLm9wZW4ucHVzaChbcmVmLCBjYWxsYmFja10pXG4gICAgcmV0dXJuIHJlZlxuICB9XG5cbiAgLyoqXG4gICAqIFJlZ2lzdGVycyBjYWxsYmFja3MgZm9yIGNvbm5lY3Rpb24gY2xvc2UgZXZlbnRzXG4gICAqIEBwYXJhbSB7RnVuY3Rpb259IGNhbGxiYWNrXG4gICAqL1xuICBvbkNsb3NlKGNhbGxiYWNrKXtcbiAgICBsZXQgcmVmID0gdGhpcy5tYWtlUmVmKClcbiAgICB0aGlzLnN0YXRlQ2hhbmdlQ2FsbGJhY2tzLmNsb3NlLnB1c2goW3JlZiwgY2FsbGJhY2tdKVxuICAgIHJldHVybiByZWZcbiAgfVxuXG4gIC8qKlxuICAgKiBSZWdpc3RlcnMgY2FsbGJhY2tzIGZvciBjb25uZWN0aW9uIGVycm9yIGV2ZW50c1xuICAgKlxuICAgKiBAZXhhbXBsZSBzb2NrZXQub25FcnJvcihmdW5jdGlvbihlcnJvcil7IGFsZXJ0KFwiQW4gZXJyb3Igb2NjdXJyZWRcIikgfSlcbiAgICpcbiAgICogQHBhcmFtIHtGdW5jdGlvbn0gY2FsbGJhY2tcbiAgICovXG4gIG9uRXJyb3IoY2FsbGJhY2spe1xuICAgIGxldCByZWYgPSB0aGlzLm1ha2VSZWYoKVxuICAgIHRoaXMuc3RhdGVDaGFuZ2VDYWxsYmFja3MuZXJyb3IucHVzaChbcmVmLCBjYWxsYmFja10pXG4gICAgcmV0dXJuIHJlZlxuICB9XG5cbiAgLyoqXG4gICAqIFJlZ2lzdGVycyBjYWxsYmFja3MgZm9yIGNvbm5lY3Rpb24gbWVzc2FnZSBldmVudHNcbiAgICogQHBhcmFtIHtGdW5jdGlvbn0gY2FsbGJhY2tcbiAgICovXG4gIG9uTWVzc2FnZShjYWxsYmFjayl7XG4gICAgbGV0IHJlZiA9IHRoaXMubWFrZVJlZigpXG4gICAgdGhpcy5zdGF0ZUNoYW5nZUNhbGxiYWNrcy5tZXNzYWdlLnB1c2goW3JlZiwgY2FsbGJhY2tdKVxuICAgIHJldHVybiByZWZcbiAgfVxuXG4gIC8qKlxuICAgKiBQaW5ncyB0aGUgc2VydmVyIGFuZCBpbnZva2VzIHRoZSBjYWxsYmFjayB3aXRoIHRoZSBSVFQgaW4gbWlsbGlzZWNvbmRzXG4gICAqIEBwYXJhbSB7RnVuY3Rpb259IGNhbGxiYWNrXG4gICAqXG4gICAqIFJldHVybnMgdHJ1ZSBpZiB0aGUgcGluZyB3YXMgcHVzaGVkIG9yIGZhbHNlIGlmIHVuYWJsZSB0byBiZSBwdXNoZWQuXG4gICAqL1xuICBwaW5nKGNhbGxiYWNrKXtcbiAgICBpZighdGhpcy5pc0Nvbm5lY3RlZCgpKXsgcmV0dXJuIGZhbHNlIH1cbiAgICBsZXQgcmVmID0gdGhpcy5tYWtlUmVmKClcbiAgICBsZXQgc3RhcnRUaW1lID0gRGF0ZS5ub3coKVxuICAgIHRoaXMucHVzaCh7dG9waWM6IFwicGhvZW5peFwiLCBldmVudDogXCJoZWFydGJlYXRcIiwgcGF5bG9hZDoge30sIHJlZjogcmVmfSlcbiAgICBsZXQgb25Nc2dSZWYgPSB0aGlzLm9uTWVzc2FnZShtc2cgPT4ge1xuICAgICAgaWYobXNnLnJlZiA9PT0gcmVmKXtcbiAgICAgICAgdGhpcy5vZmYoW29uTXNnUmVmXSlcbiAgICAgICAgY2FsbGJhY2soRGF0ZS5ub3coKSAtIHN0YXJ0VGltZSlcbiAgICAgIH1cbiAgICB9KVxuICAgIHJldHVybiB0cnVlXG4gIH1cblxuICAvKipcbiAgICogQHByaXZhdGVcbiAgICovXG5cbiAgdHJhbnNwb3J0Q29ubmVjdCgpe1xuICAgIHRoaXMuY29ubmVjdENsb2NrKytcbiAgICB0aGlzLmNsb3NlV2FzQ2xlYW4gPSBmYWxzZVxuICAgIGxldCBwcm90b2NvbHMgPSB1bmRlZmluZWRcbiAgICAvLyBTZWMtV2ViU29ja2V0LVByb3RvY29sIGJhc2VkIHRva2VuXG4gICAgLy8gKGxvbmdwb2xsIHVzZXMgQXV0aG9yaXphdGlvbiBoZWFkZXIgaW5zdGVhZClcbiAgICBpZih0aGlzLmF1dGhUb2tlbil7XG4gICAgICBwcm90b2NvbHMgPSBbXCJwaG9lbml4XCIsIGAke0FVVEhfVE9LRU5fUFJFRklYfSR7YnRvYSh0aGlzLmF1dGhUb2tlbikucmVwbGFjZSgvPS9nLCBcIlwiKX1gXVxuICAgIH1cbiAgICB0aGlzLmNvbm4gPSBuZXcgdGhpcy50cmFuc3BvcnQodGhpcy5lbmRQb2ludFVSTCgpLCBwcm90b2NvbHMpXG4gICAgdGhpcy5jb25uLmJpbmFyeVR5cGUgPSB0aGlzLmJpbmFyeVR5cGVcbiAgICB0aGlzLmNvbm4udGltZW91dCA9IHRoaXMubG9uZ3BvbGxlclRpbWVvdXRcbiAgICB0aGlzLmNvbm4ub25vcGVuID0gKCkgPT4gdGhpcy5vbkNvbm5PcGVuKClcbiAgICB0aGlzLmNvbm4ub25lcnJvciA9IGVycm9yID0+IHRoaXMub25Db25uRXJyb3IoZXJyb3IpXG4gICAgdGhpcy5jb25uLm9ubWVzc2FnZSA9IGV2ZW50ID0+IHRoaXMub25Db25uTWVzc2FnZShldmVudClcbiAgICB0aGlzLmNvbm4ub25jbG9zZSA9IGV2ZW50ID0+IHRoaXMub25Db25uQ2xvc2UoZXZlbnQpXG4gIH1cblxuICBnZXRTZXNzaW9uKGtleSl7IHJldHVybiB0aGlzLnNlc3Npb25TdG9yZSAmJiB0aGlzLnNlc3Npb25TdG9yZS5nZXRJdGVtKGtleSkgfVxuXG4gIHN0b3JlU2Vzc2lvbihrZXksIHZhbCl7IHRoaXMuc2Vzc2lvblN0b3JlICYmIHRoaXMuc2Vzc2lvblN0b3JlLnNldEl0ZW0oa2V5LCB2YWwpIH1cblxuICBjb25uZWN0V2l0aEZhbGxiYWNrKGZhbGxiYWNrVHJhbnNwb3J0LCBmYWxsYmFja1RocmVzaG9sZCA9IDI1MDApe1xuICAgIGNsZWFyVGltZW91dCh0aGlzLmZhbGxiYWNrVGltZXIpXG4gICAgbGV0IGVzdGFibGlzaGVkID0gZmFsc2VcbiAgICBsZXQgcHJpbWFyeVRyYW5zcG9ydCA9IHRydWVcbiAgICBsZXQgb3BlblJlZiwgZXJyb3JSZWZcbiAgICBsZXQgZmFsbGJhY2sgPSAocmVhc29uKSA9PiB7XG4gICAgICB0aGlzLmxvZyhcInRyYW5zcG9ydFwiLCBgZmFsbGluZyBiYWNrIHRvICR7ZmFsbGJhY2tUcmFuc3BvcnQubmFtZX0uLi5gLCByZWFzb24pXG4gICAgICB0aGlzLm9mZihbb3BlblJlZiwgZXJyb3JSZWZdKVxuICAgICAgcHJpbWFyeVRyYW5zcG9ydCA9IGZhbHNlXG4gICAgICB0aGlzLnJlcGxhY2VUcmFuc3BvcnQoZmFsbGJhY2tUcmFuc3BvcnQpXG4gICAgICB0aGlzLnRyYW5zcG9ydENvbm5lY3QoKVxuICAgIH1cbiAgICBpZih0aGlzLmdldFNlc3Npb24oYHBoeDpmYWxsYmFjazoke2ZhbGxiYWNrVHJhbnNwb3J0Lm5hbWV9YCkpeyByZXR1cm4gZmFsbGJhY2soXCJtZW1vcml6ZWRcIikgfVxuXG4gICAgdGhpcy5mYWxsYmFja1RpbWVyID0gc2V0VGltZW91dChmYWxsYmFjaywgZmFsbGJhY2tUaHJlc2hvbGQpXG5cbiAgICBlcnJvclJlZiA9IHRoaXMub25FcnJvcihyZWFzb24gPT4ge1xuICAgICAgdGhpcy5sb2coXCJ0cmFuc3BvcnRcIiwgXCJlcnJvclwiLCByZWFzb24pXG4gICAgICBpZihwcmltYXJ5VHJhbnNwb3J0ICYmICFlc3RhYmxpc2hlZCl7XG4gICAgICAgIGNsZWFyVGltZW91dCh0aGlzLmZhbGxiYWNrVGltZXIpXG4gICAgICAgIGZhbGxiYWNrKHJlYXNvbilcbiAgICAgIH1cbiAgICB9KVxuICAgIHRoaXMub25PcGVuKCgpID0+IHtcbiAgICAgIGVzdGFibGlzaGVkID0gdHJ1ZVxuICAgICAgaWYoIXByaW1hcnlUcmFuc3BvcnQpe1xuICAgICAgICAvLyBvbmx5IG1lbW9yaXplIExQIGlmIHdlIG5ldmVyIGNvbm5lY3RlZCB0byBwcmltYXJ5XG4gICAgICAgIGlmKCF0aGlzLnByaW1hcnlQYXNzZWRIZWFsdGhDaGVjayl7IHRoaXMuc3RvcmVTZXNzaW9uKGBwaHg6ZmFsbGJhY2s6JHtmYWxsYmFja1RyYW5zcG9ydC5uYW1lfWAsIFwidHJ1ZVwiKSB9XG4gICAgICAgIHJldHVybiB0aGlzLmxvZyhcInRyYW5zcG9ydFwiLCBgZXN0YWJsaXNoZWQgJHtmYWxsYmFja1RyYW5zcG9ydC5uYW1lfSBmYWxsYmFja2ApXG4gICAgICB9XG4gICAgICAvLyBpZiB3ZSd2ZSBlc3RhYmxpc2hlZCBwcmltYXJ5LCBnaXZlIHRoZSBmYWxsYmFjayBhIG5ldyBwZXJpb2QgdG8gYXR0ZW1wdCBwaW5nXG4gICAgICBjbGVhclRpbWVvdXQodGhpcy5mYWxsYmFja1RpbWVyKVxuICAgICAgdGhpcy5mYWxsYmFja1RpbWVyID0gc2V0VGltZW91dChmYWxsYmFjaywgZmFsbGJhY2tUaHJlc2hvbGQpXG4gICAgICB0aGlzLnBpbmcocnR0ID0+IHtcbiAgICAgICAgdGhpcy5sb2coXCJ0cmFuc3BvcnRcIiwgXCJjb25uZWN0ZWQgdG8gcHJpbWFyeSBhZnRlclwiLCBydHQpXG4gICAgICAgIHRoaXMucHJpbWFyeVBhc3NlZEhlYWx0aENoZWNrID0gdHJ1ZVxuICAgICAgICBjbGVhclRpbWVvdXQodGhpcy5mYWxsYmFja1RpbWVyKVxuICAgICAgfSlcbiAgICB9KVxuICAgIHRoaXMudHJhbnNwb3J0Q29ubmVjdCgpXG4gIH1cblxuICBjbGVhckhlYXJ0YmVhdHMoKXtcbiAgICBjbGVhclRpbWVvdXQodGhpcy5oZWFydGJlYXRUaW1lcilcbiAgICBjbGVhclRpbWVvdXQodGhpcy5oZWFydGJlYXRUaW1lb3V0VGltZXIpXG4gIH1cblxuICBvbkNvbm5PcGVuKCl7XG4gICAgaWYodGhpcy5oYXNMb2dnZXIoKSkgdGhpcy5sb2coXCJ0cmFuc3BvcnRcIiwgYCR7dGhpcy50cmFuc3BvcnQubmFtZX0gY29ubmVjdGVkIHRvICR7dGhpcy5lbmRQb2ludFVSTCgpfWApXG4gICAgdGhpcy5jbG9zZVdhc0NsZWFuID0gZmFsc2VcbiAgICB0aGlzLmRpc2Nvbm5lY3RpbmcgPSBmYWxzZVxuICAgIHRoaXMuZXN0YWJsaXNoZWRDb25uZWN0aW9ucysrXG4gICAgdGhpcy5mbHVzaFNlbmRCdWZmZXIoKVxuICAgIHRoaXMucmVjb25uZWN0VGltZXIucmVzZXQoKVxuICAgIHRoaXMucmVzZXRIZWFydGJlYXQoKVxuICAgIHRoaXMuc3RhdGVDaGFuZ2VDYWxsYmFja3Mub3Blbi5mb3JFYWNoKChbLCBjYWxsYmFja10pID0+IGNhbGxiYWNrKCkpXG4gIH1cblxuICAvKipcbiAgICogQHByaXZhdGVcbiAgICovXG5cbiAgaGVhcnRiZWF0VGltZW91dCgpe1xuICAgIGlmKHRoaXMucGVuZGluZ0hlYXJ0YmVhdFJlZil7XG4gICAgICB0aGlzLnBlbmRpbmdIZWFydGJlYXRSZWYgPSBudWxsXG4gICAgICBpZih0aGlzLmhhc0xvZ2dlcigpKXsgdGhpcy5sb2coXCJ0cmFuc3BvcnRcIiwgXCJoZWFydGJlYXQgdGltZW91dC4gQXR0ZW1wdGluZyB0byByZS1lc3RhYmxpc2ggY29ubmVjdGlvblwiKSB9XG4gICAgICB0aGlzLnRyaWdnZXJDaGFuRXJyb3IoKVxuICAgICAgdGhpcy5jbG9zZVdhc0NsZWFuID0gZmFsc2VcbiAgICAgIHRoaXMudGVhcmRvd24oKCkgPT4gdGhpcy5yZWNvbm5lY3RUaW1lci5zY2hlZHVsZVRpbWVvdXQoKSwgV1NfQ0xPU0VfTk9STUFMLCBcImhlYXJ0YmVhdCB0aW1lb3V0XCIpXG4gICAgfVxuICB9XG5cbiAgcmVzZXRIZWFydGJlYXQoKXtcbiAgICBpZih0aGlzLmNvbm4gJiYgdGhpcy5jb25uLnNraXBIZWFydGJlYXQpeyByZXR1cm4gfVxuICAgIHRoaXMucGVuZGluZ0hlYXJ0YmVhdFJlZiA9IG51bGxcbiAgICB0aGlzLmNsZWFySGVhcnRiZWF0cygpXG4gICAgdGhpcy5oZWFydGJlYXRUaW1lciA9IHNldFRpbWVvdXQoKCkgPT4gdGhpcy5zZW5kSGVhcnRiZWF0KCksIHRoaXMuaGVhcnRiZWF0SW50ZXJ2YWxNcylcbiAgfVxuXG4gIHRlYXJkb3duKGNhbGxiYWNrLCBjb2RlLCByZWFzb24pe1xuICAgIGlmKCF0aGlzLmNvbm4pe1xuICAgICAgcmV0dXJuIGNhbGxiYWNrICYmIGNhbGxiYWNrKClcbiAgICB9XG4gICAgbGV0IGNvbm5lY3RDbG9jayA9IHRoaXMuY29ubmVjdENsb2NrXG5cbiAgICB0aGlzLndhaXRGb3JCdWZmZXJEb25lKCgpID0+IHtcbiAgICAgIGlmKGNvbm5lY3RDbG9jayAhPT0gdGhpcy5jb25uZWN0Q2xvY2speyByZXR1cm4gfVxuICAgICAgaWYodGhpcy5jb25uKXtcbiAgICAgICAgaWYoY29kZSl7IHRoaXMuY29ubi5jbG9zZShjb2RlLCByZWFzb24gfHwgXCJcIikgfSBlbHNlIHsgdGhpcy5jb25uLmNsb3NlKCkgfVxuICAgICAgfVxuXG4gICAgICB0aGlzLndhaXRGb3JTb2NrZXRDbG9zZWQoKCkgPT4ge1xuICAgICAgICBpZihjb25uZWN0Q2xvY2sgIT09IHRoaXMuY29ubmVjdENsb2NrKXsgcmV0dXJuIH1cbiAgICAgICAgaWYodGhpcy5jb25uKXtcbiAgICAgICAgICB0aGlzLmNvbm4ub25vcGVuID0gZnVuY3Rpb24gKCl7IH0gLy8gbm9vcFxuICAgICAgICAgIHRoaXMuY29ubi5vbmVycm9yID0gZnVuY3Rpb24gKCl7IH0gLy8gbm9vcFxuICAgICAgICAgIHRoaXMuY29ubi5vbm1lc3NhZ2UgPSBmdW5jdGlvbiAoKXsgfSAvLyBub29wXG4gICAgICAgICAgdGhpcy5jb25uLm9uY2xvc2UgPSBmdW5jdGlvbiAoKXsgfSAvLyBub29wXG4gICAgICAgICAgdGhpcy5jb25uID0gbnVsbFxuICAgICAgICB9XG5cbiAgICAgICAgY2FsbGJhY2sgJiYgY2FsbGJhY2soKVxuICAgICAgfSlcbiAgICB9KVxuICB9XG5cbiAgd2FpdEZvckJ1ZmZlckRvbmUoY2FsbGJhY2ssIHRyaWVzID0gMSl7XG4gICAgaWYodHJpZXMgPT09IDUgfHwgIXRoaXMuY29ubiB8fCAhdGhpcy5jb25uLmJ1ZmZlcmVkQW1vdW50KXtcbiAgICAgIGNhbGxiYWNrKClcbiAgICAgIHJldHVyblxuICAgIH1cblxuICAgIHNldFRpbWVvdXQoKCkgPT4ge1xuICAgICAgdGhpcy53YWl0Rm9yQnVmZmVyRG9uZShjYWxsYmFjaywgdHJpZXMgKyAxKVxuICAgIH0sIDE1MCAqIHRyaWVzKVxuICB9XG5cbiAgd2FpdEZvclNvY2tldENsb3NlZChjYWxsYmFjaywgdHJpZXMgPSAxKXtcbiAgICBpZih0cmllcyA9PT0gNSB8fCAhdGhpcy5jb25uIHx8IHRoaXMuY29ubi5yZWFkeVN0YXRlID09PSBTT0NLRVRfU1RBVEVTLmNsb3NlZCl7XG4gICAgICBjYWxsYmFjaygpXG4gICAgICByZXR1cm5cbiAgICB9XG5cbiAgICBzZXRUaW1lb3V0KCgpID0+IHtcbiAgICAgIHRoaXMud2FpdEZvclNvY2tldENsb3NlZChjYWxsYmFjaywgdHJpZXMgKyAxKVxuICAgIH0sIDE1MCAqIHRyaWVzKVxuICB9XG5cbiAgb25Db25uQ2xvc2UoZXZlbnQpe1xuICAgIGxldCBjbG9zZUNvZGUgPSBldmVudCAmJiBldmVudC5jb2RlXG4gICAgaWYodGhpcy5oYXNMb2dnZXIoKSkgdGhpcy5sb2coXCJ0cmFuc3BvcnRcIiwgXCJjbG9zZVwiLCBldmVudClcbiAgICB0aGlzLnRyaWdnZXJDaGFuRXJyb3IoKVxuICAgIHRoaXMuY2xlYXJIZWFydGJlYXRzKClcbiAgICBpZighdGhpcy5jbG9zZVdhc0NsZWFuICYmIGNsb3NlQ29kZSAhPT0gMTAwMCl7XG4gICAgICB0aGlzLnJlY29ubmVjdFRpbWVyLnNjaGVkdWxlVGltZW91dCgpXG4gICAgfVxuICAgIHRoaXMuc3RhdGVDaGFuZ2VDYWxsYmFja3MuY2xvc2UuZm9yRWFjaCgoWywgY2FsbGJhY2tdKSA9PiBjYWxsYmFjayhldmVudCkpXG4gIH1cblxuICAvKipcbiAgICogQHByaXZhdGVcbiAgICovXG4gIG9uQ29ubkVycm9yKGVycm9yKXtcbiAgICBpZih0aGlzLmhhc0xvZ2dlcigpKSB0aGlzLmxvZyhcInRyYW5zcG9ydFwiLCBlcnJvcilcbiAgICBsZXQgdHJhbnNwb3J0QmVmb3JlID0gdGhpcy50cmFuc3BvcnRcbiAgICBsZXQgZXN0YWJsaXNoZWRCZWZvcmUgPSB0aGlzLmVzdGFibGlzaGVkQ29ubmVjdGlvbnNcbiAgICB0aGlzLnN0YXRlQ2hhbmdlQ2FsbGJhY2tzLmVycm9yLmZvckVhY2goKFssIGNhbGxiYWNrXSkgPT4ge1xuICAgICAgY2FsbGJhY2soZXJyb3IsIHRyYW5zcG9ydEJlZm9yZSwgZXN0YWJsaXNoZWRCZWZvcmUpXG4gICAgfSlcbiAgICBpZih0cmFuc3BvcnRCZWZvcmUgPT09IHRoaXMudHJhbnNwb3J0IHx8IGVzdGFibGlzaGVkQmVmb3JlID4gMCl7XG4gICAgICB0aGlzLnRyaWdnZXJDaGFuRXJyb3IoKVxuICAgIH1cbiAgfVxuXG4gIC8qKlxuICAgKiBAcHJpdmF0ZVxuICAgKi9cbiAgdHJpZ2dlckNoYW5FcnJvcigpe1xuICAgIHRoaXMuY2hhbm5lbHMuZm9yRWFjaChjaGFubmVsID0+IHtcbiAgICAgIGlmKCEoY2hhbm5lbC5pc0Vycm9yZWQoKSB8fCBjaGFubmVsLmlzTGVhdmluZygpIHx8IGNoYW5uZWwuaXNDbG9zZWQoKSkpe1xuICAgICAgICBjaGFubmVsLnRyaWdnZXIoQ0hBTk5FTF9FVkVOVFMuZXJyb3IpXG4gICAgICB9XG4gICAgfSlcbiAgfVxuXG4gIC8qKlxuICAgKiBAcmV0dXJucyB7c3RyaW5nfVxuICAgKi9cbiAgY29ubmVjdGlvblN0YXRlKCl7XG4gICAgc3dpdGNoKHRoaXMuY29ubiAmJiB0aGlzLmNvbm4ucmVhZHlTdGF0ZSl7XG4gICAgICBjYXNlIFNPQ0tFVF9TVEFURVMuY29ubmVjdGluZzogcmV0dXJuIFwiY29ubmVjdGluZ1wiXG4gICAgICBjYXNlIFNPQ0tFVF9TVEFURVMub3BlbjogcmV0dXJuIFwib3BlblwiXG4gICAgICBjYXNlIFNPQ0tFVF9TVEFURVMuY2xvc2luZzogcmV0dXJuIFwiY2xvc2luZ1wiXG4gICAgICBkZWZhdWx0OiByZXR1cm4gXCJjbG9zZWRcIlxuICAgIH1cbiAgfVxuXG4gIC8qKlxuICAgKiBAcmV0dXJucyB7Ym9vbGVhbn1cbiAgICovXG4gIGlzQ29ubmVjdGVkKCl7IHJldHVybiB0aGlzLmNvbm5lY3Rpb25TdGF0ZSgpID09PSBcIm9wZW5cIiB9XG5cbiAgLyoqXG4gICAqIEBwcml2YXRlXG4gICAqXG4gICAqIEBwYXJhbSB7Q2hhbm5lbH1cbiAgICovXG4gIHJlbW92ZShjaGFubmVsKXtcbiAgICB0aGlzLm9mZihjaGFubmVsLnN0YXRlQ2hhbmdlUmVmcylcbiAgICB0aGlzLmNoYW5uZWxzID0gdGhpcy5jaGFubmVscy5maWx0ZXIoYyA9PiBjICE9PSBjaGFubmVsKVxuICB9XG5cbiAgLyoqXG4gICAqIFJlbW92ZXMgYG9uT3BlbmAsIGBvbkNsb3NlYCwgYG9uRXJyb3IsYCBhbmQgYG9uTWVzc2FnZWAgcmVnaXN0cmF0aW9ucy5cbiAgICpcbiAgICogQHBhcmFtIHtyZWZzfSAtIGxpc3Qgb2YgcmVmcyByZXR1cm5lZCBieSBjYWxscyB0b1xuICAgKiAgICAgICAgICAgICAgICAgYG9uT3BlbmAsIGBvbkNsb3NlYCwgYG9uRXJyb3IsYCBhbmQgYG9uTWVzc2FnZWBcbiAgICovXG4gIG9mZihyZWZzKXtcbiAgICBmb3IobGV0IGtleSBpbiB0aGlzLnN0YXRlQ2hhbmdlQ2FsbGJhY2tzKXtcbiAgICAgIHRoaXMuc3RhdGVDaGFuZ2VDYWxsYmFja3Nba2V5XSA9IHRoaXMuc3RhdGVDaGFuZ2VDYWxsYmFja3Nba2V5XS5maWx0ZXIoKFtyZWZdKSA9PiB7XG4gICAgICAgIHJldHVybiByZWZzLmluZGV4T2YocmVmKSA9PT0gLTFcbiAgICAgIH0pXG4gICAgfVxuICB9XG5cbiAgLyoqXG4gICAqIEluaXRpYXRlcyBhIG5ldyBjaGFubmVsIGZvciB0aGUgZ2l2ZW4gdG9waWNcbiAgICpcbiAgICogQHBhcmFtIHtzdHJpbmd9IHRvcGljXG4gICAqIEBwYXJhbSB7T2JqZWN0fSBjaGFuUGFyYW1zIC0gUGFyYW1ldGVycyBmb3IgdGhlIGNoYW5uZWxcbiAgICogQHJldHVybnMge0NoYW5uZWx9XG4gICAqL1xuICBjaGFubmVsKHRvcGljLCBjaGFuUGFyYW1zID0ge30pe1xuICAgIGxldCBjaGFuID0gbmV3IENoYW5uZWwodG9waWMsIGNoYW5QYXJhbXMsIHRoaXMpXG4gICAgdGhpcy5jaGFubmVscy5wdXNoKGNoYW4pXG4gICAgcmV0dXJuIGNoYW5cbiAgfVxuXG4gIC8qKlxuICAgKiBAcGFyYW0ge09iamVjdH0gZGF0YVxuICAgKi9cbiAgcHVzaChkYXRhKXtcbiAgICBpZih0aGlzLmhhc0xvZ2dlcigpKXtcbiAgICAgIGxldCB7dG9waWMsIGV2ZW50LCBwYXlsb2FkLCByZWYsIGpvaW5fcmVmfSA9IGRhdGFcbiAgICAgIHRoaXMubG9nKFwicHVzaFwiLCBgJHt0b3BpY30gJHtldmVudH0gKCR7am9pbl9yZWZ9LCAke3JlZn0pYCwgcGF5bG9hZClcbiAgICB9XG5cbiAgICBpZih0aGlzLmlzQ29ubmVjdGVkKCkpe1xuICAgICAgdGhpcy5lbmNvZGUoZGF0YSwgcmVzdWx0ID0+IHRoaXMuY29ubi5zZW5kKHJlc3VsdCkpXG4gICAgfSBlbHNlIHtcbiAgICAgIHRoaXMuc2VuZEJ1ZmZlci5wdXNoKCgpID0+IHRoaXMuZW5jb2RlKGRhdGEsIHJlc3VsdCA9PiB0aGlzLmNvbm4uc2VuZChyZXN1bHQpKSlcbiAgICB9XG4gIH1cblxuICAvKipcbiAgICogUmV0dXJuIHRoZSBuZXh0IG1lc3NhZ2UgcmVmLCBhY2NvdW50aW5nIGZvciBvdmVyZmxvd3NcbiAgICogQHJldHVybnMge3N0cmluZ31cbiAgICovXG4gIG1ha2VSZWYoKXtcbiAgICBsZXQgbmV3UmVmID0gdGhpcy5yZWYgKyAxXG4gICAgaWYobmV3UmVmID09PSB0aGlzLnJlZil7IHRoaXMucmVmID0gMCB9IGVsc2UgeyB0aGlzLnJlZiA9IG5ld1JlZiB9XG5cbiAgICByZXR1cm4gdGhpcy5yZWYudG9TdHJpbmcoKVxuICB9XG5cbiAgc2VuZEhlYXJ0YmVhdCgpe1xuICAgIGlmKHRoaXMucGVuZGluZ0hlYXJ0YmVhdFJlZiAmJiAhdGhpcy5pc0Nvbm5lY3RlZCgpKXsgcmV0dXJuIH1cbiAgICB0aGlzLnBlbmRpbmdIZWFydGJlYXRSZWYgPSB0aGlzLm1ha2VSZWYoKVxuICAgIHRoaXMucHVzaCh7dG9waWM6IFwicGhvZW5peFwiLCBldmVudDogXCJoZWFydGJlYXRcIiwgcGF5bG9hZDoge30sIHJlZjogdGhpcy5wZW5kaW5nSGVhcnRiZWF0UmVmfSlcbiAgICB0aGlzLmhlYXJ0YmVhdFRpbWVvdXRUaW1lciA9IHNldFRpbWVvdXQoKCkgPT4gdGhpcy5oZWFydGJlYXRUaW1lb3V0KCksIHRoaXMuaGVhcnRiZWF0SW50ZXJ2YWxNcylcbiAgfVxuXG4gIGZsdXNoU2VuZEJ1ZmZlcigpe1xuICAgIGlmKHRoaXMuaXNDb25uZWN0ZWQoKSAmJiB0aGlzLnNlbmRCdWZmZXIubGVuZ3RoID4gMCl7XG4gICAgICB0aGlzLnNlbmRCdWZmZXIuZm9yRWFjaChjYWxsYmFjayA9PiBjYWxsYmFjaygpKVxuICAgICAgdGhpcy5zZW5kQnVmZmVyID0gW11cbiAgICB9XG4gIH1cblxuICBvbkNvbm5NZXNzYWdlKHJhd01lc3NhZ2Upe1xuICAgIHRoaXMuZGVjb2RlKHJhd01lc3NhZ2UuZGF0YSwgbXNnID0+IHtcbiAgICAgIGxldCB7dG9waWMsIGV2ZW50LCBwYXlsb2FkLCByZWYsIGpvaW5fcmVmfSA9IG1zZ1xuICAgICAgaWYocmVmICYmIHJlZiA9PT0gdGhpcy5wZW5kaW5nSGVhcnRiZWF0UmVmKXtcbiAgICAgICAgdGhpcy5jbGVhckhlYXJ0YmVhdHMoKVxuICAgICAgICB0aGlzLnBlbmRpbmdIZWFydGJlYXRSZWYgPSBudWxsXG4gICAgICAgIHRoaXMuaGVhcnRiZWF0VGltZXIgPSBzZXRUaW1lb3V0KCgpID0+IHRoaXMuc2VuZEhlYXJ0YmVhdCgpLCB0aGlzLmhlYXJ0YmVhdEludGVydmFsTXMpXG4gICAgICB9XG5cbiAgICAgIGlmKHRoaXMuaGFzTG9nZ2VyKCkpIHRoaXMubG9nKFwicmVjZWl2ZVwiLCBgJHtwYXlsb2FkLnN0YXR1cyB8fCBcIlwifSAke3RvcGljfSAke2V2ZW50fSAke3JlZiAmJiBcIihcIiArIHJlZiArIFwiKVwiIHx8IFwiXCJ9YCwgcGF5bG9hZClcblxuICAgICAgZm9yKGxldCBpID0gMDsgaSA8IHRoaXMuY2hhbm5lbHMubGVuZ3RoOyBpKyspe1xuICAgICAgICBjb25zdCBjaGFubmVsID0gdGhpcy5jaGFubmVsc1tpXVxuICAgICAgICBpZighY2hhbm5lbC5pc01lbWJlcih0b3BpYywgZXZlbnQsIHBheWxvYWQsIGpvaW5fcmVmKSl7IGNvbnRpbnVlIH1cbiAgICAgICAgY2hhbm5lbC50cmlnZ2VyKGV2ZW50LCBwYXlsb2FkLCByZWYsIGpvaW5fcmVmKVxuICAgICAgfVxuXG4gICAgICBmb3IobGV0IGkgPSAwOyBpIDwgdGhpcy5zdGF0ZUNoYW5nZUNhbGxiYWNrcy5tZXNzYWdlLmxlbmd0aDsgaSsrKXtcbiAgICAgICAgbGV0IFssIGNhbGxiYWNrXSA9IHRoaXMuc3RhdGVDaGFuZ2VDYWxsYmFja3MubWVzc2FnZVtpXVxuICAgICAgICBjYWxsYmFjayhtc2cpXG4gICAgICB9XG4gICAgfSlcbiAgfVxuXG4gIGxlYXZlT3BlblRvcGljKHRvcGljKXtcbiAgICBsZXQgZHVwQ2hhbm5lbCA9IHRoaXMuY2hhbm5lbHMuZmluZChjID0+IGMudG9waWMgPT09IHRvcGljICYmIChjLmlzSm9pbmVkKCkgfHwgYy5pc0pvaW5pbmcoKSkpXG4gICAgaWYoZHVwQ2hhbm5lbCl7XG4gICAgICBpZih0aGlzLmhhc0xvZ2dlcigpKSB0aGlzLmxvZyhcInRyYW5zcG9ydFwiLCBgbGVhdmluZyBkdXBsaWNhdGUgdG9waWMgXCIke3RvcGljfVwiYClcbiAgICAgIGR1cENoYW5uZWwubGVhdmUoKVxuICAgIH1cbiAgfVxufVxuIiwgImV4cG9ydCBjb25zdCBDT05TRUNVVElWRV9SRUxPQURTID0gXCJjb25zZWN1dGl2ZS1yZWxvYWRzXCI7XG5leHBvcnQgY29uc3QgTUFYX1JFTE9BRFMgPSAxMDtcbmV4cG9ydCBjb25zdCBSRUxPQURfSklUVEVSX01JTiA9IDUwMDA7XG5leHBvcnQgY29uc3QgUkVMT0FEX0pJVFRFUl9NQVggPSAxMDAwMDtcbmV4cG9ydCBjb25zdCBGQUlMU0FGRV9KSVRURVIgPSAzMDAwMDtcbmV4cG9ydCBjb25zdCBQSFhfRVZFTlRfQ0xBU1NFUyA9IFtcbiAgXCJwaHgtY2xpY2stbG9hZGluZ1wiLFxuICBcInBoeC1jaGFuZ2UtbG9hZGluZ1wiLFxuICBcInBoeC1zdWJtaXQtbG9hZGluZ1wiLFxuICBcInBoeC1rZXlkb3duLWxvYWRpbmdcIixcbiAgXCJwaHgta2V5dXAtbG9hZGluZ1wiLFxuICBcInBoeC1ibHVyLWxvYWRpbmdcIixcbiAgXCJwaHgtZm9jdXMtbG9hZGluZ1wiLFxuICBcInBoeC1ob29rLWxvYWRpbmdcIixcbl07XG5leHBvcnQgY29uc3QgUEhYX0NPTVBPTkVOVCA9IFwiZGF0YS1waHgtY29tcG9uZW50XCI7XG5leHBvcnQgY29uc3QgUEhYX1ZJRVdfUkVGID0gXCJkYXRhLXBoeC12aWV3XCI7XG5leHBvcnQgY29uc3QgUEhYX0xJVkVfTElOSyA9IFwiZGF0YS1waHgtbGlua1wiO1xuZXhwb3J0IGNvbnN0IFBIWF9UUkFDS19TVEFUSUMgPSBcInRyYWNrLXN0YXRpY1wiO1xuZXhwb3J0IGNvbnN0IFBIWF9MSU5LX1NUQVRFID0gXCJkYXRhLXBoeC1saW5rLXN0YXRlXCI7XG5leHBvcnQgY29uc3QgUEhYX1JFRl9MT0FESU5HID0gXCJkYXRhLXBoeC1yZWYtbG9hZGluZ1wiO1xuZXhwb3J0IGNvbnN0IFBIWF9SRUZfU1JDID0gXCJkYXRhLXBoeC1yZWYtc3JjXCI7XG5leHBvcnQgY29uc3QgUEhYX1JFRl9MT0NLID0gXCJkYXRhLXBoeC1yZWYtbG9ja1wiO1xuZXhwb3J0IGNvbnN0IFBIWF9QRU5ESU5HX1JFRlMgPSBcInBoeC1wZW5kaW5nLXJlZnNcIjtcbmV4cG9ydCBjb25zdCBQSFhfVFJBQ0tfVVBMT0FEUyA9IFwidHJhY2stdXBsb2Fkc1wiO1xuZXhwb3J0IGNvbnN0IFBIWF9VUExPQURfUkVGID0gXCJkYXRhLXBoeC11cGxvYWQtcmVmXCI7XG5leHBvcnQgY29uc3QgUEhYX1BSRUZMSUdIVEVEX1JFRlMgPSBcImRhdGEtcGh4LXByZWZsaWdodGVkLXJlZnNcIjtcbmV4cG9ydCBjb25zdCBQSFhfRE9ORV9SRUZTID0gXCJkYXRhLXBoeC1kb25lLXJlZnNcIjtcbmV4cG9ydCBjb25zdCBQSFhfRFJPUF9UQVJHRVQgPSBcImRyb3AtdGFyZ2V0XCI7XG5leHBvcnQgY29uc3QgUEhYX0FDVElWRV9FTlRSWV9SRUZTID0gXCJkYXRhLXBoeC1hY3RpdmUtcmVmc1wiO1xuZXhwb3J0IGNvbnN0IFBIWF9MSVZFX0ZJTEVfVVBEQVRFRCA9IFwicGh4OmxpdmUtZmlsZTp1cGRhdGVkXCI7XG5leHBvcnQgY29uc3QgUEhYX1NLSVAgPSBcImRhdGEtcGh4LXNraXBcIjtcbmV4cG9ydCBjb25zdCBQSFhfTUFHSUNfSUQgPSBcImRhdGEtcGh4LWlkXCI7XG5leHBvcnQgY29uc3QgUEhYX1BSVU5FID0gXCJkYXRhLXBoeC1wcnVuZVwiO1xuZXhwb3J0IGNvbnN0IFBIWF9DT05ORUNURURfQ0xBU1MgPSBcInBoeC1jb25uZWN0ZWRcIjtcbmV4cG9ydCBjb25zdCBQSFhfTE9BRElOR19DTEFTUyA9IFwicGh4LWxvYWRpbmdcIjtcbmV4cG9ydCBjb25zdCBQSFhfRVJST1JfQ0xBU1MgPSBcInBoeC1lcnJvclwiO1xuZXhwb3J0IGNvbnN0IFBIWF9DTElFTlRfRVJST1JfQ0xBU1MgPSBcInBoeC1jbGllbnQtZXJyb3JcIjtcbmV4cG9ydCBjb25zdCBQSFhfU0VSVkVSX0VSUk9SX0NMQVNTID0gXCJwaHgtc2VydmVyLWVycm9yXCI7XG5leHBvcnQgY29uc3QgUEhYX1BBUkVOVF9JRCA9IFwiZGF0YS1waHgtcGFyZW50LWlkXCI7XG5leHBvcnQgY29uc3QgUEhYX01BSU4gPSBcImRhdGEtcGh4LW1haW5cIjtcbmV4cG9ydCBjb25zdCBQSFhfUk9PVF9JRCA9IFwiZGF0YS1waHgtcm9vdC1pZFwiO1xuZXhwb3J0IGNvbnN0IFBIWF9WSUVXUE9SVF9UT1AgPSBcInZpZXdwb3J0LXRvcFwiO1xuZXhwb3J0IGNvbnN0IFBIWF9WSUVXUE9SVF9CT1RUT00gPSBcInZpZXdwb3J0LWJvdHRvbVwiO1xuZXhwb3J0IGNvbnN0IFBIWF9UUklHR0VSX0FDVElPTiA9IFwidHJpZ2dlci1hY3Rpb25cIjtcbmV4cG9ydCBjb25zdCBQSFhfSEFTX0ZPQ1VTRUQgPSBcInBoeC1oYXMtZm9jdXNlZFwiO1xuZXhwb3J0IGNvbnN0IEZPQ1VTQUJMRV9JTlBVVFMgPSBbXG4gIFwidGV4dFwiLFxuICBcInRleHRhcmVhXCIsXG4gIFwibnVtYmVyXCIsXG4gIFwiZW1haWxcIixcbiAgXCJwYXNzd29yZFwiLFxuICBcInNlYXJjaFwiLFxuICBcInRlbFwiLFxuICBcInVybFwiLFxuICBcImRhdGVcIixcbiAgXCJ0aW1lXCIsXG4gIFwiZGF0ZXRpbWUtbG9jYWxcIixcbiAgXCJjb2xvclwiLFxuICBcInJhbmdlXCIsXG5dO1xuZXhwb3J0IGNvbnN0IENIRUNLQUJMRV9JTlBVVFMgPSBbXCJjaGVja2JveFwiLCBcInJhZGlvXCJdO1xuZXhwb3J0IGNvbnN0IFBIWF9IQVNfU1VCTUlUVEVEID0gXCJwaHgtaGFzLXN1Ym1pdHRlZFwiO1xuZXhwb3J0IGNvbnN0IFBIWF9TRVNTSU9OID0gXCJkYXRhLXBoeC1zZXNzaW9uXCI7XG5leHBvcnQgY29uc3QgUEhYX1ZJRVdfU0VMRUNUT1IgPSBgWyR7UEhYX1NFU1NJT059XWA7XG5leHBvcnQgY29uc3QgUEhYX1NUSUNLWSA9IFwiZGF0YS1waHgtc3RpY2t5XCI7XG5leHBvcnQgY29uc3QgUEhYX1NUQVRJQyA9IFwiZGF0YS1waHgtc3RhdGljXCI7XG5leHBvcnQgY29uc3QgUEhYX1JFQURPTkxZID0gXCJkYXRhLXBoeC1yZWFkb25seVwiO1xuZXhwb3J0IGNvbnN0IFBIWF9ESVNBQkxFRCA9IFwiZGF0YS1waHgtZGlzYWJsZWRcIjtcbmV4cG9ydCBjb25zdCBQSFhfRElTQUJMRV9XSVRIID0gXCJkaXNhYmxlLXdpdGhcIjtcbmV4cG9ydCBjb25zdCBQSFhfRElTQUJMRV9XSVRIX1JFU1RPUkUgPSBcImRhdGEtcGh4LWRpc2FibGUtd2l0aC1yZXN0b3JlXCI7XG5leHBvcnQgY29uc3QgUEhYX0hPT0sgPSBcImhvb2tcIjtcbmV4cG9ydCBjb25zdCBQSFhfREVCT1VOQ0UgPSBcImRlYm91bmNlXCI7XG5leHBvcnQgY29uc3QgUEhYX1RIUk9UVExFID0gXCJ0aHJvdHRsZVwiO1xuZXhwb3J0IGNvbnN0IFBIWF9VUERBVEUgPSBcInVwZGF0ZVwiO1xuZXhwb3J0IGNvbnN0IFBIWF9TVFJFQU0gPSBcInN0cmVhbVwiO1xuZXhwb3J0IGNvbnN0IFBIWF9TVFJFQU1fUkVGID0gXCJkYXRhLXBoeC1zdHJlYW1cIjtcbmV4cG9ydCBjb25zdCBQSFhfUE9SVEFMID0gXCJkYXRhLXBoeC1wb3J0YWxcIjtcbmV4cG9ydCBjb25zdCBQSFhfVEVMRVBPUlRFRF9SRUYgPSBcImRhdGEtcGh4LXRlbGVwb3J0ZWRcIjtcbmV4cG9ydCBjb25zdCBQSFhfVEVMRVBPUlRFRF9TUkMgPSBcImRhdGEtcGh4LXRlbGVwb3J0ZWQtc3JjXCI7XG5leHBvcnQgY29uc3QgUEhYX1JVTlRJTUVfSE9PSyA9IFwiZGF0YS1waHgtcnVudGltZS1ob29rXCI7XG5leHBvcnQgY29uc3QgUEhYX0xWX1BJRCA9IFwiZGF0YS1waHgtcGlkXCI7XG5leHBvcnQgY29uc3QgUEhYX0tFWSA9IFwia2V5XCI7XG5leHBvcnQgY29uc3QgUEhYX1BSSVZBVEUgPSBcInBoeFByaXZhdGVcIjtcbmV4cG9ydCBjb25zdCBQSFhfQVVUT19SRUNPVkVSID0gXCJhdXRvLXJlY292ZXJcIjtcbmV4cG9ydCBjb25zdCBQSFhfTFZfREVCVUcgPSBcInBoeDpsaXZlLXNvY2tldDpkZWJ1Z1wiO1xuZXhwb3J0IGNvbnN0IFBIWF9MVl9QUk9GSUxFID0gXCJwaHg6bGl2ZS1zb2NrZXQ6cHJvZmlsaW5nXCI7XG5leHBvcnQgY29uc3QgUEhYX0xWX0xBVEVOQ1lfU0lNID0gXCJwaHg6bGl2ZS1zb2NrZXQ6bGF0ZW5jeS1zaW1cIjtcbmV4cG9ydCBjb25zdCBQSFhfTFZfSElTVE9SWV9QT1NJVElPTiA9IFwicGh4Om5hdi1oaXN0b3J5LXBvc2l0aW9uXCI7XG5leHBvcnQgY29uc3QgUEhYX1BST0dSRVNTID0gXCJwcm9ncmVzc1wiO1xuZXhwb3J0IGNvbnN0IFBIWF9NT1VOVEVEID0gXCJtb3VudGVkXCI7XG5leHBvcnQgY29uc3QgUEhYX1JFTE9BRF9TVEFUVVMgPSBcIl9fcGhvZW5peF9yZWxvYWRfc3RhdHVzX19cIjtcbmV4cG9ydCBjb25zdCBMT0FERVJfVElNRU9VVCA9IDE7XG5leHBvcnQgY29uc3QgTUFYX0NISUxEX0pPSU5fQVRURU1QVFMgPSAzO1xuZXhwb3J0IGNvbnN0IEJFRk9SRV9VTkxPQURfTE9BREVSX1RJTUVPVVQgPSAyMDA7XG5leHBvcnQgY29uc3QgRElTQ09OTkVDVEVEX1RJTUVPVVQgPSA1MDA7XG5leHBvcnQgY29uc3QgQklORElOR19QUkVGSVggPSBcInBoeC1cIjtcbmV4cG9ydCBjb25zdCBQVVNIX1RJTUVPVVQgPSAzMDAwMDtcbmV4cG9ydCBjb25zdCBMSU5LX0hFQURFUiA9IFwieC1yZXF1ZXN0ZWQtd2l0aFwiO1xuZXhwb3J0IGNvbnN0IFJFU1BPTlNFX1VSTF9IRUFERVIgPSBcIngtcmVzcG9uc2UtdXJsXCI7XG5leHBvcnQgY29uc3QgREVCT1VOQ0VfVFJJR0dFUiA9IFwiZGVib3VuY2UtdHJpZ2dlclwiO1xuZXhwb3J0IGNvbnN0IFRIUk9UVExFRCA9IFwidGhyb3R0bGVkXCI7XG5leHBvcnQgY29uc3QgREVCT1VOQ0VfUFJFVl9LRVkgPSBcImRlYm91bmNlLXByZXYta2V5XCI7XG5leHBvcnQgY29uc3QgREVGQVVMVFMgPSB7XG4gIGRlYm91bmNlOiAzMDAsXG4gIHRocm90dGxlOiAzMDAsXG59O1xuZXhwb3J0IGNvbnN0IFBIWF9QRU5ESU5HX0FUVFJTID0gW1BIWF9SRUZfTE9BRElORywgUEhYX1JFRl9TUkMsIFBIWF9SRUZfTE9DS107XG4vLyBSZW5kZXJlZFxuZXhwb3J0IGNvbnN0IFNUQVRJQyA9IFwic1wiO1xuZXhwb3J0IGNvbnN0IFJPT1QgPSBcInJcIjtcbmV4cG9ydCBjb25zdCBDT01QT05FTlRTID0gXCJjXCI7XG5leHBvcnQgY29uc3QgS0VZRUQgPSBcImtcIjtcbmV4cG9ydCBjb25zdCBLRVlFRF9DT1VOVCA9IFwia2NcIjtcbmV4cG9ydCBjb25zdCBFVkVOVFMgPSBcImVcIjtcbmV4cG9ydCBjb25zdCBSRVBMWSA9IFwiclwiO1xuZXhwb3J0IGNvbnN0IFRJVExFID0gXCJ0XCI7XG5leHBvcnQgY29uc3QgVEVNUExBVEVTID0gXCJwXCI7XG5leHBvcnQgY29uc3QgU1RSRUFNID0gXCJzdHJlYW1cIjtcbiIsICJpbXBvcnQgeyBsb2dFcnJvciB9IGZyb20gXCIuL3V0aWxzXCI7XG5cbmV4cG9ydCBkZWZhdWx0IGNsYXNzIEVudHJ5VXBsb2FkZXIge1xuICBjb25zdHJ1Y3RvcihlbnRyeSwgY29uZmlnLCBsaXZlU29ja2V0KSB7XG4gICAgY29uc3QgeyBjaHVua19zaXplLCBjaHVua190aW1lb3V0IH0gPSBjb25maWc7XG4gICAgdGhpcy5saXZlU29ja2V0ID0gbGl2ZVNvY2tldDtcbiAgICB0aGlzLmVudHJ5ID0gZW50cnk7XG4gICAgdGhpcy5vZmZzZXQgPSAwO1xuICAgIHRoaXMuY2h1bmtTaXplID0gY2h1bmtfc2l6ZTtcbiAgICB0aGlzLmNodW5rVGltZW91dCA9IGNodW5rX3RpbWVvdXQ7XG4gICAgdGhpcy5jaHVua1RpbWVyID0gbnVsbDtcbiAgICB0aGlzLmVycm9yZWQgPSBmYWxzZTtcbiAgICB0aGlzLnVwbG9hZENoYW5uZWwgPSBsaXZlU29ja2V0LmNoYW5uZWwoYGx2dToke2VudHJ5LnJlZn1gLCB7XG4gICAgICB0b2tlbjogZW50cnkubWV0YWRhdGEoKSxcbiAgICB9KTtcbiAgfVxuXG4gIGVycm9yKHJlYXNvbikge1xuICAgIGlmICh0aGlzLmVycm9yZWQpIHtcbiAgICAgIHJldHVybjtcbiAgICB9XG4gICAgdGhpcy51cGxvYWRDaGFubmVsLmxlYXZlKCk7XG4gICAgdGhpcy5lcnJvcmVkID0gdHJ1ZTtcbiAgICBjbGVhclRpbWVvdXQodGhpcy5jaHVua1RpbWVyKTtcbiAgICB0aGlzLmVudHJ5LmVycm9yKHJlYXNvbik7XG4gIH1cblxuICB1cGxvYWQoKSB7XG4gICAgdGhpcy51cGxvYWRDaGFubmVsLm9uRXJyb3IoKHJlYXNvbikgPT4gdGhpcy5lcnJvcihyZWFzb24pKTtcbiAgICB0aGlzLnVwbG9hZENoYW5uZWxcbiAgICAgIC5qb2luKClcbiAgICAgIC5yZWNlaXZlKFwib2tcIiwgKF9kYXRhKSA9PiB0aGlzLnJlYWROZXh0Q2h1bmsoKSlcbiAgICAgIC5yZWNlaXZlKFwiZXJyb3JcIiwgKHJlYXNvbikgPT4gdGhpcy5lcnJvcihyZWFzb24pKTtcbiAgfVxuXG4gIGlzRG9uZSgpIHtcbiAgICByZXR1cm4gdGhpcy5vZmZzZXQgPj0gdGhpcy5lbnRyeS5maWxlLnNpemU7XG4gIH1cblxuICByZWFkTmV4dENodW5rKCkge1xuICAgIGNvbnN0IHJlYWRlciA9IG5ldyB3aW5kb3cuRmlsZVJlYWRlcigpO1xuICAgIGNvbnN0IGJsb2IgPSB0aGlzLmVudHJ5LmZpbGUuc2xpY2UoXG4gICAgICB0aGlzLm9mZnNldCxcbiAgICAgIHRoaXMuY2h1bmtTaXplICsgdGhpcy5vZmZzZXQsXG4gICAgKTtcbiAgICByZWFkZXIub25sb2FkID0gKGUpID0+IHtcbiAgICAgIGlmIChlLnRhcmdldC5lcnJvciA9PT0gbnVsbCkge1xuICAgICAgICB0aGlzLm9mZnNldCArPSAvKiogQHR5cGUge0FycmF5QnVmZmVyfSAqLyAoZS50YXJnZXQucmVzdWx0KS5ieXRlTGVuZ3RoO1xuICAgICAgICB0aGlzLnB1c2hDaHVuaygvKiogQHR5cGUge0FycmF5QnVmZmVyfSAqLyAoZS50YXJnZXQucmVzdWx0KSk7XG4gICAgICB9IGVsc2Uge1xuICAgICAgICByZXR1cm4gbG9nRXJyb3IoXCJSZWFkIGVycm9yOiBcIiArIGUudGFyZ2V0LmVycm9yKTtcbiAgICAgIH1cbiAgICB9O1xuICAgIHJlYWRlci5yZWFkQXNBcnJheUJ1ZmZlcihibG9iKTtcbiAgfVxuXG4gIHB1c2hDaHVuayhjaHVuaykge1xuICAgIGlmICghdGhpcy51cGxvYWRDaGFubmVsLmlzSm9pbmVkKCkpIHtcbiAgICAgIHJldHVybjtcbiAgICB9XG4gICAgdGhpcy51cGxvYWRDaGFubmVsXG4gICAgICAucHVzaChcImNodW5rXCIsIGNodW5rLCB0aGlzLmNodW5rVGltZW91dClcbiAgICAgIC5yZWNlaXZlKFwib2tcIiwgKCkgPT4ge1xuICAgICAgICB0aGlzLmVudHJ5LnByb2dyZXNzKCh0aGlzLm9mZnNldCAvIHRoaXMuZW50cnkuZmlsZS5zaXplKSAqIDEwMCk7XG4gICAgICAgIGlmICghdGhpcy5pc0RvbmUoKSkge1xuICAgICAgICAgIHRoaXMuY2h1bmtUaW1lciA9IHNldFRpbWVvdXQoXG4gICAgICAgICAgICAoKSA9PiB0aGlzLnJlYWROZXh0Q2h1bmsoKSxcbiAgICAgICAgICAgIHRoaXMubGl2ZVNvY2tldC5nZXRMYXRlbmN5U2ltKCkgfHwgMCxcbiAgICAgICAgICApO1xuICAgICAgICB9XG4gICAgICB9KVxuICAgICAgLnJlY2VpdmUoXCJlcnJvclwiLCAoeyByZWFzb24gfSkgPT4gdGhpcy5lcnJvcihyZWFzb24pKTtcbiAgfVxufVxuIiwgImltcG9ydCB7IFBIWF9WSUVXX1NFTEVDVE9SIH0gZnJvbSBcIi4vY29uc3RhbnRzXCI7XG5cbmltcG9ydCBFbnRyeVVwbG9hZGVyIGZyb20gXCIuL2VudHJ5X3VwbG9hZGVyXCI7XG5cbmV4cG9ydCBjb25zdCBsb2dFcnJvciA9IChtc2csIG9iaikgPT4gY29uc29sZS5lcnJvciAmJiBjb25zb2xlLmVycm9yKG1zZywgb2JqKTtcblxuZXhwb3J0IGNvbnN0IGlzQ2lkID0gKGNpZCkgPT4ge1xuICBjb25zdCB0eXBlID0gdHlwZW9mIGNpZDtcbiAgcmV0dXJuIHR5cGUgPT09IFwibnVtYmVyXCIgfHwgKHR5cGUgPT09IFwic3RyaW5nXCIgJiYgL14oMHxbMS05XVxcZCopJC8udGVzdChjaWQpKTtcbn07XG5cbmV4cG9ydCBmdW5jdGlvbiBkZXRlY3REdXBsaWNhdGVJZHMoKSB7XG4gIGNvbnN0IGlkcyA9IG5ldyBTZXQoKTtcbiAgY29uc3QgZWxlbXMgPSBkb2N1bWVudC5xdWVyeVNlbGVjdG9yQWxsKFwiKltpZF1cIik7XG4gIGZvciAobGV0IGkgPSAwLCBsZW4gPSBlbGVtcy5sZW5ndGg7IGkgPCBsZW47IGkrKykge1xuICAgIGlmIChpZHMuaGFzKGVsZW1zW2ldLmlkKSkge1xuICAgICAgY29uc29sZS5lcnJvcihcbiAgICAgICAgYE11bHRpcGxlIElEcyBkZXRlY3RlZDogJHtlbGVtc1tpXS5pZH0uIEVuc3VyZSB1bmlxdWUgZWxlbWVudCBpZHMuYCxcbiAgICAgICk7XG4gICAgfSBlbHNlIHtcbiAgICAgIGlkcy5hZGQoZWxlbXNbaV0uaWQpO1xuICAgIH1cbiAgfVxufVxuXG5leHBvcnQgZnVuY3Rpb24gZGV0ZWN0SW52YWxpZFN0cmVhbUluc2VydHMoaW5zZXJ0cykge1xuICBjb25zdCBlcnJvcnMgPSBuZXcgU2V0KCk7XG4gIE9iamVjdC5rZXlzKGluc2VydHMpLmZvckVhY2goKGlkKSA9PiB7XG4gICAgY29uc3Qgc3RyZWFtRWwgPSBkb2N1bWVudC5nZXRFbGVtZW50QnlJZChpZCk7XG4gICAgaWYgKFxuICAgICAgc3RyZWFtRWwgJiZcbiAgICAgIHN0cmVhbUVsLnBhcmVudEVsZW1lbnQgJiZcbiAgICAgIHN0cmVhbUVsLnBhcmVudEVsZW1lbnQuZ2V0QXR0cmlidXRlKFwicGh4LXVwZGF0ZVwiKSAhPT0gXCJzdHJlYW1cIlxuICAgICkge1xuICAgICAgZXJyb3JzLmFkZChcbiAgICAgICAgYFRoZSBzdHJlYW0gY29udGFpbmVyIHdpdGggaWQgXCIke3N0cmVhbUVsLnBhcmVudEVsZW1lbnQuaWR9XCIgaXMgbWlzc2luZyB0aGUgcGh4LXVwZGF0ZT1cInN0cmVhbVwiIGF0dHJpYnV0ZS4gRW5zdXJlIGl0IGlzIHNldCBmb3Igc3RyZWFtcyB0byB3b3JrIHByb3Blcmx5LmAsXG4gICAgICApO1xuICAgIH1cbiAgfSk7XG4gIGVycm9ycy5mb3JFYWNoKChlcnJvcikgPT4gY29uc29sZS5lcnJvcihlcnJvcikpO1xufVxuXG5leHBvcnQgY29uc3QgZGVidWcgPSAodmlldywga2luZCwgbXNnLCBvYmopID0+IHtcbiAgaWYgKHZpZXcubGl2ZVNvY2tldC5pc0RlYnVnRW5hYmxlZCgpKSB7XG4gICAgY29uc29sZS5sb2coYCR7dmlldy5pZH0gJHtraW5kfTogJHttc2d9IC0gYCwgb2JqKTtcbiAgfVxufTtcblxuLy8gd3JhcHMgdmFsdWUgaW4gY2xvc3VyZSBvciByZXR1cm5zIGNsb3N1cmVcbmV4cG9ydCBjb25zdCBjbG9zdXJlID0gKHZhbCkgPT5cbiAgdHlwZW9mIHZhbCA9PT0gXCJmdW5jdGlvblwiXG4gICAgPyB2YWxcbiAgICA6IGZ1bmN0aW9uICgpIHtcbiAgICAgICAgcmV0dXJuIHZhbDtcbiAgICAgIH07XG5cbmV4cG9ydCBjb25zdCBjbG9uZSA9IChvYmopID0+IHtcbiAgcmV0dXJuIEpTT04ucGFyc2UoSlNPTi5zdHJpbmdpZnkob2JqKSk7XG59O1xuXG5leHBvcnQgY29uc3QgY2xvc2VzdFBoeEJpbmRpbmcgPSAoZWwsIGJpbmRpbmcsIGJvcmRlckVsKSA9PiB7XG4gIGRvIHtcbiAgICBpZiAoZWwubWF0Y2hlcyhgWyR7YmluZGluZ31dYCkgJiYgIWVsLmRpc2FibGVkKSB7XG4gICAgICByZXR1cm4gZWw7XG4gICAgfVxuICAgIGVsID0gZWwucGFyZW50RWxlbWVudCB8fCBlbC5wYXJlbnROb2RlO1xuICB9IHdoaWxlIChcbiAgICBlbCAhPT0gbnVsbCAmJlxuICAgIGVsLm5vZGVUeXBlID09PSAxICYmXG4gICAgISgoYm9yZGVyRWwgJiYgYm9yZGVyRWwuaXNTYW1lTm9kZShlbCkpIHx8IGVsLm1hdGNoZXMoUEhYX1ZJRVdfU0VMRUNUT1IpKVxuICApO1xuICByZXR1cm4gbnVsbDtcbn07XG5cbmV4cG9ydCBjb25zdCBpc09iamVjdCA9IChvYmopID0+IHtcbiAgcmV0dXJuIG9iaiAhPT0gbnVsbCAmJiB0eXBlb2Ygb2JqID09PSBcIm9iamVjdFwiICYmICEob2JqIGluc3RhbmNlb2YgQXJyYXkpO1xufTtcblxuZXhwb3J0IGNvbnN0IGlzRXF1YWxPYmogPSAob2JqMSwgb2JqMikgPT5cbiAgSlNPTi5zdHJpbmdpZnkob2JqMSkgPT09IEpTT04uc3RyaW5naWZ5KG9iajIpO1xuXG5leHBvcnQgY29uc3QgaXNFbXB0eSA9IChvYmopID0+IHtcbiAgZm9yIChjb25zdCB4IGluIG9iaikge1xuICAgIHJldHVybiBmYWxzZTtcbiAgfVxuICByZXR1cm4gdHJ1ZTtcbn07XG5cbmV4cG9ydCBjb25zdCBtYXliZSA9IChlbCwgY2FsbGJhY2spID0+IGVsICYmIGNhbGxiYWNrKGVsKTtcblxuZXhwb3J0IGNvbnN0IGNoYW5uZWxVcGxvYWRlciA9IGZ1bmN0aW9uIChlbnRyaWVzLCBvbkVycm9yLCByZXNwLCBsaXZlU29ja2V0KSB7XG4gIGVudHJpZXMuZm9yRWFjaCgoZW50cnkpID0+IHtcbiAgICBjb25zdCBlbnRyeVVwbG9hZGVyID0gbmV3IEVudHJ5VXBsb2FkZXIoZW50cnksIHJlc3AuY29uZmlnLCBsaXZlU29ja2V0KTtcbiAgICBlbnRyeVVwbG9hZGVyLnVwbG9hZCgpO1xuICB9KTtcbn07XG4iLCAiY29uc3QgQnJvd3NlciA9IHtcbiAgY2FuUHVzaFN0YXRlKCkge1xuICAgIHJldHVybiB0eXBlb2YgaGlzdG9yeS5wdXNoU3RhdGUgIT09IFwidW5kZWZpbmVkXCI7XG4gIH0sXG5cbiAgZHJvcExvY2FsKGxvY2FsU3RvcmFnZSwgbmFtZXNwYWNlLCBzdWJrZXkpIHtcbiAgICByZXR1cm4gbG9jYWxTdG9yYWdlLnJlbW92ZUl0ZW0odGhpcy5sb2NhbEtleShuYW1lc3BhY2UsIHN1YmtleSkpO1xuICB9LFxuXG4gIHVwZGF0ZUxvY2FsKGxvY2FsU3RvcmFnZSwgbmFtZXNwYWNlLCBzdWJrZXksIGluaXRpYWwsIGZ1bmMpIHtcbiAgICBjb25zdCBjdXJyZW50ID0gdGhpcy5nZXRMb2NhbChsb2NhbFN0b3JhZ2UsIG5hbWVzcGFjZSwgc3Via2V5KTtcbiAgICBjb25zdCBrZXkgPSB0aGlzLmxvY2FsS2V5KG5hbWVzcGFjZSwgc3Via2V5KTtcbiAgICBjb25zdCBuZXdWYWwgPSBjdXJyZW50ID09PSBudWxsID8gaW5pdGlhbCA6IGZ1bmMoY3VycmVudCk7XG4gICAgbG9jYWxTdG9yYWdlLnNldEl0ZW0oa2V5LCBKU09OLnN0cmluZ2lmeShuZXdWYWwpKTtcbiAgICByZXR1cm4gbmV3VmFsO1xuICB9LFxuXG4gIGdldExvY2FsKGxvY2FsU3RvcmFnZSwgbmFtZXNwYWNlLCBzdWJrZXkpIHtcbiAgICByZXR1cm4gSlNPTi5wYXJzZShsb2NhbFN0b3JhZ2UuZ2V0SXRlbSh0aGlzLmxvY2FsS2V5KG5hbWVzcGFjZSwgc3Via2V5KSkpO1xuICB9LFxuXG4gIHVwZGF0ZUN1cnJlbnRTdGF0ZShjYWxsYmFjaykge1xuICAgIGlmICghdGhpcy5jYW5QdXNoU3RhdGUoKSkge1xuICAgICAgcmV0dXJuO1xuICAgIH1cbiAgICBoaXN0b3J5LnJlcGxhY2VTdGF0ZShcbiAgICAgIGNhbGxiYWNrKGhpc3Rvcnkuc3RhdGUgfHwge30pLFxuICAgICAgXCJcIixcbiAgICAgIHdpbmRvdy5sb2NhdGlvbi5ocmVmLFxuICAgICk7XG4gIH0sXG5cbiAgcHVzaFN0YXRlKGtpbmQsIG1ldGEsIHRvKSB7XG4gICAgaWYgKHRoaXMuY2FuUHVzaFN0YXRlKCkpIHtcbiAgICAgIGlmICh0byAhPT0gd2luZG93LmxvY2F0aW9uLmhyZWYpIHtcbiAgICAgICAgaWYgKG1ldGEudHlwZSA9PSBcInJlZGlyZWN0XCIgJiYgbWV0YS5zY3JvbGwpIHtcbiAgICAgICAgICAvLyBJZiB3ZSdyZSByZWRpcmVjdGluZyBzdG9yZSB0aGUgY3VycmVudCBzY3JvbGxZIGZvciB0aGUgY3VycmVudCBoaXN0b3J5IHN0YXRlLlxuICAgICAgICAgIGNvbnN0IGN1cnJlbnRTdGF0ZSA9IGhpc3Rvcnkuc3RhdGUgfHwge307XG4gICAgICAgICAgY3VycmVudFN0YXRlLnNjcm9sbCA9IG1ldGEuc2Nyb2xsO1xuICAgICAgICAgIGhpc3RvcnkucmVwbGFjZVN0YXRlKGN1cnJlbnRTdGF0ZSwgXCJcIiwgd2luZG93LmxvY2F0aW9uLmhyZWYpO1xuICAgICAgICB9XG5cbiAgICAgICAgZGVsZXRlIG1ldGEuc2Nyb2xsOyAvLyBPbmx5IHN0b3JlIHRoZSBzY3JvbGwgaW4gdGhlIHJlZGlyZWN0IGNhc2UuXG4gICAgICAgIGhpc3Rvcnlba2luZCArIFwiU3RhdGVcIl0obWV0YSwgXCJcIiwgdG8gfHwgbnVsbCk7IC8vIElFIHdpbGwgY29lcmNlIHVuZGVmaW5lZCB0byBzdHJpbmdcblxuICAgICAgICAvLyB3aGVuIHVzaW5nIG5hdmlnYXRlLCB3ZSdkIGNhbGwgcHVzaFN0YXRlIGltbWVkaWF0ZWx5IGJlZm9yZSBwYXRjaGluZyB0aGUgRE9NLFxuICAgICAgICAvLyBqdW1waW5nIGJhY2sgdG8gdGhlIHRvcCBvZiB0aGUgcGFnZSwgZWZmZWN0aXZlbHkgaWdub3JpbmcgdGhlIHNjcm9sbEludG9WaWV3O1xuICAgICAgICAvLyB0aGVyZWZvcmUgd2Ugd2FpdCBmb3IgdGhlIG5leHQgZnJhbWUgKGFmdGVyIHRoZSBET00gcGF0Y2gpIGFuZCBvbmx5IHRoZW4gdHJ5XG4gICAgICAgIC8vIHRvIHNjcm9sbCB0byB0aGUgaGFzaEVsXG4gICAgICAgIHdpbmRvdy5yZXF1ZXN0QW5pbWF0aW9uRnJhbWUoKCkgPT4ge1xuICAgICAgICAgIGNvbnN0IGhhc2hFbCA9IHRoaXMuZ2V0SGFzaFRhcmdldEVsKHdpbmRvdy5sb2NhdGlvbi5oYXNoKTtcblxuICAgICAgICAgIGlmIChoYXNoRWwpIHtcbiAgICAgICAgICAgIGhhc2hFbC5zY3JvbGxJbnRvVmlldygpO1xuICAgICAgICAgIH0gZWxzZSBpZiAobWV0YS50eXBlID09PSBcInJlZGlyZWN0XCIpIHtcbiAgICAgICAgICAgIHdpbmRvdy5zY3JvbGwoMCwgMCk7XG4gICAgICAgICAgfVxuICAgICAgICB9KTtcbiAgICAgIH1cbiAgICB9IGVsc2Uge1xuICAgICAgdGhpcy5yZWRpcmVjdCh0byk7XG4gICAgfVxuICB9LFxuXG4gIHNldENvb2tpZShuYW1lLCB2YWx1ZSwgbWF4QWdlU2Vjb25kcykge1xuICAgIGNvbnN0IGV4cGlyZXMgPVxuICAgICAgdHlwZW9mIG1heEFnZVNlY29uZHMgPT09IFwibnVtYmVyXCIgPyBgIG1heC1hZ2U9JHttYXhBZ2VTZWNvbmRzfTtgIDogXCJcIjtcbiAgICBkb2N1bWVudC5jb29raWUgPSBgJHtuYW1lfT0ke3ZhbHVlfTske2V4cGlyZXN9IHBhdGg9L2A7XG4gIH0sXG5cbiAgZ2V0Q29va2llKG5hbWUpIHtcbiAgICByZXR1cm4gZG9jdW1lbnQuY29va2llLnJlcGxhY2UoXG4gICAgICBuZXcgUmVnRXhwKGAoPzooPzpefC4qO1xccyopJHtuYW1lfVxccypcXD1cXHMqKFteO10qKS4qJCl8Xi4qJGApLFxuICAgICAgXCIkMVwiLFxuICAgICk7XG4gIH0sXG5cbiAgZGVsZXRlQ29va2llKG5hbWUpIHtcbiAgICBkb2N1bWVudC5jb29raWUgPSBgJHtuYW1lfT07IG1heC1hZ2U9LTE7IHBhdGg9L2A7XG4gIH0sXG5cbiAgcmVkaXJlY3QoXG4gICAgdG9VUkwsXG4gICAgZmxhc2gsXG4gICAgbmF2aWdhdGUgPSAodXJsKSA9PiB7XG4gICAgICB3aW5kb3cubG9jYXRpb24uaHJlZiA9IHVybDtcbiAgICB9LFxuICApIHtcbiAgICBpZiAoZmxhc2gpIHtcbiAgICAgIHRoaXMuc2V0Q29va2llKFwiX19waG9lbml4X2ZsYXNoX19cIiwgZmxhc2gsIDYwKTtcbiAgICB9XG4gICAgbmF2aWdhdGUodG9VUkwpO1xuICB9LFxuXG4gIGxvY2FsS2V5KG5hbWVzcGFjZSwgc3Via2V5KSB7XG4gICAgcmV0dXJuIGAke25hbWVzcGFjZX0tJHtzdWJrZXl9YDtcbiAgfSxcblxuICBnZXRIYXNoVGFyZ2V0RWwobWF5YmVIYXNoKSB7XG4gICAgY29uc3QgaGFzaCA9IG1heWJlSGFzaC50b1N0cmluZygpLnN1YnN0cmluZygxKTtcbiAgICBpZiAoaGFzaCA9PT0gXCJcIikge1xuICAgICAgcmV0dXJuO1xuICAgIH1cbiAgICByZXR1cm4gKFxuICAgICAgZG9jdW1lbnQuZ2V0RWxlbWVudEJ5SWQoaGFzaCkgfHxcbiAgICAgIGRvY3VtZW50LnF1ZXJ5U2VsZWN0b3IoYGFbbmFtZT1cIiR7aGFzaH1cIl1gKVxuICAgICk7XG4gIH0sXG59O1xuXG5leHBvcnQgZGVmYXVsdCBCcm93c2VyO1xuIiwgImltcG9ydCB7XG4gIENIRUNLQUJMRV9JTlBVVFMsXG4gIERFQk9VTkNFX1BSRVZfS0VZLFxuICBERUJPVU5DRV9UUklHR0VSLFxuICBGT0NVU0FCTEVfSU5QVVRTLFxuICBQSFhfQ09NUE9ORU5ULFxuICBQSFhfVklFV19SRUYsXG4gIFBIWF9URUxFUE9SVEVEX1JFRixcbiAgUEhYX0hBU19GT0NVU0VELFxuICBQSFhfSEFTX1NVQk1JVFRFRCxcbiAgUEhYX01BSU4sXG4gIFBIWF9QQVJFTlRfSUQsXG4gIFBIWF9QUklWQVRFLFxuICBQSFhfUkVGX1NSQyxcbiAgUEhYX1JFRl9MT0NLLFxuICBQSFhfUEVORElOR19BVFRSUyxcbiAgUEhYX1JPT1RfSUQsXG4gIFBIWF9TRVNTSU9OLFxuICBQSFhfU1RBVElDLFxuICBQSFhfVVBMT0FEX1JFRixcbiAgUEhYX1ZJRVdfU0VMRUNUT1IsXG4gIFBIWF9TVElDS1ksXG4gIFBIWF9FVkVOVF9DTEFTU0VTLFxuICBUSFJPVFRMRUQsXG4gIFBIWF9QT1JUQUwsXG4gIFBIWF9TVFJFQU0sXG59IGZyb20gXCIuL2NvbnN0YW50c1wiO1xuXG5pbXBvcnQgeyBsb2dFcnJvciB9IGZyb20gXCIuL3V0aWxzXCI7XG5cbmNvbnN0IERPTSA9IHtcbiAgYnlJZChpZCkge1xuICAgIHJldHVybiBkb2N1bWVudC5nZXRFbGVtZW50QnlJZChpZCkgfHwgbG9nRXJyb3IoYG5vIGlkIGZvdW5kIGZvciAke2lkfWApO1xuICB9LFxuXG4gIHJlbW92ZUNsYXNzKGVsLCBjbGFzc05hbWUpIHtcbiAgICBlbC5jbGFzc0xpc3QucmVtb3ZlKGNsYXNzTmFtZSk7XG4gICAgaWYgKGVsLmNsYXNzTGlzdC5sZW5ndGggPT09IDApIHtcbiAgICAgIGVsLnJlbW92ZUF0dHJpYnV0ZShcImNsYXNzXCIpO1xuICAgIH1cbiAgfSxcblxuICBhbGwobm9kZSwgcXVlcnksIGNhbGxiYWNrKSB7XG4gICAgaWYgKCFub2RlKSB7XG4gICAgICByZXR1cm4gW107XG4gICAgfVxuICAgIGNvbnN0IGFycmF5ID0gQXJyYXkuZnJvbShub2RlLnF1ZXJ5U2VsZWN0b3JBbGwocXVlcnkpKTtcbiAgICBpZiAoY2FsbGJhY2spIHtcbiAgICAgIGFycmF5LmZvckVhY2goY2FsbGJhY2spO1xuICAgIH1cbiAgICByZXR1cm4gYXJyYXk7XG4gIH0sXG5cbiAgY2hpbGROb2RlTGVuZ3RoKGh0bWwpIHtcbiAgICBjb25zdCB0ZW1wbGF0ZSA9IGRvY3VtZW50LmNyZWF0ZUVsZW1lbnQoXCJ0ZW1wbGF0ZVwiKTtcbiAgICB0ZW1wbGF0ZS5pbm5lckhUTUwgPSBodG1sO1xuICAgIHJldHVybiB0ZW1wbGF0ZS5jb250ZW50LmNoaWxkRWxlbWVudENvdW50O1xuICB9LFxuXG4gIGlzVXBsb2FkSW5wdXQoZWwpIHtcbiAgICByZXR1cm4gZWwudHlwZSA9PT0gXCJmaWxlXCIgJiYgZWwuZ2V0QXR0cmlidXRlKFBIWF9VUExPQURfUkVGKSAhPT0gbnVsbDtcbiAgfSxcblxuICBpc0F1dG9VcGxvYWQoaW5wdXRFbCkge1xuICAgIHJldHVybiBpbnB1dEVsLmhhc0F0dHJpYnV0ZShcImRhdGEtcGh4LWF1dG8tdXBsb2FkXCIpO1xuICB9LFxuXG4gIGZpbmRVcGxvYWRJbnB1dHMobm9kZSkge1xuICAgIGNvbnN0IGZvcm1JZCA9IG5vZGUuaWQ7XG4gICAgY29uc3QgaW5wdXRzT3V0c2lkZUZvcm0gPSB0aGlzLmFsbChcbiAgICAgIGRvY3VtZW50LFxuICAgICAgYGlucHV0W3R5cGU9XCJmaWxlXCJdWyR7UEhYX1VQTE9BRF9SRUZ9XVtmb3JtPVwiJHtmb3JtSWR9XCJdYCxcbiAgICApO1xuICAgIHJldHVybiB0aGlzLmFsbChub2RlLCBgaW5wdXRbdHlwZT1cImZpbGVcIl1bJHtQSFhfVVBMT0FEX1JFRn1dYCkuY29uY2F0KFxuICAgICAgaW5wdXRzT3V0c2lkZUZvcm0sXG4gICAgKTtcbiAgfSxcblxuICBmaW5kQ29tcG9uZW50Tm9kZUxpc3Qodmlld0lkLCBjaWQsIGRvYyA9IGRvY3VtZW50KSB7XG4gICAgcmV0dXJuIHRoaXMuYWxsKFxuICAgICAgZG9jLFxuICAgICAgYFske1BIWF9WSUVXX1JFRn09XCIke3ZpZXdJZH1cIl1bJHtQSFhfQ09NUE9ORU5UfT1cIiR7Y2lkfVwiXWAsXG4gICAgKTtcbiAgfSxcblxuICBpc1BoeERlc3Ryb3llZChub2RlKSB7XG4gICAgcmV0dXJuIG5vZGUuaWQgJiYgRE9NLnByaXZhdGUobm9kZSwgXCJkZXN0cm95ZWRcIikgPyB0cnVlIDogZmFsc2U7XG4gIH0sXG5cbiAgd2FudHNOZXdUYWIoZSkge1xuICAgIGNvbnN0IHdhbnRzTmV3VGFiID1cbiAgICAgIGUuY3RybEtleSB8fCBlLnNoaWZ0S2V5IHx8IGUubWV0YUtleSB8fCAoZS5idXR0b24gJiYgZS5idXR0b24gPT09IDEpO1xuICAgIGNvbnN0IGlzRG93bmxvYWQgPVxuICAgICAgZS50YXJnZXQgaW5zdGFuY2VvZiBIVE1MQW5jaG9yRWxlbWVudCAmJlxuICAgICAgZS50YXJnZXQuaGFzQXR0cmlidXRlKFwiZG93bmxvYWRcIik7XG4gICAgY29uc3QgaXNUYXJnZXRCbGFuayA9XG4gICAgICBlLnRhcmdldC5oYXNBdHRyaWJ1dGUoXCJ0YXJnZXRcIikgJiZcbiAgICAgIGUudGFyZ2V0LmdldEF0dHJpYnV0ZShcInRhcmdldFwiKS50b0xvd2VyQ2FzZSgpID09PSBcIl9ibGFua1wiO1xuICAgIGNvbnN0IGlzVGFyZ2V0TmFtZWRUYWIgPVxuICAgICAgZS50YXJnZXQuaGFzQXR0cmlidXRlKFwidGFyZ2V0XCIpICYmXG4gICAgICAhZS50YXJnZXQuZ2V0QXR0cmlidXRlKFwidGFyZ2V0XCIpLnN0YXJ0c1dpdGgoXCJfXCIpO1xuICAgIHJldHVybiB3YW50c05ld1RhYiB8fCBpc1RhcmdldEJsYW5rIHx8IGlzRG93bmxvYWQgfHwgaXNUYXJnZXROYW1lZFRhYjtcbiAgfSxcblxuICBpc1VubG9hZGFibGVGb3JtU3VibWl0KGUpIHtcbiAgICAvLyBJZ25vcmUgZm9ybSBzdWJtaXNzaW9ucyBpbnRlbmRlZCB0byBjbG9zZSBhIG5hdGl2ZSA8ZGlhbG9nPiBlbGVtZW50XG4gICAgLy8gaHR0cHM6Ly9kZXZlbG9wZXIubW96aWxsYS5vcmcvZW4tVVMvZG9jcy9XZWIvSFRNTC9FbGVtZW50L2RpYWxvZyN1c2FnZV9ub3Rlc1xuICAgIGNvbnN0IGlzRGlhbG9nU3VibWl0ID1cbiAgICAgIChlLnRhcmdldCAmJiBlLnRhcmdldC5nZXRBdHRyaWJ1dGUoXCJtZXRob2RcIikgPT09IFwiZGlhbG9nXCIpIHx8XG4gICAgICAoZS5zdWJtaXR0ZXIgJiYgZS5zdWJtaXR0ZXIuZ2V0QXR0cmlidXRlKFwiZm9ybW1ldGhvZFwiKSA9PT0gXCJkaWFsb2dcIik7XG5cbiAgICBpZiAoaXNEaWFsb2dTdWJtaXQpIHtcbiAgICAgIHJldHVybiBmYWxzZTtcbiAgICB9IGVsc2Uge1xuICAgICAgcmV0dXJuICFlLmRlZmF1bHRQcmV2ZW50ZWQgJiYgIXRoaXMud2FudHNOZXdUYWIoZSk7XG4gICAgfVxuICB9LFxuXG4gIGlzTmV3UGFnZUNsaWNrKGUsIGN1cnJlbnRMb2NhdGlvbikge1xuICAgIGNvbnN0IGhyZWYgPVxuICAgICAgZS50YXJnZXQgaW5zdGFuY2VvZiBIVE1MQW5jaG9yRWxlbWVudFxuICAgICAgICA/IGUudGFyZ2V0LmdldEF0dHJpYnV0ZShcImhyZWZcIilcbiAgICAgICAgOiBudWxsO1xuICAgIGxldCB1cmw7XG5cbiAgICBpZiAoZS5kZWZhdWx0UHJldmVudGVkIHx8IGhyZWYgPT09IG51bGwgfHwgdGhpcy53YW50c05ld1RhYihlKSkge1xuICAgICAgcmV0dXJuIGZhbHNlO1xuICAgIH1cbiAgICBpZiAoaHJlZi5zdGFydHNXaXRoKFwibWFpbHRvOlwiKSB8fCBocmVmLnN0YXJ0c1dpdGgoXCJ0ZWw6XCIpKSB7XG4gICAgICByZXR1cm4gZmFsc2U7XG4gICAgfVxuICAgIGlmIChlLnRhcmdldC5pc0NvbnRlbnRFZGl0YWJsZSkge1xuICAgICAgcmV0dXJuIGZhbHNlO1xuICAgIH1cblxuICAgIHRyeSB7XG4gICAgICB1cmwgPSBuZXcgVVJMKGhyZWYpO1xuICAgIH0gY2F0Y2gge1xuICAgICAgdHJ5IHtcbiAgICAgICAgdXJsID0gbmV3IFVSTChocmVmLCBjdXJyZW50TG9jYXRpb24pO1xuICAgICAgfSBjYXRjaCB7XG4gICAgICAgIC8vIGJhZCBVUkwsIGZhbGxiYWNrIHRvIGxldCBicm93c2VyIHRyeSBpdCBhcyBleHRlcm5hbFxuICAgICAgICByZXR1cm4gdHJ1ZTtcbiAgICAgIH1cbiAgICB9XG5cbiAgICBpZiAoXG4gICAgICB1cmwuaG9zdCA9PT0gY3VycmVudExvY2F0aW9uLmhvc3QgJiZcbiAgICAgIHVybC5wcm90b2NvbCA9PT0gY3VycmVudExvY2F0aW9uLnByb3RvY29sXG4gICAgKSB7XG4gICAgICBpZiAoXG4gICAgICAgIHVybC5wYXRobmFtZSA9PT0gY3VycmVudExvY2F0aW9uLnBhdGhuYW1lICYmXG4gICAgICAgIHVybC5zZWFyY2ggPT09IGN1cnJlbnRMb2NhdGlvbi5zZWFyY2hcbiAgICAgICkge1xuICAgICAgICByZXR1cm4gdXJsLmhhc2ggPT09IFwiXCIgJiYgIXVybC5ocmVmLmVuZHNXaXRoKFwiI1wiKTtcbiAgICAgIH1cbiAgICB9XG4gICAgcmV0dXJuIHVybC5wcm90b2NvbC5zdGFydHNXaXRoKFwiaHR0cFwiKTtcbiAgfSxcblxuICBtYXJrUGh4Q2hpbGREZXN0cm95ZWQoZWwpIHtcbiAgICBpZiAodGhpcy5pc1BoeENoaWxkKGVsKSkge1xuICAgICAgZWwuc2V0QXR0cmlidXRlKFBIWF9TRVNTSU9OLCBcIlwiKTtcbiAgICB9XG4gICAgdGhpcy5wdXRQcml2YXRlKGVsLCBcImRlc3Ryb3llZFwiLCB0cnVlKTtcbiAgfSxcblxuICBmaW5kUGh4Q2hpbGRyZW5JbkZyYWdtZW50KGh0bWwsIHBhcmVudElkKSB7XG4gICAgY29uc3QgdGVtcGxhdGUgPSBkb2N1bWVudC5jcmVhdGVFbGVtZW50KFwidGVtcGxhdGVcIik7XG4gICAgdGVtcGxhdGUuaW5uZXJIVE1MID0gaHRtbDtcbiAgICByZXR1cm4gdGhpcy5maW5kUGh4Q2hpbGRyZW4odGVtcGxhdGUuY29udGVudCwgcGFyZW50SWQpO1xuICB9LFxuXG4gIGlzSWdub3JlZChlbCwgcGh4VXBkYXRlKSB7XG4gICAgcmV0dXJuIChcbiAgICAgIChlbC5nZXRBdHRyaWJ1dGUocGh4VXBkYXRlKSB8fCBlbC5nZXRBdHRyaWJ1dGUoXCJkYXRhLXBoeC11cGRhdGVcIikpID09PVxuICAgICAgXCJpZ25vcmVcIlxuICAgICk7XG4gIH0sXG5cbiAgaXNQaHhVcGRhdGUoZWwsIHBoeFVwZGF0ZSwgdXBkYXRlVHlwZXMpIHtcbiAgICByZXR1cm4gKFxuICAgICAgZWwuZ2V0QXR0cmlidXRlICYmIHVwZGF0ZVR5cGVzLmluZGV4T2YoZWwuZ2V0QXR0cmlidXRlKHBoeFVwZGF0ZSkpID49IDBcbiAgICApO1xuICB9LFxuXG4gIGZpbmRQaHhTdGlja3koZWwpIHtcbiAgICByZXR1cm4gdGhpcy5hbGwoZWwsIGBbJHtQSFhfU1RJQ0tZfV1gKTtcbiAgfSxcblxuICBmaW5kUGh4Q2hpbGRyZW4oZWwsIHBhcmVudElkKSB7XG4gICAgcmV0dXJuIHRoaXMuYWxsKGVsLCBgJHtQSFhfVklFV19TRUxFQ1RPUn1bJHtQSFhfUEFSRU5UX0lEfT1cIiR7cGFyZW50SWR9XCJdYCk7XG4gIH0sXG5cbiAgZmluZEV4aXN0aW5nUGFyZW50Q0lEcyh2aWV3SWQsIGNpZHMpIHtcbiAgICAvLyB3ZSBvbmx5IHdhbnQgdG8gZmluZCBwYXJlbnRzIHRoYXQgZXhpc3Qgb24gdGhlIHBhZ2VcbiAgICAvLyBpZiBhIGNpZCBpcyBub3Qgb24gdGhlIHBhZ2UsIHRoZSBvbmx5IHdheSBpdCBjYW4gYmUgYWRkZWQgYmFjayB0byB0aGUgcGFnZVxuICAgIC8vIGlzIGlmIGEgcGFyZW50IGFkZHMgaXQgYmFjaywgdGhlcmVmb3JlIGlmIGEgY2lkIGRvZXMgbm90IGV4aXN0IG9uIHRoZSBwYWdlLFxuICAgIC8vIHdlIHNob3VsZCBub3QgdHJ5IHRvIHJlbmRlciBpdCBieSBpdHNlbGYgKGJlY2F1c2UgaXQgd291bGQgYmUgcmVuZGVyZWQgdHdpY2UsXG4gICAgLy8gb25lIGJ5IHRoZSBwYXJlbnQsIGFuZCBhIHNlY29uZCB0aW1lIGJ5IGl0c2VsZilcbiAgICBjb25zdCBwYXJlbnRDaWRzID0gbmV3IFNldCgpO1xuICAgIGNvbnN0IGNoaWxkcmVuQ2lkcyA9IG5ldyBTZXQoKTtcblxuICAgIGNpZHMuZm9yRWFjaCgoY2lkKSA9PiB7XG4gICAgICB0aGlzLmFsbChcbiAgICAgICAgZG9jdW1lbnQsXG4gICAgICAgIGBbJHtQSFhfVklFV19SRUZ9PVwiJHt2aWV3SWR9XCJdWyR7UEhYX0NPTVBPTkVOVH09XCIke2NpZH1cIl1gLFxuICAgICAgKS5mb3JFYWNoKChwYXJlbnQpID0+IHtcbiAgICAgICAgcGFyZW50Q2lkcy5hZGQoY2lkKTtcbiAgICAgICAgdGhpcy5hbGwocGFyZW50LCBgWyR7UEhYX1ZJRVdfUkVGfT1cIiR7dmlld0lkfVwiXVske1BIWF9DT01QT05FTlR9XWApXG4gICAgICAgICAgLm1hcCgoZWwpID0+IHBhcnNlSW50KGVsLmdldEF0dHJpYnV0ZShQSFhfQ09NUE9ORU5UKSkpXG4gICAgICAgICAgLmZvckVhY2goKGNoaWxkQ0lEKSA9PiBjaGlsZHJlbkNpZHMuYWRkKGNoaWxkQ0lEKSk7XG4gICAgICB9KTtcbiAgICB9KTtcblxuICAgIGNoaWxkcmVuQ2lkcy5mb3JFYWNoKChjaGlsZENpZCkgPT4gcGFyZW50Q2lkcy5kZWxldGUoY2hpbGRDaWQpKTtcblxuICAgIHJldHVybiBwYXJlbnRDaWRzO1xuICB9LFxuXG4gIHByaXZhdGUoZWwsIGtleSkge1xuICAgIHJldHVybiBlbFtQSFhfUFJJVkFURV0gJiYgZWxbUEhYX1BSSVZBVEVdW2tleV07XG4gIH0sXG5cbiAgZGVsZXRlUHJpdmF0ZShlbCwga2V5KSB7XG4gICAgZWxbUEhYX1BSSVZBVEVdICYmIGRlbGV0ZSBlbFtQSFhfUFJJVkFURV1ba2V5XTtcbiAgfSxcblxuICBwdXRQcml2YXRlKGVsLCBrZXksIHZhbHVlKSB7XG4gICAgaWYgKCFlbFtQSFhfUFJJVkFURV0pIHtcbiAgICAgIGVsW1BIWF9QUklWQVRFXSA9IHt9O1xuICAgIH1cbiAgICBlbFtQSFhfUFJJVkFURV1ba2V5XSA9IHZhbHVlO1xuICB9LFxuXG4gIHVwZGF0ZVByaXZhdGUoZWwsIGtleSwgZGVmYXVsdFZhbCwgdXBkYXRlRnVuYykge1xuICAgIGNvbnN0IGV4aXN0aW5nID0gdGhpcy5wcml2YXRlKGVsLCBrZXkpO1xuICAgIGlmIChleGlzdGluZyA9PT0gdW5kZWZpbmVkKSB7XG4gICAgICB0aGlzLnB1dFByaXZhdGUoZWwsIGtleSwgdXBkYXRlRnVuYyhkZWZhdWx0VmFsKSk7XG4gICAgfSBlbHNlIHtcbiAgICAgIHRoaXMucHV0UHJpdmF0ZShlbCwga2V5LCB1cGRhdGVGdW5jKGV4aXN0aW5nKSk7XG4gICAgfVxuICB9LFxuXG4gIHN5bmNQZW5kaW5nQXR0cnMoZnJvbUVsLCB0b0VsKSB7XG4gICAgaWYgKCFmcm9tRWwuaGFzQXR0cmlidXRlKFBIWF9SRUZfU1JDKSkge1xuICAgICAgcmV0dXJuO1xuICAgIH1cbiAgICBQSFhfRVZFTlRfQ0xBU1NFUy5mb3JFYWNoKChjbGFzc05hbWUpID0+IHtcbiAgICAgIGZyb21FbC5jbGFzc0xpc3QuY29udGFpbnMoY2xhc3NOYW1lKSAmJiB0b0VsLmNsYXNzTGlzdC5hZGQoY2xhc3NOYW1lKTtcbiAgICB9KTtcbiAgICBQSFhfUEVORElOR19BVFRSUy5maWx0ZXIoKGF0dHIpID0+IGZyb21FbC5oYXNBdHRyaWJ1dGUoYXR0cikpLmZvckVhY2goXG4gICAgICAoYXR0cikgPT4ge1xuICAgICAgICB0b0VsLnNldEF0dHJpYnV0ZShhdHRyLCBmcm9tRWwuZ2V0QXR0cmlidXRlKGF0dHIpKTtcbiAgICAgIH0sXG4gICAgKTtcbiAgfSxcblxuICBjb3B5UHJpdmF0ZXModGFyZ2V0LCBzb3VyY2UpIHtcbiAgICBpZiAoc291cmNlW1BIWF9QUklWQVRFXSkge1xuICAgICAgdGFyZ2V0W1BIWF9QUklWQVRFXSA9IHNvdXJjZVtQSFhfUFJJVkFURV07XG4gICAgfVxuICB9LFxuXG4gIHB1dFRpdGxlKHN0cikge1xuICAgIGNvbnN0IHRpdGxlRWwgPSBkb2N1bWVudC5xdWVyeVNlbGVjdG9yKFwidGl0bGVcIik7XG4gICAgaWYgKHRpdGxlRWwpIHtcbiAgICAgIGNvbnN0IHsgcHJlZml4LCBzdWZmaXgsIGRlZmF1bHQ6IGRlZmF1bHRUaXRsZSB9ID0gdGl0bGVFbC5kYXRhc2V0O1xuICAgICAgY29uc3QgaXNFbXB0eSA9IHR5cGVvZiBzdHIgIT09IFwic3RyaW5nXCIgfHwgc3RyLnRyaW0oKSA9PT0gXCJcIjtcbiAgICAgIGlmIChpc0VtcHR5ICYmIHR5cGVvZiBkZWZhdWx0VGl0bGUgIT09IFwic3RyaW5nXCIpIHtcbiAgICAgICAgcmV0dXJuO1xuICAgICAgfVxuXG4gICAgICBjb25zdCBpbm5lciA9IGlzRW1wdHkgPyBkZWZhdWx0VGl0bGUgOiBzdHI7XG4gICAgICBkb2N1bWVudC50aXRsZSA9IGAke3ByZWZpeCB8fCBcIlwifSR7aW5uZXIgfHwgXCJcIn0ke3N1ZmZpeCB8fCBcIlwifWA7XG4gICAgfSBlbHNlIHtcbiAgICAgIGRvY3VtZW50LnRpdGxlID0gc3RyO1xuICAgIH1cbiAgfSxcblxuICBkZWJvdW5jZShcbiAgICBlbCxcbiAgICBldmVudCxcbiAgICBwaHhEZWJvdW5jZSxcbiAgICBkZWZhdWx0RGVib3VuY2UsXG4gICAgcGh4VGhyb3R0bGUsXG4gICAgZGVmYXVsdFRocm90dGxlLFxuICAgIGFzeW5jRmlsdGVyLFxuICAgIGNhbGxiYWNrLFxuICApIHtcbiAgICBsZXQgZGVib3VuY2UgPSBlbC5nZXRBdHRyaWJ1dGUocGh4RGVib3VuY2UpO1xuICAgIGxldCB0aHJvdHRsZSA9IGVsLmdldEF0dHJpYnV0ZShwaHhUaHJvdHRsZSk7XG5cbiAgICBpZiAoZGVib3VuY2UgPT09IFwiXCIpIHtcbiAgICAgIGRlYm91bmNlID0gZGVmYXVsdERlYm91bmNlO1xuICAgIH1cbiAgICBpZiAodGhyb3R0bGUgPT09IFwiXCIpIHtcbiAgICAgIHRocm90dGxlID0gZGVmYXVsdFRocm90dGxlO1xuICAgIH1cbiAgICBjb25zdCB2YWx1ZSA9IGRlYm91bmNlIHx8IHRocm90dGxlO1xuICAgIHN3aXRjaCAodmFsdWUpIHtcbiAgICAgIGNhc2UgbnVsbDpcbiAgICAgICAgcmV0dXJuIGNhbGxiYWNrKCk7XG5cbiAgICAgIGNhc2UgXCJibHVyXCI6XG4gICAgICAgIHRoaXMuaW5jQ3ljbGUoZWwsIFwiZGVib3VuY2UtYmx1ci1jeWNsZVwiLCAoKSA9PiB7XG4gICAgICAgICAgaWYgKGFzeW5jRmlsdGVyKCkpIHtcbiAgICAgICAgICAgIGNhbGxiYWNrKCk7XG4gICAgICAgICAgfVxuICAgICAgICB9KTtcbiAgICAgICAgaWYgKHRoaXMub25jZShlbCwgXCJkZWJvdW5jZS1ibHVyXCIpKSB7XG4gICAgICAgICAgZWwuYWRkRXZlbnRMaXN0ZW5lcihcImJsdXJcIiwgKCkgPT5cbiAgICAgICAgICAgIHRoaXMudHJpZ2dlckN5Y2xlKGVsLCBcImRlYm91bmNlLWJsdXItY3ljbGVcIiksXG4gICAgICAgICAgKTtcbiAgICAgICAgfVxuICAgICAgICByZXR1cm47XG5cbiAgICAgIGRlZmF1bHQ6XG4gICAgICAgIGNvbnN0IHRpbWVvdXQgPSBwYXJzZUludCh2YWx1ZSk7XG4gICAgICAgIGNvbnN0IHRyaWdnZXIgPSAoKSA9PlxuICAgICAgICAgIHRocm90dGxlID8gdGhpcy5kZWxldGVQcml2YXRlKGVsLCBUSFJPVFRMRUQpIDogY2FsbGJhY2soKTtcbiAgICAgICAgY29uc3QgY3VycmVudEN5Y2xlID0gdGhpcy5pbmNDeWNsZShlbCwgREVCT1VOQ0VfVFJJR0dFUiwgdHJpZ2dlcik7XG4gICAgICAgIGlmIChpc05hTih0aW1lb3V0KSkge1xuICAgICAgICAgIHJldHVybiBsb2dFcnJvcihgaW52YWxpZCB0aHJvdHRsZS9kZWJvdW5jZSB2YWx1ZTogJHt2YWx1ZX1gKTtcbiAgICAgICAgfVxuICAgICAgICBpZiAodGhyb3R0bGUpIHtcbiAgICAgICAgICBsZXQgbmV3S2V5RG93biA9IGZhbHNlO1xuICAgICAgICAgIGlmIChldmVudC50eXBlID09PSBcImtleWRvd25cIikge1xuICAgICAgICAgICAgY29uc3QgcHJldktleSA9IHRoaXMucHJpdmF0ZShlbCwgREVCT1VOQ0VfUFJFVl9LRVkpO1xuICAgICAgICAgICAgdGhpcy5wdXRQcml2YXRlKGVsLCBERUJPVU5DRV9QUkVWX0tFWSwgZXZlbnQua2V5KTtcbiAgICAgICAgICAgIG5ld0tleURvd24gPSBwcmV2S2V5ICE9PSBldmVudC5rZXk7XG4gICAgICAgICAgfVxuXG4gICAgICAgICAgaWYgKCFuZXdLZXlEb3duICYmIHRoaXMucHJpdmF0ZShlbCwgVEhST1RUTEVEKSkge1xuICAgICAgICAgICAgcmV0dXJuIGZhbHNlO1xuICAgICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgICBjYWxsYmFjaygpO1xuICAgICAgICAgICAgY29uc3QgdCA9IHNldFRpbWVvdXQoKCkgPT4ge1xuICAgICAgICAgICAgICBpZiAoYXN5bmNGaWx0ZXIoKSkge1xuICAgICAgICAgICAgICAgIHRoaXMudHJpZ2dlckN5Y2xlKGVsLCBERUJPVU5DRV9UUklHR0VSKTtcbiAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgfSwgdGltZW91dCk7XG4gICAgICAgICAgICB0aGlzLnB1dFByaXZhdGUoZWwsIFRIUk9UVExFRCwgdCk7XG4gICAgICAgICAgfVxuICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgIHNldFRpbWVvdXQoKCkgPT4ge1xuICAgICAgICAgICAgaWYgKGFzeW5jRmlsdGVyKCkpIHtcbiAgICAgICAgICAgICAgdGhpcy50cmlnZ2VyQ3ljbGUoZWwsIERFQk9VTkNFX1RSSUdHRVIsIGN1cnJlbnRDeWNsZSk7XG4gICAgICAgICAgICB9XG4gICAgICAgICAgfSwgdGltZW91dCk7XG4gICAgICAgIH1cblxuICAgICAgICBjb25zdCBmb3JtID0gZWwuZm9ybTtcbiAgICAgICAgaWYgKGZvcm0gJiYgdGhpcy5vbmNlKGZvcm0sIFwiYmluZC1kZWJvdW5jZVwiKSkge1xuICAgICAgICAgIGZvcm0uYWRkRXZlbnRMaXN0ZW5lcihcInN1Ym1pdFwiLCAoKSA9PiB7XG4gICAgICAgICAgICBBcnJheS5mcm9tKG5ldyBGb3JtRGF0YShmb3JtKS5lbnRyaWVzKCksIChbbmFtZV0pID0+IHtcbiAgICAgICAgICAgICAgY29uc3QgaW5wdXQgPSBmb3JtLnF1ZXJ5U2VsZWN0b3IoYFtuYW1lPVwiJHtuYW1lfVwiXWApO1xuICAgICAgICAgICAgICB0aGlzLmluY0N5Y2xlKGlucHV0LCBERUJPVU5DRV9UUklHR0VSKTtcbiAgICAgICAgICAgICAgdGhpcy5kZWxldGVQcml2YXRlKGlucHV0LCBUSFJPVFRMRUQpO1xuICAgICAgICAgICAgfSk7XG4gICAgICAgICAgfSk7XG4gICAgICAgIH1cbiAgICAgICAgaWYgKHRoaXMub25jZShlbCwgXCJiaW5kLWRlYm91bmNlXCIpKSB7XG4gICAgICAgICAgZWwuYWRkRXZlbnRMaXN0ZW5lcihcImJsdXJcIiwgKCkgPT4ge1xuICAgICAgICAgICAgLy8gYmVjYXVzZSB3ZSB0cmlnZ2VyIHRoZSBjYWxsYmFjayBoZXJlLFxuICAgICAgICAgICAgLy8gd2UgYWxzbyBjbGVhciB0aGUgdGhyb3R0bGUgdGltZW91dCB0byBwcmV2ZW50IHRoZSBjYWxsYmFja1xuICAgICAgICAgICAgLy8gZnJvbSBiZWluZyBjYWxsZWQgYWdhaW4gYWZ0ZXIgdGhlIHRpbWVvdXQgZmlyZXNcbiAgICAgICAgICAgIGNsZWFyVGltZW91dCh0aGlzLnByaXZhdGUoZWwsIFRIUk9UVExFRCkpO1xuICAgICAgICAgICAgdGhpcy50cmlnZ2VyQ3ljbGUoZWwsIERFQk9VTkNFX1RSSUdHRVIpO1xuICAgICAgICAgIH0pO1xuICAgICAgICB9XG4gICAgfVxuICB9LFxuXG4gIHRyaWdnZXJDeWNsZShlbCwga2V5LCBjdXJyZW50Q3ljbGUpIHtcbiAgICBjb25zdCBbY3ljbGUsIHRyaWdnZXJdID0gdGhpcy5wcml2YXRlKGVsLCBrZXkpO1xuICAgIGlmICghY3VycmVudEN5Y2xlKSB7XG4gICAgICBjdXJyZW50Q3ljbGUgPSBjeWNsZTtcbiAgICB9XG4gICAgaWYgKGN1cnJlbnRDeWNsZSA9PT0gY3ljbGUpIHtcbiAgICAgIHRoaXMuaW5jQ3ljbGUoZWwsIGtleSk7XG4gICAgICB0cmlnZ2VyKCk7XG4gICAgfVxuICB9LFxuXG4gIG9uY2UoZWwsIGtleSkge1xuICAgIGlmICh0aGlzLnByaXZhdGUoZWwsIGtleSkgPT09IHRydWUpIHtcbiAgICAgIHJldHVybiBmYWxzZTtcbiAgICB9XG4gICAgdGhpcy5wdXRQcml2YXRlKGVsLCBrZXksIHRydWUpO1xuICAgIHJldHVybiB0cnVlO1xuICB9LFxuXG4gIGluY0N5Y2xlKGVsLCBrZXksIHRyaWdnZXIgPSBmdW5jdGlvbiAoKSB7fSkge1xuICAgIGxldCBbY3VycmVudEN5Y2xlXSA9IHRoaXMucHJpdmF0ZShlbCwga2V5KSB8fCBbMCwgdHJpZ2dlcl07XG4gICAgY3VycmVudEN5Y2xlKys7XG4gICAgdGhpcy5wdXRQcml2YXRlKGVsLCBrZXksIFtjdXJyZW50Q3ljbGUsIHRyaWdnZXJdKTtcbiAgICByZXR1cm4gY3VycmVudEN5Y2xlO1xuICB9LFxuXG4gIC8vIG1haW50YWlucyBvciBhZGRzIHByaXZhdGVseSB1c2VkIGhvb2sgaW5mb3JtYXRpb25cbiAgLy8gZnJvbUVsIGFuZCB0b0VsIGNhbiBiZSB0aGUgc2FtZSBlbGVtZW50IGluIHRoZSBjYXNlIG9mIGEgbmV3bHkgYWRkZWQgbm9kZVxuICAvLyBmcm9tRWwgYW5kIHRvRWwgY2FuIGJlIGFueSBIVE1MIG5vZGUgdHlwZSwgc28gd2UgbmVlZCB0byBjaGVjayBpZiBpdCdzIGFuIGVsZW1lbnQgbm9kZVxuICBtYWludGFpblByaXZhdGVIb29rcyhmcm9tRWwsIHRvRWwsIHBoeFZpZXdwb3J0VG9wLCBwaHhWaWV3cG9ydEJvdHRvbSkge1xuICAgIC8vIG1haW50YWluIHRoZSBob29rcyBjcmVhdGVkIHdpdGggY3JlYXRlSG9va1xuICAgIGlmIChcbiAgICAgIGZyb21FbC5oYXNBdHRyaWJ1dGUgJiZcbiAgICAgIGZyb21FbC5oYXNBdHRyaWJ1dGUoXCJkYXRhLXBoeC1ob29rXCIpICYmXG4gICAgICAhdG9FbC5oYXNBdHRyaWJ1dGUoXCJkYXRhLXBoeC1ob29rXCIpXG4gICAgKSB7XG4gICAgICB0b0VsLnNldEF0dHJpYnV0ZShcImRhdGEtcGh4LWhvb2tcIiwgZnJvbUVsLmdldEF0dHJpYnV0ZShcImRhdGEtcGh4LWhvb2tcIikpO1xuICAgIH1cbiAgICAvLyBhZGQgaG9va3MgdG8gZWxlbWVudHMgd2l0aCB2aWV3cG9ydCBhdHRyaWJ1dGVzXG4gICAgaWYgKFxuICAgICAgdG9FbC5oYXNBdHRyaWJ1dGUgJiZcbiAgICAgICh0b0VsLmhhc0F0dHJpYnV0ZShwaHhWaWV3cG9ydFRvcCkgfHxcbiAgICAgICAgdG9FbC5oYXNBdHRyaWJ1dGUocGh4Vmlld3BvcnRCb3R0b20pKVxuICAgICkge1xuICAgICAgdG9FbC5zZXRBdHRyaWJ1dGUoXCJkYXRhLXBoeC1ob29rXCIsIFwiUGhvZW5peC5JbmZpbml0ZVNjcm9sbFwiKTtcbiAgICB9XG4gIH0sXG5cbiAgcHV0Q3VzdG9tRWxIb29rKGVsLCBob29rKSB7XG4gICAgaWYgKGVsLmlzQ29ubmVjdGVkKSB7XG4gICAgICBlbC5zZXRBdHRyaWJ1dGUoXCJkYXRhLXBoeC1ob29rXCIsIFwiXCIpO1xuICAgIH0gZWxzZSB7XG4gICAgICBjb25zb2xlLmVycm9yKGBcbiAgICAgICAgaG9vayBhdHRhY2hlZCB0byBub24tY29ubmVjdGVkIERPTSBlbGVtZW50XG4gICAgICAgIGVuc3VyZSB5b3UgYXJlIGNhbGxpbmcgY3JlYXRlSG9vayB3aXRoaW4geW91ciBjb25uZWN0ZWRDYWxsYmFjay4gJHtlbC5vdXRlckhUTUx9XG4gICAgICBgKTtcbiAgICB9XG4gICAgdGhpcy5wdXRQcml2YXRlKGVsLCBcImN1c3RvbS1lbC1ob29rXCIsIGhvb2spO1xuICB9LFxuXG4gIGdldEN1c3RvbUVsSG9vayhlbCkge1xuICAgIHJldHVybiB0aGlzLnByaXZhdGUoZWwsIFwiY3VzdG9tLWVsLWhvb2tcIik7XG4gIH0sXG5cbiAgaXNVc2VkSW5wdXQoZWwpIHtcbiAgICByZXR1cm4gKFxuICAgICAgZWwubm9kZVR5cGUgPT09IE5vZGUuRUxFTUVOVF9OT0RFICYmXG4gICAgICAodGhpcy5wcml2YXRlKGVsLCBQSFhfSEFTX0ZPQ1VTRUQpIHx8IHRoaXMucHJpdmF0ZShlbCwgUEhYX0hBU19TVUJNSVRURUQpKVxuICAgICk7XG4gIH0sXG5cbiAgcmVzZXRGb3JtKGZvcm0pIHtcbiAgICBBcnJheS5mcm9tKGZvcm0uZWxlbWVudHMpLmZvckVhY2goKGlucHV0KSA9PiB7XG4gICAgICB0aGlzLmRlbGV0ZVByaXZhdGUoaW5wdXQsIFBIWF9IQVNfRk9DVVNFRCk7XG4gICAgICB0aGlzLmRlbGV0ZVByaXZhdGUoaW5wdXQsIFBIWF9IQVNfU1VCTUlUVEVEKTtcbiAgICB9KTtcbiAgfSxcblxuICBpc1BoeENoaWxkKG5vZGUpIHtcbiAgICByZXR1cm4gbm9kZS5nZXRBdHRyaWJ1dGUgJiYgbm9kZS5nZXRBdHRyaWJ1dGUoUEhYX1BBUkVOVF9JRCk7XG4gIH0sXG5cbiAgaXNQaHhTdGlja3kobm9kZSkge1xuICAgIHJldHVybiBub2RlLmdldEF0dHJpYnV0ZSAmJiBub2RlLmdldEF0dHJpYnV0ZShQSFhfU1RJQ0tZKSAhPT0gbnVsbDtcbiAgfSxcblxuICBpc0NoaWxkT2ZBbnkoZWwsIHBhcmVudHMpIHtcbiAgICByZXR1cm4gISFwYXJlbnRzLmZpbmQoKHBhcmVudCkgPT4gcGFyZW50LmNvbnRhaW5zKGVsKSk7XG4gIH0sXG5cbiAgZmlyc3RQaHhDaGlsZChlbCkge1xuICAgIHJldHVybiB0aGlzLmlzUGh4Q2hpbGQoZWwpID8gZWwgOiB0aGlzLmFsbChlbCwgYFske1BIWF9QQVJFTlRfSUR9XWApWzBdO1xuICB9LFxuXG4gIGlzUG9ydGFsVGVtcGxhdGUoZWwpIHtcbiAgICByZXR1cm4gZWwudGFnTmFtZSA9PT0gXCJURU1QTEFURVwiICYmIGVsLmhhc0F0dHJpYnV0ZShQSFhfUE9SVEFMKTtcbiAgfSxcblxuICBjbG9zZXN0Vmlld0VsKGVsKSB7XG4gICAgLy8gZmluZCB0aGUgY2xvc2VzdCBwb3J0YWwgb3IgdmlldyBlbGVtZW50LCB3aGljaGV2ZXIgY29tZXMgZmlyc3RcbiAgICBjb25zdCBwb3J0YWxPclZpZXdFbCA9IGVsLmNsb3Nlc3QoXG4gICAgICBgWyR7UEhYX1RFTEVQT1JURURfUkVGfV0sJHtQSFhfVklFV19TRUxFQ1RPUn1gLFxuICAgICk7XG4gICAgaWYgKCFwb3J0YWxPclZpZXdFbCkge1xuICAgICAgcmV0dXJuIG51bGw7XG4gICAgfVxuICAgIGlmIChwb3J0YWxPclZpZXdFbC5oYXNBdHRyaWJ1dGUoUEhYX1RFTEVQT1JURURfUkVGKSkge1xuICAgICAgLy8gUEhYX1RFTEVQT1JURURfUkVGIGlzIHNldCB0byB0aGUgaWQgb2YgdGhlIHZpZXcgdGhhdCBvd25zIHRoZSBwb3J0YWwgZWxlbWVudFxuICAgICAgcmV0dXJuIHRoaXMuYnlJZChwb3J0YWxPclZpZXdFbC5nZXRBdHRyaWJ1dGUoUEhYX1RFTEVQT1JURURfUkVGKSk7XG4gICAgfSBlbHNlIGlmIChwb3J0YWxPclZpZXdFbC5oYXNBdHRyaWJ1dGUoUEhYX1NFU1NJT04pKSB7XG4gICAgICByZXR1cm4gcG9ydGFsT3JWaWV3RWw7XG4gICAgfVxuICAgIHJldHVybiBudWxsO1xuICB9LFxuXG4gIGRpc3BhdGNoRXZlbnQodGFyZ2V0LCBuYW1lLCBvcHRzID0ge30pIHtcbiAgICBsZXQgZGVmYXVsdEJ1YmJsZSA9IHRydWU7XG4gICAgY29uc3QgaXNVcGxvYWRUYXJnZXQgPVxuICAgICAgdGFyZ2V0Lm5vZGVOYW1lID09PSBcIklOUFVUXCIgJiYgdGFyZ2V0LnR5cGUgPT09IFwiZmlsZVwiO1xuICAgIGlmIChpc1VwbG9hZFRhcmdldCAmJiBuYW1lID09PSBcImNsaWNrXCIpIHtcbiAgICAgIGRlZmF1bHRCdWJibGUgPSBmYWxzZTtcbiAgICB9XG4gICAgY29uc3QgYnViYmxlcyA9IG9wdHMuYnViYmxlcyA9PT0gdW5kZWZpbmVkID8gZGVmYXVsdEJ1YmJsZSA6ICEhb3B0cy5idWJibGVzO1xuICAgIGNvbnN0IGV2ZW50T3B0cyA9IHtcbiAgICAgIGJ1YmJsZXM6IGJ1YmJsZXMsXG4gICAgICBjYW5jZWxhYmxlOiB0cnVlLFxuICAgICAgZGV0YWlsOiBvcHRzLmRldGFpbCB8fCB7fSxcbiAgICB9O1xuICAgIGNvbnN0IGV2ZW50ID1cbiAgICAgIG5hbWUgPT09IFwiY2xpY2tcIlxuICAgICAgICA/IG5ldyBNb3VzZUV2ZW50KFwiY2xpY2tcIiwgZXZlbnRPcHRzKVxuICAgICAgICA6IG5ldyBDdXN0b21FdmVudChuYW1lLCBldmVudE9wdHMpO1xuICAgIHRhcmdldC5kaXNwYXRjaEV2ZW50KGV2ZW50KTtcbiAgfSxcblxuICBjbG9uZU5vZGUobm9kZSwgaHRtbCkge1xuICAgIGlmICh0eXBlb2YgaHRtbCA9PT0gXCJ1bmRlZmluZWRcIikge1xuICAgICAgcmV0dXJuIG5vZGUuY2xvbmVOb2RlKHRydWUpO1xuICAgIH0gZWxzZSB7XG4gICAgICBjb25zdCBjbG9uZWQgPSBub2RlLmNsb25lTm9kZShmYWxzZSk7XG4gICAgICBjbG9uZWQuaW5uZXJIVE1MID0gaHRtbDtcbiAgICAgIHJldHVybiBjbG9uZWQ7XG4gICAgfVxuICB9LFxuXG4gIC8vIG1lcmdlIGF0dHJpYnV0ZXMgZnJvbSBzb3VyY2UgdG8gdGFyZ2V0XG4gIC8vIGlmIGFuIGVsZW1lbnQgaXMgaWdub3JlZCwgd2Ugb25seSBtZXJnZSBkYXRhIGF0dHJpYnV0ZXNcbiAgLy8gaW5jbHVkaW5nIHJlbW92aW5nIGRhdGEgYXR0cmlidXRlcyB0aGF0IGFyZSBubyBsb25nZXIgaW4gdGhlIHNvdXJjZVxuICBtZXJnZUF0dHJzKHRhcmdldCwgc291cmNlLCBvcHRzID0ge30pIHtcbiAgICBjb25zdCBleGNsdWRlID0gbmV3IFNldChvcHRzLmV4Y2x1ZGUgfHwgW10pO1xuICAgIGNvbnN0IGlzSWdub3JlZCA9IG9wdHMuaXNJZ25vcmVkO1xuICAgIGNvbnN0IHNvdXJjZUF0dHJzID0gc291cmNlLmF0dHJpYnV0ZXM7XG4gICAgZm9yIChsZXQgaSA9IHNvdXJjZUF0dHJzLmxlbmd0aCAtIDE7IGkgPj0gMDsgaS0tKSB7XG4gICAgICBjb25zdCBuYW1lID0gc291cmNlQXR0cnNbaV0ubmFtZTtcbiAgICAgIGlmICghZXhjbHVkZS5oYXMobmFtZSkpIHtcbiAgICAgICAgY29uc3Qgc291cmNlVmFsdWUgPSBzb3VyY2UuZ2V0QXR0cmlidXRlKG5hbWUpO1xuICAgICAgICBpZiAoXG4gICAgICAgICAgdGFyZ2V0LmdldEF0dHJpYnV0ZShuYW1lKSAhPT0gc291cmNlVmFsdWUgJiZcbiAgICAgICAgICAoIWlzSWdub3JlZCB8fCAoaXNJZ25vcmVkICYmIG5hbWUuc3RhcnRzV2l0aChcImRhdGEtXCIpKSlcbiAgICAgICAgKSB7XG4gICAgICAgICAgdGFyZ2V0LnNldEF0dHJpYnV0ZShuYW1lLCBzb3VyY2VWYWx1ZSk7XG4gICAgICAgIH1cbiAgICAgIH0gZWxzZSB7XG4gICAgICAgIC8vIFdlIGV4Y2x1ZGUgdGhlIHZhbHVlIGZyb20gYmVpbmcgbWVyZ2VkIG9uIGZvY3VzZWQgaW5wdXRzLCBiZWNhdXNlIHRoZVxuICAgICAgICAvLyB1c2VyJ3MgaW5wdXQgc2hvdWxkIGFsd2F5cyB3aW4uXG4gICAgICAgIC8vIFdlIGNhbiBzdGlsbCBhc3NpZ24gaXQgYXMgbG9uZyBhcyB0aGUgdmFsdWUgcHJvcGVydHkgaXMgdGhlIHNhbWUsIHRob3VnaC5cbiAgICAgICAgLy8gVGhpcyBwcmV2ZW50cyBhIHNpdHVhdGlvbiB3aGVyZSB0aGUgdXBkYXRlZCBob29rIGlzIG5vdCBiZWluZyB0cmlnZ2VyZWRcbiAgICAgICAgLy8gd2hlbiBhbiBpbnB1dCBpcyBiYWNrIGluIGl0cyBcIm9yaWdpbmFsIHN0YXRlXCIsIGJlY2F1c2UgdGhlIGF0dHJpYnV0ZVxuICAgICAgICAvLyB3YXMgbmV2ZXIgY2hhbmdlZCwgc2VlOlxuICAgICAgICAvLyBodHRwczovL2dpdGh1Yi5jb20vcGhvZW5peGZyYW1ld29yay9waG9lbml4X2xpdmVfdmlldy9pc3N1ZXMvMjE2M1xuICAgICAgICBpZiAobmFtZSA9PT0gXCJ2YWx1ZVwiKSB7XG4gICAgICAgICAgY29uc3Qgc291cmNlVmFsdWUgPSBzb3VyY2UudmFsdWUgPz8gc291cmNlLmdldEF0dHJpYnV0ZShuYW1lKTtcbiAgICAgICAgICBpZiAodGFyZ2V0LnZhbHVlID09PSBzb3VyY2VWYWx1ZSkge1xuICAgICAgICAgICAgLy8gYWN0dWFsbHkgc2V0IHRoZSB2YWx1ZSBhdHRyaWJ1dGUgdG8gc3luYyBpdCB3aXRoIHRoZSB2YWx1ZSBwcm9wZXJ0eVxuICAgICAgICAgICAgdGFyZ2V0LnNldEF0dHJpYnV0ZShcInZhbHVlXCIsIHNvdXJjZS5nZXRBdHRyaWJ1dGUobmFtZSkpO1xuICAgICAgICAgIH1cbiAgICAgICAgfVxuICAgICAgfVxuICAgIH1cblxuICAgIGNvbnN0IHRhcmdldEF0dHJzID0gdGFyZ2V0LmF0dHJpYnV0ZXM7XG4gICAgZm9yIChsZXQgaSA9IHRhcmdldEF0dHJzLmxlbmd0aCAtIDE7IGkgPj0gMDsgaS0tKSB7XG4gICAgICBjb25zdCBuYW1lID0gdGFyZ2V0QXR0cnNbaV0ubmFtZTtcbiAgICAgIGlmIChpc0lnbm9yZWQpIHtcbiAgICAgICAgaWYgKFxuICAgICAgICAgIG5hbWUuc3RhcnRzV2l0aChcImRhdGEtXCIpICYmXG4gICAgICAgICAgIXNvdXJjZS5oYXNBdHRyaWJ1dGUobmFtZSkgJiZcbiAgICAgICAgICAhUEhYX1BFTkRJTkdfQVRUUlMuaW5jbHVkZXMobmFtZSlcbiAgICAgICAgKSB7XG4gICAgICAgICAgdGFyZ2V0LnJlbW92ZUF0dHJpYnV0ZShuYW1lKTtcbiAgICAgICAgfVxuICAgICAgfSBlbHNlIHtcbiAgICAgICAgaWYgKCFzb3VyY2UuaGFzQXR0cmlidXRlKG5hbWUpKSB7XG4gICAgICAgICAgdGFyZ2V0LnJlbW92ZUF0dHJpYnV0ZShuYW1lKTtcbiAgICAgICAgfVxuICAgICAgfVxuICAgIH1cbiAgfSxcblxuICBtZXJnZUZvY3VzZWRJbnB1dCh0YXJnZXQsIHNvdXJjZSkge1xuICAgIC8vIHNraXAgc2VsZWN0cyBiZWNhdXNlIEZGIHdpbGwgcmVzZXQgaGlnaGxpZ2h0ZWQgaW5kZXggZm9yIGFueSBzZXRBdHRyaWJ1dGVcbiAgICBpZiAoISh0YXJnZXQgaW5zdGFuY2VvZiBIVE1MU2VsZWN0RWxlbWVudCkpIHtcbiAgICAgIERPTS5tZXJnZUF0dHJzKHRhcmdldCwgc291cmNlLCB7IGV4Y2x1ZGU6IFtcInZhbHVlXCJdIH0pO1xuICAgIH1cblxuICAgIGlmIChzb3VyY2UucmVhZE9ubHkpIHtcbiAgICAgIHRhcmdldC5zZXRBdHRyaWJ1dGUoXCJyZWFkb25seVwiLCB0cnVlKTtcbiAgICB9IGVsc2Uge1xuICAgICAgdGFyZ2V0LnJlbW92ZUF0dHJpYnV0ZShcInJlYWRvbmx5XCIpO1xuICAgIH1cbiAgfSxcblxuICBoYXNTZWxlY3Rpb25SYW5nZShlbCkge1xuICAgIHJldHVybiAoXG4gICAgICBlbC5zZXRTZWxlY3Rpb25SYW5nZSAmJiAoZWwudHlwZSA9PT0gXCJ0ZXh0XCIgfHwgZWwudHlwZSA9PT0gXCJ0ZXh0YXJlYVwiKVxuICAgICk7XG4gIH0sXG5cbiAgcmVzdG9yZUZvY3VzKGZvY3VzZWQsIHNlbGVjdGlvblN0YXJ0LCBzZWxlY3Rpb25FbmQpIHtcbiAgICBpZiAoZm9jdXNlZCBpbnN0YW5jZW9mIEhUTUxTZWxlY3RFbGVtZW50KSB7XG4gICAgICBmb2N1c2VkLmZvY3VzKCk7XG4gICAgfVxuICAgIGlmICghRE9NLmlzVGV4dHVhbElucHV0KGZvY3VzZWQpKSB7XG4gICAgICByZXR1cm47XG4gICAgfVxuXG4gICAgY29uc3Qgd2FzRm9jdXNlZCA9IGZvY3VzZWQubWF0Y2hlcyhcIjpmb2N1c1wiKTtcbiAgICBpZiAoIXdhc0ZvY3VzZWQpIHtcbiAgICAgIGZvY3VzZWQuZm9jdXMoKTtcbiAgICB9XG4gICAgaWYgKHRoaXMuaGFzU2VsZWN0aW9uUmFuZ2UoZm9jdXNlZCkpIHtcbiAgICAgIGZvY3VzZWQuc2V0U2VsZWN0aW9uUmFuZ2Uoc2VsZWN0aW9uU3RhcnQsIHNlbGVjdGlvbkVuZCk7XG4gICAgfVxuICB9LFxuXG4gIGlzRm9ybUlucHV0KGVsKSB7XG4gICAgaWYgKGVsLmxvY2FsTmFtZSAmJiBjdXN0b21FbGVtZW50cy5nZXQoZWwubG9jYWxOYW1lKSkge1xuICAgICAgLy8gQ3VzdG9tIEVsZW1lbnRzIG1heSBiZSBmb3JtIGFzc29jaWF0ZWQuIFRoaXMgYWxsb3dzIHRoZW1cbiAgICAgIC8vIHRvIHBhcnRpY2lwYXRlIHdpdGhpbiBhIGZvcm0ncyBsaWZlY3ljbGUsIGluY2x1ZGluZyBmb3JtXG4gICAgICAvLyB2YWxpZGl0eSBhbmQgZm9ybSBzdWJtaXNzaW9ucy5cbiAgICAgIC8vIFRoZSBzcGVjIGZvciBGb3JtIEFzc29jaWF0ZWQgY3VzdG9tIGVsZW1lbnRzIHJlcXVpcmVzIHRoZVxuICAgICAgLy8gY3VzdG9tIGVsZW1lbnQncyBjbGFzcyB0byBjb250YWluIGEgc3RhdGljIGJvb2xlYW4gdmFsdWUgb2YgYGZvcm1Bc3NvY2lhdGVkYFxuICAgICAgLy8gd2hpY2ggaWRlbnRpZmllcyB0aGlzIGNsYXNzIGFzIGFsbG93ZWQgdG8gYXNzb2NpYXRlIHRvIGEgZm9ybS5cbiAgICAgIC8vIFNlZSBodHRwczovL2h0bWwuc3BlYy53aGF0d2cub3JnL2Rldi9jdXN0b20tZWxlbWVudHMuaHRtbCNjdXN0b20tZWxlbWVudHMtZmFjZS1leGFtcGxlXG4gICAgICAvLyBmb3IgZGV0YWlscy5cbiAgICAgIHJldHVybiBjdXN0b21FbGVtZW50cy5nZXQoZWwubG9jYWxOYW1lKVtgZm9ybUFzc29jaWF0ZWRgXTtcbiAgICB9XG5cbiAgICByZXR1cm4gKFxuICAgICAgL14oPzppbnB1dHxzZWxlY3R8dGV4dGFyZWEpJC9pLnRlc3QoZWwudGFnTmFtZSkgJiYgZWwudHlwZSAhPT0gXCJidXR0b25cIlxuICAgICk7XG4gIH0sXG5cbiAgc3luY0F0dHJzVG9Qcm9wcyhlbCkge1xuICAgIGlmIChcbiAgICAgIGVsIGluc3RhbmNlb2YgSFRNTElucHV0RWxlbWVudCAmJlxuICAgICAgQ0hFQ0tBQkxFX0lOUFVUUy5pbmRleE9mKGVsLnR5cGUudG9Mb2NhbGVMb3dlckNhc2UoKSkgPj0gMFxuICAgICkge1xuICAgICAgZWwuY2hlY2tlZCA9IGVsLmdldEF0dHJpYnV0ZShcImNoZWNrZWRcIikgIT09IG51bGw7XG4gICAgfVxuICB9LFxuXG4gIGlzVGV4dHVhbElucHV0KGVsKSB7XG4gICAgcmV0dXJuIEZPQ1VTQUJMRV9JTlBVVFMuaW5kZXhPZihlbC50eXBlKSA+PSAwO1xuICB9LFxuXG4gIGlzTm93VHJpZ2dlckZvcm1FeHRlcm5hbChlbCwgcGh4VHJpZ2dlckV4dGVybmFsKSB7XG4gICAgcmV0dXJuIChcbiAgICAgIGVsLmdldEF0dHJpYnV0ZSAmJlxuICAgICAgZWwuZ2V0QXR0cmlidXRlKHBoeFRyaWdnZXJFeHRlcm5hbCkgIT09IG51bGwgJiZcbiAgICAgIGRvY3VtZW50LmJvZHkuY29udGFpbnMoZWwpXG4gICAgKTtcbiAgfSxcblxuICBjbGVhbkNoaWxkTm9kZXMoY29udGFpbmVyLCBwaHhVcGRhdGUpIHtcbiAgICBpZiAoXG4gICAgICBET00uaXNQaHhVcGRhdGUoY29udGFpbmVyLCBwaHhVcGRhdGUsIFtcImFwcGVuZFwiLCBcInByZXBlbmRcIiwgUEhYX1NUUkVBTV0pXG4gICAgKSB7XG4gICAgICBjb25zdCB0b1JlbW92ZSA9IFtdO1xuICAgICAgY29udGFpbmVyLmNoaWxkTm9kZXMuZm9yRWFjaCgoY2hpbGROb2RlKSA9PiB7XG4gICAgICAgIGlmICghY2hpbGROb2RlLmlkKSB7XG4gICAgICAgICAgLy8gU2tpcCB3YXJuaW5nIGlmIGl0J3MgYW4gZW1wdHkgdGV4dCBub2RlIChlLmcuIGEgbmV3LWxpbmUpXG4gICAgICAgICAgY29uc3QgaXNFbXB0eVRleHROb2RlID1cbiAgICAgICAgICAgIGNoaWxkTm9kZS5ub2RlVHlwZSA9PT0gTm9kZS5URVhUX05PREUgJiZcbiAgICAgICAgICAgIGNoaWxkTm9kZS5ub2RlVmFsdWUudHJpbSgpID09PSBcIlwiO1xuICAgICAgICAgIGlmICghaXNFbXB0eVRleHROb2RlICYmIGNoaWxkTm9kZS5ub2RlVHlwZSAhPT0gTm9kZS5DT01NRU5UX05PREUpIHtcbiAgICAgICAgICAgIGxvZ0Vycm9yKFxuICAgICAgICAgICAgICBcIm9ubHkgSFRNTCBlbGVtZW50IHRhZ3Mgd2l0aCBhbiBpZCBhcmUgYWxsb3dlZCBpbnNpZGUgY29udGFpbmVycyB3aXRoIHBoeC11cGRhdGUuXFxuXFxuXCIgK1xuICAgICAgICAgICAgICAgIGByZW1vdmluZyBpbGxlZ2FsIG5vZGU6IFwiJHsoY2hpbGROb2RlLm91dGVySFRNTCB8fCBjaGlsZE5vZGUubm9kZVZhbHVlKS50cmltKCl9XCJcXG5cXG5gLFxuICAgICAgICAgICAgKTtcbiAgICAgICAgICB9XG4gICAgICAgICAgdG9SZW1vdmUucHVzaChjaGlsZE5vZGUpO1xuICAgICAgICB9XG4gICAgICB9KTtcbiAgICAgIHRvUmVtb3ZlLmZvckVhY2goKGNoaWxkTm9kZSkgPT4gY2hpbGROb2RlLnJlbW92ZSgpKTtcbiAgICB9XG4gIH0sXG5cbiAgcmVwbGFjZVJvb3RDb250YWluZXIoY29udGFpbmVyLCB0YWdOYW1lLCBhdHRycykge1xuICAgIGNvbnN0IHJldGFpbmVkQXR0cnMgPSBuZXcgU2V0KFtcbiAgICAgIFwiaWRcIixcbiAgICAgIFBIWF9TRVNTSU9OLFxuICAgICAgUEhYX1NUQVRJQyxcbiAgICAgIFBIWF9NQUlOLFxuICAgICAgUEhYX1JPT1RfSUQsXG4gICAgXSk7XG4gICAgaWYgKGNvbnRhaW5lci50YWdOYW1lLnRvTG93ZXJDYXNlKCkgPT09IHRhZ05hbWUudG9Mb3dlckNhc2UoKSkge1xuICAgICAgQXJyYXkuZnJvbShjb250YWluZXIuYXR0cmlidXRlcylcbiAgICAgICAgLmZpbHRlcigoYXR0cikgPT4gIXJldGFpbmVkQXR0cnMuaGFzKGF0dHIubmFtZS50b0xvd2VyQ2FzZSgpKSlcbiAgICAgICAgLmZvckVhY2goKGF0dHIpID0+IGNvbnRhaW5lci5yZW1vdmVBdHRyaWJ1dGUoYXR0ci5uYW1lKSk7XG5cbiAgICAgIE9iamVjdC5rZXlzKGF0dHJzKVxuICAgICAgICAuZmlsdGVyKChuYW1lKSA9PiAhcmV0YWluZWRBdHRycy5oYXMobmFtZS50b0xvd2VyQ2FzZSgpKSlcbiAgICAgICAgLmZvckVhY2goKGF0dHIpID0+IGNvbnRhaW5lci5zZXRBdHRyaWJ1dGUoYXR0ciwgYXR0cnNbYXR0cl0pKTtcblxuICAgICAgcmV0dXJuIGNvbnRhaW5lcjtcbiAgICB9IGVsc2Uge1xuICAgICAgY29uc3QgbmV3Q29udGFpbmVyID0gZG9jdW1lbnQuY3JlYXRlRWxlbWVudCh0YWdOYW1lKTtcbiAgICAgIE9iamVjdC5rZXlzKGF0dHJzKS5mb3JFYWNoKChhdHRyKSA9PlxuICAgICAgICBuZXdDb250YWluZXIuc2V0QXR0cmlidXRlKGF0dHIsIGF0dHJzW2F0dHJdKSxcbiAgICAgICk7XG4gICAgICByZXRhaW5lZEF0dHJzLmZvckVhY2goKGF0dHIpID0+XG4gICAgICAgIG5ld0NvbnRhaW5lci5zZXRBdHRyaWJ1dGUoYXR0ciwgY29udGFpbmVyLmdldEF0dHJpYnV0ZShhdHRyKSksXG4gICAgICApO1xuICAgICAgbmV3Q29udGFpbmVyLmlubmVySFRNTCA9IGNvbnRhaW5lci5pbm5lckhUTUw7XG4gICAgICBjb250YWluZXIucmVwbGFjZVdpdGgobmV3Q29udGFpbmVyKTtcbiAgICAgIHJldHVybiBuZXdDb250YWluZXI7XG4gICAgfVxuICB9LFxuXG4gIGdldFN0aWNreShlbCwgbmFtZSwgZGVmYXVsdFZhbCkge1xuICAgIGNvbnN0IG9wID0gKERPTS5wcml2YXRlKGVsLCBcInN0aWNreVwiKSB8fCBbXSkuZmluZChcbiAgICAgIChbZXhpc3RpbmdOYW1lXSkgPT4gbmFtZSA9PT0gZXhpc3RpbmdOYW1lLFxuICAgICk7XG4gICAgaWYgKG9wKSB7XG4gICAgICBjb25zdCBbX25hbWUsIF9vcCwgc3Rhc2hlZFJlc3VsdF0gPSBvcDtcbiAgICAgIHJldHVybiBzdGFzaGVkUmVzdWx0O1xuICAgIH0gZWxzZSB7XG4gICAgICByZXR1cm4gdHlwZW9mIGRlZmF1bHRWYWwgPT09IFwiZnVuY3Rpb25cIiA/IGRlZmF1bHRWYWwoKSA6IGRlZmF1bHRWYWw7XG4gICAgfVxuICB9LFxuXG4gIGRlbGV0ZVN0aWNreShlbCwgbmFtZSkge1xuICAgIHRoaXMudXBkYXRlUHJpdmF0ZShlbCwgXCJzdGlja3lcIiwgW10sIChvcHMpID0+IHtcbiAgICAgIHJldHVybiBvcHMuZmlsdGVyKChbZXhpc3RpbmdOYW1lLCBfXSkgPT4gZXhpc3RpbmdOYW1lICE9PSBuYW1lKTtcbiAgICB9KTtcbiAgfSxcblxuICBwdXRTdGlja3koZWwsIG5hbWUsIG9wKSB7XG4gICAgY29uc3Qgc3Rhc2hlZFJlc3VsdCA9IG9wKGVsKTtcbiAgICB0aGlzLnVwZGF0ZVByaXZhdGUoZWwsIFwic3RpY2t5XCIsIFtdLCAob3BzKSA9PiB7XG4gICAgICBjb25zdCBleGlzdGluZ0luZGV4ID0gb3BzLmZpbmRJbmRleChcbiAgICAgICAgKFtleGlzdGluZ05hbWVdKSA9PiBuYW1lID09PSBleGlzdGluZ05hbWUsXG4gICAgICApO1xuICAgICAgaWYgKGV4aXN0aW5nSW5kZXggPj0gMCkge1xuICAgICAgICBvcHNbZXhpc3RpbmdJbmRleF0gPSBbbmFtZSwgb3AsIHN0YXNoZWRSZXN1bHRdO1xuICAgICAgfSBlbHNlIHtcbiAgICAgICAgb3BzLnB1c2goW25hbWUsIG9wLCBzdGFzaGVkUmVzdWx0XSk7XG4gICAgICB9XG4gICAgICByZXR1cm4gb3BzO1xuICAgIH0pO1xuICB9LFxuXG4gIGFwcGx5U3RpY2t5T3BlcmF0aW9ucyhlbCkge1xuICAgIGNvbnN0IG9wcyA9IERPTS5wcml2YXRlKGVsLCBcInN0aWNreVwiKTtcbiAgICBpZiAoIW9wcykge1xuICAgICAgcmV0dXJuO1xuICAgIH1cblxuICAgIG9wcy5mb3JFYWNoKChbbmFtZSwgb3AsIF9zdGFzaGVkXSkgPT4gdGhpcy5wdXRTdGlja3koZWwsIG5hbWUsIG9wKSk7XG4gIH0sXG5cbiAgaXNMb2NrZWQoZWwpIHtcbiAgICByZXR1cm4gZWwuaGFzQXR0cmlidXRlICYmIGVsLmhhc0F0dHJpYnV0ZShQSFhfUkVGX0xPQ0spO1xuICB9LFxufTtcblxuZXhwb3J0IGRlZmF1bHQgRE9NO1xuIiwgImltcG9ydCB7XG4gIFBIWF9BQ1RJVkVfRU5UUllfUkVGUyxcbiAgUEhYX0xJVkVfRklMRV9VUERBVEVELFxuICBQSFhfUFJFRkxJR0hURURfUkVGUyxcbn0gZnJvbSBcIi4vY29uc3RhbnRzXCI7XG5cbmltcG9ydCB7IGNoYW5uZWxVcGxvYWRlciwgbG9nRXJyb3IgfSBmcm9tIFwiLi91dGlsc1wiO1xuXG5pbXBvcnQgTGl2ZVVwbG9hZGVyIGZyb20gXCIuL2xpdmVfdXBsb2FkZXJcIjtcblxuZXhwb3J0IGRlZmF1bHQgY2xhc3MgVXBsb2FkRW50cnkge1xuICBzdGF0aWMgaXNBY3RpdmUoZmlsZUVsLCBmaWxlKSB7XG4gICAgY29uc3QgaXNOZXcgPSBmaWxlLl9waHhSZWYgPT09IHVuZGVmaW5lZDtcbiAgICBjb25zdCBhY3RpdmVSZWZzID0gZmlsZUVsLmdldEF0dHJpYnV0ZShQSFhfQUNUSVZFX0VOVFJZX1JFRlMpLnNwbGl0KFwiLFwiKTtcbiAgICBjb25zdCBpc0FjdGl2ZSA9IGFjdGl2ZVJlZnMuaW5kZXhPZihMaXZlVXBsb2FkZXIuZ2VuRmlsZVJlZihmaWxlKSkgPj0gMDtcbiAgICByZXR1cm4gZmlsZS5zaXplID4gMCAmJiAoaXNOZXcgfHwgaXNBY3RpdmUpO1xuICB9XG5cbiAgc3RhdGljIGlzUHJlZmxpZ2h0ZWQoZmlsZUVsLCBmaWxlKSB7XG4gICAgY29uc3QgcHJlZmxpZ2h0ZWRSZWZzID0gZmlsZUVsXG4gICAgICAuZ2V0QXR0cmlidXRlKFBIWF9QUkVGTElHSFRFRF9SRUZTKVxuICAgICAgLnNwbGl0KFwiLFwiKTtcbiAgICBjb25zdCBpc1ByZWZsaWdodGVkID1cbiAgICAgIHByZWZsaWdodGVkUmVmcy5pbmRleE9mKExpdmVVcGxvYWRlci5nZW5GaWxlUmVmKGZpbGUpKSA+PSAwO1xuICAgIHJldHVybiBpc1ByZWZsaWdodGVkICYmIHRoaXMuaXNBY3RpdmUoZmlsZUVsLCBmaWxlKTtcbiAgfVxuXG4gIHN0YXRpYyBpc1ByZWZsaWdodEluUHJvZ3Jlc3MoZmlsZSkge1xuICAgIHJldHVybiBmaWxlLl9wcmVmbGlnaHRJblByb2dyZXNzID09PSB0cnVlO1xuICB9XG5cbiAgc3RhdGljIG1hcmtQcmVmbGlnaHRJblByb2dyZXNzKGZpbGUpIHtcbiAgICBmaWxlLl9wcmVmbGlnaHRJblByb2dyZXNzID0gdHJ1ZTtcbiAgfVxuXG4gIGNvbnN0cnVjdG9yKGZpbGVFbCwgZmlsZSwgdmlldywgYXV0b1VwbG9hZCkge1xuICAgIHRoaXMucmVmID0gTGl2ZVVwbG9hZGVyLmdlbkZpbGVSZWYoZmlsZSk7XG4gICAgdGhpcy5maWxlRWwgPSBmaWxlRWw7XG4gICAgdGhpcy5maWxlID0gZmlsZTtcbiAgICB0aGlzLnZpZXcgPSB2aWV3O1xuICAgIHRoaXMubWV0YSA9IG51bGw7XG4gICAgdGhpcy5faXNDYW5jZWxsZWQgPSBmYWxzZTtcbiAgICB0aGlzLl9pc0RvbmUgPSBmYWxzZTtcbiAgICB0aGlzLl9wcm9ncmVzcyA9IDA7XG4gICAgdGhpcy5fbGFzdFByb2dyZXNzU2VudCA9IC0xO1xuICAgIHRoaXMuX29uRG9uZSA9IGZ1bmN0aW9uICgpIHt9O1xuICAgIHRoaXMuX29uRWxVcGRhdGVkID0gdGhpcy5vbkVsVXBkYXRlZC5iaW5kKHRoaXMpO1xuICAgIHRoaXMuZmlsZUVsLmFkZEV2ZW50TGlzdGVuZXIoUEhYX0xJVkVfRklMRV9VUERBVEVELCB0aGlzLl9vbkVsVXBkYXRlZCk7XG4gICAgdGhpcy5hdXRvVXBsb2FkID0gYXV0b1VwbG9hZDtcbiAgfVxuXG4gIG1ldGFkYXRhKCkge1xuICAgIHJldHVybiB0aGlzLm1ldGE7XG4gIH1cblxuICBwcm9ncmVzcyhwcm9ncmVzcykge1xuICAgIHRoaXMuX3Byb2dyZXNzID0gTWF0aC5mbG9vcihwcm9ncmVzcyk7XG4gICAgaWYgKHRoaXMuX3Byb2dyZXNzID4gdGhpcy5fbGFzdFByb2dyZXNzU2VudCkge1xuICAgICAgaWYgKHRoaXMuX3Byb2dyZXNzID49IDEwMCkge1xuICAgICAgICB0aGlzLl9wcm9ncmVzcyA9IDEwMDtcbiAgICAgICAgdGhpcy5fbGFzdFByb2dyZXNzU2VudCA9IDEwMDtcbiAgICAgICAgdGhpcy5faXNEb25lID0gdHJ1ZTtcbiAgICAgICAgdGhpcy52aWV3LnB1c2hGaWxlUHJvZ3Jlc3ModGhpcy5maWxlRWwsIHRoaXMucmVmLCAxMDAsICgpID0+IHtcbiAgICAgICAgICBMaXZlVXBsb2FkZXIudW50cmFja0ZpbGUodGhpcy5maWxlRWwsIHRoaXMuZmlsZSk7XG4gICAgICAgICAgdGhpcy5fb25Eb25lKCk7XG4gICAgICAgIH0pO1xuICAgICAgfSBlbHNlIHtcbiAgICAgICAgdGhpcy5fbGFzdFByb2dyZXNzU2VudCA9IHRoaXMuX3Byb2dyZXNzO1xuICAgICAgICB0aGlzLnZpZXcucHVzaEZpbGVQcm9ncmVzcyh0aGlzLmZpbGVFbCwgdGhpcy5yZWYsIHRoaXMuX3Byb2dyZXNzKTtcbiAgICAgIH1cbiAgICB9XG4gIH1cblxuICBpc0NhbmNlbGxlZCgpIHtcbiAgICByZXR1cm4gdGhpcy5faXNDYW5jZWxsZWQ7XG4gIH1cblxuICBjYW5jZWwoKSB7XG4gICAgdGhpcy5maWxlLl9wcmVmbGlnaHRJblByb2dyZXNzID0gZmFsc2U7XG4gICAgdGhpcy5faXNDYW5jZWxsZWQgPSB0cnVlO1xuICAgIHRoaXMuX2lzRG9uZSA9IHRydWU7XG4gICAgdGhpcy5fb25Eb25lKCk7XG4gIH1cblxuICBpc0RvbmUoKSB7XG4gICAgcmV0dXJuIHRoaXMuX2lzRG9uZTtcbiAgfVxuXG4gIGVycm9yKHJlYXNvbiA9IFwiZmFpbGVkXCIpIHtcbiAgICB0aGlzLmZpbGVFbC5yZW1vdmVFdmVudExpc3RlbmVyKFBIWF9MSVZFX0ZJTEVfVVBEQVRFRCwgdGhpcy5fb25FbFVwZGF0ZWQpO1xuICAgIHRoaXMudmlldy5wdXNoRmlsZVByb2dyZXNzKHRoaXMuZmlsZUVsLCB0aGlzLnJlZiwgeyBlcnJvcjogcmVhc29uIH0pO1xuICAgIGlmICghdGhpcy5pc0F1dG9VcGxvYWQoKSkge1xuICAgICAgTGl2ZVVwbG9hZGVyLmNsZWFyRmlsZXModGhpcy5maWxlRWwpO1xuICAgIH1cbiAgfVxuXG4gIGlzQXV0b1VwbG9hZCgpIHtcbiAgICByZXR1cm4gdGhpcy5hdXRvVXBsb2FkO1xuICB9XG5cbiAgLy9wcml2YXRlXG5cbiAgb25Eb25lKGNhbGxiYWNrKSB7XG4gICAgdGhpcy5fb25Eb25lID0gKCkgPT4ge1xuICAgICAgdGhpcy5maWxlRWwucmVtb3ZlRXZlbnRMaXN0ZW5lcihQSFhfTElWRV9GSUxFX1VQREFURUQsIHRoaXMuX29uRWxVcGRhdGVkKTtcbiAgICAgIGNhbGxiYWNrKCk7XG4gICAgfTtcbiAgfVxuXG4gIG9uRWxVcGRhdGVkKCkge1xuICAgIGNvbnN0IGFjdGl2ZVJlZnMgPSB0aGlzLmZpbGVFbFxuICAgICAgLmdldEF0dHJpYnV0ZShQSFhfQUNUSVZFX0VOVFJZX1JFRlMpXG4gICAgICAuc3BsaXQoXCIsXCIpO1xuICAgIGlmIChhY3RpdmVSZWZzLmluZGV4T2YodGhpcy5yZWYpID09PSAtMSkge1xuICAgICAgTGl2ZVVwbG9hZGVyLnVudHJhY2tGaWxlKHRoaXMuZmlsZUVsLCB0aGlzLmZpbGUpO1xuICAgICAgdGhpcy5jYW5jZWwoKTtcbiAgICB9XG4gIH1cblxuICB0b1ByZWZsaWdodFBheWxvYWQoKSB7XG4gICAgcmV0dXJuIHtcbiAgICAgIGxhc3RfbW9kaWZpZWQ6IHRoaXMuZmlsZS5sYXN0TW9kaWZpZWQsXG4gICAgICBuYW1lOiB0aGlzLmZpbGUubmFtZSxcbiAgICAgIHJlbGF0aXZlX3BhdGg6IHRoaXMuZmlsZS53ZWJraXRSZWxhdGl2ZVBhdGgsXG4gICAgICBzaXplOiB0aGlzLmZpbGUuc2l6ZSxcbiAgICAgIHR5cGU6IHRoaXMuZmlsZS50eXBlLFxuICAgICAgcmVmOiB0aGlzLnJlZixcbiAgICAgIG1ldGE6IHR5cGVvZiB0aGlzLmZpbGUubWV0YSA9PT0gXCJmdW5jdGlvblwiID8gdGhpcy5maWxlLm1ldGEoKSA6IHVuZGVmaW5lZCxcbiAgICB9O1xuICB9XG5cbiAgdXBsb2FkZXIodXBsb2FkZXJzKSB7XG4gICAgaWYgKHRoaXMubWV0YS51cGxvYWRlcikge1xuICAgICAgY29uc3QgY2FsbGJhY2sgPVxuICAgICAgICB1cGxvYWRlcnNbdGhpcy5tZXRhLnVwbG9hZGVyXSB8fFxuICAgICAgICBsb2dFcnJvcihgbm8gdXBsb2FkZXIgY29uZmlndXJlZCBmb3IgJHt0aGlzLm1ldGEudXBsb2FkZXJ9YCk7XG4gICAgICByZXR1cm4geyBuYW1lOiB0aGlzLm1ldGEudXBsb2FkZXIsIGNhbGxiYWNrOiBjYWxsYmFjayB9O1xuICAgIH0gZWxzZSB7XG4gICAgICByZXR1cm4geyBuYW1lOiBcImNoYW5uZWxcIiwgY2FsbGJhY2s6IGNoYW5uZWxVcGxvYWRlciB9O1xuICAgIH1cbiAgfVxuXG4gIHppcFBvc3RGbGlnaHQocmVzcCkge1xuICAgIHRoaXMubWV0YSA9IHJlc3AuZW50cmllc1t0aGlzLnJlZl07XG4gICAgaWYgKCF0aGlzLm1ldGEpIHtcbiAgICAgIGxvZ0Vycm9yKGBubyBwcmVmbGlnaHQgdXBsb2FkIHJlc3BvbnNlIHJldHVybmVkIHdpdGggcmVmICR7dGhpcy5yZWZ9YCwge1xuICAgICAgICBpbnB1dDogdGhpcy5maWxlRWwsXG4gICAgICAgIHJlc3BvbnNlOiByZXNwLFxuICAgICAgfSk7XG4gICAgfVxuICB9XG59XG4iLCAiaW1wb3J0IHtcbiAgUEhYX0RPTkVfUkVGUyxcbiAgUEhYX1BSRUZMSUdIVEVEX1JFRlMsXG4gIFBIWF9VUExPQURfUkVGLFxufSBmcm9tIFwiLi9jb25zdGFudHNcIjtcblxuaW1wb3J0IHt9IGZyb20gXCIuL3V0aWxzXCI7XG5cbmltcG9ydCBET00gZnJvbSBcIi4vZG9tXCI7XG5pbXBvcnQgVXBsb2FkRW50cnkgZnJvbSBcIi4vdXBsb2FkX2VudHJ5XCI7XG5cbmxldCBsaXZlVXBsb2FkZXJGaWxlUmVmID0gMDtcblxuZXhwb3J0IGRlZmF1bHQgY2xhc3MgTGl2ZVVwbG9hZGVyIHtcbiAgc3RhdGljIGdlbkZpbGVSZWYoZmlsZSkge1xuICAgIGNvbnN0IHJlZiA9IGZpbGUuX3BoeFJlZjtcbiAgICBpZiAocmVmICE9PSB1bmRlZmluZWQpIHtcbiAgICAgIHJldHVybiByZWY7XG4gICAgfSBlbHNlIHtcbiAgICAgIGZpbGUuX3BoeFJlZiA9IChsaXZlVXBsb2FkZXJGaWxlUmVmKyspLnRvU3RyaW5nKCk7XG4gICAgICByZXR1cm4gZmlsZS5fcGh4UmVmO1xuICAgIH1cbiAgfVxuXG4gIHN0YXRpYyBnZXRFbnRyeURhdGFVUkwoaW5wdXRFbCwgcmVmLCBjYWxsYmFjaykge1xuICAgIGNvbnN0IGZpbGUgPSB0aGlzLmFjdGl2ZUZpbGVzKGlucHV0RWwpLmZpbmQoXG4gICAgICAoZmlsZSkgPT4gdGhpcy5nZW5GaWxlUmVmKGZpbGUpID09PSByZWYsXG4gICAgKTtcbiAgICBjYWxsYmFjayhVUkwuY3JlYXRlT2JqZWN0VVJMKGZpbGUpKTtcbiAgfVxuXG4gIHN0YXRpYyBoYXNVcGxvYWRzSW5Qcm9ncmVzcyhmb3JtRWwpIHtcbiAgICBsZXQgYWN0aXZlID0gMDtcbiAgICBET00uZmluZFVwbG9hZElucHV0cyhmb3JtRWwpLmZvckVhY2goKGlucHV0KSA9PiB7XG4gICAgICBpZiAoXG4gICAgICAgIGlucHV0LmdldEF0dHJpYnV0ZShQSFhfUFJFRkxJR0hURURfUkVGUykgIT09XG4gICAgICAgIGlucHV0LmdldEF0dHJpYnV0ZShQSFhfRE9ORV9SRUZTKVxuICAgICAgKSB7XG4gICAgICAgIGFjdGl2ZSsrO1xuICAgICAgfVxuICAgIH0pO1xuICAgIHJldHVybiBhY3RpdmUgPiAwO1xuICB9XG5cbiAgc3RhdGljIHNlcmlhbGl6ZVVwbG9hZHMoaW5wdXRFbCkge1xuICAgIGNvbnN0IGZpbGVzID0gdGhpcy5hY3RpdmVGaWxlcyhpbnB1dEVsKTtcbiAgICBjb25zdCBmaWxlRGF0YSA9IHt9O1xuICAgIGZpbGVzLmZvckVhY2goKGZpbGUpID0+IHtcbiAgICAgIGNvbnN0IGVudHJ5ID0geyBwYXRoOiBpbnB1dEVsLm5hbWUgfTtcbiAgICAgIGNvbnN0IHVwbG9hZFJlZiA9IGlucHV0RWwuZ2V0QXR0cmlidXRlKFBIWF9VUExPQURfUkVGKTtcbiAgICAgIGZpbGVEYXRhW3VwbG9hZFJlZl0gPSBmaWxlRGF0YVt1cGxvYWRSZWZdIHx8IFtdO1xuICAgICAgZW50cnkucmVmID0gdGhpcy5nZW5GaWxlUmVmKGZpbGUpO1xuICAgICAgZW50cnkubGFzdF9tb2RpZmllZCA9IGZpbGUubGFzdE1vZGlmaWVkO1xuICAgICAgZW50cnkubmFtZSA9IGZpbGUubmFtZSB8fCBlbnRyeS5yZWY7XG4gICAgICBlbnRyeS5yZWxhdGl2ZV9wYXRoID0gZmlsZS53ZWJraXRSZWxhdGl2ZVBhdGg7XG4gICAgICBlbnRyeS50eXBlID0gZmlsZS50eXBlO1xuICAgICAgZW50cnkuc2l6ZSA9IGZpbGUuc2l6ZTtcbiAgICAgIGlmICh0eXBlb2YgZmlsZS5tZXRhID09PSBcImZ1bmN0aW9uXCIpIHtcbiAgICAgICAgZW50cnkubWV0YSA9IGZpbGUubWV0YSgpO1xuICAgICAgfVxuICAgICAgZmlsZURhdGFbdXBsb2FkUmVmXS5wdXNoKGVudHJ5KTtcbiAgICB9KTtcbiAgICByZXR1cm4gZmlsZURhdGE7XG4gIH1cblxuICBzdGF0aWMgY2xlYXJGaWxlcyhpbnB1dEVsKSB7XG4gICAgaW5wdXRFbC52YWx1ZSA9IG51bGw7XG4gICAgaW5wdXRFbC5yZW1vdmVBdHRyaWJ1dGUoUEhYX1VQTE9BRF9SRUYpO1xuICAgIERPTS5wdXRQcml2YXRlKGlucHV0RWwsIFwiZmlsZXNcIiwgW10pO1xuICB9XG5cbiAgc3RhdGljIHVudHJhY2tGaWxlKGlucHV0RWwsIGZpbGUpIHtcbiAgICBET00ucHV0UHJpdmF0ZShcbiAgICAgIGlucHV0RWwsXG4gICAgICBcImZpbGVzXCIsXG4gICAgICBET00ucHJpdmF0ZShpbnB1dEVsLCBcImZpbGVzXCIpLmZpbHRlcigoZikgPT4gIU9iamVjdC5pcyhmLCBmaWxlKSksXG4gICAgKTtcbiAgfVxuXG4gIC8qKlxuICAgKiBAcGFyYW0ge0hUTUxJbnB1dEVsZW1lbnR9IGlucHV0RWxcbiAgICogQHBhcmFtIHtBcnJheTxGaWxlfEJsb2I+fSBmaWxlc1xuICAgKiBAcGFyYW0ge0RhdGFUcmFuc2Zlcn0gW2RhdGFUcmFuc2Zlcl1cbiAgICovXG4gIHN0YXRpYyB0cmFja0ZpbGVzKGlucHV0RWwsIGZpbGVzLCBkYXRhVHJhbnNmZXIpIHtcbiAgICBpZiAoaW5wdXRFbC5nZXRBdHRyaWJ1dGUoXCJtdWx0aXBsZVwiKSAhPT0gbnVsbCkge1xuICAgICAgY29uc3QgbmV3RmlsZXMgPSBmaWxlcy5maWx0ZXIoXG4gICAgICAgIChmaWxlKSA9PiAhdGhpcy5hY3RpdmVGaWxlcyhpbnB1dEVsKS5maW5kKChmKSA9PiBPYmplY3QuaXMoZiwgZmlsZSkpLFxuICAgICAgKTtcbiAgICAgIERPTS51cGRhdGVQcml2YXRlKGlucHV0RWwsIFwiZmlsZXNcIiwgW10sIChleGlzdGluZykgPT5cbiAgICAgICAgZXhpc3RpbmcuY29uY2F0KG5ld0ZpbGVzKSxcbiAgICAgICk7XG4gICAgICBpbnB1dEVsLnZhbHVlID0gbnVsbDtcbiAgICB9IGVsc2Uge1xuICAgICAgLy8gUmVzZXQgaW5wdXRFbCBmaWxlcyB0byBhbGlnbiBvdXRwdXQgd2l0aCBwcm9ncmFtbWF0aWMgY2hhbmdlcyAoaS5lLiBkcmFnIGFuZCBkcm9wKVxuICAgICAgaWYgKGRhdGFUcmFuc2ZlciAmJiBkYXRhVHJhbnNmZXIuZmlsZXMubGVuZ3RoID4gMCkge1xuICAgICAgICBpbnB1dEVsLmZpbGVzID0gZGF0YVRyYW5zZmVyLmZpbGVzO1xuICAgICAgfVxuICAgICAgRE9NLnB1dFByaXZhdGUoaW5wdXRFbCwgXCJmaWxlc1wiLCBmaWxlcyk7XG4gICAgfVxuICB9XG5cbiAgc3RhdGljIGFjdGl2ZUZpbGVJbnB1dHMoZm9ybUVsKSB7XG4gICAgY29uc3QgZmlsZUlucHV0cyA9IERPTS5maW5kVXBsb2FkSW5wdXRzKGZvcm1FbCk7XG4gICAgcmV0dXJuIEFycmF5LmZyb20oZmlsZUlucHV0cykuZmlsdGVyKFxuICAgICAgKGVsKSA9PiBlbC5maWxlcyAmJiB0aGlzLmFjdGl2ZUZpbGVzKGVsKS5sZW5ndGggPiAwLFxuICAgICk7XG4gIH1cblxuICBzdGF0aWMgYWN0aXZlRmlsZXMoaW5wdXQpIHtcbiAgICByZXR1cm4gKERPTS5wcml2YXRlKGlucHV0LCBcImZpbGVzXCIpIHx8IFtdKS5maWx0ZXIoKGYpID0+XG4gICAgICBVcGxvYWRFbnRyeS5pc0FjdGl2ZShpbnB1dCwgZiksXG4gICAgKTtcbiAgfVxuXG4gIHN0YXRpYyBpbnB1dHNBd2FpdGluZ1ByZWZsaWdodChmb3JtRWwpIHtcbiAgICBjb25zdCBmaWxlSW5wdXRzID0gRE9NLmZpbmRVcGxvYWRJbnB1dHMoZm9ybUVsKTtcbiAgICByZXR1cm4gQXJyYXkuZnJvbShmaWxlSW5wdXRzKS5maWx0ZXIoXG4gICAgICAoaW5wdXQpID0+IHRoaXMuZmlsZXNBd2FpdGluZ1ByZWZsaWdodChpbnB1dCkubGVuZ3RoID4gMCxcbiAgICApO1xuICB9XG5cbiAgc3RhdGljIGZpbGVzQXdhaXRpbmdQcmVmbGlnaHQoaW5wdXQpIHtcbiAgICByZXR1cm4gdGhpcy5hY3RpdmVGaWxlcyhpbnB1dCkuZmlsdGVyKFxuICAgICAgKGYpID0+XG4gICAgICAgICFVcGxvYWRFbnRyeS5pc1ByZWZsaWdodGVkKGlucHV0LCBmKSAmJlxuICAgICAgICAhVXBsb2FkRW50cnkuaXNQcmVmbGlnaHRJblByb2dyZXNzKGYpLFxuICAgICk7XG4gIH1cblxuICBzdGF0aWMgbWFya1ByZWZsaWdodEluUHJvZ3Jlc3MoZW50cmllcykge1xuICAgIGVudHJpZXMuZm9yRWFjaCgoZW50cnkpID0+IFVwbG9hZEVudHJ5Lm1hcmtQcmVmbGlnaHRJblByb2dyZXNzKGVudHJ5LmZpbGUpKTtcbiAgfVxuXG4gIGNvbnN0cnVjdG9yKGlucHV0RWwsIHZpZXcsIG9uQ29tcGxldGUpIHtcbiAgICB0aGlzLmF1dG9VcGxvYWQgPSBET00uaXNBdXRvVXBsb2FkKGlucHV0RWwpO1xuICAgIHRoaXMudmlldyA9IHZpZXc7XG4gICAgdGhpcy5vbkNvbXBsZXRlID0gb25Db21wbGV0ZTtcbiAgICB0aGlzLl9lbnRyaWVzID0gQXJyYXkuZnJvbShcbiAgICAgIExpdmVVcGxvYWRlci5maWxlc0F3YWl0aW5nUHJlZmxpZ2h0KGlucHV0RWwpIHx8IFtdLFxuICAgICkubWFwKChmaWxlKSA9PiBuZXcgVXBsb2FkRW50cnkoaW5wdXRFbCwgZmlsZSwgdmlldywgdGhpcy5hdXRvVXBsb2FkKSk7XG5cbiAgICAvLyBwcmV2ZW50IHNlbmRpbmcgZHVwbGljYXRlIHByZWZsaWdodCByZXF1ZXN0c1xuICAgIExpdmVVcGxvYWRlci5tYXJrUHJlZmxpZ2h0SW5Qcm9ncmVzcyh0aGlzLl9lbnRyaWVzKTtcblxuICAgIHRoaXMubnVtRW50cmllc0luUHJvZ3Jlc3MgPSB0aGlzLl9lbnRyaWVzLmxlbmd0aDtcbiAgfVxuXG4gIGlzQXV0b1VwbG9hZCgpIHtcbiAgICByZXR1cm4gdGhpcy5hdXRvVXBsb2FkO1xuICB9XG5cbiAgZW50cmllcygpIHtcbiAgICByZXR1cm4gdGhpcy5fZW50cmllcztcbiAgfVxuXG4gIGluaXRBZGFwdGVyVXBsb2FkKHJlc3AsIG9uRXJyb3IsIGxpdmVTb2NrZXQpIHtcbiAgICB0aGlzLl9lbnRyaWVzID0gdGhpcy5fZW50cmllcy5tYXAoKGVudHJ5KSA9PiB7XG4gICAgICBpZiAoZW50cnkuaXNDYW5jZWxsZWQoKSkge1xuICAgICAgICB0aGlzLm51bUVudHJpZXNJblByb2dyZXNzLS07XG4gICAgICAgIGlmICh0aGlzLm51bUVudHJpZXNJblByb2dyZXNzID09PSAwKSB7XG4gICAgICAgICAgdGhpcy5vbkNvbXBsZXRlKCk7XG4gICAgICAgIH1cbiAgICAgIH0gZWxzZSB7XG4gICAgICAgIGVudHJ5LnppcFBvc3RGbGlnaHQocmVzcCk7XG4gICAgICAgIGVudHJ5Lm9uRG9uZSgoKSA9PiB7XG4gICAgICAgICAgdGhpcy5udW1FbnRyaWVzSW5Qcm9ncmVzcy0tO1xuICAgICAgICAgIGlmICh0aGlzLm51bUVudHJpZXNJblByb2dyZXNzID09PSAwKSB7XG4gICAgICAgICAgICB0aGlzLm9uQ29tcGxldGUoKTtcbiAgICAgICAgICB9XG4gICAgICAgIH0pO1xuICAgICAgfVxuICAgICAgcmV0dXJuIGVudHJ5O1xuICAgIH0pO1xuXG4gICAgY29uc3QgZ3JvdXBlZEVudHJpZXMgPSB0aGlzLl9lbnRyaWVzLnJlZHVjZSgoYWNjLCBlbnRyeSkgPT4ge1xuICAgICAgaWYgKCFlbnRyeS5tZXRhKSB7XG4gICAgICAgIHJldHVybiBhY2M7XG4gICAgICB9XG4gICAgICBjb25zdCB7IG5hbWUsIGNhbGxiYWNrIH0gPSBlbnRyeS51cGxvYWRlcihsaXZlU29ja2V0LnVwbG9hZGVycyk7XG4gICAgICBhY2NbbmFtZV0gPSBhY2NbbmFtZV0gfHwgeyBjYWxsYmFjazogY2FsbGJhY2ssIGVudHJpZXM6IFtdIH07XG4gICAgICBhY2NbbmFtZV0uZW50cmllcy5wdXNoKGVudHJ5KTtcbiAgICAgIHJldHVybiBhY2M7XG4gICAgfSwge30pO1xuXG4gICAgZm9yIChjb25zdCBuYW1lIGluIGdyb3VwZWRFbnRyaWVzKSB7XG4gICAgICBjb25zdCB7IGNhbGxiYWNrLCBlbnRyaWVzIH0gPSBncm91cGVkRW50cmllc1tuYW1lXTtcbiAgICAgIGNhbGxiYWNrKGVudHJpZXMsIG9uRXJyb3IsIHJlc3AsIGxpdmVTb2NrZXQpO1xuICAgIH1cbiAgfVxufVxuIiwgImNvbnN0IEFSSUEgPSB7XG4gIGFueU9mKGluc3RhbmNlLCBjbGFzc2VzKSB7XG4gICAgcmV0dXJuIGNsYXNzZXMuZmluZCgobmFtZSkgPT4gaW5zdGFuY2UgaW5zdGFuY2VvZiBuYW1lKTtcbiAgfSxcblxuICBpc0ZvY3VzYWJsZShlbCwgaW50ZXJhY3RpdmVPbmx5KSB7XG4gICAgcmV0dXJuIChcbiAgICAgIChlbCBpbnN0YW5jZW9mIEhUTUxBbmNob3JFbGVtZW50ICYmIGVsLnJlbCAhPT0gXCJpZ25vcmVcIikgfHxcbiAgICAgIChlbCBpbnN0YW5jZW9mIEhUTUxBcmVhRWxlbWVudCAmJiBlbC5ocmVmICE9PSB1bmRlZmluZWQpIHx8XG4gICAgICAoIWVsLmRpc2FibGVkICYmXG4gICAgICAgIHRoaXMuYW55T2YoZWwsIFtcbiAgICAgICAgICBIVE1MSW5wdXRFbGVtZW50LFxuICAgICAgICAgIEhUTUxTZWxlY3RFbGVtZW50LFxuICAgICAgICAgIEhUTUxUZXh0QXJlYUVsZW1lbnQsXG4gICAgICAgICAgSFRNTEJ1dHRvbkVsZW1lbnQsXG4gICAgICAgIF0pKSB8fFxuICAgICAgZWwgaW5zdGFuY2VvZiBIVE1MSUZyYW1lRWxlbWVudCB8fFxuICAgICAgKGVsLnRhYkluZGV4ID49IDAgJiYgZWwuZ2V0QXR0cmlidXRlKFwiYXJpYS1oaWRkZW5cIikgIT09IFwidHJ1ZVwiKSB8fFxuICAgICAgKCFpbnRlcmFjdGl2ZU9ubHkgJiZcbiAgICAgICAgZWwuZ2V0QXR0cmlidXRlKFwidGFiaW5kZXhcIikgIT09IG51bGwgJiZcbiAgICAgICAgZWwuZ2V0QXR0cmlidXRlKFwiYXJpYS1oaWRkZW5cIikgIT09IFwidHJ1ZVwiKVxuICAgICk7XG4gIH0sXG5cbiAgYXR0ZW1wdEZvY3VzKGVsLCBpbnRlcmFjdGl2ZU9ubHkpIHtcbiAgICBpZiAodGhpcy5pc0ZvY3VzYWJsZShlbCwgaW50ZXJhY3RpdmVPbmx5KSkge1xuICAgICAgdHJ5IHtcbiAgICAgICAgZWwuZm9jdXMoKTtcbiAgICAgIH0gY2F0Y2gge1xuICAgICAgICAvLyB0aGF0J3MgZmluZVxuICAgICAgfVxuICAgIH1cbiAgICByZXR1cm4gISFkb2N1bWVudC5hY3RpdmVFbGVtZW50ICYmIGRvY3VtZW50LmFjdGl2ZUVsZW1lbnQuaXNTYW1lTm9kZShlbCk7XG4gIH0sXG5cbiAgZm9jdXNGaXJzdEludGVyYWN0aXZlKGVsKSB7XG4gICAgbGV0IGNoaWxkID0gZWwuZmlyc3RFbGVtZW50Q2hpbGQ7XG4gICAgd2hpbGUgKGNoaWxkKSB7XG4gICAgICBpZiAodGhpcy5hdHRlbXB0Rm9jdXMoY2hpbGQsIHRydWUpIHx8IHRoaXMuZm9jdXNGaXJzdEludGVyYWN0aXZlKGNoaWxkKSkge1xuICAgICAgICByZXR1cm4gdHJ1ZTtcbiAgICAgIH1cbiAgICAgIGNoaWxkID0gY2hpbGQubmV4dEVsZW1lbnRTaWJsaW5nO1xuICAgIH1cbiAgfSxcblxuICBmb2N1c0ZpcnN0KGVsKSB7XG4gICAgbGV0IGNoaWxkID0gZWwuZmlyc3RFbGVtZW50Q2hpbGQ7XG4gICAgd2hpbGUgKGNoaWxkKSB7XG4gICAgICBpZiAodGhpcy5hdHRlbXB0Rm9jdXMoY2hpbGQpIHx8IHRoaXMuZm9jdXNGaXJzdChjaGlsZCkpIHtcbiAgICAgICAgcmV0dXJuIHRydWU7XG4gICAgICB9XG4gICAgICBjaGlsZCA9IGNoaWxkLm5leHRFbGVtZW50U2libGluZztcbiAgICB9XG4gIH0sXG5cbiAgZm9jdXNMYXN0KGVsKSB7XG4gICAgbGV0IGNoaWxkID0gZWwubGFzdEVsZW1lbnRDaGlsZDtcbiAgICB3aGlsZSAoY2hpbGQpIHtcbiAgICAgIGlmICh0aGlzLmF0dGVtcHRGb2N1cyhjaGlsZCkgfHwgdGhpcy5mb2N1c0xhc3QoY2hpbGQpKSB7XG4gICAgICAgIHJldHVybiB0cnVlO1xuICAgICAgfVxuICAgICAgY2hpbGQgPSBjaGlsZC5wcmV2aW91c0VsZW1lbnRTaWJsaW5nO1xuICAgIH1cbiAgfSxcbn07XG5leHBvcnQgZGVmYXVsdCBBUklBO1xuIiwgImltcG9ydCB7XG4gIFBIWF9BQ1RJVkVfRU5UUllfUkVGUyxcbiAgUEhYX0xJVkVfRklMRV9VUERBVEVELFxuICBQSFhfUFJFRkxJR0hURURfUkVGUyxcbiAgUEhYX1VQTE9BRF9SRUYsXG59IGZyb20gXCIuL2NvbnN0YW50c1wiO1xuXG5pbXBvcnQgTGl2ZVVwbG9hZGVyIGZyb20gXCIuL2xpdmVfdXBsb2FkZXJcIjtcbmltcG9ydCBBUklBIGZyb20gXCIuL2FyaWFcIjtcblxuY29uc3QgSG9va3MgPSB7XG4gIExpdmVGaWxlVXBsb2FkOiB7XG4gICAgYWN0aXZlUmVmcygpIHtcbiAgICAgIHJldHVybiB0aGlzLmVsLmdldEF0dHJpYnV0ZShQSFhfQUNUSVZFX0VOVFJZX1JFRlMpO1xuICAgIH0sXG5cbiAgICBwcmVmbGlnaHRlZFJlZnMoKSB7XG4gICAgICByZXR1cm4gdGhpcy5lbC5nZXRBdHRyaWJ1dGUoUEhYX1BSRUZMSUdIVEVEX1JFRlMpO1xuICAgIH0sXG5cbiAgICBtb3VudGVkKCkge1xuICAgICAgdGhpcy5wcmVmbGlnaHRlZFdhcyA9IHRoaXMucHJlZmxpZ2h0ZWRSZWZzKCk7XG4gICAgfSxcblxuICAgIHVwZGF0ZWQoKSB7XG4gICAgICBjb25zdCBuZXdQcmVmbGlnaHRzID0gdGhpcy5wcmVmbGlnaHRlZFJlZnMoKTtcbiAgICAgIGlmICh0aGlzLnByZWZsaWdodGVkV2FzICE9PSBuZXdQcmVmbGlnaHRzKSB7XG4gICAgICAgIHRoaXMucHJlZmxpZ2h0ZWRXYXMgPSBuZXdQcmVmbGlnaHRzO1xuICAgICAgICBpZiAobmV3UHJlZmxpZ2h0cyA9PT0gXCJcIikge1xuICAgICAgICAgIHRoaXMuX192aWV3KCkuY2FuY2VsU3VibWl0KHRoaXMuZWwuZm9ybSk7XG4gICAgICAgIH1cbiAgICAgIH1cblxuICAgICAgaWYgKHRoaXMuYWN0aXZlUmVmcygpID09PSBcIlwiKSB7XG4gICAgICAgIHRoaXMuZWwudmFsdWUgPSBudWxsO1xuICAgICAgfVxuICAgICAgdGhpcy5lbC5kaXNwYXRjaEV2ZW50KG5ldyBDdXN0b21FdmVudChQSFhfTElWRV9GSUxFX1VQREFURUQpKTtcbiAgICB9LFxuICB9LFxuXG4gIExpdmVJbWdQcmV2aWV3OiB7XG4gICAgbW91bnRlZCgpIHtcbiAgICAgIHRoaXMucmVmID0gdGhpcy5lbC5nZXRBdHRyaWJ1dGUoXCJkYXRhLXBoeC1lbnRyeS1yZWZcIik7XG4gICAgICB0aGlzLmlucHV0RWwgPSBkb2N1bWVudC5nZXRFbGVtZW50QnlJZChcbiAgICAgICAgdGhpcy5lbC5nZXRBdHRyaWJ1dGUoUEhYX1VQTE9BRF9SRUYpLFxuICAgICAgKTtcbiAgICAgIExpdmVVcGxvYWRlci5nZXRFbnRyeURhdGFVUkwodGhpcy5pbnB1dEVsLCB0aGlzLnJlZiwgKHVybCkgPT4ge1xuICAgICAgICB0aGlzLnVybCA9IHVybDtcbiAgICAgICAgdGhpcy5lbC5zcmMgPSB1cmw7XG4gICAgICB9KTtcbiAgICB9LFxuICAgIGRlc3Ryb3llZCgpIHtcbiAgICAgIFVSTC5yZXZva2VPYmplY3RVUkwodGhpcy51cmwpO1xuICAgIH0sXG4gIH0sXG4gIEZvY3VzV3JhcDoge1xuICAgIG1vdW50ZWQoKSB7XG4gICAgICB0aGlzLmZvY3VzU3RhcnQgPSB0aGlzLmVsLmZpcnN0RWxlbWVudENoaWxkO1xuICAgICAgdGhpcy5mb2N1c0VuZCA9IHRoaXMuZWwubGFzdEVsZW1lbnRDaGlsZDtcbiAgICAgIHRoaXMuZm9jdXNTdGFydC5hZGRFdmVudExpc3RlbmVyKFwiZm9jdXNcIiwgKGUpID0+IHtcbiAgICAgICAgaWYgKCFlLnJlbGF0ZWRUYXJnZXQgfHwgIXRoaXMuZWwuY29udGFpbnMoZS5yZWxhdGVkVGFyZ2V0KSkge1xuICAgICAgICAgIC8vIEhhbmRsZSBmb2N1cyBlbnRlcmluZyBmcm9tIG91dHNpZGUgKGUuZy4gVGFiIHdoZW4gYm9keSBpcyBmb2N1c2VkKVxuICAgICAgICAgIC8vIGh0dHBzOi8vZ2l0aHViLmNvbS9waG9lbml4ZnJhbWV3b3JrL3Bob2VuaXhfbGl2ZV92aWV3L2lzc3Vlcy8zNjM2XG4gICAgICAgICAgY29uc3QgbmV4dEZvY3VzID0gZS50YXJnZXQubmV4dEVsZW1lbnRTaWJsaW5nO1xuICAgICAgICAgIEFSSUEuYXR0ZW1wdEZvY3VzKG5leHRGb2N1cykgfHwgQVJJQS5mb2N1c0ZpcnN0KG5leHRGb2N1cyk7XG4gICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgQVJJQS5mb2N1c0xhc3QodGhpcy5lbCk7XG4gICAgICAgIH1cbiAgICAgIH0pO1xuICAgICAgdGhpcy5mb2N1c0VuZC5hZGRFdmVudExpc3RlbmVyKFwiZm9jdXNcIiwgKGUpID0+IHtcbiAgICAgICAgaWYgKCFlLnJlbGF0ZWRUYXJnZXQgfHwgIXRoaXMuZWwuY29udGFpbnMoZS5yZWxhdGVkVGFyZ2V0KSkge1xuICAgICAgICAgIC8vIEhhbmRsZSBmb2N1cyBlbnRlcmluZyBmcm9tIG91dHNpZGUgKGUuZy4gU2hpZnQrVGFiIHdoZW4gYm9keSBpcyBmb2N1c2VkKVxuICAgICAgICAgIC8vIGh0dHBzOi8vZ2l0aHViLmNvbS9waG9lbml4ZnJhbWV3b3JrL3Bob2VuaXhfbGl2ZV92aWV3L2lzc3Vlcy8zNjM2XG4gICAgICAgICAgY29uc3QgbmV4dEZvY3VzID0gZS50YXJnZXQucHJldmlvdXNFbGVtZW50U2libGluZztcbiAgICAgICAgICBBUklBLmF0dGVtcHRGb2N1cyhuZXh0Rm9jdXMpIHx8IEFSSUEuZm9jdXNMYXN0KG5leHRGb2N1cyk7XG4gICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgQVJJQS5mb2N1c0ZpcnN0KHRoaXMuZWwpO1xuICAgICAgICB9XG4gICAgICB9KTtcbiAgICAgIC8vIG9ubHkgdHJ5IHRvIGNoYW5nZSB0aGUgZm9jdXMgaWYgaXQgaXMgbm90IGFscmVhZHkgaW5zaWRlXG4gICAgICBpZiAoIXRoaXMuZWwuY29udGFpbnMoZG9jdW1lbnQuYWN0aXZlRWxlbWVudCkpIHtcbiAgICAgICAgdGhpcy5lbC5hZGRFdmVudExpc3RlbmVyKFwicGh4OnNob3ctZW5kXCIsICgpID0+IHRoaXMuZWwuZm9jdXMoKSk7XG4gICAgICAgIGlmICh3aW5kb3cuZ2V0Q29tcHV0ZWRTdHlsZSh0aGlzLmVsKS5kaXNwbGF5ICE9PSBcIm5vbmVcIikge1xuICAgICAgICAgIEFSSUEuZm9jdXNGaXJzdCh0aGlzLmVsKTtcbiAgICAgICAgfVxuICAgICAgfVxuICAgIH0sXG4gIH0sXG59O1xuXG5jb25zdCBmaW5kU2Nyb2xsQ29udGFpbmVyID0gKGVsKSA9PiB7XG4gIC8vIHRoZSBzY3JvbGwgZXZlbnQgd29uJ3QgYmUgZmlyZWQgb24gdGhlIGh0bWwvYm9keSBlbGVtZW50IGV2ZW4gaWYgb3ZlcmZsb3cgaXMgc2V0XG4gIC8vIHRoZXJlZm9yZSB3ZSByZXR1cm4gbnVsbCB0byBpbnN0ZWFkIGxpc3RlbiBmb3Igc2Nyb2xsIGV2ZW50cyBvbiBkb2N1bWVudFxuICBpZiAoW1wiSFRNTFwiLCBcIkJPRFlcIl0uaW5kZXhPZihlbC5ub2RlTmFtZS50b1VwcGVyQ2FzZSgpKSA+PSAwKSByZXR1cm4gbnVsbDtcbiAgaWYgKFtcInNjcm9sbFwiLCBcImF1dG9cIl0uaW5kZXhPZihnZXRDb21wdXRlZFN0eWxlKGVsKS5vdmVyZmxvd1kpID49IDApXG4gICAgcmV0dXJuIGVsO1xuICByZXR1cm4gZmluZFNjcm9sbENvbnRhaW5lcihlbC5wYXJlbnRFbGVtZW50KTtcbn07XG5cbmNvbnN0IHNjcm9sbFRvcCA9IChzY3JvbGxDb250YWluZXIpID0+IHtcbiAgaWYgKHNjcm9sbENvbnRhaW5lcikge1xuICAgIHJldHVybiBzY3JvbGxDb250YWluZXIuc2Nyb2xsVG9wO1xuICB9IGVsc2Uge1xuICAgIHJldHVybiBkb2N1bWVudC5kb2N1bWVudEVsZW1lbnQuc2Nyb2xsVG9wIHx8IGRvY3VtZW50LmJvZHkuc2Nyb2xsVG9wO1xuICB9XG59O1xuXG5jb25zdCBib3R0b20gPSAoc2Nyb2xsQ29udGFpbmVyKSA9PiB7XG4gIGlmIChzY3JvbGxDb250YWluZXIpIHtcbiAgICByZXR1cm4gc2Nyb2xsQ29udGFpbmVyLmdldEJvdW5kaW5nQ2xpZW50UmVjdCgpLmJvdHRvbTtcbiAgfSBlbHNlIHtcbiAgICAvLyB3aGVuIHdlIGhhdmUgbm8gY29udGFpbmVyLCB0aGUgd2hvbGUgcGFnZSBzY3JvbGxzLFxuICAgIC8vIHRoZXJlZm9yZSB0aGUgYm90dG9tIGNvb3JkaW5hdGUgaXMgdGhlIHZpZXdwb3J0IGhlaWdodFxuICAgIHJldHVybiB3aW5kb3cuaW5uZXJIZWlnaHQgfHwgZG9jdW1lbnQuZG9jdW1lbnRFbGVtZW50LmNsaWVudEhlaWdodDtcbiAgfVxufTtcblxuY29uc3QgdG9wID0gKHNjcm9sbENvbnRhaW5lcikgPT4ge1xuICBpZiAoc2Nyb2xsQ29udGFpbmVyKSB7XG4gICAgcmV0dXJuIHNjcm9sbENvbnRhaW5lci5nZXRCb3VuZGluZ0NsaWVudFJlY3QoKS50b3A7XG4gIH0gZWxzZSB7XG4gICAgLy8gd2hlbiB3ZSBoYXZlIG5vIGNvbnRhaW5lciB0aGUgd2hvbGUgcGFnZSBzY3JvbGxzLFxuICAgIC8vIHRoZXJlZm9yZSB0aGUgdG9wIGNvb3JkaW5hdGUgaXMgMFxuICAgIHJldHVybiAwO1xuICB9XG59O1xuXG5jb25zdCBpc0F0Vmlld3BvcnRUb3AgPSAoZWwsIHNjcm9sbENvbnRhaW5lcikgPT4ge1xuICBjb25zdCByZWN0ID0gZWwuZ2V0Qm91bmRpbmdDbGllbnRSZWN0KCk7XG4gIHJldHVybiAoXG4gICAgTWF0aC5jZWlsKHJlY3QudG9wKSA+PSB0b3Aoc2Nyb2xsQ29udGFpbmVyKSAmJlxuICAgIE1hdGguY2VpbChyZWN0LmxlZnQpID49IDAgJiZcbiAgICBNYXRoLmZsb29yKHJlY3QudG9wKSA8PSBib3R0b20oc2Nyb2xsQ29udGFpbmVyKVxuICApO1xufTtcblxuY29uc3QgaXNBdFZpZXdwb3J0Qm90dG9tID0gKGVsLCBzY3JvbGxDb250YWluZXIpID0+IHtcbiAgY29uc3QgcmVjdCA9IGVsLmdldEJvdW5kaW5nQ2xpZW50UmVjdCgpO1xuICByZXR1cm4gKFxuICAgIE1hdGguY2VpbChyZWN0LmJvdHRvbSkgPj0gdG9wKHNjcm9sbENvbnRhaW5lcikgJiZcbiAgICBNYXRoLmNlaWwocmVjdC5sZWZ0KSA+PSAwICYmXG4gICAgTWF0aC5mbG9vcihyZWN0LmJvdHRvbSkgPD0gYm90dG9tKHNjcm9sbENvbnRhaW5lcilcbiAgKTtcbn07XG5cbmNvbnN0IGlzV2l0aGluVmlld3BvcnQgPSAoZWwsIHNjcm9sbENvbnRhaW5lcikgPT4ge1xuICBjb25zdCByZWN0ID0gZWwuZ2V0Qm91bmRpbmdDbGllbnRSZWN0KCk7XG4gIHJldHVybiAoXG4gICAgTWF0aC5jZWlsKHJlY3QudG9wKSA+PSB0b3Aoc2Nyb2xsQ29udGFpbmVyKSAmJlxuICAgIE1hdGguY2VpbChyZWN0LmxlZnQpID49IDAgJiZcbiAgICBNYXRoLmZsb29yKHJlY3QudG9wKSA8PSBib3R0b20oc2Nyb2xsQ29udGFpbmVyKVxuICApO1xufTtcblxuSG9va3MuSW5maW5pdGVTY3JvbGwgPSB7XG4gIG1vdW50ZWQoKSB7XG4gICAgdGhpcy5zY3JvbGxDb250YWluZXIgPSBmaW5kU2Nyb2xsQ29udGFpbmVyKHRoaXMuZWwpO1xuICAgIGxldCBzY3JvbGxCZWZvcmUgPSBzY3JvbGxUb3AodGhpcy5zY3JvbGxDb250YWluZXIpO1xuICAgIGxldCB0b3BPdmVycmFuID0gZmFsc2U7XG4gICAgY29uc3QgdGhyb3R0bGVJbnRlcnZhbCA9IDUwMDtcbiAgICBsZXQgcGVuZGluZ09wID0gbnVsbDtcblxuICAgIGNvbnN0IG9uVG9wT3ZlcnJ1biA9IHRoaXMudGhyb3R0bGUoXG4gICAgICB0aHJvdHRsZUludGVydmFsLFxuICAgICAgKHRvcEV2ZW50LCBmaXJzdENoaWxkKSA9PiB7XG4gICAgICAgIHBlbmRpbmdPcCA9ICgpID0+IHRydWU7XG4gICAgICAgIHRoaXMubGl2ZVNvY2tldC5qcygpLnB1c2godGhpcy5lbCwgdG9wRXZlbnQsIHtcbiAgICAgICAgICB2YWx1ZTogeyBpZDogZmlyc3RDaGlsZC5pZCwgX292ZXJyYW46IHRydWUgfSxcbiAgICAgICAgICBjYWxsYmFjazogKCkgPT4ge1xuICAgICAgICAgICAgcGVuZGluZ09wID0gbnVsbDtcbiAgICAgICAgICB9LFxuICAgICAgICB9KTtcbiAgICAgIH0sXG4gICAgKTtcblxuICAgIGNvbnN0IG9uRmlyc3RDaGlsZEF0VG9wID0gdGhpcy50aHJvdHRsZShcbiAgICAgIHRocm90dGxlSW50ZXJ2YWwsXG4gICAgICAodG9wRXZlbnQsIGZpcnN0Q2hpbGQpID0+IHtcbiAgICAgICAgcGVuZGluZ09wID0gKCkgPT4gZmlyc3RDaGlsZC5zY3JvbGxJbnRvVmlldyh7IGJsb2NrOiBcInN0YXJ0XCIgfSk7XG4gICAgICAgIHRoaXMubGl2ZVNvY2tldC5qcygpLnB1c2godGhpcy5lbCwgdG9wRXZlbnQsIHtcbiAgICAgICAgICB2YWx1ZTogeyBpZDogZmlyc3RDaGlsZC5pZCB9LFxuICAgICAgICAgIGNhbGxiYWNrOiAoKSA9PiB7XG4gICAgICAgICAgICBwZW5kaW5nT3AgPSBudWxsO1xuICAgICAgICAgICAgLy8gbWFrZSBzdXJlIHRoYXQgdGhlIERPTSBpcyBwYXRjaGVkIGJ5IHdhaXRpbmcgZm9yIHRoZSBuZXh0IHRpY2tcbiAgICAgICAgICAgIHdpbmRvdy5yZXF1ZXN0QW5pbWF0aW9uRnJhbWUoKCkgPT4ge1xuICAgICAgICAgICAgICBpZiAoIWlzV2l0aGluVmlld3BvcnQoZmlyc3RDaGlsZCwgdGhpcy5zY3JvbGxDb250YWluZXIpKSB7XG4gICAgICAgICAgICAgICAgZmlyc3RDaGlsZC5zY3JvbGxJbnRvVmlldyh7IGJsb2NrOiBcInN0YXJ0XCIgfSk7XG4gICAgICAgICAgICAgIH1cbiAgICAgICAgICAgIH0pO1xuICAgICAgICAgIH0sXG4gICAgICAgIH0pO1xuICAgICAgfSxcbiAgICApO1xuXG4gICAgY29uc3Qgb25MYXN0Q2hpbGRBdEJvdHRvbSA9IHRoaXMudGhyb3R0bGUoXG4gICAgICB0aHJvdHRsZUludGVydmFsLFxuICAgICAgKGJvdHRvbUV2ZW50LCBsYXN0Q2hpbGQpID0+IHtcbiAgICAgICAgcGVuZGluZ09wID0gKCkgPT4gbGFzdENoaWxkLnNjcm9sbEludG9WaWV3KHsgYmxvY2s6IFwiZW5kXCIgfSk7XG4gICAgICAgIHRoaXMubGl2ZVNvY2tldC5qcygpLnB1c2godGhpcy5lbCwgYm90dG9tRXZlbnQsIHtcbiAgICAgICAgICB2YWx1ZTogeyBpZDogbGFzdENoaWxkLmlkIH0sXG4gICAgICAgICAgY2FsbGJhY2s6ICgpID0+IHtcbiAgICAgICAgICAgIHBlbmRpbmdPcCA9IG51bGw7XG4gICAgICAgICAgICAvLyBtYWtlIHN1cmUgdGhhdCB0aGUgRE9NIGlzIHBhdGNoZWQgYnkgd2FpdGluZyBmb3IgdGhlIG5leHQgdGlja1xuICAgICAgICAgICAgd2luZG93LnJlcXVlc3RBbmltYXRpb25GcmFtZSgoKSA9PiB7XG4gICAgICAgICAgICAgIGlmICghaXNXaXRoaW5WaWV3cG9ydChsYXN0Q2hpbGQsIHRoaXMuc2Nyb2xsQ29udGFpbmVyKSkge1xuICAgICAgICAgICAgICAgIGxhc3RDaGlsZC5zY3JvbGxJbnRvVmlldyh7IGJsb2NrOiBcImVuZFwiIH0pO1xuICAgICAgICAgICAgICB9XG4gICAgICAgICAgICB9KTtcbiAgICAgICAgICB9LFxuICAgICAgICB9KTtcbiAgICAgIH0sXG4gICAgKTtcblxuICAgIHRoaXMub25TY3JvbGwgPSAoX2UpID0+IHtcbiAgICAgIGNvbnN0IHNjcm9sbE5vdyA9IHNjcm9sbFRvcCh0aGlzLnNjcm9sbENvbnRhaW5lcik7XG5cbiAgICAgIGlmIChwZW5kaW5nT3ApIHtcbiAgICAgICAgc2Nyb2xsQmVmb3JlID0gc2Nyb2xsTm93O1xuICAgICAgICByZXR1cm4gcGVuZGluZ09wKCk7XG4gICAgICB9XG4gICAgICBjb25zdCByZWN0ID0gdGhpcy5lbC5nZXRCb3VuZGluZ0NsaWVudFJlY3QoKTtcbiAgICAgIGNvbnN0IHRvcEV2ZW50ID0gdGhpcy5lbC5nZXRBdHRyaWJ1dGUoXG4gICAgICAgIHRoaXMubGl2ZVNvY2tldC5iaW5kaW5nKFwidmlld3BvcnQtdG9wXCIpLFxuICAgICAgKTtcbiAgICAgIGNvbnN0IGJvdHRvbUV2ZW50ID0gdGhpcy5lbC5nZXRBdHRyaWJ1dGUoXG4gICAgICAgIHRoaXMubGl2ZVNvY2tldC5iaW5kaW5nKFwidmlld3BvcnQtYm90dG9tXCIpLFxuICAgICAgKTtcbiAgICAgIGNvbnN0IGxhc3RDaGlsZCA9IHRoaXMuZWwubGFzdEVsZW1lbnRDaGlsZDtcbiAgICAgIGNvbnN0IGZpcnN0Q2hpbGQgPSB0aGlzLmVsLmZpcnN0RWxlbWVudENoaWxkO1xuICAgICAgY29uc3QgaXNTY3JvbGxpbmdVcCA9IHNjcm9sbE5vdyA8IHNjcm9sbEJlZm9yZTtcbiAgICAgIGNvbnN0IGlzU2Nyb2xsaW5nRG93biA9IHNjcm9sbE5vdyA+IHNjcm9sbEJlZm9yZTtcblxuICAgICAgLy8gZWwgb3ZlcnJhbiB3aGlsZSBzY3JvbGxpbmcgdXBcbiAgICAgIGlmIChpc1Njcm9sbGluZ1VwICYmIHRvcEV2ZW50ICYmICF0b3BPdmVycmFuICYmIHJlY3QudG9wID49IDApIHtcbiAgICAgICAgdG9wT3ZlcnJhbiA9IHRydWU7XG4gICAgICAgIG9uVG9wT3ZlcnJ1bih0b3BFdmVudCwgZmlyc3RDaGlsZCk7XG4gICAgICB9IGVsc2UgaWYgKGlzU2Nyb2xsaW5nRG93biAmJiB0b3BPdmVycmFuICYmIHJlY3QudG9wIDw9IDApIHtcbiAgICAgICAgdG9wT3ZlcnJhbiA9IGZhbHNlO1xuICAgICAgfVxuXG4gICAgICBpZiAoXG4gICAgICAgIHRvcEV2ZW50ICYmXG4gICAgICAgIGlzU2Nyb2xsaW5nVXAgJiZcbiAgICAgICAgaXNBdFZpZXdwb3J0VG9wKGZpcnN0Q2hpbGQsIHRoaXMuc2Nyb2xsQ29udGFpbmVyKVxuICAgICAgKSB7XG4gICAgICAgIG9uRmlyc3RDaGlsZEF0VG9wKHRvcEV2ZW50LCBmaXJzdENoaWxkKTtcbiAgICAgIH0gZWxzZSBpZiAoXG4gICAgICAgIGJvdHRvbUV2ZW50ICYmXG4gICAgICAgIGlzU2Nyb2xsaW5nRG93biAmJlxuICAgICAgICBpc0F0Vmlld3BvcnRCb3R0b20obGFzdENoaWxkLCB0aGlzLnNjcm9sbENvbnRhaW5lcilcbiAgICAgICkge1xuICAgICAgICBvbkxhc3RDaGlsZEF0Qm90dG9tKGJvdHRvbUV2ZW50LCBsYXN0Q2hpbGQpO1xuICAgICAgfVxuICAgICAgc2Nyb2xsQmVmb3JlID0gc2Nyb2xsTm93O1xuICAgIH07XG5cbiAgICBpZiAodGhpcy5zY3JvbGxDb250YWluZXIpIHtcbiAgICAgIHRoaXMuc2Nyb2xsQ29udGFpbmVyLmFkZEV2ZW50TGlzdGVuZXIoXCJzY3JvbGxcIiwgdGhpcy5vblNjcm9sbCk7XG4gICAgfSBlbHNlIHtcbiAgICAgIHdpbmRvdy5hZGRFdmVudExpc3RlbmVyKFwic2Nyb2xsXCIsIHRoaXMub25TY3JvbGwpO1xuICAgIH1cbiAgfSxcblxuICBkZXN0cm95ZWQoKSB7XG4gICAgaWYgKHRoaXMuc2Nyb2xsQ29udGFpbmVyKSB7XG4gICAgICB0aGlzLnNjcm9sbENvbnRhaW5lci5yZW1vdmVFdmVudExpc3RlbmVyKFwic2Nyb2xsXCIsIHRoaXMub25TY3JvbGwpO1xuICAgIH0gZWxzZSB7XG4gICAgICB3aW5kb3cucmVtb3ZlRXZlbnRMaXN0ZW5lcihcInNjcm9sbFwiLCB0aGlzLm9uU2Nyb2xsKTtcbiAgICB9XG4gIH0sXG5cbiAgdGhyb3R0bGUoaW50ZXJ2YWwsIGNhbGxiYWNrKSB7XG4gICAgbGV0IGxhc3RDYWxsQXQgPSAwO1xuICAgIGxldCB0aW1lcjtcblxuICAgIHJldHVybiAoLi4uYXJncykgPT4ge1xuICAgICAgY29uc3Qgbm93ID0gRGF0ZS5ub3coKTtcbiAgICAgIGNvbnN0IHJlbWFpbmluZ1RpbWUgPSBpbnRlcnZhbCAtIChub3cgLSBsYXN0Q2FsbEF0KTtcblxuICAgICAgaWYgKHJlbWFpbmluZ1RpbWUgPD0gMCB8fCByZW1haW5pbmdUaW1lID4gaW50ZXJ2YWwpIHtcbiAgICAgICAgaWYgKHRpbWVyKSB7XG4gICAgICAgICAgY2xlYXJUaW1lb3V0KHRpbWVyKTtcbiAgICAgICAgICB0aW1lciA9IG51bGw7XG4gICAgICAgIH1cbiAgICAgICAgbGFzdENhbGxBdCA9IG5vdztcbiAgICAgICAgY2FsbGJhY2soLi4uYXJncyk7XG4gICAgICB9IGVsc2UgaWYgKCF0aW1lcikge1xuICAgICAgICB0aW1lciA9IHNldFRpbWVvdXQoKCkgPT4ge1xuICAgICAgICAgIGxhc3RDYWxsQXQgPSBEYXRlLm5vdygpO1xuICAgICAgICAgIHRpbWVyID0gbnVsbDtcbiAgICAgICAgICBjYWxsYmFjayguLi5hcmdzKTtcbiAgICAgICAgfSwgcmVtYWluaW5nVGltZSk7XG4gICAgICB9XG4gICAgfTtcbiAgfSxcbn07XG5leHBvcnQgZGVmYXVsdCBIb29rcztcbiIsICJpbXBvcnQge1xuICBQSFhfUkVGX0xPQURJTkcsXG4gIFBIWF9SRUZfTE9DSyxcbiAgUEhYX1JFRl9TUkMsXG4gIFBIWF9QRU5ESU5HX1JFRlMsXG4gIFBIWF9FVkVOVF9DTEFTU0VTLFxuICBQSFhfRElTQUJMRUQsXG4gIFBIWF9SRUFET05MWSxcbiAgUEhYX0RJU0FCTEVfV0lUSF9SRVNUT1JFLFxufSBmcm9tIFwiLi9jb25zdGFudHNcIjtcblxuaW1wb3J0IERPTSBmcm9tIFwiLi9kb21cIjtcblxuZXhwb3J0IGRlZmF1bHQgY2xhc3MgRWxlbWVudFJlZiB7XG4gIHN0YXRpYyBvblVubG9jayhlbCwgY2FsbGJhY2spIHtcbiAgICBpZiAoIURPTS5pc0xvY2tlZChlbCkgJiYgIWVsLmNsb3Nlc3QoYFske1BIWF9SRUZfTE9DS31dYCkpIHtcbiAgICAgIHJldHVybiBjYWxsYmFjaygpO1xuICAgIH1cbiAgICBjb25zdCBjbG9zZXN0TG9jayA9IGVsLmNsb3Nlc3QoYFske1BIWF9SRUZfTE9DS31dYCk7XG4gICAgY29uc3QgcmVmID0gY2xvc2VzdExvY2tcbiAgICAgIC5jbG9zZXN0KGBbJHtQSFhfUkVGX0xPQ0t9XWApXG4gICAgICAuZ2V0QXR0cmlidXRlKFBIWF9SRUZfTE9DSyk7XG4gICAgY2xvc2VzdExvY2suYWRkRXZlbnRMaXN0ZW5lcihcbiAgICAgIGBwaHg6dW5kby1sb2NrOiR7cmVmfWAsXG4gICAgICAoKSA9PiB7XG4gICAgICAgIGNhbGxiYWNrKCk7XG4gICAgICB9LFxuICAgICAgeyBvbmNlOiB0cnVlIH0sXG4gICAgKTtcbiAgfVxuXG4gIGNvbnN0cnVjdG9yKGVsKSB7XG4gICAgdGhpcy5lbCA9IGVsO1xuICAgIHRoaXMubG9hZGluZ1JlZiA9IGVsLmhhc0F0dHJpYnV0ZShQSFhfUkVGX0xPQURJTkcpXG4gICAgICA/IHBhcnNlSW50KGVsLmdldEF0dHJpYnV0ZShQSFhfUkVGX0xPQURJTkcpLCAxMClcbiAgICAgIDogbnVsbDtcbiAgICB0aGlzLmxvY2tSZWYgPSBlbC5oYXNBdHRyaWJ1dGUoUEhYX1JFRl9MT0NLKVxuICAgICAgPyBwYXJzZUludChlbC5nZXRBdHRyaWJ1dGUoUEhYX1JFRl9MT0NLKSwgMTApXG4gICAgICA6IG51bGw7XG4gIH1cblxuICAvLyBwdWJsaWNcblxuICBtYXliZVVuZG8ocmVmLCBwaHhFdmVudCwgZWFjaENsb25lQ2FsbGJhY2spIHtcbiAgICBpZiAoIXRoaXMuaXNXaXRoaW4ocmVmKSkge1xuICAgICAgLy8gd2UgY2Fubm90IHVuZG8gdGhlIGxvY2sgLyBsb2FkaW5nIG5vdywgYXMgdGhlcmUgaXMgYSBuZXdlciBvbmUgYWxyZWFkeSBzZXQ7XG4gICAgICAvLyB3ZSBuZWVkIHRvIHN0b3JlIHRoZSBvcmlnaW5hbCByZWYgd2UgdHJpZWQgdG8gc2VuZCB0aGUgdW5kbyBldmVudCBsYXRlclxuICAgICAgRE9NLnVwZGF0ZVByaXZhdGUodGhpcy5lbCwgUEhYX1BFTkRJTkdfUkVGUywgW10sIChwZW5kaW5nUmVmcykgPT4ge1xuICAgICAgICBwZW5kaW5nUmVmcy5wdXNoKHJlZik7XG4gICAgICAgIHJldHVybiBwZW5kaW5nUmVmcztcbiAgICAgIH0pO1xuICAgICAgcmV0dXJuO1xuICAgIH1cblxuICAgIC8vIHVuZG8gbG9ja3MgYW5kIGFwcGx5IGNsb25lc1xuICAgIHRoaXMudW5kb0xvY2tzKHJlZiwgcGh4RXZlbnQsIGVhY2hDbG9uZUNhbGxiYWNrKTtcblxuICAgIC8vIHVuZG8gbG9hZGluZyBzdGF0ZXNcbiAgICB0aGlzLnVuZG9Mb2FkaW5nKHJlZiwgcGh4RXZlbnQpO1xuXG4gICAgLy8gZW5zdXJlIHVuZG8gZXZlbnRzIGFyZSBmaXJlZCBmb3IgcGVuZGluZyByZWZzIHRoYXRcbiAgICAvLyBhcmUgcmVzb2x2ZWQgYnkgdGhlIGN1cnJlbnQgcmVmLCBvdGhlcndpc2Ugd2UnZCBsZWFrIGV2ZW50IGxpc3RlbmVyc1xuICAgIERPTS51cGRhdGVQcml2YXRlKHRoaXMuZWwsIFBIWF9QRU5ESU5HX1JFRlMsIFtdLCAocGVuZGluZ1JlZnMpID0+IHtcbiAgICAgIHJldHVybiBwZW5kaW5nUmVmcy5maWx0ZXIoKHBlbmRpbmdSZWYpID0+IHtcbiAgICAgICAgbGV0IG9wdHMgPSB7XG4gICAgICAgICAgZGV0YWlsOiB7IHJlZjogcGVuZGluZ1JlZiwgZXZlbnQ6IHBoeEV2ZW50IH0sXG4gICAgICAgICAgYnViYmxlczogdHJ1ZSxcbiAgICAgICAgICBjYW5jZWxhYmxlOiBmYWxzZSxcbiAgICAgICAgfTtcbiAgICAgICAgaWYgKHRoaXMubG9hZGluZ1JlZiAmJiB0aGlzLmxvYWRpbmdSZWYgPiBwZW5kaW5nUmVmKSB7XG4gICAgICAgICAgdGhpcy5lbC5kaXNwYXRjaEV2ZW50KFxuICAgICAgICAgICAgbmV3IEN1c3RvbUV2ZW50KGBwaHg6dW5kby1sb2FkaW5nOiR7cGVuZGluZ1JlZn1gLCBvcHRzKSxcbiAgICAgICAgICApO1xuICAgICAgICB9XG4gICAgICAgIGlmICh0aGlzLmxvY2tSZWYgJiYgdGhpcy5sb2NrUmVmID4gcGVuZGluZ1JlZikge1xuICAgICAgICAgIHRoaXMuZWwuZGlzcGF0Y2hFdmVudChcbiAgICAgICAgICAgIG5ldyBDdXN0b21FdmVudChgcGh4OnVuZG8tbG9jazoke3BlbmRpbmdSZWZ9YCwgb3B0cyksXG4gICAgICAgICAgKTtcbiAgICAgICAgfVxuICAgICAgICByZXR1cm4gcGVuZGluZ1JlZiA+IHJlZjtcbiAgICAgIH0pO1xuICAgIH0pO1xuXG4gICAgLy8gY2xlYW4gdXAgaWYgZnVsbHkgcmVzb2x2ZWRcbiAgICBpZiAodGhpcy5pc0Z1bGx5UmVzb2x2ZWRCeShyZWYpKSB7XG4gICAgICB0aGlzLmVsLnJlbW92ZUF0dHJpYnV0ZShQSFhfUkVGX1NSQyk7XG4gICAgfVxuICB9XG5cbiAgLy8gcHJpdmF0ZVxuXG4gIGlzV2l0aGluKHJlZikge1xuICAgIHJldHVybiAhKFxuICAgICAgdGhpcy5sb2FkaW5nUmVmICE9PSBudWxsICYmXG4gICAgICB0aGlzLmxvYWRpbmdSZWYgPiByZWYgJiZcbiAgICAgIHRoaXMubG9ja1JlZiAhPT0gbnVsbCAmJlxuICAgICAgdGhpcy5sb2NrUmVmID4gcmVmXG4gICAgKTtcbiAgfVxuXG4gIC8vIENoZWNrIGZvciBjbG9uZWQgUEhYX1JFRl9MT0NLIGVsZW1lbnQgdGhhdCBoYXMgYmVlbiBtb3JwaGVkIGJlaGluZFxuICAvLyB0aGUgc2NlbmVzIHdoaWxlIHRoaXMgZWxlbWVudCB3YXMgbG9ja2VkIGluIHRoZSBET00uXG4gIC8vIFdoZW4gd2UgYXBwbHkgdGhlIGNsb25lZCB0cmVlIHRvIHRoZSBhY3RpdmUgRE9NIGVsZW1lbnQsIHdlIG11c3RcbiAgLy9cbiAgLy8gICAxLiBleGVjdXRlIHBlbmRpbmcgbW91bnRlZCBob29rcyBmb3Igbm9kZXMgbm93IGluIHRoZSBET01cbiAgLy8gICAyLiB1bmRvIGFueSByZWYgaW5zaWRlIHRoZSBjbG9uZWQgdHJlZSB0aGF0IGhhcyBzaW5jZSBiZWVuIGFjaydkXG4gIHVuZG9Mb2NrcyhyZWYsIHBoeEV2ZW50LCBlYWNoQ2xvbmVDYWxsYmFjaykge1xuICAgIGlmICghdGhpcy5pc0xvY2tVbmRvbmVCeShyZWYpKSB7XG4gICAgICByZXR1cm47XG4gICAgfVxuXG4gICAgY29uc3QgY2xvbmVkVHJlZSA9IERPTS5wcml2YXRlKHRoaXMuZWwsIFBIWF9SRUZfTE9DSyk7XG4gICAgaWYgKGNsb25lZFRyZWUpIHtcbiAgICAgIGVhY2hDbG9uZUNhbGxiYWNrKGNsb25lZFRyZWUpO1xuICAgICAgRE9NLmRlbGV0ZVByaXZhdGUodGhpcy5lbCwgUEhYX1JFRl9MT0NLKTtcbiAgICB9XG4gICAgdGhpcy5lbC5yZW1vdmVBdHRyaWJ1dGUoUEhYX1JFRl9MT0NLKTtcblxuICAgIGNvbnN0IG9wdHMgPSB7XG4gICAgICBkZXRhaWw6IHsgcmVmOiByZWYsIGV2ZW50OiBwaHhFdmVudCB9LFxuICAgICAgYnViYmxlczogdHJ1ZSxcbiAgICAgIGNhbmNlbGFibGU6IGZhbHNlLFxuICAgIH07XG4gICAgdGhpcy5lbC5kaXNwYXRjaEV2ZW50KFxuICAgICAgbmV3IEN1c3RvbUV2ZW50KGBwaHg6dW5kby1sb2NrOiR7dGhpcy5sb2NrUmVmfWAsIG9wdHMpLFxuICAgICk7XG4gIH1cblxuICB1bmRvTG9hZGluZyhyZWYsIHBoeEV2ZW50KSB7XG4gICAgaWYgKCF0aGlzLmlzTG9hZGluZ1VuZG9uZUJ5KHJlZikpIHtcbiAgICAgIGlmIChcbiAgICAgICAgdGhpcy5jYW5VbmRvTG9hZGluZyhyZWYpICYmXG4gICAgICAgIHRoaXMuZWwuY2xhc3NMaXN0LmNvbnRhaW5zKFwicGh4LXN1Ym1pdC1sb2FkaW5nXCIpXG4gICAgICApIHtcbiAgICAgICAgdGhpcy5lbC5jbGFzc0xpc3QucmVtb3ZlKFwicGh4LWNoYW5nZS1sb2FkaW5nXCIpO1xuICAgICAgfVxuICAgICAgcmV0dXJuO1xuICAgIH1cblxuICAgIGlmICh0aGlzLmNhblVuZG9Mb2FkaW5nKHJlZikpIHtcbiAgICAgIHRoaXMuZWwucmVtb3ZlQXR0cmlidXRlKFBIWF9SRUZfTE9BRElORyk7XG4gICAgICBjb25zdCBkaXNhYmxlZFZhbCA9IHRoaXMuZWwuZ2V0QXR0cmlidXRlKFBIWF9ESVNBQkxFRCk7XG4gICAgICBjb25zdCByZWFkT25seVZhbCA9IHRoaXMuZWwuZ2V0QXR0cmlidXRlKFBIWF9SRUFET05MWSk7XG4gICAgICAvLyByZXN0b3JlIGlucHV0c1xuICAgICAgaWYgKHJlYWRPbmx5VmFsICE9PSBudWxsKSB7XG4gICAgICAgIHRoaXMuZWwucmVhZE9ubHkgPSByZWFkT25seVZhbCA9PT0gXCJ0cnVlXCIgPyB0cnVlIDogZmFsc2U7XG4gICAgICAgIHRoaXMuZWwucmVtb3ZlQXR0cmlidXRlKFBIWF9SRUFET05MWSk7XG4gICAgICB9XG4gICAgICBpZiAoZGlzYWJsZWRWYWwgIT09IG51bGwpIHtcbiAgICAgICAgdGhpcy5lbC5kaXNhYmxlZCA9IGRpc2FibGVkVmFsID09PSBcInRydWVcIiA/IHRydWUgOiBmYWxzZTtcbiAgICAgICAgdGhpcy5lbC5yZW1vdmVBdHRyaWJ1dGUoUEhYX0RJU0FCTEVEKTtcbiAgICAgIH1cbiAgICAgIC8vIHJlc3RvcmUgZGlzYWJsZXNcbiAgICAgIGNvbnN0IGRpc2FibGVSZXN0b3JlID0gdGhpcy5lbC5nZXRBdHRyaWJ1dGUoUEhYX0RJU0FCTEVfV0lUSF9SRVNUT1JFKTtcbiAgICAgIGlmIChkaXNhYmxlUmVzdG9yZSAhPT0gbnVsbCkge1xuICAgICAgICB0aGlzLmVsLmlubmVyVGV4dCA9IGRpc2FibGVSZXN0b3JlO1xuICAgICAgICB0aGlzLmVsLnJlbW92ZUF0dHJpYnV0ZShQSFhfRElTQUJMRV9XSVRIX1JFU1RPUkUpO1xuICAgICAgfVxuXG4gICAgICBjb25zdCBvcHRzID0ge1xuICAgICAgICBkZXRhaWw6IHsgcmVmOiByZWYsIGV2ZW50OiBwaHhFdmVudCB9LFxuICAgICAgICBidWJibGVzOiB0cnVlLFxuICAgICAgICBjYW5jZWxhYmxlOiBmYWxzZSxcbiAgICAgIH07XG4gICAgICB0aGlzLmVsLmRpc3BhdGNoRXZlbnQoXG4gICAgICAgIG5ldyBDdXN0b21FdmVudChgcGh4OnVuZG8tbG9hZGluZzoke3RoaXMubG9hZGluZ1JlZn1gLCBvcHRzKSxcbiAgICAgICk7XG4gICAgfVxuXG4gICAgLy8gcmVtb3ZlIGNsYXNzZXNcbiAgICBQSFhfRVZFTlRfQ0xBU1NFUy5mb3JFYWNoKChuYW1lKSA9PiB7XG4gICAgICBpZiAobmFtZSAhPT0gXCJwaHgtc3VibWl0LWxvYWRpbmdcIiB8fCB0aGlzLmNhblVuZG9Mb2FkaW5nKHJlZikpIHtcbiAgICAgICAgRE9NLnJlbW92ZUNsYXNzKHRoaXMuZWwsIG5hbWUpO1xuICAgICAgfVxuICAgIH0pO1xuICB9XG5cbiAgaXNMb2FkaW5nVW5kb25lQnkocmVmKSB7XG4gICAgcmV0dXJuIHRoaXMubG9hZGluZ1JlZiA9PT0gbnVsbCA/IGZhbHNlIDogdGhpcy5sb2FkaW5nUmVmIDw9IHJlZjtcbiAgfVxuICBpc0xvY2tVbmRvbmVCeShyZWYpIHtcbiAgICByZXR1cm4gdGhpcy5sb2NrUmVmID09PSBudWxsID8gZmFsc2UgOiB0aGlzLmxvY2tSZWYgPD0gcmVmO1xuICB9XG5cbiAgaXNGdWxseVJlc29sdmVkQnkocmVmKSB7XG4gICAgcmV0dXJuIChcbiAgICAgICh0aGlzLmxvYWRpbmdSZWYgPT09IG51bGwgfHwgdGhpcy5sb2FkaW5nUmVmIDw9IHJlZikgJiZcbiAgICAgICh0aGlzLmxvY2tSZWYgPT09IG51bGwgfHwgdGhpcy5sb2NrUmVmIDw9IHJlZilcbiAgICApO1xuICB9XG5cbiAgLy8gb25seSByZW1vdmUgdGhlIHBoeC1zdWJtaXQtbG9hZGluZyBjbGFzcyBpZiB3ZSBhcmUgbm90IGxvY2tlZFxuICBjYW5VbmRvTG9hZGluZyhyZWYpIHtcbiAgICByZXR1cm4gdGhpcy5sb2NrUmVmID09PSBudWxsIHx8IHRoaXMubG9ja1JlZiA8PSByZWY7XG4gIH1cbn1cbiIsICJpbXBvcnQgeyBtYXliZSB9IGZyb20gXCIuL3V0aWxzXCI7XG5cbmltcG9ydCBET00gZnJvbSBcIi4vZG9tXCI7XG5cbmV4cG9ydCBkZWZhdWx0IGNsYXNzIERPTVBvc3RNb3JwaFJlc3RvcmVyIHtcbiAgY29uc3RydWN0b3IoY29udGFpbmVyQmVmb3JlLCBjb250YWluZXJBZnRlciwgdXBkYXRlVHlwZSkge1xuICAgIGNvbnN0IGlkc0JlZm9yZSA9IG5ldyBTZXQoKTtcbiAgICBjb25zdCBpZHNBZnRlciA9IG5ldyBTZXQoXG4gICAgICBbLi4uY29udGFpbmVyQWZ0ZXIuY2hpbGRyZW5dLm1hcCgoY2hpbGQpID0+IGNoaWxkLmlkKSxcbiAgICApO1xuXG4gICAgY29uc3QgZWxlbWVudHNUb01vZGlmeSA9IFtdO1xuXG4gICAgQXJyYXkuZnJvbShjb250YWluZXJCZWZvcmUuY2hpbGRyZW4pLmZvckVhY2goKGNoaWxkKSA9PiB7XG4gICAgICBpZiAoY2hpbGQuaWQpIHtcbiAgICAgICAgLy8gYWxsIG9mIG91ciBjaGlsZHJlbiBzaG91bGQgYmUgZWxlbWVudHMgd2l0aCBpZHNcbiAgICAgICAgaWRzQmVmb3JlLmFkZChjaGlsZC5pZCk7XG4gICAgICAgIGlmIChpZHNBZnRlci5oYXMoY2hpbGQuaWQpKSB7XG4gICAgICAgICAgY29uc3QgcHJldmlvdXNFbGVtZW50SWQgPVxuICAgICAgICAgICAgY2hpbGQucHJldmlvdXNFbGVtZW50U2libGluZyAmJiBjaGlsZC5wcmV2aW91c0VsZW1lbnRTaWJsaW5nLmlkO1xuICAgICAgICAgIGVsZW1lbnRzVG9Nb2RpZnkucHVzaCh7XG4gICAgICAgICAgICBlbGVtZW50SWQ6IGNoaWxkLmlkLFxuICAgICAgICAgICAgcHJldmlvdXNFbGVtZW50SWQ6IHByZXZpb3VzRWxlbWVudElkLFxuICAgICAgICAgIH0pO1xuICAgICAgICB9XG4gICAgICB9XG4gICAgfSk7XG5cbiAgICB0aGlzLmNvbnRhaW5lcklkID0gY29udGFpbmVyQWZ0ZXIuaWQ7XG4gICAgdGhpcy51cGRhdGVUeXBlID0gdXBkYXRlVHlwZTtcbiAgICB0aGlzLmVsZW1lbnRzVG9Nb2RpZnkgPSBlbGVtZW50c1RvTW9kaWZ5O1xuICAgIHRoaXMuZWxlbWVudElkc1RvQWRkID0gWy4uLmlkc0FmdGVyXS5maWx0ZXIoKGlkKSA9PiAhaWRzQmVmb3JlLmhhcyhpZCkpO1xuICB9XG5cbiAgLy8gV2UgZG8gdGhlIGZvbGxvd2luZyB0byBvcHRpbWl6ZSBhcHBlbmQvcHJlcGVuZCBvcGVyYXRpb25zOlxuICAvLyAgIDEpIFRyYWNrIGlkcyBvZiBtb2RpZmllZCBlbGVtZW50cyAmIG9mIG5ldyBlbGVtZW50c1xuICAvLyAgIDIpIEFsbCB0aGUgbW9kaWZpZWQgZWxlbWVudHMgYXJlIHB1dCBiYWNrIGluIHRoZSBjb3JyZWN0IHBvc2l0aW9uIGluIHRoZSBET00gdHJlZVxuICAvLyAgICAgIGJ5IHN0b3JpbmcgdGhlIGlkIG9mIHRoZWlyIHByZXZpb3VzIHNpYmxpbmdcbiAgLy8gICAzKSBOZXcgZWxlbWVudHMgYXJlIGdvaW5nIHRvIGJlIHB1dCBpbiB0aGUgcmlnaHQgcGxhY2UgYnkgbW9ycGhkb20gZHVyaW5nIGFwcGVuZC5cbiAgLy8gICAgICBGb3IgcHJlcGVuZCwgd2UgbW92ZSB0aGVtIHRvIHRoZSBmaXJzdCBwb3NpdGlvbiBpbiB0aGUgY29udGFpbmVyXG4gIHBlcmZvcm0oKSB7XG4gICAgY29uc3QgY29udGFpbmVyID0gRE9NLmJ5SWQodGhpcy5jb250YWluZXJJZCk7XG4gICAgaWYgKCFjb250YWluZXIpIHtcbiAgICAgIHJldHVybjtcbiAgICB9XG4gICAgdGhpcy5lbGVtZW50c1RvTW9kaWZ5LmZvckVhY2goKGVsZW1lbnRUb01vZGlmeSkgPT4ge1xuICAgICAgaWYgKGVsZW1lbnRUb01vZGlmeS5wcmV2aW91c0VsZW1lbnRJZCkge1xuICAgICAgICBtYXliZShcbiAgICAgICAgICBkb2N1bWVudC5nZXRFbGVtZW50QnlJZChlbGVtZW50VG9Nb2RpZnkucHJldmlvdXNFbGVtZW50SWQpLFxuICAgICAgICAgIChwcmV2aW91c0VsZW0pID0+IHtcbiAgICAgICAgICAgIG1heWJlKFxuICAgICAgICAgICAgICBkb2N1bWVudC5nZXRFbGVtZW50QnlJZChlbGVtZW50VG9Nb2RpZnkuZWxlbWVudElkKSxcbiAgICAgICAgICAgICAgKGVsZW0pID0+IHtcbiAgICAgICAgICAgICAgICBjb25zdCBpc0luUmlnaHRQbGFjZSA9XG4gICAgICAgICAgICAgICAgICBlbGVtLnByZXZpb3VzRWxlbWVudFNpYmxpbmcgJiZcbiAgICAgICAgICAgICAgICAgIGVsZW0ucHJldmlvdXNFbGVtZW50U2libGluZy5pZCA9PSBwcmV2aW91c0VsZW0uaWQ7XG4gICAgICAgICAgICAgICAgaWYgKCFpc0luUmlnaHRQbGFjZSkge1xuICAgICAgICAgICAgICAgICAgcHJldmlvdXNFbGVtLmluc2VydEFkamFjZW50RWxlbWVudChcImFmdGVyZW5kXCIsIGVsZW0pO1xuICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgfSxcbiAgICAgICAgICAgICk7XG4gICAgICAgICAgfSxcbiAgICAgICAgKTtcbiAgICAgIH0gZWxzZSB7XG4gICAgICAgIC8vIFRoaXMgaXMgdGhlIGZpcnN0IGVsZW1lbnQgaW4gdGhlIGNvbnRhaW5lclxuICAgICAgICBtYXliZShkb2N1bWVudC5nZXRFbGVtZW50QnlJZChlbGVtZW50VG9Nb2RpZnkuZWxlbWVudElkKSwgKGVsZW0pID0+IHtcbiAgICAgICAgICBjb25zdCBpc0luUmlnaHRQbGFjZSA9IGVsZW0ucHJldmlvdXNFbGVtZW50U2libGluZyA9PSBudWxsO1xuICAgICAgICAgIGlmICghaXNJblJpZ2h0UGxhY2UpIHtcbiAgICAgICAgICAgIGNvbnRhaW5lci5pbnNlcnRBZGphY2VudEVsZW1lbnQoXCJhZnRlcmJlZ2luXCIsIGVsZW0pO1xuICAgICAgICAgIH1cbiAgICAgICAgfSk7XG4gICAgICB9XG4gICAgfSk7XG5cbiAgICBpZiAodGhpcy51cGRhdGVUeXBlID09IFwicHJlcGVuZFwiKSB7XG4gICAgICB0aGlzLmVsZW1lbnRJZHNUb0FkZC5yZXZlcnNlKCkuZm9yRWFjaCgoZWxlbUlkKSA9PiB7XG4gICAgICAgIG1heWJlKGRvY3VtZW50LmdldEVsZW1lbnRCeUlkKGVsZW1JZCksIChlbGVtKSA9PlxuICAgICAgICAgIGNvbnRhaW5lci5pbnNlcnRBZGphY2VudEVsZW1lbnQoXCJhZnRlcmJlZ2luXCIsIGVsZW0pLFxuICAgICAgICApO1xuICAgICAgfSk7XG4gICAgfVxuICB9XG59XG4iLCAidmFyIERPQ1VNRU5UX0ZSQUdNRU5UX05PREUgPSAxMTtcblxuZnVuY3Rpb24gbW9ycGhBdHRycyhmcm9tTm9kZSwgdG9Ob2RlKSB7XG4gICAgdmFyIHRvTm9kZUF0dHJzID0gdG9Ob2RlLmF0dHJpYnV0ZXM7XG4gICAgdmFyIGF0dHI7XG4gICAgdmFyIGF0dHJOYW1lO1xuICAgIHZhciBhdHRyTmFtZXNwYWNlVVJJO1xuICAgIHZhciBhdHRyVmFsdWU7XG4gICAgdmFyIGZyb21WYWx1ZTtcblxuICAgIC8vIGRvY3VtZW50LWZyYWdtZW50cyBkb250IGhhdmUgYXR0cmlidXRlcyBzbyBsZXRzIG5vdCBkbyBhbnl0aGluZ1xuICAgIGlmICh0b05vZGUubm9kZVR5cGUgPT09IERPQ1VNRU5UX0ZSQUdNRU5UX05PREUgfHwgZnJvbU5vZGUubm9kZVR5cGUgPT09IERPQ1VNRU5UX0ZSQUdNRU5UX05PREUpIHtcbiAgICAgIHJldHVybjtcbiAgICB9XG5cbiAgICAvLyB1cGRhdGUgYXR0cmlidXRlcyBvbiBvcmlnaW5hbCBET00gZWxlbWVudFxuICAgIGZvciAodmFyIGkgPSB0b05vZGVBdHRycy5sZW5ndGggLSAxOyBpID49IDA7IGktLSkge1xuICAgICAgICBhdHRyID0gdG9Ob2RlQXR0cnNbaV07XG4gICAgICAgIGF0dHJOYW1lID0gYXR0ci5uYW1lO1xuICAgICAgICBhdHRyTmFtZXNwYWNlVVJJID0gYXR0ci5uYW1lc3BhY2VVUkk7XG4gICAgICAgIGF0dHJWYWx1ZSA9IGF0dHIudmFsdWU7XG5cbiAgICAgICAgaWYgKGF0dHJOYW1lc3BhY2VVUkkpIHtcbiAgICAgICAgICAgIGF0dHJOYW1lID0gYXR0ci5sb2NhbE5hbWUgfHwgYXR0ck5hbWU7XG4gICAgICAgICAgICBmcm9tVmFsdWUgPSBmcm9tTm9kZS5nZXRBdHRyaWJ1dGVOUyhhdHRyTmFtZXNwYWNlVVJJLCBhdHRyTmFtZSk7XG5cbiAgICAgICAgICAgIGlmIChmcm9tVmFsdWUgIT09IGF0dHJWYWx1ZSkge1xuICAgICAgICAgICAgICAgIGlmIChhdHRyLnByZWZpeCA9PT0gJ3htbG5zJyl7XG4gICAgICAgICAgICAgICAgICAgIGF0dHJOYW1lID0gYXR0ci5uYW1lOyAvLyBJdCdzIG5vdCBhbGxvd2VkIHRvIHNldCBhbiBhdHRyaWJ1dGUgd2l0aCB0aGUgWE1MTlMgbmFtZXNwYWNlIHdpdGhvdXQgc3BlY2lmeWluZyB0aGUgYHhtbG5zYCBwcmVmaXhcbiAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICAgICAgZnJvbU5vZGUuc2V0QXR0cmlidXRlTlMoYXR0ck5hbWVzcGFjZVVSSSwgYXR0ck5hbWUsIGF0dHJWYWx1ZSk7XG4gICAgICAgICAgICB9XG4gICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgICBmcm9tVmFsdWUgPSBmcm9tTm9kZS5nZXRBdHRyaWJ1dGUoYXR0ck5hbWUpO1xuXG4gICAgICAgICAgICBpZiAoZnJvbVZhbHVlICE9PSBhdHRyVmFsdWUpIHtcbiAgICAgICAgICAgICAgICBmcm9tTm9kZS5zZXRBdHRyaWJ1dGUoYXR0ck5hbWUsIGF0dHJWYWx1ZSk7XG4gICAgICAgICAgICB9XG4gICAgICAgIH1cbiAgICB9XG5cbiAgICAvLyBSZW1vdmUgYW55IGV4dHJhIGF0dHJpYnV0ZXMgZm91bmQgb24gdGhlIG9yaWdpbmFsIERPTSBlbGVtZW50IHRoYXRcbiAgICAvLyB3ZXJlbid0IGZvdW5kIG9uIHRoZSB0YXJnZXQgZWxlbWVudC5cbiAgICB2YXIgZnJvbU5vZGVBdHRycyA9IGZyb21Ob2RlLmF0dHJpYnV0ZXM7XG5cbiAgICBmb3IgKHZhciBkID0gZnJvbU5vZGVBdHRycy5sZW5ndGggLSAxOyBkID49IDA7IGQtLSkge1xuICAgICAgICBhdHRyID0gZnJvbU5vZGVBdHRyc1tkXTtcbiAgICAgICAgYXR0ck5hbWUgPSBhdHRyLm5hbWU7XG4gICAgICAgIGF0dHJOYW1lc3BhY2VVUkkgPSBhdHRyLm5hbWVzcGFjZVVSSTtcblxuICAgICAgICBpZiAoYXR0ck5hbWVzcGFjZVVSSSkge1xuICAgICAgICAgICAgYXR0ck5hbWUgPSBhdHRyLmxvY2FsTmFtZSB8fCBhdHRyTmFtZTtcblxuICAgICAgICAgICAgaWYgKCF0b05vZGUuaGFzQXR0cmlidXRlTlMoYXR0ck5hbWVzcGFjZVVSSSwgYXR0ck5hbWUpKSB7XG4gICAgICAgICAgICAgICAgZnJvbU5vZGUucmVtb3ZlQXR0cmlidXRlTlMoYXR0ck5hbWVzcGFjZVVSSSwgYXR0ck5hbWUpO1xuICAgICAgICAgICAgfVxuICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgICAgaWYgKCF0b05vZGUuaGFzQXR0cmlidXRlKGF0dHJOYW1lKSkge1xuICAgICAgICAgICAgICAgIGZyb21Ob2RlLnJlbW92ZUF0dHJpYnV0ZShhdHRyTmFtZSk7XG4gICAgICAgICAgICB9XG4gICAgICAgIH1cbiAgICB9XG59XG5cbnZhciByYW5nZTsgLy8gQ3JlYXRlIGEgcmFuZ2Ugb2JqZWN0IGZvciBlZmZpY2VudGx5IHJlbmRlcmluZyBzdHJpbmdzIHRvIGVsZW1lbnRzLlxudmFyIE5TX1hIVE1MID0gJ2h0dHA6Ly93d3cudzMub3JnLzE5OTkveGh0bWwnO1xuXG52YXIgZG9jID0gdHlwZW9mIGRvY3VtZW50ID09PSAndW5kZWZpbmVkJyA/IHVuZGVmaW5lZCA6IGRvY3VtZW50O1xudmFyIEhBU19URU1QTEFURV9TVVBQT1JUID0gISFkb2MgJiYgJ2NvbnRlbnQnIGluIGRvYy5jcmVhdGVFbGVtZW50KCd0ZW1wbGF0ZScpO1xudmFyIEhBU19SQU5HRV9TVVBQT1JUID0gISFkb2MgJiYgZG9jLmNyZWF0ZVJhbmdlICYmICdjcmVhdGVDb250ZXh0dWFsRnJhZ21lbnQnIGluIGRvYy5jcmVhdGVSYW5nZSgpO1xuXG5mdW5jdGlvbiBjcmVhdGVGcmFnbWVudEZyb21UZW1wbGF0ZShzdHIpIHtcbiAgICB2YXIgdGVtcGxhdGUgPSBkb2MuY3JlYXRlRWxlbWVudCgndGVtcGxhdGUnKTtcbiAgICB0ZW1wbGF0ZS5pbm5lckhUTUwgPSBzdHI7XG4gICAgcmV0dXJuIHRlbXBsYXRlLmNvbnRlbnQuY2hpbGROb2Rlc1swXTtcbn1cblxuZnVuY3Rpb24gY3JlYXRlRnJhZ21lbnRGcm9tUmFuZ2Uoc3RyKSB7XG4gICAgaWYgKCFyYW5nZSkge1xuICAgICAgICByYW5nZSA9IGRvYy5jcmVhdGVSYW5nZSgpO1xuICAgICAgICByYW5nZS5zZWxlY3ROb2RlKGRvYy5ib2R5KTtcbiAgICB9XG5cbiAgICB2YXIgZnJhZ21lbnQgPSByYW5nZS5jcmVhdGVDb250ZXh0dWFsRnJhZ21lbnQoc3RyKTtcbiAgICByZXR1cm4gZnJhZ21lbnQuY2hpbGROb2Rlc1swXTtcbn1cblxuZnVuY3Rpb24gY3JlYXRlRnJhZ21lbnRGcm9tV3JhcChzdHIpIHtcbiAgICB2YXIgZnJhZ21lbnQgPSBkb2MuY3JlYXRlRWxlbWVudCgnYm9keScpO1xuICAgIGZyYWdtZW50LmlubmVySFRNTCA9IHN0cjtcbiAgICByZXR1cm4gZnJhZ21lbnQuY2hpbGROb2Rlc1swXTtcbn1cblxuLyoqXG4gKiBUaGlzIGlzIGFib3V0IHRoZSBzYW1lXG4gKiB2YXIgaHRtbCA9IG5ldyBET01QYXJzZXIoKS5wYXJzZUZyb21TdHJpbmcoc3RyLCAndGV4dC9odG1sJyk7XG4gKiByZXR1cm4gaHRtbC5ib2R5LmZpcnN0Q2hpbGQ7XG4gKlxuICogQG1ldGhvZCB0b0VsZW1lbnRcbiAqIEBwYXJhbSB7U3RyaW5nfSBzdHJcbiAqL1xuZnVuY3Rpb24gdG9FbGVtZW50KHN0cikge1xuICAgIHN0ciA9IHN0ci50cmltKCk7XG4gICAgaWYgKEhBU19URU1QTEFURV9TVVBQT1JUKSB7XG4gICAgICAvLyBhdm9pZCByZXN0cmljdGlvbnMgb24gY29udGVudCBmb3IgdGhpbmdzIGxpa2UgYDx0cj48dGg+SGk8L3RoPjwvdHI+YCB3aGljaFxuICAgICAgLy8gY3JlYXRlQ29udGV4dHVhbEZyYWdtZW50IGRvZXNuJ3Qgc3VwcG9ydFxuICAgICAgLy8gPHRlbXBsYXRlPiBzdXBwb3J0IG5vdCBhdmFpbGFibGUgaW4gSUVcbiAgICAgIHJldHVybiBjcmVhdGVGcmFnbWVudEZyb21UZW1wbGF0ZShzdHIpO1xuICAgIH0gZWxzZSBpZiAoSEFTX1JBTkdFX1NVUFBPUlQpIHtcbiAgICAgIHJldHVybiBjcmVhdGVGcmFnbWVudEZyb21SYW5nZShzdHIpO1xuICAgIH1cblxuICAgIHJldHVybiBjcmVhdGVGcmFnbWVudEZyb21XcmFwKHN0cik7XG59XG5cbi8qKlxuICogUmV0dXJucyB0cnVlIGlmIHR3byBub2RlJ3MgbmFtZXMgYXJlIHRoZSBzYW1lLlxuICpcbiAqIE5PVEU6IFdlIGRvbid0IGJvdGhlciBjaGVja2luZyBgbmFtZXNwYWNlVVJJYCBiZWNhdXNlIHlvdSB3aWxsIG5ldmVyIGZpbmQgdHdvIEhUTUwgZWxlbWVudHMgd2l0aCB0aGUgc2FtZVxuICogICAgICAgbm9kZU5hbWUgYW5kIGRpZmZlcmVudCBuYW1lc3BhY2UgVVJJcy5cbiAqXG4gKiBAcGFyYW0ge0VsZW1lbnR9IGFcbiAqIEBwYXJhbSB7RWxlbWVudH0gYiBUaGUgdGFyZ2V0IGVsZW1lbnRcbiAqIEByZXR1cm4ge2Jvb2xlYW59XG4gKi9cbmZ1bmN0aW9uIGNvbXBhcmVOb2RlTmFtZXMoZnJvbUVsLCB0b0VsKSB7XG4gICAgdmFyIGZyb21Ob2RlTmFtZSA9IGZyb21FbC5ub2RlTmFtZTtcbiAgICB2YXIgdG9Ob2RlTmFtZSA9IHRvRWwubm9kZU5hbWU7XG4gICAgdmFyIGZyb21Db2RlU3RhcnQsIHRvQ29kZVN0YXJ0O1xuXG4gICAgaWYgKGZyb21Ob2RlTmFtZSA9PT0gdG9Ob2RlTmFtZSkge1xuICAgICAgICByZXR1cm4gdHJ1ZTtcbiAgICB9XG5cbiAgICBmcm9tQ29kZVN0YXJ0ID0gZnJvbU5vZGVOYW1lLmNoYXJDb2RlQXQoMCk7XG4gICAgdG9Db2RlU3RhcnQgPSB0b05vZGVOYW1lLmNoYXJDb2RlQXQoMCk7XG5cbiAgICAvLyBJZiB0aGUgdGFyZ2V0IGVsZW1lbnQgaXMgYSB2aXJ0dWFsIERPTSBub2RlIG9yIFNWRyBub2RlIHRoZW4gd2UgbWF5XG4gICAgLy8gbmVlZCB0byBub3JtYWxpemUgdGhlIHRhZyBuYW1lIGJlZm9yZSBjb21wYXJpbmcuIE5vcm1hbCBIVE1MIGVsZW1lbnRzIHRoYXQgYXJlXG4gICAgLy8gaW4gdGhlIFwiaHR0cDovL3d3dy53My5vcmcvMTk5OS94aHRtbFwiXG4gICAgLy8gYXJlIGNvbnZlcnRlZCB0byB1cHBlciBjYXNlXG4gICAgaWYgKGZyb21Db2RlU3RhcnQgPD0gOTAgJiYgdG9Db2RlU3RhcnQgPj0gOTcpIHsgLy8gZnJvbSBpcyB1cHBlciBhbmQgdG8gaXMgbG93ZXJcbiAgICAgICAgcmV0dXJuIGZyb21Ob2RlTmFtZSA9PT0gdG9Ob2RlTmFtZS50b1VwcGVyQ2FzZSgpO1xuICAgIH0gZWxzZSBpZiAodG9Db2RlU3RhcnQgPD0gOTAgJiYgZnJvbUNvZGVTdGFydCA+PSA5NykgeyAvLyB0byBpcyB1cHBlciBhbmQgZnJvbSBpcyBsb3dlclxuICAgICAgICByZXR1cm4gdG9Ob2RlTmFtZSA9PT0gZnJvbU5vZGVOYW1lLnRvVXBwZXJDYXNlKCk7XG4gICAgfSBlbHNlIHtcbiAgICAgICAgcmV0dXJuIGZhbHNlO1xuICAgIH1cbn1cblxuLyoqXG4gKiBDcmVhdGUgYW4gZWxlbWVudCwgb3B0aW9uYWxseSB3aXRoIGEga25vd24gbmFtZXNwYWNlIFVSSS5cbiAqXG4gKiBAcGFyYW0ge3N0cmluZ30gbmFtZSB0aGUgZWxlbWVudCBuYW1lLCBlLmcuICdkaXYnIG9yICdzdmcnXG4gKiBAcGFyYW0ge3N0cmluZ30gW25hbWVzcGFjZVVSSV0gdGhlIGVsZW1lbnQncyBuYW1lc3BhY2UgVVJJLCBpLmUuIHRoZSB2YWx1ZSBvZlxuICogaXRzIGB4bWxuc2AgYXR0cmlidXRlIG9yIGl0cyBpbmZlcnJlZCBuYW1lc3BhY2UuXG4gKlxuICogQHJldHVybiB7RWxlbWVudH1cbiAqL1xuZnVuY3Rpb24gY3JlYXRlRWxlbWVudE5TKG5hbWUsIG5hbWVzcGFjZVVSSSkge1xuICAgIHJldHVybiAhbmFtZXNwYWNlVVJJIHx8IG5hbWVzcGFjZVVSSSA9PT0gTlNfWEhUTUwgP1xuICAgICAgICBkb2MuY3JlYXRlRWxlbWVudChuYW1lKSA6XG4gICAgICAgIGRvYy5jcmVhdGVFbGVtZW50TlMobmFtZXNwYWNlVVJJLCBuYW1lKTtcbn1cblxuLyoqXG4gKiBDb3BpZXMgdGhlIGNoaWxkcmVuIG9mIG9uZSBET00gZWxlbWVudCB0byBhbm90aGVyIERPTSBlbGVtZW50XG4gKi9cbmZ1bmN0aW9uIG1vdmVDaGlsZHJlbihmcm9tRWwsIHRvRWwpIHtcbiAgICB2YXIgY3VyQ2hpbGQgPSBmcm9tRWwuZmlyc3RDaGlsZDtcbiAgICB3aGlsZSAoY3VyQ2hpbGQpIHtcbiAgICAgICAgdmFyIG5leHRDaGlsZCA9IGN1ckNoaWxkLm5leHRTaWJsaW5nO1xuICAgICAgICB0b0VsLmFwcGVuZENoaWxkKGN1ckNoaWxkKTtcbiAgICAgICAgY3VyQ2hpbGQgPSBuZXh0Q2hpbGQ7XG4gICAgfVxuICAgIHJldHVybiB0b0VsO1xufVxuXG5mdW5jdGlvbiBzeW5jQm9vbGVhbkF0dHJQcm9wKGZyb21FbCwgdG9FbCwgbmFtZSkge1xuICAgIGlmIChmcm9tRWxbbmFtZV0gIT09IHRvRWxbbmFtZV0pIHtcbiAgICAgICAgZnJvbUVsW25hbWVdID0gdG9FbFtuYW1lXTtcbiAgICAgICAgaWYgKGZyb21FbFtuYW1lXSkge1xuICAgICAgICAgICAgZnJvbUVsLnNldEF0dHJpYnV0ZShuYW1lLCAnJyk7XG4gICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgICBmcm9tRWwucmVtb3ZlQXR0cmlidXRlKG5hbWUpO1xuICAgICAgICB9XG4gICAgfVxufVxuXG52YXIgc3BlY2lhbEVsSGFuZGxlcnMgPSB7XG4gICAgT1BUSU9OOiBmdW5jdGlvbihmcm9tRWwsIHRvRWwpIHtcbiAgICAgICAgdmFyIHBhcmVudE5vZGUgPSBmcm9tRWwucGFyZW50Tm9kZTtcbiAgICAgICAgaWYgKHBhcmVudE5vZGUpIHtcbiAgICAgICAgICAgIHZhciBwYXJlbnROYW1lID0gcGFyZW50Tm9kZS5ub2RlTmFtZS50b1VwcGVyQ2FzZSgpO1xuICAgICAgICAgICAgaWYgKHBhcmVudE5hbWUgPT09ICdPUFRHUk9VUCcpIHtcbiAgICAgICAgICAgICAgICBwYXJlbnROb2RlID0gcGFyZW50Tm9kZS5wYXJlbnROb2RlO1xuICAgICAgICAgICAgICAgIHBhcmVudE5hbWUgPSBwYXJlbnROb2RlICYmIHBhcmVudE5vZGUubm9kZU5hbWUudG9VcHBlckNhc2UoKTtcbiAgICAgICAgICAgIH1cbiAgICAgICAgICAgIGlmIChwYXJlbnROYW1lID09PSAnU0VMRUNUJyAmJiAhcGFyZW50Tm9kZS5oYXNBdHRyaWJ1dGUoJ211bHRpcGxlJykpIHtcbiAgICAgICAgICAgICAgICBpZiAoZnJvbUVsLmhhc0F0dHJpYnV0ZSgnc2VsZWN0ZWQnKSAmJiAhdG9FbC5zZWxlY3RlZCkge1xuICAgICAgICAgICAgICAgICAgICAvLyBXb3JrYXJvdW5kIGZvciBNUyBFZGdlIGJ1ZyB3aGVyZSB0aGUgJ3NlbGVjdGVkJyBhdHRyaWJ1dGUgY2FuIG9ubHkgYmVcbiAgICAgICAgICAgICAgICAgICAgLy8gcmVtb3ZlZCBpZiBzZXQgdG8gYSBub24tZW1wdHkgdmFsdWU6XG4gICAgICAgICAgICAgICAgICAgIC8vIGh0dHBzOi8vZGV2ZWxvcGVyLm1pY3Jvc29mdC5jb20vZW4tdXMvbWljcm9zb2Z0LWVkZ2UvcGxhdGZvcm0vaXNzdWVzLzEyMDg3Njc5L1xuICAgICAgICAgICAgICAgICAgICBmcm9tRWwuc2V0QXR0cmlidXRlKCdzZWxlY3RlZCcsICdzZWxlY3RlZCcpO1xuICAgICAgICAgICAgICAgICAgICBmcm9tRWwucmVtb3ZlQXR0cmlidXRlKCdzZWxlY3RlZCcpO1xuICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgICAvLyBXZSBoYXZlIHRvIHJlc2V0IHNlbGVjdCBlbGVtZW50J3Mgc2VsZWN0ZWRJbmRleCB0byAtMSwgb3RoZXJ3aXNlIHNldHRpbmdcbiAgICAgICAgICAgICAgICAvLyBmcm9tRWwuc2VsZWN0ZWQgdXNpbmcgdGhlIHN5bmNCb29sZWFuQXR0clByb3AgYmVsb3cgaGFzIG5vIGVmZmVjdC5cbiAgICAgICAgICAgICAgICAvLyBUaGUgY29ycmVjdCBzZWxlY3RlZEluZGV4IHdpbGwgYmUgc2V0IGluIHRoZSBTRUxFQ1Qgc3BlY2lhbCBoYW5kbGVyIGJlbG93LlxuICAgICAgICAgICAgICAgIHBhcmVudE5vZGUuc2VsZWN0ZWRJbmRleCA9IC0xO1xuICAgICAgICAgICAgfVxuICAgICAgICB9XG4gICAgICAgIHN5bmNCb29sZWFuQXR0clByb3AoZnJvbUVsLCB0b0VsLCAnc2VsZWN0ZWQnKTtcbiAgICB9LFxuICAgIC8qKlxuICAgICAqIFRoZSBcInZhbHVlXCIgYXR0cmlidXRlIGlzIHNwZWNpYWwgZm9yIHRoZSA8aW5wdXQ+IGVsZW1lbnQgc2luY2UgaXQgc2V0c1xuICAgICAqIHRoZSBpbml0aWFsIHZhbHVlLiBDaGFuZ2luZyB0aGUgXCJ2YWx1ZVwiIGF0dHJpYnV0ZSB3aXRob3V0IGNoYW5naW5nIHRoZVxuICAgICAqIFwidmFsdWVcIiBwcm9wZXJ0eSB3aWxsIGhhdmUgbm8gZWZmZWN0IHNpbmNlIGl0IGlzIG9ubHkgdXNlZCB0byB0aGUgc2V0IHRoZVxuICAgICAqIGluaXRpYWwgdmFsdWUuICBTaW1pbGFyIGZvciB0aGUgXCJjaGVja2VkXCIgYXR0cmlidXRlLCBhbmQgXCJkaXNhYmxlZFwiLlxuICAgICAqL1xuICAgIElOUFVUOiBmdW5jdGlvbihmcm9tRWwsIHRvRWwpIHtcbiAgICAgICAgc3luY0Jvb2xlYW5BdHRyUHJvcChmcm9tRWwsIHRvRWwsICdjaGVja2VkJyk7XG4gICAgICAgIHN5bmNCb29sZWFuQXR0clByb3AoZnJvbUVsLCB0b0VsLCAnZGlzYWJsZWQnKTtcblxuICAgICAgICBpZiAoZnJvbUVsLnZhbHVlICE9PSB0b0VsLnZhbHVlKSB7XG4gICAgICAgICAgICBmcm9tRWwudmFsdWUgPSB0b0VsLnZhbHVlO1xuICAgICAgICB9XG5cbiAgICAgICAgaWYgKCF0b0VsLmhhc0F0dHJpYnV0ZSgndmFsdWUnKSkge1xuICAgICAgICAgICAgZnJvbUVsLnJlbW92ZUF0dHJpYnV0ZSgndmFsdWUnKTtcbiAgICAgICAgfVxuICAgIH0sXG5cbiAgICBURVhUQVJFQTogZnVuY3Rpb24oZnJvbUVsLCB0b0VsKSB7XG4gICAgICAgIHZhciBuZXdWYWx1ZSA9IHRvRWwudmFsdWU7XG4gICAgICAgIGlmIChmcm9tRWwudmFsdWUgIT09IG5ld1ZhbHVlKSB7XG4gICAgICAgICAgICBmcm9tRWwudmFsdWUgPSBuZXdWYWx1ZTtcbiAgICAgICAgfVxuXG4gICAgICAgIHZhciBmaXJzdENoaWxkID0gZnJvbUVsLmZpcnN0Q2hpbGQ7XG4gICAgICAgIGlmIChmaXJzdENoaWxkKSB7XG4gICAgICAgICAgICAvLyBOZWVkZWQgZm9yIElFLiBBcHBhcmVudGx5IElFIHNldHMgdGhlIHBsYWNlaG9sZGVyIGFzIHRoZVxuICAgICAgICAgICAgLy8gbm9kZSB2YWx1ZSBhbmQgdmlzZSB2ZXJzYS4gVGhpcyBpZ25vcmVzIGFuIGVtcHR5IHVwZGF0ZS5cbiAgICAgICAgICAgIHZhciBvbGRWYWx1ZSA9IGZpcnN0Q2hpbGQubm9kZVZhbHVlO1xuXG4gICAgICAgICAgICBpZiAob2xkVmFsdWUgPT0gbmV3VmFsdWUgfHwgKCFuZXdWYWx1ZSAmJiBvbGRWYWx1ZSA9PSBmcm9tRWwucGxhY2Vob2xkZXIpKSB7XG4gICAgICAgICAgICAgICAgcmV0dXJuO1xuICAgICAgICAgICAgfVxuXG4gICAgICAgICAgICBmaXJzdENoaWxkLm5vZGVWYWx1ZSA9IG5ld1ZhbHVlO1xuICAgICAgICB9XG4gICAgfSxcbiAgICBTRUxFQ1Q6IGZ1bmN0aW9uKGZyb21FbCwgdG9FbCkge1xuICAgICAgICBpZiAoIXRvRWwuaGFzQXR0cmlidXRlKCdtdWx0aXBsZScpKSB7XG4gICAgICAgICAgICB2YXIgc2VsZWN0ZWRJbmRleCA9IC0xO1xuICAgICAgICAgICAgdmFyIGkgPSAwO1xuICAgICAgICAgICAgLy8gV2UgaGF2ZSB0byBsb29wIHRocm91Z2ggY2hpbGRyZW4gb2YgZnJvbUVsLCBub3QgdG9FbCBzaW5jZSBub2RlcyBjYW4gYmUgbW92ZWRcbiAgICAgICAgICAgIC8vIGZyb20gdG9FbCB0byBmcm9tRWwgZGlyZWN0bHkgd2hlbiBtb3JwaGluZy5cbiAgICAgICAgICAgIC8vIEF0IHRoZSB0aW1lIHRoaXMgc3BlY2lhbCBoYW5kbGVyIGlzIGludm9rZWQsIGFsbCBjaGlsZHJlbiBoYXZlIGFscmVhZHkgYmVlbiBtb3JwaGVkXG4gICAgICAgICAgICAvLyBhbmQgYXBwZW5kZWQgdG8gLyByZW1vdmVkIGZyb20gZnJvbUVsLCBzbyB1c2luZyBmcm9tRWwgaGVyZSBpcyBzYWZlIGFuZCBjb3JyZWN0LlxuICAgICAgICAgICAgdmFyIGN1ckNoaWxkID0gZnJvbUVsLmZpcnN0Q2hpbGQ7XG4gICAgICAgICAgICB2YXIgb3B0Z3JvdXA7XG4gICAgICAgICAgICB2YXIgbm9kZU5hbWU7XG4gICAgICAgICAgICB3aGlsZShjdXJDaGlsZCkge1xuICAgICAgICAgICAgICAgIG5vZGVOYW1lID0gY3VyQ2hpbGQubm9kZU5hbWUgJiYgY3VyQ2hpbGQubm9kZU5hbWUudG9VcHBlckNhc2UoKTtcbiAgICAgICAgICAgICAgICBpZiAobm9kZU5hbWUgPT09ICdPUFRHUk9VUCcpIHtcbiAgICAgICAgICAgICAgICAgICAgb3B0Z3JvdXAgPSBjdXJDaGlsZDtcbiAgICAgICAgICAgICAgICAgICAgY3VyQ2hpbGQgPSBvcHRncm91cC5maXJzdENoaWxkO1xuICAgICAgICAgICAgICAgICAgICAvLyBoYW5kbGUgZW1wdHkgb3B0Z3JvdXBzXG4gICAgICAgICAgICAgICAgICAgIGlmICghY3VyQ2hpbGQpIHtcbiAgICAgICAgICAgICAgICAgICAgICAgIGN1ckNoaWxkID0gb3B0Z3JvdXAubmV4dFNpYmxpbmc7XG4gICAgICAgICAgICAgICAgICAgICAgICBvcHRncm91cCA9IG51bGw7XG4gICAgICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgICAgICAgICAgICBpZiAobm9kZU5hbWUgPT09ICdPUFRJT04nKSB7XG4gICAgICAgICAgICAgICAgICAgICAgICBpZiAoY3VyQ2hpbGQuaGFzQXR0cmlidXRlKCdzZWxlY3RlZCcpKSB7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgc2VsZWN0ZWRJbmRleCA9IGk7XG4gICAgICAgICAgICAgICAgICAgICAgICAgICAgYnJlYWs7XG4gICAgICAgICAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICAgICAgICAgICAgICBpKys7XG4gICAgICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgICAgICAgY3VyQ2hpbGQgPSBjdXJDaGlsZC5uZXh0U2libGluZztcbiAgICAgICAgICAgICAgICAgICAgaWYgKCFjdXJDaGlsZCAmJiBvcHRncm91cCkge1xuICAgICAgICAgICAgICAgICAgICAgICAgY3VyQ2hpbGQgPSBvcHRncm91cC5uZXh0U2libGluZztcbiAgICAgICAgICAgICAgICAgICAgICAgIG9wdGdyb3VwID0gbnVsbDtcbiAgICAgICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgIH1cblxuICAgICAgICAgICAgZnJvbUVsLnNlbGVjdGVkSW5kZXggPSBzZWxlY3RlZEluZGV4O1xuICAgICAgICB9XG4gICAgfVxufTtcblxudmFyIEVMRU1FTlRfTk9ERSA9IDE7XG52YXIgRE9DVU1FTlRfRlJBR01FTlRfTk9ERSQxID0gMTE7XG52YXIgVEVYVF9OT0RFID0gMztcbnZhciBDT01NRU5UX05PREUgPSA4O1xuXG5mdW5jdGlvbiBub29wKCkge31cblxuZnVuY3Rpb24gZGVmYXVsdEdldE5vZGVLZXkobm9kZSkge1xuICBpZiAobm9kZSkge1xuICAgIHJldHVybiAobm9kZS5nZXRBdHRyaWJ1dGUgJiYgbm9kZS5nZXRBdHRyaWJ1dGUoJ2lkJykpIHx8IG5vZGUuaWQ7XG4gIH1cbn1cblxuZnVuY3Rpb24gbW9ycGhkb21GYWN0b3J5KG1vcnBoQXR0cnMpIHtcblxuICByZXR1cm4gZnVuY3Rpb24gbW9ycGhkb20oZnJvbU5vZGUsIHRvTm9kZSwgb3B0aW9ucykge1xuICAgIGlmICghb3B0aW9ucykge1xuICAgICAgb3B0aW9ucyA9IHt9O1xuICAgIH1cblxuICAgIGlmICh0eXBlb2YgdG9Ob2RlID09PSAnc3RyaW5nJykge1xuICAgICAgaWYgKGZyb21Ob2RlLm5vZGVOYW1lID09PSAnI2RvY3VtZW50JyB8fCBmcm9tTm9kZS5ub2RlTmFtZSA9PT0gJ0hUTUwnIHx8IGZyb21Ob2RlLm5vZGVOYW1lID09PSAnQk9EWScpIHtcbiAgICAgICAgdmFyIHRvTm9kZUh0bWwgPSB0b05vZGU7XG4gICAgICAgIHRvTm9kZSA9IGRvYy5jcmVhdGVFbGVtZW50KCdodG1sJyk7XG4gICAgICAgIHRvTm9kZS5pbm5lckhUTUwgPSB0b05vZGVIdG1sO1xuICAgICAgfSBlbHNlIHtcbiAgICAgICAgdG9Ob2RlID0gdG9FbGVtZW50KHRvTm9kZSk7XG4gICAgICB9XG4gICAgfSBlbHNlIGlmICh0b05vZGUubm9kZVR5cGUgPT09IERPQ1VNRU5UX0ZSQUdNRU5UX05PREUkMSkge1xuICAgICAgdG9Ob2RlID0gdG9Ob2RlLmZpcnN0RWxlbWVudENoaWxkO1xuICAgIH1cblxuICAgIHZhciBnZXROb2RlS2V5ID0gb3B0aW9ucy5nZXROb2RlS2V5IHx8IGRlZmF1bHRHZXROb2RlS2V5O1xuICAgIHZhciBvbkJlZm9yZU5vZGVBZGRlZCA9IG9wdGlvbnMub25CZWZvcmVOb2RlQWRkZWQgfHwgbm9vcDtcbiAgICB2YXIgb25Ob2RlQWRkZWQgPSBvcHRpb25zLm9uTm9kZUFkZGVkIHx8IG5vb3A7XG4gICAgdmFyIG9uQmVmb3JlRWxVcGRhdGVkID0gb3B0aW9ucy5vbkJlZm9yZUVsVXBkYXRlZCB8fCBub29wO1xuICAgIHZhciBvbkVsVXBkYXRlZCA9IG9wdGlvbnMub25FbFVwZGF0ZWQgfHwgbm9vcDtcbiAgICB2YXIgb25CZWZvcmVOb2RlRGlzY2FyZGVkID0gb3B0aW9ucy5vbkJlZm9yZU5vZGVEaXNjYXJkZWQgfHwgbm9vcDtcbiAgICB2YXIgb25Ob2RlRGlzY2FyZGVkID0gb3B0aW9ucy5vbk5vZGVEaXNjYXJkZWQgfHwgbm9vcDtcbiAgICB2YXIgb25CZWZvcmVFbENoaWxkcmVuVXBkYXRlZCA9IG9wdGlvbnMub25CZWZvcmVFbENoaWxkcmVuVXBkYXRlZCB8fCBub29wO1xuICAgIHZhciBza2lwRnJvbUNoaWxkcmVuID0gb3B0aW9ucy5za2lwRnJvbUNoaWxkcmVuIHx8IG5vb3A7XG4gICAgdmFyIGFkZENoaWxkID0gb3B0aW9ucy5hZGRDaGlsZCB8fCBmdW5jdGlvbihwYXJlbnQsIGNoaWxkKXsgcmV0dXJuIHBhcmVudC5hcHBlbmRDaGlsZChjaGlsZCk7IH07XG4gICAgdmFyIGNoaWxkcmVuT25seSA9IG9wdGlvbnMuY2hpbGRyZW5Pbmx5ID09PSB0cnVlO1xuXG4gICAgLy8gVGhpcyBvYmplY3QgaXMgdXNlZCBhcyBhIGxvb2t1cCB0byBxdWlja2x5IGZpbmQgYWxsIGtleWVkIGVsZW1lbnRzIGluIHRoZSBvcmlnaW5hbCBET00gdHJlZS5cbiAgICB2YXIgZnJvbU5vZGVzTG9va3VwID0gT2JqZWN0LmNyZWF0ZShudWxsKTtcbiAgICB2YXIga2V5ZWRSZW1vdmFsTGlzdCA9IFtdO1xuXG4gICAgZnVuY3Rpb24gYWRkS2V5ZWRSZW1vdmFsKGtleSkge1xuICAgICAga2V5ZWRSZW1vdmFsTGlzdC5wdXNoKGtleSk7XG4gICAgfVxuXG4gICAgZnVuY3Rpb24gd2Fsa0Rpc2NhcmRlZENoaWxkTm9kZXMobm9kZSwgc2tpcEtleWVkTm9kZXMpIHtcbiAgICAgIGlmIChub2RlLm5vZGVUeXBlID09PSBFTEVNRU5UX05PREUpIHtcbiAgICAgICAgdmFyIGN1ckNoaWxkID0gbm9kZS5maXJzdENoaWxkO1xuICAgICAgICB3aGlsZSAoY3VyQ2hpbGQpIHtcblxuICAgICAgICAgIHZhciBrZXkgPSB1bmRlZmluZWQ7XG5cbiAgICAgICAgICBpZiAoc2tpcEtleWVkTm9kZXMgJiYgKGtleSA9IGdldE5vZGVLZXkoY3VyQ2hpbGQpKSkge1xuICAgICAgICAgICAgLy8gSWYgd2UgYXJlIHNraXBwaW5nIGtleWVkIG5vZGVzIHRoZW4gd2UgYWRkIHRoZSBrZXlcbiAgICAgICAgICAgIC8vIHRvIGEgbGlzdCBzbyB0aGF0IGl0IGNhbiBiZSBoYW5kbGVkIGF0IHRoZSB2ZXJ5IGVuZC5cbiAgICAgICAgICAgIGFkZEtleWVkUmVtb3ZhbChrZXkpO1xuICAgICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgICAvLyBPbmx5IHJlcG9ydCB0aGUgbm9kZSBhcyBkaXNjYXJkZWQgaWYgaXQgaXMgbm90IGtleWVkLiBXZSBkbyB0aGlzIGJlY2F1c2VcbiAgICAgICAgICAgIC8vIGF0IHRoZSBlbmQgd2UgbG9vcCB0aHJvdWdoIGFsbCBrZXllZCBlbGVtZW50cyB0aGF0IHdlcmUgdW5tYXRjaGVkXG4gICAgICAgICAgICAvLyBhbmQgdGhlbiBkaXNjYXJkIHRoZW0gaW4gb25lIGZpbmFsIHBhc3MuXG4gICAgICAgICAgICBvbk5vZGVEaXNjYXJkZWQoY3VyQ2hpbGQpO1xuICAgICAgICAgICAgaWYgKGN1ckNoaWxkLmZpcnN0Q2hpbGQpIHtcbiAgICAgICAgICAgICAgd2Fsa0Rpc2NhcmRlZENoaWxkTm9kZXMoY3VyQ2hpbGQsIHNraXBLZXllZE5vZGVzKTtcbiAgICAgICAgICAgIH1cbiAgICAgICAgICB9XG5cbiAgICAgICAgICBjdXJDaGlsZCA9IGN1ckNoaWxkLm5leHRTaWJsaW5nO1xuICAgICAgICB9XG4gICAgICB9XG4gICAgfVxuXG4gICAgLyoqXG4gICAgKiBSZW1vdmVzIGEgRE9NIG5vZGUgb3V0IG9mIHRoZSBvcmlnaW5hbCBET01cbiAgICAqXG4gICAgKiBAcGFyYW0gIHtOb2RlfSBub2RlIFRoZSBub2RlIHRvIHJlbW92ZVxuICAgICogQHBhcmFtICB7Tm9kZX0gcGFyZW50Tm9kZSBUaGUgbm9kZXMgcGFyZW50XG4gICAgKiBAcGFyYW0gIHtCb29sZWFufSBza2lwS2V5ZWROb2RlcyBJZiB0cnVlIHRoZW4gZWxlbWVudHMgd2l0aCBrZXlzIHdpbGwgYmUgc2tpcHBlZCBhbmQgbm90IGRpc2NhcmRlZC5cbiAgICAqIEByZXR1cm4ge3VuZGVmaW5lZH1cbiAgICAqL1xuICAgIGZ1bmN0aW9uIHJlbW92ZU5vZGUobm9kZSwgcGFyZW50Tm9kZSwgc2tpcEtleWVkTm9kZXMpIHtcbiAgICAgIGlmIChvbkJlZm9yZU5vZGVEaXNjYXJkZWQobm9kZSkgPT09IGZhbHNlKSB7XG4gICAgICAgIHJldHVybjtcbiAgICAgIH1cblxuICAgICAgaWYgKHBhcmVudE5vZGUpIHtcbiAgICAgICAgcGFyZW50Tm9kZS5yZW1vdmVDaGlsZChub2RlKTtcbiAgICAgIH1cblxuICAgICAgb25Ob2RlRGlzY2FyZGVkKG5vZGUpO1xuICAgICAgd2Fsa0Rpc2NhcmRlZENoaWxkTm9kZXMobm9kZSwgc2tpcEtleWVkTm9kZXMpO1xuICAgIH1cblxuICAgIC8vIC8vIFRyZWVXYWxrZXIgaW1wbGVtZW50YXRpb24gaXMgbm8gZmFzdGVyLCBidXQga2VlcGluZyB0aGlzIGFyb3VuZCBpbiBjYXNlIHRoaXMgY2hhbmdlcyBpbiB0aGUgZnV0dXJlXG4gICAgLy8gZnVuY3Rpb24gaW5kZXhUcmVlKHJvb3QpIHtcbiAgICAvLyAgICAgdmFyIHRyZWVXYWxrZXIgPSBkb2N1bWVudC5jcmVhdGVUcmVlV2Fsa2VyKFxuICAgIC8vICAgICAgICAgcm9vdCxcbiAgICAvLyAgICAgICAgIE5vZGVGaWx0ZXIuU0hPV19FTEVNRU5UKTtcbiAgICAvL1xuICAgIC8vICAgICB2YXIgZWw7XG4gICAgLy8gICAgIHdoaWxlKChlbCA9IHRyZWVXYWxrZXIubmV4dE5vZGUoKSkpIHtcbiAgICAvLyAgICAgICAgIHZhciBrZXkgPSBnZXROb2RlS2V5KGVsKTtcbiAgICAvLyAgICAgICAgIGlmIChrZXkpIHtcbiAgICAvLyAgICAgICAgICAgICBmcm9tTm9kZXNMb29rdXBba2V5XSA9IGVsO1xuICAgIC8vICAgICAgICAgfVxuICAgIC8vICAgICB9XG4gICAgLy8gfVxuXG4gICAgLy8gLy8gTm9kZUl0ZXJhdG9yIGltcGxlbWVudGF0aW9uIGlzIG5vIGZhc3RlciwgYnV0IGtlZXBpbmcgdGhpcyBhcm91bmQgaW4gY2FzZSB0aGlzIGNoYW5nZXMgaW4gdGhlIGZ1dHVyZVxuICAgIC8vXG4gICAgLy8gZnVuY3Rpb24gaW5kZXhUcmVlKG5vZGUpIHtcbiAgICAvLyAgICAgdmFyIG5vZGVJdGVyYXRvciA9IGRvY3VtZW50LmNyZWF0ZU5vZGVJdGVyYXRvcihub2RlLCBOb2RlRmlsdGVyLlNIT1dfRUxFTUVOVCk7XG4gICAgLy8gICAgIHZhciBlbDtcbiAgICAvLyAgICAgd2hpbGUoKGVsID0gbm9kZUl0ZXJhdG9yLm5leHROb2RlKCkpKSB7XG4gICAgLy8gICAgICAgICB2YXIga2V5ID0gZ2V0Tm9kZUtleShlbCk7XG4gICAgLy8gICAgICAgICBpZiAoa2V5KSB7XG4gICAgLy8gICAgICAgICAgICAgZnJvbU5vZGVzTG9va3VwW2tleV0gPSBlbDtcbiAgICAvLyAgICAgICAgIH1cbiAgICAvLyAgICAgfVxuICAgIC8vIH1cblxuICAgIGZ1bmN0aW9uIGluZGV4VHJlZShub2RlKSB7XG4gICAgICBpZiAobm9kZS5ub2RlVHlwZSA9PT0gRUxFTUVOVF9OT0RFIHx8IG5vZGUubm9kZVR5cGUgPT09IERPQ1VNRU5UX0ZSQUdNRU5UX05PREUkMSkge1xuICAgICAgICB2YXIgY3VyQ2hpbGQgPSBub2RlLmZpcnN0Q2hpbGQ7XG4gICAgICAgIHdoaWxlIChjdXJDaGlsZCkge1xuICAgICAgICAgIHZhciBrZXkgPSBnZXROb2RlS2V5KGN1ckNoaWxkKTtcbiAgICAgICAgICBpZiAoa2V5KSB7XG4gICAgICAgICAgICBmcm9tTm9kZXNMb29rdXBba2V5XSA9IGN1ckNoaWxkO1xuICAgICAgICAgIH1cblxuICAgICAgICAgIC8vIFdhbGsgcmVjdXJzaXZlbHlcbiAgICAgICAgICBpbmRleFRyZWUoY3VyQ2hpbGQpO1xuXG4gICAgICAgICAgY3VyQ2hpbGQgPSBjdXJDaGlsZC5uZXh0U2libGluZztcbiAgICAgICAgfVxuICAgICAgfVxuICAgIH1cblxuICAgIGluZGV4VHJlZShmcm9tTm9kZSk7XG5cbiAgICBmdW5jdGlvbiBoYW5kbGVOb2RlQWRkZWQoZWwpIHtcbiAgICAgIG9uTm9kZUFkZGVkKGVsKTtcblxuICAgICAgdmFyIGN1ckNoaWxkID0gZWwuZmlyc3RDaGlsZDtcbiAgICAgIHdoaWxlIChjdXJDaGlsZCkge1xuICAgICAgICB2YXIgbmV4dFNpYmxpbmcgPSBjdXJDaGlsZC5uZXh0U2libGluZztcblxuICAgICAgICB2YXIga2V5ID0gZ2V0Tm9kZUtleShjdXJDaGlsZCk7XG4gICAgICAgIGlmIChrZXkpIHtcbiAgICAgICAgICB2YXIgdW5tYXRjaGVkRnJvbUVsID0gZnJvbU5vZGVzTG9va3VwW2tleV07XG4gICAgICAgICAgLy8gaWYgd2UgZmluZCBhIGR1cGxpY2F0ZSAjaWQgbm9kZSBpbiBjYWNoZSwgcmVwbGFjZSBgZWxgIHdpdGggY2FjaGUgdmFsdWVcbiAgICAgICAgICAvLyBhbmQgbW9ycGggaXQgdG8gdGhlIGNoaWxkIG5vZGUuXG4gICAgICAgICAgaWYgKHVubWF0Y2hlZEZyb21FbCAmJiBjb21wYXJlTm9kZU5hbWVzKGN1ckNoaWxkLCB1bm1hdGNoZWRGcm9tRWwpKSB7XG4gICAgICAgICAgICBjdXJDaGlsZC5wYXJlbnROb2RlLnJlcGxhY2VDaGlsZCh1bm1hdGNoZWRGcm9tRWwsIGN1ckNoaWxkKTtcbiAgICAgICAgICAgIG1vcnBoRWwodW5tYXRjaGVkRnJvbUVsLCBjdXJDaGlsZCk7XG4gICAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAgIGhhbmRsZU5vZGVBZGRlZChjdXJDaGlsZCk7XG4gICAgICAgICAgfVxuICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgIC8vIHJlY3Vyc2l2ZWx5IGNhbGwgZm9yIGN1ckNoaWxkIGFuZCBpdCdzIGNoaWxkcmVuIHRvIHNlZSBpZiB3ZSBmaW5kIHNvbWV0aGluZyBpblxuICAgICAgICAgIC8vIGZyb21Ob2Rlc0xvb2t1cFxuICAgICAgICAgIGhhbmRsZU5vZGVBZGRlZChjdXJDaGlsZCk7XG4gICAgICAgIH1cblxuICAgICAgICBjdXJDaGlsZCA9IG5leHRTaWJsaW5nO1xuICAgICAgfVxuICAgIH1cblxuICAgIGZ1bmN0aW9uIGNsZWFudXBGcm9tRWwoZnJvbUVsLCBjdXJGcm9tTm9kZUNoaWxkLCBjdXJGcm9tTm9kZUtleSkge1xuICAgICAgLy8gV2UgaGF2ZSBwcm9jZXNzZWQgYWxsIG9mIHRoZSBcInRvIG5vZGVzXCIuIElmIGN1ckZyb21Ob2RlQ2hpbGQgaXNcbiAgICAgIC8vIG5vbi1udWxsIHRoZW4gd2Ugc3RpbGwgaGF2ZSBzb21lIGZyb20gbm9kZXMgbGVmdCBvdmVyIHRoYXQgbmVlZFxuICAgICAgLy8gdG8gYmUgcmVtb3ZlZFxuICAgICAgd2hpbGUgKGN1ckZyb21Ob2RlQ2hpbGQpIHtcbiAgICAgICAgdmFyIGZyb21OZXh0U2libGluZyA9IGN1ckZyb21Ob2RlQ2hpbGQubmV4dFNpYmxpbmc7XG4gICAgICAgIGlmICgoY3VyRnJvbU5vZGVLZXkgPSBnZXROb2RlS2V5KGN1ckZyb21Ob2RlQ2hpbGQpKSkge1xuICAgICAgICAgIC8vIFNpbmNlIHRoZSBub2RlIGlzIGtleWVkIGl0IG1pZ2h0IGJlIG1hdGNoZWQgdXAgbGF0ZXIgc28gd2UgZGVmZXJcbiAgICAgICAgICAvLyB0aGUgYWN0dWFsIHJlbW92YWwgdG8gbGF0ZXJcbiAgICAgICAgICBhZGRLZXllZFJlbW92YWwoY3VyRnJvbU5vZGVLZXkpO1xuICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgIC8vIE5PVEU6IHdlIHNraXAgbmVzdGVkIGtleWVkIG5vZGVzIGZyb20gYmVpbmcgcmVtb3ZlZCBzaW5jZSB0aGVyZSBpc1xuICAgICAgICAgIC8vICAgICAgIHN0aWxsIGEgY2hhbmNlIHRoZXkgd2lsbCBiZSBtYXRjaGVkIHVwIGxhdGVyXG4gICAgICAgICAgcmVtb3ZlTm9kZShjdXJGcm9tTm9kZUNoaWxkLCBmcm9tRWwsIHRydWUgLyogc2tpcCBrZXllZCBub2RlcyAqLyk7XG4gICAgICAgIH1cbiAgICAgICAgY3VyRnJvbU5vZGVDaGlsZCA9IGZyb21OZXh0U2libGluZztcbiAgICAgIH1cbiAgICB9XG5cbiAgICBmdW5jdGlvbiBtb3JwaEVsKGZyb21FbCwgdG9FbCwgY2hpbGRyZW5Pbmx5KSB7XG4gICAgICB2YXIgdG9FbEtleSA9IGdldE5vZGVLZXkodG9FbCk7XG5cbiAgICAgIGlmICh0b0VsS2V5KSB7XG4gICAgICAgIC8vIElmIGFuIGVsZW1lbnQgd2l0aCBhbiBJRCBpcyBiZWluZyBtb3JwaGVkIHRoZW4gaXQgd2lsbCBiZSBpbiB0aGUgZmluYWxcbiAgICAgICAgLy8gRE9NIHNvIGNsZWFyIGl0IG91dCBvZiB0aGUgc2F2ZWQgZWxlbWVudHMgY29sbGVjdGlvblxuICAgICAgICBkZWxldGUgZnJvbU5vZGVzTG9va3VwW3RvRWxLZXldO1xuICAgICAgfVxuXG4gICAgICBpZiAoIWNoaWxkcmVuT25seSkge1xuICAgICAgICAvLyBvcHRpb25hbFxuICAgICAgICB2YXIgYmVmb3JlVXBkYXRlUmVzdWx0ID0gb25CZWZvcmVFbFVwZGF0ZWQoZnJvbUVsLCB0b0VsKTtcbiAgICAgICAgaWYgKGJlZm9yZVVwZGF0ZVJlc3VsdCA9PT0gZmFsc2UpIHtcbiAgICAgICAgICByZXR1cm47XG4gICAgICAgIH0gZWxzZSBpZiAoYmVmb3JlVXBkYXRlUmVzdWx0IGluc3RhbmNlb2YgSFRNTEVsZW1lbnQpIHtcbiAgICAgICAgICBmcm9tRWwgPSBiZWZvcmVVcGRhdGVSZXN1bHQ7XG4gICAgICAgICAgLy8gcmVpbmRleCB0aGUgbmV3IGZyb21FbCBpbiBjYXNlIGl0J3Mgbm90IGluIHRoZSBzYW1lXG4gICAgICAgICAgLy8gdHJlZSBhcyB0aGUgb3JpZ2luYWwgZnJvbUVsXG4gICAgICAgICAgLy8gKFBob2VuaXggTGl2ZVZpZXcgc29tZXRpbWVzIHJldHVybnMgYSBjbG9uZWQgdHJlZSxcbiAgICAgICAgICAvLyAgYnV0IGtleWVkIGxvb2t1cHMgd291bGQgc3RpbGwgcG9pbnQgdG8gdGhlIG9yaWdpbmFsIHRyZWUpXG4gICAgICAgICAgaW5kZXhUcmVlKGZyb21FbCk7XG4gICAgICAgIH1cblxuICAgICAgICAvLyB1cGRhdGUgYXR0cmlidXRlcyBvbiBvcmlnaW5hbCBET00gZWxlbWVudCBmaXJzdFxuICAgICAgICBtb3JwaEF0dHJzKGZyb21FbCwgdG9FbCk7XG4gICAgICAgIC8vIG9wdGlvbmFsXG4gICAgICAgIG9uRWxVcGRhdGVkKGZyb21FbCk7XG5cbiAgICAgICAgaWYgKG9uQmVmb3JlRWxDaGlsZHJlblVwZGF0ZWQoZnJvbUVsLCB0b0VsKSA9PT0gZmFsc2UpIHtcbiAgICAgICAgICByZXR1cm47XG4gICAgICAgIH1cbiAgICAgIH1cblxuICAgICAgaWYgKGZyb21FbC5ub2RlTmFtZSAhPT0gJ1RFWFRBUkVBJykge1xuICAgICAgICBtb3JwaENoaWxkcmVuKGZyb21FbCwgdG9FbCk7XG4gICAgICB9IGVsc2Uge1xuICAgICAgICBzcGVjaWFsRWxIYW5kbGVycy5URVhUQVJFQShmcm9tRWwsIHRvRWwpO1xuICAgICAgfVxuICAgIH1cblxuICAgIGZ1bmN0aW9uIG1vcnBoQ2hpbGRyZW4oZnJvbUVsLCB0b0VsKSB7XG4gICAgICB2YXIgc2tpcEZyb20gPSBza2lwRnJvbUNoaWxkcmVuKGZyb21FbCwgdG9FbCk7XG4gICAgICB2YXIgY3VyVG9Ob2RlQ2hpbGQgPSB0b0VsLmZpcnN0Q2hpbGQ7XG4gICAgICB2YXIgY3VyRnJvbU5vZGVDaGlsZCA9IGZyb21FbC5maXJzdENoaWxkO1xuICAgICAgdmFyIGN1clRvTm9kZUtleTtcbiAgICAgIHZhciBjdXJGcm9tTm9kZUtleTtcblxuICAgICAgdmFyIGZyb21OZXh0U2libGluZztcbiAgICAgIHZhciB0b05leHRTaWJsaW5nO1xuICAgICAgdmFyIG1hdGNoaW5nRnJvbUVsO1xuXG4gICAgICAvLyB3YWxrIHRoZSBjaGlsZHJlblxuICAgICAgb3V0ZXI6IHdoaWxlIChjdXJUb05vZGVDaGlsZCkge1xuICAgICAgICB0b05leHRTaWJsaW5nID0gY3VyVG9Ob2RlQ2hpbGQubmV4dFNpYmxpbmc7XG4gICAgICAgIGN1clRvTm9kZUtleSA9IGdldE5vZGVLZXkoY3VyVG9Ob2RlQ2hpbGQpO1xuXG4gICAgICAgIC8vIHdhbGsgdGhlIGZyb21Ob2RlIGNoaWxkcmVuIGFsbCB0aGUgd2F5IHRocm91Z2hcbiAgICAgICAgd2hpbGUgKCFza2lwRnJvbSAmJiBjdXJGcm9tTm9kZUNoaWxkKSB7XG4gICAgICAgICAgZnJvbU5leHRTaWJsaW5nID0gY3VyRnJvbU5vZGVDaGlsZC5uZXh0U2libGluZztcblxuICAgICAgICAgIGlmIChjdXJUb05vZGVDaGlsZC5pc1NhbWVOb2RlICYmIGN1clRvTm9kZUNoaWxkLmlzU2FtZU5vZGUoY3VyRnJvbU5vZGVDaGlsZCkpIHtcbiAgICAgICAgICAgIGN1clRvTm9kZUNoaWxkID0gdG9OZXh0U2libGluZztcbiAgICAgICAgICAgIGN1ckZyb21Ob2RlQ2hpbGQgPSBmcm9tTmV4dFNpYmxpbmc7XG4gICAgICAgICAgICBjb250aW51ZSBvdXRlcjtcbiAgICAgICAgICB9XG5cbiAgICAgICAgICBjdXJGcm9tTm9kZUtleSA9IGdldE5vZGVLZXkoY3VyRnJvbU5vZGVDaGlsZCk7XG5cbiAgICAgICAgICB2YXIgY3VyRnJvbU5vZGVUeXBlID0gY3VyRnJvbU5vZGVDaGlsZC5ub2RlVHlwZTtcblxuICAgICAgICAgIC8vIHRoaXMgbWVhbnMgaWYgdGhlIGN1ckZyb21Ob2RlQ2hpbGQgZG9lc250IGhhdmUgYSBtYXRjaCB3aXRoIHRoZSBjdXJUb05vZGVDaGlsZFxuICAgICAgICAgIHZhciBpc0NvbXBhdGlibGUgPSB1bmRlZmluZWQ7XG5cbiAgICAgICAgICBpZiAoY3VyRnJvbU5vZGVUeXBlID09PSBjdXJUb05vZGVDaGlsZC5ub2RlVHlwZSkge1xuICAgICAgICAgICAgaWYgKGN1ckZyb21Ob2RlVHlwZSA9PT0gRUxFTUVOVF9OT0RFKSB7XG4gICAgICAgICAgICAgIC8vIEJvdGggbm9kZXMgYmVpbmcgY29tcGFyZWQgYXJlIEVsZW1lbnQgbm9kZXNcblxuICAgICAgICAgICAgICBpZiAoY3VyVG9Ob2RlS2V5KSB7XG4gICAgICAgICAgICAgICAgLy8gVGhlIHRhcmdldCBub2RlIGhhcyBhIGtleSBzbyB3ZSB3YW50IHRvIG1hdGNoIGl0IHVwIHdpdGggdGhlIGNvcnJlY3QgZWxlbWVudFxuICAgICAgICAgICAgICAgIC8vIGluIHRoZSBvcmlnaW5hbCBET00gdHJlZVxuICAgICAgICAgICAgICAgIGlmIChjdXJUb05vZGVLZXkgIT09IGN1ckZyb21Ob2RlS2V5KSB7XG4gICAgICAgICAgICAgICAgICAvLyBUaGUgY3VycmVudCBlbGVtZW50IGluIHRoZSBvcmlnaW5hbCBET00gdHJlZSBkb2VzIG5vdCBoYXZlIGEgbWF0Y2hpbmcga2V5IHNvXG4gICAgICAgICAgICAgICAgICAvLyBsZXQncyBjaGVjayBvdXIgbG9va3VwIHRvIHNlZSBpZiB0aGVyZSBpcyBhIG1hdGNoaW5nIGVsZW1lbnQgaW4gdGhlIG9yaWdpbmFsXG4gICAgICAgICAgICAgICAgICAvLyBET00gdHJlZVxuICAgICAgICAgICAgICAgICAgaWYgKChtYXRjaGluZ0Zyb21FbCA9IGZyb21Ob2Rlc0xvb2t1cFtjdXJUb05vZGVLZXldKSkge1xuICAgICAgICAgICAgICAgICAgICBpZiAoZnJvbU5leHRTaWJsaW5nID09PSBtYXRjaGluZ0Zyb21FbCkge1xuICAgICAgICAgICAgICAgICAgICAgIC8vIFNwZWNpYWwgY2FzZSBmb3Igc2luZ2xlIGVsZW1lbnQgcmVtb3ZhbHMuIFRvIGF2b2lkIHJlbW92aW5nIHRoZSBvcmlnaW5hbFxuICAgICAgICAgICAgICAgICAgICAgIC8vIERPTSBub2RlIG91dCBvZiB0aGUgdHJlZSAoc2luY2UgdGhhdCBjYW4gYnJlYWsgQ1NTIHRyYW5zaXRpb25zLCBldGMuKSxcbiAgICAgICAgICAgICAgICAgICAgICAvLyB3ZSB3aWxsIGluc3RlYWQgZGlzY2FyZCB0aGUgY3VycmVudCBub2RlIGFuZCB3YWl0IHVudGlsIHRoZSBuZXh0XG4gICAgICAgICAgICAgICAgICAgICAgLy8gaXRlcmF0aW9uIHRvIHByb3Blcmx5IG1hdGNoIHVwIHRoZSBrZXllZCB0YXJnZXQgZWxlbWVudCB3aXRoIGl0cyBtYXRjaGluZ1xuICAgICAgICAgICAgICAgICAgICAgIC8vIGVsZW1lbnQgaW4gdGhlIG9yaWdpbmFsIHRyZWVcbiAgICAgICAgICAgICAgICAgICAgICBpc0NvbXBhdGlibGUgPSBmYWxzZTtcbiAgICAgICAgICAgICAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAgICAgICAgICAgICAvLyBXZSBmb3VuZCBhIG1hdGNoaW5nIGtleWVkIGVsZW1lbnQgc29tZXdoZXJlIGluIHRoZSBvcmlnaW5hbCBET00gdHJlZS5cbiAgICAgICAgICAgICAgICAgICAgICAvLyBMZXQncyBtb3ZlIHRoZSBvcmlnaW5hbCBET00gbm9kZSBpbnRvIHRoZSBjdXJyZW50IHBvc2l0aW9uIGFuZCBtb3JwaFxuICAgICAgICAgICAgICAgICAgICAgIC8vIGl0LlxuXG4gICAgICAgICAgICAgICAgICAgICAgLy8gTk9URTogV2UgdXNlIGluc2VydEJlZm9yZSBpbnN0ZWFkIG9mIHJlcGxhY2VDaGlsZCBiZWNhdXNlIHdlIHdhbnQgdG8gZ28gdGhyb3VnaFxuICAgICAgICAgICAgICAgICAgICAgIC8vIHRoZSBgcmVtb3ZlTm9kZSgpYCBmdW5jdGlvbiBmb3IgdGhlIG5vZGUgdGhhdCBpcyBiZWluZyBkaXNjYXJkZWQgc28gdGhhdFxuICAgICAgICAgICAgICAgICAgICAgIC8vIGFsbCBsaWZlY3ljbGUgaG9va3MgYXJlIGNvcnJlY3RseSBpbnZva2VkXG4gICAgICAgICAgICAgICAgICAgICAgZnJvbUVsLmluc2VydEJlZm9yZShtYXRjaGluZ0Zyb21FbCwgY3VyRnJvbU5vZGVDaGlsZCk7XG5cbiAgICAgICAgICAgICAgICAgICAgICAvLyBmcm9tTmV4dFNpYmxpbmcgPSBjdXJGcm9tTm9kZUNoaWxkLm5leHRTaWJsaW5nO1xuXG4gICAgICAgICAgICAgICAgICAgICAgaWYgKGN1ckZyb21Ob2RlS2V5KSB7XG4gICAgICAgICAgICAgICAgICAgICAgICAvLyBTaW5jZSB0aGUgbm9kZSBpcyBrZXllZCBpdCBtaWdodCBiZSBtYXRjaGVkIHVwIGxhdGVyIHNvIHdlIGRlZmVyXG4gICAgICAgICAgICAgICAgICAgICAgICAvLyB0aGUgYWN0dWFsIHJlbW92YWwgdG8gbGF0ZXJcbiAgICAgICAgICAgICAgICAgICAgICAgIGFkZEtleWVkUmVtb3ZhbChjdXJGcm9tTm9kZUtleSk7XG4gICAgICAgICAgICAgICAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAgICAgICAgICAgICAgIC8vIE5PVEU6IHdlIHNraXAgbmVzdGVkIGtleWVkIG5vZGVzIGZyb20gYmVpbmcgcmVtb3ZlZCBzaW5jZSB0aGVyZSBpc1xuICAgICAgICAgICAgICAgICAgICAgICAgLy8gICAgICAgc3RpbGwgYSBjaGFuY2UgdGhleSB3aWxsIGJlIG1hdGNoZWQgdXAgbGF0ZXJcbiAgICAgICAgICAgICAgICAgICAgICAgIHJlbW92ZU5vZGUoY3VyRnJvbU5vZGVDaGlsZCwgZnJvbUVsLCB0cnVlIC8qIHNraXAga2V5ZWQgbm9kZXMgKi8pO1xuICAgICAgICAgICAgICAgICAgICAgIH1cblxuICAgICAgICAgICAgICAgICAgICAgIGN1ckZyb21Ob2RlQ2hpbGQgPSBtYXRjaGluZ0Zyb21FbDtcbiAgICAgICAgICAgICAgICAgICAgICBjdXJGcm9tTm9kZUtleSA9IGdldE5vZGVLZXkoY3VyRnJvbU5vZGVDaGlsZCk7XG4gICAgICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgICAgICAgICAgIC8vIFRoZSBub2RlcyBhcmUgbm90IGNvbXBhdGlibGUgc2luY2UgdGhlIFwidG9cIiBub2RlIGhhcyBhIGtleSBhbmQgdGhlcmVcbiAgICAgICAgICAgICAgICAgICAgLy8gaXMgbm8gbWF0Y2hpbmcga2V5ZWQgbm9kZSBpbiB0aGUgc291cmNlIHRyZWVcbiAgICAgICAgICAgICAgICAgICAgaXNDb21wYXRpYmxlID0gZmFsc2U7XG4gICAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICB9IGVsc2UgaWYgKGN1ckZyb21Ob2RlS2V5KSB7XG4gICAgICAgICAgICAgICAgLy8gVGhlIG9yaWdpbmFsIGhhcyBhIGtleVxuICAgICAgICAgICAgICAgIGlzQ29tcGF0aWJsZSA9IGZhbHNlO1xuICAgICAgICAgICAgICB9XG5cbiAgICAgICAgICAgICAgaXNDb21wYXRpYmxlID0gaXNDb21wYXRpYmxlICE9PSBmYWxzZSAmJiBjb21wYXJlTm9kZU5hbWVzKGN1ckZyb21Ob2RlQ2hpbGQsIGN1clRvTm9kZUNoaWxkKTtcbiAgICAgICAgICAgICAgaWYgKGlzQ29tcGF0aWJsZSkge1xuICAgICAgICAgICAgICAgIC8vIFdlIGZvdW5kIGNvbXBhdGlibGUgRE9NIGVsZW1lbnRzIHNvIHRyYW5zZm9ybVxuICAgICAgICAgICAgICAgIC8vIHRoZSBjdXJyZW50IFwiZnJvbVwiIG5vZGUgdG8gbWF0Y2ggdGhlIGN1cnJlbnRcbiAgICAgICAgICAgICAgICAvLyB0YXJnZXQgRE9NIG5vZGUuXG4gICAgICAgICAgICAgICAgLy8gTU9SUEhcbiAgICAgICAgICAgICAgICBtb3JwaEVsKGN1ckZyb21Ob2RlQ2hpbGQsIGN1clRvTm9kZUNoaWxkKTtcbiAgICAgICAgICAgICAgfVxuXG4gICAgICAgICAgICB9IGVsc2UgaWYgKGN1ckZyb21Ob2RlVHlwZSA9PT0gVEVYVF9OT0RFIHx8IGN1ckZyb21Ob2RlVHlwZSA9PSBDT01NRU5UX05PREUpIHtcbiAgICAgICAgICAgICAgLy8gQm90aCBub2RlcyBiZWluZyBjb21wYXJlZCBhcmUgVGV4dCBvciBDb21tZW50IG5vZGVzXG4gICAgICAgICAgICAgIGlzQ29tcGF0aWJsZSA9IHRydWU7XG4gICAgICAgICAgICAgIC8vIFNpbXBseSB1cGRhdGUgbm9kZVZhbHVlIG9uIHRoZSBvcmlnaW5hbCBub2RlIHRvXG4gICAgICAgICAgICAgIC8vIGNoYW5nZSB0aGUgdGV4dCB2YWx1ZVxuICAgICAgICAgICAgICBpZiAoY3VyRnJvbU5vZGVDaGlsZC5ub2RlVmFsdWUgIT09IGN1clRvTm9kZUNoaWxkLm5vZGVWYWx1ZSkge1xuICAgICAgICAgICAgICAgIGN1ckZyb21Ob2RlQ2hpbGQubm9kZVZhbHVlID0gY3VyVG9Ob2RlQ2hpbGQubm9kZVZhbHVlO1xuICAgICAgICAgICAgICB9XG5cbiAgICAgICAgICAgIH1cbiAgICAgICAgICB9XG5cbiAgICAgICAgICBpZiAoaXNDb21wYXRpYmxlKSB7XG4gICAgICAgICAgICAvLyBBZHZhbmNlIGJvdGggdGhlIFwidG9cIiBjaGlsZCBhbmQgdGhlIFwiZnJvbVwiIGNoaWxkIHNpbmNlIHdlIGZvdW5kIGEgbWF0Y2hcbiAgICAgICAgICAgIC8vIE5vdGhpbmcgZWxzZSB0byBkbyBhcyB3ZSBhbHJlYWR5IHJlY3Vyc2l2ZWx5IGNhbGxlZCBtb3JwaENoaWxkcmVuIGFib3ZlXG4gICAgICAgICAgICBjdXJUb05vZGVDaGlsZCA9IHRvTmV4dFNpYmxpbmc7XG4gICAgICAgICAgICBjdXJGcm9tTm9kZUNoaWxkID0gZnJvbU5leHRTaWJsaW5nO1xuICAgICAgICAgICAgY29udGludWUgb3V0ZXI7XG4gICAgICAgICAgfVxuXG4gICAgICAgICAgLy8gTm8gY29tcGF0aWJsZSBtYXRjaCBzbyByZW1vdmUgdGhlIG9sZCBub2RlIGZyb20gdGhlIERPTSBhbmQgY29udGludWUgdHJ5aW5nIHRvIGZpbmQgYVxuICAgICAgICAgIC8vIG1hdGNoIGluIHRoZSBvcmlnaW5hbCBET00uIEhvd2V2ZXIsIHdlIG9ubHkgZG8gdGhpcyBpZiB0aGUgZnJvbSBub2RlIGlzIG5vdCBrZXllZFxuICAgICAgICAgIC8vIHNpbmNlIGl0IGlzIHBvc3NpYmxlIHRoYXQgYSBrZXllZCBub2RlIG1pZ2h0IG1hdGNoIHVwIHdpdGggYSBub2RlIHNvbWV3aGVyZSBlbHNlIGluIHRoZVxuICAgICAgICAgIC8vIHRhcmdldCB0cmVlIGFuZCB3ZSBkb24ndCB3YW50IHRvIGRpc2NhcmQgaXQganVzdCB5ZXQgc2luY2UgaXQgc3RpbGwgbWlnaHQgZmluZCBhXG4gICAgICAgICAgLy8gaG9tZSBpbiB0aGUgZmluYWwgRE9NIHRyZWUuIEFmdGVyIGV2ZXJ5dGhpbmcgaXMgZG9uZSB3ZSB3aWxsIHJlbW92ZSBhbnkga2V5ZWQgbm9kZXNcbiAgICAgICAgICAvLyB0aGF0IGRpZG4ndCBmaW5kIGEgaG9tZVxuICAgICAgICAgIGlmIChjdXJGcm9tTm9kZUtleSkge1xuICAgICAgICAgICAgLy8gU2luY2UgdGhlIG5vZGUgaXMga2V5ZWQgaXQgbWlnaHQgYmUgbWF0Y2hlZCB1cCBsYXRlciBzbyB3ZSBkZWZlclxuICAgICAgICAgICAgLy8gdGhlIGFjdHVhbCByZW1vdmFsIHRvIGxhdGVyXG4gICAgICAgICAgICBhZGRLZXllZFJlbW92YWwoY3VyRnJvbU5vZGVLZXkpO1xuICAgICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgICAvLyBOT1RFOiB3ZSBza2lwIG5lc3RlZCBrZXllZCBub2RlcyBmcm9tIGJlaW5nIHJlbW92ZWQgc2luY2UgdGhlcmUgaXNcbiAgICAgICAgICAgIC8vICAgICAgIHN0aWxsIGEgY2hhbmNlIHRoZXkgd2lsbCBiZSBtYXRjaGVkIHVwIGxhdGVyXG4gICAgICAgICAgICByZW1vdmVOb2RlKGN1ckZyb21Ob2RlQ2hpbGQsIGZyb21FbCwgdHJ1ZSAvKiBza2lwIGtleWVkIG5vZGVzICovKTtcbiAgICAgICAgICB9XG5cbiAgICAgICAgICBjdXJGcm9tTm9kZUNoaWxkID0gZnJvbU5leHRTaWJsaW5nO1xuICAgICAgICB9IC8vIEVORDogd2hpbGUoY3VyRnJvbU5vZGVDaGlsZCkge31cblxuICAgICAgICAvLyBJZiB3ZSBnb3QgdGhpcyBmYXIgdGhlbiB3ZSBkaWQgbm90IGZpbmQgYSBjYW5kaWRhdGUgbWF0Y2ggZm9yXG4gICAgICAgIC8vIG91ciBcInRvIG5vZGVcIiBhbmQgd2UgZXhoYXVzdGVkIGFsbCBvZiB0aGUgY2hpbGRyZW4gXCJmcm9tXCJcbiAgICAgICAgLy8gbm9kZXMuIFRoZXJlZm9yZSwgd2Ugd2lsbCBqdXN0IGFwcGVuZCB0aGUgY3VycmVudCBcInRvXCIgbm9kZVxuICAgICAgICAvLyB0byB0aGUgZW5kXG4gICAgICAgIGlmIChjdXJUb05vZGVLZXkgJiYgKG1hdGNoaW5nRnJvbUVsID0gZnJvbU5vZGVzTG9va3VwW2N1clRvTm9kZUtleV0pICYmIGNvbXBhcmVOb2RlTmFtZXMobWF0Y2hpbmdGcm9tRWwsIGN1clRvTm9kZUNoaWxkKSkge1xuICAgICAgICAgIC8vIE1PUlBIXG4gICAgICAgICAgaWYoIXNraXBGcm9tKXsgYWRkQ2hpbGQoZnJvbUVsLCBtYXRjaGluZ0Zyb21FbCk7IH1cbiAgICAgICAgICBtb3JwaEVsKG1hdGNoaW5nRnJvbUVsLCBjdXJUb05vZGVDaGlsZCk7XG4gICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgdmFyIG9uQmVmb3JlTm9kZUFkZGVkUmVzdWx0ID0gb25CZWZvcmVOb2RlQWRkZWQoY3VyVG9Ob2RlQ2hpbGQpO1xuICAgICAgICAgIGlmIChvbkJlZm9yZU5vZGVBZGRlZFJlc3VsdCAhPT0gZmFsc2UpIHtcbiAgICAgICAgICAgIGlmIChvbkJlZm9yZU5vZGVBZGRlZFJlc3VsdCkge1xuICAgICAgICAgICAgICBjdXJUb05vZGVDaGlsZCA9IG9uQmVmb3JlTm9kZUFkZGVkUmVzdWx0O1xuICAgICAgICAgICAgfVxuXG4gICAgICAgICAgICBpZiAoY3VyVG9Ob2RlQ2hpbGQuYWN0dWFsaXplKSB7XG4gICAgICAgICAgICAgIGN1clRvTm9kZUNoaWxkID0gY3VyVG9Ob2RlQ2hpbGQuYWN0dWFsaXplKGZyb21FbC5vd25lckRvY3VtZW50IHx8IGRvYyk7XG4gICAgICAgICAgICB9XG4gICAgICAgICAgICBhZGRDaGlsZChmcm9tRWwsIGN1clRvTm9kZUNoaWxkKTtcbiAgICAgICAgICAgIGhhbmRsZU5vZGVBZGRlZChjdXJUb05vZGVDaGlsZCk7XG4gICAgICAgICAgfVxuICAgICAgICB9XG5cbiAgICAgICAgY3VyVG9Ob2RlQ2hpbGQgPSB0b05leHRTaWJsaW5nO1xuICAgICAgICBjdXJGcm9tTm9kZUNoaWxkID0gZnJvbU5leHRTaWJsaW5nO1xuICAgICAgfVxuXG4gICAgICBjbGVhbnVwRnJvbUVsKGZyb21FbCwgY3VyRnJvbU5vZGVDaGlsZCwgY3VyRnJvbU5vZGVLZXkpO1xuXG4gICAgICB2YXIgc3BlY2lhbEVsSGFuZGxlciA9IHNwZWNpYWxFbEhhbmRsZXJzW2Zyb21FbC5ub2RlTmFtZV07XG4gICAgICBpZiAoc3BlY2lhbEVsSGFuZGxlcikge1xuICAgICAgICBzcGVjaWFsRWxIYW5kbGVyKGZyb21FbCwgdG9FbCk7XG4gICAgICB9XG4gICAgfSAvLyBFTkQ6IG1vcnBoQ2hpbGRyZW4oLi4uKVxuXG4gICAgdmFyIG1vcnBoZWROb2RlID0gZnJvbU5vZGU7XG4gICAgdmFyIG1vcnBoZWROb2RlVHlwZSA9IG1vcnBoZWROb2RlLm5vZGVUeXBlO1xuICAgIHZhciB0b05vZGVUeXBlID0gdG9Ob2RlLm5vZGVUeXBlO1xuXG4gICAgaWYgKCFjaGlsZHJlbk9ubHkpIHtcbiAgICAgIC8vIEhhbmRsZSB0aGUgY2FzZSB3aGVyZSB3ZSBhcmUgZ2l2ZW4gdHdvIERPTSBub2RlcyB0aGF0IGFyZSBub3RcbiAgICAgIC8vIGNvbXBhdGlibGUgKGUuZy4gPGRpdj4gLS0+IDxzcGFuPiBvciA8ZGl2PiAtLT4gVEVYVClcbiAgICAgIGlmIChtb3JwaGVkTm9kZVR5cGUgPT09IEVMRU1FTlRfTk9ERSkge1xuICAgICAgICBpZiAodG9Ob2RlVHlwZSA9PT0gRUxFTUVOVF9OT0RFKSB7XG4gICAgICAgICAgaWYgKCFjb21wYXJlTm9kZU5hbWVzKGZyb21Ob2RlLCB0b05vZGUpKSB7XG4gICAgICAgICAgICBvbk5vZGVEaXNjYXJkZWQoZnJvbU5vZGUpO1xuICAgICAgICAgICAgbW9ycGhlZE5vZGUgPSBtb3ZlQ2hpbGRyZW4oZnJvbU5vZGUsIGNyZWF0ZUVsZW1lbnROUyh0b05vZGUubm9kZU5hbWUsIHRvTm9kZS5uYW1lc3BhY2VVUkkpKTtcbiAgICAgICAgICB9XG4gICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgLy8gR29pbmcgZnJvbSBhbiBlbGVtZW50IG5vZGUgdG8gYSB0ZXh0IG5vZGVcbiAgICAgICAgICBtb3JwaGVkTm9kZSA9IHRvTm9kZTtcbiAgICAgICAgfVxuICAgICAgfSBlbHNlIGlmIChtb3JwaGVkTm9kZVR5cGUgPT09IFRFWFRfTk9ERSB8fCBtb3JwaGVkTm9kZVR5cGUgPT09IENPTU1FTlRfTk9ERSkgeyAvLyBUZXh0IG9yIGNvbW1lbnQgbm9kZVxuICAgICAgICBpZiAodG9Ob2RlVHlwZSA9PT0gbW9ycGhlZE5vZGVUeXBlKSB7XG4gICAgICAgICAgaWYgKG1vcnBoZWROb2RlLm5vZGVWYWx1ZSAhPT0gdG9Ob2RlLm5vZGVWYWx1ZSkge1xuICAgICAgICAgICAgbW9ycGhlZE5vZGUubm9kZVZhbHVlID0gdG9Ob2RlLm5vZGVWYWx1ZTtcbiAgICAgICAgICB9XG5cbiAgICAgICAgICByZXR1cm4gbW9ycGhlZE5vZGU7XG4gICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgLy8gVGV4dCBub2RlIHRvIHNvbWV0aGluZyBlbHNlXG4gICAgICAgICAgbW9ycGhlZE5vZGUgPSB0b05vZGU7XG4gICAgICAgIH1cbiAgICAgIH1cbiAgICB9XG5cbiAgICBpZiAobW9ycGhlZE5vZGUgPT09IHRvTm9kZSkge1xuICAgICAgLy8gVGhlIFwidG8gbm9kZVwiIHdhcyBub3QgY29tcGF0aWJsZSB3aXRoIHRoZSBcImZyb20gbm9kZVwiIHNvIHdlIGhhZCB0b1xuICAgICAgLy8gdG9zcyBvdXQgdGhlIFwiZnJvbSBub2RlXCIgYW5kIHVzZSB0aGUgXCJ0byBub2RlXCJcbiAgICAgIG9uTm9kZURpc2NhcmRlZChmcm9tTm9kZSk7XG4gICAgfSBlbHNlIHtcbiAgICAgIGlmICh0b05vZGUuaXNTYW1lTm9kZSAmJiB0b05vZGUuaXNTYW1lTm9kZShtb3JwaGVkTm9kZSkpIHtcbiAgICAgICAgcmV0dXJuO1xuICAgICAgfVxuXG4gICAgICBtb3JwaEVsKG1vcnBoZWROb2RlLCB0b05vZGUsIGNoaWxkcmVuT25seSk7XG5cbiAgICAgIC8vIFdlIG5vdyBuZWVkIHRvIGxvb3Agb3ZlciBhbnkga2V5ZWQgbm9kZXMgdGhhdCBtaWdodCBuZWVkIHRvIGJlXG4gICAgICAvLyByZW1vdmVkLiBXZSBvbmx5IGRvIHRoZSByZW1vdmFsIGlmIHdlIGtub3cgdGhhdCB0aGUga2V5ZWQgbm9kZVxuICAgICAgLy8gbmV2ZXIgZm91bmQgYSBtYXRjaC4gV2hlbiBhIGtleWVkIG5vZGUgaXMgbWF0Y2hlZCB1cCB3ZSByZW1vdmVcbiAgICAgIC8vIGl0IG91dCBvZiBmcm9tTm9kZXNMb29rdXAgYW5kIHdlIHVzZSBmcm9tTm9kZXNMb29rdXAgdG8gZGV0ZXJtaW5lXG4gICAgICAvLyBpZiBhIGtleWVkIG5vZGUgaGFzIGJlZW4gbWF0Y2hlZCB1cCBvciBub3RcbiAgICAgIGlmIChrZXllZFJlbW92YWxMaXN0KSB7XG4gICAgICAgIGZvciAodmFyIGk9MCwgbGVuPWtleWVkUmVtb3ZhbExpc3QubGVuZ3RoOyBpPGxlbjsgaSsrKSB7XG4gICAgICAgICAgdmFyIGVsVG9SZW1vdmUgPSBmcm9tTm9kZXNMb29rdXBba2V5ZWRSZW1vdmFsTGlzdFtpXV07XG4gICAgICAgICAgaWYgKGVsVG9SZW1vdmUpIHtcbiAgICAgICAgICAgIHJlbW92ZU5vZGUoZWxUb1JlbW92ZSwgZWxUb1JlbW92ZS5wYXJlbnROb2RlLCBmYWxzZSk7XG4gICAgICAgICAgfVxuICAgICAgICB9XG4gICAgICB9XG4gICAgfVxuXG4gICAgaWYgKCFjaGlsZHJlbk9ubHkgJiYgbW9ycGhlZE5vZGUgIT09IGZyb21Ob2RlICYmIGZyb21Ob2RlLnBhcmVudE5vZGUpIHtcbiAgICAgIGlmIChtb3JwaGVkTm9kZS5hY3R1YWxpemUpIHtcbiAgICAgICAgbW9ycGhlZE5vZGUgPSBtb3JwaGVkTm9kZS5hY3R1YWxpemUoZnJvbU5vZGUub3duZXJEb2N1bWVudCB8fCBkb2MpO1xuICAgICAgfVxuICAgICAgLy8gSWYgd2UgaGFkIHRvIHN3YXAgb3V0IHRoZSBmcm9tIG5vZGUgd2l0aCBhIG5ldyBub2RlIGJlY2F1c2UgdGhlIG9sZFxuICAgICAgLy8gbm9kZSB3YXMgbm90IGNvbXBhdGlibGUgd2l0aCB0aGUgdGFyZ2V0IG5vZGUgdGhlbiB3ZSBuZWVkIHRvXG4gICAgICAvLyByZXBsYWNlIHRoZSBvbGQgRE9NIG5vZGUgaW4gdGhlIG9yaWdpbmFsIERPTSB0cmVlLiBUaGlzIGlzIG9ubHlcbiAgICAgIC8vIHBvc3NpYmxlIGlmIHRoZSBvcmlnaW5hbCBET00gbm9kZSB3YXMgcGFydCBvZiBhIERPTSB0cmVlIHdoaWNoXG4gICAgICAvLyB3ZSBrbm93IGlzIHRoZSBjYXNlIGlmIGl0IGhhcyBhIHBhcmVudCBub2RlLlxuICAgICAgZnJvbU5vZGUucGFyZW50Tm9kZS5yZXBsYWNlQ2hpbGQobW9ycGhlZE5vZGUsIGZyb21Ob2RlKTtcbiAgICB9XG5cbiAgICByZXR1cm4gbW9ycGhlZE5vZGU7XG4gIH07XG59XG5cbnZhciBtb3JwaGRvbSA9IG1vcnBoZG9tRmFjdG9yeShtb3JwaEF0dHJzKTtcblxuZXhwb3J0IGRlZmF1bHQgbW9ycGhkb207XG4iLCAiaW1wb3J0IHtcbiAgUEhYX0NPTVBPTkVOVCxcbiAgUEhYX1BSVU5FLFxuICBQSFhfUk9PVF9JRCxcbiAgUEhYX1NFU1NJT04sXG4gIFBIWF9TS0lQLFxuICBQSFhfTUFHSUNfSUQsXG4gIFBIWF9TVEFUSUMsXG4gIFBIWF9UUklHR0VSX0FDVElPTixcbiAgUEhYX1VQREFURSxcbiAgUEhYX1JFRl9TUkMsXG4gIFBIWF9SRUZfTE9DSyxcbiAgUEhYX1NUUkVBTSxcbiAgUEhYX1NUUkVBTV9SRUYsXG4gIFBIWF9WSUVXUE9SVF9UT1AsXG4gIFBIWF9WSUVXUE9SVF9CT1RUT00sXG4gIFBIWF9QT1JUQUwsXG4gIFBIWF9URUxFUE9SVEVEX1JFRixcbiAgUEhYX1RFTEVQT1JURURfU1JDLFxuICBQSFhfUlVOVElNRV9IT09LLFxufSBmcm9tIFwiLi9jb25zdGFudHNcIjtcblxuaW1wb3J0IHsgZGV0ZWN0RHVwbGljYXRlSWRzLCBkZXRlY3RJbnZhbGlkU3RyZWFtSW5zZXJ0cywgaXNDaWQgfSBmcm9tIFwiLi91dGlsc1wiO1xuaW1wb3J0IEVsZW1lbnRSZWYgZnJvbSBcIi4vZWxlbWVudF9yZWZcIjtcbmltcG9ydCBET00gZnJvbSBcIi4vZG9tXCI7XG5pbXBvcnQgRE9NUG9zdE1vcnBoUmVzdG9yZXIgZnJvbSBcIi4vZG9tX3Bvc3RfbW9ycGhfcmVzdG9yZXJcIjtcbmltcG9ydCBtb3JwaGRvbSBmcm9tIFwibW9ycGhkb21cIjtcblxuZXhwb3J0IGRlZmF1bHQgY2xhc3MgRE9NUGF0Y2gge1xuICBjb25zdHJ1Y3Rvcih2aWV3LCBjb250YWluZXIsIGlkLCBodG1sLCBzdHJlYW1zLCB0YXJnZXRDSUQsIG9wdHMgPSB7fSkge1xuICAgIHRoaXMudmlldyA9IHZpZXc7XG4gICAgdGhpcy5saXZlU29ja2V0ID0gdmlldy5saXZlU29ja2V0O1xuICAgIHRoaXMuY29udGFpbmVyID0gY29udGFpbmVyO1xuICAgIHRoaXMuaWQgPSBpZDtcbiAgICB0aGlzLnJvb3RJRCA9IHZpZXcucm9vdC5pZDtcbiAgICB0aGlzLmh0bWwgPSBodG1sO1xuICAgIHRoaXMuc3RyZWFtcyA9IHN0cmVhbXM7XG4gICAgdGhpcy5zdHJlYW1JbnNlcnRzID0ge307XG4gICAgdGhpcy5zdHJlYW1Db21wb25lbnRSZXN0b3JlID0ge307XG4gICAgdGhpcy50YXJnZXRDSUQgPSB0YXJnZXRDSUQ7XG4gICAgdGhpcy5jaWRQYXRjaCA9IGlzQ2lkKHRoaXMudGFyZ2V0Q0lEKTtcbiAgICB0aGlzLnBlbmRpbmdSZW1vdmVzID0gW107XG4gICAgdGhpcy5waHhSZW1vdmUgPSB0aGlzLmxpdmVTb2NrZXQuYmluZGluZyhcInJlbW92ZVwiKTtcbiAgICB0aGlzLnRhcmdldENvbnRhaW5lciA9IHRoaXMuaXNDSURQYXRjaCgpXG4gICAgICA/IHRoaXMudGFyZ2V0Q0lEQ29udGFpbmVyKGh0bWwpXG4gICAgICA6IGNvbnRhaW5lcjtcbiAgICB0aGlzLmNhbGxiYWNrcyA9IHtcbiAgICAgIGJlZm9yZWFkZGVkOiBbXSxcbiAgICAgIGJlZm9yZXVwZGF0ZWQ6IFtdLFxuICAgICAgYmVmb3JlcGh4Q2hpbGRBZGRlZDogW10sXG4gICAgICBhZnRlcmFkZGVkOiBbXSxcbiAgICAgIGFmdGVydXBkYXRlZDogW10sXG4gICAgICBhZnRlcmRpc2NhcmRlZDogW10sXG4gICAgICBhZnRlcnBoeENoaWxkQWRkZWQ6IFtdLFxuICAgICAgYWZ0ZXJ0cmFuc2l0aW9uc0Rpc2NhcmRlZDogW10sXG4gICAgfTtcbiAgICB0aGlzLndpdGhDaGlsZHJlbiA9IG9wdHMud2l0aENoaWxkcmVuIHx8IG9wdHMudW5kb1JlZiB8fCBmYWxzZTtcbiAgICB0aGlzLnVuZG9SZWYgPSBvcHRzLnVuZG9SZWY7XG4gIH1cblxuICBiZWZvcmUoa2luZCwgY2FsbGJhY2spIHtcbiAgICB0aGlzLmNhbGxiYWNrc1tgYmVmb3JlJHtraW5kfWBdLnB1c2goY2FsbGJhY2spO1xuICB9XG4gIGFmdGVyKGtpbmQsIGNhbGxiYWNrKSB7XG4gICAgdGhpcy5jYWxsYmFja3NbYGFmdGVyJHtraW5kfWBdLnB1c2goY2FsbGJhY2spO1xuICB9XG5cbiAgdHJhY2tCZWZvcmUoa2luZCwgLi4uYXJncykge1xuICAgIHRoaXMuY2FsbGJhY2tzW2BiZWZvcmUke2tpbmR9YF0uZm9yRWFjaCgoY2FsbGJhY2spID0+IGNhbGxiYWNrKC4uLmFyZ3MpKTtcbiAgfVxuXG4gIHRyYWNrQWZ0ZXIoa2luZCwgLi4uYXJncykge1xuICAgIHRoaXMuY2FsbGJhY2tzW2BhZnRlciR7a2luZH1gXS5mb3JFYWNoKChjYWxsYmFjaykgPT4gY2FsbGJhY2soLi4uYXJncykpO1xuICB9XG5cbiAgbWFya1BydW5hYmxlQ29udGVudEZvclJlbW92YWwoKSB7XG4gICAgY29uc3QgcGh4VXBkYXRlID0gdGhpcy5saXZlU29ja2V0LmJpbmRpbmcoUEhYX1VQREFURSk7XG4gICAgRE9NLmFsbChcbiAgICAgIHRoaXMuY29udGFpbmVyLFxuICAgICAgYFske3BoeFVwZGF0ZX09YXBwZW5kXSA+ICosIFske3BoeFVwZGF0ZX09cHJlcGVuZF0gPiAqYCxcbiAgICAgIChlbCkgPT4ge1xuICAgICAgICBlbC5zZXRBdHRyaWJ1dGUoUEhYX1BSVU5FLCBcIlwiKTtcbiAgICAgIH0sXG4gICAgKTtcbiAgfVxuXG4gIHBlcmZvcm0oaXNKb2luUGF0Y2gpIHtcbiAgICBjb25zdCB7IHZpZXcsIGxpdmVTb2NrZXQsIGh0bWwsIGNvbnRhaW5lciB9ID0gdGhpcztcbiAgICBsZXQgdGFyZ2V0Q29udGFpbmVyID0gdGhpcy50YXJnZXRDb250YWluZXI7XG5cbiAgICBpZiAodGhpcy5pc0NJRFBhdGNoKCkgJiYgIXRoaXMudGFyZ2V0Q29udGFpbmVyKSB7XG4gICAgICByZXR1cm47XG4gICAgfVxuXG4gICAgaWYgKHRoaXMuaXNDSURQYXRjaCgpKSB7XG4gICAgICAvLyBodHRwczovL2dpdGh1Yi5jb20vcGhvZW5peGZyYW1ld29yay9waG9lbml4X2xpdmVfdmlldy9wdWxsLzM5NDJcbiAgICAgIC8vIHdlIG5lZWQgdG8gZW5zdXJlIHRoYXQgbm8gcGFyZW50IGlzIGxvY2tlZFxuICAgICAgY29uc3QgY2xvc2VzdExvY2sgPSB0YXJnZXRDb250YWluZXIuY2xvc2VzdChgWyR7UEhYX1JFRl9MT0NLfV1gKTtcbiAgICAgIGlmIChjbG9zZXN0TG9jaykge1xuICAgICAgICBjb25zdCBjbG9uZWRUcmVlID0gRE9NLnByaXZhdGUoY2xvc2VzdExvY2ssIFBIWF9SRUZfTE9DSyk7XG4gICAgICAgIGlmIChjbG9uZWRUcmVlKSB7XG4gICAgICAgICAgLy8gaWYgYSBwYXJlbnQgaXMgbG9ja2VkIHdpdGggYSBjbG9uZWQgdHJlZSwgd2UgbmVlZCB0byBwYXRjaCB0aGUgY2xvbmVkIHRyZWUgaW5zdGVhZFxuICAgICAgICAgIHRhcmdldENvbnRhaW5lciA9IGNsb25lZFRyZWUucXVlcnlTZWxlY3RvcihcbiAgICAgICAgICAgIGBbZGF0YS1waHgtY29tcG9uZW50PVwiJHt0aGlzLnRhcmdldENJRH1cIl1gLFxuICAgICAgICAgICk7XG4gICAgICAgIH1cbiAgICAgIH1cbiAgICB9XG5cbiAgICBjb25zdCBmb2N1c2VkID0gbGl2ZVNvY2tldC5nZXRBY3RpdmVFbGVtZW50KCk7XG4gICAgY29uc3QgeyBzZWxlY3Rpb25TdGFydCwgc2VsZWN0aW9uRW5kIH0gPVxuICAgICAgZm9jdXNlZCAmJiBET00uaGFzU2VsZWN0aW9uUmFuZ2UoZm9jdXNlZCkgPyBmb2N1c2VkIDoge307XG4gICAgY29uc3QgcGh4VXBkYXRlID0gbGl2ZVNvY2tldC5iaW5kaW5nKFBIWF9VUERBVEUpO1xuICAgIGNvbnN0IHBoeFZpZXdwb3J0VG9wID0gbGl2ZVNvY2tldC5iaW5kaW5nKFBIWF9WSUVXUE9SVF9UT1ApO1xuICAgIGNvbnN0IHBoeFZpZXdwb3J0Qm90dG9tID0gbGl2ZVNvY2tldC5iaW5kaW5nKFBIWF9WSUVXUE9SVF9CT1RUT00pO1xuICAgIGNvbnN0IHBoeFRyaWdnZXJFeHRlcm5hbCA9IGxpdmVTb2NrZXQuYmluZGluZyhQSFhfVFJJR0dFUl9BQ1RJT04pO1xuICAgIGNvbnN0IGFkZGVkID0gW107XG4gICAgY29uc3QgdXBkYXRlcyA9IFtdO1xuICAgIGNvbnN0IGFwcGVuZFByZXBlbmRVcGRhdGVzID0gW107XG5cbiAgICAvLyBhcyB0aGUgcG9ydGFsIHRhcmdldCBpdHNlbGYgY291bGQgYmUgYXQgdGhlIGVuZCBvZiB0aGUgRE9NLFxuICAgIC8vIGl0IG1heSBub3QgYmUgcHJlc2VudCB3aGlsZSBtb3JwaGluZyBwcmV2aW91cyBwYXJ0cztcbiAgICAvLyB0aGVyZWZvcmUgd2UgYXBwbHkgYWxsIHRlbGVwb3J0cyBhZnRlciB0aGUgbW9ycGhpbmcgaXMgZG9uZStcbiAgICBjb25zdCBwb3J0YWxDYWxsYmFja3MgPSBbXTtcblxuICAgIGxldCBleHRlcm5hbEZvcm1UcmlnZ2VyZWQgPSBudWxsO1xuXG4gICAgY29uc3QgbW9ycGggPSAoXG4gICAgICB0YXJnZXRDb250YWluZXIsXG4gICAgICBzb3VyY2UsXG4gICAgICB3aXRoQ2hpbGRyZW4gPSB0aGlzLndpdGhDaGlsZHJlbixcbiAgICApID0+IHtcbiAgICAgIGNvbnN0IG1vcnBoQ2FsbGJhY2tzID0ge1xuICAgICAgICAvLyBub3JtYWxseSwgd2UgYXJlIHJ1bm5pbmcgd2l0aCBjaGlsZHJlbk9ubHksIGFzIHRoZSBwYXRjaCBIVE1MIGZvciBhIExWXG4gICAgICAgIC8vIGRvZXMgbm90IGluY2x1ZGUgdGhlIExWIGF0dHJzIChkYXRhLXBoeC1zZXNzaW9uLCBldGMuKVxuICAgICAgICAvLyB3aGVuIHdlIGFyZSBwYXRjaGluZyBhIGxpdmUgY29tcG9uZW50LCB3ZSBkbyB3YW50IHRvIHBhdGNoIHRoZSByb290IGVsZW1lbnQgYXMgd2VsbDtcbiAgICAgICAgLy8gYW5vdGhlciBjYXNlIGlzIHRoZSByZWN1cnNpdmUgcGF0Y2ggb2YgYSBzdHJlYW0gaXRlbSB0aGF0IHdhcyBrZXB0IG9uIHJlc2V0ICgtPiBvbkJlZm9yZU5vZGVBZGRlZClcbiAgICAgICAgY2hpbGRyZW5Pbmx5OlxuICAgICAgICAgIHRhcmdldENvbnRhaW5lci5nZXRBdHRyaWJ1dGUoUEhYX0NPTVBPTkVOVCkgPT09IG51bGwgJiYgIXdpdGhDaGlsZHJlbixcbiAgICAgICAgZ2V0Tm9kZUtleTogKG5vZGUpID0+IHtcbiAgICAgICAgICBpZiAoRE9NLmlzUGh4RGVzdHJveWVkKG5vZGUpKSB7XG4gICAgICAgICAgICByZXR1cm4gbnVsbDtcbiAgICAgICAgICB9XG4gICAgICAgICAgLy8gSWYgd2UgaGF2ZSBhIGpvaW4gcGF0Y2gsIHRoZW4gYnkgZGVmaW5pdGlvbiB0aGVyZSB3YXMgbm8gUEhYX01BR0lDX0lELlxuICAgICAgICAgIC8vIFRoaXMgaXMgaW1wb3J0YW50IHRvIHJlZHVjZSB0aGUgYW1vdW50IG9mIGVsZW1lbnRzIG1vcnBoZG9tIGRpc2NhcmRzLlxuICAgICAgICAgIGlmIChpc0pvaW5QYXRjaCkge1xuICAgICAgICAgICAgcmV0dXJuIG5vZGUuaWQ7XG4gICAgICAgICAgfVxuICAgICAgICAgIHJldHVybiAoXG4gICAgICAgICAgICBub2RlLmlkIHx8IChub2RlLmdldEF0dHJpYnV0ZSAmJiBub2RlLmdldEF0dHJpYnV0ZShQSFhfTUFHSUNfSUQpKVxuICAgICAgICAgICk7XG4gICAgICAgIH0sXG4gICAgICAgIC8vIHNraXAgaW5kZXhpbmcgZnJvbSBjaGlsZHJlbiB3aGVuIGNvbnRhaW5lciBpcyBzdHJlYW1cbiAgICAgICAgc2tpcEZyb21DaGlsZHJlbjogKGZyb20pID0+IHtcbiAgICAgICAgICByZXR1cm4gZnJvbS5nZXRBdHRyaWJ1dGUocGh4VXBkYXRlKSA9PT0gUEhYX1NUUkVBTTtcbiAgICAgICAgfSxcbiAgICAgICAgLy8gdGVsbCBtb3JwaGRvbSBob3cgdG8gYWRkIGEgY2hpbGRcbiAgICAgICAgYWRkQ2hpbGQ6IChwYXJlbnQsIGNoaWxkKSA9PiB7XG4gICAgICAgICAgY29uc3QgeyByZWYsIHN0cmVhbUF0IH0gPSB0aGlzLmdldFN0cmVhbUluc2VydChjaGlsZCk7XG4gICAgICAgICAgaWYgKHJlZiA9PT0gdW5kZWZpbmVkKSB7XG4gICAgICAgICAgICByZXR1cm4gcGFyZW50LmFwcGVuZENoaWxkKGNoaWxkKTtcbiAgICAgICAgICB9XG5cbiAgICAgICAgICB0aGlzLnNldFN0cmVhbVJlZihjaGlsZCwgcmVmKTtcblxuICAgICAgICAgIC8vIHN0cmVhbWluZ1xuICAgICAgICAgIGlmIChzdHJlYW1BdCA9PT0gMCkge1xuICAgICAgICAgICAgcGFyZW50Lmluc2VydEFkamFjZW50RWxlbWVudChcImFmdGVyYmVnaW5cIiwgY2hpbGQpO1xuICAgICAgICAgIH0gZWxzZSBpZiAoc3RyZWFtQXQgPT09IC0xKSB7XG4gICAgICAgICAgICBjb25zdCBsYXN0Q2hpbGQgPSBwYXJlbnQubGFzdEVsZW1lbnRDaGlsZDtcbiAgICAgICAgICAgIGlmIChsYXN0Q2hpbGQgJiYgIWxhc3RDaGlsZC5oYXNBdHRyaWJ1dGUoUEhYX1NUUkVBTV9SRUYpKSB7XG4gICAgICAgICAgICAgIGNvbnN0IG5vblN0cmVhbUNoaWxkID0gQXJyYXkuZnJvbShwYXJlbnQuY2hpbGRyZW4pLmZpbmQoXG4gICAgICAgICAgICAgICAgKGMpID0+ICFjLmhhc0F0dHJpYnV0ZShQSFhfU1RSRUFNX1JFRiksXG4gICAgICAgICAgICAgICk7XG4gICAgICAgICAgICAgIHBhcmVudC5pbnNlcnRCZWZvcmUoY2hpbGQsIG5vblN0cmVhbUNoaWxkKTtcbiAgICAgICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgICAgIHBhcmVudC5hcHBlbmRDaGlsZChjaGlsZCk7XG4gICAgICAgICAgICB9XG4gICAgICAgICAgfSBlbHNlIGlmIChzdHJlYW1BdCA+IDApIHtcbiAgICAgICAgICAgIGNvbnN0IHNpYmxpbmcgPSBBcnJheS5mcm9tKHBhcmVudC5jaGlsZHJlbilbc3RyZWFtQXRdO1xuICAgICAgICAgICAgcGFyZW50Lmluc2VydEJlZm9yZShjaGlsZCwgc2libGluZyk7XG4gICAgICAgICAgfVxuICAgICAgICB9LFxuICAgICAgICBvbkJlZm9yZU5vZGVBZGRlZDogKGVsKSA9PiB7XG4gICAgICAgICAgLy8gZG9uJ3QgYWRkIHVwZGF0ZV9vbmx5IG5vZGVzIGlmIHRoZXkgZGlkIG5vdCBhbHJlYWR5IGV4aXN0XG4gICAgICAgICAgaWYgKFxuICAgICAgICAgICAgdGhpcy5nZXRTdHJlYW1JbnNlcnQoZWwpPy51cGRhdGVPbmx5ICYmXG4gICAgICAgICAgICAhdGhpcy5zdHJlYW1Db21wb25lbnRSZXN0b3JlW2VsLmlkXVxuICAgICAgICAgICkge1xuICAgICAgICAgICAgcmV0dXJuIGZhbHNlO1xuICAgICAgICAgIH1cblxuICAgICAgICAgIERPTS5tYWludGFpblByaXZhdGVIb29rcyhlbCwgZWwsIHBoeFZpZXdwb3J0VG9wLCBwaHhWaWV3cG9ydEJvdHRvbSk7XG4gICAgICAgICAgdGhpcy50cmFja0JlZm9yZShcImFkZGVkXCIsIGVsKTtcblxuICAgICAgICAgIGxldCBtb3JwaGVkRWwgPSBlbDtcbiAgICAgICAgICAvLyB0aGlzIGlzIGEgc3RyZWFtIGl0ZW0gdGhhdCB3YXMga2VwdCBvbiByZXNldCwgcmVjdXJzaXZlbHkgbW9ycGggaXRcbiAgICAgICAgICBpZiAodGhpcy5zdHJlYW1Db21wb25lbnRSZXN0b3JlW2VsLmlkXSkge1xuICAgICAgICAgICAgbW9ycGhlZEVsID0gdGhpcy5zdHJlYW1Db21wb25lbnRSZXN0b3JlW2VsLmlkXTtcbiAgICAgICAgICAgIGRlbGV0ZSB0aGlzLnN0cmVhbUNvbXBvbmVudFJlc3RvcmVbZWwuaWRdO1xuICAgICAgICAgICAgbW9ycGgobW9ycGhlZEVsLCBlbCwgdHJ1ZSk7XG4gICAgICAgICAgfVxuXG4gICAgICAgICAgcmV0dXJuIG1vcnBoZWRFbDtcbiAgICAgICAgfSxcbiAgICAgICAgb25Ob2RlQWRkZWQ6IChlbCkgPT4ge1xuICAgICAgICAgIGlmIChlbC5nZXRBdHRyaWJ1dGUpIHtcbiAgICAgICAgICAgIHRoaXMubWF5YmVSZU9yZGVyU3RyZWFtKGVsLCB0cnVlKTtcbiAgICAgICAgICB9XG4gICAgICAgICAgLy8gcGh4LXBvcnRhbCBoYW5kbGluZ1xuICAgICAgICAgIGlmIChET00uaXNQb3J0YWxUZW1wbGF0ZShlbCkpIHtcbiAgICAgICAgICAgIHBvcnRhbENhbGxiYWNrcy5wdXNoKCgpID0+IHRoaXMudGVsZXBvcnQoZWwsIG1vcnBoKSk7XG4gICAgICAgICAgfVxuXG4gICAgICAgICAgLy8gaGFjayB0byBmaXggU2FmYXJpIGhhbmRsaW5nIG9mIGltZyBzcmNzZXQgYW5kIHZpZGVvIHRhZ3NcbiAgICAgICAgICBpZiAoZWwgaW5zdGFuY2VvZiBIVE1MSW1hZ2VFbGVtZW50ICYmIGVsLnNyY3NldCkge1xuICAgICAgICAgICAgLy8gZXNsaW50LWRpc2FibGUtbmV4dC1saW5lIG5vLXNlbGYtYXNzaWduXG4gICAgICAgICAgICBlbC5zcmNzZXQgPSBlbC5zcmNzZXQ7XG4gICAgICAgICAgfSBlbHNlIGlmIChlbCBpbnN0YW5jZW9mIEhUTUxWaWRlb0VsZW1lbnQgJiYgZWwuYXV0b3BsYXkpIHtcbiAgICAgICAgICAgIGVsLnBsYXkoKTtcbiAgICAgICAgICB9XG4gICAgICAgICAgaWYgKERPTS5pc05vd1RyaWdnZXJGb3JtRXh0ZXJuYWwoZWwsIHBoeFRyaWdnZXJFeHRlcm5hbCkpIHtcbiAgICAgICAgICAgIGV4dGVybmFsRm9ybVRyaWdnZXJlZCA9IGVsO1xuICAgICAgICAgIH1cblxuICAgICAgICAgIC8vIG5lc3RlZCB2aWV3IGhhbmRsaW5nXG4gICAgICAgICAgaWYgKFxuICAgICAgICAgICAgKERPTS5pc1BoeENoaWxkKGVsKSAmJiB2aWV3Lm93bnNFbGVtZW50KGVsKSkgfHxcbiAgICAgICAgICAgIChET00uaXNQaHhTdGlja3koZWwpICYmIHZpZXcub3duc0VsZW1lbnQoZWwucGFyZW50Tm9kZSkpXG4gICAgICAgICAgKSB7XG4gICAgICAgICAgICB0aGlzLnRyYWNrQWZ0ZXIoXCJwaHhDaGlsZEFkZGVkXCIsIGVsKTtcbiAgICAgICAgICB9XG5cbiAgICAgICAgICAvLyBkYXRhLXBoeC1ydW50aW1lLWhvb2tcbiAgICAgICAgICBpZiAoZWwubm9kZU5hbWUgPT09IFwiU0NSSVBUXCIgJiYgZWwuaGFzQXR0cmlidXRlKFBIWF9SVU5USU1FX0hPT0spKSB7XG4gICAgICAgICAgICB0aGlzLmhhbmRsZVJ1bnRpbWVIb29rKGVsLCBzb3VyY2UpO1xuICAgICAgICAgIH1cblxuICAgICAgICAgIGFkZGVkLnB1c2goZWwpO1xuICAgICAgICB9LFxuICAgICAgICBvbk5vZGVEaXNjYXJkZWQ6IChlbCkgPT4gdGhpcy5vbk5vZGVEaXNjYXJkZWQoZWwpLFxuICAgICAgICBvbkJlZm9yZU5vZGVEaXNjYXJkZWQ6IChlbCkgPT4ge1xuICAgICAgICAgIGlmIChlbC5nZXRBdHRyaWJ1dGUgJiYgZWwuZ2V0QXR0cmlidXRlKFBIWF9QUlVORSkgIT09IG51bGwpIHtcbiAgICAgICAgICAgIHJldHVybiB0cnVlO1xuICAgICAgICAgIH1cbiAgICAgICAgICBpZiAoXG4gICAgICAgICAgICBlbC5wYXJlbnRFbGVtZW50ICE9PSBudWxsICYmXG4gICAgICAgICAgICBlbC5pZCAmJlxuICAgICAgICAgICAgRE9NLmlzUGh4VXBkYXRlKGVsLnBhcmVudEVsZW1lbnQsIHBoeFVwZGF0ZSwgW1xuICAgICAgICAgICAgICBQSFhfU1RSRUFNLFxuICAgICAgICAgICAgICBcImFwcGVuZFwiLFxuICAgICAgICAgICAgICBcInByZXBlbmRcIixcbiAgICAgICAgICAgIF0pXG4gICAgICAgICAgKSB7XG4gICAgICAgICAgICByZXR1cm4gZmFsc2U7XG4gICAgICAgICAgfVxuICAgICAgICAgIC8vIGRvbid0IHJlbW92ZSB0ZWxlcG9ydGVkIGVsZW1lbnRzXG4gICAgICAgICAgaWYgKGVsLmdldEF0dHJpYnV0ZSAmJiBlbC5nZXRBdHRyaWJ1dGUoUEhYX1RFTEVQT1JURURfUkVGKSkge1xuICAgICAgICAgICAgcmV0dXJuIGZhbHNlO1xuICAgICAgICAgIH1cbiAgICAgICAgICBpZiAodGhpcy5tYXliZVBlbmRpbmdSZW1vdmUoZWwpKSB7XG4gICAgICAgICAgICByZXR1cm4gZmFsc2U7XG4gICAgICAgICAgfVxuICAgICAgICAgIGlmICh0aGlzLnNraXBDSURTaWJsaW5nKGVsKSkge1xuICAgICAgICAgICAgcmV0dXJuIGZhbHNlO1xuICAgICAgICAgIH1cblxuICAgICAgICAgIGlmIChET00uaXNQb3J0YWxUZW1wbGF0ZShlbCkpIHtcbiAgICAgICAgICAgIC8vIGlmIHRoZSBwb3J0YWwgdGVtcGxhdGUgaXRzZWxmIGlzIHJlbW92ZWQsIHJlbW92ZSB0aGUgdGVsZXBvcnRlZCBlbGVtZW50IGFzIHdlbGw7XG4gICAgICAgICAgICAvLyB3ZSBhbHNvIHBlcmZvcm0gYSBjaGVjayBhZnRlciBtb3JwaGRvbSBpcyBmaW5pc2hlZCB0byBjYXRjaCBwYXJlbnQgcmVtb3ZhbHNcbiAgICAgICAgICAgIGNvbnN0IHRlbGVwb3J0ZWRFbCA9IGRvY3VtZW50LmdldEVsZW1lbnRCeUlkKFxuICAgICAgICAgICAgICBlbC5jb250ZW50LmZpcnN0RWxlbWVudENoaWxkLmlkLFxuICAgICAgICAgICAgKTtcbiAgICAgICAgICAgIGlmICh0ZWxlcG9ydGVkRWwpIHtcbiAgICAgICAgICAgICAgdGVsZXBvcnRlZEVsLnJlbW92ZSgpO1xuICAgICAgICAgICAgICBtb3JwaENhbGxiYWNrcy5vbk5vZGVEaXNjYXJkZWQodGVsZXBvcnRlZEVsKTtcbiAgICAgICAgICAgICAgdGhpcy52aWV3LmRyb3BQb3J0YWxFbGVtZW50SWQodGVsZXBvcnRlZEVsLmlkKTtcbiAgICAgICAgICAgIH1cbiAgICAgICAgICB9XG5cbiAgICAgICAgICByZXR1cm4gdHJ1ZTtcbiAgICAgICAgfSxcbiAgICAgICAgb25FbFVwZGF0ZWQ6IChlbCkgPT4ge1xuICAgICAgICAgIGlmIChET00uaXNOb3dUcmlnZ2VyRm9ybUV4dGVybmFsKGVsLCBwaHhUcmlnZ2VyRXh0ZXJuYWwpKSB7XG4gICAgICAgICAgICBleHRlcm5hbEZvcm1UcmlnZ2VyZWQgPSBlbDtcbiAgICAgICAgICB9XG4gICAgICAgICAgdXBkYXRlcy5wdXNoKGVsKTtcbiAgICAgICAgICB0aGlzLm1heWJlUmVPcmRlclN0cmVhbShlbCwgZmFsc2UpO1xuICAgICAgICB9LFxuICAgICAgICBvbkJlZm9yZUVsVXBkYXRlZDogKGZyb21FbCwgdG9FbCkgPT4ge1xuICAgICAgICAgIC8vIGlmIHdlIGFyZSBwYXRjaGluZyB0aGUgcm9vdCB0YXJnZXQgY29udGFpbmVyIGFuZCB0aGUgaWQgaGFzIGNoYW5nZWQsIHRyZWF0IGl0IGFzIGEgbmV3IG5vZGVcbiAgICAgICAgICAvLyBieSByZXBsYWNpbmcgdGhlIGZyb21FbCB3aXRoIHRoZSB0b0VsLCB3aGljaCBlbnN1cmVzIGhvb2tzIGFyZSB0b3JuIGRvd24gYW5kIHJlLWNyZWF0ZWRcbiAgICAgICAgICBpZiAoXG4gICAgICAgICAgICBmcm9tRWwuaWQgJiZcbiAgICAgICAgICAgIGZyb21FbC5pc1NhbWVOb2RlKHRhcmdldENvbnRhaW5lcikgJiZcbiAgICAgICAgICAgIGZyb21FbC5pZCAhPT0gdG9FbC5pZFxuICAgICAgICAgICkge1xuICAgICAgICAgICAgbW9ycGhDYWxsYmFja3Mub25Ob2RlRGlzY2FyZGVkKGZyb21FbCk7XG4gICAgICAgICAgICBmcm9tRWwucmVwbGFjZVdpdGgodG9FbCk7XG4gICAgICAgICAgICByZXR1cm4gbW9ycGhDYWxsYmFja3Mub25Ob2RlQWRkZWQodG9FbCk7XG4gICAgICAgICAgfVxuICAgICAgICAgIERPTS5zeW5jUGVuZGluZ0F0dHJzKGZyb21FbCwgdG9FbCk7XG4gICAgICAgICAgRE9NLm1haW50YWluUHJpdmF0ZUhvb2tzKFxuICAgICAgICAgICAgZnJvbUVsLFxuICAgICAgICAgICAgdG9FbCxcbiAgICAgICAgICAgIHBoeFZpZXdwb3J0VG9wLFxuICAgICAgICAgICAgcGh4Vmlld3BvcnRCb3R0b20sXG4gICAgICAgICAgKTtcbiAgICAgICAgICBET00uY2xlYW5DaGlsZE5vZGVzKHRvRWwsIHBoeFVwZGF0ZSk7XG4gICAgICAgICAgaWYgKHRoaXMuc2tpcENJRFNpYmxpbmcodG9FbCkpIHtcbiAgICAgICAgICAgIC8vIGlmIHRoaXMgaXMgYSBsaXZlIGNvbXBvbmVudCB1c2VkIGluIGEgc3RyZWFtLCB3ZSBtYXkgbmVlZCB0byByZW9yZGVyIGl0XG4gICAgICAgICAgICB0aGlzLm1heWJlUmVPcmRlclN0cmVhbShmcm9tRWwpO1xuICAgICAgICAgICAgcmV0dXJuIGZhbHNlO1xuICAgICAgICAgIH1cbiAgICAgICAgICBpZiAoRE9NLmlzUGh4U3RpY2t5KGZyb21FbCkpIHtcbiAgICAgICAgICAgIFtQSFhfU0VTU0lPTiwgUEhYX1NUQVRJQywgUEhYX1JPT1RfSURdXG4gICAgICAgICAgICAgIC5tYXAoKGF0dHIpID0+IFtcbiAgICAgICAgICAgICAgICBhdHRyLFxuICAgICAgICAgICAgICAgIGZyb21FbC5nZXRBdHRyaWJ1dGUoYXR0ciksXG4gICAgICAgICAgICAgICAgdG9FbC5nZXRBdHRyaWJ1dGUoYXR0ciksXG4gICAgICAgICAgICAgIF0pXG4gICAgICAgICAgICAgIC5mb3JFYWNoKChbYXR0ciwgZnJvbVZhbCwgdG9WYWxdKSA9PiB7XG4gICAgICAgICAgICAgICAgaWYgKHRvVmFsICYmIGZyb21WYWwgIT09IHRvVmFsKSB7XG4gICAgICAgICAgICAgICAgICBmcm9tRWwuc2V0QXR0cmlidXRlKGF0dHIsIHRvVmFsKTtcbiAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICAgIH0pO1xuXG4gICAgICAgICAgICByZXR1cm4gZmFsc2U7XG4gICAgICAgICAgfVxuICAgICAgICAgIGlmIChcbiAgICAgICAgICAgIERPTS5pc0lnbm9yZWQoZnJvbUVsLCBwaHhVcGRhdGUpIHx8XG4gICAgICAgICAgICAoZnJvbUVsLmZvcm0gJiYgZnJvbUVsLmZvcm0uaXNTYW1lTm9kZShleHRlcm5hbEZvcm1UcmlnZ2VyZWQpKVxuICAgICAgICAgICkge1xuICAgICAgICAgICAgdGhpcy50cmFja0JlZm9yZShcInVwZGF0ZWRcIiwgZnJvbUVsLCB0b0VsKTtcbiAgICAgICAgICAgIERPTS5tZXJnZUF0dHJzKGZyb21FbCwgdG9FbCwge1xuICAgICAgICAgICAgICBpc0lnbm9yZWQ6IERPTS5pc0lnbm9yZWQoZnJvbUVsLCBwaHhVcGRhdGUpLFxuICAgICAgICAgICAgfSk7XG4gICAgICAgICAgICB1cGRhdGVzLnB1c2goZnJvbUVsKTtcbiAgICAgICAgICAgIERPTS5hcHBseVN0aWNreU9wZXJhdGlvbnMoZnJvbUVsKTtcbiAgICAgICAgICAgIHJldHVybiBmYWxzZTtcbiAgICAgICAgICB9XG4gICAgICAgICAgaWYgKFxuICAgICAgICAgICAgZnJvbUVsLnR5cGUgPT09IFwibnVtYmVyXCIgJiZcbiAgICAgICAgICAgIGZyb21FbC52YWxpZGl0eSAmJlxuICAgICAgICAgICAgZnJvbUVsLnZhbGlkaXR5LmJhZElucHV0XG4gICAgICAgICAgKSB7XG4gICAgICAgICAgICByZXR1cm4gZmFsc2U7XG4gICAgICAgICAgfVxuICAgICAgICAgIC8vIElmIHRoZSBlbGVtZW50IGhhcyBQSFhfUkVGX1NSQywgaXQgaXMgbG9hZGluZyBvciBsb2NrZWQgYW5kIGF3YWl0aW5nIGFuIGFjay5cbiAgICAgICAgICAvLyBJZiBpdCdzIGxvY2tlZCwgd2UgY2xvbmUgdGhlIGZyb21FbCB0cmVlIGFuZCBpbnN0cnVjdCBtb3JwaGRvbSB0byB1c2VcbiAgICAgICAgICAvLyB0aGUgY2xvbmVkIHRyZWUgYXMgdGhlIHNvdXJjZSBvZiB0aGUgbW9ycGggZm9yIHRoaXMgYnJhbmNoIGZyb20gaGVyZSBvbiBvdXQuXG4gICAgICAgICAgLy8gV2Uga2VlcCBhIHJlZmVyZW5jZSB0byB0aGUgY2xvbmVkIHRyZWUgaW4gdGhlIGVsZW1lbnQncyBwcml2YXRlIGRhdGEsIGFuZFxuICAgICAgICAgIC8vIG9uIGFjayAodmlldy51bmRvUmVmcyksIHdlIG1vcnBoIHRoZSBjbG9uZWQgdHJlZSB3aXRoIHRoZSB0cnVlIGZyb21FbCBpbiB0aGUgRE9NIHRvXG4gICAgICAgICAgLy8gYXBwbHkgYW55IGNoYW5nZXMgdGhhdCBoYXBwZW5lZCB3aGlsZSB0aGUgZWxlbWVudCB3YXMgbG9ja2VkLlxuICAgICAgICAgIGNvbnN0IGlzRm9jdXNlZEZvcm1FbCA9XG4gICAgICAgICAgICBmb2N1c2VkICYmIGZyb21FbC5pc1NhbWVOb2RlKGZvY3VzZWQpICYmIERPTS5pc0Zvcm1JbnB1dChmcm9tRWwpO1xuICAgICAgICAgIGNvbnN0IGZvY3VzZWRTZWxlY3RDaGFuZ2VkID1cbiAgICAgICAgICAgIGlzRm9jdXNlZEZvcm1FbCAmJiB0aGlzLmlzQ2hhbmdlZFNlbGVjdChmcm9tRWwsIHRvRWwpO1xuICAgICAgICAgIGlmIChmcm9tRWwuaGFzQXR0cmlidXRlKFBIWF9SRUZfU1JDKSkge1xuICAgICAgICAgICAgY29uc3QgcmVmID0gbmV3IEVsZW1lbnRSZWYoZnJvbUVsKTtcbiAgICAgICAgICAgIC8vIG9ubHkgcGVyZm9ybSB0aGUgY2xvbmUgc3RlcCBpZiB0aGlzIGlzIG5vdCBhIHBhdGNoIHRoYXQgdW5sb2Nrc1xuICAgICAgICAgICAgaWYgKFxuICAgICAgICAgICAgICByZWYubG9ja1JlZiAmJlxuICAgICAgICAgICAgICAoIXRoaXMudW5kb1JlZiB8fCAhcmVmLmlzTG9ja1VuZG9uZUJ5KHRoaXMudW5kb1JlZikpXG4gICAgICAgICAgICApIHtcbiAgICAgICAgICAgICAgaWYgKERPTS5pc1VwbG9hZElucHV0KGZyb21FbCkpIHtcbiAgICAgICAgICAgICAgICBET00ubWVyZ2VBdHRycyhmcm9tRWwsIHRvRWwsIHsgaXNJZ25vcmVkOiB0cnVlIH0pO1xuICAgICAgICAgICAgICAgIHRoaXMudHJhY2tCZWZvcmUoXCJ1cGRhdGVkXCIsIGZyb21FbCwgdG9FbCk7XG4gICAgICAgICAgICAgICAgdXBkYXRlcy5wdXNoKGZyb21FbCk7XG4gICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgRE9NLmFwcGx5U3RpY2t5T3BlcmF0aW9ucyhmcm9tRWwpO1xuICAgICAgICAgICAgICBjb25zdCBpc0xvY2tlZCA9IGZyb21FbC5oYXNBdHRyaWJ1dGUoUEhYX1JFRl9MT0NLKTtcbiAgICAgICAgICAgICAgY29uc3QgY2xvbmUgPSBpc0xvY2tlZFxuICAgICAgICAgICAgICAgID8gRE9NLnByaXZhdGUoZnJvbUVsLCBQSFhfUkVGX0xPQ0spIHx8IGZyb21FbC5jbG9uZU5vZGUodHJ1ZSlcbiAgICAgICAgICAgICAgICA6IG51bGw7XG4gICAgICAgICAgICAgIGlmIChjbG9uZSkge1xuICAgICAgICAgICAgICAgIERPTS5wdXRQcml2YXRlKGZyb21FbCwgUEhYX1JFRl9MT0NLLCBjbG9uZSk7XG4gICAgICAgICAgICAgICAgaWYgKCFpc0ZvY3VzZWRGb3JtRWwpIHtcbiAgICAgICAgICAgICAgICAgIGZyb21FbCA9IGNsb25lO1xuICAgICAgICAgICAgICAgIH1cbiAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgfVxuICAgICAgICAgIH1cblxuICAgICAgICAgIC8vIG5lc3RlZCB2aWV3IGhhbmRsaW5nXG4gICAgICAgICAgaWYgKERPTS5pc1BoeENoaWxkKHRvRWwpKSB7XG4gICAgICAgICAgICBjb25zdCBwcmV2U2Vzc2lvbiA9IGZyb21FbC5nZXRBdHRyaWJ1dGUoUEhYX1NFU1NJT04pO1xuICAgICAgICAgICAgRE9NLm1lcmdlQXR0cnMoZnJvbUVsLCB0b0VsLCB7IGV4Y2x1ZGU6IFtQSFhfU1RBVElDXSB9KTtcbiAgICAgICAgICAgIGlmIChwcmV2U2Vzc2lvbiAhPT0gXCJcIikge1xuICAgICAgICAgICAgICBmcm9tRWwuc2V0QXR0cmlidXRlKFBIWF9TRVNTSU9OLCBwcmV2U2Vzc2lvbik7XG4gICAgICAgICAgICB9XG4gICAgICAgICAgICBmcm9tRWwuc2V0QXR0cmlidXRlKFBIWF9ST09UX0lELCB0aGlzLnJvb3RJRCk7XG4gICAgICAgICAgICBET00uYXBwbHlTdGlja3lPcGVyYXRpb25zKGZyb21FbCk7XG4gICAgICAgICAgICByZXR1cm4gZmFsc2U7XG4gICAgICAgICAgfVxuXG4gICAgICAgICAgLy8gaWYgd2UgYXJlIHVuZG9pbmcgYSBsb2NrLCBjb3B5IHBvdGVudGlhbGx5IG5lc3RlZCBjbG9uZXMgb3ZlclxuICAgICAgICAgIGlmICh0aGlzLnVuZG9SZWYgJiYgRE9NLnByaXZhdGUodG9FbCwgUEhYX1JFRl9MT0NLKSkge1xuICAgICAgICAgICAgRE9NLnB1dFByaXZhdGUoXG4gICAgICAgICAgICAgIGZyb21FbCxcbiAgICAgICAgICAgICAgUEhYX1JFRl9MT0NLLFxuICAgICAgICAgICAgICBET00ucHJpdmF0ZSh0b0VsLCBQSFhfUkVGX0xPQ0spLFxuICAgICAgICAgICAgKTtcbiAgICAgICAgICB9XG4gICAgICAgICAgLy8gbm93IGNvcHkgcmVndWxhciBET00ucHJpdmF0ZSBkYXRhXG4gICAgICAgICAgRE9NLmNvcHlQcml2YXRlcyh0b0VsLCBmcm9tRWwpO1xuXG4gICAgICAgICAgLy8gcGh4LXBvcnRhbCBoYW5kbGluZ1xuICAgICAgICAgIGlmIChET00uaXNQb3J0YWxUZW1wbGF0ZSh0b0VsKSkge1xuICAgICAgICAgICAgcG9ydGFsQ2FsbGJhY2tzLnB1c2goKCkgPT4gdGhpcy50ZWxlcG9ydCh0b0VsLCBtb3JwaCkpO1xuICAgICAgICAgICAgcmV0dXJuIGZhbHNlO1xuICAgICAgICAgIH1cblxuICAgICAgICAgIC8vIHNraXAgcGF0Y2hpbmcgZm9jdXNlZCBpbnB1dHMgdW5sZXNzIGZvY3VzIGlzIGEgc2VsZWN0IHRoYXQgaGFzIGNoYW5nZWQgb3B0aW9uc1xuICAgICAgICAgIGlmIChcbiAgICAgICAgICAgIGlzRm9jdXNlZEZvcm1FbCAmJlxuICAgICAgICAgICAgZnJvbUVsLnR5cGUgIT09IFwiaGlkZGVuXCIgJiZcbiAgICAgICAgICAgICFmb2N1c2VkU2VsZWN0Q2hhbmdlZFxuICAgICAgICAgICkge1xuICAgICAgICAgICAgdGhpcy50cmFja0JlZm9yZShcInVwZGF0ZWRcIiwgZnJvbUVsLCB0b0VsKTtcbiAgICAgICAgICAgIERPTS5tZXJnZUZvY3VzZWRJbnB1dChmcm9tRWwsIHRvRWwpO1xuICAgICAgICAgICAgRE9NLnN5bmNBdHRyc1RvUHJvcHMoZnJvbUVsKTtcbiAgICAgICAgICAgIHVwZGF0ZXMucHVzaChmcm9tRWwpO1xuICAgICAgICAgICAgRE9NLmFwcGx5U3RpY2t5T3BlcmF0aW9ucyhmcm9tRWwpO1xuICAgICAgICAgICAgcmV0dXJuIGZhbHNlO1xuICAgICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgICAvLyBibHVyIGZvY3VzZWQgc2VsZWN0IGlmIGl0IGNoYW5nZWQgc28gbmF0aXZlIFVJIGlzIHVwZGF0ZWQgKGllIHNhZmFyaSB3b24ndCB1cGRhdGUgdmlzaWJsZSBvcHRpb25zKVxuICAgICAgICAgICAgaWYgKGZvY3VzZWRTZWxlY3RDaGFuZ2VkKSB7XG4gICAgICAgICAgICAgIGZyb21FbC5ibHVyKCk7XG4gICAgICAgICAgICB9XG4gICAgICAgICAgICBpZiAoRE9NLmlzUGh4VXBkYXRlKHRvRWwsIHBoeFVwZGF0ZSwgW1wiYXBwZW5kXCIsIFwicHJlcGVuZFwiXSkpIHtcbiAgICAgICAgICAgICAgYXBwZW5kUHJlcGVuZFVwZGF0ZXMucHVzaChcbiAgICAgICAgICAgICAgICBuZXcgRE9NUG9zdE1vcnBoUmVzdG9yZXIoXG4gICAgICAgICAgICAgICAgICBmcm9tRWwsXG4gICAgICAgICAgICAgICAgICB0b0VsLFxuICAgICAgICAgICAgICAgICAgdG9FbC5nZXRBdHRyaWJ1dGUocGh4VXBkYXRlKSxcbiAgICAgICAgICAgICAgICApLFxuICAgICAgICAgICAgICApO1xuICAgICAgICAgICAgfVxuXG4gICAgICAgICAgICBET00uc3luY0F0dHJzVG9Qcm9wcyh0b0VsKTtcbiAgICAgICAgICAgIERPTS5hcHBseVN0aWNreU9wZXJhdGlvbnModG9FbCk7XG4gICAgICAgICAgICB0aGlzLnRyYWNrQmVmb3JlKFwidXBkYXRlZFwiLCBmcm9tRWwsIHRvRWwpO1xuICAgICAgICAgICAgcmV0dXJuIGZyb21FbDtcbiAgICAgICAgICB9XG4gICAgICAgIH0sXG4gICAgICB9O1xuXG4gICAgICBtb3JwaGRvbSh0YXJnZXRDb250YWluZXIsIHNvdXJjZSwgbW9ycGhDYWxsYmFja3MpO1xuICAgIH07XG5cbiAgICB0aGlzLnRyYWNrQmVmb3JlKFwiYWRkZWRcIiwgY29udGFpbmVyKTtcbiAgICB0aGlzLnRyYWNrQmVmb3JlKFwidXBkYXRlZFwiLCBjb250YWluZXIsIGNvbnRhaW5lcik7XG5cbiAgICBsaXZlU29ja2V0LnRpbWUoXCJtb3JwaGRvbVwiLCAoKSA9PiB7XG4gICAgICB0aGlzLnN0cmVhbXMuZm9yRWFjaCgoW3JlZiwgaW5zZXJ0cywgZGVsZXRlSWRzLCByZXNldF0pID0+IHtcbiAgICAgICAgaW5zZXJ0cy5mb3JFYWNoKChba2V5LCBzdHJlYW1BdCwgbGltaXQsIHVwZGF0ZU9ubHldKSA9PiB7XG4gICAgICAgICAgdGhpcy5zdHJlYW1JbnNlcnRzW2tleV0gPSB7IHJlZiwgc3RyZWFtQXQsIGxpbWl0LCByZXNldCwgdXBkYXRlT25seSB9O1xuICAgICAgICB9KTtcbiAgICAgICAgaWYgKHJlc2V0ICE9PSB1bmRlZmluZWQpIHtcbiAgICAgICAgICBET00uYWxsKGNvbnRhaW5lciwgYFske1BIWF9TVFJFQU1fUkVGfT1cIiR7cmVmfVwiXWAsIChjaGlsZCkgPT4ge1xuICAgICAgICAgICAgdGhpcy5yZW1vdmVTdHJlYW1DaGlsZEVsZW1lbnQoY2hpbGQpO1xuICAgICAgICAgIH0pO1xuICAgICAgICB9XG4gICAgICAgIGRlbGV0ZUlkcy5mb3JFYWNoKChpZCkgPT4ge1xuICAgICAgICAgIGNvbnN0IGNoaWxkID0gY29udGFpbmVyLnF1ZXJ5U2VsZWN0b3IoYFtpZD1cIiR7aWR9XCJdYCk7XG4gICAgICAgICAgaWYgKGNoaWxkKSB7XG4gICAgICAgICAgICB0aGlzLnJlbW92ZVN0cmVhbUNoaWxkRWxlbWVudChjaGlsZCk7XG4gICAgICAgICAgfVxuICAgICAgICB9KTtcbiAgICAgIH0pO1xuXG4gICAgICAvLyBjbGVhciBzdHJlYW0gaXRlbXMgZnJvbSB0aGUgZGVhZCByZW5kZXIgaWYgdGhleSBhcmUgbm90IGluc2VydGVkIGFnYWluXG4gICAgICBpZiAoaXNKb2luUGF0Y2gpIHtcbiAgICAgICAgRE9NLmFsbCh0aGlzLmNvbnRhaW5lciwgYFske3BoeFVwZGF0ZX09JHtQSFhfU1RSRUFNfV1gKVxuICAgICAgICAgIC8vIGl0IGlzIGltcG9ydGFudCB0byBmaWx0ZXIgdGhlIGVsZW1lbnQgYmVmb3JlIHJlbW92aW5nIHRoZW0sIGFzXG4gICAgICAgICAgLy8gaXQgbWF5IGhhcHBlbiB0aGF0IHN0cmVhbXMgYXJlIG5lc3RlZCBhbmQgdGhlIG93bmVyIGNoZWNrIGZhaWxzIGlmXG4gICAgICAgICAgLy8gYSBwYXJlbnQgaXMgcmVtb3ZlZCBiZWZvcmUgYSBjaGlsZFxuICAgICAgICAgIC5maWx0ZXIoKGVsKSA9PiB0aGlzLnZpZXcub3duc0VsZW1lbnQoZWwpKVxuICAgICAgICAgIC5mb3JFYWNoKChlbCkgPT4ge1xuICAgICAgICAgICAgQXJyYXkuZnJvbShlbC5jaGlsZHJlbikuZm9yRWFjaCgoY2hpbGQpID0+IHtcbiAgICAgICAgICAgICAgLy8gd2UgYWxyZWFkeSBwZXJmb3JtZWQgdGhlIG93bmVyIGNoZWNrLCBlYWNoIGNoaWxkIGlzIGd1YXJhbnRlZWQgdG8gYmUgb3duZWRcbiAgICAgICAgICAgICAgLy8gYnkgdGhlIHZpZXcuIFRvIHByZXZlbnQgdGhlIG5lc3RlZCBvd25lciBjaGVjayBmcm9tIGZhaWxpbmcgaW4gY2FzZSBvZiBuZXN0ZWRcbiAgICAgICAgICAgICAgLy8gc3RyZWFtcyB3aGVyZSB0aGUgcGFyZW50IGlzIHJlbW92ZWQgYmVmb3JlIHRoZSBjaGlsZCwgd2UgZm9yY2UgdGhlIHJlbW92YWxcbiAgICAgICAgICAgICAgdGhpcy5yZW1vdmVTdHJlYW1DaGlsZEVsZW1lbnQoY2hpbGQsIHRydWUpO1xuICAgICAgICAgICAgfSk7XG4gICAgICAgICAgfSk7XG4gICAgICB9XG5cbiAgICAgIG1vcnBoKHRhcmdldENvbnRhaW5lciwgaHRtbCk7XG4gICAgICAvLyBub3JtYWwgcGF0Y2ggY29tcGxldGUsIHRlbGVwb3J0IGVsZW1lbnRzIG5vd1xuICAgICAgcG9ydGFsQ2FsbGJhY2tzLmZvckVhY2goKGNhbGxiYWNrKSA9PiBjYWxsYmFjaygpKTtcbiAgICAgIC8vIGNoZWNrIGZvciBhbnkgdGVsZXBvcnRlZCBlbGVtZW50cyB0aGF0IGFyZSBub3QgaW4gdGhlIHZpZXcgYW55IG1vcmVcbiAgICAgIC8vIGFuZCByZW1vdmUgdGhlbVxuICAgICAgdGhpcy52aWV3LnBvcnRhbEVsZW1lbnRJZHMuZm9yRWFjaCgoaWQpID0+IHtcbiAgICAgICAgY29uc3QgZWwgPSBkb2N1bWVudC5nZXRFbGVtZW50QnlJZChpZCk7XG4gICAgICAgIGlmIChlbCkge1xuICAgICAgICAgIGNvbnN0IHNvdXJjZSA9IGRvY3VtZW50LmdldEVsZW1lbnRCeUlkKFxuICAgICAgICAgICAgZWwuZ2V0QXR0cmlidXRlKFBIWF9URUxFUE9SVEVEX1NSQyksXG4gICAgICAgICAgKTtcbiAgICAgICAgICBpZiAoIXNvdXJjZSkge1xuICAgICAgICAgICAgZWwucmVtb3ZlKCk7XG4gICAgICAgICAgICB0aGlzLm9uTm9kZURpc2NhcmRlZChlbCk7XG4gICAgICAgICAgICB0aGlzLnZpZXcuZHJvcFBvcnRhbEVsZW1lbnRJZChpZCk7XG4gICAgICAgICAgfVxuICAgICAgICB9XG4gICAgICB9KTtcbiAgICB9KTtcblxuICAgIGlmIChsaXZlU29ja2V0LmlzRGVidWdFbmFibGVkKCkpIHtcbiAgICAgIGRldGVjdER1cGxpY2F0ZUlkcygpO1xuICAgICAgZGV0ZWN0SW52YWxpZFN0cmVhbUluc2VydHModGhpcy5zdHJlYW1JbnNlcnRzKTtcbiAgICAgIC8vIHdhcm4gaWYgdGhlcmUgYXJlIGFueSBpbnB1dHMgbmFtZWQgXCJpZFwiXG4gICAgICBBcnJheS5mcm9tKGRvY3VtZW50LnF1ZXJ5U2VsZWN0b3JBbGwoXCJpbnB1dFtuYW1lPWlkXVwiKSkuZm9yRWFjaChcbiAgICAgICAgKG5vZGUpID0+IHtcbiAgICAgICAgICBpZiAobm9kZSBpbnN0YW5jZW9mIEhUTUxJbnB1dEVsZW1lbnQgJiYgbm9kZS5mb3JtKSB7XG4gICAgICAgICAgICBjb25zb2xlLmVycm9yKFxuICAgICAgICAgICAgICAnRGV0ZWN0ZWQgYW4gaW5wdXQgd2l0aCBuYW1lPVwiaWRcIiBpbnNpZGUgYSBmb3JtISBUaGlzIHdpbGwgY2F1c2UgcHJvYmxlbXMgd2hlbiBwYXRjaGluZyB0aGUgRE9NLlxcbicsXG4gICAgICAgICAgICAgIG5vZGUsXG4gICAgICAgICAgICApO1xuICAgICAgICAgIH1cbiAgICAgICAgfSxcbiAgICAgICk7XG4gICAgfVxuXG4gICAgaWYgKGFwcGVuZFByZXBlbmRVcGRhdGVzLmxlbmd0aCA+IDApIHtcbiAgICAgIGxpdmVTb2NrZXQudGltZShcInBvc3QtbW9ycGggYXBwZW5kL3ByZXBlbmQgcmVzdG9yYXRpb25cIiwgKCkgPT4ge1xuICAgICAgICBhcHBlbmRQcmVwZW5kVXBkYXRlcy5mb3JFYWNoKCh1cGRhdGUpID0+IHVwZGF0ZS5wZXJmb3JtKCkpO1xuICAgICAgfSk7XG4gICAgfVxuXG4gICAgbGl2ZVNvY2tldC5zaWxlbmNlRXZlbnRzKCgpID0+XG4gICAgICBET00ucmVzdG9yZUZvY3VzKGZvY3VzZWQsIHNlbGVjdGlvblN0YXJ0LCBzZWxlY3Rpb25FbmQpLFxuICAgICk7XG4gICAgRE9NLmRpc3BhdGNoRXZlbnQoZG9jdW1lbnQsIFwicGh4OnVwZGF0ZVwiKTtcbiAgICBhZGRlZC5mb3JFYWNoKChlbCkgPT4gdGhpcy50cmFja0FmdGVyKFwiYWRkZWRcIiwgZWwpKTtcbiAgICB1cGRhdGVzLmZvckVhY2goKGVsKSA9PiB0aGlzLnRyYWNrQWZ0ZXIoXCJ1cGRhdGVkXCIsIGVsKSk7XG5cbiAgICB0aGlzLnRyYW5zaXRpb25QZW5kaW5nUmVtb3ZlcygpO1xuXG4gICAgaWYgKGV4dGVybmFsRm9ybVRyaWdnZXJlZCkge1xuICAgICAgbGl2ZVNvY2tldC51bmxvYWQoKTtcbiAgICAgIC8vIGNoZWNrIGZvciBzdWJtaXR0ZXIgYW5kIGluamVjdCBpdCBhcyBoaWRkZW4gaW5wdXQgZm9yIGV4dGVybmFsIHN1Ym1pdDtcbiAgICAgIC8vIEluIHRoZW9yeSwgaXQgY291bGQgaGFwcGVuIHRoYXQgdGhlIHN0b3JlZCBzdWJtaXR0ZXIgaXMgb3V0ZGF0ZWQgYW5kIGRvZXNuJ3RcbiAgICAgIC8vIGV4aXN0IGluIHRoZSBET00gYW55IG1vcmUsIGJ1dCB0aGlzIGlzIHVubGlrZWx5LCBzbyB3ZSBqdXN0IGFjY2VwdCBpdCBmb3Igbm93LlxuICAgICAgY29uc3Qgc3VibWl0dGVyID0gRE9NLnByaXZhdGUoZXh0ZXJuYWxGb3JtVHJpZ2dlcmVkLCBcInN1Ym1pdHRlclwiKTtcbiAgICAgIGlmIChzdWJtaXR0ZXIgJiYgc3VibWl0dGVyLm5hbWUgJiYgdGFyZ2V0Q29udGFpbmVyLmNvbnRhaW5zKHN1Ym1pdHRlcikpIHtcbiAgICAgICAgY29uc3QgaW5wdXQgPSBkb2N1bWVudC5jcmVhdGVFbGVtZW50KFwiaW5wdXRcIik7XG4gICAgICAgIGlucHV0LnR5cGUgPSBcImhpZGRlblwiO1xuICAgICAgICBjb25zdCBmb3JtSWQgPSBzdWJtaXR0ZXIuZ2V0QXR0cmlidXRlKFwiZm9ybVwiKTtcbiAgICAgICAgaWYgKGZvcm1JZCkge1xuICAgICAgICAgIGlucHV0LnNldEF0dHJpYnV0ZShcImZvcm1cIiwgZm9ybUlkKTtcbiAgICAgICAgfVxuICAgICAgICBpbnB1dC5uYW1lID0gc3VibWl0dGVyLm5hbWU7XG4gICAgICAgIGlucHV0LnZhbHVlID0gc3VibWl0dGVyLnZhbHVlO1xuICAgICAgICBzdWJtaXR0ZXIucGFyZW50RWxlbWVudC5pbnNlcnRCZWZvcmUoaW5wdXQsIHN1Ym1pdHRlcik7XG4gICAgICB9XG4gICAgICAvLyB1c2UgcHJvdG90eXBlJ3Mgc3VibWl0IGluIGNhc2UgdGhlcmUncyBhIGZvcm0gY29udHJvbCB3aXRoIG5hbWUgb3IgaWQgb2YgXCJzdWJtaXRcIlxuICAgICAgLy8gaHR0cHM6Ly9kZXZlbG9wZXIubW96aWxsYS5vcmcvZW4tVVMvZG9jcy9XZWIvQVBJL0hUTUxGb3JtRWxlbWVudC9zdWJtaXRcbiAgICAgIE9iamVjdC5nZXRQcm90b3R5cGVPZihleHRlcm5hbEZvcm1UcmlnZ2VyZWQpLnN1Ym1pdC5jYWxsKFxuICAgICAgICBleHRlcm5hbEZvcm1UcmlnZ2VyZWQsXG4gICAgICApO1xuICAgIH1cbiAgICByZXR1cm4gdHJ1ZTtcbiAgfVxuXG4gIG9uTm9kZURpc2NhcmRlZChlbCkge1xuICAgIC8vIG5lc3RlZCB2aWV3IGhhbmRsaW5nXG4gICAgaWYgKERPTS5pc1BoeENoaWxkKGVsKSB8fCBET00uaXNQaHhTdGlja3koZWwpKSB7XG4gICAgICB0aGlzLmxpdmVTb2NrZXQuZGVzdHJveVZpZXdCeUVsKGVsKTtcbiAgICB9XG4gICAgdGhpcy50cmFja0FmdGVyKFwiZGlzY2FyZGVkXCIsIGVsKTtcbiAgfVxuXG4gIG1heWJlUGVuZGluZ1JlbW92ZShub2RlKSB7XG4gICAgaWYgKG5vZGUuZ2V0QXR0cmlidXRlICYmIG5vZGUuZ2V0QXR0cmlidXRlKHRoaXMucGh4UmVtb3ZlKSAhPT0gbnVsbCkge1xuICAgICAgdGhpcy5wZW5kaW5nUmVtb3Zlcy5wdXNoKG5vZGUpO1xuICAgICAgcmV0dXJuIHRydWU7XG4gICAgfSBlbHNlIHtcbiAgICAgIHJldHVybiBmYWxzZTtcbiAgICB9XG4gIH1cblxuICByZW1vdmVTdHJlYW1DaGlsZEVsZW1lbnQoY2hpbGQsIGZvcmNlID0gZmFsc2UpIHtcbiAgICAvLyBtYWtlIHN1cmUgdG8gb25seSByZW1vdmUgZWxlbWVudHMgb3duZWQgYnkgdGhlIGN1cnJlbnQgdmlld1xuICAgIC8vIHNlZSBodHRwczovL2dpdGh1Yi5jb20vcGhvZW5peGZyYW1ld29yay9waG9lbml4X2xpdmVfdmlldy9pc3N1ZXMvMzA0N1xuICAgIC8vIGFuZCBodHRwczovL2dpdGh1Yi5jb20vcGhvZW5peGZyYW1ld29yay9waG9lbml4X2xpdmVfdmlldy9pc3N1ZXMvMzY4MVxuICAgIGlmICghZm9yY2UgJiYgIXRoaXMudmlldy5vd25zRWxlbWVudChjaGlsZCkpIHtcbiAgICAgIHJldHVybjtcbiAgICB9XG5cbiAgICAvLyB3ZSBuZWVkIHRvIHN0b3JlIHRoZSBub2RlIGlmIGl0IGlzIGFjdHVhbGx5IHJlLWFkZGVkIGluIHRoZSBzYW1lIHBhdGNoXG4gICAgLy8gd2UgZG8gTk9UIHdhbnQgdG8gZXhlY3V0ZSBwaHgtcmVtb3ZlLCB3ZSBkbyBOT1Qgd2FudCB0byBjYWxsIG9uTm9kZURpc2NhcmRlZFxuICAgIGlmICh0aGlzLnN0cmVhbUluc2VydHNbY2hpbGQuaWRdKSB7XG4gICAgICB0aGlzLnN0cmVhbUNvbXBvbmVudFJlc3RvcmVbY2hpbGQuaWRdID0gY2hpbGQ7XG4gICAgICBjaGlsZC5yZW1vdmUoKTtcbiAgICB9IGVsc2Uge1xuICAgICAgLy8gb25seSByZW1vdmUgdGhlIGVsZW1lbnQgbm93IGlmIGl0IGhhcyBubyBwaHgtcmVtb3ZlIGJpbmRpbmdcbiAgICAgIGlmICghdGhpcy5tYXliZVBlbmRpbmdSZW1vdmUoY2hpbGQpKSB7XG4gICAgICAgIGNoaWxkLnJlbW92ZSgpO1xuICAgICAgICB0aGlzLm9uTm9kZURpc2NhcmRlZChjaGlsZCk7XG4gICAgICB9XG4gICAgfVxuICB9XG5cbiAgZ2V0U3RyZWFtSW5zZXJ0KGVsKSB7XG4gICAgY29uc3QgaW5zZXJ0ID0gZWwuaWQgPyB0aGlzLnN0cmVhbUluc2VydHNbZWwuaWRdIDoge307XG4gICAgcmV0dXJuIGluc2VydCB8fCB7fTtcbiAgfVxuXG4gIHNldFN0cmVhbVJlZihlbCwgcmVmKSB7XG4gICAgRE9NLnB1dFN0aWNreShlbCwgUEhYX1NUUkVBTV9SRUYsIChlbCkgPT5cbiAgICAgIGVsLnNldEF0dHJpYnV0ZShQSFhfU1RSRUFNX1JFRiwgcmVmKSxcbiAgICApO1xuICB9XG5cbiAgbWF5YmVSZU9yZGVyU3RyZWFtKGVsLCBpc05ldykge1xuICAgIGNvbnN0IHsgcmVmLCBzdHJlYW1BdCwgcmVzZXQgfSA9IHRoaXMuZ2V0U3RyZWFtSW5zZXJ0KGVsKTtcbiAgICBpZiAoc3RyZWFtQXQgPT09IHVuZGVmaW5lZCkge1xuICAgICAgcmV0dXJuO1xuICAgIH1cblxuICAgIC8vIHdlIG5lZWQgdG8gc2V0IHRoZSBQSFhfU1RSRUFNX1JFRiBoZXJlIGFzIHdlbGwgYXMgYWRkQ2hpbGQgaXMgaW52b2tlZCBvbmx5IGZvciBwYXJlbnRzXG4gICAgdGhpcy5zZXRTdHJlYW1SZWYoZWwsIHJlZik7XG5cbiAgICBpZiAoIXJlc2V0ICYmICFpc05ldykge1xuICAgICAgLy8gd2Ugb25seSByZW9yZGVyIGlmIHRoZSBlbGVtZW50IGlzIG5ldyBvciBpdCdzIGEgc3RyZWFtIHJlc2V0XG4gICAgICByZXR1cm47XG4gICAgfVxuXG4gICAgLy8gY2hlY2sgaWYgdGhlIGVsZW1lbnQgaGFzIGEgcGFyZW50IGVsZW1lbnQ7XG4gICAgLy8gaXQgZG9lc24ndCBpZiB3ZSBhcmUgY3VycmVudGx5IHJlY3Vyc2l2ZWx5IG1vcnBoaW5nIChyZXN0b3JpbmcgYSBzYXZlZCBzdHJlYW0gY2hpbGQpXG4gICAgLy8gYmVjYXVzZSB0aGUgZWxlbWVudCBpcyBub3QgeWV0IGFkZGVkIHRvIHRoZSByZWFsIGRvbTtcbiAgICAvLyByZW9yZGVyaW5nIGRvZXMgbm90IG1ha2Ugc2Vuc2UgaW4gdGhhdCBjYXNlIGFueXdheVxuICAgIGlmICghZWwucGFyZW50RWxlbWVudCkge1xuICAgICAgcmV0dXJuO1xuICAgIH1cblxuICAgIGlmIChzdHJlYW1BdCA9PT0gMCkge1xuICAgICAgZWwucGFyZW50RWxlbWVudC5pbnNlcnRCZWZvcmUoZWwsIGVsLnBhcmVudEVsZW1lbnQuZmlyc3RFbGVtZW50Q2hpbGQpO1xuICAgIH0gZWxzZSBpZiAoc3RyZWFtQXQgPiAwKSB7XG4gICAgICBjb25zdCBjaGlsZHJlbiA9IEFycmF5LmZyb20oZWwucGFyZW50RWxlbWVudC5jaGlsZHJlbik7XG4gICAgICBjb25zdCBvbGRJbmRleCA9IGNoaWxkcmVuLmluZGV4T2YoZWwpO1xuICAgICAgaWYgKHN0cmVhbUF0ID49IGNoaWxkcmVuLmxlbmd0aCAtIDEpIHtcbiAgICAgICAgZWwucGFyZW50RWxlbWVudC5hcHBlbmRDaGlsZChlbCk7XG4gICAgICB9IGVsc2Uge1xuICAgICAgICBjb25zdCBzaWJsaW5nID0gY2hpbGRyZW5bc3RyZWFtQXRdO1xuICAgICAgICBpZiAob2xkSW5kZXggPiBzdHJlYW1BdCkge1xuICAgICAgICAgIGVsLnBhcmVudEVsZW1lbnQuaW5zZXJ0QmVmb3JlKGVsLCBzaWJsaW5nKTtcbiAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICBlbC5wYXJlbnRFbGVtZW50Lmluc2VydEJlZm9yZShlbCwgc2libGluZy5uZXh0RWxlbWVudFNpYmxpbmcpO1xuICAgICAgICB9XG4gICAgICB9XG4gICAgfVxuXG4gICAgdGhpcy5tYXliZUxpbWl0U3RyZWFtKGVsKTtcbiAgfVxuXG4gIG1heWJlTGltaXRTdHJlYW0oZWwpIHtcbiAgICBjb25zdCB7IGxpbWl0IH0gPSB0aGlzLmdldFN0cmVhbUluc2VydChlbCk7XG4gICAgY29uc3QgY2hpbGRyZW4gPSBsaW1pdCAhPT0gbnVsbCAmJiBBcnJheS5mcm9tKGVsLnBhcmVudEVsZW1lbnQuY2hpbGRyZW4pO1xuICAgIGlmIChsaW1pdCAmJiBsaW1pdCA8IDAgJiYgY2hpbGRyZW4ubGVuZ3RoID4gbGltaXQgKiAtMSkge1xuICAgICAgY2hpbGRyZW5cbiAgICAgICAgLnNsaWNlKDAsIGNoaWxkcmVuLmxlbmd0aCArIGxpbWl0KVxuICAgICAgICAuZm9yRWFjaCgoY2hpbGQpID0+IHRoaXMucmVtb3ZlU3RyZWFtQ2hpbGRFbGVtZW50KGNoaWxkKSk7XG4gICAgfSBlbHNlIGlmIChsaW1pdCAmJiBsaW1pdCA+PSAwICYmIGNoaWxkcmVuLmxlbmd0aCA+IGxpbWl0KSB7XG4gICAgICBjaGlsZHJlblxuICAgICAgICAuc2xpY2UobGltaXQpXG4gICAgICAgIC5mb3JFYWNoKChjaGlsZCkgPT4gdGhpcy5yZW1vdmVTdHJlYW1DaGlsZEVsZW1lbnQoY2hpbGQpKTtcbiAgICB9XG4gIH1cblxuICB0cmFuc2l0aW9uUGVuZGluZ1JlbW92ZXMoKSB7XG4gICAgY29uc3QgeyBwZW5kaW5nUmVtb3ZlcywgbGl2ZVNvY2tldCB9ID0gdGhpcztcbiAgICBpZiAocGVuZGluZ1JlbW92ZXMubGVuZ3RoID4gMCkge1xuICAgICAgbGl2ZVNvY2tldC50cmFuc2l0aW9uUmVtb3ZlcyhwZW5kaW5nUmVtb3ZlcywgKCkgPT4ge1xuICAgICAgICBwZW5kaW5nUmVtb3Zlcy5mb3JFYWNoKChlbCkgPT4ge1xuICAgICAgICAgIGNvbnN0IGNoaWxkID0gRE9NLmZpcnN0UGh4Q2hpbGQoZWwpO1xuICAgICAgICAgIGlmIChjaGlsZCkge1xuICAgICAgICAgICAgbGl2ZVNvY2tldC5kZXN0cm95Vmlld0J5RWwoY2hpbGQpO1xuICAgICAgICAgIH1cbiAgICAgICAgICBlbC5yZW1vdmUoKTtcbiAgICAgICAgfSk7XG4gICAgICAgIHRoaXMudHJhY2tBZnRlcihcInRyYW5zaXRpb25zRGlzY2FyZGVkXCIsIHBlbmRpbmdSZW1vdmVzKTtcbiAgICAgIH0pO1xuICAgIH1cbiAgfVxuXG4gIGlzQ2hhbmdlZFNlbGVjdChmcm9tRWwsIHRvRWwpIHtcbiAgICBpZiAoIShmcm9tRWwgaW5zdGFuY2VvZiBIVE1MU2VsZWN0RWxlbWVudCkgfHwgZnJvbUVsLm11bHRpcGxlKSB7XG4gICAgICByZXR1cm4gZmFsc2U7XG4gICAgfVxuICAgIGlmIChmcm9tRWwub3B0aW9ucy5sZW5ndGggIT09IHRvRWwub3B0aW9ucy5sZW5ndGgpIHtcbiAgICAgIHJldHVybiB0cnVlO1xuICAgIH1cblxuICAgIC8vIGtlZXAgdGhlIGN1cnJlbnQgdmFsdWVcbiAgICB0b0VsLnZhbHVlID0gZnJvbUVsLnZhbHVlO1xuXG4gICAgLy8gaW4gZ2VuZXJhbCB3ZSBoYXZlIHRvIGJlIHZlcnkgY2FyZWZ1bCB3aXRoIHVzaW5nIGlzRXF1YWxOb2RlIGFzIGl0IGRvZXMgbm90IGEgcmVsaWFibGVcbiAgICAvLyBET00gdHJlZSBlcXVhbGl0eSBjaGVjaywgYnV0IGZvciBzZWxlY3Rpb24gYXR0cmlidXRlcyBhbmQgb3B0aW9ucyBpdCB3b3JrcyBmaW5lXG4gICAgcmV0dXJuICFmcm9tRWwuaXNFcXVhbE5vZGUodG9FbCk7XG4gIH1cblxuICBpc0NJRFBhdGNoKCkge1xuICAgIHJldHVybiB0aGlzLmNpZFBhdGNoO1xuICB9XG5cbiAgc2tpcENJRFNpYmxpbmcoZWwpIHtcbiAgICByZXR1cm4gZWwubm9kZVR5cGUgPT09IE5vZGUuRUxFTUVOVF9OT0RFICYmIGVsLmhhc0F0dHJpYnV0ZShQSFhfU0tJUCk7XG4gIH1cblxuICB0YXJnZXRDSURDb250YWluZXIoaHRtbCkge1xuICAgIGlmICghdGhpcy5pc0NJRFBhdGNoKCkpIHtcbiAgICAgIHJldHVybjtcbiAgICB9XG4gICAgY29uc3QgW2ZpcnN0LCAuLi5yZXN0XSA9IERPTS5maW5kQ29tcG9uZW50Tm9kZUxpc3QoXG4gICAgICB0aGlzLnZpZXcuaWQsXG4gICAgICB0aGlzLnRhcmdldENJRCxcbiAgICApO1xuICAgIGlmIChyZXN0Lmxlbmd0aCA9PT0gMCAmJiBET00uY2hpbGROb2RlTGVuZ3RoKGh0bWwpID09PSAxKSB7XG4gICAgICByZXR1cm4gZmlyc3Q7XG4gICAgfSBlbHNlIHtcbiAgICAgIHJldHVybiBmaXJzdCAmJiBmaXJzdC5wYXJlbnROb2RlO1xuICAgIH1cbiAgfVxuXG4gIGluZGV4T2YocGFyZW50LCBjaGlsZCkge1xuICAgIHJldHVybiBBcnJheS5mcm9tKHBhcmVudC5jaGlsZHJlbikuaW5kZXhPZihjaGlsZCk7XG4gIH1cblxuICB0ZWxlcG9ydChlbCwgbW9ycGgpIHtcbiAgICBjb25zdCB0YXJnZXRTZWxlY3RvciA9IGVsLmdldEF0dHJpYnV0ZShQSFhfUE9SVEFMKTtcbiAgICBjb25zdCBwb3J0YWxDb250YWluZXIgPSBkb2N1bWVudC5xdWVyeVNlbGVjdG9yKHRhcmdldFNlbGVjdG9yKTtcbiAgICBpZiAoIXBvcnRhbENvbnRhaW5lcikge1xuICAgICAgdGhyb3cgbmV3IEVycm9yKFxuICAgICAgICBcInBvcnRhbCB0YXJnZXQgd2l0aCBzZWxlY3RvciBcIiArIHRhcmdldFNlbGVjdG9yICsgXCIgbm90IGZvdW5kXCIsXG4gICAgICApO1xuICAgIH1cbiAgICAvLyBwaHgtcG9ydGFsIHRlbXBsYXRlcyBtdXN0IGhhdmUgYSBzaW5nbGUgcm9vdCBlbGVtZW50LCBzbyB3ZSBhc3N1bWUgdGhpcyB0byBiZVxuICAgIC8vIHRoZSBjYXNlIGhlcmVcbiAgICBjb25zdCB0b1RlbGVwb3J0ID0gZWwuY29udGVudC5maXJzdEVsZW1lbnRDaGlsZDtcbiAgICAvLyB0aGUgUEhYX1NLSVAgb3B0aW1pemF0aW9uIGNhbiBhbHNvIGFwcGx5IGluc2lkZSBvZiB0aGUgPHRlbXBsYXRlPiBlbGVtZW50c1xuICAgIGlmICh0aGlzLnNraXBDSURTaWJsaW5nKHRvVGVsZXBvcnQpKSB7XG4gICAgICByZXR1cm47XG4gICAgfVxuICAgIGlmICghdG9UZWxlcG9ydD8uaWQpIHtcbiAgICAgIHRocm93IG5ldyBFcnJvcihcbiAgICAgICAgXCJwaHgtcG9ydGFsIHRlbXBsYXRlIG11c3QgaGF2ZSBhIHNpbmdsZSByb290IGVsZW1lbnQgd2l0aCBJRCFcIixcbiAgICAgICk7XG4gICAgfVxuICAgIGNvbnN0IGV4aXN0aW5nID0gZG9jdW1lbnQuZ2V0RWxlbWVudEJ5SWQodG9UZWxlcG9ydC5pZCk7XG4gICAgbGV0IHBvcnRhbFRhcmdldDtcbiAgICBpZiAoZXhpc3RpbmcpIHtcbiAgICAgIC8vIGNoZWNrIGlmIHRoZSBlbGVtZW50IG5lZWRzIHRvIGJlIG1vdmVkIHRvIGFub3RoZXIgdGFyZ2V0XG4gICAgICBpZiAoIXBvcnRhbENvbnRhaW5lci5jb250YWlucyhleGlzdGluZykpIHtcbiAgICAgICAgcG9ydGFsQ29udGFpbmVyLmFwcGVuZENoaWxkKGV4aXN0aW5nKTtcbiAgICAgIH1cbiAgICAgIC8vIHdlIGFscmVhZHkgdGVsZXBvcnRlZCBpbiBhIHByZXZpb3VzIHBhdGNoXG4gICAgICBwb3J0YWxUYXJnZXQgPSBleGlzdGluZztcbiAgICB9IGVsc2Uge1xuICAgICAgLy8gY3JlYXRlIGVtcHR5IHRhcmdldCBhbmQgbW9ycGggaXQgcmVjdXJzaXZlbHlcbiAgICAgIHBvcnRhbFRhcmdldCA9IGRvY3VtZW50LmNyZWF0ZUVsZW1lbnQodG9UZWxlcG9ydC50YWdOYW1lKTtcbiAgICAgIHBvcnRhbENvbnRhaW5lci5hcHBlbmRDaGlsZChwb3J0YWxUYXJnZXQpO1xuICAgIH1cbiAgICAvLyBtYXJrIHRoZSB0YXJnZXQgYXMgdGVsZXBvcnRlZDtcbiAgICAvLyB0byBwcmV2ZW50IHVubmVjZXNzYXJ5IGF0dHJpYnV0ZSBtb2RpZmljYXRpb25zLCB3ZSBzZXQgdGhlIGF0dHJpYnV0ZVxuICAgIC8vIG9uIHRoZSBzb3VyY2UgYW5kIHJlbW92ZSBpdCBhZnRlciBtb3JwaGluZyAod2UgY291bGQgYWxzbyBqdXN0IGtlZXAgaXQpXG4gICAgLy8gb3RoZXJ3aXNlIG1vcnBoZG9tIHdvdWxkIHJlbW92ZSBpdCwgYXMgdGhlIHJlZiBpcyBub3QgcHJlc2VudCBpbiB0aGUgc291cmNlXG4gICAgLy8gYW5kIHdlJ2QgbmVlZCB0byBzZXQgaXQgYmFjayBhZnRlciBlYWNoIG1vcnBoXG4gICAgdG9UZWxlcG9ydC5zZXRBdHRyaWJ1dGUoUEhYX1RFTEVQT1JURURfUkVGLCB0aGlzLnZpZXcuaWQpO1xuICAgIHRvVGVsZXBvcnQuc2V0QXR0cmlidXRlKFBIWF9URUxFUE9SVEVEX1NSQywgZWwuaWQpO1xuICAgIG1vcnBoKHBvcnRhbFRhcmdldCwgdG9UZWxlcG9ydCwgdHJ1ZSk7XG4gICAgdG9UZWxlcG9ydC5yZW1vdmVBdHRyaWJ1dGUoUEhYX1RFTEVQT1JURURfUkVGKTtcbiAgICB0b1RlbGVwb3J0LnJlbW92ZUF0dHJpYnV0ZShQSFhfVEVMRVBPUlRFRF9TUkMpO1xuICAgIC8vIHN0b3JlIGEgcmVmZXJlbmNlIHRvIHRoZSB0ZWxlcG9ydGVkIGVsZW1lbnQgaW4gdGhlIHZpZXdcbiAgICAvLyB0byBjbGVhbnVwIHdoZW4gdGhlIHZpZXcgaXMgZGVzdHJveWVkLCBpbiBjYXNlIHRoZSBwb3J0YWwgdGFyZ2V0XG4gICAgLy8gaXMgb3V0c2lkZSB0aGUgdmlldyBpdHNlbGZcbiAgICB0aGlzLnZpZXcucHVzaFBvcnRhbEVsZW1lbnRJZCh0b1RlbGVwb3J0LmlkKTtcbiAgfVxuXG4gIGhhbmRsZVJ1bnRpbWVIb29rKGVsLCBzb3VyY2UpIHtcbiAgICAvLyB1c3VhbGx5LCBzY3JpcHRzIGFyZSBub3QgZXhlY3V0ZWQgd2hlbiBtb3JwaGRvbSBhZGRzIHRoZW0gdG8gdGhlIERPTVxuICAgIC8vIHdlIHNwZWNpYWwgY2FzZSBydW50aW1lIGNvbG9jYXRlZCBob29rc1xuICAgIGNvbnN0IG5hbWUgPSBlbC5nZXRBdHRyaWJ1dGUoUEhYX1JVTlRJTUVfSE9PSyk7XG4gICAgbGV0IG5vbmNlID0gZWwuaGFzQXR0cmlidXRlKFwibm9uY2VcIikgPyBlbC5nZXRBdHRyaWJ1dGUoXCJub25jZVwiKSA6IG51bGw7XG4gICAgaWYgKGVsLmhhc0F0dHJpYnV0ZShcIm5vbmNlXCIpKSB7XG4gICAgICBjb25zdCB0ZW1wbGF0ZSA9IGRvY3VtZW50LmNyZWF0ZUVsZW1lbnQoXCJ0ZW1wbGF0ZVwiKTtcbiAgICAgIHRlbXBsYXRlLmlubmVySFRNTCA9IHNvdXJjZTtcbiAgICAgIG5vbmNlID0gdGVtcGxhdGUuY29udGVudFxuICAgICAgICAucXVlcnlTZWxlY3Rvcihgc2NyaXB0WyR7UEhYX1JVTlRJTUVfSE9PS309XCIke0NTUy5lc2NhcGUobmFtZSl9XCJdYClcbiAgICAgICAgLmdldEF0dHJpYnV0ZShcIm5vbmNlXCIpO1xuICAgIH1cbiAgICBjb25zdCBzY3JpcHQgPSBkb2N1bWVudC5jcmVhdGVFbGVtZW50KFwic2NyaXB0XCIpO1xuICAgIHNjcmlwdC50ZXh0Q29udGVudCA9IGVsLnRleHRDb250ZW50O1xuICAgIERPTS5tZXJnZUF0dHJzKHNjcmlwdCwgZWwsIHsgaXNJZ25vcmVkOiBmYWxzZSB9KTtcbiAgICBpZiAobm9uY2UpIHtcbiAgICAgIHNjcmlwdC5ub25jZSA9IG5vbmNlO1xuICAgIH1cbiAgICBlbC5yZXBsYWNlV2l0aChzY3JpcHQpO1xuICAgIGVsID0gc2NyaXB0O1xuICB9XG59XG4iLCAiaW1wb3J0IHtcbiAgQ09NUE9ORU5UUyxcbiAgVEVNUExBVEVTLFxuICBFVkVOVFMsXG4gIFBIWF9DT01QT05FTlQsXG4gIFBIWF9WSUVXX1JFRixcbiAgUEhYX1NLSVAsXG4gIFBIWF9NQUdJQ19JRCxcbiAgUkVQTFksXG4gIFNUQVRJQyxcbiAgVElUTEUsXG4gIFNUUkVBTSxcbiAgUk9PVCxcbiAgS0VZRUQsXG4gIEtFWUVEX0NPVU5ULFxufSBmcm9tIFwiLi9jb25zdGFudHNcIjtcblxuaW1wb3J0IHsgaXNPYmplY3QsIGxvZ0Vycm9yLCBpc0NpZCB9IGZyb20gXCIuL3V0aWxzXCI7XG5cbmNvbnN0IFZPSURfVEFHUyA9IG5ldyBTZXQoW1xuICBcImFyZWFcIixcbiAgXCJiYXNlXCIsXG4gIFwiYnJcIixcbiAgXCJjb2xcIixcbiAgXCJjb21tYW5kXCIsXG4gIFwiZW1iZWRcIixcbiAgXCJoclwiLFxuICBcImltZ1wiLFxuICBcImlucHV0XCIsXG4gIFwia2V5Z2VuXCIsXG4gIFwibGlua1wiLFxuICBcIm1ldGFcIixcbiAgXCJwYXJhbVwiLFxuICBcInNvdXJjZVwiLFxuICBcInRyYWNrXCIsXG4gIFwid2JyXCIsXG5dKTtcbmNvbnN0IHF1b3RlQ2hhcnMgPSBuZXcgU2V0KFtcIidcIiwgJ1wiJ10pO1xuXG5leHBvcnQgY29uc3QgbW9kaWZ5Um9vdCA9IChodG1sLCBhdHRycywgY2xlYXJJbm5lckhUTUwpID0+IHtcbiAgbGV0IGkgPSAwO1xuICBsZXQgaW5zaWRlQ29tbWVudCA9IGZhbHNlO1xuICBsZXQgYmVmb3JlVGFnLCBhZnRlclRhZywgdGFnLCB0YWdOYW1lRW5kc0F0LCBpZCwgbmV3SFRNTDtcblxuICBjb25zdCBsb29rYWhlYWQgPSBodG1sLm1hdGNoKC9eKFxccyooPzo8IS0tLio/LS0+XFxzKikqKTwoW15cXHNcXC8+XSspLyk7XG4gIGlmIChsb29rYWhlYWQgPT09IG51bGwpIHtcbiAgICB0aHJvdyBuZXcgRXJyb3IoYG1hbGZvcm1lZCBodG1sICR7aHRtbH1gKTtcbiAgfVxuXG4gIGkgPSBsb29rYWhlYWRbMF0ubGVuZ3RoO1xuICBiZWZvcmVUYWcgPSBsb29rYWhlYWRbMV07XG4gIHRhZyA9IGxvb2thaGVhZFsyXTtcbiAgdGFnTmFtZUVuZHNBdCA9IGk7XG5cbiAgLy8gU2NhbiB0aGUgb3BlbmluZyB0YWcgZm9yIGlkLCBpZiB0aGVyZSBpcyBhbnlcbiAgZm9yIChpOyBpIDwgaHRtbC5sZW5ndGg7IGkrKykge1xuICAgIGlmIChodG1sLmNoYXJBdChpKSA9PT0gXCI+XCIpIHtcbiAgICAgIGJyZWFrO1xuICAgIH1cbiAgICBpZiAoaHRtbC5jaGFyQXQoaSkgPT09IFwiPVwiKSB7XG4gICAgICBjb25zdCBpc0lkID0gaHRtbC5zbGljZShpIC0gMywgaSkgPT09IFwiIGlkXCI7XG4gICAgICBpKys7XG4gICAgICBjb25zdCBjaGFyID0gaHRtbC5jaGFyQXQoaSk7XG4gICAgICBpZiAocXVvdGVDaGFycy5oYXMoY2hhcikpIHtcbiAgICAgICAgY29uc3QgYXR0clN0YXJ0c0F0ID0gaTtcbiAgICAgICAgaSsrO1xuICAgICAgICBmb3IgKGk7IGkgPCBodG1sLmxlbmd0aDsgaSsrKSB7XG4gICAgICAgICAgaWYgKGh0bWwuY2hhckF0KGkpID09PSBjaGFyKSB7XG4gICAgICAgICAgICBicmVhaztcbiAgICAgICAgICB9XG4gICAgICAgIH1cbiAgICAgICAgaWYgKGlzSWQpIHtcbiAgICAgICAgICBpZCA9IGh0bWwuc2xpY2UoYXR0clN0YXJ0c0F0ICsgMSwgaSk7XG4gICAgICAgICAgYnJlYWs7XG4gICAgICAgIH1cbiAgICAgIH1cbiAgICB9XG4gIH1cblxuICBsZXQgY2xvc2VBdCA9IGh0bWwubGVuZ3RoIC0gMTtcbiAgaW5zaWRlQ29tbWVudCA9IGZhbHNlO1xuICB3aGlsZSAoY2xvc2VBdCA+PSBiZWZvcmVUYWcubGVuZ3RoICsgdGFnLmxlbmd0aCkge1xuICAgIGNvbnN0IGNoYXIgPSBodG1sLmNoYXJBdChjbG9zZUF0KTtcbiAgICBpZiAoaW5zaWRlQ29tbWVudCkge1xuICAgICAgaWYgKGNoYXIgPT09IFwiLVwiICYmIGh0bWwuc2xpY2UoY2xvc2VBdCAtIDMsIGNsb3NlQXQpID09PSBcIjwhLVwiKSB7XG4gICAgICAgIGluc2lkZUNvbW1lbnQgPSBmYWxzZTtcbiAgICAgICAgY2xvc2VBdCAtPSA0O1xuICAgICAgfSBlbHNlIHtcbiAgICAgICAgY2xvc2VBdCAtPSAxO1xuICAgICAgfVxuICAgIH0gZWxzZSBpZiAoY2hhciA9PT0gXCI+XCIgJiYgaHRtbC5zbGljZShjbG9zZUF0IC0gMiwgY2xvc2VBdCkgPT09IFwiLS1cIikge1xuICAgICAgaW5zaWRlQ29tbWVudCA9IHRydWU7XG4gICAgICBjbG9zZUF0IC09IDM7XG4gICAgfSBlbHNlIGlmIChjaGFyID09PSBcIj5cIikge1xuICAgICAgYnJlYWs7XG4gICAgfSBlbHNlIHtcbiAgICAgIGNsb3NlQXQgLT0gMTtcbiAgICB9XG4gIH1cbiAgYWZ0ZXJUYWcgPSBodG1sLnNsaWNlKGNsb3NlQXQgKyAxLCBodG1sLmxlbmd0aCk7XG5cbiAgY29uc3QgYXR0cnNTdHIgPSBPYmplY3Qua2V5cyhhdHRycylcbiAgICAubWFwKChhdHRyKSA9PiAoYXR0cnNbYXR0cl0gPT09IHRydWUgPyBhdHRyIDogYCR7YXR0cn09XCIke2F0dHJzW2F0dHJdfVwiYCkpXG4gICAgLmpvaW4oXCIgXCIpO1xuXG4gIGlmIChjbGVhcklubmVySFRNTCkge1xuICAgIC8vIEtlZXAgdGhlIGlkIGlmIGFueVxuICAgIGNvbnN0IGlkQXR0clN0ciA9IGlkID8gYCBpZD1cIiR7aWR9XCJgIDogXCJcIjtcbiAgICBpZiAoVk9JRF9UQUdTLmhhcyh0YWcpKSB7XG4gICAgICBuZXdIVE1MID0gYDwke3RhZ30ke2lkQXR0clN0cn0ke2F0dHJzU3RyID09PSBcIlwiID8gXCJcIiA6IFwiIFwifSR7YXR0cnNTdHJ9Lz5gO1xuICAgIH0gZWxzZSB7XG4gICAgICBuZXdIVE1MID0gYDwke3RhZ30ke2lkQXR0clN0cn0ke2F0dHJzU3RyID09PSBcIlwiID8gXCJcIiA6IFwiIFwifSR7YXR0cnNTdHJ9PjwvJHt0YWd9PmA7XG4gICAgfVxuICB9IGVsc2Uge1xuICAgIGNvbnN0IHJlc3QgPSBodG1sLnNsaWNlKHRhZ05hbWVFbmRzQXQsIGNsb3NlQXQgKyAxKTtcbiAgICBuZXdIVE1MID0gYDwke3RhZ30ke2F0dHJzU3RyID09PSBcIlwiID8gXCJcIiA6IFwiIFwifSR7YXR0cnNTdHJ9JHtyZXN0fWA7XG4gIH1cblxuICByZXR1cm4gW25ld0hUTUwsIGJlZm9yZVRhZywgYWZ0ZXJUYWddO1xufTtcblxuZXhwb3J0IGRlZmF1bHQgY2xhc3MgUmVuZGVyZWQge1xuICBzdGF0aWMgZXh0cmFjdChkaWZmKSB7XG4gICAgY29uc3QgeyBbUkVQTFldOiByZXBseSwgW0VWRU5UU106IGV2ZW50cywgW1RJVExFXTogdGl0bGUgfSA9IGRpZmY7XG4gICAgZGVsZXRlIGRpZmZbUkVQTFldO1xuICAgIGRlbGV0ZSBkaWZmW0VWRU5UU107XG4gICAgZGVsZXRlIGRpZmZbVElUTEVdO1xuICAgIHJldHVybiB7IGRpZmYsIHRpdGxlLCByZXBseTogcmVwbHkgfHwgbnVsbCwgZXZlbnRzOiBldmVudHMgfHwgW10gfTtcbiAgfVxuXG4gIGNvbnN0cnVjdG9yKHZpZXdJZCwgcmVuZGVyZWQpIHtcbiAgICB0aGlzLnZpZXdJZCA9IHZpZXdJZDtcbiAgICB0aGlzLnJlbmRlcmVkID0ge307XG4gICAgdGhpcy5tYWdpY0lkID0gMDtcbiAgICB0aGlzLm1lcmdlRGlmZihyZW5kZXJlZCk7XG4gIH1cblxuICBwYXJlbnRWaWV3SWQoKSB7XG4gICAgcmV0dXJuIHRoaXMudmlld0lkO1xuICB9XG5cbiAgdG9TdHJpbmcob25seUNpZHMpIHtcbiAgICBjb25zdCB7IGJ1ZmZlcjogc3RyLCBzdHJlYW1zOiBzdHJlYW1zIH0gPSB0aGlzLnJlY3Vyc2l2ZVRvU3RyaW5nKFxuICAgICAgdGhpcy5yZW5kZXJlZCxcbiAgICAgIHRoaXMucmVuZGVyZWRbQ09NUE9ORU5UU10sXG4gICAgICBvbmx5Q2lkcyxcbiAgICAgIHRydWUsXG4gICAgICB7fSxcbiAgICApO1xuICAgIHJldHVybiB7IGJ1ZmZlcjogc3RyLCBzdHJlYW1zOiBzdHJlYW1zIH07XG4gIH1cblxuICByZWN1cnNpdmVUb1N0cmluZyhcbiAgICByZW5kZXJlZCxcbiAgICBjb21wb25lbnRzID0gcmVuZGVyZWRbQ09NUE9ORU5UU10sXG4gICAgb25seUNpZHMsXG4gICAgY2hhbmdlVHJhY2tpbmcsXG4gICAgcm9vdEF0dHJzLFxuICApIHtcbiAgICBvbmx5Q2lkcyA9IG9ubHlDaWRzID8gbmV3IFNldChvbmx5Q2lkcykgOiBudWxsO1xuICAgIGNvbnN0IG91dHB1dCA9IHtcbiAgICAgIGJ1ZmZlcjogXCJcIixcbiAgICAgIGNvbXBvbmVudHM6IGNvbXBvbmVudHMsXG4gICAgICBvbmx5Q2lkczogb25seUNpZHMsXG4gICAgICBzdHJlYW1zOiBuZXcgU2V0KCksXG4gICAgfTtcbiAgICB0aGlzLnRvT3V0cHV0QnVmZmVyKHJlbmRlcmVkLCBudWxsLCBvdXRwdXQsIGNoYW5nZVRyYWNraW5nLCByb290QXR0cnMpO1xuICAgIHJldHVybiB7IGJ1ZmZlcjogb3V0cHV0LmJ1ZmZlciwgc3RyZWFtczogb3V0cHV0LnN0cmVhbXMgfTtcbiAgfVxuXG4gIGNvbXBvbmVudENJRHMoZGlmZikge1xuICAgIHJldHVybiBPYmplY3Qua2V5cyhkaWZmW0NPTVBPTkVOVFNdIHx8IHt9KS5tYXAoKGkpID0+IHBhcnNlSW50KGkpKTtcbiAgfVxuXG4gIGlzQ29tcG9uZW50T25seURpZmYoZGlmZikge1xuICAgIGlmICghZGlmZltDT01QT05FTlRTXSkge1xuICAgICAgcmV0dXJuIGZhbHNlO1xuICAgIH1cbiAgICByZXR1cm4gT2JqZWN0LmtleXMoZGlmZikubGVuZ3RoID09PSAxO1xuICB9XG5cbiAgZ2V0Q29tcG9uZW50KGRpZmYsIGNpZCkge1xuICAgIHJldHVybiBkaWZmW0NPTVBPTkVOVFNdW2NpZF07XG4gIH1cblxuICByZXNldFJlbmRlcihjaWQpIHtcbiAgICAvLyB3ZSBhcmUgcmFjaW5nIGEgY29tcG9uZW50IGRlc3Ryb3ksIGl0IGNvdWxkIG5vdCBleGlzdCwgc29cbiAgICAvLyBtYWtlIHN1cmUgdGhhdCB3ZSBkb24ndCB0cnkgdG8gc2V0IHJlc2V0IG9uIHVuZGVmaW5lZFxuICAgIGlmICh0aGlzLnJlbmRlcmVkW0NPTVBPTkVOVFNdW2NpZF0pIHtcbiAgICAgIHRoaXMucmVuZGVyZWRbQ09NUE9ORU5UU11bY2lkXS5yZXNldCA9IHRydWU7XG4gICAgfVxuICB9XG5cbiAgbWVyZ2VEaWZmKGRpZmYpIHtcbiAgICBjb25zdCBuZXdjID0gZGlmZltDT01QT05FTlRTXTtcbiAgICBjb25zdCBjYWNoZSA9IHt9O1xuICAgIGRlbGV0ZSBkaWZmW0NPTVBPTkVOVFNdO1xuICAgIHRoaXMucmVuZGVyZWQgPSB0aGlzLm11dGFibGVNZXJnZSh0aGlzLnJlbmRlcmVkLCBkaWZmKTtcbiAgICB0aGlzLnJlbmRlcmVkW0NPTVBPTkVOVFNdID0gdGhpcy5yZW5kZXJlZFtDT01QT05FTlRTXSB8fCB7fTtcblxuICAgIGlmIChuZXdjKSB7XG4gICAgICBjb25zdCBvbGRjID0gdGhpcy5yZW5kZXJlZFtDT01QT05FTlRTXTtcblxuICAgICAgZm9yIChjb25zdCBjaWQgaW4gbmV3Yykge1xuICAgICAgICBuZXdjW2NpZF0gPSB0aGlzLmNhY2hlZEZpbmRDb21wb25lbnQoY2lkLCBuZXdjW2NpZF0sIG9sZGMsIG5ld2MsIGNhY2hlKTtcbiAgICAgIH1cblxuICAgICAgZm9yIChjb25zdCBjaWQgaW4gbmV3Yykge1xuICAgICAgICBvbGRjW2NpZF0gPSBuZXdjW2NpZF07XG4gICAgICB9XG4gICAgICBkaWZmW0NPTVBPTkVOVFNdID0gbmV3YztcbiAgICB9XG4gIH1cblxuICBjYWNoZWRGaW5kQ29tcG9uZW50KGNpZCwgY2RpZmYsIG9sZGMsIG5ld2MsIGNhY2hlKSB7XG4gICAgaWYgKGNhY2hlW2NpZF0pIHtcbiAgICAgIHJldHVybiBjYWNoZVtjaWRdO1xuICAgIH0gZWxzZSB7XG4gICAgICBsZXQgbmRpZmYsXG4gICAgICAgIHN0YXQsXG4gICAgICAgIHNjaWQgPSBjZGlmZltTVEFUSUNdO1xuXG4gICAgICBpZiAoaXNDaWQoc2NpZCkpIHtcbiAgICAgICAgbGV0IHRkaWZmO1xuXG4gICAgICAgIGlmIChzY2lkID4gMCkge1xuICAgICAgICAgIHRkaWZmID0gdGhpcy5jYWNoZWRGaW5kQ29tcG9uZW50KHNjaWQsIG5ld2Nbc2NpZF0sIG9sZGMsIG5ld2MsIGNhY2hlKTtcbiAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICB0ZGlmZiA9IG9sZGNbLXNjaWRdO1xuICAgICAgICB9XG5cbiAgICAgICAgc3RhdCA9IHRkaWZmW1NUQVRJQ107XG4gICAgICAgIG5kaWZmID0gdGhpcy5jbG9uZU1lcmdlKHRkaWZmLCBjZGlmZiwgdHJ1ZSk7XG4gICAgICAgIG5kaWZmW1NUQVRJQ10gPSBzdGF0O1xuICAgICAgfSBlbHNlIHtcbiAgICAgICAgbmRpZmYgPVxuICAgICAgICAgIGNkaWZmW1NUQVRJQ10gIT09IHVuZGVmaW5lZCB8fCBvbGRjW2NpZF0gPT09IHVuZGVmaW5lZFxuICAgICAgICAgICAgPyBjZGlmZlxuICAgICAgICAgICAgOiB0aGlzLmNsb25lTWVyZ2Uob2xkY1tjaWRdLCBjZGlmZiwgZmFsc2UpO1xuICAgICAgfVxuXG4gICAgICBjYWNoZVtjaWRdID0gbmRpZmY7XG4gICAgICByZXR1cm4gbmRpZmY7XG4gICAgfVxuICB9XG5cbiAgbXV0YWJsZU1lcmdlKHRhcmdldCwgc291cmNlKSB7XG4gICAgaWYgKHNvdXJjZVtTVEFUSUNdICE9PSB1bmRlZmluZWQpIHtcbiAgICAgIHJldHVybiBzb3VyY2U7XG4gICAgfSBlbHNlIHtcbiAgICAgIHRoaXMuZG9NdXRhYmxlTWVyZ2UodGFyZ2V0LCBzb3VyY2UpO1xuICAgICAgcmV0dXJuIHRhcmdldDtcbiAgICB9XG4gIH1cblxuICBkb011dGFibGVNZXJnZSh0YXJnZXQsIHNvdXJjZSkge1xuICAgIGlmIChzb3VyY2VbS0VZRURdKSB7XG4gICAgICB0aGlzLm1lcmdlS2V5ZWQodGFyZ2V0LCBzb3VyY2UpO1xuICAgIH0gZWxzZSB7XG4gICAgICBmb3IgKGNvbnN0IGtleSBpbiBzb3VyY2UpIHtcbiAgICAgICAgY29uc3QgdmFsID0gc291cmNlW2tleV07XG4gICAgICAgIGNvbnN0IHRhcmdldFZhbCA9IHRhcmdldFtrZXldO1xuICAgICAgICBjb25zdCBpc09ialZhbCA9IGlzT2JqZWN0KHZhbCk7XG4gICAgICAgIGlmIChpc09ialZhbCAmJiB2YWxbU1RBVElDXSA9PT0gdW5kZWZpbmVkICYmIGlzT2JqZWN0KHRhcmdldFZhbCkpIHtcbiAgICAgICAgICB0aGlzLmRvTXV0YWJsZU1lcmdlKHRhcmdldFZhbCwgdmFsKTtcbiAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICB0YXJnZXRba2V5XSA9IHZhbDtcbiAgICAgICAgfVxuICAgICAgfVxuICAgIH1cbiAgICBpZiAodGFyZ2V0W1JPT1RdKSB7XG4gICAgICB0YXJnZXQubmV3UmVuZGVyID0gdHJ1ZTtcbiAgICB9XG4gIH1cblxuICBjbG9uZShkaWZmKSB7XG4gICAgaWYgKFwic3RydWN0dXJlZENsb25lXCIgaW4gd2luZG93KSB7XG4gICAgICByZXR1cm4gc3RydWN0dXJlZENsb25lKGRpZmYpO1xuICAgIH0gZWxzZSB7XG4gICAgICAvLyBmYWxsYmFjayBmb3IgamVzdFxuICAgICAgcmV0dXJuIEpTT04ucGFyc2UoSlNPTi5zdHJpbmdpZnkoZGlmZikpO1xuICAgIH1cbiAgfVxuXG4gIC8vIGtleWVkIGNvbXByZWhlbnNpb25zXG4gIG1lcmdlS2V5ZWQodGFyZ2V0LCBzb3VyY2UpIHtcbiAgICAvLyB3ZSBuZWVkIHRvIGNsb25lIHRoZSB0YXJnZXQgc2luY2UgZWxlbWVudHMgY2FuIG1vdmUgYW5kIG90aGVyd2lzZVxuICAgIC8vIGl0IGNvdWxkIGhhcHBlbiB0aGF0IHdlIG1vZGlmeSBhbiBlbGVtZW50IHRoYXQgd2UnbGwgbmVlZCB0byByZWZlciB0b1xuICAgIC8vIGxhdGVyXG4gICAgY29uc3QgY2xvbmVkVGFyZ2V0ID0gdGhpcy5jbG9uZSh0YXJnZXQpO1xuICAgIE9iamVjdC5lbnRyaWVzKHNvdXJjZVtLRVlFRF0pLmZvckVhY2goKFtpLCBlbnRyeV0pID0+IHtcbiAgICAgIGlmIChpID09PSBLRVlFRF9DT1VOVCkge1xuICAgICAgICByZXR1cm47XG4gICAgICB9XG4gICAgICBpZiAoQXJyYXkuaXNBcnJheShlbnRyeSkpIHtcbiAgICAgICAgLy8gW29sZF9pZHgsIGRpZmZdXG4gICAgICAgIC8vIG1vdmVkIHdpdGggZGlmZlxuICAgICAgICBjb25zdCBbb2xkX2lkeCwgZGlmZl0gPSBlbnRyeTtcbiAgICAgICAgdGFyZ2V0W0tFWUVEXVtpXSA9IGNsb25lZFRhcmdldFtLRVlFRF1bb2xkX2lkeF07XG4gICAgICAgIHRoaXMuZG9NdXRhYmxlTWVyZ2UodGFyZ2V0W0tFWUVEXVtpXSwgZGlmZik7XG4gICAgICB9IGVsc2UgaWYgKHR5cGVvZiBlbnRyeSA9PT0gXCJudW1iZXJcIikge1xuICAgICAgICAvLyBtb3ZlZCB3aXRob3V0IGRpZmZcbiAgICAgICAgY29uc3Qgb2xkX2lkeCA9IGVudHJ5O1xuICAgICAgICB0YXJnZXRbS0VZRURdW2ldID0gY2xvbmVkVGFyZ2V0W0tFWUVEXVtvbGRfaWR4XTtcbiAgICAgIH0gZWxzZSBpZiAodHlwZW9mIGVudHJ5ID09PSBcIm9iamVjdFwiKSB7XG4gICAgICAgIC8vIGRpZmYsIHNhbWUgcG9zaXRpb25cbiAgICAgICAgaWYgKCF0YXJnZXRbS0VZRURdW2ldKSB7XG4gICAgICAgICAgdGFyZ2V0W0tFWUVEXVtpXSA9IHt9O1xuICAgICAgICB9XG4gICAgICAgIHRoaXMuZG9NdXRhYmxlTWVyZ2UodGFyZ2V0W0tFWUVEXVtpXSwgZW50cnkpO1xuICAgICAgfVxuICAgIH0pO1xuICAgIC8vIGRyb3AgZXh0cmEgZW50cmllc1xuICAgIGlmIChzb3VyY2VbS0VZRURdW0tFWUVEX0NPVU5UXSA8IHRhcmdldFtLRVlFRF1bS0VZRURfQ09VTlRdKSB7XG4gICAgICBmb3IgKFxuICAgICAgICBsZXQgaSA9IHNvdXJjZVtLRVlFRF1bS0VZRURfQ09VTlRdO1xuICAgICAgICBpIDwgdGFyZ2V0W0tFWUVEXVtLRVlFRF9DT1VOVF07XG4gICAgICAgIGkrK1xuICAgICAgKSB7XG4gICAgICAgIGRlbGV0ZSB0YXJnZXRbS0VZRURdW2ldO1xuICAgICAgfVxuICAgIH1cbiAgICB0YXJnZXRbS0VZRURdW0tFWUVEX0NPVU5UXSA9IHNvdXJjZVtLRVlFRF1bS0VZRURfQ09VTlRdO1xuICAgIGlmIChzb3VyY2VbU1RSRUFNXSkge1xuICAgICAgdGFyZ2V0W1NUUkVBTV0gPSBzb3VyY2VbU1RSRUFNXTtcbiAgICB9XG4gICAgaWYgKHNvdXJjZVtURU1QTEFURVNdKSB7XG4gICAgICB0YXJnZXRbVEVNUExBVEVTXSA9IHNvdXJjZVtURU1QTEFURVNdO1xuICAgIH1cbiAgfVxuXG4gIC8vIE1lcmdlcyBjaWQgdHJlZXMgdG9nZXRoZXIsIGNvcHlpbmcgc3RhdGljcyBmcm9tIHNvdXJjZSB0cmVlLlxuICAvL1xuICAvLyBUaGUgYHBydW5lTWFnaWNJZGAgaXMgcGFzc2VkIHRvIGNvbnRyb2wgcHJ1bmluZyB0aGUgbWFnaWNJZCBvZiB0aGVcbiAgLy8gdGFyZ2V0LiBXZSBtdXN0IGFsd2F5cyBwcnVuZSB0aGUgbWFnaWNJZCB3aGVuIHdlIGFyZSBzaGFyaW5nIHN0YXRpY3NcbiAgLy8gZnJvbSBhbm90aGVyIGNvbXBvbmVudC4gSWYgbm90IHBydW5pbmcsIHdlIHJlcGxpY2F0ZSB0aGUgbG9naWMgZnJvbVxuICAvLyBtdXRhYmxlTWVyZ2UsIHdoZXJlIHdlIHNldCBuZXdSZW5kZXIgdG8gdHJ1ZSBpZiB0aGVyZSBpcyBhIHJvb3RcbiAgLy8gKGVmZmVjdGl2ZWx5IGZvcmNpbmcgdGhlIG5ldyB2ZXJzaW9uIHRvIGJlIHJlbmRlcmVkIGluc3RlYWQgb2Ygc2tpcHBlZClcbiAgLy9cbiAgY2xvbmVNZXJnZSh0YXJnZXQsIHNvdXJjZSwgcHJ1bmVNYWdpY0lkKSB7XG4gICAgY29uc3QgbWVyZ2VkID0geyAuLi50YXJnZXQsIC4uLnNvdXJjZSB9O1xuICAgIGZvciAoY29uc3Qga2V5IGluIG1lcmdlZCkge1xuICAgICAgY29uc3QgdmFsID0gc291cmNlW2tleV07XG4gICAgICBjb25zdCB0YXJnZXRWYWwgPSB0YXJnZXRba2V5XTtcbiAgICAgIGlmIChpc09iamVjdCh2YWwpICYmIHZhbFtTVEFUSUNdID09PSB1bmRlZmluZWQgJiYgaXNPYmplY3QodGFyZ2V0VmFsKSkge1xuICAgICAgICBtZXJnZWRba2V5XSA9IHRoaXMuY2xvbmVNZXJnZSh0YXJnZXRWYWwsIHZhbCwgcHJ1bmVNYWdpY0lkKTtcbiAgICAgIH0gZWxzZSBpZiAodmFsID09PSB1bmRlZmluZWQgJiYgaXNPYmplY3QodGFyZ2V0VmFsKSkge1xuICAgICAgICBtZXJnZWRba2V5XSA9IHRoaXMuY2xvbmVNZXJnZSh0YXJnZXRWYWwsIHt9LCBwcnVuZU1hZ2ljSWQpO1xuICAgICAgfVxuICAgIH1cbiAgICBpZiAocHJ1bmVNYWdpY0lkKSB7XG4gICAgICBkZWxldGUgbWVyZ2VkLm1hZ2ljSWQ7XG4gICAgICBkZWxldGUgbWVyZ2VkLm5ld1JlbmRlcjtcbiAgICB9IGVsc2UgaWYgKHRhcmdldFtST09UXSkge1xuICAgICAgbWVyZ2VkLm5ld1JlbmRlciA9IHRydWU7XG4gICAgfVxuICAgIHJldHVybiBtZXJnZWQ7XG4gIH1cblxuICBjb21wb25lbnRUb1N0cmluZyhjaWQpIHtcbiAgICBjb25zdCB7IGJ1ZmZlcjogc3RyLCBzdHJlYW1zIH0gPSB0aGlzLnJlY3Vyc2l2ZUNJRFRvU3RyaW5nKFxuICAgICAgdGhpcy5yZW5kZXJlZFtDT01QT05FTlRTXSxcbiAgICAgIGNpZCxcbiAgICAgIG51bGwsXG4gICAgKTtcbiAgICBjb25zdCBbc3RyaXBwZWRIVE1MLCBfYmVmb3JlLCBfYWZ0ZXJdID0gbW9kaWZ5Um9vdChzdHIsIHt9KTtcbiAgICByZXR1cm4geyBidWZmZXI6IHN0cmlwcGVkSFRNTCwgc3RyZWFtczogc3RyZWFtcyB9O1xuICB9XG5cbiAgcHJ1bmVDSURzKGNpZHMpIHtcbiAgICBjaWRzLmZvckVhY2goKGNpZCkgPT4gZGVsZXRlIHRoaXMucmVuZGVyZWRbQ09NUE9ORU5UU11bY2lkXSk7XG4gIH1cblxuICAvLyBwcml2YXRlXG5cbiAgZ2V0KCkge1xuICAgIHJldHVybiB0aGlzLnJlbmRlcmVkO1xuICB9XG5cbiAgaXNOZXdGaW5nZXJwcmludChkaWZmID0ge30pIHtcbiAgICByZXR1cm4gISFkaWZmW1NUQVRJQ107XG4gIH1cblxuICB0ZW1wbGF0ZVN0YXRpYyhwYXJ0LCB0ZW1wbGF0ZXMpIHtcbiAgICBpZiAodHlwZW9mIHBhcnQgPT09IFwibnVtYmVyXCIpIHtcbiAgICAgIHJldHVybiB0ZW1wbGF0ZXNbcGFydF07XG4gICAgfSBlbHNlIHtcbiAgICAgIHJldHVybiBwYXJ0O1xuICAgIH1cbiAgfVxuXG4gIG5leHRNYWdpY0lEKCkge1xuICAgIHRoaXMubWFnaWNJZCsrO1xuICAgIHJldHVybiBgbSR7dGhpcy5tYWdpY0lkfS0ke3RoaXMucGFyZW50Vmlld0lkKCl9YDtcbiAgfVxuXG4gIC8vIENvbnZlcnRzIHJlbmRlcmVkIHRyZWUgdG8gb3V0cHV0IGJ1ZmZlci5cbiAgLy9cbiAgLy8gY2hhbmdlVHJhY2tpbmcgY29udHJvbHMgaWYgd2UgY2FuIGFwcGx5IHRoZSBQSFhfU0tJUCBvcHRpbWl6YXRpb24uXG4gIHRvT3V0cHV0QnVmZmVyKHJlbmRlcmVkLCB0ZW1wbGF0ZXMsIG91dHB1dCwgY2hhbmdlVHJhY2tpbmcsIHJvb3RBdHRycyA9IHt9KSB7XG4gICAgaWYgKHJlbmRlcmVkW0tFWUVEXSkge1xuICAgICAgcmV0dXJuIHRoaXMuY29tcHJlaGVuc2lvblRvQnVmZmVyKFxuICAgICAgICByZW5kZXJlZCxcbiAgICAgICAgdGVtcGxhdGVzLFxuICAgICAgICBvdXRwdXQsXG4gICAgICAgIGNoYW5nZVRyYWNraW5nLFxuICAgICAgKTtcbiAgICB9XG5cbiAgICAvLyBUZW1wbGF0ZXMgYXJlIGEgd2F5IG9mIHNoYXJpbmcgc3RhdGljcyBiZXR3ZWVuIG11bHRpcGxlIHJlbmRlcmVkIHN0cnVjdHMuXG4gICAgLy8gU2luY2UgTGl2ZVZpZXcgMS4xLCB0aG9zZSBjYW4gYWxzbyBhcHBlYXIgYXQgdGhlIHJvb3QgLSBmb3IgZXhhbXBsZSBpZiBvbmUgcmVuZGVyc1xuICAgIC8vIHR3byBjb21wcmVoZW5zaW9ucyB0aGF0IGNhbiBzaGFyZSBzdGF0aWNzLlxuICAgIC8vIFdoZW5ldmVyIHdlIGZpbmQgdGVtcGxhdGVzLCB3ZSBuZWVkIHRvIHVzZSB0aGVtIHJlY3Vyc2l2ZWx5LiBBbHNvLCB0ZW1wbGF0ZXMgY2FuXG4gICAgLy8gYmUgc2VudCBmb3IgZWFjaCBkaWZmLCBub3Qgb25seSBmb3IgdGhlIGluaXRpYWwgb25lLiBXZSBkb24ndCB3YW50IHRvIG1lcmdlIHRoZW1cbiAgICAvLyB0aG91Z2gsIHNvIHdlIGFsd2F5cyByZXNvbHZlIHRoZW0gYW5kIHJlbW92ZSB0aGVtIGZyb20gdGhlIHJlbmRlcmVkIG9iamVjdC5cbiAgICBpZiAocmVuZGVyZWRbVEVNUExBVEVTXSkge1xuICAgICAgdGVtcGxhdGVzID0gcmVuZGVyZWRbVEVNUExBVEVTXTtcbiAgICAgIGRlbGV0ZSByZW5kZXJlZFtURU1QTEFURVNdO1xuICAgIH1cblxuICAgIGxldCB7IFtTVEFUSUNdOiBzdGF0aWNzIH0gPSByZW5kZXJlZDtcbiAgICBzdGF0aWNzID0gdGhpcy50ZW1wbGF0ZVN0YXRpYyhzdGF0aWNzLCB0ZW1wbGF0ZXMpO1xuICAgIHJlbmRlcmVkW1NUQVRJQ10gPSBzdGF0aWNzO1xuICAgIGNvbnN0IGlzUm9vdCA9IHJlbmRlcmVkW1JPT1RdO1xuICAgIGNvbnN0IHByZXZCdWZmZXIgPSBvdXRwdXQuYnVmZmVyO1xuICAgIGlmIChpc1Jvb3QpIHtcbiAgICAgIG91dHB1dC5idWZmZXIgPSBcIlwiO1xuICAgIH1cblxuICAgIC8vIHRoaXMgY29uZGl0aW9uIGlzIGNhbGxlZCB3aGVuIGZpcnN0IHJlbmRlcmluZyBhbiBvcHRpbWl6YWJsZSBmdW5jdGlvbiBjb21wb25lbnQuXG4gICAgLy8gTEMgaGF2ZSB0aGVpciBtYWdpY0lkIHByZXZpb3VzbHkgc2V0XG4gICAgaWYgKGNoYW5nZVRyYWNraW5nICYmIGlzUm9vdCAmJiAhcmVuZGVyZWQubWFnaWNJZCkge1xuICAgICAgcmVuZGVyZWQubmV3UmVuZGVyID0gdHJ1ZTtcbiAgICAgIHJlbmRlcmVkLm1hZ2ljSWQgPSB0aGlzLm5leHRNYWdpY0lEKCk7XG4gICAgfVxuXG4gICAgb3V0cHV0LmJ1ZmZlciArPSBzdGF0aWNzWzBdO1xuICAgIGZvciAobGV0IGkgPSAxOyBpIDwgc3RhdGljcy5sZW5ndGg7IGkrKykge1xuICAgICAgdGhpcy5keW5hbWljVG9CdWZmZXIocmVuZGVyZWRbaSAtIDFdLCB0ZW1wbGF0ZXMsIG91dHB1dCwgY2hhbmdlVHJhY2tpbmcpO1xuICAgICAgb3V0cHV0LmJ1ZmZlciArPSBzdGF0aWNzW2ldO1xuICAgIH1cblxuICAgIC8vIEFwcGxpZXMgdGhlIHJvb3QgdGFnIFwic2tpcFwiIG9wdGltaXphdGlvbiBpZiBzdXBwb3J0ZWQsIHdoaWNoIGNsZWFyc1xuICAgIC8vIHRoZSByb290IHRhZyBhdHRyaWJ1dGVzIGFuZCBpbm5lckhUTUwsIGFuZCBvbmx5IG1haW50YWlucyB0aGUgbWFnaWNJZC5cbiAgICAvLyBXZSBjYW4gb25seSBza2lwIHdoZW4gY2hhbmdlVHJhY2tpbmcgaXMgc3VwcG9ydGVkLFxuICAgIC8vIGFuZCB3aGVuIHRoZSByb290IGVsZW1lbnQgaGFzbid0IGV4cGVyaWVuY2VkIGFuIHVucmVuZGVyZWQgbWVyZ2UgKG5ld1JlbmRlciB0cnVlKS5cbiAgICBpZiAoaXNSb290KSB7XG4gICAgICBsZXQgc2tpcCA9IGZhbHNlO1xuICAgICAgbGV0IGF0dHJzO1xuICAgICAgLy8gV2hlbiBhIExDIGlzIHJlLWFkZGVkIHRvIHRoZSBwYWdlLCB3ZSBuZWVkIHRvIHJlLXJlbmRlciB0aGUgZW50aXJlIExDIHRyZWUsXG4gICAgICAvLyB0aGVyZWZvcmUgY2hhbmdlVHJhY2tpbmcgaXMgZmFsc2U7IGhvd2V2ZXIsIHdlIG5lZWQgdG8ga2VlcCBhbGwgdGhlIG1hZ2ljSWRzXG4gICAgICAvLyBmcm9tIGFueSBmdW5jdGlvbiBjb21wb25lbnQgc28gdGhlIG5leHQgdGltZSB0aGUgTEMgaXMgdXBkYXRlZCwgd2UgY2FuIGFwcGx5XG4gICAgICAvLyB0aGUgc2tpcCBvcHRpbWl6YXRpb25cbiAgICAgIGlmIChjaGFuZ2VUcmFja2luZyB8fCByZW5kZXJlZC5tYWdpY0lkKSB7XG4gICAgICAgIHNraXAgPSBjaGFuZ2VUcmFja2luZyAmJiAhcmVuZGVyZWQubmV3UmVuZGVyO1xuICAgICAgICBhdHRycyA9IHsgW1BIWF9NQUdJQ19JRF06IHJlbmRlcmVkLm1hZ2ljSWQsIC4uLnJvb3RBdHRycyB9O1xuICAgICAgfSBlbHNlIHtcbiAgICAgICAgYXR0cnMgPSByb290QXR0cnM7XG4gICAgICB9XG4gICAgICBpZiAoc2tpcCkge1xuICAgICAgICBhdHRyc1tQSFhfU0tJUF0gPSB0cnVlO1xuICAgICAgfVxuICAgICAgY29uc3QgW25ld1Jvb3QsIGNvbW1lbnRCZWZvcmUsIGNvbW1lbnRBZnRlcl0gPSBtb2RpZnlSb290KFxuICAgICAgICBvdXRwdXQuYnVmZmVyLFxuICAgICAgICBhdHRycyxcbiAgICAgICAgc2tpcCxcbiAgICAgICk7XG4gICAgICByZW5kZXJlZC5uZXdSZW5kZXIgPSBmYWxzZTtcbiAgICAgIG91dHB1dC5idWZmZXIgPSBwcmV2QnVmZmVyICsgY29tbWVudEJlZm9yZSArIG5ld1Jvb3QgKyBjb21tZW50QWZ0ZXI7XG4gICAgfVxuICB9XG5cbiAgY29tcHJlaGVuc2lvblRvQnVmZmVyKHJlbmRlcmVkLCB0ZW1wbGF0ZXMsIG91dHB1dCwgY2hhbmdlVHJhY2tpbmcpIHtcbiAgICBjb25zdCBrZXllZFRlbXBsYXRlcyA9IHRlbXBsYXRlcyB8fCByZW5kZXJlZFtURU1QTEFURVNdO1xuICAgIGNvbnN0IHN0YXRpY3MgPSB0aGlzLnRlbXBsYXRlU3RhdGljKHJlbmRlcmVkW1NUQVRJQ10sIHRlbXBsYXRlcyk7XG4gICAgcmVuZGVyZWRbU1RBVElDXSA9IHN0YXRpY3M7XG4gICAgZGVsZXRlIHJlbmRlcmVkW1RFTVBMQVRFU107XG4gICAgZm9yIChsZXQgaSA9IDA7IGkgPCByZW5kZXJlZFtLRVlFRF1bS0VZRURfQ09VTlRdOyBpKyspIHtcbiAgICAgIG91dHB1dC5idWZmZXIgKz0gc3RhdGljc1swXTtcbiAgICAgIGZvciAobGV0IGogPSAxOyBqIDwgc3RhdGljcy5sZW5ndGg7IGorKykge1xuICAgICAgICB0aGlzLmR5bmFtaWNUb0J1ZmZlcihcbiAgICAgICAgICByZW5kZXJlZFtLRVlFRF1baV1baiAtIDFdLFxuICAgICAgICAgIGtleWVkVGVtcGxhdGVzLFxuICAgICAgICAgIG91dHB1dCxcbiAgICAgICAgICBjaGFuZ2VUcmFja2luZyxcbiAgICAgICAgKTtcbiAgICAgICAgb3V0cHV0LmJ1ZmZlciArPSBzdGF0aWNzW2pdO1xuICAgICAgfVxuICAgIH1cbiAgICAvLyB3ZSBkb24ndCBuZWVkIHRvIHN0b3JlIHRoZSByZW5kZXJlZCB0cmVlIGZvciBzdHJlYW1zXG4gICAgaWYgKHJlbmRlcmVkW1NUUkVBTV0pIHtcbiAgICAgIGNvbnN0IHN0cmVhbSA9IHJlbmRlcmVkW1NUUkVBTV07XG4gICAgICBjb25zdCBbX3JlZiwgX2luc2VydHMsIGRlbGV0ZUlkcywgcmVzZXRdID0gc3RyZWFtIHx8IFtudWxsLCB7fSwgW10sIG51bGxdO1xuICAgICAgaWYgKFxuICAgICAgICBzdHJlYW0gIT09IHVuZGVmaW5lZCAmJlxuICAgICAgICAocmVuZGVyZWRbS0VZRURdW0tFWUVEX0NPVU5UXSA+IDAgfHwgZGVsZXRlSWRzLmxlbmd0aCA+IDAgfHwgcmVzZXQpXG4gICAgICApIHtcbiAgICAgICAgZGVsZXRlIHJlbmRlcmVkW1NUUkVBTV07XG4gICAgICAgIHJlbmRlcmVkW0tFWUVEXSA9IHtcbiAgICAgICAgICBbS0VZRURfQ09VTlRdOiAwLFxuICAgICAgICB9O1xuICAgICAgICBvdXRwdXQuc3RyZWFtcy5hZGQoc3RyZWFtKTtcbiAgICAgIH1cbiAgICB9XG4gIH1cblxuICBkeW5hbWljVG9CdWZmZXIocmVuZGVyZWQsIHRlbXBsYXRlcywgb3V0cHV0LCBjaGFuZ2VUcmFja2luZykge1xuICAgIGlmICh0eXBlb2YgcmVuZGVyZWQgPT09IFwibnVtYmVyXCIpIHtcbiAgICAgIGNvbnN0IHsgYnVmZmVyOiBzdHIsIHN0cmVhbXMgfSA9IHRoaXMucmVjdXJzaXZlQ0lEVG9TdHJpbmcoXG4gICAgICAgIG91dHB1dC5jb21wb25lbnRzLFxuICAgICAgICByZW5kZXJlZCxcbiAgICAgICAgb3V0cHV0Lm9ubHlDaWRzLFxuICAgICAgKTtcbiAgICAgIG91dHB1dC5idWZmZXIgKz0gc3RyO1xuICAgICAgb3V0cHV0LnN0cmVhbXMgPSBuZXcgU2V0KFsuLi5vdXRwdXQuc3RyZWFtcywgLi4uc3RyZWFtc10pO1xuICAgIH0gZWxzZSBpZiAoaXNPYmplY3QocmVuZGVyZWQpKSB7XG4gICAgICB0aGlzLnRvT3V0cHV0QnVmZmVyKHJlbmRlcmVkLCB0ZW1wbGF0ZXMsIG91dHB1dCwgY2hhbmdlVHJhY2tpbmcsIHt9KTtcbiAgICB9IGVsc2Uge1xuICAgICAgb3V0cHV0LmJ1ZmZlciArPSByZW5kZXJlZDtcbiAgICB9XG4gIH1cblxuICByZWN1cnNpdmVDSURUb1N0cmluZyhjb21wb25lbnRzLCBjaWQsIG9ubHlDaWRzKSB7XG4gICAgY29uc3QgY29tcG9uZW50ID1cbiAgICAgIGNvbXBvbmVudHNbY2lkXSB8fCBsb2dFcnJvcihgbm8gY29tcG9uZW50IGZvciBDSUQgJHtjaWR9YCwgY29tcG9uZW50cyk7XG4gICAgY29uc3QgYXR0cnMgPSB7IFtQSFhfQ09NUE9ORU5UXTogY2lkLCBbUEhYX1ZJRVdfUkVGXTogdGhpcy52aWV3SWQgfTtcbiAgICBjb25zdCBza2lwID0gb25seUNpZHMgJiYgIW9ubHlDaWRzLmhhcyhjaWQpO1xuICAgIC8vIFR3byBvcHRpbWl6YXRpb24gcGF0aHMgYXBwbHkgaGVyZTpcbiAgICAvL1xuICAgIC8vICAgMS4gVGhlIG9ubHlDaWRzIG9wdGltaXphdGlvbiB3b3JrcyBieSB0aGUgc2VydmVyIGRpZmYgdGVsbGluZyB1cyBvbmx5IHNwZWNpZmljXG4gICAgLy8gICAgIGNpZCdzIGhhdmUgY2hhbmdlZC4gVGhpcyBhbGxvd3MgdXMgdG8gc2tpcCByZW5kZXJpbmcgYW55IGNvbXBvbmVudCB0aGF0IGhhc24ndCBjaGFuZ2VkLFxuICAgIC8vICAgICB3aGljaCB1bHRpbWF0ZWx5IHNldHMgUEhYX1NLSVAgcm9vdCBhdHRyaWJ1dGUgYW5kIGF2b2lkcyByZW5kZXJpbmcgdGhlIGlubmVySFRNTC5cbiAgICAvL1xuICAgIC8vICAgMi4gVGhlIHJvb3QgUEhYX1NLSVAgb3B0aW1pemF0aW9uIGdlbmVyYWxpemVzIHRvIGFsbCBIRUV4IGZ1bmN0aW9uIGNvbXBvbmVudHMsIGFuZFxuICAgIC8vICAgICB3b3JrcyBpbiB0aGUgc2FtZSBQSFhfU0tJUCBhdHRyaWJ1dGUgZmFzaGlvbiBhcyAxLCBidXQgdGhlIG5ld1JlbmRlciB0cmFja2luZyBpcyBkb25lXG4gICAgLy8gICAgIGF0IHRoZSBnZW5lcmFsIGRpZmYgbWVyZ2UgbGV2ZWwuIElmIHdlIG1lcmdlIGEgZGlmZiB3aXRoIG5ldyBkeW5hbWljcywgd2UgbmVjZXNzYXJpbHkgaGF2ZVxuICAgIC8vICAgICBleHBlcmllbmNlZCBhIGNoYW5nZSB3aGljaCBtdXN0IGJlIGEgbmV3UmVuZGVyLCBhbmQgdGh1cyB3ZSBjYW4ndCBza2lwIHRoZSByZW5kZXIuXG4gICAgLy9cbiAgICAvLyBCb3RoIG9wdGltaXphdGlvbiBmbG93cyBhcHBseSBoZXJlLiBuZXdSZW5kZXIgaXMgc2V0IGJhc2VkIG9uIHRoZSBvbmx5Q2lkcyBvcHRpbWl6YXRpb24sIGFuZFxuICAgIC8vIHdlIHRyYWNrIGEgZGV0ZXJtaW5pc3RpYyBtYWdpY0lkIGJhc2VkIG9uIHRoZSBjaWQuXG4gICAgLy9cbiAgICAvLyBjaGFuZ2VUcmFja2luZyBpcyBhYm91dCB0aGUgZW50aXJlIHRyZWVcbiAgICAvLyBuZXdSZW5kZXIgaXMgYWJvdXQgdGhlIGN1cnJlbnQgcm9vdCBpbiB0aGUgdHJlZVxuICAgIC8vXG4gICAgLy8gQnkgZGVmYXVsdCBjaGFuZ2VUcmFja2luZyBpcyBlbmFibGVkLCBidXQgd2Ugc3BlY2lhbCBjYXNlIHRoZSBmbG93IHdoZXJlIHRoZSBjbGllbnQgaXMgcHJ1bmluZ1xuICAgIC8vIGNpZHMgYW5kIHRoZSBzZXJ2ZXIgYWRkcyB0aGUgY29tcG9uZW50IGJhY2suIEluIHN1Y2ggY2FzZXMsIHdlIGV4cGxpY2l0bHkgZGlzYWJsZSBjaGFuZ2VUcmFja2luZ1xuICAgIC8vIHdpdGggcmVzZXRSZW5kZXIgZm9yIHRoaXMgY2lkLCB0aGVuIHJlLWVuYWJsZSBpdCBhZnRlciB0aGUgcmVjdXJzaXZlIGNhbGwgdG8gc2tpcCB0aGUgb3B0aW1pemF0aW9uXG4gICAgLy8gZm9yIHRoZSBlbnRpcmUgY29tcG9uZW50IHRyZWUuXG4gICAgY29tcG9uZW50Lm5ld1JlbmRlciA9ICFza2lwO1xuICAgIGNvbXBvbmVudC5tYWdpY0lkID0gYGMke2NpZH0tJHt0aGlzLnBhcmVudFZpZXdJZCgpfWA7XG4gICAgLy8gZW5hYmxlIGNoYW5nZSB0cmFja2luZyBhcyBsb25nIGFzIHRoZSBjb21wb25lbnQgaGFzbid0IGJlZW4gcmVzZXRcbiAgICBjb25zdCBjaGFuZ2VUcmFja2luZyA9ICFjb21wb25lbnQucmVzZXQ7XG4gICAgY29uc3QgeyBidWZmZXI6IGh0bWwsIHN0cmVhbXMgfSA9IHRoaXMucmVjdXJzaXZlVG9TdHJpbmcoXG4gICAgICBjb21wb25lbnQsXG4gICAgICBjb21wb25lbnRzLFxuICAgICAgb25seUNpZHMsXG4gICAgICBjaGFuZ2VUcmFja2luZyxcbiAgICAgIGF0dHJzLFxuICAgICk7XG4gICAgLy8gZGlzYWJsZSByZXNldCBhZnRlciB3ZSd2ZSByZW5kZXJlZFxuICAgIGRlbGV0ZSBjb21wb25lbnQucmVzZXQ7XG5cbiAgICByZXR1cm4geyBidWZmZXI6IGh0bWwsIHN0cmVhbXM6IHN0cmVhbXMgfTtcbiAgfVxufVxuIiwgImltcG9ydCBET00gZnJvbSBcIi4vZG9tXCI7XG5pbXBvcnQgQVJJQSBmcm9tIFwiLi9hcmlhXCI7XG5cbmNvbnN0IGZvY3VzU3RhY2sgPSBbXTtcbmNvbnN0IGRlZmF1bHRfdHJhbnNpdGlvbl90aW1lID0gMjAwO1xuXG5jb25zdCBKUyA9IHtcbiAgLy8gcHJpdmF0ZVxuICBleGVjKGUsIGV2ZW50VHlwZSwgcGh4RXZlbnQsIHZpZXcsIHNvdXJjZUVsLCBkZWZhdWx0cykge1xuICAgIGNvbnN0IFtkZWZhdWx0S2luZCwgZGVmYXVsdEFyZ3NdID0gZGVmYXVsdHMgfHwgW1xuICAgICAgbnVsbCxcbiAgICAgIHsgY2FsbGJhY2s6IGRlZmF1bHRzICYmIGRlZmF1bHRzLmNhbGxiYWNrIH0sXG4gICAgXTtcbiAgICBjb25zdCBjb21tYW5kcyA9XG4gICAgICBwaHhFdmVudC5jaGFyQXQoMCkgPT09IFwiW1wiXG4gICAgICAgID8gSlNPTi5wYXJzZShwaHhFdmVudClcbiAgICAgICAgOiBbW2RlZmF1bHRLaW5kLCBkZWZhdWx0QXJnc11dO1xuXG4gICAgY29tbWFuZHMuZm9yRWFjaCgoW2tpbmQsIGFyZ3NdKSA9PiB7XG4gICAgICBpZiAoa2luZCA9PT0gZGVmYXVsdEtpbmQpIHtcbiAgICAgICAgLy8gYWx3YXlzIHByZWZlciB0aGUgYXJncywgYnV0IGtlZXAgZXhpc3Rpbmcga2V5cyBmcm9tIHRoZSBkZWZhdWx0QXJnc1xuICAgICAgICBhcmdzID0geyAuLi5kZWZhdWx0QXJncywgLi4uYXJncyB9O1xuICAgICAgICBhcmdzLmNhbGxiYWNrID0gYXJncy5jYWxsYmFjayB8fCBkZWZhdWx0QXJncy5jYWxsYmFjaztcbiAgICAgIH1cbiAgICAgIHRoaXMuZmlsdGVyVG9FbHModmlldy5saXZlU29ja2V0LCBzb3VyY2VFbCwgYXJncykuZm9yRWFjaCgoZWwpID0+IHtcbiAgICAgICAgdGhpc1tgZXhlY18ke2tpbmR9YF0oZSwgZXZlbnRUeXBlLCBwaHhFdmVudCwgdmlldywgc291cmNlRWwsIGVsLCBhcmdzKTtcbiAgICAgIH0pO1xuICAgIH0pO1xuICB9LFxuXG4gIGlzVmlzaWJsZShlbCkge1xuICAgIHJldHVybiAhIShcbiAgICAgIGVsLm9mZnNldFdpZHRoIHx8XG4gICAgICBlbC5vZmZzZXRIZWlnaHQgfHxcbiAgICAgIGVsLmdldENsaWVudFJlY3RzKCkubGVuZ3RoID4gMFxuICAgICk7XG4gIH0sXG5cbiAgLy8gcmV0dXJucyB0cnVlIGlmIGFueSBwYXJ0IG9mIHRoZSBlbGVtZW50IGlzIGluc2lkZSB0aGUgdmlld3BvcnRcbiAgaXNJblZpZXdwb3J0KGVsKSB7XG4gICAgY29uc3QgcmVjdCA9IGVsLmdldEJvdW5kaW5nQ2xpZW50UmVjdCgpO1xuICAgIGNvbnN0IHdpbmRvd0hlaWdodCA9XG4gICAgICB3aW5kb3cuaW5uZXJIZWlnaHQgfHwgZG9jdW1lbnQuZG9jdW1lbnRFbGVtZW50LmNsaWVudEhlaWdodDtcbiAgICBjb25zdCB3aW5kb3dXaWR0aCA9XG4gICAgICB3aW5kb3cuaW5uZXJXaWR0aCB8fCBkb2N1bWVudC5kb2N1bWVudEVsZW1lbnQuY2xpZW50V2lkdGg7XG5cbiAgICByZXR1cm4gKFxuICAgICAgcmVjdC5yaWdodCA+IDAgJiZcbiAgICAgIHJlY3QuYm90dG9tID4gMCAmJlxuICAgICAgcmVjdC5sZWZ0IDwgd2luZG93V2lkdGggJiZcbiAgICAgIHJlY3QudG9wIDwgd2luZG93SGVpZ2h0XG4gICAgKTtcbiAgfSxcblxuICAvLyBwcml2YXRlXG5cbiAgLy8gY29tbWFuZHNcblxuICBleGVjX2V4ZWMoZSwgZXZlbnRUeXBlLCBwaHhFdmVudCwgdmlldywgc291cmNlRWwsIGVsLCB7IGF0dHIsIHRvIH0pIHtcbiAgICBjb25zdCBlbmNvZGVkSlMgPSBlbC5nZXRBdHRyaWJ1dGUoYXR0cik7XG4gICAgaWYgKCFlbmNvZGVkSlMpIHtcbiAgICAgIHRocm93IG5ldyBFcnJvcihgZXhwZWN0ZWQgJHthdHRyfSB0byBjb250YWluIEpTIGNvbW1hbmQgb24gXCIke3RvfVwiYCk7XG4gICAgfVxuICAgIHZpZXcubGl2ZVNvY2tldC5leGVjSlMoZWwsIGVuY29kZWRKUywgZXZlbnRUeXBlKTtcbiAgfSxcblxuICBleGVjX2Rpc3BhdGNoKFxuICAgIGUsXG4gICAgZXZlbnRUeXBlLFxuICAgIHBoeEV2ZW50LFxuICAgIHZpZXcsXG4gICAgc291cmNlRWwsXG4gICAgZWwsXG4gICAgeyBldmVudCwgZGV0YWlsLCBidWJibGVzLCBibG9ja2luZyB9LFxuICApIHtcbiAgICBkZXRhaWwgPSBkZXRhaWwgfHwge307XG4gICAgZGV0YWlsLmRpc3BhdGNoZXIgPSBzb3VyY2VFbDtcbiAgICBpZiAoYmxvY2tpbmcpIHtcbiAgICAgIGNvbnN0IHByb21pc2UgPSBuZXcgUHJvbWlzZSgocmVzb2x2ZSwgX3JlamVjdCkgPT4ge1xuICAgICAgICBkZXRhaWwuZG9uZSA9IHJlc29sdmU7XG4gICAgICB9KTtcbiAgICAgIHZpZXcubGl2ZVNvY2tldC5hc3luY1RyYW5zaXRpb24ocHJvbWlzZSk7XG4gICAgfVxuICAgIERPTS5kaXNwYXRjaEV2ZW50KGVsLCBldmVudCwgeyBkZXRhaWwsIGJ1YmJsZXMgfSk7XG4gIH0sXG5cbiAgZXhlY19wdXNoKGUsIGV2ZW50VHlwZSwgcGh4RXZlbnQsIHZpZXcsIHNvdXJjZUVsLCBlbCwgYXJncykge1xuICAgIGNvbnN0IHtcbiAgICAgIGV2ZW50LFxuICAgICAgZGF0YSxcbiAgICAgIHRhcmdldCxcbiAgICAgIHBhZ2VfbG9hZGluZyxcbiAgICAgIGxvYWRpbmcsXG4gICAgICB2YWx1ZSxcbiAgICAgIGRpc3BhdGNoZXIsXG4gICAgICBjYWxsYmFjayxcbiAgICB9ID0gYXJncztcbiAgICBjb25zdCBwdXNoT3B0cyA9IHtcbiAgICAgIGxvYWRpbmcsXG4gICAgICB2YWx1ZSxcbiAgICAgIHRhcmdldCxcbiAgICAgIHBhZ2VfbG9hZGluZzogISFwYWdlX2xvYWRpbmcsXG4gICAgICBvcmlnaW5hbEV2ZW50OiBlLFxuICAgIH07XG4gICAgY29uc3QgdGFyZ2V0U3JjID1cbiAgICAgIGV2ZW50VHlwZSA9PT0gXCJjaGFuZ2VcIiAmJiBkaXNwYXRjaGVyID8gZGlzcGF0Y2hlciA6IHNvdXJjZUVsO1xuICAgIGNvbnN0IHBoeFRhcmdldCA9XG4gICAgICB0YXJnZXQgfHwgdGFyZ2V0U3JjLmdldEF0dHJpYnV0ZSh2aWV3LmJpbmRpbmcoXCJ0YXJnZXRcIikpIHx8IHRhcmdldFNyYztcbiAgICBjb25zdCBoYW5kbGVyID0gKHRhcmdldFZpZXcsIHRhcmdldEN0eCkgPT4ge1xuICAgICAgaWYgKCF0YXJnZXRWaWV3LmlzQ29ubmVjdGVkKCkpIHtcbiAgICAgICAgcmV0dXJuO1xuICAgICAgfVxuICAgICAgaWYgKGV2ZW50VHlwZSA9PT0gXCJjaGFuZ2VcIikge1xuICAgICAgICBsZXQgeyBuZXdDaWQsIF90YXJnZXQgfSA9IGFyZ3M7XG4gICAgICAgIF90YXJnZXQgPVxuICAgICAgICAgIF90YXJnZXQgfHwgKERPTS5pc0Zvcm1JbnB1dChzb3VyY2VFbCkgPyBzb3VyY2VFbC5uYW1lIDogdW5kZWZpbmVkKTtcbiAgICAgICAgaWYgKF90YXJnZXQpIHtcbiAgICAgICAgICBwdXNoT3B0cy5fdGFyZ2V0ID0gX3RhcmdldDtcbiAgICAgICAgfVxuICAgICAgICB0YXJnZXRWaWV3LnB1c2hJbnB1dChcbiAgICAgICAgICBzb3VyY2VFbCxcbiAgICAgICAgICB0YXJnZXRDdHgsXG4gICAgICAgICAgbmV3Q2lkLFxuICAgICAgICAgIGV2ZW50IHx8IHBoeEV2ZW50LFxuICAgICAgICAgIHB1c2hPcHRzLFxuICAgICAgICAgIGNhbGxiYWNrLFxuICAgICAgICApO1xuICAgICAgfSBlbHNlIGlmIChldmVudFR5cGUgPT09IFwic3VibWl0XCIpIHtcbiAgICAgICAgY29uc3QgeyBzdWJtaXR0ZXIgfSA9IGFyZ3M7XG4gICAgICAgIHRhcmdldFZpZXcuc3VibWl0Rm9ybShcbiAgICAgICAgICBzb3VyY2VFbCxcbiAgICAgICAgICB0YXJnZXRDdHgsXG4gICAgICAgICAgZXZlbnQgfHwgcGh4RXZlbnQsXG4gICAgICAgICAgc3VibWl0dGVyLFxuICAgICAgICAgIHB1c2hPcHRzLFxuICAgICAgICAgIGNhbGxiYWNrLFxuICAgICAgICApO1xuICAgICAgfSBlbHNlIHtcbiAgICAgICAgdGFyZ2V0Vmlldy5wdXNoRXZlbnQoXG4gICAgICAgICAgZXZlbnRUeXBlLFxuICAgICAgICAgIHNvdXJjZUVsLFxuICAgICAgICAgIHRhcmdldEN0eCxcbiAgICAgICAgICBldmVudCB8fCBwaHhFdmVudCxcbiAgICAgICAgICBkYXRhLFxuICAgICAgICAgIHB1c2hPcHRzLFxuICAgICAgICAgIGNhbGxiYWNrLFxuICAgICAgICApO1xuICAgICAgfVxuICAgIH07XG4gICAgLy8gaW4gY2FzZSBvZiBmb3JtUmVjb3ZlcnksIHRhcmdldFZpZXcgYW5kIHRhcmdldEN0eCBhcmUgcGFzc2VkIGFzIGFyZ3VtZW50XG4gICAgLy8gYXMgdGhleSBhcmUgbG9va2VkIHVwIGluIGEgdGVtcGxhdGUgZWxlbWVudCwgbm90IHRoZSByZWFsIERPTVxuICAgIGlmIChhcmdzLnRhcmdldFZpZXcgJiYgYXJncy50YXJnZXRDdHgpIHtcbiAgICAgIGhhbmRsZXIoYXJncy50YXJnZXRWaWV3LCBhcmdzLnRhcmdldEN0eCk7XG4gICAgfSBlbHNlIHtcbiAgICAgIHZpZXcud2l0aGluVGFyZ2V0cyhwaHhUYXJnZXQsIGhhbmRsZXIpO1xuICAgIH1cbiAgfSxcblxuICBleGVjX25hdmlnYXRlKGUsIGV2ZW50VHlwZSwgcGh4RXZlbnQsIHZpZXcsIHNvdXJjZUVsLCBlbCwgeyBocmVmLCByZXBsYWNlIH0pIHtcbiAgICB2aWV3LmxpdmVTb2NrZXQuaGlzdG9yeVJlZGlyZWN0KFxuICAgICAgZSxcbiAgICAgIGhyZWYsXG4gICAgICByZXBsYWNlID8gXCJyZXBsYWNlXCIgOiBcInB1c2hcIixcbiAgICAgIG51bGwsXG4gICAgICBzb3VyY2VFbCxcbiAgICApO1xuICB9LFxuXG4gIGV4ZWNfcGF0Y2goZSwgZXZlbnRUeXBlLCBwaHhFdmVudCwgdmlldywgc291cmNlRWwsIGVsLCB7IGhyZWYsIHJlcGxhY2UgfSkge1xuICAgIHZpZXcubGl2ZVNvY2tldC5wdXNoSGlzdG9yeVBhdGNoKFxuICAgICAgZSxcbiAgICAgIGhyZWYsXG4gICAgICByZXBsYWNlID8gXCJyZXBsYWNlXCIgOiBcInB1c2hcIixcbiAgICAgIHNvdXJjZUVsLFxuICAgICk7XG4gIH0sXG5cbiAgZXhlY19mb2N1cyhlLCBldmVudFR5cGUsIHBoeEV2ZW50LCB2aWV3LCBzb3VyY2VFbCwgZWwpIHtcbiAgICBBUklBLmF0dGVtcHRGb2N1cyhlbCk7XG4gICAgLy8gaW4gY2FzZSB0aGUgSlMuZm9jdXMgY29tbWFuZCBpcyBpbiBhIEpTLnNob3cvaGlkZS90b2dnbGUgY2hhaW4sIGZvciBzaG93IHdlIG5lZWRcbiAgICAvLyB0byB3YWl0IGZvciBKUy5zaG93IHRvIGhhdmUgdXBkYXRlZCB0aGUgZWxlbWVudCdzIGRpc3BsYXkgcHJvcGVydHkgKHNlZSBleGVjX3RvZ2dsZSlcbiAgICAvLyBidXQgdGhhdCBydW4gaW4gbmVzdGVkIGFuaW1hdGlvbiBmcmFtZXMsIHRoZXJlZm9yZSB3ZSBuZWVkIHRvIHVzZSB0aGVtIGhlcmUgYXMgd2VsbFxuICAgIHdpbmRvdy5yZXF1ZXN0QW5pbWF0aW9uRnJhbWUoKCkgPT4ge1xuICAgICAgd2luZG93LnJlcXVlc3RBbmltYXRpb25GcmFtZSgoKSA9PiBBUklBLmF0dGVtcHRGb2N1cyhlbCkpO1xuICAgIH0pO1xuICB9LFxuXG4gIGV4ZWNfZm9jdXNfZmlyc3QoZSwgZXZlbnRUeXBlLCBwaHhFdmVudCwgdmlldywgc291cmNlRWwsIGVsKSB7XG4gICAgQVJJQS5mb2N1c0ZpcnN0SW50ZXJhY3RpdmUoZWwpIHx8IEFSSUEuZm9jdXNGaXJzdChlbCk7XG4gICAgLy8gaWYgeW91IHdvbmRlciBhYm91dCB0aGUgbmVzdGVkIGFuaW1hdGlvbiBmcmFtZXMsIHNlZSBleGVjX2ZvY3VzXG4gICAgd2luZG93LnJlcXVlc3RBbmltYXRpb25GcmFtZSgoKSA9PiB7XG4gICAgICB3aW5kb3cucmVxdWVzdEFuaW1hdGlvbkZyYW1lKFxuICAgICAgICAoKSA9PiBBUklBLmZvY3VzRmlyc3RJbnRlcmFjdGl2ZShlbCkgfHwgQVJJQS5mb2N1c0ZpcnN0KGVsKSxcbiAgICAgICk7XG4gICAgfSk7XG4gIH0sXG5cbiAgZXhlY19wdXNoX2ZvY3VzKGUsIGV2ZW50VHlwZSwgcGh4RXZlbnQsIHZpZXcsIHNvdXJjZUVsLCBlbCkge1xuICAgIGZvY3VzU3RhY2sucHVzaChlbCB8fCBzb3VyY2VFbCk7XG4gIH0sXG5cbiAgZXhlY19wb3BfZm9jdXMoX2UsIF9ldmVudFR5cGUsIF9waHhFdmVudCwgX3ZpZXcsIF9zb3VyY2VFbCwgX2VsKSB7XG4gICAgY29uc3QgZWwgPSBmb2N1c1N0YWNrLnBvcCgpO1xuICAgIGlmIChlbCkge1xuICAgICAgZWwuZm9jdXMoKTtcbiAgICAgIC8vIGlmIHlvdSB3b25kZXIgYWJvdXQgdGhlIG5lc3RlZCBhbmltYXRpb24gZnJhbWVzLCBzZWUgZXhlY19mb2N1c1xuICAgICAgd2luZG93LnJlcXVlc3RBbmltYXRpb25GcmFtZSgoKSA9PiB7XG4gICAgICAgIHdpbmRvdy5yZXF1ZXN0QW5pbWF0aW9uRnJhbWUoKCkgPT4gZWwuZm9jdXMoKSk7XG4gICAgICB9KTtcbiAgICB9XG4gIH0sXG5cbiAgZXhlY19hZGRfY2xhc3MoXG4gICAgZSxcbiAgICBldmVudFR5cGUsXG4gICAgcGh4RXZlbnQsXG4gICAgdmlldyxcbiAgICBzb3VyY2VFbCxcbiAgICBlbCxcbiAgICB7IG5hbWVzLCB0cmFuc2l0aW9uLCB0aW1lLCBibG9ja2luZyB9LFxuICApIHtcbiAgICB0aGlzLmFkZE9yUmVtb3ZlQ2xhc3NlcyhlbCwgbmFtZXMsIFtdLCB0cmFuc2l0aW9uLCB0aW1lLCB2aWV3LCBibG9ja2luZyk7XG4gIH0sXG5cbiAgZXhlY19yZW1vdmVfY2xhc3MoXG4gICAgZSxcbiAgICBldmVudFR5cGUsXG4gICAgcGh4RXZlbnQsXG4gICAgdmlldyxcbiAgICBzb3VyY2VFbCxcbiAgICBlbCxcbiAgICB7IG5hbWVzLCB0cmFuc2l0aW9uLCB0aW1lLCBibG9ja2luZyB9LFxuICApIHtcbiAgICB0aGlzLmFkZE9yUmVtb3ZlQ2xhc3NlcyhlbCwgW10sIG5hbWVzLCB0cmFuc2l0aW9uLCB0aW1lLCB2aWV3LCBibG9ja2luZyk7XG4gIH0sXG5cbiAgZXhlY190b2dnbGVfY2xhc3MoXG4gICAgZSxcbiAgICBldmVudFR5cGUsXG4gICAgcGh4RXZlbnQsXG4gICAgdmlldyxcbiAgICBzb3VyY2VFbCxcbiAgICBlbCxcbiAgICB7IG5hbWVzLCB0cmFuc2l0aW9uLCB0aW1lLCBibG9ja2luZyB9LFxuICApIHtcbiAgICB0aGlzLnRvZ2dsZUNsYXNzZXMoZWwsIG5hbWVzLCB0cmFuc2l0aW9uLCB0aW1lLCB2aWV3LCBibG9ja2luZyk7XG4gIH0sXG5cbiAgZXhlY190b2dnbGVfYXR0cihcbiAgICBlLFxuICAgIGV2ZW50VHlwZSxcbiAgICBwaHhFdmVudCxcbiAgICB2aWV3LFxuICAgIHNvdXJjZUVsLFxuICAgIGVsLFxuICAgIHsgYXR0cjogW2F0dHIsIHZhbDEsIHZhbDJdIH0sXG4gICkge1xuICAgIHRoaXMudG9nZ2xlQXR0cihlbCwgYXR0ciwgdmFsMSwgdmFsMik7XG4gIH0sXG5cbiAgZXhlY19pZ25vcmVfYXR0cnMoZSwgZXZlbnRUeXBlLCBwaHhFdmVudCwgdmlldywgc291cmNlRWwsIGVsLCB7IGF0dHJzIH0pIHtcbiAgICB0aGlzLmlnbm9yZUF0dHJzKGVsLCBhdHRycyk7XG4gIH0sXG5cbiAgZXhlY190cmFuc2l0aW9uKFxuICAgIGUsXG4gICAgZXZlbnRUeXBlLFxuICAgIHBoeEV2ZW50LFxuICAgIHZpZXcsXG4gICAgc291cmNlRWwsXG4gICAgZWwsXG4gICAgeyB0aW1lLCB0cmFuc2l0aW9uLCBibG9ja2luZyB9LFxuICApIHtcbiAgICB0aGlzLmFkZE9yUmVtb3ZlQ2xhc3NlcyhlbCwgW10sIFtdLCB0cmFuc2l0aW9uLCB0aW1lLCB2aWV3LCBibG9ja2luZyk7XG4gIH0sXG5cbiAgZXhlY190b2dnbGUoXG4gICAgZSxcbiAgICBldmVudFR5cGUsXG4gICAgcGh4RXZlbnQsXG4gICAgdmlldyxcbiAgICBzb3VyY2VFbCxcbiAgICBlbCxcbiAgICB7IGRpc3BsYXksIGlucywgb3V0cywgdGltZSwgYmxvY2tpbmcgfSxcbiAgKSB7XG4gICAgdGhpcy50b2dnbGUoZXZlbnRUeXBlLCB2aWV3LCBlbCwgZGlzcGxheSwgaW5zLCBvdXRzLCB0aW1lLCBibG9ja2luZyk7XG4gIH0sXG5cbiAgZXhlY19zaG93KFxuICAgIGUsXG4gICAgZXZlbnRUeXBlLFxuICAgIHBoeEV2ZW50LFxuICAgIHZpZXcsXG4gICAgc291cmNlRWwsXG4gICAgZWwsXG4gICAgeyBkaXNwbGF5LCB0cmFuc2l0aW9uLCB0aW1lLCBibG9ja2luZyB9LFxuICApIHtcbiAgICB0aGlzLnNob3coZXZlbnRUeXBlLCB2aWV3LCBlbCwgZGlzcGxheSwgdHJhbnNpdGlvbiwgdGltZSwgYmxvY2tpbmcpO1xuICB9LFxuXG4gIGV4ZWNfaGlkZShcbiAgICBlLFxuICAgIGV2ZW50VHlwZSxcbiAgICBwaHhFdmVudCxcbiAgICB2aWV3LFxuICAgIHNvdXJjZUVsLFxuICAgIGVsLFxuICAgIHsgZGlzcGxheSwgdHJhbnNpdGlvbiwgdGltZSwgYmxvY2tpbmcgfSxcbiAgKSB7XG4gICAgdGhpcy5oaWRlKGV2ZW50VHlwZSwgdmlldywgZWwsIGRpc3BsYXksIHRyYW5zaXRpb24sIHRpbWUsIGJsb2NraW5nKTtcbiAgfSxcblxuICBleGVjX3NldF9hdHRyKFxuICAgIGUsXG4gICAgZXZlbnRUeXBlLFxuICAgIHBoeEV2ZW50LFxuICAgIHZpZXcsXG4gICAgc291cmNlRWwsXG4gICAgZWwsXG4gICAgeyBhdHRyOiBbYXR0ciwgdmFsXSB9LFxuICApIHtcbiAgICB0aGlzLnNldE9yUmVtb3ZlQXR0cnMoZWwsIFtbYXR0ciwgdmFsXV0sIFtdKTtcbiAgfSxcblxuICBleGVjX3JlbW92ZV9hdHRyKGUsIGV2ZW50VHlwZSwgcGh4RXZlbnQsIHZpZXcsIHNvdXJjZUVsLCBlbCwgeyBhdHRyIH0pIHtcbiAgICB0aGlzLnNldE9yUmVtb3ZlQXR0cnMoZWwsIFtdLCBbYXR0cl0pO1xuICB9LFxuXG4gIGlnbm9yZUF0dHJzKGVsLCBhdHRycykge1xuICAgIERPTS5wdXRQcml2YXRlKGVsLCBcIkpTOmlnbm9yZV9hdHRyc1wiLCB7XG4gICAgICBhcHBseTogKGZyb21FbCwgdG9FbCkgPT4ge1xuICAgICAgICBBcnJheS5mcm9tKGZyb21FbC5hdHRyaWJ1dGVzKS5mb3JFYWNoKChhdHRyKSA9PiB7XG4gICAgICAgICAgaWYgKFxuICAgICAgICAgICAgYXR0cnMuc29tZShcbiAgICAgICAgICAgICAgKHRvSWdub3JlKSA9PlxuICAgICAgICAgICAgICAgIGF0dHIubmFtZSA9PSB0b0lnbm9yZSB8fFxuICAgICAgICAgICAgICAgICh0b0lnbm9yZS5pbmNsdWRlcyhcIipcIikgJiYgYXR0ci5uYW1lLm1hdGNoKHRvSWdub3JlKSAhPSBudWxsKSxcbiAgICAgICAgICAgIClcbiAgICAgICAgICApIHtcbiAgICAgICAgICAgIHRvRWwuc2V0QXR0cmlidXRlKGF0dHIubmFtZSwgYXR0ci52YWx1ZSk7XG4gICAgICAgICAgfVxuICAgICAgICB9KTtcbiAgICAgIH0sXG4gICAgfSk7XG4gIH0sXG5cbiAgb25CZWZvcmVFbFVwZGF0ZWQoZnJvbUVsLCB0b0VsKSB7XG4gICAgY29uc3QgaWdub3JlQXR0cnMgPSBET00ucHJpdmF0ZShmcm9tRWwsIFwiSlM6aWdub3JlX2F0dHJzXCIpO1xuICAgIGlmIChpZ25vcmVBdHRycykge1xuICAgICAgaWdub3JlQXR0cnMuYXBwbHkoZnJvbUVsLCB0b0VsKTtcbiAgICB9XG4gIH0sXG5cbiAgLy8gdXRpbHMgZm9yIGNvbW1hbmRzXG5cbiAgc2hvdyhldmVudFR5cGUsIHZpZXcsIGVsLCBkaXNwbGF5LCB0cmFuc2l0aW9uLCB0aW1lLCBibG9ja2luZykge1xuICAgIGlmICghdGhpcy5pc1Zpc2libGUoZWwpKSB7XG4gICAgICB0aGlzLnRvZ2dsZShcbiAgICAgICAgZXZlbnRUeXBlLFxuICAgICAgICB2aWV3LFxuICAgICAgICBlbCxcbiAgICAgICAgZGlzcGxheSxcbiAgICAgICAgdHJhbnNpdGlvbixcbiAgICAgICAgbnVsbCxcbiAgICAgICAgdGltZSxcbiAgICAgICAgYmxvY2tpbmcsXG4gICAgICApO1xuICAgIH1cbiAgfSxcblxuICBoaWRlKGV2ZW50VHlwZSwgdmlldywgZWwsIGRpc3BsYXksIHRyYW5zaXRpb24sIHRpbWUsIGJsb2NraW5nKSB7XG4gICAgaWYgKHRoaXMuaXNWaXNpYmxlKGVsKSkge1xuICAgICAgdGhpcy50b2dnbGUoXG4gICAgICAgIGV2ZW50VHlwZSxcbiAgICAgICAgdmlldyxcbiAgICAgICAgZWwsXG4gICAgICAgIGRpc3BsYXksXG4gICAgICAgIG51bGwsXG4gICAgICAgIHRyYW5zaXRpb24sXG4gICAgICAgIHRpbWUsXG4gICAgICAgIGJsb2NraW5nLFxuICAgICAgKTtcbiAgICB9XG4gIH0sXG5cbiAgdG9nZ2xlKGV2ZW50VHlwZSwgdmlldywgZWwsIGRpc3BsYXksIGlucywgb3V0cywgdGltZSwgYmxvY2tpbmcpIHtcbiAgICB0aW1lID0gdGltZSB8fCBkZWZhdWx0X3RyYW5zaXRpb25fdGltZTtcbiAgICBjb25zdCBbaW5DbGFzc2VzLCBpblN0YXJ0Q2xhc3NlcywgaW5FbmRDbGFzc2VzXSA9IGlucyB8fCBbW10sIFtdLCBbXV07XG4gICAgY29uc3QgW291dENsYXNzZXMsIG91dFN0YXJ0Q2xhc3Nlcywgb3V0RW5kQ2xhc3Nlc10gPSBvdXRzIHx8IFtbXSwgW10sIFtdXTtcbiAgICBpZiAoaW5DbGFzc2VzLmxlbmd0aCA+IDAgfHwgb3V0Q2xhc3Nlcy5sZW5ndGggPiAwKSB7XG4gICAgICBpZiAodGhpcy5pc1Zpc2libGUoZWwpKSB7XG4gICAgICAgIGNvbnN0IG9uU3RhcnQgPSAoKSA9PiB7XG4gICAgICAgICAgdGhpcy5hZGRPclJlbW92ZUNsYXNzZXMoXG4gICAgICAgICAgICBlbCxcbiAgICAgICAgICAgIG91dFN0YXJ0Q2xhc3NlcyxcbiAgICAgICAgICAgIGluQ2xhc3Nlcy5jb25jYXQoaW5TdGFydENsYXNzZXMpLmNvbmNhdChpbkVuZENsYXNzZXMpLFxuICAgICAgICAgICk7XG4gICAgICAgICAgd2luZG93LnJlcXVlc3RBbmltYXRpb25GcmFtZSgoKSA9PiB7XG4gICAgICAgICAgICB0aGlzLmFkZE9yUmVtb3ZlQ2xhc3NlcyhlbCwgb3V0Q2xhc3NlcywgW10pO1xuICAgICAgICAgICAgd2luZG93LnJlcXVlc3RBbmltYXRpb25GcmFtZSgoKSA9PlxuICAgICAgICAgICAgICB0aGlzLmFkZE9yUmVtb3ZlQ2xhc3NlcyhlbCwgb3V0RW5kQ2xhc3Nlcywgb3V0U3RhcnRDbGFzc2VzKSxcbiAgICAgICAgICAgICk7XG4gICAgICAgICAgfSk7XG4gICAgICAgIH07XG4gICAgICAgIGNvbnN0IG9uRW5kID0gKCkgPT4ge1xuICAgICAgICAgIHRoaXMuYWRkT3JSZW1vdmVDbGFzc2VzKGVsLCBbXSwgb3V0Q2xhc3Nlcy5jb25jYXQob3V0RW5kQ2xhc3NlcykpO1xuICAgICAgICAgIERPTS5wdXRTdGlja3koXG4gICAgICAgICAgICBlbCxcbiAgICAgICAgICAgIFwidG9nZ2xlXCIsXG4gICAgICAgICAgICAoY3VycmVudEVsKSA9PiAoY3VycmVudEVsLnN0eWxlLmRpc3BsYXkgPSBcIm5vbmVcIiksXG4gICAgICAgICAgKTtcbiAgICAgICAgICBlbC5kaXNwYXRjaEV2ZW50KG5ldyBFdmVudChcInBoeDpoaWRlLWVuZFwiKSk7XG4gICAgICAgIH07XG4gICAgICAgIGVsLmRpc3BhdGNoRXZlbnQobmV3IEV2ZW50KFwicGh4OmhpZGUtc3RhcnRcIikpO1xuICAgICAgICBpZiAoYmxvY2tpbmcgPT09IGZhbHNlKSB7XG4gICAgICAgICAgb25TdGFydCgpO1xuICAgICAgICAgIHNldFRpbWVvdXQob25FbmQsIHRpbWUpO1xuICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgIHZpZXcudHJhbnNpdGlvbih0aW1lLCBvblN0YXJ0LCBvbkVuZCk7XG4gICAgICAgIH1cbiAgICAgIH0gZWxzZSB7XG4gICAgICAgIGlmIChldmVudFR5cGUgPT09IFwicmVtb3ZlXCIpIHtcbiAgICAgICAgICByZXR1cm47XG4gICAgICAgIH1cbiAgICAgICAgY29uc3Qgb25TdGFydCA9ICgpID0+IHtcbiAgICAgICAgICB0aGlzLmFkZE9yUmVtb3ZlQ2xhc3NlcyhcbiAgICAgICAgICAgIGVsLFxuICAgICAgICAgICAgaW5TdGFydENsYXNzZXMsXG4gICAgICAgICAgICBvdXRDbGFzc2VzLmNvbmNhdChvdXRTdGFydENsYXNzZXMpLmNvbmNhdChvdXRFbmRDbGFzc2VzKSxcbiAgICAgICAgICApO1xuICAgICAgICAgIGNvbnN0IHN0aWNreURpc3BsYXkgPSBkaXNwbGF5IHx8IHRoaXMuZGVmYXVsdERpc3BsYXkoZWwpO1xuICAgICAgICAgIHdpbmRvdy5yZXF1ZXN0QW5pbWF0aW9uRnJhbWUoKCkgPT4ge1xuICAgICAgICAgICAgLy8gZmlyc3QgYWRkIHRoZSBzdGFydGluZyArIGFjdGl2ZSBjbGFzcywgVEhFTiBtYWtlIHRoZSBlbGVtZW50IHZpc2libGVcbiAgICAgICAgICAgIC8vIG90aGVyd2lzZSBpZiB3ZSB0b2dnbGVkIHRoZSB2aXNpYmlsaXR5IGVhcmxpZXIgY3NzIGFuaW1hdGlvbnNcbiAgICAgICAgICAgIC8vIHdvdWxkIGZsaWNrZXIsIGFzIHRoZSBlbGVtZW50IGJlY29tZXMgdmlzaWJsZSBiZWZvcmUgdGhlIGFjdGl2ZSBhbmltYXRpb25cbiAgICAgICAgICAgIC8vIGNsYXNzIGlzIHNldCAoc2VlIGh0dHBzOi8vZ2l0aHViLmNvbS9waG9lbml4ZnJhbWV3b3JrL3Bob2VuaXhfbGl2ZV92aWV3L2lzc3Vlcy8zNDU2KVxuICAgICAgICAgICAgdGhpcy5hZGRPclJlbW92ZUNsYXNzZXMoZWwsIGluQ2xhc3NlcywgW10pO1xuICAgICAgICAgICAgLy8gYWRkT3JSZW1vdmVDbGFzc2VzIHVzZXMgYSByZXF1ZXN0QW5pbWF0aW9uRnJhbWUgaXRzZWxmLCB0aGVyZWZvcmUgd2UgbmVlZCB0byBtb3ZlIHRoZSBwdXRTdGlja3lcbiAgICAgICAgICAgIC8vIGludG8gdGhlIG5leHQgcmVxdWVzdEFuaW1hdGlvbkZyYW1lLi4uXG4gICAgICAgICAgICB3aW5kb3cucmVxdWVzdEFuaW1hdGlvbkZyYW1lKCgpID0+IHtcbiAgICAgICAgICAgICAgRE9NLnB1dFN0aWNreShcbiAgICAgICAgICAgICAgICBlbCxcbiAgICAgICAgICAgICAgICBcInRvZ2dsZVwiLFxuICAgICAgICAgICAgICAgIChjdXJyZW50RWwpID0+IChjdXJyZW50RWwuc3R5bGUuZGlzcGxheSA9IHN0aWNreURpc3BsYXkpLFxuICAgICAgICAgICAgICApO1xuICAgICAgICAgICAgICB0aGlzLmFkZE9yUmVtb3ZlQ2xhc3NlcyhlbCwgaW5FbmRDbGFzc2VzLCBpblN0YXJ0Q2xhc3Nlcyk7XG4gICAgICAgICAgICB9KTtcbiAgICAgICAgICB9KTtcbiAgICAgICAgfTtcbiAgICAgICAgY29uc3Qgb25FbmQgPSAoKSA9PiB7XG4gICAgICAgICAgdGhpcy5hZGRPclJlbW92ZUNsYXNzZXMoZWwsIFtdLCBpbkNsYXNzZXMuY29uY2F0KGluRW5kQ2xhc3NlcykpO1xuICAgICAgICAgIGVsLmRpc3BhdGNoRXZlbnQobmV3IEV2ZW50KFwicGh4OnNob3ctZW5kXCIpKTtcbiAgICAgICAgfTtcbiAgICAgICAgZWwuZGlzcGF0Y2hFdmVudChuZXcgRXZlbnQoXCJwaHg6c2hvdy1zdGFydFwiKSk7XG4gICAgICAgIGlmIChibG9ja2luZyA9PT0gZmFsc2UpIHtcbiAgICAgICAgICBvblN0YXJ0KCk7XG4gICAgICAgICAgc2V0VGltZW91dChvbkVuZCwgdGltZSk7XG4gICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgdmlldy50cmFuc2l0aW9uKHRpbWUsIG9uU3RhcnQsIG9uRW5kKTtcbiAgICAgICAgfVxuICAgICAgfVxuICAgIH0gZWxzZSB7XG4gICAgICBpZiAodGhpcy5pc1Zpc2libGUoZWwpKSB7XG4gICAgICAgIHdpbmRvdy5yZXF1ZXN0QW5pbWF0aW9uRnJhbWUoKCkgPT4ge1xuICAgICAgICAgIGVsLmRpc3BhdGNoRXZlbnQobmV3IEV2ZW50KFwicGh4OmhpZGUtc3RhcnRcIikpO1xuICAgICAgICAgIERPTS5wdXRTdGlja3koXG4gICAgICAgICAgICBlbCxcbiAgICAgICAgICAgIFwidG9nZ2xlXCIsXG4gICAgICAgICAgICAoY3VycmVudEVsKSA9PiAoY3VycmVudEVsLnN0eWxlLmRpc3BsYXkgPSBcIm5vbmVcIiksXG4gICAgICAgICAgKTtcbiAgICAgICAgICBlbC5kaXNwYXRjaEV2ZW50KG5ldyBFdmVudChcInBoeDpoaWRlLWVuZFwiKSk7XG4gICAgICAgIH0pO1xuICAgICAgfSBlbHNlIHtcbiAgICAgICAgd2luZG93LnJlcXVlc3RBbmltYXRpb25GcmFtZSgoKSA9PiB7XG4gICAgICAgICAgZWwuZGlzcGF0Y2hFdmVudChuZXcgRXZlbnQoXCJwaHg6c2hvdy1zdGFydFwiKSk7XG4gICAgICAgICAgY29uc3Qgc3RpY2t5RGlzcGxheSA9IGRpc3BsYXkgfHwgdGhpcy5kZWZhdWx0RGlzcGxheShlbCk7XG4gICAgICAgICAgRE9NLnB1dFN0aWNreShcbiAgICAgICAgICAgIGVsLFxuICAgICAgICAgICAgXCJ0b2dnbGVcIixcbiAgICAgICAgICAgIChjdXJyZW50RWwpID0+IChjdXJyZW50RWwuc3R5bGUuZGlzcGxheSA9IHN0aWNreURpc3BsYXkpLFxuICAgICAgICAgICk7XG4gICAgICAgICAgZWwuZGlzcGF0Y2hFdmVudChuZXcgRXZlbnQoXCJwaHg6c2hvdy1lbmRcIikpO1xuICAgICAgICB9KTtcbiAgICAgIH1cbiAgICB9XG4gIH0sXG5cbiAgdG9nZ2xlQ2xhc3NlcyhlbCwgY2xhc3NlcywgdHJhbnNpdGlvbiwgdGltZSwgdmlldywgYmxvY2tpbmcpIHtcbiAgICB3aW5kb3cucmVxdWVzdEFuaW1hdGlvbkZyYW1lKCgpID0+IHtcbiAgICAgIGNvbnN0IFtwcmV2QWRkcywgcHJldlJlbW92ZXNdID0gRE9NLmdldFN0aWNreShlbCwgXCJjbGFzc2VzXCIsIFtbXSwgW11dKTtcbiAgICAgIGNvbnN0IG5ld0FkZHMgPSBjbGFzc2VzLmZpbHRlcihcbiAgICAgICAgKG5hbWUpID0+IHByZXZBZGRzLmluZGV4T2YobmFtZSkgPCAwICYmICFlbC5jbGFzc0xpc3QuY29udGFpbnMobmFtZSksXG4gICAgICApO1xuICAgICAgY29uc3QgbmV3UmVtb3ZlcyA9IGNsYXNzZXMuZmlsdGVyKFxuICAgICAgICAobmFtZSkgPT4gcHJldlJlbW92ZXMuaW5kZXhPZihuYW1lKSA8IDAgJiYgZWwuY2xhc3NMaXN0LmNvbnRhaW5zKG5hbWUpLFxuICAgICAgKTtcbiAgICAgIHRoaXMuYWRkT3JSZW1vdmVDbGFzc2VzKFxuICAgICAgICBlbCxcbiAgICAgICAgbmV3QWRkcyxcbiAgICAgICAgbmV3UmVtb3ZlcyxcbiAgICAgICAgdHJhbnNpdGlvbixcbiAgICAgICAgdGltZSxcbiAgICAgICAgdmlldyxcbiAgICAgICAgYmxvY2tpbmcsXG4gICAgICApO1xuICAgIH0pO1xuICB9LFxuXG4gIHRvZ2dsZUF0dHIoZWwsIGF0dHIsIHZhbDEsIHZhbDIpIHtcbiAgICBpZiAoZWwuaGFzQXR0cmlidXRlKGF0dHIpKSB7XG4gICAgICBpZiAodmFsMiAhPT0gdW5kZWZpbmVkKSB7XG4gICAgICAgIC8vIHRvZ2dsZSBiZXR3ZWVuIHZhbDEgYW5kIHZhbDJcbiAgICAgICAgaWYgKGVsLmdldEF0dHJpYnV0ZShhdHRyKSA9PT0gdmFsMSkge1xuICAgICAgICAgIHRoaXMuc2V0T3JSZW1vdmVBdHRycyhlbCwgW1thdHRyLCB2YWwyXV0sIFtdKTtcbiAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICB0aGlzLnNldE9yUmVtb3ZlQXR0cnMoZWwsIFtbYXR0ciwgdmFsMV1dLCBbXSk7XG4gICAgICAgIH1cbiAgICAgIH0gZWxzZSB7XG4gICAgICAgIC8vIHJlbW92ZSBhdHRyXG4gICAgICAgIHRoaXMuc2V0T3JSZW1vdmVBdHRycyhlbCwgW10sIFthdHRyXSk7XG4gICAgICB9XG4gICAgfSBlbHNlIHtcbiAgICAgIHRoaXMuc2V0T3JSZW1vdmVBdHRycyhlbCwgW1thdHRyLCB2YWwxXV0sIFtdKTtcbiAgICB9XG4gIH0sXG5cbiAgYWRkT3JSZW1vdmVDbGFzc2VzKGVsLCBhZGRzLCByZW1vdmVzLCB0cmFuc2l0aW9uLCB0aW1lLCB2aWV3LCBibG9ja2luZykge1xuICAgIHRpbWUgPSB0aW1lIHx8IGRlZmF1bHRfdHJhbnNpdGlvbl90aW1lO1xuICAgIGNvbnN0IFt0cmFuc2l0aW9uUnVuLCB0cmFuc2l0aW9uU3RhcnQsIHRyYW5zaXRpb25FbmRdID0gdHJhbnNpdGlvbiB8fCBbXG4gICAgICBbXSxcbiAgICAgIFtdLFxuICAgICAgW10sXG4gICAgXTtcbiAgICBpZiAodHJhbnNpdGlvblJ1bi5sZW5ndGggPiAwKSB7XG4gICAgICBjb25zdCBvblN0YXJ0ID0gKCkgPT4ge1xuICAgICAgICB0aGlzLmFkZE9yUmVtb3ZlQ2xhc3NlcyhcbiAgICAgICAgICBlbCxcbiAgICAgICAgICB0cmFuc2l0aW9uU3RhcnQsXG4gICAgICAgICAgW10uY29uY2F0KHRyYW5zaXRpb25SdW4pLmNvbmNhdCh0cmFuc2l0aW9uRW5kKSxcbiAgICAgICAgKTtcbiAgICAgICAgd2luZG93LnJlcXVlc3RBbmltYXRpb25GcmFtZSgoKSA9PiB7XG4gICAgICAgICAgdGhpcy5hZGRPclJlbW92ZUNsYXNzZXMoZWwsIHRyYW5zaXRpb25SdW4sIFtdKTtcbiAgICAgICAgICB3aW5kb3cucmVxdWVzdEFuaW1hdGlvbkZyYW1lKCgpID0+XG4gICAgICAgICAgICB0aGlzLmFkZE9yUmVtb3ZlQ2xhc3NlcyhlbCwgdHJhbnNpdGlvbkVuZCwgdHJhbnNpdGlvblN0YXJ0KSxcbiAgICAgICAgICApO1xuICAgICAgICB9KTtcbiAgICAgIH07XG4gICAgICBjb25zdCBvbkRvbmUgPSAoKSA9PlxuICAgICAgICB0aGlzLmFkZE9yUmVtb3ZlQ2xhc3NlcyhcbiAgICAgICAgICBlbCxcbiAgICAgICAgICBhZGRzLmNvbmNhdCh0cmFuc2l0aW9uRW5kKSxcbiAgICAgICAgICByZW1vdmVzLmNvbmNhdCh0cmFuc2l0aW9uUnVuKS5jb25jYXQodHJhbnNpdGlvblN0YXJ0KSxcbiAgICAgICAgKTtcbiAgICAgIGlmIChibG9ja2luZyA9PT0gZmFsc2UpIHtcbiAgICAgICAgb25TdGFydCgpO1xuICAgICAgICBzZXRUaW1lb3V0KG9uRG9uZSwgdGltZSk7XG4gICAgICB9IGVsc2Uge1xuICAgICAgICB2aWV3LnRyYW5zaXRpb24odGltZSwgb25TdGFydCwgb25Eb25lKTtcbiAgICAgIH1cbiAgICAgIHJldHVybjtcbiAgICB9XG5cbiAgICB3aW5kb3cucmVxdWVzdEFuaW1hdGlvbkZyYW1lKCgpID0+IHtcbiAgICAgIGNvbnN0IFtwcmV2QWRkcywgcHJldlJlbW92ZXNdID0gRE9NLmdldFN0aWNreShlbCwgXCJjbGFzc2VzXCIsIFtbXSwgW11dKTtcbiAgICAgIGNvbnN0IGtlZXBBZGRzID0gYWRkcy5maWx0ZXIoXG4gICAgICAgIChuYW1lKSA9PiBwcmV2QWRkcy5pbmRleE9mKG5hbWUpIDwgMCAmJiAhZWwuY2xhc3NMaXN0LmNvbnRhaW5zKG5hbWUpLFxuICAgICAgKTtcbiAgICAgIGNvbnN0IGtlZXBSZW1vdmVzID0gcmVtb3Zlcy5maWx0ZXIoXG4gICAgICAgIChuYW1lKSA9PiBwcmV2UmVtb3Zlcy5pbmRleE9mKG5hbWUpIDwgMCAmJiBlbC5jbGFzc0xpc3QuY29udGFpbnMobmFtZSksXG4gICAgICApO1xuICAgICAgY29uc3QgbmV3QWRkcyA9IHByZXZBZGRzXG4gICAgICAgIC5maWx0ZXIoKG5hbWUpID0+IHJlbW92ZXMuaW5kZXhPZihuYW1lKSA8IDApXG4gICAgICAgIC5jb25jYXQoa2VlcEFkZHMpO1xuICAgICAgY29uc3QgbmV3UmVtb3ZlcyA9IHByZXZSZW1vdmVzXG4gICAgICAgIC5maWx0ZXIoKG5hbWUpID0+IGFkZHMuaW5kZXhPZihuYW1lKSA8IDApXG4gICAgICAgIC5jb25jYXQoa2VlcFJlbW92ZXMpO1xuXG4gICAgICBET00ucHV0U3RpY2t5KGVsLCBcImNsYXNzZXNcIiwgKGN1cnJlbnRFbCkgPT4ge1xuICAgICAgICBjdXJyZW50RWwuY2xhc3NMaXN0LnJlbW92ZSguLi5uZXdSZW1vdmVzKTtcbiAgICAgICAgY3VycmVudEVsLmNsYXNzTGlzdC5hZGQoLi4ubmV3QWRkcyk7XG4gICAgICAgIHJldHVybiBbbmV3QWRkcywgbmV3UmVtb3Zlc107XG4gICAgICB9KTtcbiAgICB9KTtcbiAgfSxcblxuICBzZXRPclJlbW92ZUF0dHJzKGVsLCBzZXRzLCByZW1vdmVzKSB7XG4gICAgY29uc3QgW3ByZXZTZXRzLCBwcmV2UmVtb3Zlc10gPSBET00uZ2V0U3RpY2t5KGVsLCBcImF0dHJzXCIsIFtbXSwgW11dKTtcblxuICAgIGNvbnN0IGFsdGVyZWRBdHRycyA9IHNldHMubWFwKChbYXR0ciwgX3ZhbF0pID0+IGF0dHIpLmNvbmNhdChyZW1vdmVzKTtcbiAgICBjb25zdCBuZXdTZXRzID0gcHJldlNldHNcbiAgICAgIC5maWx0ZXIoKFthdHRyLCBfdmFsXSkgPT4gIWFsdGVyZWRBdHRycy5pbmNsdWRlcyhhdHRyKSlcbiAgICAgIC5jb25jYXQoc2V0cyk7XG4gICAgY29uc3QgbmV3UmVtb3ZlcyA9IHByZXZSZW1vdmVzXG4gICAgICAuZmlsdGVyKChhdHRyKSA9PiAhYWx0ZXJlZEF0dHJzLmluY2x1ZGVzKGF0dHIpKVxuICAgICAgLmNvbmNhdChyZW1vdmVzKTtcblxuICAgIERPTS5wdXRTdGlja3koZWwsIFwiYXR0cnNcIiwgKGN1cnJlbnRFbCkgPT4ge1xuICAgICAgbmV3UmVtb3Zlcy5mb3JFYWNoKChhdHRyKSA9PiBjdXJyZW50RWwucmVtb3ZlQXR0cmlidXRlKGF0dHIpKTtcbiAgICAgIG5ld1NldHMuZm9yRWFjaCgoW2F0dHIsIHZhbF0pID0+IGN1cnJlbnRFbC5zZXRBdHRyaWJ1dGUoYXR0ciwgdmFsKSk7XG4gICAgICByZXR1cm4gW25ld1NldHMsIG5ld1JlbW92ZXNdO1xuICAgIH0pO1xuICB9LFxuXG4gIGhhc0FsbENsYXNzZXMoZWwsIGNsYXNzZXMpIHtcbiAgICByZXR1cm4gY2xhc3Nlcy5ldmVyeSgobmFtZSkgPT4gZWwuY2xhc3NMaXN0LmNvbnRhaW5zKG5hbWUpKTtcbiAgfSxcblxuICBpc1RvZ2dsZWRPdXQoZWwsIG91dENsYXNzZXMpIHtcbiAgICByZXR1cm4gIXRoaXMuaXNWaXNpYmxlKGVsKSB8fCB0aGlzLmhhc0FsbENsYXNzZXMoZWwsIG91dENsYXNzZXMpO1xuICB9LFxuXG4gIGZpbHRlclRvRWxzKGxpdmVTb2NrZXQsIHNvdXJjZUVsLCB7IHRvIH0pIHtcbiAgICBjb25zdCBkZWZhdWx0UXVlcnkgPSAoKSA9PiB7XG4gICAgICBpZiAodHlwZW9mIHRvID09PSBcInN0cmluZ1wiKSB7XG4gICAgICAgIHJldHVybiBkb2N1bWVudC5xdWVyeVNlbGVjdG9yQWxsKHRvKTtcbiAgICAgIH0gZWxzZSBpZiAodG8uY2xvc2VzdCkge1xuICAgICAgICBjb25zdCB0b0VsID0gc291cmNlRWwuY2xvc2VzdCh0by5jbG9zZXN0KTtcbiAgICAgICAgcmV0dXJuIHRvRWwgPyBbdG9FbF0gOiBbXTtcbiAgICAgIH0gZWxzZSBpZiAodG8uaW5uZXIpIHtcbiAgICAgICAgcmV0dXJuIHNvdXJjZUVsLnF1ZXJ5U2VsZWN0b3JBbGwodG8uaW5uZXIpO1xuICAgICAgfVxuICAgIH07XG4gICAgcmV0dXJuIHRvXG4gICAgICA/IGxpdmVTb2NrZXQuanNRdWVyeVNlbGVjdG9yQWxsKHNvdXJjZUVsLCB0bywgZGVmYXVsdFF1ZXJ5KVxuICAgICAgOiBbc291cmNlRWxdO1xuICB9LFxuXG4gIGRlZmF1bHREaXNwbGF5KGVsKSB7XG4gICAgcmV0dXJuIChcbiAgICAgIHsgdHI6IFwidGFibGUtcm93XCIsIHRkOiBcInRhYmxlLWNlbGxcIiB9W2VsLnRhZ05hbWUudG9Mb3dlckNhc2UoKV0gfHwgXCJibG9ja1wiXG4gICAgKTtcbiAgfSxcblxuICB0cmFuc2l0aW9uQ2xhc3Nlcyh2YWwpIHtcbiAgICBpZiAoIXZhbCkge1xuICAgICAgcmV0dXJuIG51bGw7XG4gICAgfVxuXG4gICAgbGV0IFt0cmFucywgdFN0YXJ0LCB0RW5kXSA9IEFycmF5LmlzQXJyYXkodmFsKVxuICAgICAgPyB2YWxcbiAgICAgIDogW3ZhbC5zcGxpdChcIiBcIiksIFtdLCBbXV07XG4gICAgdHJhbnMgPSBBcnJheS5pc0FycmF5KHRyYW5zKSA/IHRyYW5zIDogdHJhbnMuc3BsaXQoXCIgXCIpO1xuICAgIHRTdGFydCA9IEFycmF5LmlzQXJyYXkodFN0YXJ0KSA/IHRTdGFydCA6IHRTdGFydC5zcGxpdChcIiBcIik7XG4gICAgdEVuZCA9IEFycmF5LmlzQXJyYXkodEVuZCkgPyB0RW5kIDogdEVuZC5zcGxpdChcIiBcIik7XG4gICAgcmV0dXJuIFt0cmFucywgdFN0YXJ0LCB0RW5kXTtcbiAgfSxcbn07XG5cbmV4cG9ydCBkZWZhdWx0IEpTO1xuIiwgImltcG9ydCBKUyBmcm9tIFwiLi9qc1wiO1xuaW1wb3J0IExpdmVTb2NrZXQgZnJvbSBcIi4vbGl2ZV9zb2NrZXRcIjtcblxudHlwZSBUcmFuc2l0aW9uID0gc3RyaW5nIHwgc3RyaW5nW107XG5cbi8vIEJhc2Ugb3B0aW9ucyBmb3IgY29tbWFuZHMgaW52b2x2aW5nIHRyYW5zaXRpb25zIGFuZCB0aW1pbmdcbnR5cGUgQmFzZU9wdHMgPSB7XG4gIC8qKlxuICAgKiBUaGUgQ1NTIHRyYW5zaXRpb24gY2xhc3NlcyB0byBzZXQuXG4gICAqIEFjY2VwdHMgYSBzdHJpbmcgb2YgY2xhc3NlcyBvciBhIDMtdHVwbGUgbGlrZTpcbiAgICogYFtcImVhc2Utb3V0IGR1cmF0aW9uLTMwMFwiLCBcIm9wYWNpdHktMFwiLCBcIm9wYWNpdHktMTAwXCJdYFxuICAgKi9cbiAgdHJhbnNpdGlvbj86IFRyYW5zaXRpb247XG4gIC8qKiBUaGUgdHJhbnNpdGlvbiBkdXJhdGlvbiBpbiBtaWxsaXNlY29uZHMuIERlZmF1bHRzIDIwMC4gKi9cbiAgdGltZT86IG51bWJlcjtcbiAgLyoqIFdoZXRoZXIgdG8gYmxvY2sgVUkgZHVyaW5nIHRyYW5zaXRpb24uIERlZmF1bHRzIGB0cnVlYC4gKi9cbiAgYmxvY2tpbmc/OiBib29sZWFuO1xufTtcblxudHlwZSBTaG93T3B0cyA9IEJhc2VPcHRzICYge1xuICAvKiogVGhlIENTUyBkaXNwbGF5IHZhbHVlIHRvIHNldC4gRGVmYXVsdHMgXCJibG9ja1wiLiAqL1xuICBkaXNwbGF5Pzogc3RyaW5nO1xufTtcblxudHlwZSBUb2dnbGVPcHRzID0ge1xuICAvKiogVGhlIENTUyBkaXNwbGF5IHZhbHVlIHRvIHNldC4gRGVmYXVsdHMgXCJibG9ja1wiLiAqL1xuICBkaXNwbGF5Pzogc3RyaW5nO1xuICAvKipcbiAgICogVGhlIENTUyB0cmFuc2l0aW9uIGNsYXNzZXMgZm9yIHNob3dpbmcuXG4gICAqIEFjY2VwdHMgZWl0aGVyIHRoZSBzdHJpbmcgb2YgY2xhc3NlcyB0byBhcHBseSB3aGVuIHRvZ2dsaW5nIGluLCBvclxuICAgKiBhIDMtdHVwbGUgY29udGFpbmluZyB0aGUgdHJhbnNpdGlvbiBjbGFzcywgdGhlIGNsYXNzIHRvIGFwcGx5XG4gICAqIHRvIHN0YXJ0IHRoZSB0cmFuc2l0aW9uLCBhbmQgdGhlIGVuZGluZyB0cmFuc2l0aW9uIGNsYXNzLCBzdWNoIGFzOlxuICAgKiBgW1wiZWFzZS1vdXQgZHVyYXRpb24tMzAwXCIsIFwib3BhY2l0eS0wXCIsIFwib3BhY2l0eS0xMDBcIl1gXG4gICAqL1xuICBpbj86IFRyYW5zaXRpb247XG4gIC8qKlxuICAgKiBUaGUgQ1NTIHRyYW5zaXRpb24gY2xhc3NlcyBmb3IgaGlkaW5nLlxuICAgKiBBY2NlcHRzIGVpdGhlciBzdHJpbmcgb2YgY2xhc3NlcyB0byBhcHBseSB3aGVuIHRvZ2dsaW5nIG91dCwgb3JcbiAgICogYSAzLXR1cGxlIGNvbnRhaW5pbmcgdGhlIHRyYW5zaXRpb24gY2xhc3MsIHRoZSBjbGFzcyB0byBhcHBseVxuICAgKiB0byBzdGFydCB0aGUgdHJhbnNpdGlvbiwgYW5kIHRoZSBlbmRpbmcgdHJhbnNpdGlvbiBjbGFzcywgc3VjaCBhczpcbiAgICogYFtcImVhc2Utb3V0IGR1cmF0aW9uLTMwMFwiLCBcIm9wYWNpdHktMTAwXCIsIFwib3BhY2l0eS0wXCJdYFxuICAgKi9cbiAgb3V0PzogVHJhbnNpdGlvbjtcbiAgLyoqIFRoZSB0cmFuc2l0aW9uIGR1cmF0aW9uIGluIG1pbGxpc2Vjb25kcy4gKi9cbiAgdGltZT86IG51bWJlcjtcbiAgLyoqIFdoZXRoZXIgdG8gYmxvY2sgVUkgZHVyaW5nIHRyYW5zaXRpb24uIERlZmF1bHRzIGB0cnVlYC4gKi9cbiAgYmxvY2tpbmc/OiBib29sZWFuO1xufTtcblxuLy8gT3B0aW9ucyBzcGVjaWZpYyB0byB0aGUgJ3RyYW5zaXRpb24nIGNvbW1hbmRcbnR5cGUgVHJhbnNpdGlvbkNvbW1hbmRPcHRzID0ge1xuICAvKiogVGhlIHRyYW5zaXRpb24gZHVyYXRpb24gaW4gbWlsbGlzZWNvbmRzLiAqL1xuICB0aW1lPzogbnVtYmVyO1xuICAvKiogV2hldGhlciB0byBibG9jayBVSSBkdXJpbmcgdHJhbnNpdGlvbi4gRGVmYXVsdHMgYHRydWVgLiAqL1xuICBibG9ja2luZz86IGJvb2xlYW47XG59O1xuXG50eXBlIFB1c2hPcHRzID0ge1xuICAvKiogRGF0YSB0byBiZSBtZXJnZWQgaW50byB0aGUgZXZlbnQgcGF5bG9hZC4gKi9cbiAgdmFsdWU/OiBhbnk7XG4gIC8qKiBGb3IgdGFyZ2V0aW5nIGEgTGl2ZUNvbXBvbmVudCBieSBpdHMgSUQsIGEgY29tcG9uZW50IElEIChudW1iZXIpLCBvciBhIENTUyBzZWxlY3RvciBzdHJpbmcuICovXG4gIHRhcmdldD86IEhUTUxFbGVtZW50IHwgbnVtYmVyIHwgc3RyaW5nO1xuICAvKiogSW5kaWNhdGVzIGlmIGEgcGFnZSBsb2FkaW5nIHN0YXRlIHNob3VsZCBiZSBzaG93bi4gKi9cbiAgcGFnZV9sb2FkaW5nPzogYm9vbGVhbjtcbiAgW2tleTogc3RyaW5nXTogYW55OyAvLyBBbGxvdyBvdGhlciBwcm9wZXJ0aWVzIGxpa2UgJ2NpZCcsICdyZWRpcmVjdCcsIGV0Yy5cbn07XG5cbnR5cGUgTmF2aWdhdGlvbk9wdHMgPSB7XG4gIC8qKiBXaGV0aGVyIHRvIHJlcGxhY2UgdGhlIGN1cnJlbnQgaGlzdG9yeSBlbnRyeSBpbnN0ZWFkIG9mIHB1c2hpbmcgYSBuZXcgb25lLiAqL1xuICByZXBsYWNlPzogYm9vbGVhbjtcbn07XG5cbi8qKlxuICogUmVwcmVzZW50cyBhbGwgcG9zc2libGUgSlMgY29tbWFuZHMgdGhhdCBjYW4gYmUgZ2VuZXJhdGVkIGJ5IHRoZSBmYWN0b3J5LlxuICogVGhpcyBpcyB1c2VkIGFzIGEgYmFzZSBmb3IgTGl2ZVNvY2tldEpTQ29tbWFuZHMgYW5kIEhvb2tKU0NvbW1hbmRzLlxuICovXG5pbnRlcmZhY2UgQWxsSlNDb21tYW5kcyB7XG4gIC8qKlxuICAgKiBFeGVjdXRlcyBlbmNvZGVkIEphdmFTY3JpcHQgaW4gdGhlIGNvbnRleHQgb2YgdGhlIGVsZW1lbnQuXG4gICAqIFRoaXMgdmVyc2lvbiBpcyBmb3IgZ2VuZXJhbCB1c2UgdmlhIGxpdmVTb2NrZXQuanMoKS5cbiAgICpcbiAgICogQHBhcmFtIGVsIC0gVGhlIGVsZW1lbnQgaW4gd2hvc2UgY29udGV4dCB0byBleGVjdXRlIHRoZSBKYXZhU2NyaXB0LlxuICAgKiBAcGFyYW0gZW5jb2RlZEpTIC0gVGhlIGVuY29kZWQgSmF2YVNjcmlwdCBzdHJpbmcgdG8gZXhlY3V0ZS5cbiAgICovXG4gIGV4ZWMoZWw6IEhUTUxFbGVtZW50LCBlbmNvZGVkSlM6IHN0cmluZyk6IHZvaWQ7XG5cbiAgLyoqXG4gICAqIFNob3dzIGFuIGVsZW1lbnQuXG4gICAqXG4gICAqIEBwYXJhbSBlbCAtIFRoZSBlbGVtZW50IHRvIHNob3cuXG4gICAqIEBwYXJhbSB7U2hvd09wdHN9IFtvcHRzPXt9XSAtIE9wdGlvbmFsIHNldHRpbmdzLlxuICAgKiAgIEFjY2VwdHM6IGBkaXNwbGF5YCwgYHRyYW5zaXRpb25gLCBgdGltZWAsIGFuZCBgYmxvY2tpbmdgLlxuICAgKi9cbiAgc2hvdyhlbDogSFRNTEVsZW1lbnQsIG9wdHM/OiBTaG93T3B0cyk6IHZvaWQ7XG5cbiAgLyoqXG4gICAqIEhpZGVzIGFuIGVsZW1lbnQuXG4gICAqXG4gICAqIEBwYXJhbSBlbCAtIFRoZSBlbGVtZW50IHRvIGhpZGUuXG4gICAqIEBwYXJhbSBbb3B0cz17fV0gLSBPcHRpb25hbCBzZXR0aW5ncy5cbiAgICogICBBY2NlcHRzOiBgdHJhbnNpdGlvbmAsIGB0aW1lYCwgYW5kIGBibG9ja2luZ2AuXG4gICAqL1xuICBoaWRlKGVsOiBIVE1MRWxlbWVudCwgb3B0cz86IEJhc2VPcHRzKTogdm9pZDtcblxuICAvKipcbiAgICogVG9nZ2xlcyB0aGUgdmlzaWJpbGl0eSBvZiBhbiBlbGVtZW50LlxuICAgKlxuICAgKiBAcGFyYW0gZWwgLSBUaGUgZWxlbWVudCB0byB0b2dnbGUuXG4gICAqIEBwYXJhbSBbb3B0cz17fV0gLSBPcHRpb25hbCBzZXR0aW5ncy5cbiAgICogICBBY2NlcHRzOiBgZGlzcGxheWAsIGBpbmAsIGBvdXRgLCBgdGltZWAsIGFuZCBgYmxvY2tpbmdgLlxuICAgKi9cbiAgdG9nZ2xlKGVsOiBIVE1MRWxlbWVudCwgb3B0cz86IFRvZ2dsZU9wdHMpOiB2b2lkO1xuXG4gIC8qKlxuICAgKiBBZGRzIENTUyBjbGFzc2VzIHRvIGFuIGVsZW1lbnQuXG4gICAqXG4gICAqIEBwYXJhbSBlbCAtIFRoZSBlbGVtZW50IHRvIGFkZCBjbGFzc2VzIHRvLlxuICAgKiBAcGFyYW0gbmFtZXMgLSBUaGUgY2xhc3MgbmFtZShzKSB0byBhZGQuXG4gICAqIEBwYXJhbSBbb3B0cz17fV0gLSBPcHRpb25hbCBzZXR0aW5ncy5cbiAgICogICBBY2NlcHRzOiBgdHJhbnNpdGlvbmAsIGB0aW1lYCwgYW5kIGBibG9ja2luZ2AuXG4gICAqL1xuICBhZGRDbGFzcyhlbDogSFRNTEVsZW1lbnQsIG5hbWVzOiBzdHJpbmcgfCBzdHJpbmdbXSwgb3B0cz86IEJhc2VPcHRzKTogdm9pZDtcblxuICAvKipcbiAgICogUmVtb3ZlcyBDU1MgY2xhc3NlcyBmcm9tIGFuIGVsZW1lbnQuXG4gICAqXG4gICAqIEBwYXJhbSBlbCAtIFRoZSBlbGVtZW50IHRvIHJlbW92ZSBjbGFzc2VzIGZyb20uXG4gICAqIEBwYXJhbSBuYW1lcyAtIFRoZSBjbGFzcyBuYW1lKHMpIHRvIHJlbW92ZS5cbiAgICogQHBhcmFtIFtvcHRzPXt9XSAtIE9wdGlvbmFsIHNldHRpbmdzLlxuICAgKiAgIEFjY2VwdHM6IGB0cmFuc2l0aW9uYCwgYHRpbWVgLCBhbmQgYGJsb2NraW5nYC5cbiAgICovXG4gIHJlbW92ZUNsYXNzKGVsOiBIVE1MRWxlbWVudCwgbmFtZXM6IHN0cmluZyB8IHN0cmluZ1tdLCBvcHRzPzogQmFzZU9wdHMpOiB2b2lkO1xuXG4gIC8qKlxuICAgKiBUb2dnbGVzIENTUyBjbGFzc2VzIG9uIGFuIGVsZW1lbnQuXG4gICAqXG4gICAqIEBwYXJhbSBlbCAtIFRoZSBlbGVtZW50IHRvIHRvZ2dsZSBjbGFzc2VzIG9uLlxuICAgKiBAcGFyYW0gbmFtZXMgLSBUaGUgY2xhc3MgbmFtZShzKSB0byB0b2dnbGUuXG4gICAqIEBwYXJhbSBbb3B0cz17fV0gLSBPcHRpb25hbCBzZXR0aW5ncy5cbiAgICogICBBY2NlcHRzOiBgdHJhbnNpdGlvbmAsIGB0aW1lYCwgYW5kIGBibG9ja2luZ2AuXG4gICAqL1xuICB0b2dnbGVDbGFzcyhlbDogSFRNTEVsZW1lbnQsIG5hbWVzOiBzdHJpbmcgfCBzdHJpbmdbXSwgb3B0cz86IEJhc2VPcHRzKTogdm9pZDtcblxuICAvKipcbiAgICogQXBwbGllcyBhIENTUyB0cmFuc2l0aW9uIHRvIGFuIGVsZW1lbnQuXG4gICAqXG4gICAqIEBwYXJhbSBlbCAtIFRoZSBlbGVtZW50IHRvIGFwcGx5IHRoZSB0cmFuc2l0aW9uIHRvLlxuICAgKiBAcGFyYW0gdHJhbnNpdGlvbiAtIFRoZSB0cmFuc2l0aW9uIGNsYXNzKGVzKSB0byBhcHBseS5cbiAgICogICBBY2NlcHRzIGEgc3RyaW5nIG9mIGNsYXNzZXMgdG8gYXBwbHkgd2hlbiB0cmFuc2l0aW9uaW5nIG9yXG4gICAqICAgYSAzLXR1cGxlIGNvbnRhaW5pbmcgdGhlIHRyYW5zaXRpb24gY2xhc3MsIHRoZSBjbGFzcyB0byBhcHBseVxuICAgKiAgIHRvIHN0YXJ0IHRoZSB0cmFuc2l0aW9uLCBhbmQgdGhlIGVuZGluZyB0cmFuc2l0aW9uIGNsYXNzLCBzdWNoIGFzOlxuICAgKlxuICAgKiAgICAgICBbXCJlYXNlLW91dCBkdXJhdGlvbi0zMDBcIiwgXCJvcGFjaXR5LTEwMFwiLCBcIm9wYWNpdHktMFwiXVxuICAgKlxuICAgKiBAcGFyYW0gW29wdHM9e31dIC0gT3B0aW9uYWwgc2V0dGluZ3MgZm9yIHRpbWluZyBhbmQgYmxvY2tpbmcgYmVoYXZpb3IuXG4gICAqICAgQWNjZXB0czogYHRpbWVgIGFuZCBgYmxvY2tpbmdgLlxuICAgKi9cbiAgdHJhbnNpdGlvbihcbiAgICBlbDogSFRNTEVsZW1lbnQsXG4gICAgdHJhbnNpdGlvbjogc3RyaW5nIHwgc3RyaW5nW10sXG4gICAgb3B0cz86IFRyYW5zaXRpb25Db21tYW5kT3B0cyxcbiAgKTogdm9pZDtcblxuICAvKipcbiAgICogU2V0cyBhbiBhdHRyaWJ1dGUgb24gYW4gZWxlbWVudC5cbiAgICpcbiAgICogQHBhcmFtIGVsIC0gVGhlIGVsZW1lbnQgdG8gc2V0IHRoZSBhdHRyaWJ1dGUgb24uXG4gICAqIEBwYXJhbSBhdHRyIC0gVGhlIGF0dHJpYnV0ZSBuYW1lIHRvIHNldC5cbiAgICogQHBhcmFtIHZhbCAtIFRoZSB2YWx1ZSB0byBzZXQgZm9yIHRoZSBhdHRyaWJ1dGUuXG4gICAqL1xuICBzZXRBdHRyaWJ1dGUoZWw6IEhUTUxFbGVtZW50LCBhdHRyOiBzdHJpbmcsIHZhbDogc3RyaW5nKTogdm9pZDtcblxuICAvKipcbiAgICogUmVtb3ZlcyBhbiBhdHRyaWJ1dGUgZnJvbSBhbiBlbGVtZW50LlxuICAgKlxuICAgKiBAcGFyYW0gZWwgLSBUaGUgZWxlbWVudCB0byByZW1vdmUgdGhlIGF0dHJpYnV0ZSBmcm9tLlxuICAgKiBAcGFyYW0gYXR0ciAtIFRoZSBhdHRyaWJ1dGUgbmFtZSB0byByZW1vdmUuXG4gICAqL1xuICByZW1vdmVBdHRyaWJ1dGUoZWw6IEhUTUxFbGVtZW50LCBhdHRyOiBzdHJpbmcpOiB2b2lkO1xuXG4gIC8qKlxuICAgKiBUb2dnbGVzIGFuIGF0dHJpYnV0ZSBvbiBhbiBlbGVtZW50IGJldHdlZW4gdHdvIHZhbHVlcy5cbiAgICpcbiAgICogQHBhcmFtIGVsIC0gVGhlIGVsZW1lbnQgdG8gdG9nZ2xlIHRoZSBhdHRyaWJ1dGUgb24uXG4gICAqIEBwYXJhbSBhdHRyIC0gVGhlIGF0dHJpYnV0ZSBuYW1lIHRvIHRvZ2dsZS5cbiAgICogQHBhcmFtIHZhbDEgLSBUaGUgZmlyc3QgdmFsdWUgdG8gdG9nZ2xlIGJldHdlZW4uXG4gICAqIEBwYXJhbSB2YWwyIC0gVGhlIHNlY29uZCB2YWx1ZSB0byB0b2dnbGUgYmV0d2Vlbi5cbiAgICovXG4gIHRvZ2dsZUF0dHJpYnV0ZShcbiAgICBlbDogSFRNTEVsZW1lbnQsXG4gICAgYXR0cjogc3RyaW5nLFxuICAgIHZhbDE6IHN0cmluZyxcbiAgICB2YWwyOiBzdHJpbmcsXG4gICk6IHZvaWQ7XG5cbiAgLyoqXG4gICAqIFB1c2hlcyBhbiBldmVudCB0byB0aGUgc2VydmVyLlxuICAgKlxuICAgKiBAcGFyYW0gZWwgLSBBbiBlbGVtZW50IHRoYXQgYmVsb25ncyB0byB0aGUgdGFyZ2V0IExpdmVWaWV3IC8gTGl2ZUNvbXBvbmVudCBvciBhIGNvbXBvbmVudCBJRC5cbiAgICogICBUbyB0YXJnZXQgYSBMaXZlQ29tcG9uZW50IGJ5IGl0cyBJRCwgcGFzcyBhIHNlcGFyYXRlIGB0YXJnZXRgIGluIHRoZSBvcHRpb25zLlxuICAgKiBAcGFyYW0gdHlwZSAtIFRoZSBldmVudCBuYW1lIHRvIHB1c2guXG4gICAqIEBwYXJhbSBbb3B0cz17fV0gLSBPcHRpb25hbCBzZXR0aW5ncy5cbiAgICogICBBY2NlcHRzOiBgdmFsdWVgLCBgdGFyZ2V0YCwgYHBhZ2VfbG9hZGluZ2AuXG4gICAqL1xuICBwdXNoKGVsOiBIVE1MRWxlbWVudCwgdHlwZTogc3RyaW5nLCBvcHRzPzogUHVzaE9wdHMpOiB2b2lkO1xuXG4gIC8qKlxuICAgKiBTZW5kcyBhIG5hdmlnYXRpb24gZXZlbnQgdG8gdGhlIHNlcnZlciBhbmQgdXBkYXRlcyB0aGUgYnJvd3NlcidzIHB1c2hTdGF0ZSBoaXN0b3J5LlxuICAgKlxuICAgKiBAcGFyYW0gaHJlZiAtIFRoZSBVUkwgdG8gbmF2aWdhdGUgdG8uXG4gICAqIEBwYXJhbSBbb3B0cz17fV0gLSBPcHRpb25hbCBzZXR0aW5ncy5cbiAgICogICBBY2NlcHRzOiBgcmVwbGFjZWAuXG4gICAqL1xuICBuYXZpZ2F0ZShocmVmOiBzdHJpbmcsIG9wdHM/OiBOYXZpZ2F0aW9uT3B0cyk6IHZvaWQ7XG5cbiAgLyoqXG4gICAqIFNlbmRzIGEgcGF0Y2ggZXZlbnQgdG8gdGhlIHNlcnZlciBhbmQgdXBkYXRlcyB0aGUgYnJvd3NlcidzIHB1c2hTdGF0ZSBoaXN0b3J5LlxuICAgKlxuICAgKiBAcGFyYW0gaHJlZiAtIFRoZSBVUkwgdG8gcGF0Y2ggdG8uXG4gICAqIEBwYXJhbSBbb3B0cz17fV0gLSBPcHRpb25hbCBzZXR0aW5ncy5cbiAgICogICBBY2NlcHRzOiBgcmVwbGFjZWAuXG4gICAqL1xuICBwYXRjaChocmVmOiBzdHJpbmcsIG9wdHM/OiBOYXZpZ2F0aW9uT3B0cyk6IHZvaWQ7XG5cbiAgLyoqXG4gICAqIE1hcmsgYXR0cmlidXRlcyBhcyBpZ25vcmVkLCBza2lwcGluZyB0aGVtIHdoZW4gcGF0Y2hpbmcgdGhlIERPTS5cbiAgICpcbiAgICogQHBhcmFtIGVsIC0gVGhlIGVsZW1lbnQgdG8gaWdub3JlIGF0dHJpYnV0ZXMgb24uXG4gICAqIEBwYXJhbSBhdHRycyAtIFRoZSBhdHRyaWJ1dGUgbmFtZSBvciBuYW1lcyB0byBpZ25vcmUuXG4gICAqL1xuICBpZ25vcmVBdHRyaWJ1dGVzKGVsOiBIVE1MRWxlbWVudCwgYXR0cnM6IHN0cmluZyB8IHN0cmluZ1tdKTogdm9pZDtcbn1cblxuZXhwb3J0IGRlZmF1bHQgKFxuICBsaXZlU29ja2V0OiBMaXZlU29ja2V0LFxuICBldmVudFR5cGU6IHN0cmluZyB8IG51bGwsXG4pOiBBbGxKU0NvbW1hbmRzID0+IHtcbiAgcmV0dXJuIHtcbiAgICBleGVjKGVsLCBlbmNvZGVkSlMpIHtcbiAgICAgIGxpdmVTb2NrZXQuZXhlY0pTKGVsLCBlbmNvZGVkSlMsIGV2ZW50VHlwZSk7XG4gICAgfSxcbiAgICBzaG93KGVsLCBvcHRzID0ge30pIHtcbiAgICAgIGNvbnN0IG93bmVyID0gbGl2ZVNvY2tldC5vd25lcihlbCk7XG4gICAgICBKUy5zaG93KFxuICAgICAgICBldmVudFR5cGUsXG4gICAgICAgIG93bmVyLFxuICAgICAgICBlbCxcbiAgICAgICAgb3B0cy5kaXNwbGF5LFxuICAgICAgICBKUy50cmFuc2l0aW9uQ2xhc3NlcyhvcHRzLnRyYW5zaXRpb24pLFxuICAgICAgICBvcHRzLnRpbWUsXG4gICAgICAgIG9wdHMuYmxvY2tpbmcsXG4gICAgICApO1xuICAgIH0sXG4gICAgaGlkZShlbCwgb3B0cyA9IHt9KSB7XG4gICAgICBjb25zdCBvd25lciA9IGxpdmVTb2NrZXQub3duZXIoZWwpO1xuICAgICAgSlMuaGlkZShcbiAgICAgICAgZXZlbnRUeXBlLFxuICAgICAgICBvd25lcixcbiAgICAgICAgZWwsXG4gICAgICAgIG51bGwsXG4gICAgICAgIEpTLnRyYW5zaXRpb25DbGFzc2VzKG9wdHMudHJhbnNpdGlvbiksXG4gICAgICAgIG9wdHMudGltZSxcbiAgICAgICAgb3B0cy5ibG9ja2luZyxcbiAgICAgICk7XG4gICAgfSxcbiAgICB0b2dnbGUoZWwsIG9wdHMgPSB7fSkge1xuICAgICAgY29uc3Qgb3duZXIgPSBsaXZlU29ja2V0Lm93bmVyKGVsKTtcbiAgICAgIGNvbnN0IGluVHJhbnNpdGlvbiA9IEpTLnRyYW5zaXRpb25DbGFzc2VzKG9wdHMuaW4pO1xuICAgICAgY29uc3Qgb3V0VHJhbnNpdGlvbiA9IEpTLnRyYW5zaXRpb25DbGFzc2VzKG9wdHMub3V0KTtcbiAgICAgIEpTLnRvZ2dsZShcbiAgICAgICAgZXZlbnRUeXBlLFxuICAgICAgICBvd25lcixcbiAgICAgICAgZWwsXG4gICAgICAgIG9wdHMuZGlzcGxheSxcbiAgICAgICAgaW5UcmFuc2l0aW9uLFxuICAgICAgICBvdXRUcmFuc2l0aW9uLFxuICAgICAgICBvcHRzLnRpbWUsXG4gICAgICAgIG9wdHMuYmxvY2tpbmcsXG4gICAgICApO1xuICAgIH0sXG4gICAgYWRkQ2xhc3MoZWwsIG5hbWVzLCBvcHRzID0ge30pIHtcbiAgICAgIGNvbnN0IGNsYXNzTmFtZXMgPSBBcnJheS5pc0FycmF5KG5hbWVzKSA/IG5hbWVzIDogbmFtZXMuc3BsaXQoXCIgXCIpO1xuICAgICAgY29uc3Qgb3duZXIgPSBsaXZlU29ja2V0Lm93bmVyKGVsKTtcbiAgICAgIEpTLmFkZE9yUmVtb3ZlQ2xhc3NlcyhcbiAgICAgICAgZWwsXG4gICAgICAgIGNsYXNzTmFtZXMsXG4gICAgICAgIFtdLFxuICAgICAgICBKUy50cmFuc2l0aW9uQ2xhc3NlcyhvcHRzLnRyYW5zaXRpb24pLFxuICAgICAgICBvcHRzLnRpbWUsXG4gICAgICAgIG93bmVyLFxuICAgICAgICBvcHRzLmJsb2NraW5nLFxuICAgICAgKTtcbiAgICB9LFxuICAgIHJlbW92ZUNsYXNzKGVsLCBuYW1lcywgb3B0cyA9IHt9KSB7XG4gICAgICBjb25zdCBjbGFzc05hbWVzID0gQXJyYXkuaXNBcnJheShuYW1lcykgPyBuYW1lcyA6IG5hbWVzLnNwbGl0KFwiIFwiKTtcbiAgICAgIGNvbnN0IG93bmVyID0gbGl2ZVNvY2tldC5vd25lcihlbCk7XG4gICAgICBKUy5hZGRPclJlbW92ZUNsYXNzZXMoXG4gICAgICAgIGVsLFxuICAgICAgICBbXSxcbiAgICAgICAgY2xhc3NOYW1lcyxcbiAgICAgICAgSlMudHJhbnNpdGlvbkNsYXNzZXMob3B0cy50cmFuc2l0aW9uKSxcbiAgICAgICAgb3B0cy50aW1lLFxuICAgICAgICBvd25lcixcbiAgICAgICAgb3B0cy5ibG9ja2luZyxcbiAgICAgICk7XG4gICAgfSxcbiAgICB0b2dnbGVDbGFzcyhlbCwgbmFtZXMsIG9wdHMgPSB7fSkge1xuICAgICAgY29uc3QgY2xhc3NOYW1lcyA9IEFycmF5LmlzQXJyYXkobmFtZXMpID8gbmFtZXMgOiBuYW1lcy5zcGxpdChcIiBcIik7XG4gICAgICBjb25zdCBvd25lciA9IGxpdmVTb2NrZXQub3duZXIoZWwpO1xuICAgICAgSlMudG9nZ2xlQ2xhc3NlcyhcbiAgICAgICAgZWwsXG4gICAgICAgIGNsYXNzTmFtZXMsXG4gICAgICAgIEpTLnRyYW5zaXRpb25DbGFzc2VzKG9wdHMudHJhbnNpdGlvbiksXG4gICAgICAgIG9wdHMudGltZSxcbiAgICAgICAgb3duZXIsXG4gICAgICAgIG9wdHMuYmxvY2tpbmcsXG4gICAgICApO1xuICAgIH0sXG4gICAgdHJhbnNpdGlvbihlbCwgdHJhbnNpdGlvbiwgb3B0cyA9IHt9KSB7XG4gICAgICBjb25zdCBvd25lciA9IGxpdmVTb2NrZXQub3duZXIoZWwpO1xuICAgICAgSlMuYWRkT3JSZW1vdmVDbGFzc2VzKFxuICAgICAgICBlbCxcbiAgICAgICAgW10sXG4gICAgICAgIFtdLFxuICAgICAgICBKUy50cmFuc2l0aW9uQ2xhc3Nlcyh0cmFuc2l0aW9uKSxcbiAgICAgICAgb3B0cy50aW1lLFxuICAgICAgICBvd25lcixcbiAgICAgICAgb3B0cy5ibG9ja2luZyxcbiAgICAgICk7XG4gICAgfSxcbiAgICBzZXRBdHRyaWJ1dGUoZWwsIGF0dHIsIHZhbCkge1xuICAgICAgSlMuc2V0T3JSZW1vdmVBdHRycyhlbCwgW1thdHRyLCB2YWxdXSwgW10pO1xuICAgIH0sXG4gICAgcmVtb3ZlQXR0cmlidXRlKGVsLCBhdHRyKSB7XG4gICAgICBKUy5zZXRPclJlbW92ZUF0dHJzKGVsLCBbXSwgW2F0dHJdKTtcbiAgICB9LFxuICAgIHRvZ2dsZUF0dHJpYnV0ZShlbCwgYXR0ciwgdmFsMSwgdmFsMikge1xuICAgICAgSlMudG9nZ2xlQXR0cihlbCwgYXR0ciwgdmFsMSwgdmFsMik7XG4gICAgfSxcbiAgICBwdXNoKGVsLCB0eXBlLCBvcHRzID0ge30pIHtcbiAgICAgIGxpdmVTb2NrZXQud2l0aGluT3duZXJzKGVsLCAodmlldykgPT4ge1xuICAgICAgICBjb25zdCBkYXRhID0gb3B0cy52YWx1ZSB8fCB7fTtcbiAgICAgICAgZGVsZXRlIG9wdHMudmFsdWU7XG4gICAgICAgIGxldCBlID0gbmV3IEN1c3RvbUV2ZW50KFwicGh4OmV4ZWNcIiwgeyBkZXRhaWw6IHsgc291cmNlRWxlbWVudDogZWwgfSB9KTtcbiAgICAgICAgSlMuZXhlYyhlLCBldmVudFR5cGUsIHR5cGUsIHZpZXcsIGVsLCBbXCJwdXNoXCIsIHsgZGF0YSwgLi4ub3B0cyB9XSk7XG4gICAgICB9KTtcbiAgICB9LFxuICAgIG5hdmlnYXRlKGhyZWYsIG9wdHMgPSB7fSkge1xuICAgICAgY29uc3QgY3VzdG9tRXZlbnQgPSBuZXcgQ3VzdG9tRXZlbnQoXCJwaHg6ZXhlY1wiKTtcbiAgICAgIGxpdmVTb2NrZXQuaGlzdG9yeVJlZGlyZWN0KFxuICAgICAgICBjdXN0b21FdmVudCxcbiAgICAgICAgaHJlZixcbiAgICAgICAgb3B0cy5yZXBsYWNlID8gXCJyZXBsYWNlXCIgOiBcInB1c2hcIixcbiAgICAgICAgbnVsbCxcbiAgICAgICAgbnVsbCxcbiAgICAgICk7XG4gICAgfSxcbiAgICBwYXRjaChocmVmLCBvcHRzID0ge30pIHtcbiAgICAgIGNvbnN0IGN1c3RvbUV2ZW50ID0gbmV3IEN1c3RvbUV2ZW50KFwicGh4OmV4ZWNcIik7XG4gICAgICBsaXZlU29ja2V0LnB1c2hIaXN0b3J5UGF0Y2goXG4gICAgICAgIGN1c3RvbUV2ZW50LFxuICAgICAgICBocmVmLFxuICAgICAgICBvcHRzLnJlcGxhY2UgPyBcInJlcGxhY2VcIiA6IFwicHVzaFwiLFxuICAgICAgICBudWxsLFxuICAgICAgKTtcbiAgICB9LFxuICAgIGlnbm9yZUF0dHJpYnV0ZXMoZWwsIGF0dHJzKSB7XG4gICAgICBKUy5pZ25vcmVBdHRycyhlbCwgQXJyYXkuaXNBcnJheShhdHRycykgPyBhdHRycyA6IFthdHRyc10pO1xuICAgIH0sXG4gIH07XG59O1xuXG4vKipcbiAqIEpTQ29tbWFuZHMgZm9yIHVzZSB3aXRoIGBsaXZlU29ja2V0LmpzKClgLlxuICogSW5jbHVkZXMgdGhlIGdlbmVyYWwgYGV4ZWNgIGNvbW1hbmQgdGhhdCByZXF1aXJlcyBhbiBlbGVtZW50LlxuICovXG5leHBvcnQgdHlwZSBMaXZlU29ja2V0SlNDb21tYW5kcyA9IEFsbEpTQ29tbWFuZHM7XG5cbi8qKlxuICogSlNDb21tYW5kcyBmb3IgdXNlIHdpdGhpbiBhIEhvb2suXG4gKiBUaGUgYGV4ZWNgIGNvbW1hbmQgaXMgdGFpbG9yZWQgZm9yIGhvb2tzLCBub3QgcmVxdWlyaW5nIGFuIGV4cGxpY2l0IGVsZW1lbnQuXG4gKi9cbmV4cG9ydCBpbnRlcmZhY2UgSG9va0pTQ29tbWFuZHMgZXh0ZW5kcyBPbWl0PEFsbEpTQ29tbWFuZHMsIFwiZXhlY1wiPiB7XG4gIC8qKlxuICAgKiBFeGVjdXRlcyBlbmNvZGVkIEphdmFTY3JpcHQgaW4gdGhlIGNvbnRleHQgb2YgdGhlIGhvb2sncyBlbGVtZW50LlxuICAgKlxuICAgKiBAcGFyYW0ge3N0cmluZ30gZW5jb2RlZEpTIC0gVGhlIGVuY29kZWQgSmF2YVNjcmlwdCBzdHJpbmcgdG8gZXhlY3V0ZS5cbiAgICovXG4gIGV4ZWMoZW5jb2RlZEpTOiBzdHJpbmcpOiB2b2lkO1xufVxuIiwgImltcG9ydCBqc0NvbW1hbmRzLCB7IEhvb2tKU0NvbW1hbmRzIH0gZnJvbSBcIi4vanNfY29tbWFuZHNcIjtcbmltcG9ydCBET00gZnJvbSBcIi4vZG9tXCI7XG5pbXBvcnQgTGl2ZVNvY2tldCBmcm9tIFwiLi9saXZlX3NvY2tldFwiO1xuaW1wb3J0IFZpZXcgZnJvbSBcIi4vdmlld1wiO1xuXG5jb25zdCBIT09LX0lEID0gXCJob29rSWRcIjtcbmxldCB2aWV3SG9va0lEID0gMTtcblxuZXhwb3J0IHR5cGUgT25SZXBseSA9IChyZXBseTogYW55LCByZWY6IG51bWJlcikgPT4gYW55O1xuZXhwb3J0IHR5cGUgQ2FsbGJhY2tSZWYgPSB7IGV2ZW50OiBzdHJpbmc7IGNhbGxiYWNrOiAocGF5bG9hZDogYW55KSA9PiBhbnkgfTtcblxuZXhwb3J0IHR5cGUgUGh4VGFyZ2V0ID0gc3RyaW5nIHwgbnVtYmVyIHwgSFRNTEVsZW1lbnQ7XG5cbmV4cG9ydCBpbnRlcmZhY2UgSG9va0ludGVyZmFjZSB7XG4gIC8qKlxuICAgKiBUaGUgRE9NIGVsZW1lbnQgdGhhdCB0aGUgaG9vayBpcyBhdHRhY2hlZCB0by5cbiAgICovXG4gIGVsOiBIVE1MRWxlbWVudDtcblxuICAvKipcbiAgICogVGhlIExpdmVTb2NrZXQgaW5zdGFuY2UgdGhhdCB0aGUgaG9vayBpcyBhdHRhY2hlZCB0by5cbiAgICovXG4gIGxpdmVTb2NrZXQ6IExpdmVTb2NrZXQ7XG5cbiAgLyoqXG4gICAqIFRoZSBtb3VudGVkIGNhbGxiYWNrLlxuICAgKlxuICAgKiBDYWxsZWQgd2hlbiB0aGUgZWxlbWVudCBoYXMgYmVlbiBhZGRlZCB0byB0aGUgRE9NIGFuZCBpdHMgc2VydmVyIExpdmVWaWV3IGhhcyBmaW5pc2hlZCBtb3VudGluZy5cbiAgICovXG4gIG1vdW50ZWQ/OiAoKSA9PiB2b2lkO1xuXG4gIC8qKlxuICAgKiBUaGUgYmVmb3JlVXBkYXRlIGNhbGxiYWNrLlxuICAgKlxuICAgKiBDYWxsZWQgd2hlbiB0aGUgZWxlbWVudCBpcyBhYm91dCB0byBiZSB1cGRhdGVkIGluIHRoZSBET00uXG4gICAqIE5vdGU6IGFueSBjYWxsIGhlcmUgbXVzdCBiZSBzeW5jaHJvbm91cyBhcyB0aGUgb3BlcmF0aW9uIGNhbm5vdCBiZSBkZWZlcnJlZCBvciBjYW5jZWxsZWQuXG4gICAqL1xuICBiZWZvcmVVcGRhdGU/OiAoKSA9PiB2b2lkO1xuXG4gIC8qKlxuICAgKiBUaGUgdXBkYXRlZCBjYWxsYmFjay5cbiAgICpcbiAgICogQ2FsbGVkIHdoZW4gdGhlIGVsZW1lbnQgaGFzIGJlZW4gdXBkYXRlZCBpbiB0aGUgRE9NIGJ5IHRoZSBzZXJ2ZXJcbiAgICovXG4gIHVwZGF0ZWQ/OiAoKSA9PiB2b2lkO1xuXG4gIC8qKlxuICAgKiBUaGUgZGVzdHJveWVkIGNhbGxiYWNrLlxuICAgKlxuICAgKiBDYWxsZWQgd2hlbiB0aGUgZWxlbWVudCBoYXMgYmVlbiByZW1vdmVkIGZyb20gdGhlIHBhZ2UsIGVpdGhlciBieSBhIHBhcmVudCB1cGRhdGUsIG9yIGJ5IHRoZSBwYXJlbnQgYmVpbmcgcmVtb3ZlZCBlbnRpcmVseVxuICAgKi9cbiAgZGVzdHJveWVkPzogKCkgPT4gdm9pZDtcblxuICAvKipcbiAgICogVGhlIGRpc2Nvbm5lY3RlZCBjYWxsYmFjay5cbiAgICpcbiAgICogQ2FsbGVkIHdoZW4gdGhlIGVsZW1lbnQncyBwYXJlbnQgTGl2ZVZpZXcgaGFzIGRpc2Nvbm5lY3RlZCBmcm9tIHRoZSBzZXJ2ZXIuXG4gICAqL1xuICBkaXNjb25uZWN0ZWQ/OiAoKSA9PiB2b2lkO1xuXG4gIC8qKlxuICAgKiBUaGUgcmVjb25uZWN0ZWQgY2FsbGJhY2suXG4gICAqXG4gICAqIENhbGxlZCB3aGVuIHRoZSBlbGVtZW50J3MgcGFyZW50IExpdmVWaWV3IGhhcyByZWNvbm5lY3RlZCB0byB0aGUgc2VydmVyLlxuICAgKi9cbiAgcmVjb25uZWN0ZWQ/OiAoKSA9PiB2b2lkO1xuXG4gIC8qKlxuICAgKiBSZXR1cm5zIGFuIG9iamVjdCB3aXRoIG1ldGhvZHMgdG8gbWFuaXBsdWF0ZSB0aGUgRE9NIGFuZCBleGVjdXRlIEphdmFTY3JpcHQuXG4gICAqIFRoZSBhcHBsaWVkIGNoYW5nZXMgaW50ZWdyYXRlIHdpdGggc2VydmVyIERPTSBwYXRjaGluZy5cbiAgICovXG4gIGpzKCk6IEhvb2tKU0NvbW1hbmRzO1xuXG4gIC8qKlxuICAgKiBQdXNoZXMgYW4gZXZlbnQgdG8gdGhlIHNlcnZlci5cbiAgICpcbiAgICogQHBhcmFtIGV2ZW50IC0gVGhlIGV2ZW50IG5hbWUuXG4gICAqIEBwYXJhbSBbcGF5bG9hZF0gLSBUaGUgcGF5bG9hZCB0byBzZW5kIHRvIHRoZSBzZXJ2ZXIuIERlZmF1bHRzIHRvIGFuIGVtcHR5IG9iamVjdC5cbiAgICogQHBhcmFtIFtvblJlcGx5XSAtIEEgY2FsbGJhY2sgdG8gaGFuZGxlIHRoZSBzZXJ2ZXIncyByZXBseS5cbiAgICpcbiAgICogV2hlbiBvblJlcGx5IGlzIG5vdCBwcm92aWRlZCwgdGhlIG1ldGhvZCByZXR1cm5zIGEgUHJvbWlzZSB0aGF0XG4gICAqIFdoZW4gb25SZXBseSBpcyBwcm92aWRlZCwgdGhlIG1ldGhvZCByZXR1cm5zIHZvaWQuXG4gICAqL1xuICBwdXNoRXZlbnQoZXZlbnQ6IHN0cmluZywgcGF5bG9hZDogYW55LCBvblJlcGx5OiBPblJlcGx5KTogdm9pZDtcbiAgcHVzaEV2ZW50KGV2ZW50OiBzdHJpbmcsIHBheWxvYWQ/OiBhbnkpOiBQcm9taXNlPGFueT47XG5cbiAgLyoqXG4gICAqIFB1c2hlZCBhIHRhcmdldGVkIGV2ZW50IHRvIHRoZSBzZXJ2ZXIuXG4gICAqXG4gICAqIEl0IHNlbmRzIHRoZSBldmVudCB0byB0aGUgTGl2ZUNvbXBvbmVudCBvciBMaXZlVmlldyB0aGUgYHNlbGVjdG9yT3JUYXJnZXRgIGlzIGRlZmluZWQgaW4sXG4gICAqIHdoZXJlIGl0cyB2YWx1ZSBjYW4gYmUgZWl0aGVyIGEgcXVlcnkgc2VsZWN0b3IsIGFuIGFjdHVhbCBET00gZWxlbWVudCwgb3IgYSBDSUQgKGNvbXBvbmVudCBpZClcbiAgICogcmV0dXJuZWQgYnkgdGhlIGBAbXlzZWxmYCBhc3NpZ24uXG4gICAqXG4gICAqIElmIHRoZSBxdWVyeSBzZWxlY3RvciByZXR1cm5zIG1vcmUgdGhhbiBvbmUgZWxlbWVudCBpdCB3aWxsIHNlbmQgdGhlIGV2ZW50IHRvIGFsbCBvZiB0aGVtLFxuICAgKiBldmVuIGlmIGFsbCB0aGUgZWxlbWVudHMgYXJlIGluIHRoZSBzYW1lIExpdmVDb21wb25lbnQgb3IgTGl2ZVZpZXcuIEJlY2F1c2Ugb2YgdGhpcyxcbiAgICogaWYgbm8gY2FsbGJhY2sgaXMgcGFzc2VkLCBhIHByb21pc2UgaXMgcmV0dXJuZWQgdGhhdCBtYXRjaGVzIHRoZSByZXR1cm4gdmFsdWUgb2ZcbiAgICogW2BQcm9taXNlLmFsbFNldHRsZWQoKWBdKGh0dHBzOi8vZGV2ZWxvcGVyLm1vemlsbGEub3JnL2VuLVVTL2RvY3MvV2ViL0phdmFTY3JpcHQvUmVmZXJlbmNlL0dsb2JhbF9PYmplY3RzL1Byb21pc2UvYWxsU2V0dGxlZCNyZXR1cm5fdmFsdWUpLlxuICAgKiBJbmRpdmlkdWFsIGZ1bGZpbGxlZCB2YWx1ZXMgYXJlIG9mIHRoZSBmb3JtYXQgYHsgcmVwbHksIHJlZiB9YCwgd2hlcmUgYHJlcGx5YCBpcyB0aGUgc2VydmVyJ3MgcmVwbHkuXG4gICAqXG4gICAqIEBwYXJhbSBzZWxlY3Rvck9yVGFyZ2V0IC0gVGhlIHNlbGVjdG9yLCBlbGVtZW50LCBvciBDSUQgdG8gdGFyZ2V0LlxuICAgKiBAcGFyYW0gZXZlbnQgLSBUaGUgZXZlbnQgbmFtZS5cbiAgICogQHBhcmFtIFtwYXlsb2FkXSAtIFRoZSBwYXlsb2FkIHRvIHNlbmQgdG8gdGhlIHNlcnZlci4gRGVmYXVsdHMgdG8gYW4gZW1wdHkgb2JqZWN0LlxuICAgKiBAcGFyYW0gW29uUmVwbHldIC0gQSBjYWxsYmFjayB0byBoYW5kbGUgdGhlIHNlcnZlcidzIHJlcGx5LlxuICAgKlxuICAgKiBXaGVuIG9uUmVwbHkgaXMgbm90IHByb3ZpZGVkLCB0aGUgbWV0aG9kIHJldHVybnMgYSBQcm9taXNlLlxuICAgKiBXaGVuIG9uUmVwbHkgaXMgcHJvdmlkZWQsIHRoZSBtZXRob2QgcmV0dXJucyB2b2lkLlxuICAgKi9cbiAgcHVzaEV2ZW50VG8oXG4gICAgc2VsZWN0b3JPclRhcmdldDogUGh4VGFyZ2V0LFxuICAgIGV2ZW50OiBzdHJpbmcsXG4gICAgcGF5bG9hZDogb2JqZWN0LFxuICAgIG9uUmVwbHk6IE9uUmVwbHksXG4gICk6IHZvaWQ7XG4gIHB1c2hFdmVudFRvKFxuICAgIHNlbGVjdG9yT3JUYXJnZXQ6IFBoeFRhcmdldCxcbiAgICBldmVudDogc3RyaW5nLFxuICAgIHBheWxvYWQ/OiBvYmplY3QsXG4gICk6IFByb21pc2U8UHJvbWlzZVNldHRsZWRSZXN1bHQ8eyByZXBseTogYW55OyByZWY6IG51bWJlciB9PltdPjtcblxuICAvKipcbiAgICogQWxsb3dzIHRvIHJlZ2lzdGVyIGEgY2FsbGJhY2sgdG8gYmUgY2FsbGVkIHdoZW4gYW4gZXZlbnQgaXMgcmVjZWl2ZWQgZnJvbSB0aGUgc2VydmVyLlxuICAgKlxuICAgKiBUaGlzIGlzIHVzZWQgdG8gaGFuZGxlIGBwdXNoRXZlbnRgIGNhbGxzIGZyb20gdGhlIHNlcnZlci4gVGhlIGNhbGxiYWNrIGlzIGNhbGxlZCB3aXRoIHRoZSBwYXlsb2FkIGZyb20gdGhlIHNlcnZlci5cbiAgICpcbiAgICogQHBhcmFtIGV2ZW50IC0gVGhlIGV2ZW50IG5hbWUuXG4gICAqIEBwYXJhbSBjYWxsYmFjayAtIFRoZSBjYWxsYmFjayB0byBjYWxsIHdoZW4gdGhlIGV2ZW50IGlzIHJlY2VpdmVkLlxuICAgKlxuICAgKiBAcmV0dXJucyBBIHJlZmVyZW5jZSB0byB0aGUgY2FsbGJhY2ssIHdoaWNoIGNhbiBiZSB1c2VkIGluIGByZW1vdmVIYW5kbGVFdmVudGAgdG8gcmVtb3ZlIHRoZSBjYWxsYmFjay5cbiAgICovXG4gIGhhbmRsZUV2ZW50KGV2ZW50OiBzdHJpbmcsIGNhbGxiYWNrOiAocGF5bG9hZDogYW55KSA9PiBhbnkpOiBDYWxsYmFja1JlZjtcblxuICAvKipcbiAgICogUmVtb3ZlcyBhIGNhbGxiYWNrIHJlZ2lzdGVyZWQgd2l0aCBgaGFuZGxlRXZlbnRgLlxuICAgKlxuICAgKiBAcGFyYW0gY2FsbGJhY2tSZWYgLSBUaGUgcmVmZXJlbmNlIHRvIHRoZSBjYWxsYmFjayB0byByZW1vdmUuXG4gICAqL1xuICByZW1vdmVIYW5kbGVFdmVudChyZWY6IENhbGxiYWNrUmVmKTogdm9pZDtcblxuICAvKipcbiAgICogQWxsb3dzIHRvIHRyaWdnZXIgYSBsaXZlIGZpbGUgdXBsb2FkLlxuICAgKlxuICAgKiBAcGFyYW0gbmFtZSAtIFRoZSB1cGxvYWQgbmFtZSBjb3JyZXNwb25kaW5nIHRvIHRoZSBgUGhvZW5peC5MaXZlVmlldy5hbGxvd191cGxvYWQvM2AgY2FsbC5cbiAgICogQHBhcmFtIGZpbGVzIC0gVGhlIGZpbGVzIHRvIHVwbG9hZC5cbiAgICovXG4gIHVwbG9hZChuYW1lOiBhbnksIGZpbGVzOiBhbnkpOiBhbnk7XG5cbiAgLyoqXG4gICAqIEFsbG93cyB0byB0cmlnZ2VyIGEgbGl2ZSBmaWxlIHVwbG9hZCB0byBhIHNwZWNpZmljIHRhcmdldC5cbiAgICpcbiAgICogQHBhcmFtIHNlbGVjdG9yT3JUYXJnZXQgLSBUaGUgdGFyZ2V0IHRvIHVwbG9hZCB0aGUgZmlsZXMgdG8uXG4gICAqIEBwYXJhbSBuYW1lIC0gVGhlIHVwbG9hZCBuYW1lIGNvcnJlc3BvbmRpbmcgdG8gdGhlIGBQaG9lbml4LkxpdmVWaWV3LmFsbG93X3VwbG9hZC8zYCBjYWxsLlxuICAgKiBAcGFyYW0gZmlsZXMgLSBUaGUgZmlsZXMgdG8gdXBsb2FkLlxuICAgKi9cbiAgdXBsb2FkVG8oc2VsZWN0b3JPclRhcmdldDogUGh4VGFyZ2V0LCBuYW1lOiBhbnksIGZpbGVzOiBhbnkpOiBhbnk7XG5cbiAgLy8gYWxsb3cgdW5rbm93biBtZXRob2RzLCBhcyBwZW9wbGUgY2FuIGRlZmluZSB0aGVtIGluIHRoZWlyIGhvb2tzXG4gIFtrZXk6IFByb3BlcnR5S2V5XTogYW55O1xufVxuXG4vLyBiYXNlZCBvbiBodHRwczovL2dpdGh1Yi5jb20vRGVmaW5pdGVseVR5cGVkL0RlZmluaXRlbHlUeXBlZC9ibG9iL2ZhYzFhYTc1YWNkZGRiZjRmMWE5NWU5OGVlMjI5N2I1NGNlNGI0YzkvdHlwZXMvcGhvZW5peF9saXZlX3ZpZXcvaG9va3MuZC50cyNMMjZcbi8vIGxpY2Vuc2VkIHVuZGVyIE1JVFxuZXhwb3J0IGludGVyZmFjZSBIb29rPFQgPSBvYmplY3Q+IHtcbiAgLyoqXG4gICAqIFRoZSBtb3VudGVkIGNhbGxiYWNrLlxuICAgKlxuICAgKiBDYWxsZWQgd2hlbiB0aGUgZWxlbWVudCBoYXMgYmVlbiBhZGRlZCB0byB0aGUgRE9NIGFuZCBpdHMgc2VydmVyIExpdmVWaWV3IGhhcyBmaW5pc2hlZCBtb3VudGluZy5cbiAgICovXG4gIG1vdW50ZWQ/OiAodGhpczogVCAmIEhvb2tJbnRlcmZhY2UpID0+IHZvaWQ7XG5cbiAgLyoqXG4gICAqIFRoZSBiZWZvcmVVcGRhdGUgY2FsbGJhY2suXG4gICAqXG4gICAqIENhbGxlZCB3aGVuIHRoZSBlbGVtZW50IGlzIGFib3V0IHRvIGJlIHVwZGF0ZWQgaW4gdGhlIERPTS5cbiAgICogTm90ZTogYW55IGNhbGwgaGVyZSBtdXN0IGJlIHN5bmNocm9ub3VzIGFzIHRoZSBvcGVyYXRpb24gY2Fubm90IGJlIGRlZmVycmVkIG9yIGNhbmNlbGxlZC5cbiAgICovXG4gIGJlZm9yZVVwZGF0ZT86ICh0aGlzOiBUICYgSG9va0ludGVyZmFjZSkgPT4gdm9pZDtcblxuICAvKipcbiAgICogVGhlIHVwZGF0ZWQgY2FsbGJhY2suXG4gICAqXG4gICAqIENhbGxlZCB3aGVuIHRoZSBlbGVtZW50IGhhcyBiZWVuIHVwZGF0ZWQgaW4gdGhlIERPTSBieSB0aGUgc2VydmVyXG4gICAqL1xuICB1cGRhdGVkPzogKHRoaXM6IFQgJiBIb29rSW50ZXJmYWNlKSA9PiB2b2lkO1xuXG4gIC8qKlxuICAgKiBUaGUgZGVzdHJveWVkIGNhbGxiYWNrLlxuICAgKlxuICAgKiBDYWxsZWQgd2hlbiB0aGUgZWxlbWVudCBoYXMgYmVlbiByZW1vdmVkIGZyb20gdGhlIHBhZ2UsIGVpdGhlciBieSBhIHBhcmVudCB1cGRhdGUsIG9yIGJ5IHRoZSBwYXJlbnQgYmVpbmcgcmVtb3ZlZCBlbnRpcmVseVxuICAgKi9cbiAgZGVzdHJveWVkPzogKHRoaXM6IFQgJiBIb29rSW50ZXJmYWNlKSA9PiB2b2lkO1xuXG4gIC8qKlxuICAgKiBUaGUgZGlzY29ubmVjdGVkIGNhbGxiYWNrLlxuICAgKlxuICAgKiBDYWxsZWQgd2hlbiB0aGUgZWxlbWVudCdzIHBhcmVudCBMaXZlVmlldyBoYXMgZGlzY29ubmVjdGVkIGZyb20gdGhlIHNlcnZlci5cbiAgICovXG4gIGRpc2Nvbm5lY3RlZD86ICh0aGlzOiBUICYgSG9va0ludGVyZmFjZSkgPT4gdm9pZDtcblxuICAvKipcbiAgICogVGhlIHJlY29ubmVjdGVkIGNhbGxiYWNrLlxuICAgKlxuICAgKiBDYWxsZWQgd2hlbiB0aGUgZWxlbWVudCdzIHBhcmVudCBMaXZlVmlldyBoYXMgcmVjb25uZWN0ZWQgdG8gdGhlIHNlcnZlci5cbiAgICovXG4gIHJlY29ubmVjdGVkPzogKHRoaXM6IFQgJiBIb29rSW50ZXJmYWNlKSA9PiB2b2lkO1xuXG4gIC8vIEFsbG93IGN1c3RvbSBtZXRob2RzIHdpdGggYW55IHNpZ25hdHVyZSBhbmQgY3VzdG9tIHByb3BlcnRpZXNcbiAgW2tleTogUHJvcGVydHlLZXldOiBhbnk7XG59XG5cbi8qKlxuICogQmFzZSBjbGFzcyBmb3IgTGl2ZVZpZXcgaG9va3MuIFVzZXJzIGV4dGVuZCB0aGlzIGNsYXNzIHRvIGRlZmluZSB0aGVpciBob29rcy5cbiAqXG4gKiBFeGFtcGxlOlxuICogYGBgdHlwZXNjcmlwdFxuICogY2xhc3MgTXlDdXN0b21Ib29rIGV4dGVuZHMgVmlld0hvb2sge1xuICogICBteVN0YXRlID0gXCJpbml0aWFsXCI7XG4gKlxuICogICBtb3VudGVkKCkge1xuICogICAgIGNvbnNvbGUubG9nKFwiSG9vayBtb3VudGVkIG9uIGVsZW1lbnQ6XCIsIHRoaXMuZWwpO1xuICogICAgIHRoaXMuZWwuYWRkRXZlbnRMaXN0ZW5lcihcImNsaWNrXCIsICgpID0+IHtcbiAqICAgICAgIHRoaXMucHVzaEV2ZW50KFwiZWxlbWVudC1jbGlja2VkXCIsIHsgc3RhdGU6IHRoaXMubXlTdGF0ZSB9KTtcbiAqICAgICB9KTtcbiAqICAgfVxuICpcbiAqICAgdXBkYXRlZCgpIHtcbiAqICAgICBjb25zb2xlLmxvZyhcIkhvb2sgdXBkYXRlZFwiLCB0aGlzLmVsLmlkKTtcbiAqICAgfVxuICpcbiAqICAgbXlDdXN0b21NZXRob2Qoc29tZUFyZzogc3RyaW5nKSB7XG4gKiAgICAgY29uc29sZS5sb2coXCJteUN1c3RvbU1ldGhvZCBjYWxsZWQgd2l0aDpcIiwgc29tZUFyZywgXCJDdXJyZW50IHN0YXRlOlwiLCB0aGlzLm15U3RhdGUpO1xuICogICB9XG4gKiB9XG4gKiBgYGBcbiAqXG4gKiBUaGUgYHRoaXNgIGNvbnRleHQgd2l0aGluIHRoZSBob29rIG1ldGhvZHMgKG1vdW50ZWQsIHVwZGF0ZWQsIGN1c3RvbSBtZXRob2RzLCBldGMuKVxuICogd2lsbCByZWZlciB0byB0aGUgaG9vayBpbnN0YW5jZSwgcHJvdmlkaW5nIGFjY2VzcyB0byBgdGhpcy5lbGAsIGB0aGlzLmxpdmVTb2NrZXRgLFxuICogYHRoaXMucHVzaEV2ZW50KClgLCBldGMuLCBhcyB3ZWxsIGFzIGFueSBwcm9wZXJ0aWVzIG9yIG1ldGhvZHMgZGVmaW5lZCBvbiB0aGUgc3ViY2xhc3MuXG4gKi9cbmV4cG9ydCBjbGFzcyBWaWV3SG9vayBpbXBsZW1lbnRzIEhvb2tJbnRlcmZhY2Uge1xuICBlbDogSFRNTEVsZW1lbnQ7XG4gIGxpdmVTb2NrZXQ6IExpdmVTb2NrZXQ7XG5cbiAgcHJpdmF0ZSBfX2xpc3RlbmVyczogU2V0PENhbGxiYWNrUmVmPjtcbiAgcHJpdmF0ZSBfX2lzRGlzY29ubmVjdGVkOiBib29sZWFuO1xuICBwcml2YXRlIF9fdmlldzogKCkgPT4gVmlldztcblxuICBzdGF0aWMgbWFrZUlEKCkge1xuICAgIHJldHVybiB2aWV3SG9va0lEKys7XG4gIH1cbiAgc3RhdGljIGVsZW1lbnRJRChlbDogSFRNTEVsZW1lbnQpIHtcbiAgICByZXR1cm4gRE9NLnByaXZhdGUoZWwsIEhPT0tfSUQpO1xuICB9XG5cbiAgY29uc3RydWN0b3IodmlldzogVmlldyB8IG51bGwsIGVsOiBIVE1MRWxlbWVudCwgY2FsbGJhY2tzPzogSG9vaykge1xuICAgIHRoaXMuZWwgPSBlbDtcbiAgICB0aGlzLl9fYXR0YWNoVmlldyh2aWV3KTtcbiAgICB0aGlzLl9fbGlzdGVuZXJzID0gbmV3IFNldCgpO1xuICAgIHRoaXMuX19pc0Rpc2Nvbm5lY3RlZCA9IGZhbHNlO1xuICAgIERPTS5wdXRQcml2YXRlKHRoaXMuZWwsIEhPT0tfSUQsIFZpZXdIb29rLm1ha2VJRCgpKTtcblxuICAgIGlmIChjYWxsYmFja3MpIHtcbiAgICAgIC8vIFRoaXMgaW5zdGFuY2UgaXMgZm9yIGFuIG9iamVjdC1saXRlcmFsIGhvb2suIENvcHkgbWV0aG9kcy9wcm9wZXJ0aWVzLlxuICAgICAgLy8gVGhlc2UgYXJlIHByb3BlcnRpZXMgdGhhdCBzaG91bGQgTk9UIGJlIG92ZXJyaWRkZW4gYnkgdGhlIGNhbGxiYWNrcyBvYmplY3QuXG4gICAgICBjb25zdCBwcm90ZWN0ZWRQcm9wcyA9IG5ldyBTZXQoW1xuICAgICAgICBcImVsXCIsXG4gICAgICAgIFwibGl2ZVNvY2tldFwiLFxuICAgICAgICBcIl9fdmlld1wiLFxuICAgICAgICBcIl9fbGlzdGVuZXJzXCIsXG4gICAgICAgIFwiX19pc0Rpc2Nvbm5lY3RlZFwiLFxuICAgICAgICBcImNvbnN0cnVjdG9yXCIsIC8vIFN0YW5kYXJkIG9iamVjdCBwcm9wZXJ0aWVzXG4gICAgICAgIC8vIENvcmUgVmlld0hvb2sgQVBJIG1ldGhvZHNcbiAgICAgICAgXCJqc1wiLFxuICAgICAgICBcInB1c2hFdmVudFwiLFxuICAgICAgICBcInB1c2hFdmVudFRvXCIsXG4gICAgICAgIFwiaGFuZGxlRXZlbnRcIixcbiAgICAgICAgXCJyZW1vdmVIYW5kbGVFdmVudFwiLFxuICAgICAgICBcInVwbG9hZFwiLFxuICAgICAgICBcInVwbG9hZFRvXCIsXG4gICAgICAgIC8vIEludGVybmFsIGxpZmVjeWNsZSBjYWxsZXJzXG4gICAgICAgIFwiX19tb3VudGVkXCIsXG4gICAgICAgIFwiX191cGRhdGVkXCIsXG4gICAgICAgIFwiX19iZWZvcmVVcGRhdGVcIixcbiAgICAgICAgXCJfX2Rlc3Ryb3llZFwiLFxuICAgICAgICBcIl9fcmVjb25uZWN0ZWRcIixcbiAgICAgICAgXCJfX2Rpc2Nvbm5lY3RlZFwiLFxuICAgICAgICBcIl9fY2xlYW51cF9fXCIsXG4gICAgICBdKTtcblxuICAgICAgZm9yIChjb25zdCBrZXkgaW4gY2FsbGJhY2tzKSB7XG4gICAgICAgIGlmIChPYmplY3QucHJvdG90eXBlLmhhc093blByb3BlcnR5LmNhbGwoY2FsbGJhY2tzLCBrZXkpKSB7XG4gICAgICAgICAgKHRoaXMgYXMgYW55KVtrZXldID0gY2FsbGJhY2tzW2tleV07XG4gICAgICAgICAgLy8gZm9yIGJhY2t3YXJkcyBjb21wYXRpYmlsaXR5LCB3ZSBhbGxvdyB0aGUgb3ZlcndyaXRlLCBidXQgd2UgbG9nIGEgd2FybmluZ1xuICAgICAgICAgIGlmIChwcm90ZWN0ZWRQcm9wcy5oYXMoa2V5KSkge1xuICAgICAgICAgICAgY29uc29sZS53YXJuKFxuICAgICAgICAgICAgICBgSG9vayBvYmplY3QgZm9yIGVsZW1lbnQgIyR7ZWwuaWR9IG92ZXJ3cml0ZXMgY29yZSBwcm9wZXJ0eSAnJHtrZXl9JyFgLFxuICAgICAgICAgICAgKTtcbiAgICAgICAgICB9XG4gICAgICAgIH1cbiAgICAgIH1cblxuICAgICAgY29uc3QgbGlmZWN5Y2xlTWV0aG9kczogKGtleW9mIEhvb2spW10gPSBbXG4gICAgICAgIFwibW91bnRlZFwiLFxuICAgICAgICBcImJlZm9yZVVwZGF0ZVwiLFxuICAgICAgICBcInVwZGF0ZWRcIixcbiAgICAgICAgXCJkZXN0cm95ZWRcIixcbiAgICAgICAgXCJkaXNjb25uZWN0ZWRcIixcbiAgICAgICAgXCJyZWNvbm5lY3RlZFwiLFxuICAgICAgXTtcbiAgICAgIGxpZmVjeWNsZU1ldGhvZHMuZm9yRWFjaCgobWV0aG9kTmFtZSkgPT4ge1xuICAgICAgICBpZiAoXG4gICAgICAgICAgY2FsbGJhY2tzW21ldGhvZE5hbWVdICYmXG4gICAgICAgICAgdHlwZW9mIGNhbGxiYWNrc1ttZXRob2ROYW1lXSA9PT0gXCJmdW5jdGlvblwiXG4gICAgICAgICkge1xuICAgICAgICAgICh0aGlzIGFzIGFueSlbbWV0aG9kTmFtZV0gPSBjYWxsYmFja3NbbWV0aG9kTmFtZV07XG4gICAgICAgIH1cbiAgICAgIH0pO1xuICAgIH1cbiAgICAvLyBJZiAnY2FsbGJhY2tzJyBpcyBub3QgcHJvdmlkZWQsIHRoaXMgaXMgYW4gaW5zdGFuY2Ugb2YgYSB1c2VyLWRlZmluZWQgY2xhc3MgKGUuZy4sIE15SG9vaykuXG4gICAgLy8gSXRzIG1ldGhvZHMgKG1vdW50ZWQsIHVwZGF0ZWQsIGN1c3RvbSkgYXJlIGFscmVhZHkgcGFydCBvZiBpdHMgcHJvdG90eXBlIG9yIGluc3RhbmNlLFxuICAgIC8vIGFuZCB3aWxsIGNvcnJlY3RseSBvdmVycmlkZSB0aGUgZGVmYXVsdHMgZnJvbSBWaWV3SG9vay5wcm90b3R5cGUuXG4gIH1cblxuICAvKiogQGludGVybmFsICovXG4gIF9fYXR0YWNoVmlldyh2aWV3OiBWaWV3IHwgbnVsbCkge1xuICAgIGlmICh2aWV3KSB7XG4gICAgICB0aGlzLl9fdmlldyA9ICgpID0+IHZpZXc7XG4gICAgICB0aGlzLmxpdmVTb2NrZXQgPSB2aWV3LmxpdmVTb2NrZXQ7XG4gICAgfSBlbHNlIHtcbiAgICAgIHRoaXMuX192aWV3ID0gKCkgPT4ge1xuICAgICAgICB0aHJvdyBuZXcgRXJyb3IoXG4gICAgICAgICAgYGhvb2sgbm90IHlldCBhdHRhY2hlZCB0byBhIGxpdmUgdmlldzogJHt0aGlzLmVsLm91dGVySFRNTH1gLFxuICAgICAgICApO1xuICAgICAgfTtcbiAgICAgIHRoaXMubGl2ZVNvY2tldCA9IG51bGw7XG4gICAgfVxuICB9XG5cbiAgLy8gRGVmYXVsdCBsaWZlY3ljbGUgbWV0aG9kc1xuICBtb3VudGVkKCk6IHZvaWQge31cbiAgYmVmb3JlVXBkYXRlKCk6IHZvaWQge31cbiAgdXBkYXRlZCgpOiB2b2lkIHt9XG4gIGRlc3Ryb3llZCgpOiB2b2lkIHt9XG4gIGRpc2Nvbm5lY3RlZCgpOiB2b2lkIHt9XG4gIHJlY29ubmVjdGVkKCk6IHZvaWQge31cblxuICAvLyBJbnRlcm5hbCBsaWZlY3ljbGUgY2FsbGVycyAtIGNhbGxlZCBieSB0aGUgVmlld1xuXG4gIC8qKiBAaW50ZXJuYWwgKi9cbiAgX19tb3VudGVkKCkge1xuICAgIHRoaXMubW91bnRlZCgpO1xuICB9XG4gIC8qKiBAaW50ZXJuYWwgKi9cbiAgX191cGRhdGVkKCkge1xuICAgIHRoaXMudXBkYXRlZCgpO1xuICB9XG4gIC8qKiBAaW50ZXJuYWwgKi9cbiAgX19iZWZvcmVVcGRhdGUoKSB7XG4gICAgdGhpcy5iZWZvcmVVcGRhdGUoKTtcbiAgfVxuICAvKiogQGludGVybmFsICovXG4gIF9fZGVzdHJveWVkKCkge1xuICAgIHRoaXMuZGVzdHJveWVkKCk7XG4gICAgRE9NLmRlbGV0ZVByaXZhdGUodGhpcy5lbCwgSE9PS19JRCk7IC8vIGh0dHBzOi8vZ2l0aHViLmNvbS9waG9lbml4ZnJhbWV3b3JrL3Bob2VuaXhfbGl2ZV92aWV3L2lzc3Vlcy8zNDk2XG4gIH1cbiAgLyoqIEBpbnRlcm5hbCAqL1xuICBfX3JlY29ubmVjdGVkKCkge1xuICAgIGlmICh0aGlzLl9faXNEaXNjb25uZWN0ZWQpIHtcbiAgICAgIHRoaXMuX19pc0Rpc2Nvbm5lY3RlZCA9IGZhbHNlO1xuICAgICAgdGhpcy5yZWNvbm5lY3RlZCgpO1xuICAgIH1cbiAgfVxuICAvKiogQGludGVybmFsICovXG4gIF9fZGlzY29ubmVjdGVkKCkge1xuICAgIHRoaXMuX19pc0Rpc2Nvbm5lY3RlZCA9IHRydWU7XG4gICAgdGhpcy5kaXNjb25uZWN0ZWQoKTtcbiAgfVxuXG4gIGpzKCk6IEhvb2tKU0NvbW1hbmRzIHtcbiAgICByZXR1cm4ge1xuICAgICAgLi4uanNDb21tYW5kcyh0aGlzLl9fdmlldygpLmxpdmVTb2NrZXQsIFwiaG9va1wiKSxcbiAgICAgIGV4ZWM6IChlbmNvZGVkSlM6IHN0cmluZykgPT4ge1xuICAgICAgICB0aGlzLl9fdmlldygpLmxpdmVTb2NrZXQuZXhlY0pTKHRoaXMuZWwsIGVuY29kZWRKUywgXCJob29rXCIpO1xuICAgICAgfSxcbiAgICB9O1xuICB9XG5cbiAgcHVzaEV2ZW50KGV2ZW50OiBzdHJpbmcsIHBheWxvYWQ/OiBhbnksIG9uUmVwbHk/OiBPblJlcGx5KSB7XG4gICAgY29uc3QgcHJvbWlzZSA9IHRoaXMuX192aWV3KCkucHVzaEhvb2tFdmVudChcbiAgICAgIHRoaXMuZWwsXG4gICAgICBudWxsLFxuICAgICAgZXZlbnQsXG4gICAgICBwYXlsb2FkIHx8IHt9LFxuICAgICk7XG4gICAgaWYgKG9uUmVwbHkgPT09IHVuZGVmaW5lZCkge1xuICAgICAgcmV0dXJuIHByb21pc2UudGhlbigoeyByZXBseSB9KSA9PiByZXBseSk7XG4gICAgfVxuICAgIHByb21pc2UudGhlbigoeyByZXBseSwgcmVmIH0pID0+IG9uUmVwbHkocmVwbHksIHJlZikpLmNhdGNoKCgpID0+IHt9KTtcbiAgICByZXR1cm47XG4gIH1cblxuICBwdXNoRXZlbnRUbyhcbiAgICBzZWxlY3Rvck9yVGFyZ2V0OiBQaHhUYXJnZXQsXG4gICAgZXZlbnQ6IHN0cmluZyxcbiAgICBwYXlsb2FkPzogb2JqZWN0LFxuICAgIG9uUmVwbHk/OiBPblJlcGx5LFxuICApIHtcbiAgICBpZiAob25SZXBseSA9PT0gdW5kZWZpbmVkKSB7XG4gICAgICBjb25zdCB0YXJnZXRQYWlyOiB7IHZpZXc6IFZpZXc7IHRhcmdldEN0eDogYW55IH1bXSA9IFtdO1xuICAgICAgdGhpcy5fX3ZpZXcoKS53aXRoaW5UYXJnZXRzKHNlbGVjdG9yT3JUYXJnZXQsICh2aWV3LCB0YXJnZXRDdHgpID0+IHtcbiAgICAgICAgdGFyZ2V0UGFpci5wdXNoKHsgdmlldywgdGFyZ2V0Q3R4IH0pO1xuICAgICAgfSk7XG4gICAgICBjb25zdCBwcm9taXNlcyA9IHRhcmdldFBhaXIubWFwKCh7IHZpZXcsIHRhcmdldEN0eCB9KSA9PiB7XG4gICAgICAgIHJldHVybiB2aWV3LnB1c2hIb29rRXZlbnQodGhpcy5lbCwgdGFyZ2V0Q3R4LCBldmVudCwgcGF5bG9hZCB8fCB7fSk7XG4gICAgICB9KTtcbiAgICAgIHJldHVybiBQcm9taXNlLmFsbFNldHRsZWQocHJvbWlzZXMpO1xuICAgIH1cbiAgICB0aGlzLl9fdmlldygpLndpdGhpblRhcmdldHMoc2VsZWN0b3JPclRhcmdldCwgKHZpZXcsIHRhcmdldEN0eCkgPT4ge1xuICAgICAgdmlld1xuICAgICAgICAucHVzaEhvb2tFdmVudCh0aGlzLmVsLCB0YXJnZXRDdHgsIGV2ZW50LCBwYXlsb2FkIHx8IHt9KVxuICAgICAgICAudGhlbigoeyByZXBseSwgcmVmIH0pID0+IG9uUmVwbHkocmVwbHksIHJlZikpXG4gICAgICAgIC5jYXRjaCgoKSA9PiB7fSk7XG4gICAgfSk7XG4gICAgcmV0dXJuO1xuICB9XG5cbiAgaGFuZGxlRXZlbnQoZXZlbnQ6IHN0cmluZywgY2FsbGJhY2s6IChwYXlsb2FkOiBhbnkpID0+IGFueSk6IENhbGxiYWNrUmVmIHtcbiAgICBjb25zdCBjYWxsYmFja1JlZjogQ2FsbGJhY2tSZWYgPSB7XG4gICAgICBldmVudCxcbiAgICAgIGNhbGxiYWNrOiAoY3VzdG9tRXZlbnQ6IEN1c3RvbUV2ZW50KSA9PiBjYWxsYmFjayhjdXN0b21FdmVudC5kZXRhaWwpLFxuICAgIH07XG4gICAgd2luZG93LmFkZEV2ZW50TGlzdGVuZXIoXG4gICAgICBgcGh4OiR7ZXZlbnR9YCxcbiAgICAgIGNhbGxiYWNrUmVmLmNhbGxiYWNrIGFzIEV2ZW50TGlzdGVuZXIsXG4gICAgKTtcbiAgICB0aGlzLl9fbGlzdGVuZXJzLmFkZChjYWxsYmFja1JlZik7XG4gICAgcmV0dXJuIGNhbGxiYWNrUmVmO1xuICB9XG5cbiAgcmVtb3ZlSGFuZGxlRXZlbnQocmVmOiBDYWxsYmFja1JlZik6IHZvaWQge1xuICAgIHdpbmRvdy5yZW1vdmVFdmVudExpc3RlbmVyKFxuICAgICAgYHBoeDoke3JlZi5ldmVudH1gLFxuICAgICAgcmVmLmNhbGxiYWNrIGFzIEV2ZW50TGlzdGVuZXIsXG4gICAgKTtcbiAgICB0aGlzLl9fbGlzdGVuZXJzLmRlbGV0ZShyZWYpO1xuICB9XG5cbiAgdXBsb2FkKG5hbWU6IHN0cmluZywgZmlsZXM6IEZpbGVMaXN0KTogYW55IHtcbiAgICByZXR1cm4gdGhpcy5fX3ZpZXcoKS5kaXNwYXRjaFVwbG9hZHMobnVsbCwgbmFtZSwgZmlsZXMpO1xuICB9XG5cbiAgdXBsb2FkVG8oc2VsZWN0b3JPclRhcmdldDogUGh4VGFyZ2V0LCBuYW1lOiBzdHJpbmcsIGZpbGVzOiBGaWxlTGlzdCk6IGFueSB7XG4gICAgcmV0dXJuIHRoaXMuX192aWV3KCkud2l0aGluVGFyZ2V0cyhzZWxlY3Rvck9yVGFyZ2V0LCAodmlldywgdGFyZ2V0Q3R4KSA9PiB7XG4gICAgICB2aWV3LmRpc3BhdGNoVXBsb2Fkcyh0YXJnZXRDdHgsIG5hbWUsIGZpbGVzKTtcbiAgICB9KTtcbiAgfVxuXG4gIC8qKiBAaW50ZXJuYWwgKi9cbiAgX19jbGVhbnVwX18oKSB7XG4gICAgdGhpcy5fX2xpc3RlbmVycy5mb3JFYWNoKChjYWxsYmFja1JlZikgPT5cbiAgICAgIHRoaXMucmVtb3ZlSGFuZGxlRXZlbnQoY2FsbGJhY2tSZWYpLFxuICAgICk7XG4gIH1cbn1cblxuZXhwb3J0IHR5cGUgSG9va3NPcHRpb25zID0gUmVjb3JkPHN0cmluZywgdHlwZW9mIFZpZXdIb29rIHwgSG9vaz47XG5cbmV4cG9ydCBkZWZhdWx0IFZpZXdIb29rO1xuIiwgImltcG9ydCB7XG4gIEJFRk9SRV9VTkxPQURfTE9BREVSX1RJTUVPVVQsXG4gIENIRUNLQUJMRV9JTlBVVFMsXG4gIENPTlNFQ1VUSVZFX1JFTE9BRFMsXG4gIFBIWF9BVVRPX1JFQ09WRVIsXG4gIFBIWF9DT01QT05FTlQsXG4gIFBIWF9WSUVXX1JFRixcbiAgUEhYX0NPTk5FQ1RFRF9DTEFTUyxcbiAgUEhYX0RJU0FCTEVfV0lUSCxcbiAgUEhYX0RJU0FCTEVfV0lUSF9SRVNUT1JFLFxuICBQSFhfRElTQUJMRUQsXG4gIFBIWF9MT0FESU5HX0NMQVNTLFxuICBQSFhfRVJST1JfQ0xBU1MsXG4gIFBIWF9DTElFTlRfRVJST1JfQ0xBU1MsXG4gIFBIWF9TRVJWRVJfRVJST1JfQ0xBU1MsXG4gIFBIWF9IQVNfRk9DVVNFRCxcbiAgUEhYX0hBU19TVUJNSVRURUQsXG4gIFBIWF9IT09LLFxuICBQSFhfUEFSRU5UX0lELFxuICBQSFhfUFJPR1JFU1MsXG4gIFBIWF9SRUFET05MWSxcbiAgUEhYX1JFRl9MT0FESU5HLFxuICBQSFhfUkVGX1NSQyxcbiAgUEhYX1JFRl9MT0NLLFxuICBQSFhfUk9PVF9JRCxcbiAgUEhYX1NFU1NJT04sXG4gIFBIWF9TVEFUSUMsXG4gIFBIWF9TVElDS1ksXG4gIFBIWF9UUkFDS19TVEFUSUMsXG4gIFBIWF9UUkFDS19VUExPQURTLFxuICBQSFhfVVBEQVRFLFxuICBQSFhfVVBMT0FEX1JFRixcbiAgUEhYX1ZJRVdfU0VMRUNUT1IsXG4gIFBIWF9NQUlOLFxuICBQSFhfTU9VTlRFRCxcbiAgUFVTSF9USU1FT1VULFxuICBQSFhfVklFV1BPUlRfVE9QLFxuICBQSFhfVklFV1BPUlRfQk9UVE9NLFxuICBNQVhfQ0hJTERfSk9JTl9BVFRFTVBUUyxcbiAgUEhYX0xWX1BJRCxcbn0gZnJvbSBcIi4vY29uc3RhbnRzXCI7XG5cbmltcG9ydCB7XG4gIGNsb25lLFxuICBjbG9zZXN0UGh4QmluZGluZyxcbiAgaXNFbXB0eSxcbiAgaXNFcXVhbE9iaixcbiAgbG9nRXJyb3IsXG4gIG1heWJlLFxuICBpc0NpZCxcbn0gZnJvbSBcIi4vdXRpbHNcIjtcblxuaW1wb3J0IEJyb3dzZXIgZnJvbSBcIi4vYnJvd3NlclwiO1xuaW1wb3J0IERPTSBmcm9tIFwiLi9kb21cIjtcbmltcG9ydCBFbGVtZW50UmVmIGZyb20gXCIuL2VsZW1lbnRfcmVmXCI7XG5pbXBvcnQgRE9NUGF0Y2ggZnJvbSBcIi4vZG9tX3BhdGNoXCI7XG5pbXBvcnQgTGl2ZVVwbG9hZGVyIGZyb20gXCIuL2xpdmVfdXBsb2FkZXJcIjtcbmltcG9ydCBSZW5kZXJlZCBmcm9tIFwiLi9yZW5kZXJlZFwiO1xuaW1wb3J0IHsgVmlld0hvb2sgfSBmcm9tIFwiLi92aWV3X2hvb2tcIjtcbmltcG9ydCBKUyBmcm9tIFwiLi9qc1wiO1xuXG5pbXBvcnQgbW9ycGhkb20gZnJvbSBcIm1vcnBoZG9tXCI7XG5cbmV4cG9ydCBjb25zdCBwcmVwZW5kRm9ybURhdGFLZXkgPSAoa2V5LCBwcmVmaXgpID0+IHtcbiAgY29uc3QgaXNBcnJheSA9IGtleS5lbmRzV2l0aChcIltdXCIpO1xuICAvLyBSZW1vdmUgdGhlIFwiW11cIiBpZiBpdCdzIGFuIGFycmF5XG4gIGxldCBiYXNlS2V5ID0gaXNBcnJheSA/IGtleS5zbGljZSgwLCAtMikgOiBrZXk7XG4gIC8vIFJlcGxhY2UgbGFzdCBvY2N1cnJlbmNlIG9mIGtleSBiZWZvcmUgYSBjbG9zaW5nIGJyYWNrZXQgb3IgdGhlIGVuZCB3aXRoIGtleSBwbHVzIHN1ZmZpeFxuICBiYXNlS2V5ID0gYmFzZUtleS5yZXBsYWNlKC8oW15cXFtcXF1dKykoXFxdPyQpLywgYCR7cHJlZml4fSQxJDJgKTtcbiAgLy8gQWRkIGJhY2sgdGhlIFwiW11cIiBpZiBpdCB3YXMgYW4gYXJyYXlcbiAgaWYgKGlzQXJyYXkpIHtcbiAgICBiYXNlS2V5ICs9IFwiW11cIjtcbiAgfVxuICByZXR1cm4gYmFzZUtleTtcbn07XG5cbmNvbnN0IHNlcmlhbGl6ZUZvcm0gPSAoZm9ybSwgb3B0cywgb25seU5hbWVzID0gW10pID0+IHtcbiAgY29uc3QgeyBzdWJtaXR0ZXIgfSA9IG9wdHM7XG5cbiAgLy8gV2UgbXVzdCBpbmplY3QgdGhlIHN1Ym1pdHRlciBpbiB0aGUgb3JkZXIgdGhhdCBpdCBleGlzdHMgaW4gdGhlIERPTVxuICAvLyByZWxhdGl2ZSB0byBvdGhlciBpbnB1dHMuIEZvciBleGFtcGxlLCBmb3IgY2hlY2tib3ggZ3JvdXBzLCB0aGUgb3JkZXIgbXVzdCBiZSBtYWludGFpbmVkLlxuICBsZXQgaW5qZWN0ZWRFbGVtZW50O1xuICBpZiAoc3VibWl0dGVyICYmIHN1Ym1pdHRlci5uYW1lKSB7XG4gICAgY29uc3QgaW5wdXQgPSBkb2N1bWVudC5jcmVhdGVFbGVtZW50KFwiaW5wdXRcIik7XG4gICAgaW5wdXQudHlwZSA9IFwiaGlkZGVuXCI7XG4gICAgLy8gc2V0IHRoZSBmb3JtIGF0dHJpYnV0ZSBpZiB0aGUgc3VibWl0dGVyIGhhcyBvbmU7XG4gICAgLy8gdGhpcyBjYW4gaGFwcGVuIGlmIHRoZSBlbGVtZW50IGlzIG91dHNpZGUgdGhlIGFjdHVhbCBmb3JtIGVsZW1lbnRcbiAgICBjb25zdCBmb3JtSWQgPSBzdWJtaXR0ZXIuZ2V0QXR0cmlidXRlKFwiZm9ybVwiKTtcbiAgICBpZiAoZm9ybUlkKSB7XG4gICAgICBpbnB1dC5zZXRBdHRyaWJ1dGUoXCJmb3JtXCIsIGZvcm1JZCk7XG4gICAgfVxuICAgIGlucHV0Lm5hbWUgPSBzdWJtaXR0ZXIubmFtZTtcbiAgICBpbnB1dC52YWx1ZSA9IHN1Ym1pdHRlci52YWx1ZTtcbiAgICBzdWJtaXR0ZXIucGFyZW50RWxlbWVudC5pbnNlcnRCZWZvcmUoaW5wdXQsIHN1Ym1pdHRlcik7XG4gICAgaW5qZWN0ZWRFbGVtZW50ID0gaW5wdXQ7XG4gIH1cblxuICBjb25zdCBmb3JtRGF0YSA9IG5ldyBGb3JtRGF0YShmb3JtKTtcbiAgY29uc3QgdG9SZW1vdmUgPSBbXTtcblxuICBmb3JtRGF0YS5mb3JFYWNoKCh2YWwsIGtleSwgX2luZGV4KSA9PiB7XG4gICAgaWYgKHZhbCBpbnN0YW5jZW9mIEZpbGUpIHtcbiAgICAgIHRvUmVtb3ZlLnB1c2goa2V5KTtcbiAgICB9XG4gIH0pO1xuXG4gIC8vIENsZWFudXAgYWZ0ZXIgYnVpbGRpbmcgZmlsZURhdGFcbiAgdG9SZW1vdmUuZm9yRWFjaCgoa2V5KSA9PiBmb3JtRGF0YS5kZWxldGUoa2V5KSk7XG5cbiAgY29uc3QgcGFyYW1zID0gbmV3IFVSTFNlYXJjaFBhcmFtcygpO1xuXG4gIGNvbnN0IHsgaW5wdXRzVW51c2VkLCBvbmx5SGlkZGVuSW5wdXRzIH0gPSBBcnJheS5mcm9tKGZvcm0uZWxlbWVudHMpLnJlZHVjZShcbiAgICAoYWNjLCBpbnB1dCkgPT4ge1xuICAgICAgY29uc3QgeyBpbnB1dHNVbnVzZWQsIG9ubHlIaWRkZW5JbnB1dHMgfSA9IGFjYztcbiAgICAgIGNvbnN0IGtleSA9IGlucHV0Lm5hbWU7XG4gICAgICBpZiAoIWtleSkge1xuICAgICAgICByZXR1cm4gYWNjO1xuICAgICAgfVxuXG4gICAgICBpZiAoaW5wdXRzVW51c2VkW2tleV0gPT09IHVuZGVmaW5lZCkge1xuICAgICAgICBpbnB1dHNVbnVzZWRba2V5XSA9IHRydWU7XG4gICAgICB9XG4gICAgICBpZiAob25seUhpZGRlbklucHV0c1trZXldID09PSB1bmRlZmluZWQpIHtcbiAgICAgICAgb25seUhpZGRlbklucHV0c1trZXldID0gdHJ1ZTtcbiAgICAgIH1cblxuICAgICAgY29uc3QgaXNVc2VkID1cbiAgICAgICAgRE9NLnByaXZhdGUoaW5wdXQsIFBIWF9IQVNfRk9DVVNFRCkgfHxcbiAgICAgICAgRE9NLnByaXZhdGUoaW5wdXQsIFBIWF9IQVNfU1VCTUlUVEVEKTtcbiAgICAgIGNvbnN0IGlzSGlkZGVuID0gaW5wdXQudHlwZSA9PT0gXCJoaWRkZW5cIjtcbiAgICAgIGlucHV0c1VudXNlZFtrZXldID0gaW5wdXRzVW51c2VkW2tleV0gJiYgIWlzVXNlZDtcbiAgICAgIG9ubHlIaWRkZW5JbnB1dHNba2V5XSA9IG9ubHlIaWRkZW5JbnB1dHNba2V5XSAmJiBpc0hpZGRlbjtcblxuICAgICAgcmV0dXJuIGFjYztcbiAgICB9LFxuICAgIHsgaW5wdXRzVW51c2VkOiB7fSwgb25seUhpZGRlbklucHV0czoge30gfSxcbiAgKTtcblxuICBmb3IgKGNvbnN0IFtrZXksIHZhbF0gb2YgZm9ybURhdGEuZW50cmllcygpKSB7XG4gICAgaWYgKG9ubHlOYW1lcy5sZW5ndGggPT09IDAgfHwgb25seU5hbWVzLmluZGV4T2Yoa2V5KSA+PSAwKSB7XG4gICAgICBjb25zdCBpc1VudXNlZCA9IGlucHV0c1VudXNlZFtrZXldO1xuICAgICAgY29uc3QgaGlkZGVuID0gb25seUhpZGRlbklucHV0c1trZXldO1xuICAgICAgaWYgKGlzVW51c2VkICYmICEoc3VibWl0dGVyICYmIHN1Ym1pdHRlci5uYW1lID09IGtleSkgJiYgIWhpZGRlbikge1xuICAgICAgICBwYXJhbXMuYXBwZW5kKHByZXBlbmRGb3JtRGF0YUtleShrZXksIFwiX3VudXNlZF9cIiksIFwiXCIpO1xuICAgICAgfVxuICAgICAgaWYgKHR5cGVvZiB2YWwgPT09IFwic3RyaW5nXCIpIHtcbiAgICAgICAgcGFyYW1zLmFwcGVuZChrZXksIHZhbCk7XG4gICAgICB9XG4gICAgfVxuICB9XG5cbiAgLy8gcmVtb3ZlIHRoZSBpbmplY3RlZCBlbGVtZW50IGFnYWluXG4gIC8vIChpdCB3b3VsZCBiZSByZW1vdmVkIGJ5IHRoZSBuZXh0IGRvbSBwYXRjaCBhbnl3YXksIGJ1dCB0aGlzIGlzIGNsZWFuZXIpXG4gIGlmIChzdWJtaXR0ZXIgJiYgaW5qZWN0ZWRFbGVtZW50KSB7XG4gICAgc3VibWl0dGVyLnBhcmVudEVsZW1lbnQucmVtb3ZlQ2hpbGQoaW5qZWN0ZWRFbGVtZW50KTtcbiAgfVxuXG4gIHJldHVybiBwYXJhbXMudG9TdHJpbmcoKTtcbn07XG5cbmV4cG9ydCBkZWZhdWx0IGNsYXNzIFZpZXcge1xuICBzdGF0aWMgY2xvc2VzdFZpZXcoZWwpIHtcbiAgICBjb25zdCBsaXZlVmlld0VsID0gZWwuY2xvc2VzdChQSFhfVklFV19TRUxFQ1RPUik7XG4gICAgcmV0dXJuIGxpdmVWaWV3RWwgPyBET00ucHJpdmF0ZShsaXZlVmlld0VsLCBcInZpZXdcIikgOiBudWxsO1xuICB9XG5cbiAgY29uc3RydWN0b3IoZWwsIGxpdmVTb2NrZXQsIHBhcmVudFZpZXcsIGZsYXNoLCBsaXZlUmVmZXJlcikge1xuICAgIHRoaXMuaXNEZWFkID0gZmFsc2U7XG4gICAgdGhpcy5saXZlU29ja2V0ID0gbGl2ZVNvY2tldDtcbiAgICB0aGlzLmZsYXNoID0gZmxhc2g7XG4gICAgdGhpcy5wYXJlbnQgPSBwYXJlbnRWaWV3O1xuICAgIHRoaXMucm9vdCA9IHBhcmVudFZpZXcgPyBwYXJlbnRWaWV3LnJvb3QgOiB0aGlzO1xuICAgIHRoaXMuZWwgPSBlbDtcbiAgICAvLyBzZWUgaHR0cHM6Ly9naXRodWIuY29tL3Bob2VuaXhmcmFtZXdvcmsvcGhvZW5peF9saXZlX3ZpZXcvcHVsbC8zNzIxXG4gICAgLy8gY2hlY2sgaWYgdGhlIGVsZW1lbnQgaXMgYWxyZWFkeSBib3VuZCB0byBhIHZpZXdcbiAgICBjb25zdCBib3VuZFZpZXcgPSBET00ucHJpdmF0ZSh0aGlzLmVsLCBcInZpZXdcIik7XG4gICAgaWYgKGJvdW5kVmlldyAhPT0gdW5kZWZpbmVkICYmIGJvdW5kVmlldy5pc0RlYWQgIT09IHRydWUpIHtcbiAgICAgIGxvZ0Vycm9yKFxuICAgICAgICBgVGhlIERPTSBlbGVtZW50IGZvciB0aGlzIHZpZXcgaGFzIGFscmVhZHkgYmVlbiBib3VuZCB0byBhIHZpZXcuXG5cbiAgICAgICAgQW4gZWxlbWVudCBjYW4gb25seSBldmVyIGJlIGFzc29jaWF0ZWQgd2l0aCBhIHNpbmdsZSB2aWV3IVxuICAgICAgICBQbGVhc2UgZW5zdXJlIHRoYXQgeW91IGFyZSBub3QgdHJ5aW5nIHRvIGluaXRpYWxpemUgbXVsdGlwbGUgTGl2ZVNvY2tldHMgb24gdGhlIHNhbWUgcGFnZS5cbiAgICAgICAgVGhpcyBjb3VsZCBoYXBwZW4gaWYgeW91J3JlIGFjY2lkZW50YWxseSB0cnlpbmcgdG8gcmVuZGVyIHlvdXIgcm9vdCBsYXlvdXQgbW9yZSB0aGFuIG9uY2UuXG4gICAgICAgIEVuc3VyZSB0aGF0IHRoZSB0ZW1wbGF0ZSBzZXQgb24gdGhlIExpdmVWaWV3IGlzIGRpZmZlcmVudCB0aGFuIHRoZSByb290IGxheW91dC5cbiAgICAgIGAsXG4gICAgICAgIHsgdmlldzogYm91bmRWaWV3IH0sXG4gICAgICApO1xuICAgICAgdGhyb3cgbmV3IEVycm9yKFwiQ2Fubm90IGJpbmQgbXVsdGlwbGUgdmlld3MgdG8gdGhlIHNhbWUgRE9NIGVsZW1lbnQuXCIpO1xuICAgIH1cbiAgICAvLyBiaW5kIHRoZSB2aWV3IHRvIHRoZSBlbGVtZW50XG4gICAgRE9NLnB1dFByaXZhdGUodGhpcy5lbCwgXCJ2aWV3XCIsIHRoaXMpO1xuICAgIHRoaXMuaWQgPSB0aGlzLmVsLmlkO1xuICAgIHRoaXMucmVmID0gMDtcbiAgICB0aGlzLmxhc3RBY2tSZWYgPSBudWxsO1xuICAgIHRoaXMuY2hpbGRKb2lucyA9IDA7XG4gICAgLyoqXG4gICAgICogQHR5cGUge1JldHVyblR5cGU8dHlwZW9mIHNldFRpbWVvdXQ+IHwgbnVsbH1cbiAgICAgKi9cbiAgICB0aGlzLmxvYWRlclRpbWVyID0gbnVsbDtcbiAgICAvKipcbiAgICAgKiBAdHlwZSB7UmV0dXJuVHlwZTx0eXBlb2Ygc2V0VGltZW91dD4gfCBudWxsfVxuICAgICAqL1xuICAgIHRoaXMuZGlzY29ubmVjdGVkVGltZXIgPSBudWxsO1xuICAgIHRoaXMucGVuZGluZ0RpZmZzID0gW107XG4gICAgdGhpcy5wZW5kaW5nRm9ybXMgPSBuZXcgU2V0KCk7XG4gICAgdGhpcy5yZWRpcmVjdCA9IGZhbHNlO1xuICAgIHRoaXMuaHJlZiA9IG51bGw7XG4gICAgdGhpcy5qb2luQ291bnQgPSB0aGlzLnBhcmVudCA/IHRoaXMucGFyZW50LmpvaW5Db3VudCAtIDEgOiAwO1xuICAgIHRoaXMuam9pbkF0dGVtcHRzID0gMDtcbiAgICB0aGlzLmpvaW5QZW5kaW5nID0gdHJ1ZTtcbiAgICB0aGlzLmRlc3Ryb3llZCA9IGZhbHNlO1xuICAgIHRoaXMuam9pbkNhbGxiYWNrID0gZnVuY3Rpb24gKG9uRG9uZSkge1xuICAgICAgb25Eb25lICYmIG9uRG9uZSgpO1xuICAgIH07XG4gICAgdGhpcy5zdG9wQ2FsbGJhY2sgPSBmdW5jdGlvbiAoKSB7fTtcbiAgICB0aGlzLnBlbmRpbmdKb2luT3BzID0gdGhpcy5wYXJlbnQgPyBudWxsIDogW107XG4gICAgdGhpcy52aWV3SG9va3MgPSB7fTtcbiAgICB0aGlzLmZvcm1TdWJtaXRzID0gW107XG4gICAgdGhpcy5jaGlsZHJlbiA9IHRoaXMucGFyZW50ID8gbnVsbCA6IHt9O1xuICAgIHRoaXMucm9vdC5jaGlsZHJlblt0aGlzLmlkXSA9IHt9O1xuICAgIHRoaXMuZm9ybXNGb3JSZWNvdmVyeSA9IHt9O1xuICAgIHRoaXMuY2hhbm5lbCA9IHRoaXMubGl2ZVNvY2tldC5jaGFubmVsKGBsdjoke3RoaXMuaWR9YCwgKCkgPT4ge1xuICAgICAgY29uc3QgdXJsID0gdGhpcy5ocmVmICYmIHRoaXMuZXhwYW5kVVJMKHRoaXMuaHJlZik7XG4gICAgICByZXR1cm4ge1xuICAgICAgICByZWRpcmVjdDogdGhpcy5yZWRpcmVjdCA/IHVybCA6IHVuZGVmaW5lZCxcbiAgICAgICAgdXJsOiB0aGlzLnJlZGlyZWN0ID8gdW5kZWZpbmVkIDogdXJsIHx8IHVuZGVmaW5lZCxcbiAgICAgICAgcGFyYW1zOiB0aGlzLmNvbm5lY3RQYXJhbXMobGl2ZVJlZmVyZXIpLFxuICAgICAgICBzZXNzaW9uOiB0aGlzLmdldFNlc3Npb24oKSxcbiAgICAgICAgc3RhdGljOiB0aGlzLmdldFN0YXRpYygpLFxuICAgICAgICBmbGFzaDogdGhpcy5mbGFzaCxcbiAgICAgICAgc3RpY2t5OiB0aGlzLmVsLmhhc0F0dHJpYnV0ZShQSFhfU1RJQ0tZKSxcbiAgICAgIH07XG4gICAgfSk7XG4gICAgdGhpcy5wb3J0YWxFbGVtZW50SWRzID0gbmV3IFNldCgpO1xuICB9XG5cbiAgc2V0SHJlZihocmVmKSB7XG4gICAgdGhpcy5ocmVmID0gaHJlZjtcbiAgfVxuXG4gIHNldFJlZGlyZWN0KGhyZWYpIHtcbiAgICB0aGlzLnJlZGlyZWN0ID0gdHJ1ZTtcbiAgICB0aGlzLmhyZWYgPSBocmVmO1xuICB9XG5cbiAgaXNNYWluKCkge1xuICAgIHJldHVybiB0aGlzLmVsLmhhc0F0dHJpYnV0ZShQSFhfTUFJTik7XG4gIH1cblxuICBjb25uZWN0UGFyYW1zKGxpdmVSZWZlcmVyKSB7XG4gICAgY29uc3QgcGFyYW1zID0gdGhpcy5saXZlU29ja2V0LnBhcmFtcyh0aGlzLmVsKTtcbiAgICBjb25zdCBtYW5pZmVzdCA9IERPTS5hbGwoZG9jdW1lbnQsIGBbJHt0aGlzLmJpbmRpbmcoUEhYX1RSQUNLX1NUQVRJQyl9XWApXG4gICAgICAubWFwKChub2RlKSA9PiBub2RlLnNyYyB8fCBub2RlLmhyZWYpXG4gICAgICAuZmlsdGVyKCh1cmwpID0+IHR5cGVvZiB1cmwgPT09IFwic3RyaW5nXCIpO1xuXG4gICAgaWYgKG1hbmlmZXN0Lmxlbmd0aCA+IDApIHtcbiAgICAgIHBhcmFtc1tcIl90cmFja19zdGF0aWNcIl0gPSBtYW5pZmVzdDtcbiAgICB9XG4gICAgcGFyYW1zW1wiX21vdW50c1wiXSA9IHRoaXMuam9pbkNvdW50O1xuICAgIHBhcmFtc1tcIl9tb3VudF9hdHRlbXB0c1wiXSA9IHRoaXMuam9pbkF0dGVtcHRzO1xuICAgIHBhcmFtc1tcIl9saXZlX3JlZmVyZXJcIl0gPSBsaXZlUmVmZXJlcjtcbiAgICB0aGlzLmpvaW5BdHRlbXB0cysrO1xuXG4gICAgcmV0dXJuIHBhcmFtcztcbiAgfVxuXG4gIGlzQ29ubmVjdGVkKCkge1xuICAgIHJldHVybiB0aGlzLmNoYW5uZWwuY2FuUHVzaCgpO1xuICB9XG5cbiAgZ2V0U2Vzc2lvbigpIHtcbiAgICByZXR1cm4gdGhpcy5lbC5nZXRBdHRyaWJ1dGUoUEhYX1NFU1NJT04pO1xuICB9XG5cbiAgZ2V0U3RhdGljKCkge1xuICAgIGNvbnN0IHZhbCA9IHRoaXMuZWwuZ2V0QXR0cmlidXRlKFBIWF9TVEFUSUMpO1xuICAgIHJldHVybiB2YWwgPT09IFwiXCIgPyBudWxsIDogdmFsO1xuICB9XG5cbiAgZGVzdHJveShjYWxsYmFjayA9IGZ1bmN0aW9uICgpIHt9KSB7XG4gICAgdGhpcy5kZXN0cm95QWxsQ2hpbGRyZW4oKTtcbiAgICB0aGlzLmRlc3Ryb3lQb3J0YWxFbGVtZW50cygpO1xuICAgIHRoaXMuZGVzdHJveWVkID0gdHJ1ZTtcbiAgICBET00uZGVsZXRlUHJpdmF0ZSh0aGlzLmVsLCBcInZpZXdcIik7XG4gICAgZGVsZXRlIHRoaXMucm9vdC5jaGlsZHJlblt0aGlzLmlkXTtcbiAgICBpZiAodGhpcy5wYXJlbnQpIHtcbiAgICAgIGRlbGV0ZSB0aGlzLnJvb3QuY2hpbGRyZW5bdGhpcy5wYXJlbnQuaWRdW3RoaXMuaWRdO1xuICAgIH1cbiAgICBjbGVhclRpbWVvdXQodGhpcy5sb2FkZXJUaW1lcik7XG4gICAgY29uc3Qgb25GaW5pc2hlZCA9ICgpID0+IHtcbiAgICAgIGNhbGxiYWNrKCk7XG4gICAgICBmb3IgKGNvbnN0IGlkIGluIHRoaXMudmlld0hvb2tzKSB7XG4gICAgICAgIHRoaXMuZGVzdHJveUhvb2sodGhpcy52aWV3SG9va3NbaWRdKTtcbiAgICAgIH1cbiAgICB9O1xuXG4gICAgRE9NLm1hcmtQaHhDaGlsZERlc3Ryb3llZCh0aGlzLmVsKTtcblxuICAgIHRoaXMubG9nKFwiZGVzdHJveWVkXCIsICgpID0+IFtcInRoZSBjaGlsZCBoYXMgYmVlbiByZW1vdmVkIGZyb20gdGhlIHBhcmVudFwiXSk7XG4gICAgdGhpcy5jaGFubmVsXG4gICAgICAubGVhdmUoKVxuICAgICAgLnJlY2VpdmUoXCJva1wiLCBvbkZpbmlzaGVkKVxuICAgICAgLnJlY2VpdmUoXCJlcnJvclwiLCBvbkZpbmlzaGVkKVxuICAgICAgLnJlY2VpdmUoXCJ0aW1lb3V0XCIsIG9uRmluaXNoZWQpO1xuICB9XG5cbiAgc2V0Q29udGFpbmVyQ2xhc3NlcyguLi5jbGFzc2VzKSB7XG4gICAgdGhpcy5lbC5jbGFzc0xpc3QucmVtb3ZlKFxuICAgICAgUEhYX0NPTk5FQ1RFRF9DTEFTUyxcbiAgICAgIFBIWF9MT0FESU5HX0NMQVNTLFxuICAgICAgUEhYX0VSUk9SX0NMQVNTLFxuICAgICAgUEhYX0NMSUVOVF9FUlJPUl9DTEFTUyxcbiAgICAgIFBIWF9TRVJWRVJfRVJST1JfQ0xBU1MsXG4gICAgKTtcbiAgICB0aGlzLmVsLmNsYXNzTGlzdC5hZGQoLi4uY2xhc3Nlcyk7XG4gIH1cblxuICBzaG93TG9hZGVyKHRpbWVvdXQpIHtcbiAgICBjbGVhclRpbWVvdXQodGhpcy5sb2FkZXJUaW1lcik7XG4gICAgaWYgKHRpbWVvdXQpIHtcbiAgICAgIHRoaXMubG9hZGVyVGltZXIgPSBzZXRUaW1lb3V0KCgpID0+IHRoaXMuc2hvd0xvYWRlcigpLCB0aW1lb3V0KTtcbiAgICB9IGVsc2Uge1xuICAgICAgZm9yIChjb25zdCBpZCBpbiB0aGlzLnZpZXdIb29rcykge1xuICAgICAgICB0aGlzLnZpZXdIb29rc1tpZF0uX19kaXNjb25uZWN0ZWQoKTtcbiAgICAgIH1cbiAgICAgIHRoaXMuc2V0Q29udGFpbmVyQ2xhc3NlcyhQSFhfTE9BRElOR19DTEFTUyk7XG4gICAgfVxuICB9XG5cbiAgZXhlY0FsbChiaW5kaW5nKSB7XG4gICAgRE9NLmFsbCh0aGlzLmVsLCBgWyR7YmluZGluZ31dYCwgKGVsKSA9PlxuICAgICAgdGhpcy5saXZlU29ja2V0LmV4ZWNKUyhlbCwgZWwuZ2V0QXR0cmlidXRlKGJpbmRpbmcpKSxcbiAgICApO1xuICB9XG5cbiAgaGlkZUxvYWRlcigpIHtcbiAgICBjbGVhclRpbWVvdXQodGhpcy5sb2FkZXJUaW1lcik7XG4gICAgY2xlYXJUaW1lb3V0KHRoaXMuZGlzY29ubmVjdGVkVGltZXIpO1xuICAgIHRoaXMuc2V0Q29udGFpbmVyQ2xhc3NlcyhQSFhfQ09OTkVDVEVEX0NMQVNTKTtcbiAgICB0aGlzLmV4ZWNBbGwodGhpcy5iaW5kaW5nKFwiY29ubmVjdGVkXCIpKTtcbiAgfVxuXG4gIHRyaWdnZXJSZWNvbm5lY3RlZCgpIHtcbiAgICBmb3IgKGNvbnN0IGlkIGluIHRoaXMudmlld0hvb2tzKSB7XG4gICAgICB0aGlzLnZpZXdIb29rc1tpZF0uX19yZWNvbm5lY3RlZCgpO1xuICAgIH1cbiAgfVxuXG4gIGxvZyhraW5kLCBtc2dDYWxsYmFjaykge1xuICAgIHRoaXMubGl2ZVNvY2tldC5sb2codGhpcywga2luZCwgbXNnQ2FsbGJhY2spO1xuICB9XG5cbiAgdHJhbnNpdGlvbih0aW1lLCBvblN0YXJ0LCBvbkRvbmUgPSBmdW5jdGlvbiAoKSB7fSkge1xuICAgIHRoaXMubGl2ZVNvY2tldC50cmFuc2l0aW9uKHRpbWUsIG9uU3RhcnQsIG9uRG9uZSk7XG4gIH1cblxuICAvLyBjYWxscyB0aGUgY2FsbGJhY2sgd2l0aCB0aGUgdmlldyBhbmQgdGFyZ2V0IGVsZW1lbnQgZm9yIHRoZSBnaXZlbiBwaHhUYXJnZXRcbiAgLy8gdGFyZ2V0cyBjYW4gYmU6XG4gIC8vICAqIGFuIGVsZW1lbnQgaXRzZWxmLCB0aGVuIGl0IGlzIHNpbXBseSBwYXNzZWQgdG8gbGl2ZVNvY2tldC5vd25lcjtcbiAgLy8gICogYSBDSUQgKENvbXBvbmVudCBJRCksIHRoZW4gd2UgZmlyc3Qgc2VhcmNoIHRoZSBjb21wb25lbnQncyBlbGVtZW50IGluIHRoZSBET01cbiAgLy8gICogYSBzZWxlY3RvciwgdGhlbiB3ZSBzZWFyY2ggdGhlIHNlbGVjdG9yIGluIHRoZSBET00gYW5kIGNhbGwgdGhlIGNhbGxiYWNrXG4gIC8vICAgIGZvciBlYWNoIGVsZW1lbnQgZm91bmQgd2l0aCB0aGUgY29ycmVzcG9uZGluZyBvd25lciB2aWV3XG4gIHdpdGhpblRhcmdldHMocGh4VGFyZ2V0LCBjYWxsYmFjaywgZG9tID0gZG9jdW1lbnQpIHtcbiAgICAvLyBpbiB0aGUgZm9ybSByZWNvdmVyeSBjYXNlIHdlIHNlYXJjaCBpbiBhIHRlbXBsYXRlIGZyYWdtZW50IGluc3RlYWQgb2ZcbiAgICAvLyB0aGUgcmVhbCBkb20sIHRoZXJlZm9yZSB3ZSBvcHRpb25hbGx5IHBhc3MgZG9tIGFuZCB2aWV3RWxcblxuICAgIGlmIChwaHhUYXJnZXQgaW5zdGFuY2VvZiBIVE1MRWxlbWVudCB8fCBwaHhUYXJnZXQgaW5zdGFuY2VvZiBTVkdFbGVtZW50KSB7XG4gICAgICByZXR1cm4gdGhpcy5saXZlU29ja2V0Lm93bmVyKHBoeFRhcmdldCwgKHZpZXcpID0+XG4gICAgICAgIGNhbGxiYWNrKHZpZXcsIHBoeFRhcmdldCksXG4gICAgICApO1xuICAgIH1cblxuICAgIGlmIChpc0NpZChwaHhUYXJnZXQpKSB7XG4gICAgICBjb25zdCB0YXJnZXRzID0gRE9NLmZpbmRDb21wb25lbnROb2RlTGlzdCh0aGlzLmlkLCBwaHhUYXJnZXQsIGRvbSk7XG4gICAgICBpZiAodGFyZ2V0cy5sZW5ndGggPT09IDApIHtcbiAgICAgICAgbG9nRXJyb3IoYG5vIGNvbXBvbmVudCBmb3VuZCBtYXRjaGluZyBwaHgtdGFyZ2V0IG9mICR7cGh4VGFyZ2V0fWApO1xuICAgICAgfSBlbHNlIHtcbiAgICAgICAgY2FsbGJhY2sodGhpcywgcGFyc2VJbnQocGh4VGFyZ2V0KSk7XG4gICAgICB9XG4gICAgfSBlbHNlIHtcbiAgICAgIGNvbnN0IHRhcmdldHMgPSBBcnJheS5mcm9tKGRvbS5xdWVyeVNlbGVjdG9yQWxsKHBoeFRhcmdldCkpO1xuICAgICAgaWYgKHRhcmdldHMubGVuZ3RoID09PSAwKSB7XG4gICAgICAgIGxvZ0Vycm9yKFxuICAgICAgICAgIGBub3RoaW5nIGZvdW5kIG1hdGNoaW5nIHRoZSBwaHgtdGFyZ2V0IHNlbGVjdG9yIFwiJHtwaHhUYXJnZXR9XCJgLFxuICAgICAgICApO1xuICAgICAgfVxuICAgICAgdGFyZ2V0cy5mb3JFYWNoKCh0YXJnZXQpID0+XG4gICAgICAgIHRoaXMubGl2ZVNvY2tldC5vd25lcih0YXJnZXQsICh2aWV3KSA9PiBjYWxsYmFjayh2aWV3LCB0YXJnZXQpKSxcbiAgICAgICk7XG4gICAgfVxuICB9XG5cbiAgYXBwbHlEaWZmKHR5cGUsIHJhd0RpZmYsIGNhbGxiYWNrKSB7XG4gICAgdGhpcy5sb2codHlwZSwgKCkgPT4gW1wiXCIsIGNsb25lKHJhd0RpZmYpXSk7XG4gICAgY29uc3QgeyBkaWZmLCByZXBseSwgZXZlbnRzLCB0aXRsZSB9ID0gUmVuZGVyZWQuZXh0cmFjdChyYXdEaWZmKTtcbiAgICBjYWxsYmFjayh7IGRpZmYsIHJlcGx5LCBldmVudHMgfSk7XG4gICAgaWYgKHR5cGVvZiB0aXRsZSA9PT0gXCJzdHJpbmdcIiB8fCB0eXBlID09IFwibW91bnRcIikge1xuICAgICAgd2luZG93LnJlcXVlc3RBbmltYXRpb25GcmFtZSgoKSA9PiBET00ucHV0VGl0bGUodGl0bGUpKTtcbiAgICB9XG4gIH1cblxuICBvbkpvaW4ocmVzcCkge1xuICAgIGNvbnN0IHsgcmVuZGVyZWQsIGNvbnRhaW5lciwgbGl2ZXZpZXdfdmVyc2lvbiwgcGlkIH0gPSByZXNwO1xuICAgIGlmIChjb250YWluZXIpIHtcbiAgICAgIGNvbnN0IFt0YWcsIGF0dHJzXSA9IGNvbnRhaW5lcjtcbiAgICAgIHRoaXMuZWwgPSBET00ucmVwbGFjZVJvb3RDb250YWluZXIodGhpcy5lbCwgdGFnLCBhdHRycyk7XG4gICAgfVxuICAgIHRoaXMuY2hpbGRKb2lucyA9IDA7XG4gICAgdGhpcy5qb2luUGVuZGluZyA9IHRydWU7XG4gICAgdGhpcy5mbGFzaCA9IG51bGw7XG4gICAgaWYgKHRoaXMucm9vdCA9PT0gdGhpcykge1xuICAgICAgdGhpcy5mb3Jtc0ZvclJlY292ZXJ5ID0gdGhpcy5nZXRGb3Jtc0ZvclJlY292ZXJ5KCk7XG4gICAgfVxuICAgIGlmICh0aGlzLmlzTWFpbigpICYmIHdpbmRvdy5oaXN0b3J5LnN0YXRlID09PSBudWxsKSB7XG4gICAgICAvLyBzZXQgaW5pdGlhbCBoaXN0b3J5IGVudHJ5IGlmIHRoaXMgaXMgdGhlIGZpcnN0IHBhZ2UgbG9hZCAobm8gaGlzdG9yeSlcbiAgICAgIEJyb3dzZXIucHVzaFN0YXRlKFwicmVwbGFjZVwiLCB7XG4gICAgICAgIHR5cGU6IFwicGF0Y2hcIixcbiAgICAgICAgaWQ6IHRoaXMuaWQsXG4gICAgICAgIHBvc2l0aW9uOiB0aGlzLmxpdmVTb2NrZXQuY3VycmVudEhpc3RvcnlQb3NpdGlvbixcbiAgICAgIH0pO1xuICAgIH1cblxuICAgIGlmIChsaXZldmlld192ZXJzaW9uICE9PSB0aGlzLmxpdmVTb2NrZXQudmVyc2lvbigpKSB7XG4gICAgICBjb25zb2xlLmVycm9yKFxuICAgICAgICBgTGl2ZVZpZXcgYXNzZXQgdmVyc2lvbiBtaXNtYXRjaC4gSmF2YVNjcmlwdCB2ZXJzaW9uICR7dGhpcy5saXZlU29ja2V0LnZlcnNpb24oKX0gdnMuIHNlcnZlciAke2xpdmV2aWV3X3ZlcnNpb259LiBUbyBhdm9pZCBpc3N1ZXMsIHBsZWFzZSBlbnN1cmUgdGhhdCB5b3VyIGFzc2V0cyB1c2UgdGhlIHNhbWUgdmVyc2lvbiBhcyB0aGUgc2VydmVyLmAsXG4gICAgICApO1xuICAgIH1cblxuICAgIC8vIFRoZSBwaWQgaXMgb25seSBzZW50IGlmXG4gICAgLy9cbiAgICAvLyAgICBjb25maWcgOnBob2VuaXhfbGl2ZV92aWV3LCA6ZGVidWdfYXR0cmlidXRlc1xuICAgIC8vXG4gICAgLy8gaWYgc2V0IHRvIHRydWUuIEl0IGlzIHRvIGhlbHAgZGVidWdnaW5nIGluIGRldmVsb3BtZW50LlxuICAgIGlmIChwaWQpIHtcbiAgICAgIHRoaXMuZWwuc2V0QXR0cmlidXRlKFBIWF9MVl9QSUQsIHBpZCk7XG4gICAgfVxuXG4gICAgQnJvd3Nlci5kcm9wTG9jYWwoXG4gICAgICB0aGlzLmxpdmVTb2NrZXQubG9jYWxTdG9yYWdlLFxuICAgICAgd2luZG93LmxvY2F0aW9uLnBhdGhuYW1lLFxuICAgICAgQ09OU0VDVVRJVkVfUkVMT0FEUyxcbiAgICApO1xuICAgIHRoaXMuYXBwbHlEaWZmKFwibW91bnRcIiwgcmVuZGVyZWQsICh7IGRpZmYsIGV2ZW50cyB9KSA9PiB7XG4gICAgICB0aGlzLnJlbmRlcmVkID0gbmV3IFJlbmRlcmVkKHRoaXMuaWQsIGRpZmYpO1xuICAgICAgY29uc3QgW2h0bWwsIHN0cmVhbXNdID0gdGhpcy5yZW5kZXJDb250YWluZXIobnVsbCwgXCJqb2luXCIpO1xuICAgICAgdGhpcy5kcm9wUGVuZGluZ1JlZnMoKTtcbiAgICAgIHRoaXMuam9pbkNvdW50Kys7XG4gICAgICB0aGlzLmpvaW5BdHRlbXB0cyA9IDA7XG5cbiAgICAgIHRoaXMubWF5YmVSZWNvdmVyRm9ybXMoaHRtbCwgKCkgPT4ge1xuICAgICAgICB0aGlzLm9uSm9pbkNvbXBsZXRlKHJlc3AsIGh0bWwsIHN0cmVhbXMsIGV2ZW50cyk7XG4gICAgICB9KTtcbiAgICB9KTtcbiAgfVxuXG4gIGRyb3BQZW5kaW5nUmVmcygpIHtcbiAgICBET00uYWxsKGRvY3VtZW50LCBgWyR7UEhYX1JFRl9TUkN9PVwiJHt0aGlzLnJlZlNyYygpfVwiXWAsIChlbCkgPT4ge1xuICAgICAgZWwucmVtb3ZlQXR0cmlidXRlKFBIWF9SRUZfTE9BRElORyk7XG4gICAgICBlbC5yZW1vdmVBdHRyaWJ1dGUoUEhYX1JFRl9TUkMpO1xuICAgICAgZWwucmVtb3ZlQXR0cmlidXRlKFBIWF9SRUZfTE9DSyk7XG4gICAgfSk7XG4gIH1cblxuICBvbkpvaW5Db21wbGV0ZSh7IGxpdmVfcGF0Y2ggfSwgaHRtbCwgc3RyZWFtcywgZXZlbnRzKSB7XG4gICAgLy8gSW4gb3JkZXIgdG8gcHJvdmlkZSBhIGJldHRlciBleHBlcmllbmNlLCB3ZSB3YW50IHRvIGpvaW5cbiAgICAvLyBhbGwgTGl2ZVZpZXdzIGZpcnN0IGFuZCBvbmx5IHRoZW4gYXBwbHkgdGhlaXIgcGF0Y2hlcy5cbiAgICBpZiAodGhpcy5qb2luQ291bnQgPiAxIHx8ICh0aGlzLnBhcmVudCAmJiAhdGhpcy5wYXJlbnQuaXNKb2luUGVuZGluZygpKSkge1xuICAgICAgcmV0dXJuIHRoaXMuYXBwbHlKb2luUGF0Y2gobGl2ZV9wYXRjaCwgaHRtbCwgc3RyZWFtcywgZXZlbnRzKTtcbiAgICB9XG5cbiAgICAvLyBPbmUgZG93bnNpZGUgb2YgdGhpcyBhcHByb2FjaCBpcyB0aGF0IHdlIG5lZWQgdG8gZmluZCBwaHhDaGlsZHJlblxuICAgIC8vIGluIHRoZSBodG1sIGZyYWdtZW50LCBpbnN0ZWFkIG9mIGRpcmVjdGx5IG9uIHRoZSBET00uIFRoZSBmcmFnbWVudFxuICAgIC8vIGFsc28gZG9lcyBub3QgaW5jbHVkZSBQSFhfU1RBVElDLCBzbyB3ZSBuZWVkIHRvIGNvcHkgaXQgb3ZlciBmcm9tXG4gICAgLy8gdGhlIERPTS5cbiAgICBjb25zdCBuZXdDaGlsZHJlbiA9IERPTS5maW5kUGh4Q2hpbGRyZW5JbkZyYWdtZW50KGh0bWwsIHRoaXMuaWQpLmZpbHRlcihcbiAgICAgICh0b0VsKSA9PiB7XG4gICAgICAgIGNvbnN0IGZyb21FbCA9IHRvRWwuaWQgJiYgdGhpcy5lbC5xdWVyeVNlbGVjdG9yKGBbaWQ9XCIke3RvRWwuaWR9XCJdYCk7XG4gICAgICAgIGNvbnN0IHBoeFN0YXRpYyA9IGZyb21FbCAmJiBmcm9tRWwuZ2V0QXR0cmlidXRlKFBIWF9TVEFUSUMpO1xuICAgICAgICBpZiAocGh4U3RhdGljKSB7XG4gICAgICAgICAgdG9FbC5zZXRBdHRyaWJ1dGUoUEhYX1NUQVRJQywgcGh4U3RhdGljKTtcbiAgICAgICAgfVxuICAgICAgICAvLyBzZXQgUEhYX1JPT1RfSUQgdG8gcHJldmVudCBldmVudHMgZnJvbSBiZWluZyBkaXNwYXRjaGVkIHRvIHRoZSByb290IHZpZXdcbiAgICAgICAgLy8gd2hpbGUgdGhlIGNoaWxkIGpvaW4gaXMgc3RpbGwgcGVuZGluZ1xuICAgICAgICBpZiAoZnJvbUVsKSB7XG4gICAgICAgICAgZnJvbUVsLnNldEF0dHJpYnV0ZShQSFhfUk9PVF9JRCwgdGhpcy5yb290LmlkKTtcbiAgICAgICAgfVxuICAgICAgICByZXR1cm4gdGhpcy5qb2luQ2hpbGQodG9FbCk7XG4gICAgICB9LFxuICAgICk7XG5cbiAgICBpZiAobmV3Q2hpbGRyZW4ubGVuZ3RoID09PSAwKSB7XG4gICAgICBpZiAodGhpcy5wYXJlbnQpIHtcbiAgICAgICAgdGhpcy5yb290LnBlbmRpbmdKb2luT3BzLnB1c2goW1xuICAgICAgICAgIHRoaXMsXG4gICAgICAgICAgKCkgPT4gdGhpcy5hcHBseUpvaW5QYXRjaChsaXZlX3BhdGNoLCBodG1sLCBzdHJlYW1zLCBldmVudHMpLFxuICAgICAgICBdKTtcbiAgICAgICAgdGhpcy5wYXJlbnQuYWNrSm9pbih0aGlzKTtcbiAgICAgIH0gZWxzZSB7XG4gICAgICAgIHRoaXMub25BbGxDaGlsZEpvaW5zQ29tcGxldGUoKTtcbiAgICAgICAgdGhpcy5hcHBseUpvaW5QYXRjaChsaXZlX3BhdGNoLCBodG1sLCBzdHJlYW1zLCBldmVudHMpO1xuICAgICAgfVxuICAgIH0gZWxzZSB7XG4gICAgICB0aGlzLnJvb3QucGVuZGluZ0pvaW5PcHMucHVzaChbXG4gICAgICAgIHRoaXMsXG4gICAgICAgICgpID0+IHRoaXMuYXBwbHlKb2luUGF0Y2gobGl2ZV9wYXRjaCwgaHRtbCwgc3RyZWFtcywgZXZlbnRzKSxcbiAgICAgIF0pO1xuICAgIH1cbiAgfVxuXG4gIGF0dGFjaFRydWVEb2NFbCgpIHtcbiAgICB0aGlzLmVsID0gRE9NLmJ5SWQodGhpcy5pZCk7XG4gICAgdGhpcy5lbC5zZXRBdHRyaWJ1dGUoUEhYX1JPT1RfSUQsIHRoaXMucm9vdC5pZCk7XG4gIH1cblxuICAvLyB0aGlzIGlzIGludm9rZWQgZm9yIGRlYWQgYW5kIGxpdmUgdmlld3MsIHNvIHdlIG11c3QgZmlsdGVyIGJ5XG4gIC8vIGJ5IG93bmVyIHRvIGVuc3VyZSB3ZSBhcmVuJ3QgZHVwbGljYXRpbmcgaG9va3MgYWNyb3NzIGRpc2Nvbm5lY3RcbiAgLy8gYW5kIGNvbm5lY3RlZCBzdGF0ZXMuIFRoaXMgYWxzbyBoYW5kbGVzIGNhc2VzIHdoZXJlIGhvb2tzIGV4aXN0XG4gIC8vIGluIGEgcm9vdCBsYXlvdXQgd2l0aCBhIExWIGluIHRoZSBib2R5XG4gIGV4ZWNOZXdNb3VudGVkKHBhcmVudCA9IGRvY3VtZW50KSB7XG4gICAgbGV0IHBoeFZpZXdwb3J0VG9wID0gdGhpcy5iaW5kaW5nKFBIWF9WSUVXUE9SVF9UT1ApO1xuICAgIGxldCBwaHhWaWV3cG9ydEJvdHRvbSA9IHRoaXMuYmluZGluZyhQSFhfVklFV1BPUlRfQk9UVE9NKTtcbiAgICB0aGlzLmFsbChcbiAgICAgIHBhcmVudCxcbiAgICAgIGBbJHtwaHhWaWV3cG9ydFRvcH1dLCBbJHtwaHhWaWV3cG9ydEJvdHRvbX1dYCxcbiAgICAgIChob29rRWwpID0+IHtcbiAgICAgICAgRE9NLm1haW50YWluUHJpdmF0ZUhvb2tzKFxuICAgICAgICAgIGhvb2tFbCxcbiAgICAgICAgICBob29rRWwsXG4gICAgICAgICAgcGh4Vmlld3BvcnRUb3AsXG4gICAgICAgICAgcGh4Vmlld3BvcnRCb3R0b20sXG4gICAgICAgICk7XG4gICAgICAgIHRoaXMubWF5YmVBZGROZXdIb29rKGhvb2tFbCk7XG4gICAgICB9LFxuICAgICk7XG4gICAgdGhpcy5hbGwoXG4gICAgICBwYXJlbnQsXG4gICAgICBgWyR7dGhpcy5iaW5kaW5nKFBIWF9IT09LKX1dLCBbZGF0YS1waHgtJHtQSFhfSE9PS31dYCxcbiAgICAgIChob29rRWwpID0+IHtcbiAgICAgICAgdGhpcy5tYXliZUFkZE5ld0hvb2soaG9va0VsKTtcbiAgICAgIH0sXG4gICAgKTtcbiAgICB0aGlzLmFsbChwYXJlbnQsIGBbJHt0aGlzLmJpbmRpbmcoUEhYX01PVU5URUQpfV1gLCAoZWwpID0+IHtcbiAgICAgIHRoaXMubWF5YmVNb3VudGVkKGVsKTtcbiAgICB9KTtcbiAgfVxuXG4gIGFsbChwYXJlbnQsIHNlbGVjdG9yLCBjYWxsYmFjaykge1xuICAgIERPTS5hbGwocGFyZW50LCBzZWxlY3RvciwgKGVsKSA9PiB7XG4gICAgICBpZiAodGhpcy5vd25zRWxlbWVudChlbCkpIHtcbiAgICAgICAgY2FsbGJhY2soZWwpO1xuICAgICAgfVxuICAgIH0pO1xuICB9XG5cbiAgYXBwbHlKb2luUGF0Y2gobGl2ZV9wYXRjaCwgaHRtbCwgc3RyZWFtcywgZXZlbnRzKSB7XG4gICAgdGhpcy5hdHRhY2hUcnVlRG9jRWwoKTtcbiAgICBjb25zdCBwYXRjaCA9IG5ldyBET01QYXRjaCh0aGlzLCB0aGlzLmVsLCB0aGlzLmlkLCBodG1sLCBzdHJlYW1zLCBudWxsKTtcbiAgICBwYXRjaC5tYXJrUHJ1bmFibGVDb250ZW50Rm9yUmVtb3ZhbCgpO1xuICAgIHRoaXMucGVyZm9ybVBhdGNoKHBhdGNoLCBmYWxzZSwgdHJ1ZSk7XG4gICAgdGhpcy5qb2luTmV3Q2hpbGRyZW4oKTtcbiAgICB0aGlzLmV4ZWNOZXdNb3VudGVkKCk7XG5cbiAgICB0aGlzLmpvaW5QZW5kaW5nID0gZmFsc2U7XG4gICAgdGhpcy5saXZlU29ja2V0LmRpc3BhdGNoRXZlbnRzKGV2ZW50cyk7XG4gICAgdGhpcy5hcHBseVBlbmRpbmdVcGRhdGVzKCk7XG5cbiAgICBpZiAobGl2ZV9wYXRjaCkge1xuICAgICAgY29uc3QgeyBraW5kLCB0byB9ID0gbGl2ZV9wYXRjaDtcbiAgICAgIHRoaXMubGl2ZVNvY2tldC5oaXN0b3J5UGF0Y2godG8sIGtpbmQpO1xuICAgIH1cbiAgICB0aGlzLmhpZGVMb2FkZXIoKTtcbiAgICBpZiAodGhpcy5qb2luQ291bnQgPiAxKSB7XG4gICAgICB0aGlzLnRyaWdnZXJSZWNvbm5lY3RlZCgpO1xuICAgIH1cbiAgICB0aGlzLnN0b3BDYWxsYmFjaygpO1xuICB9XG5cbiAgdHJpZ2dlckJlZm9yZVVwZGF0ZUhvb2soZnJvbUVsLCB0b0VsKSB7XG4gICAgdGhpcy5saXZlU29ja2V0LnRyaWdnZXJET00oXCJvbkJlZm9yZUVsVXBkYXRlZFwiLCBbZnJvbUVsLCB0b0VsXSk7XG4gICAgY29uc3QgaG9vayA9IHRoaXMuZ2V0SG9vayhmcm9tRWwpO1xuICAgIGNvbnN0IGlzSWdub3JlZCA9IGhvb2sgJiYgRE9NLmlzSWdub3JlZChmcm9tRWwsIHRoaXMuYmluZGluZyhQSFhfVVBEQVRFKSk7XG4gICAgaWYgKFxuICAgICAgaG9vayAmJlxuICAgICAgIWZyb21FbC5pc0VxdWFsTm9kZSh0b0VsKSAmJlxuICAgICAgIShpc0lnbm9yZWQgJiYgaXNFcXVhbE9iaihmcm9tRWwuZGF0YXNldCwgdG9FbC5kYXRhc2V0KSlcbiAgICApIHtcbiAgICAgIGhvb2suX19iZWZvcmVVcGRhdGUoKTtcbiAgICAgIHJldHVybiBob29rO1xuICAgIH1cbiAgfVxuXG4gIG1heWJlTW91bnRlZChlbCkge1xuICAgIGNvbnN0IHBoeE1vdW50ZWQgPSBlbC5nZXRBdHRyaWJ1dGUodGhpcy5iaW5kaW5nKFBIWF9NT1VOVEVEKSk7XG4gICAgY29uc3QgaGFzQmVlbkludm9rZWQgPSBwaHhNb3VudGVkICYmIERPTS5wcml2YXRlKGVsLCBcIm1vdW50ZWRcIik7XG4gICAgaWYgKHBoeE1vdW50ZWQgJiYgIWhhc0JlZW5JbnZva2VkKSB7XG4gICAgICB0aGlzLmxpdmVTb2NrZXQuZXhlY0pTKGVsLCBwaHhNb3VudGVkKTtcbiAgICAgIERPTS5wdXRQcml2YXRlKGVsLCBcIm1vdW50ZWRcIiwgdHJ1ZSk7XG4gICAgfVxuICB9XG5cbiAgbWF5YmVBZGROZXdIb29rKGVsKSB7XG4gICAgY29uc3QgbmV3SG9vayA9IHRoaXMuYWRkSG9vayhlbCk7XG4gICAgaWYgKG5ld0hvb2spIHtcbiAgICAgIG5ld0hvb2suX19tb3VudGVkKCk7XG4gICAgfVxuICB9XG5cbiAgcGVyZm9ybVBhdGNoKHBhdGNoLCBwcnVuZUNpZHMsIGlzSm9pblBhdGNoID0gZmFsc2UpIHtcbiAgICBjb25zdCByZW1vdmVkRWxzID0gW107XG4gICAgbGV0IHBoeENoaWxkcmVuQWRkZWQgPSBmYWxzZTtcbiAgICBjb25zdCB1cGRhdGVkSG9va0lkcyA9IG5ldyBTZXQoKTtcblxuICAgIHRoaXMubGl2ZVNvY2tldC50cmlnZ2VyRE9NKFwib25QYXRjaFN0YXJ0XCIsIFtwYXRjaC50YXJnZXRDb250YWluZXJdKTtcblxuICAgIHBhdGNoLmFmdGVyKFwiYWRkZWRcIiwgKGVsKSA9PiB7XG4gICAgICB0aGlzLmxpdmVTb2NrZXQudHJpZ2dlckRPTShcIm9uTm9kZUFkZGVkXCIsIFtlbF0pO1xuICAgICAgY29uc3QgcGh4Vmlld3BvcnRUb3AgPSB0aGlzLmJpbmRpbmcoUEhYX1ZJRVdQT1JUX1RPUCk7XG4gICAgICBjb25zdCBwaHhWaWV3cG9ydEJvdHRvbSA9IHRoaXMuYmluZGluZyhQSFhfVklFV1BPUlRfQk9UVE9NKTtcbiAgICAgIERPTS5tYWludGFpblByaXZhdGVIb29rcyhlbCwgZWwsIHBoeFZpZXdwb3J0VG9wLCBwaHhWaWV3cG9ydEJvdHRvbSk7XG4gICAgICB0aGlzLm1heWJlQWRkTmV3SG9vayhlbCk7XG4gICAgICBpZiAoZWwuZ2V0QXR0cmlidXRlKSB7XG4gICAgICAgIHRoaXMubWF5YmVNb3VudGVkKGVsKTtcbiAgICAgIH1cbiAgICB9KTtcblxuICAgIHBhdGNoLmFmdGVyKFwicGh4Q2hpbGRBZGRlZFwiLCAoZWwpID0+IHtcbiAgICAgIGlmIChET00uaXNQaHhTdGlja3koZWwpKSB7XG4gICAgICAgIHRoaXMubGl2ZVNvY2tldC5qb2luUm9vdFZpZXdzKCk7XG4gICAgICB9IGVsc2Uge1xuICAgICAgICBwaHhDaGlsZHJlbkFkZGVkID0gdHJ1ZTtcbiAgICAgIH1cbiAgICB9KTtcblxuICAgIHBhdGNoLmJlZm9yZShcInVwZGF0ZWRcIiwgKGZyb21FbCwgdG9FbCkgPT4ge1xuICAgICAgY29uc3QgaG9vayA9IHRoaXMudHJpZ2dlckJlZm9yZVVwZGF0ZUhvb2soZnJvbUVsLCB0b0VsKTtcbiAgICAgIGlmIChob29rKSB7XG4gICAgICAgIHVwZGF0ZWRIb29rSWRzLmFkZChmcm9tRWwuaWQpO1xuICAgICAgfVxuICAgICAgLy8gdHJpZ2dlciBKUyBzcGVjaWZpYyB1cGRhdGUgbG9naWMgKGZvciBleGFtcGxlIGZvciBKUy5pZ25vcmVfYXR0cmlidXRlcylcbiAgICAgIEpTLm9uQmVmb3JlRWxVcGRhdGVkKGZyb21FbCwgdG9FbCk7XG4gICAgfSk7XG5cbiAgICBwYXRjaC5hZnRlcihcInVwZGF0ZWRcIiwgKGVsKSA9PiB7XG4gICAgICBpZiAodXBkYXRlZEhvb2tJZHMuaGFzKGVsLmlkKSkge1xuICAgICAgICB0aGlzLmdldEhvb2soZWwpLl9fdXBkYXRlZCgpO1xuICAgICAgfVxuICAgIH0pO1xuXG4gICAgcGF0Y2guYWZ0ZXIoXCJkaXNjYXJkZWRcIiwgKGVsKSA9PiB7XG4gICAgICBpZiAoZWwubm9kZVR5cGUgPT09IE5vZGUuRUxFTUVOVF9OT0RFKSB7XG4gICAgICAgIHJlbW92ZWRFbHMucHVzaChlbCk7XG4gICAgICB9XG4gICAgfSk7XG5cbiAgICBwYXRjaC5hZnRlcihcInRyYW5zaXRpb25zRGlzY2FyZGVkXCIsIChlbHMpID0+XG4gICAgICB0aGlzLmFmdGVyRWxlbWVudHNSZW1vdmVkKGVscywgcHJ1bmVDaWRzKSxcbiAgICApO1xuICAgIHBhdGNoLnBlcmZvcm0oaXNKb2luUGF0Y2gpO1xuICAgIHRoaXMuYWZ0ZXJFbGVtZW50c1JlbW92ZWQocmVtb3ZlZEVscywgcHJ1bmVDaWRzKTtcblxuICAgIHRoaXMubGl2ZVNvY2tldC50cmlnZ2VyRE9NKFwib25QYXRjaEVuZFwiLCBbcGF0Y2gudGFyZ2V0Q29udGFpbmVyXSk7XG4gICAgcmV0dXJuIHBoeENoaWxkcmVuQWRkZWQ7XG4gIH1cblxuICBhZnRlckVsZW1lbnRzUmVtb3ZlZChlbGVtZW50cywgcHJ1bmVDaWRzKSB7XG4gICAgY29uc3QgZGVzdHJveWVkQ0lEcyA9IFtdO1xuICAgIGVsZW1lbnRzLmZvckVhY2goKHBhcmVudCkgPT4ge1xuICAgICAgY29uc3QgY29tcG9uZW50cyA9IERPTS5hbGwoXG4gICAgICAgIHBhcmVudCxcbiAgICAgICAgYFske1BIWF9WSUVXX1JFRn09XCIke3RoaXMuaWR9XCJdWyR7UEhYX0NPTVBPTkVOVH1dYCxcbiAgICAgICk7XG4gICAgICBjb25zdCBob29rcyA9IERPTS5hbGwoXG4gICAgICAgIHBhcmVudCxcbiAgICAgICAgYFske3RoaXMuYmluZGluZyhQSFhfSE9PSyl9XSwgW2RhdGEtcGh4LWhvb2tdYCxcbiAgICAgICk7XG4gICAgICBjb21wb25lbnRzLmNvbmNhdChwYXJlbnQpLmZvckVhY2goKGVsKSA9PiB7XG4gICAgICAgIGNvbnN0IGNpZCA9IHRoaXMuY29tcG9uZW50SUQoZWwpO1xuICAgICAgICBpZiAoXG4gICAgICAgICAgaXNDaWQoY2lkKSAmJlxuICAgICAgICAgIGRlc3Ryb3llZENJRHMuaW5kZXhPZihjaWQpID09PSAtMSAmJlxuICAgICAgICAgIGVsLmdldEF0dHJpYnV0ZShQSFhfVklFV19SRUYpID09PSB0aGlzLmlkXG4gICAgICAgICkge1xuICAgICAgICAgIGRlc3Ryb3llZENJRHMucHVzaChjaWQpO1xuICAgICAgICB9XG4gICAgICB9KTtcbiAgICAgIGhvb2tzLmNvbmNhdChwYXJlbnQpLmZvckVhY2goKGhvb2tFbCkgPT4ge1xuICAgICAgICBjb25zdCBob29rID0gdGhpcy5nZXRIb29rKGhvb2tFbCk7XG4gICAgICAgIGhvb2sgJiYgdGhpcy5kZXN0cm95SG9vayhob29rKTtcbiAgICAgIH0pO1xuICAgIH0pO1xuICAgIC8vIFdlIHNob3VsZCBub3QgcHJ1bmVDaWRzIG9uIGpvaW5zLiBPdGhlcndpc2UsIGluIGNhc2Ugb2ZcbiAgICAvLyByZWpvaW5zLCB3ZSBtYXkgbm90aWZ5IGNpZHMgdGhhdCBubyBsb25nZXIgYmVsb25nIHRvIHRoZVxuICAgIC8vIGN1cnJlbnQgTGl2ZVZpZXcgdG8gYmUgcmVtb3ZlZC5cbiAgICBpZiAocHJ1bmVDaWRzKSB7XG4gICAgICB0aGlzLm1heWJlUHVzaENvbXBvbmVudHNEZXN0cm95ZWQoZGVzdHJveWVkQ0lEcyk7XG4gICAgfVxuICB9XG5cbiAgam9pbk5ld0NoaWxkcmVuKCkge1xuICAgIERPTS5maW5kUGh4Q2hpbGRyZW4oZG9jdW1lbnQsIHRoaXMuaWQpLmZvckVhY2goKGVsKSA9PiB0aGlzLmpvaW5DaGlsZChlbCkpO1xuICB9XG5cbiAgbWF5YmVSZWNvdmVyRm9ybXMoaHRtbCwgY2FsbGJhY2spIHtcbiAgICBjb25zdCBwaHhDaGFuZ2UgPSB0aGlzLmJpbmRpbmcoXCJjaGFuZ2VcIik7XG4gICAgY29uc3Qgb2xkRm9ybXMgPSB0aGlzLnJvb3QuZm9ybXNGb3JSZWNvdmVyeTtcbiAgICAvLyBTbyB3aHkgZG8gd2UgY3JlYXRlIGEgdGVtcGxhdGUgZWxlbWVudCBoZXJlP1xuICAgIC8vIE9uZSB3YXkgdG8gcmVjb3ZlciBmb3JtcyB3b3VsZCBiZSB0byBpbW1lZGlhdGVseSBhcHBseSB0aGUgbW91bnRcbiAgICAvLyBwYXRjaCBhbmQgdGhlbiBhZnRlcndhcmRzIHJlY292ZXIgdGhlIGZvcm1zLiBIb3dldmVyLCB0aGlzIHdvdWxkXG4gICAgLy8gY2F1c2UgYSBmbGlja2VyLCBiZWNhdXNlIHRoZSBtb3VudCBwYXRjaCB3b3VsZCByZW1vdmUgdGhlIGZvcm0gY29udGVudFxuICAgIC8vIHVudGlsIGl0IGlzIHJlc3RvcmVkLiBUaGVyZWZvcmUgTFYgZGVjaWRlZCB0byBkbyBmb3JtIHJlY292ZXJ5IHdpdGggdGhlXG4gICAgLy8gcmF3IEhUTUwgYmVmb3JlIGl0IGlzIGFwcGxpZWQgYW5kIGRlbGF5IHRoZSBtb3VudCBwYXRjaCB1bnRpbCB0aGUgZm9ybVxuICAgIC8vIHJlY292ZXJ5IGV2ZW50cyBhcmUgZG9uZS5cbiAgICBjb25zdCB0ZW1wbGF0ZSA9IGRvY3VtZW50LmNyZWF0ZUVsZW1lbnQoXCJ0ZW1wbGF0ZVwiKTtcbiAgICB0ZW1wbGF0ZS5pbm5lckhUTUwgPSBodG1sO1xuICAgIC8vIGJlY2F1c2Ugd2Ugd29yayB3aXRoIGEgdGVtcGxhdGUgZWxlbWVudCwgd2UgbXVzdCBtYW51YWxseSBjb3B5IHRoZSBhdHRyaWJ1dGVzXG4gICAgLy8gb3RoZXJ3aXNlIHRoZSBvd25lciAvIHRhcmdldCBoZWxwZXJzIGRvbid0IHdvcmsgcHJvcGVybHlcbiAgICBjb25zdCByb290RWwgPSB0ZW1wbGF0ZS5jb250ZW50LmZpcnN0RWxlbWVudENoaWxkO1xuICAgIHJvb3RFbC5pZCA9IHRoaXMuaWQ7XG4gICAgcm9vdEVsLnNldEF0dHJpYnV0ZShQSFhfUk9PVF9JRCwgdGhpcy5yb290LmlkKTtcbiAgICByb290RWwuc2V0QXR0cmlidXRlKFBIWF9TRVNTSU9OLCB0aGlzLmdldFNlc3Npb24oKSk7XG4gICAgcm9vdEVsLnNldEF0dHJpYnV0ZShQSFhfU1RBVElDLCB0aGlzLmdldFN0YXRpYygpKTtcbiAgICByb290RWwuc2V0QXR0cmlidXRlKFBIWF9QQVJFTlRfSUQsIHRoaXMucGFyZW50ID8gdGhpcy5wYXJlbnQuaWQgOiBudWxsKTtcblxuICAgIC8vIHdlIGdvIG92ZXIgYWxsIGZvcm0gZWxlbWVudHMgaW4gdGhlIG5ldyBIVE1MIGZvciB0aGUgTFZcbiAgICAvLyBhbmQgbG9vayBmb3Igb2xkIGZvcm1zIGluIHRoZSBgZm9ybXNGb3JSZWNvdmVyeWAgb2JqZWN0O1xuICAgIC8vIHRoZSBmb3Jtc0ZvclJlY292ZXJ5IGNhbiBhbHNvIGNvbnRhaW4gZm9ybXMgZnJvbSBjaGlsZCB2aWV3c1xuICAgIGNvbnN0IGZvcm1zVG9SZWNvdmVyID1cbiAgICAgIC8vIHdlIGdvIG92ZXIgYWxsIGZvcm1zIGluIHRoZSBuZXcgRE9NOyBiZWNhdXNlIHRoaXMgaXMgb25seSB0aGUgSFRNTCBmb3IgdGhlIGN1cnJlbnRcbiAgICAgIC8vIHZpZXcsIHdlIGNhbiBiZSBzdXJlIHRoYXQgYWxsIGZvcm1zIGFyZSBvd25lZCBieSB0aGlzIHZpZXc6XG4gICAgICBET00uYWxsKHRlbXBsYXRlLmNvbnRlbnQsIFwiZm9ybVwiKVxuICAgICAgICAvLyBvbmx5IHJlY292ZXIgZm9ybXMgdGhhdCBoYXZlIGFuIGlkIGFuZCBhcmUgaW4gdGhlIG9sZCBET01cbiAgICAgICAgLmZpbHRlcigobmV3Rm9ybSkgPT4gbmV3Rm9ybS5pZCAmJiBvbGRGb3Jtc1tuZXdGb3JtLmlkXSlcbiAgICAgICAgLy8gYWJhbmRvbiBmb3JtcyB3ZSBhbHJlYWR5IHRyaWVkIHRvIHJlY292ZXIgdG8gcHJldmVudCBsb29waW5nIGEgZmFpbGVkIHN0YXRlXG4gICAgICAgIC5maWx0ZXIoKG5ld0Zvcm0pID0+ICF0aGlzLnBlbmRpbmdGb3Jtcy5oYXMobmV3Rm9ybS5pZCkpXG4gICAgICAgIC8vIG9ubHkgcmVjb3ZlciBpZiB0aGUgZm9ybSBoYXMgdGhlIHNhbWUgcGh4LWNoYW5nZSB2YWx1ZVxuICAgICAgICAuZmlsdGVyKFxuICAgICAgICAgIChuZXdGb3JtKSA9PlxuICAgICAgICAgICAgb2xkRm9ybXNbbmV3Rm9ybS5pZF0uZ2V0QXR0cmlidXRlKHBoeENoYW5nZSkgPT09XG4gICAgICAgICAgICBuZXdGb3JtLmdldEF0dHJpYnV0ZShwaHhDaGFuZ2UpLFxuICAgICAgICApXG4gICAgICAgIC5tYXAoKG5ld0Zvcm0pID0+IHtcbiAgICAgICAgICByZXR1cm4gW29sZEZvcm1zW25ld0Zvcm0uaWRdLCBuZXdGb3JtXTtcbiAgICAgICAgfSk7XG5cbiAgICBpZiAoZm9ybXNUb1JlY292ZXIubGVuZ3RoID09PSAwKSB7XG4gICAgICByZXR1cm4gY2FsbGJhY2soKTtcbiAgICB9XG5cbiAgICBmb3Jtc1RvUmVjb3Zlci5mb3JFYWNoKChbb2xkRm9ybSwgbmV3Rm9ybV0sIGkpID0+IHtcbiAgICAgIHRoaXMucGVuZGluZ0Zvcm1zLmFkZChuZXdGb3JtLmlkKTtcbiAgICAgIC8vIGl0IGlzIGltcG9ydGFudCB0byB1c2UgdGhlIGZpcnN0RWxlbWVudENoaWxkIG9mIHRoZSB0ZW1wbGF0ZSBjb250ZW50XG4gICAgICAvLyBiZWNhdXNlIHdoZW4gdHJhdmVyc2luZyBhIGRvY3VtZW50RnJhZ21lbnQgdXNpbmcgcGFyZW50Tm9kZSwgd2Ugd29uJ3QgZXZlciBhcnJpdmUgYXRcbiAgICAgIC8vIHRoZSBmcmFnbWVudDsgYXMgdGhlIHRlbXBsYXRlIGlzIGFsd2F5cyBhIExpdmVWaWV3LCB3ZSBjYW4gYmUgc3VyZSB0aGF0IHRoZXJlIGlzIG9ubHlcbiAgICAgIC8vIG9uZSBjaGlsZCBvbiB0aGUgcm9vdCBsZXZlbFxuICAgICAgdGhpcy5wdXNoRm9ybVJlY292ZXJ5KFxuICAgICAgICBvbGRGb3JtLFxuICAgICAgICBuZXdGb3JtLFxuICAgICAgICB0ZW1wbGF0ZS5jb250ZW50LmZpcnN0RWxlbWVudENoaWxkLFxuICAgICAgICAoKSA9PiB7XG4gICAgICAgICAgdGhpcy5wZW5kaW5nRm9ybXMuZGVsZXRlKG5ld0Zvcm0uaWQpO1xuICAgICAgICAgIC8vIHdlIG9ubHkgY2FsbCB0aGUgY2FsbGJhY2sgb25jZSBhbGwgZm9ybXMgaGF2ZSBiZWVuIHJlY292ZXJlZFxuICAgICAgICAgIGlmIChpID09PSBmb3Jtc1RvUmVjb3Zlci5sZW5ndGggLSAxKSB7XG4gICAgICAgICAgICBjYWxsYmFjaygpO1xuICAgICAgICAgIH1cbiAgICAgICAgfSxcbiAgICAgICk7XG4gICAgfSk7XG4gIH1cblxuICBnZXRDaGlsZEJ5SWQoaWQpIHtcbiAgICByZXR1cm4gdGhpcy5yb290LmNoaWxkcmVuW3RoaXMuaWRdW2lkXTtcbiAgfVxuXG4gIGdldERlc2NlbmRlbnRCeUVsKGVsKSB7XG4gICAgaWYgKGVsLmlkID09PSB0aGlzLmlkKSB7XG4gICAgICByZXR1cm4gdGhpcztcbiAgICB9IGVsc2Uge1xuICAgICAgcmV0dXJuIHRoaXMuY2hpbGRyZW5bZWwuZ2V0QXR0cmlidXRlKFBIWF9QQVJFTlRfSUQpXT8uW2VsLmlkXTtcbiAgICB9XG4gIH1cblxuICBkZXN0cm95RGVzY2VuZGVudChpZCkge1xuICAgIGZvciAoY29uc3QgcGFyZW50SWQgaW4gdGhpcy5yb290LmNoaWxkcmVuKSB7XG4gICAgICBmb3IgKGNvbnN0IGNoaWxkSWQgaW4gdGhpcy5yb290LmNoaWxkcmVuW3BhcmVudElkXSkge1xuICAgICAgICBpZiAoY2hpbGRJZCA9PT0gaWQpIHtcbiAgICAgICAgICByZXR1cm4gdGhpcy5yb290LmNoaWxkcmVuW3BhcmVudElkXVtjaGlsZElkXS5kZXN0cm95KCk7XG4gICAgICAgIH1cbiAgICAgIH1cbiAgICB9XG4gIH1cblxuICBqb2luQ2hpbGQoZWwpIHtcbiAgICBjb25zdCBjaGlsZCA9IHRoaXMuZ2V0Q2hpbGRCeUlkKGVsLmlkKTtcbiAgICBpZiAoIWNoaWxkKSB7XG4gICAgICBjb25zdCB2aWV3ID0gbmV3IFZpZXcoZWwsIHRoaXMubGl2ZVNvY2tldCwgdGhpcyk7XG4gICAgICB0aGlzLnJvb3QuY2hpbGRyZW5bdGhpcy5pZF1bdmlldy5pZF0gPSB2aWV3O1xuICAgICAgdmlldy5qb2luKCk7XG4gICAgICB0aGlzLmNoaWxkSm9pbnMrKztcbiAgICAgIHJldHVybiB0cnVlO1xuICAgIH1cbiAgfVxuXG4gIGlzSm9pblBlbmRpbmcoKSB7XG4gICAgcmV0dXJuIHRoaXMuam9pblBlbmRpbmc7XG4gIH1cblxuICBhY2tKb2luKF9jaGlsZCkge1xuICAgIHRoaXMuY2hpbGRKb2lucy0tO1xuXG4gICAgaWYgKHRoaXMuY2hpbGRKb2lucyA9PT0gMCkge1xuICAgICAgaWYgKHRoaXMucGFyZW50KSB7XG4gICAgICAgIHRoaXMucGFyZW50LmFja0pvaW4odGhpcyk7XG4gICAgICB9IGVsc2Uge1xuICAgICAgICB0aGlzLm9uQWxsQ2hpbGRKb2luc0NvbXBsZXRlKCk7XG4gICAgICB9XG4gICAgfVxuICB9XG5cbiAgb25BbGxDaGlsZEpvaW5zQ29tcGxldGUoKSB7XG4gICAgLy8gd2UgY2FuIGNsZWFyIHBlbmRpbmcgZm9ybSByZWNvdmVyaWVzIG5vdyB0aGF0IHdlJ3ZlIGpvaW5lZC5cbiAgICAvLyBUaGV5IGVpdGhlciBhbGwgcmVzb2x2ZWQgb3Igd2VyZSBhYmFuZG9uZWRcbiAgICB0aGlzLnBlbmRpbmdGb3Jtcy5jbGVhcigpO1xuICAgIC8vIHdlIGNhbiBhbHNvIGNsZWFyIHRoZSBmb3Jtc0ZvclJlY292ZXJ5IG9iamVjdCB0byBub3Qga2VlcCBvbGQgZm9ybSBlbGVtZW50cyBhcm91bmRcbiAgICB0aGlzLmZvcm1zRm9yUmVjb3ZlcnkgPSB7fTtcbiAgICB0aGlzLmpvaW5DYWxsYmFjaygoKSA9PiB7XG4gICAgICB0aGlzLnBlbmRpbmdKb2luT3BzLmZvckVhY2goKFt2aWV3LCBvcF0pID0+IHtcbiAgICAgICAgaWYgKCF2aWV3LmlzRGVzdHJveWVkKCkpIHtcbiAgICAgICAgICBvcCgpO1xuICAgICAgICB9XG4gICAgICB9KTtcbiAgICAgIHRoaXMucGVuZGluZ0pvaW5PcHMgPSBbXTtcbiAgICB9KTtcbiAgfVxuXG4gIHVwZGF0ZShkaWZmLCBldmVudHMsIGlzUGVuZGluZyA9IGZhbHNlKSB7XG4gICAgaWYgKFxuICAgICAgdGhpcy5pc0pvaW5QZW5kaW5nKCkgfHxcbiAgICAgICh0aGlzLmxpdmVTb2NrZXQuaGFzUGVuZGluZ0xpbmsoKSAmJiB0aGlzLnJvb3QuaXNNYWluKCkpXG4gICAgKSB7XG4gICAgICAvLyBkb24ndCBtdXRhdGUgaWYgdGhpcyBpcyBhbHJlYWR5IGEgcGVuZGluZyBkaWZmXG4gICAgICBpZiAoIWlzUGVuZGluZykge1xuICAgICAgICB0aGlzLnBlbmRpbmdEaWZmcy5wdXNoKHsgZGlmZiwgZXZlbnRzIH0pO1xuICAgICAgfVxuICAgICAgcmV0dXJuIGZhbHNlO1xuICAgIH1cblxuICAgIHRoaXMucmVuZGVyZWQubWVyZ2VEaWZmKGRpZmYpO1xuICAgIGxldCBwaHhDaGlsZHJlbkFkZGVkID0gZmFsc2U7XG5cbiAgICAvLyBXaGVuIHRoZSBkaWZmIG9ubHkgY29udGFpbnMgY29tcG9uZW50IGRpZmZzLCB0aGVuIHdhbGsgY29tcG9uZW50c1xuICAgIC8vIGFuZCBwYXRjaCBvbmx5IHRoZSBwYXJlbnQgY29tcG9uZW50IGNvbnRhaW5lcnMgZm91bmQgaW4gdGhlIGRpZmYuXG4gICAgLy8gT3RoZXJ3aXNlLCBwYXRjaCBlbnRpcmUgTFYgY29udGFpbmVyLlxuICAgIGlmICh0aGlzLnJlbmRlcmVkLmlzQ29tcG9uZW50T25seURpZmYoZGlmZikpIHtcbiAgICAgIHRoaXMubGl2ZVNvY2tldC50aW1lKFwiY29tcG9uZW50IHBhdGNoIGNvbXBsZXRlXCIsICgpID0+IHtcbiAgICAgICAgY29uc3QgcGFyZW50Q2lkcyA9IERPTS5maW5kRXhpc3RpbmdQYXJlbnRDSURzKFxuICAgICAgICAgIHRoaXMuaWQsXG4gICAgICAgICAgdGhpcy5yZW5kZXJlZC5jb21wb25lbnRDSURzKGRpZmYpLFxuICAgICAgICApO1xuICAgICAgICBwYXJlbnRDaWRzLmZvckVhY2goKHBhcmVudENJRCkgPT4ge1xuICAgICAgICAgIGlmIChcbiAgICAgICAgICAgIHRoaXMuY29tcG9uZW50UGF0Y2goXG4gICAgICAgICAgICAgIHRoaXMucmVuZGVyZWQuZ2V0Q29tcG9uZW50KGRpZmYsIHBhcmVudENJRCksXG4gICAgICAgICAgICAgIHBhcmVudENJRCxcbiAgICAgICAgICAgIClcbiAgICAgICAgICApIHtcbiAgICAgICAgICAgIHBoeENoaWxkcmVuQWRkZWQgPSB0cnVlO1xuICAgICAgICAgIH1cbiAgICAgICAgfSk7XG4gICAgICB9KTtcbiAgICB9IGVsc2UgaWYgKCFpc0VtcHR5KGRpZmYpKSB7XG4gICAgICB0aGlzLmxpdmVTb2NrZXQudGltZShcImZ1bGwgcGF0Y2ggY29tcGxldGVcIiwgKCkgPT4ge1xuICAgICAgICBjb25zdCBbaHRtbCwgc3RyZWFtc10gPSB0aGlzLnJlbmRlckNvbnRhaW5lcihkaWZmLCBcInVwZGF0ZVwiKTtcbiAgICAgICAgY29uc3QgcGF0Y2ggPSBuZXcgRE9NUGF0Y2godGhpcywgdGhpcy5lbCwgdGhpcy5pZCwgaHRtbCwgc3RyZWFtcywgbnVsbCk7XG4gICAgICAgIHBoeENoaWxkcmVuQWRkZWQgPSB0aGlzLnBlcmZvcm1QYXRjaChwYXRjaCwgdHJ1ZSk7XG4gICAgICB9KTtcbiAgICB9XG5cbiAgICB0aGlzLmxpdmVTb2NrZXQuZGlzcGF0Y2hFdmVudHMoZXZlbnRzKTtcbiAgICBpZiAocGh4Q2hpbGRyZW5BZGRlZCkge1xuICAgICAgdGhpcy5qb2luTmV3Q2hpbGRyZW4oKTtcbiAgICB9XG5cbiAgICByZXR1cm4gdHJ1ZTtcbiAgfVxuXG4gIHJlbmRlckNvbnRhaW5lcihkaWZmLCBraW5kKSB7XG4gICAgcmV0dXJuIHRoaXMubGl2ZVNvY2tldC50aW1lKGB0b1N0cmluZyBkaWZmICgke2tpbmR9KWAsICgpID0+IHtcbiAgICAgIGNvbnN0IHRhZyA9IHRoaXMuZWwudGFnTmFtZTtcbiAgICAgIC8vIERvbid0IHNraXAgYW55IGNvbXBvbmVudCBpbiB0aGUgZGlmZiBub3IgYW55IG1hcmtlZCBhcyBwcnVuZWRcbiAgICAgIC8vIChhcyB0aGV5IG1heSBoYXZlIGJlZW4gYWRkZWQgYmFjaylcbiAgICAgIGNvbnN0IGNpZHMgPSBkaWZmID8gdGhpcy5yZW5kZXJlZC5jb21wb25lbnRDSURzKGRpZmYpIDogbnVsbDtcbiAgICAgIGNvbnN0IHsgYnVmZmVyOiBodG1sLCBzdHJlYW1zIH0gPSB0aGlzLnJlbmRlcmVkLnRvU3RyaW5nKGNpZHMpO1xuICAgICAgcmV0dXJuIFtgPCR7dGFnfT4ke2h0bWx9PC8ke3RhZ30+YCwgc3RyZWFtc107XG4gICAgfSk7XG4gIH1cblxuICBjb21wb25lbnRQYXRjaChkaWZmLCBjaWQpIHtcbiAgICBpZiAoaXNFbXB0eShkaWZmKSkgcmV0dXJuIGZhbHNlO1xuICAgIGNvbnN0IHsgYnVmZmVyOiBodG1sLCBzdHJlYW1zIH0gPSB0aGlzLnJlbmRlcmVkLmNvbXBvbmVudFRvU3RyaW5nKGNpZCk7XG4gICAgY29uc3QgcGF0Y2ggPSBuZXcgRE9NUGF0Y2godGhpcywgdGhpcy5lbCwgdGhpcy5pZCwgaHRtbCwgc3RyZWFtcywgY2lkKTtcbiAgICBjb25zdCBjaGlsZHJlbkFkZGVkID0gdGhpcy5wZXJmb3JtUGF0Y2gocGF0Y2gsIHRydWUpO1xuICAgIHJldHVybiBjaGlsZHJlbkFkZGVkO1xuICB9XG5cbiAgZ2V0SG9vayhlbCkge1xuICAgIHJldHVybiB0aGlzLnZpZXdIb29rc1tWaWV3SG9vay5lbGVtZW50SUQoZWwpXTtcbiAgfVxuXG4gIGFkZEhvb2soZWwpIHtcbiAgICBjb25zdCBob29rRWxJZCA9IFZpZXdIb29rLmVsZW1lbnRJRChlbCk7XG5cbiAgICAvLyBvbmx5IGV2ZXIgdHJ5IHRvIGFkZCBob29rcyB0byBlbGVtZW50cyBvd25lZCBieSB0aGlzIHZpZXdcbiAgICBpZiAoZWwuZ2V0QXR0cmlidXRlICYmICF0aGlzLm93bnNFbGVtZW50KGVsKSkge1xuICAgICAgcmV0dXJuO1xuICAgIH1cblxuICAgIGlmIChob29rRWxJZCAmJiAhdGhpcy52aWV3SG9va3NbaG9va0VsSWRdKSB7XG4gICAgICAvLyBob29rIGNyZWF0ZWQsIGJ1dCBub3QgYXR0YWNoZWQgKGNyZWF0ZUhvb2sgZm9yIHdlYiBjb21wb25lbnQpXG4gICAgICBjb25zdCBob29rID1cbiAgICAgICAgRE9NLmdldEN1c3RvbUVsSG9vayhlbCkgfHxcbiAgICAgICAgbG9nRXJyb3IoYG5vIGhvb2sgZm91bmQgZm9yIGN1c3RvbSBlbGVtZW50OiAke2VsLmlkfWApO1xuICAgICAgdGhpcy52aWV3SG9va3NbaG9va0VsSWRdID0gaG9vaztcbiAgICAgIGhvb2suX19hdHRhY2hWaWV3KHRoaXMpO1xuICAgICAgcmV0dXJuIGhvb2s7XG4gICAgfSBlbHNlIGlmIChob29rRWxJZCB8fCAhZWwuZ2V0QXR0cmlidXRlKSB7XG4gICAgICAvLyBubyBob29rIGZvdW5kXG4gICAgICByZXR1cm47XG4gICAgfSBlbHNlIHtcbiAgICAgIC8vIG5ldyBob29rIGZvdW5kIHdpdGggcGh4LWhvb2sgYXR0cmlidXRlXG4gICAgICBjb25zdCBob29rTmFtZSA9XG4gICAgICAgIGVsLmdldEF0dHJpYnV0ZShgZGF0YS1waHgtJHtQSFhfSE9PS31gKSB8fFxuICAgICAgICBlbC5nZXRBdHRyaWJ1dGUodGhpcy5iaW5kaW5nKFBIWF9IT09LKSk7XG5cbiAgICAgIGlmICghaG9va05hbWUpIHtcbiAgICAgICAgcmV0dXJuO1xuICAgICAgfVxuXG4gICAgICBjb25zdCBob29rRGVmaW5pdGlvbiA9IHRoaXMubGl2ZVNvY2tldC5nZXRIb29rRGVmaW5pdGlvbihob29rTmFtZSk7XG5cbiAgICAgIGlmIChob29rRGVmaW5pdGlvbikge1xuICAgICAgICBpZiAoIWVsLmlkKSB7XG4gICAgICAgICAgbG9nRXJyb3IoXG4gICAgICAgICAgICBgbm8gRE9NIElEIGZvciBob29rIFwiJHtob29rTmFtZX1cIi4gSG9va3MgcmVxdWlyZSBhIHVuaXF1ZSBJRCBvbiBlYWNoIGVsZW1lbnQuYCxcbiAgICAgICAgICAgIGVsLFxuICAgICAgICAgICk7XG4gICAgICAgICAgcmV0dXJuO1xuICAgICAgICB9XG5cbiAgICAgICAgbGV0IGhvb2tJbnN0YW5jZTtcbiAgICAgICAgdHJ5IHtcbiAgICAgICAgICBpZiAoXG4gICAgICAgICAgICB0eXBlb2YgaG9va0RlZmluaXRpb24gPT09IFwiZnVuY3Rpb25cIiAmJlxuICAgICAgICAgICAgaG9va0RlZmluaXRpb24ucHJvdG90eXBlIGluc3RhbmNlb2YgVmlld0hvb2tcbiAgICAgICAgICApIHtcbiAgICAgICAgICAgIC8vIEl0J3MgYSBjbGFzcyBjb25zdHJ1Y3RvciAoc3ViY2xhc3Mgb2YgVmlld0hvb2spXG4gICAgICAgICAgICBob29rSW5zdGFuY2UgPSBuZXcgaG9va0RlZmluaXRpb24odGhpcywgZWwpOyAvLyBgdGhpc2AgaXMgdGhlIFZpZXcgaW5zdGFuY2VcbiAgICAgICAgICB9IGVsc2UgaWYgKFxuICAgICAgICAgICAgdHlwZW9mIGhvb2tEZWZpbml0aW9uID09PSBcIm9iamVjdFwiICYmXG4gICAgICAgICAgICBob29rRGVmaW5pdGlvbiAhPT0gbnVsbFxuICAgICAgICAgICkge1xuICAgICAgICAgICAgLy8gSXQncyBhbiBvYmplY3QgbGl0ZXJhbCwgcGFzcyBpdCB0byB0aGUgVmlld0hvb2sgY29uc3RydWN0b3IgZm9yIHdyYXBwaW5nXG4gICAgICAgICAgICBob29rSW5zdGFuY2UgPSBuZXcgVmlld0hvb2sodGhpcywgZWwsIGhvb2tEZWZpbml0aW9uKTtcbiAgICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgICAgbG9nRXJyb3IoXG4gICAgICAgICAgICAgIGBJbnZhbGlkIGhvb2sgZGVmaW5pdGlvbiBmb3IgXCIke2hvb2tOYW1lfVwiLiBFeHBlY3RlZCBhIGNsYXNzIGV4dGVuZGluZyBWaWV3SG9vayBvciBhbiBvYmplY3QgZGVmaW5pdGlvbi5gLFxuICAgICAgICAgICAgICBlbCxcbiAgICAgICAgICAgICk7XG4gICAgICAgICAgICByZXR1cm47XG4gICAgICAgICAgfVxuICAgICAgICB9IGNhdGNoIChlKSB7XG4gICAgICAgICAgY29uc3QgZXJyb3JNZXNzYWdlID0gZSBpbnN0YW5jZW9mIEVycm9yID8gZS5tZXNzYWdlIDogU3RyaW5nKGUpO1xuICAgICAgICAgIGxvZ0Vycm9yKGBGYWlsZWQgdG8gY3JlYXRlIGhvb2sgXCIke2hvb2tOYW1lfVwiOiAke2Vycm9yTWVzc2FnZX1gLCBlbCk7XG4gICAgICAgICAgcmV0dXJuO1xuICAgICAgICB9XG5cbiAgICAgICAgdGhpcy52aWV3SG9va3NbVmlld0hvb2suZWxlbWVudElEKGhvb2tJbnN0YW5jZS5lbCldID0gaG9va0luc3RhbmNlO1xuICAgICAgICByZXR1cm4gaG9va0luc3RhbmNlO1xuICAgICAgfSBlbHNlIGlmIChob29rTmFtZSAhPT0gbnVsbCkge1xuICAgICAgICBsb2dFcnJvcihgdW5rbm93biBob29rIGZvdW5kIGZvciBcIiR7aG9va05hbWV9XCJgLCBlbCk7XG4gICAgICB9XG4gICAgfVxuICB9XG5cbiAgZGVzdHJveUhvb2soaG9vaykge1xuICAgIC8vIF9fZGVzdHJveWVkIGNsZWFycyB0aGUgZWxlbWVudElEIGZyb20gdGhlIGhvb2ssIHRoZXJlZm9yZVxuICAgIC8vIHdlIG5lZWQgdG8gZ2V0IGl0IGJlZm9yZSBjYWxsaW5nIF9fZGVzdHJveWVkXG4gICAgY29uc3QgaG9va0lkID0gVmlld0hvb2suZWxlbWVudElEKGhvb2suZWwpO1xuICAgIGhvb2suX19kZXN0cm95ZWQoKTtcbiAgICBob29rLl9fY2xlYW51cF9fKCk7XG4gICAgZGVsZXRlIHRoaXMudmlld0hvb2tzW2hvb2tJZF07XG4gIH1cblxuICBhcHBseVBlbmRpbmdVcGRhdGVzKCkge1xuICAgIC8vIFRvIHByZXZlbnQgcmFjZSBjb25kaXRpb25zIHdoZXJlIHdlIG1pZ2h0IHN0aWxsIGJlIHBlbmRpbmcgYSBuZXdcbiAgICAvLyBuYXZpZ2F0aW9uIG9yIHRoZSBqb2luIGlzIHN0aWxsIHBlbmRpbmcsIGB0aGlzLnVwZGF0ZWAgcmV0dXJucyBmYWxzZVxuICAgIC8vIGlmIHRoZSBkaWZmIHdhcyBub3QgYXBwbGllZC5cbiAgICB0aGlzLnBlbmRpbmdEaWZmcyA9IHRoaXMucGVuZGluZ0RpZmZzLmZpbHRlcihcbiAgICAgICh7IGRpZmYsIGV2ZW50cyB9KSA9PiAhdGhpcy51cGRhdGUoZGlmZiwgZXZlbnRzLCB0cnVlKSxcbiAgICApO1xuICAgIHRoaXMuZWFjaENoaWxkKChjaGlsZCkgPT4gY2hpbGQuYXBwbHlQZW5kaW5nVXBkYXRlcygpKTtcbiAgfVxuXG4gIGVhY2hDaGlsZChjYWxsYmFjaykge1xuICAgIGNvbnN0IGNoaWxkcmVuID0gdGhpcy5yb290LmNoaWxkcmVuW3RoaXMuaWRdIHx8IHt9O1xuICAgIGZvciAoY29uc3QgaWQgaW4gY2hpbGRyZW4pIHtcbiAgICAgIGNhbGxiYWNrKHRoaXMuZ2V0Q2hpbGRCeUlkKGlkKSk7XG4gICAgfVxuICB9XG5cbiAgb25DaGFubmVsKGV2ZW50LCBjYikge1xuICAgIHRoaXMubGl2ZVNvY2tldC5vbkNoYW5uZWwodGhpcy5jaGFubmVsLCBldmVudCwgKHJlc3ApID0+IHtcbiAgICAgIGlmICh0aGlzLmlzSm9pblBlbmRpbmcoKSkge1xuICAgICAgICB0aGlzLnJvb3QucGVuZGluZ0pvaW5PcHMucHVzaChbdGhpcywgKCkgPT4gY2IocmVzcCldKTtcbiAgICAgIH0gZWxzZSB7XG4gICAgICAgIHRoaXMubGl2ZVNvY2tldC5yZXF1ZXN0RE9NVXBkYXRlKCgpID0+IGNiKHJlc3ApKTtcbiAgICAgIH1cbiAgICB9KTtcbiAgfVxuXG4gIGJpbmRDaGFubmVsKCkge1xuICAgIC8vIFRoZSBkaWZmIGV2ZW50IHNob3VsZCBiZSBoYW5kbGVkIGJ5IHRoZSByZWd1bGFyIHVwZGF0ZSBvcGVyYXRpb25zLlxuICAgIC8vIEFsbCBvdGhlciBvcGVyYXRpb25zIGFyZSBxdWV1ZWQgdG8gYmUgYXBwbGllZCBvbmx5IGFmdGVyIGpvaW4uXG4gICAgdGhpcy5saXZlU29ja2V0Lm9uQ2hhbm5lbCh0aGlzLmNoYW5uZWwsIFwiZGlmZlwiLCAocmF3RGlmZikgPT4ge1xuICAgICAgdGhpcy5saXZlU29ja2V0LnJlcXVlc3RET01VcGRhdGUoKCkgPT4ge1xuICAgICAgICB0aGlzLmFwcGx5RGlmZihcInVwZGF0ZVwiLCByYXdEaWZmLCAoeyBkaWZmLCBldmVudHMgfSkgPT5cbiAgICAgICAgICB0aGlzLnVwZGF0ZShkaWZmLCBldmVudHMpLFxuICAgICAgICApO1xuICAgICAgfSk7XG4gICAgfSk7XG4gICAgdGhpcy5vbkNoYW5uZWwoXCJyZWRpcmVjdFwiLCAoeyB0bywgZmxhc2ggfSkgPT5cbiAgICAgIHRoaXMub25SZWRpcmVjdCh7IHRvLCBmbGFzaCB9KSxcbiAgICApO1xuICAgIHRoaXMub25DaGFubmVsKFwibGl2ZV9wYXRjaFwiLCAocmVkaXIpID0+IHRoaXMub25MaXZlUGF0Y2gocmVkaXIpKTtcbiAgICB0aGlzLm9uQ2hhbm5lbChcImxpdmVfcmVkaXJlY3RcIiwgKHJlZGlyKSA9PiB0aGlzLm9uTGl2ZVJlZGlyZWN0KHJlZGlyKSk7XG4gICAgdGhpcy5jaGFubmVsLm9uRXJyb3IoKHJlYXNvbikgPT4gdGhpcy5vbkVycm9yKHJlYXNvbikpO1xuICAgIHRoaXMuY2hhbm5lbC5vbkNsb3NlKChyZWFzb24pID0+IHRoaXMub25DbG9zZShyZWFzb24pKTtcbiAgfVxuXG4gIGRlc3Ryb3lBbGxDaGlsZHJlbigpIHtcbiAgICB0aGlzLmVhY2hDaGlsZCgoY2hpbGQpID0+IGNoaWxkLmRlc3Ryb3koKSk7XG4gIH1cblxuICBvbkxpdmVSZWRpcmVjdChyZWRpcikge1xuICAgIGNvbnN0IHsgdG8sIGtpbmQsIGZsYXNoIH0gPSByZWRpcjtcbiAgICBjb25zdCB1cmwgPSB0aGlzLmV4cGFuZFVSTCh0byk7XG4gICAgY29uc3QgZSA9IG5ldyBDdXN0b21FdmVudChcInBoeDpzZXJ2ZXItbmF2aWdhdGVcIiwge1xuICAgICAgZGV0YWlsOiB7IHRvLCBraW5kLCBmbGFzaCB9LFxuICAgIH0pO1xuICAgIHRoaXMubGl2ZVNvY2tldC5oaXN0b3J5UmVkaXJlY3QoZSwgdXJsLCBraW5kLCBmbGFzaCk7XG4gIH1cblxuICBvbkxpdmVQYXRjaChyZWRpcikge1xuICAgIGNvbnN0IHsgdG8sIGtpbmQgfSA9IHJlZGlyO1xuICAgIHRoaXMuaHJlZiA9IHRoaXMuZXhwYW5kVVJMKHRvKTtcbiAgICB0aGlzLmxpdmVTb2NrZXQuaGlzdG9yeVBhdGNoKHRvLCBraW5kKTtcbiAgfVxuXG4gIGV4cGFuZFVSTCh0bykge1xuICAgIHJldHVybiB0by5zdGFydHNXaXRoKFwiL1wiKVxuICAgICAgPyBgJHt3aW5kb3cubG9jYXRpb24ucHJvdG9jb2x9Ly8ke3dpbmRvdy5sb2NhdGlvbi5ob3N0fSR7dG99YFxuICAgICAgOiB0bztcbiAgfVxuXG4gIC8qKlxuICAgKiBAcGFyYW0ge3t0bzogc3RyaW5nLCBmbGFzaD86IHN0cmluZywgcmVsb2FkVG9rZW4/OiBzdHJpbmd9fSByZWRpcmVjdFxuICAgKi9cbiAgb25SZWRpcmVjdCh7IHRvLCBmbGFzaCwgcmVsb2FkVG9rZW4gfSkge1xuICAgIHRoaXMubGl2ZVNvY2tldC5yZWRpcmVjdCh0bywgZmxhc2gsIHJlbG9hZFRva2VuKTtcbiAgfVxuXG4gIGlzRGVzdHJveWVkKCkge1xuICAgIHJldHVybiB0aGlzLmRlc3Ryb3llZDtcbiAgfVxuXG4gIGpvaW5EZWFkKCkge1xuICAgIHRoaXMuaXNEZWFkID0gdHJ1ZTtcbiAgfVxuXG4gIGpvaW5QdXNoKCkge1xuICAgIHRoaXMuam9pblB1c2ggPSB0aGlzLmpvaW5QdXNoIHx8IHRoaXMuY2hhbm5lbC5qb2luKCk7XG4gICAgcmV0dXJuIHRoaXMuam9pblB1c2g7XG4gIH1cblxuICBqb2luKGNhbGxiYWNrKSB7XG4gICAgdGhpcy5zaG93TG9hZGVyKHRoaXMubGl2ZVNvY2tldC5sb2FkZXJUaW1lb3V0KTtcbiAgICB0aGlzLmJpbmRDaGFubmVsKCk7XG4gICAgaWYgKHRoaXMuaXNNYWluKCkpIHtcbiAgICAgIHRoaXMuc3RvcENhbGxiYWNrID0gdGhpcy5saXZlU29ja2V0LndpdGhQYWdlTG9hZGluZyh7XG4gICAgICAgIHRvOiB0aGlzLmhyZWYsXG4gICAgICAgIGtpbmQ6IFwiaW5pdGlhbFwiLFxuICAgICAgfSk7XG4gICAgfVxuICAgIHRoaXMuam9pbkNhbGxiYWNrID0gKG9uRG9uZSkgPT4ge1xuICAgICAgb25Eb25lID0gb25Eb25lIHx8IGZ1bmN0aW9uICgpIHt9O1xuICAgICAgY2FsbGJhY2sgPyBjYWxsYmFjayh0aGlzLmpvaW5Db3VudCwgb25Eb25lKSA6IG9uRG9uZSgpO1xuICAgIH07XG5cbiAgICB0aGlzLndyYXBQdXNoKCgpID0+IHRoaXMuY2hhbm5lbC5qb2luKCksIHtcbiAgICAgIG9rOiAocmVzcCkgPT4gdGhpcy5saXZlU29ja2V0LnJlcXVlc3RET01VcGRhdGUoKCkgPT4gdGhpcy5vbkpvaW4ocmVzcCkpLFxuICAgICAgZXJyb3I6IChlcnJvcikgPT4gdGhpcy5vbkpvaW5FcnJvcihlcnJvciksXG4gICAgICB0aW1lb3V0OiAoKSA9PiB0aGlzLm9uSm9pbkVycm9yKHsgcmVhc29uOiBcInRpbWVvdXRcIiB9KSxcbiAgICB9KTtcbiAgfVxuXG4gIG9uSm9pbkVycm9yKHJlc3ApIHtcbiAgICBpZiAocmVzcC5yZWFzb24gPT09IFwicmVsb2FkXCIpIHtcbiAgICAgIHRoaXMubG9nKFwiZXJyb3JcIiwgKCkgPT4gW1xuICAgICAgICBgZmFpbGVkIG1vdW50IHdpdGggJHtyZXNwLnN0YXR1c30uIEZhbGxpbmcgYmFjayB0byBwYWdlIHJlbG9hZGAsXG4gICAgICAgIHJlc3AsXG4gICAgICBdKTtcbiAgICAgIHRoaXMub25SZWRpcmVjdCh7IHRvOiB0aGlzLnJvb3QuaHJlZiwgcmVsb2FkVG9rZW46IHJlc3AudG9rZW4gfSk7XG4gICAgICByZXR1cm47XG4gICAgfSBlbHNlIGlmIChyZXNwLnJlYXNvbiA9PT0gXCJ1bmF1dGhvcml6ZWRcIiB8fCByZXNwLnJlYXNvbiA9PT0gXCJzdGFsZVwiKSB7XG4gICAgICB0aGlzLmxvZyhcImVycm9yXCIsICgpID0+IFtcbiAgICAgICAgXCJ1bmF1dGhvcml6ZWQgbGl2ZV9yZWRpcmVjdC4gRmFsbGluZyBiYWNrIHRvIHBhZ2UgcmVxdWVzdFwiLFxuICAgICAgICByZXNwLFxuICAgICAgXSk7XG4gICAgICB0aGlzLm9uUmVkaXJlY3QoeyB0bzogdGhpcy5yb290LmhyZWYsIGZsYXNoOiB0aGlzLmZsYXNoIH0pO1xuICAgICAgcmV0dXJuO1xuICAgIH1cbiAgICBpZiAocmVzcC5yZWRpcmVjdCB8fCByZXNwLmxpdmVfcmVkaXJlY3QpIHtcbiAgICAgIHRoaXMuam9pblBlbmRpbmcgPSBmYWxzZTtcbiAgICAgIHRoaXMuY2hhbm5lbC5sZWF2ZSgpO1xuICAgIH1cbiAgICBpZiAocmVzcC5yZWRpcmVjdCkge1xuICAgICAgcmV0dXJuIHRoaXMub25SZWRpcmVjdChyZXNwLnJlZGlyZWN0KTtcbiAgICB9XG4gICAgaWYgKHJlc3AubGl2ZV9yZWRpcmVjdCkge1xuICAgICAgcmV0dXJuIHRoaXMub25MaXZlUmVkaXJlY3QocmVzcC5saXZlX3JlZGlyZWN0KTtcbiAgICB9XG4gICAgdGhpcy5sb2coXCJlcnJvclwiLCAoKSA9PiBbXCJ1bmFibGUgdG8gam9pblwiLCByZXNwXSk7XG4gICAgaWYgKHRoaXMuaXNNYWluKCkpIHtcbiAgICAgIHRoaXMuZGlzcGxheUVycm9yKFtcbiAgICAgICAgUEhYX0xPQURJTkdfQ0xBU1MsXG4gICAgICAgIFBIWF9FUlJPUl9DTEFTUyxcbiAgICAgICAgUEhYX1NFUlZFUl9FUlJPUl9DTEFTUyxcbiAgICAgIF0pO1xuICAgICAgaWYgKHRoaXMubGl2ZVNvY2tldC5pc0Nvbm5lY3RlZCgpKSB7XG4gICAgICAgIHRoaXMubGl2ZVNvY2tldC5yZWxvYWRXaXRoSml0dGVyKHRoaXMpO1xuICAgICAgfVxuICAgIH0gZWxzZSB7XG4gICAgICBpZiAodGhpcy5qb2luQXR0ZW1wdHMgPj0gTUFYX0NISUxEX0pPSU5fQVRURU1QVFMpIHtcbiAgICAgICAgLy8gcHV0IHRoZSByb290IHJldmlldyBpbnRvIHBlcm1hbmVudCBlcnJvciBzdGF0ZSwgYnV0IGRvbid0IGRlc3Ryb3kgaXQgYXMgaXQgY2FuIHJlbWFpbiBhY3RpdmVcbiAgICAgICAgdGhpcy5yb290LmRpc3BsYXlFcnJvcihbXG4gICAgICAgICAgUEhYX0xPQURJTkdfQ0xBU1MsXG4gICAgICAgICAgUEhYX0VSUk9SX0NMQVNTLFxuICAgICAgICAgIFBIWF9TRVJWRVJfRVJST1JfQ0xBU1MsXG4gICAgICAgIF0pO1xuICAgICAgICB0aGlzLmxvZyhcImVycm9yXCIsICgpID0+IFtcbiAgICAgICAgICBgZ2l2aW5nIHVwIHRyeWluZyB0byBtb3VudCBhZnRlciAke01BWF9DSElMRF9KT0lOX0FUVEVNUFRTfSB0cmllc2AsXG4gICAgICAgICAgcmVzcCxcbiAgICAgICAgXSk7XG4gICAgICAgIHRoaXMuZGVzdHJveSgpO1xuICAgICAgfVxuICAgICAgY29uc3QgdHJ1ZUNoaWxkRWwgPSBET00uYnlJZCh0aGlzLmVsLmlkKTtcbiAgICAgIGlmICh0cnVlQ2hpbGRFbCkge1xuICAgICAgICBET00ubWVyZ2VBdHRycyh0cnVlQ2hpbGRFbCwgdGhpcy5lbCk7XG4gICAgICAgIHRoaXMuZGlzcGxheUVycm9yKFtcbiAgICAgICAgICBQSFhfTE9BRElOR19DTEFTUyxcbiAgICAgICAgICBQSFhfRVJST1JfQ0xBU1MsXG4gICAgICAgICAgUEhYX1NFUlZFUl9FUlJPUl9DTEFTUyxcbiAgICAgICAgXSk7XG4gICAgICAgIHRoaXMuZWwgPSB0cnVlQ2hpbGRFbDtcbiAgICAgIH0gZWxzZSB7XG4gICAgICAgIHRoaXMuZGVzdHJveSgpO1xuICAgICAgfVxuICAgIH1cbiAgfVxuXG4gIG9uQ2xvc2UocmVhc29uKSB7XG4gICAgaWYgKHRoaXMuaXNEZXN0cm95ZWQoKSkge1xuICAgICAgcmV0dXJuO1xuICAgIH1cbiAgICBpZiAoXG4gICAgICB0aGlzLmlzTWFpbigpICYmXG4gICAgICB0aGlzLmxpdmVTb2NrZXQuaGFzUGVuZGluZ0xpbmsoKSAmJlxuICAgICAgcmVhc29uICE9PSBcImxlYXZlXCJcbiAgICApIHtcbiAgICAgIHJldHVybiB0aGlzLmxpdmVTb2NrZXQucmVsb2FkV2l0aEppdHRlcih0aGlzKTtcbiAgICB9XG4gICAgdGhpcy5kZXN0cm95QWxsQ2hpbGRyZW4oKTtcbiAgICB0aGlzLmxpdmVTb2NrZXQuZHJvcEFjdGl2ZUVsZW1lbnQodGhpcyk7XG4gICAgaWYgKHRoaXMubGl2ZVNvY2tldC5pc1VubG9hZGVkKCkpIHtcbiAgICAgIHRoaXMuc2hvd0xvYWRlcihCRUZPUkVfVU5MT0FEX0xPQURFUl9USU1FT1VUKTtcbiAgICB9XG4gIH1cblxuICBvbkVycm9yKHJlYXNvbikge1xuICAgIHRoaXMub25DbG9zZShyZWFzb24pO1xuICAgIGlmICh0aGlzLmxpdmVTb2NrZXQuaXNDb25uZWN0ZWQoKSkge1xuICAgICAgdGhpcy5sb2coXCJlcnJvclwiLCAoKSA9PiBbXCJ2aWV3IGNyYXNoZWRcIiwgcmVhc29uXSk7XG4gICAgfVxuICAgIGlmICghdGhpcy5saXZlU29ja2V0LmlzVW5sb2FkZWQoKSkge1xuICAgICAgaWYgKHRoaXMubGl2ZVNvY2tldC5pc0Nvbm5lY3RlZCgpKSB7XG4gICAgICAgIHRoaXMuZGlzcGxheUVycm9yKFtcbiAgICAgICAgICBQSFhfTE9BRElOR19DTEFTUyxcbiAgICAgICAgICBQSFhfRVJST1JfQ0xBU1MsXG4gICAgICAgICAgUEhYX1NFUlZFUl9FUlJPUl9DTEFTUyxcbiAgICAgICAgXSk7XG4gICAgICB9IGVsc2Uge1xuICAgICAgICB0aGlzLmRpc3BsYXlFcnJvcihbXG4gICAgICAgICAgUEhYX0xPQURJTkdfQ0xBU1MsXG4gICAgICAgICAgUEhYX0VSUk9SX0NMQVNTLFxuICAgICAgICAgIFBIWF9DTElFTlRfRVJST1JfQ0xBU1MsXG4gICAgICAgIF0pO1xuICAgICAgfVxuICAgIH1cbiAgfVxuXG4gIGRpc3BsYXlFcnJvcihjbGFzc2VzKSB7XG4gICAgaWYgKHRoaXMuaXNNYWluKCkpIHtcbiAgICAgIERPTS5kaXNwYXRjaEV2ZW50KHdpbmRvdywgXCJwaHg6cGFnZS1sb2FkaW5nLXN0YXJ0XCIsIHtcbiAgICAgICAgZGV0YWlsOiB7IHRvOiB0aGlzLmhyZWYsIGtpbmQ6IFwiZXJyb3JcIiB9LFxuICAgICAgfSk7XG4gICAgfVxuICAgIHRoaXMuc2hvd0xvYWRlcigpO1xuICAgIHRoaXMuc2V0Q29udGFpbmVyQ2xhc3NlcyguLi5jbGFzc2VzKTtcbiAgICB0aGlzLmRlbGF5ZWREaXNjb25uZWN0ZWQoKTtcbiAgfVxuXG4gIGRlbGF5ZWREaXNjb25uZWN0ZWQoKSB7XG4gICAgdGhpcy5kaXNjb25uZWN0ZWRUaW1lciA9IHNldFRpbWVvdXQoKCkgPT4ge1xuICAgICAgdGhpcy5leGVjQWxsKHRoaXMuYmluZGluZyhcImRpc2Nvbm5lY3RlZFwiKSk7XG4gICAgfSwgdGhpcy5saXZlU29ja2V0LmRpc2Nvbm5lY3RlZFRpbWVvdXQpO1xuICB9XG5cbiAgd3JhcFB1c2goY2FsbGVyUHVzaCwgcmVjZWl2ZXMpIHtcbiAgICBjb25zdCBsYXRlbmN5ID0gdGhpcy5saXZlU29ja2V0LmdldExhdGVuY3lTaW0oKTtcbiAgICBjb25zdCB3aXRoTGF0ZW5jeSA9IGxhdGVuY3lcbiAgICAgID8gKGNiKSA9PiBzZXRUaW1lb3V0KCgpID0+ICF0aGlzLmlzRGVzdHJveWVkKCkgJiYgY2IoKSwgbGF0ZW5jeSlcbiAgICAgIDogKGNiKSA9PiAhdGhpcy5pc0Rlc3Ryb3llZCgpICYmIGNiKCk7XG5cbiAgICB3aXRoTGF0ZW5jeSgoKSA9PiB7XG4gICAgICBjYWxsZXJQdXNoKClcbiAgICAgICAgLnJlY2VpdmUoXCJva1wiLCAocmVzcCkgPT5cbiAgICAgICAgICB3aXRoTGF0ZW5jeSgoKSA9PiByZWNlaXZlcy5vayAmJiByZWNlaXZlcy5vayhyZXNwKSksXG4gICAgICAgIClcbiAgICAgICAgLnJlY2VpdmUoXCJlcnJvclwiLCAocmVhc29uKSA9PlxuICAgICAgICAgIHdpdGhMYXRlbmN5KCgpID0+IHJlY2VpdmVzLmVycm9yICYmIHJlY2VpdmVzLmVycm9yKHJlYXNvbikpLFxuICAgICAgICApXG4gICAgICAgIC5yZWNlaXZlKFwidGltZW91dFwiLCAoKSA9PlxuICAgICAgICAgIHdpdGhMYXRlbmN5KCgpID0+IHJlY2VpdmVzLnRpbWVvdXQgJiYgcmVjZWl2ZXMudGltZW91dCgpKSxcbiAgICAgICAgKTtcbiAgICB9KTtcbiAgfVxuXG4gIHB1c2hXaXRoUmVwbHkocmVmR2VuZXJhdG9yLCBldmVudCwgcGF5bG9hZCkge1xuICAgIGlmICghdGhpcy5pc0Nvbm5lY3RlZCgpKSB7XG4gICAgICByZXR1cm4gUHJvbWlzZS5yZWplY3QobmV3IEVycm9yKFwibm8gY29ubmVjdGlvblwiKSk7XG4gICAgfVxuXG4gICAgY29uc3QgW3JlZiwgW2VsXSwgb3B0c10gPSByZWZHZW5lcmF0b3JcbiAgICAgID8gcmVmR2VuZXJhdG9yKHsgcGF5bG9hZCB9KVxuICAgICAgOiBbbnVsbCwgW10sIHt9XTtcbiAgICBjb25zdCBvbGRKb2luQ291bnQgPSB0aGlzLmpvaW5Db3VudDtcbiAgICBsZXQgb25Mb2FkaW5nRG9uZSA9IGZ1bmN0aW9uICgpIHt9O1xuICAgIGlmIChvcHRzLnBhZ2VfbG9hZGluZykge1xuICAgICAgb25Mb2FkaW5nRG9uZSA9IHRoaXMubGl2ZVNvY2tldC53aXRoUGFnZUxvYWRpbmcoe1xuICAgICAgICBraW5kOiBcImVsZW1lbnRcIixcbiAgICAgICAgdGFyZ2V0OiBlbCxcbiAgICAgIH0pO1xuICAgIH1cblxuICAgIGlmICh0eXBlb2YgcGF5bG9hZC5jaWQgIT09IFwibnVtYmVyXCIpIHtcbiAgICAgIGRlbGV0ZSBwYXlsb2FkLmNpZDtcbiAgICB9XG5cbiAgICByZXR1cm4gbmV3IFByb21pc2UoKHJlc29sdmUsIHJlamVjdCkgPT4ge1xuICAgICAgdGhpcy53cmFwUHVzaCgoKSA9PiB0aGlzLmNoYW5uZWwucHVzaChldmVudCwgcGF5bG9hZCwgUFVTSF9USU1FT1VUKSwge1xuICAgICAgICBvazogKHJlc3ApID0+IHtcbiAgICAgICAgICBpZiAocmVmICE9PSBudWxsKSB7XG4gICAgICAgICAgICB0aGlzLmxhc3RBY2tSZWYgPSByZWY7XG4gICAgICAgICAgfVxuICAgICAgICAgIGNvbnN0IGZpbmlzaCA9IChob29rUmVwbHkpID0+IHtcbiAgICAgICAgICAgIGlmIChyZXNwLnJlZGlyZWN0KSB7XG4gICAgICAgICAgICAgIHRoaXMub25SZWRpcmVjdChyZXNwLnJlZGlyZWN0KTtcbiAgICAgICAgICAgIH1cbiAgICAgICAgICAgIGlmIChyZXNwLmxpdmVfcGF0Y2gpIHtcbiAgICAgICAgICAgICAgdGhpcy5vbkxpdmVQYXRjaChyZXNwLmxpdmVfcGF0Y2gpO1xuICAgICAgICAgICAgfVxuICAgICAgICAgICAgaWYgKHJlc3AubGl2ZV9yZWRpcmVjdCkge1xuICAgICAgICAgICAgICB0aGlzLm9uTGl2ZVJlZGlyZWN0KHJlc3AubGl2ZV9yZWRpcmVjdCk7XG4gICAgICAgICAgICB9XG4gICAgICAgICAgICBvbkxvYWRpbmdEb25lKCk7XG4gICAgICAgICAgICByZXNvbHZlKHsgcmVzcDogcmVzcCwgcmVwbHk6IGhvb2tSZXBseSwgcmVmIH0pO1xuICAgICAgICAgIH07XG4gICAgICAgICAgaWYgKHJlc3AuZGlmZikge1xuICAgICAgICAgICAgdGhpcy5saXZlU29ja2V0LnJlcXVlc3RET01VcGRhdGUoKCkgPT4ge1xuICAgICAgICAgICAgICB0aGlzLmFwcGx5RGlmZihcInVwZGF0ZVwiLCByZXNwLmRpZmYsICh7IGRpZmYsIHJlcGx5LCBldmVudHMgfSkgPT4ge1xuICAgICAgICAgICAgICAgIGlmIChyZWYgIT09IG51bGwpIHtcbiAgICAgICAgICAgICAgICAgIHRoaXMudW5kb1JlZnMocmVmLCBwYXlsb2FkLmV2ZW50KTtcbiAgICAgICAgICAgICAgICB9XG4gICAgICAgICAgICAgICAgdGhpcy51cGRhdGUoZGlmZiwgZXZlbnRzKTtcbiAgICAgICAgICAgICAgICBmaW5pc2gocmVwbHkpO1xuICAgICAgICAgICAgICB9KTtcbiAgICAgICAgICAgIH0pO1xuICAgICAgICAgIH0gZWxzZSB7XG4gICAgICAgICAgICBpZiAocmVmICE9PSBudWxsKSB7XG4gICAgICAgICAgICAgIHRoaXMudW5kb1JlZnMocmVmLCBwYXlsb2FkLmV2ZW50KTtcbiAgICAgICAgICAgIH1cbiAgICAgICAgICAgIGZpbmlzaChudWxsKTtcbiAgICAgICAgICB9XG4gICAgICAgIH0sXG4gICAgICAgIGVycm9yOiAocmVhc29uKSA9PiByZWplY3QobmV3IEVycm9yKGBmYWlsZWQgd2l0aCByZWFzb246ICR7cmVhc29ufWApKSxcbiAgICAgICAgdGltZW91dDogKCkgPT4ge1xuICAgICAgICAgIHJlamVjdChuZXcgRXJyb3IoXCJ0aW1lb3V0XCIpKTtcbiAgICAgICAgICBpZiAodGhpcy5qb2luQ291bnQgPT09IG9sZEpvaW5Db3VudCkge1xuICAgICAgICAgICAgdGhpcy5saXZlU29ja2V0LnJlbG9hZFdpdGhKaXR0ZXIodGhpcywgKCkgPT4ge1xuICAgICAgICAgICAgICB0aGlzLmxvZyhcInRpbWVvdXRcIiwgKCkgPT4gW1xuICAgICAgICAgICAgICAgIFwicmVjZWl2ZWQgdGltZW91dCB3aGlsZSBjb21tdW5pY2F0aW5nIHdpdGggc2VydmVyLiBGYWxsaW5nIGJhY2sgdG8gaGFyZCByZWZyZXNoIGZvciByZWNvdmVyeVwiLFxuICAgICAgICAgICAgICBdKTtcbiAgICAgICAgICAgIH0pO1xuICAgICAgICAgIH1cbiAgICAgICAgfSxcbiAgICAgIH0pO1xuICAgIH0pO1xuICB9XG5cbiAgdW5kb1JlZnMocmVmLCBwaHhFdmVudCwgb25seUVscykge1xuICAgIGlmICghdGhpcy5pc0Nvbm5lY3RlZCgpKSB7XG4gICAgICByZXR1cm47XG4gICAgfSAvLyBleGl0IGlmIGV4dGVybmFsIGZvcm0gdHJpZ2dlcmVkXG4gICAgY29uc3Qgc2VsZWN0b3IgPSBgWyR7UEhYX1JFRl9TUkN9PVwiJHt0aGlzLnJlZlNyYygpfVwiXWA7XG5cbiAgICBpZiAob25seUVscykge1xuICAgICAgb25seUVscyA9IG5ldyBTZXQob25seUVscyk7XG4gICAgICBET00uYWxsKGRvY3VtZW50LCBzZWxlY3RvciwgKHBhcmVudCkgPT4ge1xuICAgICAgICBpZiAob25seUVscyAmJiAhb25seUVscy5oYXMocGFyZW50KSkge1xuICAgICAgICAgIHJldHVybjtcbiAgICAgICAgfVxuICAgICAgICAvLyB1bmRvIGFueSBjaGlsZCByZWZzIHdpdGhpbiBwYXJlbnQgZmlyc3RcbiAgICAgICAgRE9NLmFsbChwYXJlbnQsIHNlbGVjdG9yLCAoY2hpbGQpID0+XG4gICAgICAgICAgdGhpcy51bmRvRWxSZWYoY2hpbGQsIHJlZiwgcGh4RXZlbnQpLFxuICAgICAgICApO1xuICAgICAgICB0aGlzLnVuZG9FbFJlZihwYXJlbnQsIHJlZiwgcGh4RXZlbnQpO1xuICAgICAgfSk7XG4gICAgfSBlbHNlIHtcbiAgICAgIERPTS5hbGwoZG9jdW1lbnQsIHNlbGVjdG9yLCAoZWwpID0+IHRoaXMudW5kb0VsUmVmKGVsLCByZWYsIHBoeEV2ZW50KSk7XG4gICAgfVxuICB9XG5cbiAgdW5kb0VsUmVmKGVsLCByZWYsIHBoeEV2ZW50KSB7XG4gICAgY29uc3QgZWxSZWYgPSBuZXcgRWxlbWVudFJlZihlbCk7XG5cbiAgICBlbFJlZi5tYXliZVVuZG8ocmVmLCBwaHhFdmVudCwgKGNsb25lZFRyZWUpID0+IHtcbiAgICAgIC8vIHdlIG5lZWQgdG8gcGVyZm9ybSBhIGZ1bGwgcGF0Y2ggb24gdW5sb2NrZWQgZWxlbWVudHNcbiAgICAgIC8vIHRvIHBlcmZvcm0gYWxsIHRoZSBuZWNlc3NhcnkgbG9naWMgKGxpa2UgY2FsbGluZyB1cGRhdGVkIGZvciBob29rcywgZXRjLilcbiAgICAgIGNvbnN0IHBhdGNoID0gbmV3IERPTVBhdGNoKHRoaXMsIGVsLCB0aGlzLmlkLCBjbG9uZWRUcmVlLCBbXSwgbnVsbCwge1xuICAgICAgICB1bmRvUmVmOiByZWYsXG4gICAgICB9KTtcbiAgICAgIGNvbnN0IHBoeENoaWxkcmVuQWRkZWQgPSB0aGlzLnBlcmZvcm1QYXRjaChwYXRjaCwgdHJ1ZSk7XG4gICAgICBET00uYWxsKGVsLCBgWyR7UEhYX1JFRl9TUkN9PVwiJHt0aGlzLnJlZlNyYygpfVwiXWAsIChjaGlsZCkgPT5cbiAgICAgICAgdGhpcy51bmRvRWxSZWYoY2hpbGQsIHJlZiwgcGh4RXZlbnQpLFxuICAgICAgKTtcbiAgICAgIGlmIChwaHhDaGlsZHJlbkFkZGVkKSB7XG4gICAgICAgIHRoaXMuam9pbk5ld0NoaWxkcmVuKCk7XG4gICAgICB9XG4gICAgfSk7XG4gIH1cblxuICByZWZTcmMoKSB7XG4gICAgcmV0dXJuIHRoaXMuZWwuaWQ7XG4gIH1cblxuICBwdXRSZWYoZWxlbWVudHMsIHBoeEV2ZW50LCBldmVudFR5cGUsIG9wdHMgPSB7fSkge1xuICAgIGNvbnN0IG5ld1JlZiA9IHRoaXMucmVmKys7XG4gICAgY29uc3QgZGlzYWJsZVdpdGggPSB0aGlzLmJpbmRpbmcoUEhYX0RJU0FCTEVfV0lUSCk7XG4gICAgaWYgKG9wdHMubG9hZGluZykge1xuICAgICAgY29uc3QgbG9hZGluZ0VscyA9IERPTS5hbGwoZG9jdW1lbnQsIG9wdHMubG9hZGluZykubWFwKChlbCkgPT4ge1xuICAgICAgICByZXR1cm4geyBlbCwgbG9jazogdHJ1ZSwgbG9hZGluZzogdHJ1ZSB9O1xuICAgICAgfSk7XG4gICAgICBlbGVtZW50cyA9IGVsZW1lbnRzLmNvbmNhdChsb2FkaW5nRWxzKTtcbiAgICB9XG5cbiAgICBmb3IgKGNvbnN0IHsgZWwsIGxvY2ssIGxvYWRpbmcgfSBvZiBlbGVtZW50cykge1xuICAgICAgaWYgKCFsb2NrICYmICFsb2FkaW5nKSB7XG4gICAgICAgIHRocm93IG5ldyBFcnJvcihcInB1dFJlZiByZXF1aXJlcyBsb2NrIG9yIGxvYWRpbmdcIik7XG4gICAgICB9XG4gICAgICBlbC5zZXRBdHRyaWJ1dGUoUEhYX1JFRl9TUkMsIHRoaXMucmVmU3JjKCkpO1xuICAgICAgaWYgKGxvYWRpbmcpIHtcbiAgICAgICAgZWwuc2V0QXR0cmlidXRlKFBIWF9SRUZfTE9BRElORywgbmV3UmVmKTtcbiAgICAgIH1cbiAgICAgIGlmIChsb2NrKSB7XG4gICAgICAgIGVsLnNldEF0dHJpYnV0ZShQSFhfUkVGX0xPQ0ssIG5ld1JlZik7XG4gICAgICB9XG5cbiAgICAgIGlmIChcbiAgICAgICAgIWxvYWRpbmcgfHxcbiAgICAgICAgKG9wdHMuc3VibWl0dGVyICYmICEoZWwgPT09IG9wdHMuc3VibWl0dGVyIHx8IGVsID09PSBvcHRzLmZvcm0pKVxuICAgICAgKSB7XG4gICAgICAgIGNvbnRpbnVlO1xuICAgICAgfVxuXG4gICAgICBjb25zdCBsb2NrQ29tcGxldGVQcm9taXNlID0gbmV3IFByb21pc2UoKHJlc29sdmUpID0+IHtcbiAgICAgICAgZWwuYWRkRXZlbnRMaXN0ZW5lcihgcGh4OnVuZG8tbG9jazoke25ld1JlZn1gLCAoKSA9PiByZXNvbHZlKGRldGFpbCksIHtcbiAgICAgICAgICBvbmNlOiB0cnVlLFxuICAgICAgICB9KTtcbiAgICAgIH0pO1xuXG4gICAgICBjb25zdCBsb2FkaW5nQ29tcGxldGVQcm9taXNlID0gbmV3IFByb21pc2UoKHJlc29sdmUpID0+IHtcbiAgICAgICAgZWwuYWRkRXZlbnRMaXN0ZW5lcihcbiAgICAgICAgICBgcGh4OnVuZG8tbG9hZGluZzoke25ld1JlZn1gLFxuICAgICAgICAgICgpID0+IHJlc29sdmUoZGV0YWlsKSxcbiAgICAgICAgICB7IG9uY2U6IHRydWUgfSxcbiAgICAgICAgKTtcbiAgICAgIH0pO1xuXG4gICAgICBlbC5jbGFzc0xpc3QuYWRkKGBwaHgtJHtldmVudFR5cGV9LWxvYWRpbmdgKTtcbiAgICAgIGNvbnN0IGRpc2FibGVUZXh0ID0gZWwuZ2V0QXR0cmlidXRlKGRpc2FibGVXaXRoKTtcbiAgICAgIGlmIChkaXNhYmxlVGV4dCAhPT0gbnVsbCkge1xuICAgICAgICBpZiAoIWVsLmdldEF0dHJpYnV0ZShQSFhfRElTQUJMRV9XSVRIX1JFU1RPUkUpKSB7XG4gICAgICAgICAgZWwuc2V0QXR0cmlidXRlKFBIWF9ESVNBQkxFX1dJVEhfUkVTVE9SRSwgZWwuaW5uZXJUZXh0KTtcbiAgICAgICAgfVxuICAgICAgICBpZiAoZGlzYWJsZVRleHQgIT09IFwiXCIpIHtcbiAgICAgICAgICBlbC5pbm5lclRleHQgPSBkaXNhYmxlVGV4dDtcbiAgICAgICAgfVxuICAgICAgICAvLyBQSFhfRElTQUJMRUQgY291bGQgaGF2ZSBhbHJlYWR5IGJlZW4gc2V0IGluIGRpc2FibGVGb3JtXG4gICAgICAgIGVsLnNldEF0dHJpYnV0ZShcbiAgICAgICAgICBQSFhfRElTQUJMRUQsXG4gICAgICAgICAgZWwuZ2V0QXR0cmlidXRlKFBIWF9ESVNBQkxFRCkgfHwgZWwuZGlzYWJsZWQsXG4gICAgICAgICk7XG4gICAgICAgIGVsLnNldEF0dHJpYnV0ZShcImRpc2FibGVkXCIsIFwiXCIpO1xuICAgICAgfVxuXG4gICAgICBjb25zdCBkZXRhaWwgPSB7XG4gICAgICAgIGV2ZW50OiBwaHhFdmVudCxcbiAgICAgICAgZXZlbnRUeXBlOiBldmVudFR5cGUsXG4gICAgICAgIHJlZjogbmV3UmVmLFxuICAgICAgICBpc0xvYWRpbmc6IGxvYWRpbmcsXG4gICAgICAgIGlzTG9ja2VkOiBsb2NrLFxuICAgICAgICBsb2NrRWxlbWVudHM6IGVsZW1lbnRzLmZpbHRlcigoeyBsb2NrIH0pID0+IGxvY2spLm1hcCgoeyBlbCB9KSA9PiBlbCksXG4gICAgICAgIGxvYWRpbmdFbGVtZW50czogZWxlbWVudHNcbiAgICAgICAgICAuZmlsdGVyKCh7IGxvYWRpbmcgfSkgPT4gbG9hZGluZylcbiAgICAgICAgICAubWFwKCh7IGVsIH0pID0+IGVsKSxcbiAgICAgICAgdW5sb2NrOiAoZWxzKSA9PiB7XG4gICAgICAgICAgZWxzID0gQXJyYXkuaXNBcnJheShlbHMpID8gZWxzIDogW2Vsc107XG4gICAgICAgICAgdGhpcy51bmRvUmVmcyhuZXdSZWYsIHBoeEV2ZW50LCBlbHMpO1xuICAgICAgICB9LFxuICAgICAgICBsb2NrQ29tcGxldGU6IGxvY2tDb21wbGV0ZVByb21pc2UsXG4gICAgICAgIGxvYWRpbmdDb21wbGV0ZTogbG9hZGluZ0NvbXBsZXRlUHJvbWlzZSxcbiAgICAgICAgbG9jazogKGxvY2tFbCkgPT4ge1xuICAgICAgICAgIHJldHVybiBuZXcgUHJvbWlzZSgocmVzb2x2ZSkgPT4ge1xuICAgICAgICAgICAgaWYgKHRoaXMuaXNBY2tlZChuZXdSZWYpKSB7XG4gICAgICAgICAgICAgIHJldHVybiByZXNvbHZlKGRldGFpbCk7XG4gICAgICAgICAgICB9XG4gICAgICAgICAgICBsb2NrRWwuc2V0QXR0cmlidXRlKFBIWF9SRUZfTE9DSywgbmV3UmVmKTtcbiAgICAgICAgICAgIGxvY2tFbC5zZXRBdHRyaWJ1dGUoUEhYX1JFRl9TUkMsIHRoaXMucmVmU3JjKCkpO1xuICAgICAgICAgICAgbG9ja0VsLmFkZEV2ZW50TGlzdGVuZXIoXG4gICAgICAgICAgICAgIGBwaHg6bG9jay1zdG9wOiR7bmV3UmVmfWAsXG4gICAgICAgICAgICAgICgpID0+IHJlc29sdmUoZGV0YWlsKSxcbiAgICAgICAgICAgICAgeyBvbmNlOiB0cnVlIH0sXG4gICAgICAgICAgICApO1xuICAgICAgICAgIH0pO1xuICAgICAgICB9LFxuICAgICAgfTtcbiAgICAgIGlmIChvcHRzLnBheWxvYWQpIHtcbiAgICAgICAgZGV0YWlsW1wicGF5bG9hZFwiXSA9IG9wdHMucGF5bG9hZDtcbiAgICAgIH1cbiAgICAgIGlmIChvcHRzLnRhcmdldCkge1xuICAgICAgICBkZXRhaWxbXCJ0YXJnZXRcIl0gPSBvcHRzLnRhcmdldDtcbiAgICAgIH1cbiAgICAgIGlmIChvcHRzLm9yaWdpbmFsRXZlbnQpIHtcbiAgICAgICAgZGV0YWlsW1wib3JpZ2luYWxFdmVudFwiXSA9IG9wdHMub3JpZ2luYWxFdmVudDtcbiAgICAgIH1cbiAgICAgIGVsLmRpc3BhdGNoRXZlbnQoXG4gICAgICAgIG5ldyBDdXN0b21FdmVudChcInBoeDpwdXNoXCIsIHtcbiAgICAgICAgICBkZXRhaWw6IGRldGFpbCxcbiAgICAgICAgICBidWJibGVzOiB0cnVlLFxuICAgICAgICAgIGNhbmNlbGFibGU6IGZhbHNlLFxuICAgICAgICB9KSxcbiAgICAgICk7XG4gICAgICBpZiAocGh4RXZlbnQpIHtcbiAgICAgICAgZWwuZGlzcGF0Y2hFdmVudChcbiAgICAgICAgICBuZXcgQ3VzdG9tRXZlbnQoYHBoeDpwdXNoOiR7cGh4RXZlbnR9YCwge1xuICAgICAgICAgICAgZGV0YWlsOiBkZXRhaWwsXG4gICAgICAgICAgICBidWJibGVzOiB0cnVlLFxuICAgICAgICAgICAgY2FuY2VsYWJsZTogZmFsc2UsXG4gICAgICAgICAgfSksXG4gICAgICAgICk7XG4gICAgICB9XG4gICAgfVxuICAgIHJldHVybiBbbmV3UmVmLCBlbGVtZW50cy5tYXAoKHsgZWwgfSkgPT4gZWwpLCBvcHRzXTtcbiAgfVxuXG4gIGlzQWNrZWQocmVmKSB7XG4gICAgcmV0dXJuIHRoaXMubGFzdEFja1JlZiAhPT0gbnVsbCAmJiB0aGlzLmxhc3RBY2tSZWYgPj0gcmVmO1xuICB9XG5cbiAgY29tcG9uZW50SUQoZWwpIHtcbiAgICBjb25zdCBjaWQgPSBlbC5nZXRBdHRyaWJ1dGUgJiYgZWwuZ2V0QXR0cmlidXRlKFBIWF9DT01QT05FTlQpO1xuICAgIHJldHVybiBjaWQgPyBwYXJzZUludChjaWQpIDogbnVsbDtcbiAgfVxuXG4gIHRhcmdldENvbXBvbmVudElEKHRhcmdldCwgdGFyZ2V0Q3R4LCBvcHRzID0ge30pIHtcbiAgICBpZiAoaXNDaWQodGFyZ2V0Q3R4KSkge1xuICAgICAgcmV0dXJuIHRhcmdldEN0eDtcbiAgICB9XG5cbiAgICBjb25zdCBjaWRPclNlbGVjdG9yID1cbiAgICAgIG9wdHMudGFyZ2V0IHx8IHRhcmdldC5nZXRBdHRyaWJ1dGUodGhpcy5iaW5kaW5nKFwidGFyZ2V0XCIpKTtcbiAgICBpZiAoaXNDaWQoY2lkT3JTZWxlY3RvcikpIHtcbiAgICAgIHJldHVybiBwYXJzZUludChjaWRPclNlbGVjdG9yKTtcbiAgICB9IGVsc2UgaWYgKHRhcmdldEN0eCAmJiAoY2lkT3JTZWxlY3RvciAhPT0gbnVsbCB8fCBvcHRzLnRhcmdldCkpIHtcbiAgICAgIHJldHVybiB0aGlzLmNsb3Nlc3RDb21wb25lbnRJRCh0YXJnZXRDdHgpO1xuICAgIH0gZWxzZSB7XG4gICAgICByZXR1cm4gbnVsbDtcbiAgICB9XG4gIH1cblxuICBjbG9zZXN0Q29tcG9uZW50SUQodGFyZ2V0Q3R4KSB7XG4gICAgaWYgKGlzQ2lkKHRhcmdldEN0eCkpIHtcbiAgICAgIHJldHVybiB0YXJnZXRDdHg7XG4gICAgfSBlbHNlIGlmICh0YXJnZXRDdHgpIHtcbiAgICAgIHJldHVybiBtYXliZShcbiAgICAgICAgdGFyZ2V0Q3R4LmNsb3Nlc3QoYFske1BIWF9DT01QT05FTlR9XWApLFxuICAgICAgICAoZWwpID0+IHRoaXMub3duc0VsZW1lbnQoZWwpICYmIHRoaXMuY29tcG9uZW50SUQoZWwpLFxuICAgICAgKTtcbiAgICB9IGVsc2Uge1xuICAgICAgcmV0dXJuIG51bGw7XG4gICAgfVxuICB9XG5cbiAgcHVzaEhvb2tFdmVudChlbCwgdGFyZ2V0Q3R4LCBldmVudCwgcGF5bG9hZCkge1xuICAgIGlmICghdGhpcy5pc0Nvbm5lY3RlZCgpKSB7XG4gICAgICB0aGlzLmxvZyhcImhvb2tcIiwgKCkgPT4gW1xuICAgICAgICBcInVuYWJsZSB0byBwdXNoIGhvb2sgZXZlbnQuIExpdmVWaWV3IG5vdCBjb25uZWN0ZWRcIixcbiAgICAgICAgZXZlbnQsXG4gICAgICAgIHBheWxvYWQsXG4gICAgICBdKTtcbiAgICAgIHJldHVybiBQcm9taXNlLnJlamVjdChcbiAgICAgICAgbmV3IEVycm9yKFwidW5hYmxlIHRvIHB1c2ggaG9vayBldmVudC4gTGl2ZVZpZXcgbm90IGNvbm5lY3RlZFwiKSxcbiAgICAgICk7XG4gICAgfVxuXG4gICAgY29uc3QgcmVmR2VuZXJhdG9yID0gKCkgPT5cbiAgICAgIHRoaXMucHV0UmVmKFt7IGVsLCBsb2FkaW5nOiB0cnVlLCBsb2NrOiB0cnVlIH1dLCBldmVudCwgXCJob29rXCIsIHtcbiAgICAgICAgcGF5bG9hZCxcbiAgICAgICAgdGFyZ2V0OiB0YXJnZXRDdHgsXG4gICAgICB9KTtcblxuICAgIHJldHVybiB0aGlzLnB1c2hXaXRoUmVwbHkocmVmR2VuZXJhdG9yLCBcImV2ZW50XCIsIHtcbiAgICAgIHR5cGU6IFwiaG9va1wiLFxuICAgICAgZXZlbnQ6IGV2ZW50LFxuICAgICAgdmFsdWU6IHBheWxvYWQsXG4gICAgICBjaWQ6IHRoaXMuY2xvc2VzdENvbXBvbmVudElEKHRhcmdldEN0eCksXG4gICAgfSkudGhlbigoeyByZXNwOiBfcmVzcCwgcmVwbHksIHJlZiB9KSA9PiAoeyByZXBseSwgcmVmIH0pKTtcbiAgfVxuXG4gIGV4dHJhY3RNZXRhKGVsLCBtZXRhLCB2YWx1ZSkge1xuICAgIGNvbnN0IHByZWZpeCA9IHRoaXMuYmluZGluZyhcInZhbHVlLVwiKTtcbiAgICBmb3IgKGxldCBpID0gMDsgaSA8IGVsLmF0dHJpYnV0ZXMubGVuZ3RoOyBpKyspIHtcbiAgICAgIGlmICghbWV0YSkge1xuICAgICAgICBtZXRhID0ge307XG4gICAgICB9XG4gICAgICBjb25zdCBuYW1lID0gZWwuYXR0cmlidXRlc1tpXS5uYW1lO1xuICAgICAgaWYgKG5hbWUuc3RhcnRzV2l0aChwcmVmaXgpKSB7XG4gICAgICAgIG1ldGFbbmFtZS5yZXBsYWNlKHByZWZpeCwgXCJcIildID0gZWwuZ2V0QXR0cmlidXRlKG5hbWUpO1xuICAgICAgfVxuICAgIH1cbiAgICBpZiAoZWwudmFsdWUgIT09IHVuZGVmaW5lZCAmJiAhKGVsIGluc3RhbmNlb2YgSFRNTEZvcm1FbGVtZW50KSkge1xuICAgICAgaWYgKCFtZXRhKSB7XG4gICAgICAgIG1ldGEgPSB7fTtcbiAgICAgIH1cbiAgICAgIG1ldGEudmFsdWUgPSBlbC52YWx1ZTtcblxuICAgICAgaWYgKFxuICAgICAgICBlbC50YWdOYW1lID09PSBcIklOUFVUXCIgJiZcbiAgICAgICAgQ0hFQ0tBQkxFX0lOUFVUUy5pbmRleE9mKGVsLnR5cGUpID49IDAgJiZcbiAgICAgICAgIWVsLmNoZWNrZWRcbiAgICAgICkge1xuICAgICAgICBkZWxldGUgbWV0YS52YWx1ZTtcbiAgICAgIH1cbiAgICB9XG4gICAgaWYgKHZhbHVlKSB7XG4gICAgICBpZiAoIW1ldGEpIHtcbiAgICAgICAgbWV0YSA9IHt9O1xuICAgICAgfVxuICAgICAgZm9yIChjb25zdCBrZXkgaW4gdmFsdWUpIHtcbiAgICAgICAgbWV0YVtrZXldID0gdmFsdWVba2V5XTtcbiAgICAgIH1cbiAgICB9XG4gICAgcmV0dXJuIG1ldGE7XG4gIH1cblxuICBwdXNoRXZlbnQodHlwZSwgZWwsIHRhcmdldEN0eCwgcGh4RXZlbnQsIG1ldGEsIG9wdHMgPSB7fSwgb25SZXBseSkge1xuICAgIHRoaXMucHVzaFdpdGhSZXBseShcbiAgICAgIChtYXliZVBheWxvYWQpID0+XG4gICAgICAgIHRoaXMucHV0UmVmKFt7IGVsLCBsb2FkaW5nOiB0cnVlLCBsb2NrOiB0cnVlIH1dLCBwaHhFdmVudCwgdHlwZSwge1xuICAgICAgICAgIC4uLm9wdHMsXG4gICAgICAgICAgcGF5bG9hZDogbWF5YmVQYXlsb2FkPy5wYXlsb2FkLFxuICAgICAgICB9KSxcbiAgICAgIFwiZXZlbnRcIixcbiAgICAgIHtcbiAgICAgICAgdHlwZTogdHlwZSxcbiAgICAgICAgZXZlbnQ6IHBoeEV2ZW50LFxuICAgICAgICB2YWx1ZTogdGhpcy5leHRyYWN0TWV0YShlbCwgbWV0YSwgb3B0cy52YWx1ZSksXG4gICAgICAgIGNpZDogdGhpcy50YXJnZXRDb21wb25lbnRJRChlbCwgdGFyZ2V0Q3R4LCBvcHRzKSxcbiAgICAgIH0sXG4gICAgKVxuICAgICAgLnRoZW4oKHsgcmVwbHkgfSkgPT4gb25SZXBseSAmJiBvblJlcGx5KHJlcGx5KSlcbiAgICAgIC5jYXRjaCgoZXJyb3IpID0+IGxvZ0Vycm9yKFwiRmFpbGVkIHRvIHB1c2ggZXZlbnRcIiwgZXJyb3IpKTtcbiAgfVxuXG4gIHB1c2hGaWxlUHJvZ3Jlc3MoZmlsZUVsLCBlbnRyeVJlZiwgcHJvZ3Jlc3MsIG9uUmVwbHkgPSBmdW5jdGlvbiAoKSB7fSkge1xuICAgIHRoaXMubGl2ZVNvY2tldC53aXRoaW5Pd25lcnMoZmlsZUVsLmZvcm0sICh2aWV3LCB0YXJnZXRDdHgpID0+IHtcbiAgICAgIHZpZXdcbiAgICAgICAgLnB1c2hXaXRoUmVwbHkobnVsbCwgXCJwcm9ncmVzc1wiLCB7XG4gICAgICAgICAgZXZlbnQ6IGZpbGVFbC5nZXRBdHRyaWJ1dGUodmlldy5iaW5kaW5nKFBIWF9QUk9HUkVTUykpLFxuICAgICAgICAgIHJlZjogZmlsZUVsLmdldEF0dHJpYnV0ZShQSFhfVVBMT0FEX1JFRiksXG4gICAgICAgICAgZW50cnlfcmVmOiBlbnRyeVJlZixcbiAgICAgICAgICBwcm9ncmVzczogcHJvZ3Jlc3MsXG4gICAgICAgICAgY2lkOiB2aWV3LnRhcmdldENvbXBvbmVudElEKGZpbGVFbC5mb3JtLCB0YXJnZXRDdHgpLFxuICAgICAgICB9KVxuICAgICAgICAudGhlbigoKSA9PiBvblJlcGx5KCkpXG4gICAgICAgIC5jYXRjaCgoZXJyb3IpID0+IGxvZ0Vycm9yKFwiRmFpbGVkIHRvIHB1c2ggZmlsZSBwcm9ncmVzc1wiLCBlcnJvcikpO1xuICAgIH0pO1xuICB9XG5cbiAgcHVzaElucHV0KGlucHV0RWwsIHRhcmdldEN0eCwgZm9yY2VDaWQsIHBoeEV2ZW50LCBvcHRzLCBjYWxsYmFjaykge1xuICAgIGlmICghaW5wdXRFbC5mb3JtKSB7XG4gICAgICB0aHJvdyBuZXcgRXJyb3IoXCJmb3JtIGV2ZW50cyByZXF1aXJlIHRoZSBpbnB1dCB0byBiZSBpbnNpZGUgYSBmb3JtXCIpO1xuICAgIH1cblxuICAgIGxldCB1cGxvYWRzO1xuICAgIGNvbnN0IGNpZCA9IGlzQ2lkKGZvcmNlQ2lkKVxuICAgICAgPyBmb3JjZUNpZFxuICAgICAgOiB0aGlzLnRhcmdldENvbXBvbmVudElEKGlucHV0RWwuZm9ybSwgdGFyZ2V0Q3R4LCBvcHRzKTtcbiAgICBjb25zdCByZWZHZW5lcmF0b3IgPSAobWF5YmVQYXlsb2FkKSA9PiB7XG4gICAgICByZXR1cm4gdGhpcy5wdXRSZWYoXG4gICAgICAgIFtcbiAgICAgICAgICB7IGVsOiBpbnB1dEVsLCBsb2FkaW5nOiB0cnVlLCBsb2NrOiB0cnVlIH0sXG4gICAgICAgICAgeyBlbDogaW5wdXRFbC5mb3JtLCBsb2FkaW5nOiB0cnVlLCBsb2NrOiB0cnVlIH0sXG4gICAgICAgIF0sXG4gICAgICAgIHBoeEV2ZW50LFxuICAgICAgICBcImNoYW5nZVwiLFxuICAgICAgICB7IC4uLm9wdHMsIHBheWxvYWQ6IG1heWJlUGF5bG9hZD8ucGF5bG9hZCB9LFxuICAgICAgKTtcbiAgICB9O1xuICAgIGxldCBmb3JtRGF0YTtcbiAgICBjb25zdCBtZXRhID0gdGhpcy5leHRyYWN0TWV0YShpbnB1dEVsLmZvcm0sIHt9LCBvcHRzLnZhbHVlKTtcbiAgICBjb25zdCBzZXJpYWxpemVPcHRzID0ge307XG4gICAgaWYgKGlucHV0RWwgaW5zdGFuY2VvZiBIVE1MQnV0dG9uRWxlbWVudCkge1xuICAgICAgc2VyaWFsaXplT3B0cy5zdWJtaXR0ZXIgPSBpbnB1dEVsO1xuICAgIH1cbiAgICBpZiAoaW5wdXRFbC5nZXRBdHRyaWJ1dGUodGhpcy5iaW5kaW5nKFwiY2hhbmdlXCIpKSkge1xuICAgICAgZm9ybURhdGEgPSBzZXJpYWxpemVGb3JtKGlucHV0RWwuZm9ybSwgc2VyaWFsaXplT3B0cywgW2lucHV0RWwubmFtZV0pO1xuICAgIH0gZWxzZSB7XG4gICAgICBmb3JtRGF0YSA9IHNlcmlhbGl6ZUZvcm0oaW5wdXRFbC5mb3JtLCBzZXJpYWxpemVPcHRzKTtcbiAgICB9XG4gICAgaWYgKFxuICAgICAgRE9NLmlzVXBsb2FkSW5wdXQoaW5wdXRFbCkgJiZcbiAgICAgIGlucHV0RWwuZmlsZXMgJiZcbiAgICAgIGlucHV0RWwuZmlsZXMubGVuZ3RoID4gMFxuICAgICkge1xuICAgICAgTGl2ZVVwbG9hZGVyLnRyYWNrRmlsZXMoaW5wdXRFbCwgQXJyYXkuZnJvbShpbnB1dEVsLmZpbGVzKSk7XG4gICAgfVxuICAgIHVwbG9hZHMgPSBMaXZlVXBsb2FkZXIuc2VyaWFsaXplVXBsb2FkcyhpbnB1dEVsKTtcblxuICAgIGNvbnN0IGV2ZW50ID0ge1xuICAgICAgdHlwZTogXCJmb3JtXCIsXG4gICAgICBldmVudDogcGh4RXZlbnQsXG4gICAgICB2YWx1ZTogZm9ybURhdGEsXG4gICAgICBtZXRhOiB7XG4gICAgICAgIC8vIG5vIHRhcmdldCB3YXMgaW1wbGljaXRseSBzZW50IGFzIFwidW5kZWZpbmVkXCIgaW4gTFYgPD0gMS4wLjUsIHRoZXJlZm9yZVxuICAgICAgICAvLyB3ZSBoYXZlIHRvIGtlZXAgaXQuIEluIDEuMC42IHdlIHN3aXRjaGVkIGZyb20gcGFzc2luZyBtZXRhIGFzIFVSTCBlbmNvZGVkIGRhdGFcbiAgICAgICAgLy8gdG8gcGFzc2luZyBpdCBkaXJlY3RseSBpbiB0aGUgZXZlbnQsIGJ1dCB0aGUgSlNPTiBlbmNvZGUgd291bGQgZHJvcCBrZXlzIHdpdGhcbiAgICAgICAgLy8gdW5kZWZpbmVkIHZhbHVlcy5cbiAgICAgICAgX3RhcmdldDogb3B0cy5fdGFyZ2V0IHx8IFwidW5kZWZpbmVkXCIsXG4gICAgICAgIC4uLm1ldGEsXG4gICAgICB9LFxuICAgICAgdXBsb2FkczogdXBsb2FkcyxcbiAgICAgIGNpZDogY2lkLFxuICAgIH07XG4gICAgdGhpcy5wdXNoV2l0aFJlcGx5KHJlZkdlbmVyYXRvciwgXCJldmVudFwiLCBldmVudClcbiAgICAgIC50aGVuKCh7IHJlc3AgfSkgPT4ge1xuICAgICAgICBpZiAoRE9NLmlzVXBsb2FkSW5wdXQoaW5wdXRFbCkgJiYgRE9NLmlzQXV0b1VwbG9hZChpbnB1dEVsKSkge1xuICAgICAgICAgIC8vIHRoZSBlbGVtZW50IGNvdWxkIGJlIGluc2lkZSBhIGxvY2tlZCBwYXJlbnQgZm9yIG90aGVyIHVucmVsYXRlZCBjaGFuZ2VzO1xuICAgICAgICAgIC8vIHdlIGNhbiBvbmx5IHN0YXJ0IHVwbG9hZHMgd2hlbiB0aGUgdHJlZSBpcyB1bmxvY2tlZCBhbmQgdGhlXG4gICAgICAgICAgLy8gbmVjZXNzYXJ5IGRhdGEgYXR0cmlidXRlcyBhcmUgc2V0IGluIHRoZSByZWFsIERPTVxuICAgICAgICAgIEVsZW1lbnRSZWYub25VbmxvY2soaW5wdXRFbCwgKCkgPT4ge1xuICAgICAgICAgICAgaWYgKExpdmVVcGxvYWRlci5maWxlc0F3YWl0aW5nUHJlZmxpZ2h0KGlucHV0RWwpLmxlbmd0aCA+IDApIHtcbiAgICAgICAgICAgICAgY29uc3QgW3JlZiwgX2Vsc10gPSByZWZHZW5lcmF0b3IoKTtcbiAgICAgICAgICAgICAgdGhpcy51bmRvUmVmcyhyZWYsIHBoeEV2ZW50LCBbaW5wdXRFbC5mb3JtXSk7XG4gICAgICAgICAgICAgIHRoaXMudXBsb2FkRmlsZXMoXG4gICAgICAgICAgICAgICAgaW5wdXRFbC5mb3JtLFxuICAgICAgICAgICAgICAgIHBoeEV2ZW50LFxuICAgICAgICAgICAgICAgIHRhcmdldEN0eCxcbiAgICAgICAgICAgICAgICByZWYsXG4gICAgICAgICAgICAgICAgY2lkLFxuICAgICAgICAgICAgICAgIChfdXBsb2FkcykgPT4ge1xuICAgICAgICAgICAgICAgICAgY2FsbGJhY2sgJiYgY2FsbGJhY2socmVzcCk7XG4gICAgICAgICAgICAgICAgICB0aGlzLnRyaWdnZXJBd2FpdGluZ1N1Ym1pdChpbnB1dEVsLmZvcm0sIHBoeEV2ZW50KTtcbiAgICAgICAgICAgICAgICAgIHRoaXMudW5kb1JlZnMocmVmLCBwaHhFdmVudCk7XG4gICAgICAgICAgICAgICAgfSxcbiAgICAgICAgICAgICAgKTtcbiAgICAgICAgICAgIH1cbiAgICAgICAgICB9KTtcbiAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICBjYWxsYmFjayAmJiBjYWxsYmFjayhyZXNwKTtcbiAgICAgICAgfVxuICAgICAgfSlcbiAgICAgIC5jYXRjaCgoZXJyb3IpID0+IGxvZ0Vycm9yKFwiRmFpbGVkIHRvIHB1c2ggaW5wdXQgZXZlbnRcIiwgZXJyb3IpKTtcbiAgfVxuXG4gIHRyaWdnZXJBd2FpdGluZ1N1Ym1pdChmb3JtRWwsIHBoeEV2ZW50KSB7XG4gICAgY29uc3QgYXdhaXRpbmdTdWJtaXQgPSB0aGlzLmdldFNjaGVkdWxlZFN1Ym1pdChmb3JtRWwpO1xuICAgIGlmIChhd2FpdGluZ1N1Ym1pdCkge1xuICAgICAgY29uc3QgW19lbCwgX3JlZiwgX29wdHMsIGNhbGxiYWNrXSA9IGF3YWl0aW5nU3VibWl0O1xuICAgICAgdGhpcy5jYW5jZWxTdWJtaXQoZm9ybUVsLCBwaHhFdmVudCk7XG4gICAgICBjYWxsYmFjaygpO1xuICAgIH1cbiAgfVxuXG4gIGdldFNjaGVkdWxlZFN1Ym1pdChmb3JtRWwpIHtcbiAgICByZXR1cm4gdGhpcy5mb3JtU3VibWl0cy5maW5kKChbZWwsIF9yZWYsIF9vcHRzLCBfY2FsbGJhY2tdKSA9PlxuICAgICAgZWwuaXNTYW1lTm9kZShmb3JtRWwpLFxuICAgICk7XG4gIH1cblxuICBzY2hlZHVsZVN1Ym1pdChmb3JtRWwsIHJlZiwgb3B0cywgY2FsbGJhY2spIHtcbiAgICBpZiAodGhpcy5nZXRTY2hlZHVsZWRTdWJtaXQoZm9ybUVsKSkge1xuICAgICAgcmV0dXJuIHRydWU7XG4gICAgfVxuICAgIHRoaXMuZm9ybVN1Ym1pdHMucHVzaChbZm9ybUVsLCByZWYsIG9wdHMsIGNhbGxiYWNrXSk7XG4gIH1cblxuICBjYW5jZWxTdWJtaXQoZm9ybUVsLCBwaHhFdmVudCkge1xuICAgIHRoaXMuZm9ybVN1Ym1pdHMgPSB0aGlzLmZvcm1TdWJtaXRzLmZpbHRlcihcbiAgICAgIChbZWwsIHJlZiwgX29wdHMsIF9jYWxsYmFja10pID0+IHtcbiAgICAgICAgaWYgKGVsLmlzU2FtZU5vZGUoZm9ybUVsKSkge1xuICAgICAgICAgIHRoaXMudW5kb1JlZnMocmVmLCBwaHhFdmVudCk7XG4gICAgICAgICAgcmV0dXJuIGZhbHNlO1xuICAgICAgICB9IGVsc2Uge1xuICAgICAgICAgIHJldHVybiB0cnVlO1xuICAgICAgICB9XG4gICAgICB9LFxuICAgICk7XG4gIH1cblxuICBkaXNhYmxlRm9ybShmb3JtRWwsIHBoeEV2ZW50LCBvcHRzID0ge30pIHtcbiAgICBjb25zdCBmaWx0ZXJJZ25vcmVkID0gKGVsKSA9PiB7XG4gICAgICBjb25zdCB1c2VySWdub3JlZCA9IGNsb3Nlc3RQaHhCaW5kaW5nKFxuICAgICAgICBlbCxcbiAgICAgICAgYCR7dGhpcy5iaW5kaW5nKFBIWF9VUERBVEUpfT1pZ25vcmVgLFxuICAgICAgICBlbC5mb3JtLFxuICAgICAgKTtcbiAgICAgIHJldHVybiAhKFxuICAgICAgICB1c2VySWdub3JlZCB8fCBjbG9zZXN0UGh4QmluZGluZyhlbCwgXCJkYXRhLXBoeC11cGRhdGU9aWdub3JlXCIsIGVsLmZvcm0pXG4gICAgICApO1xuICAgIH07XG4gICAgY29uc3QgZmlsdGVyRGlzYWJsZXMgPSAoZWwpID0+IHtcbiAgICAgIHJldHVybiBlbC5oYXNBdHRyaWJ1dGUodGhpcy5iaW5kaW5nKFBIWF9ESVNBQkxFX1dJVEgpKTtcbiAgICB9O1xuICAgIGNvbnN0IGZpbHRlckJ1dHRvbiA9IChlbCkgPT4gZWwudGFnTmFtZSA9PSBcIkJVVFRPTlwiO1xuXG4gICAgY29uc3QgZmlsdGVySW5wdXQgPSAoZWwpID0+XG4gICAgICBbXCJJTlBVVFwiLCBcIlRFWFRBUkVBXCIsIFwiU0VMRUNUXCJdLmluY2x1ZGVzKGVsLnRhZ05hbWUpO1xuXG4gICAgY29uc3QgZm9ybUVsZW1lbnRzID0gQXJyYXkuZnJvbShmb3JtRWwuZWxlbWVudHMpO1xuICAgIGNvbnN0IGRpc2FibGVzID0gZm9ybUVsZW1lbnRzLmZpbHRlcihmaWx0ZXJEaXNhYmxlcyk7XG4gICAgY29uc3QgYnV0dG9ucyA9IGZvcm1FbGVtZW50cy5maWx0ZXIoZmlsdGVyQnV0dG9uKS5maWx0ZXIoZmlsdGVySWdub3JlZCk7XG4gICAgY29uc3QgaW5wdXRzID0gZm9ybUVsZW1lbnRzLmZpbHRlcihmaWx0ZXJJbnB1dCkuZmlsdGVyKGZpbHRlcklnbm9yZWQpO1xuXG4gICAgYnV0dG9ucy5mb3JFYWNoKChidXR0b24pID0+IHtcbiAgICAgIGJ1dHRvbi5zZXRBdHRyaWJ1dGUoUEhYX0RJU0FCTEVELCBidXR0b24uZGlzYWJsZWQpO1xuICAgICAgYnV0dG9uLmRpc2FibGVkID0gdHJ1ZTtcbiAgICB9KTtcbiAgICBpbnB1dHMuZm9yRWFjaCgoaW5wdXQpID0+IHtcbiAgICAgIGlucHV0LnNldEF0dHJpYnV0ZShQSFhfUkVBRE9OTFksIGlucHV0LnJlYWRPbmx5KTtcbiAgICAgIGlucHV0LnJlYWRPbmx5ID0gdHJ1ZTtcbiAgICAgIGlmIChpbnB1dC5maWxlcykge1xuICAgICAgICBpbnB1dC5zZXRBdHRyaWJ1dGUoUEhYX0RJU0FCTEVELCBpbnB1dC5kaXNhYmxlZCk7XG4gICAgICAgIGlucHV0LmRpc2FibGVkID0gdHJ1ZTtcbiAgICAgIH1cbiAgICB9KTtcbiAgICBjb25zdCBmb3JtRWxzID0gZGlzYWJsZXNcbiAgICAgIC5jb25jYXQoYnV0dG9ucylcbiAgICAgIC5jb25jYXQoaW5wdXRzKVxuICAgICAgLm1hcCgoZWwpID0+IHtcbiAgICAgICAgcmV0dXJuIHsgZWwsIGxvYWRpbmc6IHRydWUsIGxvY2s6IHRydWUgfTtcbiAgICAgIH0pO1xuXG4gICAgLy8gd2UgcmV2ZXJzZSB0aGUgb3JkZXIgc28gZm9ybSBjaGlsZHJlbiBhcmUgYWxyZWFkeSBsb2NrZWQgYnkgdGhlIHRpbWVcbiAgICAvLyB0aGUgZm9ybSBpcyBsb2NrZWRcbiAgICBjb25zdCBlbHMgPSBbeyBlbDogZm9ybUVsLCBsb2FkaW5nOiB0cnVlLCBsb2NrOiBmYWxzZSB9XVxuICAgICAgLmNvbmNhdChmb3JtRWxzKVxuICAgICAgLnJldmVyc2UoKTtcbiAgICByZXR1cm4gdGhpcy5wdXRSZWYoZWxzLCBwaHhFdmVudCwgXCJzdWJtaXRcIiwgb3B0cyk7XG4gIH1cblxuICBwdXNoRm9ybVN1Ym1pdChmb3JtRWwsIHRhcmdldEN0eCwgcGh4RXZlbnQsIHN1Ym1pdHRlciwgb3B0cywgb25SZXBseSkge1xuICAgIGNvbnN0IHJlZkdlbmVyYXRvciA9IChtYXliZVBheWxvYWQpID0+XG4gICAgICB0aGlzLmRpc2FibGVGb3JtKGZvcm1FbCwgcGh4RXZlbnQsIHtcbiAgICAgICAgLi4ub3B0cyxcbiAgICAgICAgZm9ybTogZm9ybUVsLFxuICAgICAgICBwYXlsb2FkOiBtYXliZVBheWxvYWQ/LnBheWxvYWQsXG4gICAgICAgIHN1Ym1pdHRlcjogc3VibWl0dGVyLFxuICAgICAgfSk7XG4gICAgLy8gc3RvcmUgdGhlIHN1Ym1pdHRlciBpbiB0aGUgZm9ybSBlbGVtZW50IGluIG9yZGVyIHRvIHRyaWdnZXIgaXRcbiAgICAvLyBmb3IgcGh4LXRyaWdnZXItYWN0aW9uXG4gICAgRE9NLnB1dFByaXZhdGUoZm9ybUVsLCBcInN1Ym1pdHRlclwiLCBzdWJtaXR0ZXIpO1xuICAgIGNvbnN0IGNpZCA9IHRoaXMudGFyZ2V0Q29tcG9uZW50SUQoZm9ybUVsLCB0YXJnZXRDdHgpO1xuICAgIGlmIChMaXZlVXBsb2FkZXIuaGFzVXBsb2Fkc0luUHJvZ3Jlc3MoZm9ybUVsKSkge1xuICAgICAgY29uc3QgW3JlZiwgX2Vsc10gPSByZWZHZW5lcmF0b3IoKTtcbiAgICAgIGNvbnN0IHB1c2ggPSAoKSA9PlxuICAgICAgICB0aGlzLnB1c2hGb3JtU3VibWl0KFxuICAgICAgICAgIGZvcm1FbCxcbiAgICAgICAgICB0YXJnZXRDdHgsXG4gICAgICAgICAgcGh4RXZlbnQsXG4gICAgICAgICAgc3VibWl0dGVyLFxuICAgICAgICAgIG9wdHMsXG4gICAgICAgICAgb25SZXBseSxcbiAgICAgICAgKTtcbiAgICAgIHJldHVybiB0aGlzLnNjaGVkdWxlU3VibWl0KGZvcm1FbCwgcmVmLCBvcHRzLCBwdXNoKTtcbiAgICB9IGVsc2UgaWYgKExpdmVVcGxvYWRlci5pbnB1dHNBd2FpdGluZ1ByZWZsaWdodChmb3JtRWwpLmxlbmd0aCA+IDApIHtcbiAgICAgIGNvbnN0IFtyZWYsIGVsc10gPSByZWZHZW5lcmF0b3IoKTtcbiAgICAgIGNvbnN0IHByb3h5UmVmR2VuID0gKCkgPT4gW3JlZiwgZWxzLCBvcHRzXTtcbiAgICAgIHRoaXMudXBsb2FkRmlsZXMoZm9ybUVsLCBwaHhFdmVudCwgdGFyZ2V0Q3R4LCByZWYsIGNpZCwgKF91cGxvYWRzKSA9PiB7XG4gICAgICAgIC8vIGlmIHdlIHN0aWxsIGhhdmluZyBwZW5kaW5nIHByZWZsaWdodHMgaXQgbWVhbnMgd2UgaGF2ZSBpbnZhbGlkIGVudHJpZXNcbiAgICAgICAgLy8gYW5kIHRoZSBwaHgtc3VibWl0IGNhbm5vdCBiZSBjb21wbGV0ZWRcbiAgICAgICAgaWYgKExpdmVVcGxvYWRlci5pbnB1dHNBd2FpdGluZ1ByZWZsaWdodChmb3JtRWwpLmxlbmd0aCA+IDApIHtcbiAgICAgICAgICByZXR1cm4gdGhpcy51bmRvUmVmcyhyZWYsIHBoeEV2ZW50KTtcbiAgICAgICAgfVxuICAgICAgICBjb25zdCBtZXRhID0gdGhpcy5leHRyYWN0TWV0YShmb3JtRWwsIHt9LCBvcHRzLnZhbHVlKTtcbiAgICAgICAgY29uc3QgZm9ybURhdGEgPSBzZXJpYWxpemVGb3JtKGZvcm1FbCwgeyBzdWJtaXR0ZXIgfSk7XG4gICAgICAgIHRoaXMucHVzaFdpdGhSZXBseShwcm94eVJlZkdlbiwgXCJldmVudFwiLCB7XG4gICAgICAgICAgdHlwZTogXCJmb3JtXCIsXG4gICAgICAgICAgZXZlbnQ6IHBoeEV2ZW50LFxuICAgICAgICAgIHZhbHVlOiBmb3JtRGF0YSxcbiAgICAgICAgICBtZXRhOiBtZXRhLFxuICAgICAgICAgIGNpZDogY2lkLFxuICAgICAgICB9KVxuICAgICAgICAgIC50aGVuKCh7IHJlc3AgfSkgPT4gb25SZXBseShyZXNwKSlcbiAgICAgICAgICAuY2F0Y2goKGVycm9yKSA9PiBsb2dFcnJvcihcIkZhaWxlZCB0byBwdXNoIGZvcm0gc3VibWl0XCIsIGVycm9yKSk7XG4gICAgICB9KTtcbiAgICB9IGVsc2UgaWYgKFxuICAgICAgIShcbiAgICAgICAgZm9ybUVsLmhhc0F0dHJpYnV0ZShQSFhfUkVGX1NSQykgJiZcbiAgICAgICAgZm9ybUVsLmNsYXNzTGlzdC5jb250YWlucyhcInBoeC1zdWJtaXQtbG9hZGluZ1wiKVxuICAgICAgKVxuICAgICkge1xuICAgICAgY29uc3QgbWV0YSA9IHRoaXMuZXh0cmFjdE1ldGEoZm9ybUVsLCB7fSwgb3B0cy52YWx1ZSk7XG4gICAgICBjb25zdCBmb3JtRGF0YSA9IHNlcmlhbGl6ZUZvcm0oZm9ybUVsLCB7IHN1Ym1pdHRlciB9KTtcbiAgICAgIHRoaXMucHVzaFdpdGhSZXBseShyZWZHZW5lcmF0b3IsIFwiZXZlbnRcIiwge1xuICAgICAgICB0eXBlOiBcImZvcm1cIixcbiAgICAgICAgZXZlbnQ6IHBoeEV2ZW50LFxuICAgICAgICB2YWx1ZTogZm9ybURhdGEsXG4gICAgICAgIG1ldGE6IG1ldGEsXG4gICAgICAgIGNpZDogY2lkLFxuICAgICAgfSlcbiAgICAgICAgLnRoZW4oKHsgcmVzcCB9KSA9PiBvblJlcGx5KHJlc3ApKVxuICAgICAgICAuY2F0Y2goKGVycm9yKSA9PiBsb2dFcnJvcihcIkZhaWxlZCB0byBwdXNoIGZvcm0gc3VibWl0XCIsIGVycm9yKSk7XG4gICAgfVxuICB9XG5cbiAgdXBsb2FkRmlsZXMoZm9ybUVsLCBwaHhFdmVudCwgdGFyZ2V0Q3R4LCByZWYsIGNpZCwgb25Db21wbGV0ZSkge1xuICAgIGNvbnN0IGpvaW5Db3VudEF0VXBsb2FkID0gdGhpcy5qb2luQ291bnQ7XG4gICAgY29uc3QgaW5wdXRFbHMgPSBMaXZlVXBsb2FkZXIuYWN0aXZlRmlsZUlucHV0cyhmb3JtRWwpO1xuICAgIGxldCBudW1GaWxlSW5wdXRzSW5Qcm9ncmVzcyA9IGlucHV0RWxzLmxlbmd0aDtcblxuICAgIC8vIGdldCBlYWNoIGZpbGUgaW5wdXRcbiAgICBpbnB1dEVscy5mb3JFYWNoKChpbnB1dEVsKSA9PiB7XG4gICAgICBjb25zdCB1cGxvYWRlciA9IG5ldyBMaXZlVXBsb2FkZXIoaW5wdXRFbCwgdGhpcywgKCkgPT4ge1xuICAgICAgICBudW1GaWxlSW5wdXRzSW5Qcm9ncmVzcy0tO1xuICAgICAgICBpZiAobnVtRmlsZUlucHV0c0luUHJvZ3Jlc3MgPT09IDApIHtcbiAgICAgICAgICBvbkNvbXBsZXRlKCk7XG4gICAgICAgIH1cbiAgICAgIH0pO1xuXG4gICAgICBjb25zdCBlbnRyaWVzID0gdXBsb2FkZXJcbiAgICAgICAgLmVudHJpZXMoKVxuICAgICAgICAubWFwKChlbnRyeSkgPT4gZW50cnkudG9QcmVmbGlnaHRQYXlsb2FkKCkpO1xuXG4gICAgICBpZiAoZW50cmllcy5sZW5ndGggPT09IDApIHtcbiAgICAgICAgbnVtRmlsZUlucHV0c0luUHJvZ3Jlc3MtLTtcbiAgICAgICAgcmV0dXJuO1xuICAgICAgfVxuXG4gICAgICBjb25zdCBwYXlsb2FkID0ge1xuICAgICAgICByZWY6IGlucHV0RWwuZ2V0QXR0cmlidXRlKFBIWF9VUExPQURfUkVGKSxcbiAgICAgICAgZW50cmllczogZW50cmllcyxcbiAgICAgICAgY2lkOiB0aGlzLnRhcmdldENvbXBvbmVudElEKGlucHV0RWwuZm9ybSwgdGFyZ2V0Q3R4KSxcbiAgICAgIH07XG5cbiAgICAgIHRoaXMubG9nKFwidXBsb2FkXCIsICgpID0+IFtcInNlbmRpbmcgcHJlZmxpZ2h0IHJlcXVlc3RcIiwgcGF5bG9hZF0pO1xuXG4gICAgICB0aGlzLnB1c2hXaXRoUmVwbHkobnVsbCwgXCJhbGxvd191cGxvYWRcIiwgcGF5bG9hZClcbiAgICAgICAgLnRoZW4oKHsgcmVzcCB9KSA9PiB7XG4gICAgICAgICAgdGhpcy5sb2coXCJ1cGxvYWRcIiwgKCkgPT4gW1wiZ290IHByZWZsaWdodCByZXNwb25zZVwiLCByZXNwXSk7XG4gICAgICAgICAgLy8gdGhlIHByZWZsaWdodCB3aWxsIHJlamVjdCBlbnRyaWVzIGJleW9uZCB0aGUgbWF4IGVudHJpZXNcbiAgICAgICAgICAvLyBzbyB3ZSBlcnJvciBhbmQgY2FuY2VsIGVudHJpZXMgb24gdGhlIGNsaWVudCB0aGF0IGFyZSBtaXNzaW5nIGZyb20gdGhlIHJlc3BvbnNlXG4gICAgICAgICAgdXBsb2FkZXIuZW50cmllcygpLmZvckVhY2goKGVudHJ5KSA9PiB7XG4gICAgICAgICAgICBpZiAocmVzcC5lbnRyaWVzICYmICFyZXNwLmVudHJpZXNbZW50cnkucmVmXSkge1xuICAgICAgICAgICAgICB0aGlzLmhhbmRsZUZhaWxlZEVudHJ5UHJlZmxpZ2h0KFxuICAgICAgICAgICAgICAgIGVudHJ5LnJlZixcbiAgICAgICAgICAgICAgICBcImZhaWxlZCBwcmVmbGlnaHRcIixcbiAgICAgICAgICAgICAgICB1cGxvYWRlcixcbiAgICAgICAgICAgICAgKTtcbiAgICAgICAgICAgIH1cbiAgICAgICAgICB9KTtcbiAgICAgICAgICAvLyBmb3IgYXV0byB1cGxvYWRzLCB3ZSBtYXkgaGF2ZSBhbiBlbXB0eSBlbnRyaWVzIHJlc3BvbnNlIGZyb20gdGhlIHNlcnZlclxuICAgICAgICAgIC8vIGZvciBmb3JtIHN1Ym1pdHMgdGhhdCBjb250YWluIGludmFsaWQgZW50cmllc1xuICAgICAgICAgIGlmIChyZXNwLmVycm9yIHx8IE9iamVjdC5rZXlzKHJlc3AuZW50cmllcykubGVuZ3RoID09PSAwKSB7XG4gICAgICAgICAgICB0aGlzLnVuZG9SZWZzKHJlZiwgcGh4RXZlbnQpO1xuICAgICAgICAgICAgY29uc3QgZXJyb3JzID0gcmVzcC5lcnJvciB8fCBbXTtcbiAgICAgICAgICAgIGVycm9ycy5tYXAoKFtlbnRyeV9yZWYsIHJlYXNvbl0pID0+IHtcbiAgICAgICAgICAgICAgdGhpcy5oYW5kbGVGYWlsZWRFbnRyeVByZWZsaWdodChlbnRyeV9yZWYsIHJlYXNvbiwgdXBsb2FkZXIpO1xuICAgICAgICAgICAgfSk7XG4gICAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAgIGNvbnN0IG9uRXJyb3IgPSAoY2FsbGJhY2spID0+IHtcbiAgICAgICAgICAgICAgdGhpcy5jaGFubmVsLm9uRXJyb3IoKCkgPT4ge1xuICAgICAgICAgICAgICAgIGlmICh0aGlzLmpvaW5Db3VudCA9PT0gam9pbkNvdW50QXRVcGxvYWQpIHtcbiAgICAgICAgICAgICAgICAgIGNhbGxiYWNrKCk7XG4gICAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgICB9KTtcbiAgICAgICAgICAgIH07XG4gICAgICAgICAgICB1cGxvYWRlci5pbml0QWRhcHRlclVwbG9hZChyZXNwLCBvbkVycm9yLCB0aGlzLmxpdmVTb2NrZXQpO1xuICAgICAgICAgIH1cbiAgICAgICAgfSlcbiAgICAgICAgLmNhdGNoKChlcnJvcikgPT4gbG9nRXJyb3IoXCJGYWlsZWQgdG8gcHVzaCB1cGxvYWRcIiwgZXJyb3IpKTtcbiAgICB9KTtcbiAgfVxuXG4gIGhhbmRsZUZhaWxlZEVudHJ5UHJlZmxpZ2h0KHVwbG9hZFJlZiwgcmVhc29uLCB1cGxvYWRlcikge1xuICAgIGlmICh1cGxvYWRlci5pc0F1dG9VcGxvYWQoKSkge1xuICAgICAgLy8gdXBsb2FkUmVmIG1heSBiZSB0b3AgbGV2ZWwgdXBsb2FkIGNvbmZpZyByZWYgb3IgZW50cnkgcmVmXG4gICAgICBjb25zdCBlbnRyeSA9IHVwbG9hZGVyXG4gICAgICAgIC5lbnRyaWVzKClcbiAgICAgICAgLmZpbmQoKGVudHJ5KSA9PiBlbnRyeS5yZWYgPT09IHVwbG9hZFJlZi50b1N0cmluZygpKTtcbiAgICAgIGlmIChlbnRyeSkge1xuICAgICAgICBlbnRyeS5jYW5jZWwoKTtcbiAgICAgIH1cbiAgICB9IGVsc2Uge1xuICAgICAgdXBsb2FkZXIuZW50cmllcygpLm1hcCgoZW50cnkpID0+IGVudHJ5LmNhbmNlbCgpKTtcbiAgICB9XG4gICAgdGhpcy5sb2coXCJ1cGxvYWRcIiwgKCkgPT4gW2BlcnJvciBmb3IgZW50cnkgJHt1cGxvYWRSZWZ9YCwgcmVhc29uXSk7XG4gIH1cblxuICBkaXNwYXRjaFVwbG9hZHModGFyZ2V0Q3R4LCBuYW1lLCBmaWxlc09yQmxvYnMpIHtcbiAgICBjb25zdCB0YXJnZXRFbGVtZW50ID0gdGhpcy50YXJnZXRDdHhFbGVtZW50KHRhcmdldEN0eCkgfHwgdGhpcy5lbDtcbiAgICBjb25zdCBpbnB1dHMgPSBET00uZmluZFVwbG9hZElucHV0cyh0YXJnZXRFbGVtZW50KS5maWx0ZXIoXG4gICAgICAoZWwpID0+IGVsLm5hbWUgPT09IG5hbWUsXG4gICAgKTtcbiAgICBpZiAoaW5wdXRzLmxlbmd0aCA9PT0gMCkge1xuICAgICAgbG9nRXJyb3IoYG5vIGxpdmUgZmlsZSBpbnB1dHMgZm91bmQgbWF0Y2hpbmcgdGhlIG5hbWUgXCIke25hbWV9XCJgKTtcbiAgICB9IGVsc2UgaWYgKGlucHV0cy5sZW5ndGggPiAxKSB7XG4gICAgICBsb2dFcnJvcihgZHVwbGljYXRlIGxpdmUgZmlsZSBpbnB1dHMgZm91bmQgbWF0Y2hpbmcgdGhlIG5hbWUgXCIke25hbWV9XCJgKTtcbiAgICB9IGVsc2Uge1xuICAgICAgRE9NLmRpc3BhdGNoRXZlbnQoaW5wdXRzWzBdLCBQSFhfVFJBQ0tfVVBMT0FEUywge1xuICAgICAgICBkZXRhaWw6IHsgZmlsZXM6IGZpbGVzT3JCbG9icyB9LFxuICAgICAgfSk7XG4gICAgfVxuICB9XG5cbiAgdGFyZ2V0Q3R4RWxlbWVudCh0YXJnZXRDdHgpIHtcbiAgICBpZiAoaXNDaWQodGFyZ2V0Q3R4KSkge1xuICAgICAgY29uc3QgW3RhcmdldF0gPSBET00uZmluZENvbXBvbmVudE5vZGVMaXN0KHRoaXMuaWQsIHRhcmdldEN0eCk7XG4gICAgICByZXR1cm4gdGFyZ2V0O1xuICAgIH0gZWxzZSBpZiAodGFyZ2V0Q3R4KSB7XG4gICAgICByZXR1cm4gdGFyZ2V0Q3R4O1xuICAgIH0gZWxzZSB7XG4gICAgICByZXR1cm4gbnVsbDtcbiAgICB9XG4gIH1cblxuICBwdXNoRm9ybVJlY292ZXJ5KG9sZEZvcm0sIG5ld0Zvcm0sIHRlbXBsYXRlRG9tLCBjYWxsYmFjaykge1xuICAgIC8vIHdlIGFyZSBvbmx5IHJlY292ZXJpbmcgZm9ybXMgaW5zaWRlIHRoZSBjdXJyZW50IHZpZXcsIHRoZXJlZm9yZSBpdCBpcyBzYWZlIHRvXG4gICAgLy8gc2tpcCB3aXRoaW5Pd25lcnMgaGVyZSBhbmQgYWx3YXlzIHVzZSB0aGlzIHdoZW4gcmVmZXJyaW5nIHRvIHRoZSB2aWV3XG4gICAgY29uc3QgcGh4Q2hhbmdlID0gdGhpcy5iaW5kaW5nKFwiY2hhbmdlXCIpO1xuICAgIGNvbnN0IHBoeFRhcmdldCA9IG5ld0Zvcm0uZ2V0QXR0cmlidXRlKHRoaXMuYmluZGluZyhcInRhcmdldFwiKSkgfHwgbmV3Rm9ybTtcbiAgICBjb25zdCBwaHhFdmVudCA9XG4gICAgICBuZXdGb3JtLmdldEF0dHJpYnV0ZSh0aGlzLmJpbmRpbmcoUEhYX0FVVE9fUkVDT1ZFUikpIHx8XG4gICAgICBuZXdGb3JtLmdldEF0dHJpYnV0ZSh0aGlzLmJpbmRpbmcoXCJjaGFuZ2VcIikpO1xuICAgIGNvbnN0IGlucHV0cyA9IEFycmF5LmZyb20ob2xkRm9ybS5lbGVtZW50cykuZmlsdGVyKFxuICAgICAgKGVsKSA9PiBET00uaXNGb3JtSW5wdXQoZWwpICYmIGVsLm5hbWUgJiYgIWVsLmhhc0F0dHJpYnV0ZShwaHhDaGFuZ2UpLFxuICAgICk7XG4gICAgaWYgKGlucHV0cy5sZW5ndGggPT09IDApIHtcbiAgICAgIGNhbGxiYWNrKCk7XG4gICAgICByZXR1cm47XG4gICAgfVxuXG4gICAgLy8gd2UgbXVzdCBjbGVhciB0cmFja2VkIHVwbG9hZHMgYmVmb3JlIHJlY292ZXJ5IGFzIHRoZXkgbm8gbG9uZ2VyIGhhdmUgdmFsaWQgcmVmc1xuICAgIGlucHV0cy5mb3JFYWNoKFxuICAgICAgKGlucHV0KSA9PlxuICAgICAgICBpbnB1dC5oYXNBdHRyaWJ1dGUoUEhYX1VQTE9BRF9SRUYpICYmIExpdmVVcGxvYWRlci5jbGVhckZpbGVzKGlucHV0KSxcbiAgICApO1xuICAgIC8vIHB1c2hJbnB1dCBhc3N1bWVzIHRoYXQgdGhlcmUgaXMgYSBzb3VyY2UgZWxlbWVudCB0aGF0IGluaXRpYXRlZCB0aGUgY2hhbmdlO1xuICAgIC8vIGJlY2F1c2UgdGhpcyBpcyBub3QgdGhlIGNhc2Ugd2hlbiB3ZSByZWNvdmVyIGZvcm1zLCB3ZSBwcm92aWRlIHRoZSBmaXJzdCBpbnB1dCB3ZSBmaW5kXG4gICAgY29uc3QgaW5wdXQgPSBpbnB1dHMuZmluZCgoZWwpID0+IGVsLnR5cGUgIT09IFwiaGlkZGVuXCIpIHx8IGlucHV0c1swXTtcblxuICAgIC8vIGluIHRoZSBjYXNlIHRoYXQgdGhlcmUgYXJlIG11bHRpcGxlIHRhcmdldHMsIHdlIGNvdW50IHRoZSBudW1iZXIgb2YgcGVuZGluZyByZWNvdmVyeSBldmVudHNcbiAgICAvLyBhbmQgb25seSBjYWxsIHRoZSBjYWxsYmFjayBvbmNlIGFsbCBldmVudHMgaGF2ZSBiZWVuIHByb2Nlc3NlZFxuICAgIGxldCBwZW5kaW5nID0gMDtcbiAgICAvLyB3aXRoaW5UYXJnZXRzKHBoeFRhcmdldCwgY2FsbGJhY2ssIGRvbSwgdmlld0VsKVxuICAgIHRoaXMud2l0aGluVGFyZ2V0cyhcbiAgICAgIHBoeFRhcmdldCxcbiAgICAgICh0YXJnZXRWaWV3LCB0YXJnZXRDdHgpID0+IHtcbiAgICAgICAgY29uc3QgY2lkID0gdGhpcy50YXJnZXRDb21wb25lbnRJRChuZXdGb3JtLCB0YXJnZXRDdHgpO1xuICAgICAgICBwZW5kaW5nKys7XG4gICAgICAgIGxldCBlID0gbmV3IEN1c3RvbUV2ZW50KFwicGh4OmZvcm0tcmVjb3ZlcnlcIiwge1xuICAgICAgICAgIGRldGFpbDogeyBzb3VyY2VFbGVtZW50OiBvbGRGb3JtIH0sXG4gICAgICAgIH0pO1xuICAgICAgICBKUy5leGVjKGUsIFwiY2hhbmdlXCIsIHBoeEV2ZW50LCB0aGlzLCBpbnB1dCwgW1xuICAgICAgICAgIFwicHVzaFwiLFxuICAgICAgICAgIHtcbiAgICAgICAgICAgIF90YXJnZXQ6IGlucHV0Lm5hbWUsXG4gICAgICAgICAgICB0YXJnZXRWaWV3LFxuICAgICAgICAgICAgdGFyZ2V0Q3R4LFxuICAgICAgICAgICAgbmV3Q2lkOiBjaWQsXG4gICAgICAgICAgICBjYWxsYmFjazogKCkgPT4ge1xuICAgICAgICAgICAgICBwZW5kaW5nLS07XG4gICAgICAgICAgICAgIGlmIChwZW5kaW5nID09PSAwKSB7XG4gICAgICAgICAgICAgICAgY2FsbGJhY2soKTtcbiAgICAgICAgICAgICAgfVxuICAgICAgICAgICAgfSxcbiAgICAgICAgICB9LFxuICAgICAgICBdKTtcbiAgICAgIH0sXG4gICAgICB0ZW1wbGF0ZURvbSxcbiAgICApO1xuICB9XG5cbiAgcHVzaExpbmtQYXRjaChlLCBocmVmLCB0YXJnZXRFbCwgY2FsbGJhY2spIHtcbiAgICBjb25zdCBsaW5rUmVmID0gdGhpcy5saXZlU29ja2V0LnNldFBlbmRpbmdMaW5rKGhyZWYpO1xuICAgIC8vIG9ubHkgYWRkIGxvYWRpbmcgc3RhdGVzIGlmIGV2ZW50IGlzIHRydXN0ZWQgKGl0IHdhcyB0cmlnZ2VyZWQgYnkgdXNlciwgc3VjaCBhcyBjbGljaykgYW5kXG4gICAgLy8gaXQncyBub3QgYSBmb3J3YXJkL2JhY2sgbmF2aWdhdGlvbiBmcm9tIHBvcHN0YXRlXG4gICAgY29uc3QgbG9hZGluZyA9IGUuaXNUcnVzdGVkICYmIGUudHlwZSAhPT0gXCJwb3BzdGF0ZVwiO1xuICAgIGNvbnN0IHJlZkdlbiA9IHRhcmdldEVsXG4gICAgICA/ICgpID0+XG4gICAgICAgICAgdGhpcy5wdXRSZWYoXG4gICAgICAgICAgICBbeyBlbDogdGFyZ2V0RWwsIGxvYWRpbmc6IGxvYWRpbmcsIGxvY2s6IHRydWUgfV0sXG4gICAgICAgICAgICBudWxsLFxuICAgICAgICAgICAgXCJjbGlja1wiLFxuICAgICAgICAgIClcbiAgICAgIDogbnVsbDtcbiAgICBjb25zdCBmYWxsYmFjayA9ICgpID0+IHRoaXMubGl2ZVNvY2tldC5yZWRpcmVjdCh3aW5kb3cubG9jYXRpb24uaHJlZik7XG4gICAgY29uc3QgdXJsID0gaHJlZi5zdGFydHNXaXRoKFwiL1wiKVxuICAgICAgPyBgJHtsb2NhdGlvbi5wcm90b2NvbH0vLyR7bG9jYXRpb24uaG9zdH0ke2hyZWZ9YFxuICAgICAgOiBocmVmO1xuXG4gICAgdGhpcy5wdXNoV2l0aFJlcGx5KHJlZkdlbiwgXCJsaXZlX3BhdGNoXCIsIHsgdXJsIH0pLnRoZW4oXG4gICAgICAoeyByZXNwIH0pID0+IHtcbiAgICAgICAgdGhpcy5saXZlU29ja2V0LnJlcXVlc3RET01VcGRhdGUoKCkgPT4ge1xuICAgICAgICAgIGlmIChyZXNwLmxpbmtfcmVkaXJlY3QpIHtcbiAgICAgICAgICAgIHRoaXMubGl2ZVNvY2tldC5yZXBsYWNlTWFpbihocmVmLCBudWxsLCBjYWxsYmFjaywgbGlua1JlZik7XG4gICAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAgIGlmICh0aGlzLmxpdmVTb2NrZXQuY29tbWl0UGVuZGluZ0xpbmsobGlua1JlZikpIHtcbiAgICAgICAgICAgICAgdGhpcy5ocmVmID0gaHJlZjtcbiAgICAgICAgICAgIH1cbiAgICAgICAgICAgIHRoaXMuYXBwbHlQZW5kaW5nVXBkYXRlcygpO1xuICAgICAgICAgICAgY2FsbGJhY2sgJiYgY2FsbGJhY2sobGlua1JlZik7XG4gICAgICAgICAgfVxuICAgICAgICB9KTtcbiAgICAgIH0sXG4gICAgICAoeyBlcnJvcjogX2Vycm9yLCB0aW1lb3V0OiBfdGltZW91dCB9KSA9PiBmYWxsYmFjaygpLFxuICAgICk7XG4gIH1cblxuICBnZXRGb3Jtc0ZvclJlY292ZXJ5KCkge1xuICAgIC8vIEZvcm0gcmVjb3ZlcnkgaXMgY29tcGxleCBpbiBMaXZlVmlldzpcbiAgICAvLyBXZSB3YW50IHRvIHN1cHBvcnQgbmVzdGVkIExpdmVWaWV3cyBhbmQgYWxzbyBwcm92aWRlIGEgZ29vZCB1c2VyIGV4cGVyaWVuY2UuXG4gICAgLy8gVGhlcmVmb3JlLCB3aGVuIHRoZSBjaGFubmVsIHJlam9pbnMsIHdlIGNvcHkgYWxsIGZvcm1zIHRoYXQgYXJlIGVsaWdpYmxlIGZvclxuICAgIC8vIHJlY292ZXJ5IHRvIGJlIGFibGUgdG8gYWNjZXNzIHRoZW0gbGF0ZXIuXG4gICAgLy8gV2h5IGRvIHdlIG5lZWQgdG8gY29weSB0aGVtPyBCZWNhdXNlIHdoZW4gdGhlIG1haW4gTGl2ZVZpZXcgam9pbnMsIGFueSBmb3Jtc1xuICAgIC8vIGluIG5lc3RlZCBMaXZlVmlld3Mgd291bGQgYmUgbG9zdC5cbiAgICAvL1xuICAgIC8vIFdlIHNob3VsZCByZXdvcmsgdGhpcyBpbiB0aGUgZnV0dXJlIHRvIHNlcmlhbGl6ZSB0aGUgZm9ybSBwYXlsb2FkIGhlcmVcbiAgICAvLyBpbnN0ZWFkIG9mIGNsb25pbmcgdGhlIERPTSBub2RlcywgYnV0IG1ha2luZyB0aGlzIHdvcmsgY29ycmVjdGx5IGlzIHRlZGlvdXMsXG4gICAgLy8gYXMgc2VuZGluZyB0aGUgY29ycmVjdCBmb3JtIHBheWxvYWQgcmVsaWVzIG9uIEpTLnB1c2ggdG8gZXh0cmFjdCB2YWx1ZXNcbiAgICAvLyBmcm9tIEpTIGNvbW1hbmRzIChwaHgtY2hhbmdlPXtKUy5wdXNoKFwiZXZlbnRcIiwgdmFsdWU6IC4uLiwgdGFyZ2V0OiAuLi4pfSksXG4gICAgLy8gYXMgd2VsbCBhcyB2aWV3LnB1c2hJbnB1dCwgd2hpY2ggZXhwZWN0cyBET00gZWxlbWVudHMuXG5cbiAgICBpZiAodGhpcy5qb2luQ291bnQgPT09IDApIHtcbiAgICAgIHJldHVybiB7fTtcbiAgICB9XG5cbiAgICBjb25zdCBwaHhDaGFuZ2UgPSB0aGlzLmJpbmRpbmcoXCJjaGFuZ2VcIik7XG5cbiAgICByZXR1cm4gRE9NLmFsbCh0aGlzLmVsLCBgZm9ybVske3BoeENoYW5nZX1dYClcbiAgICAgIC5maWx0ZXIoKGZvcm0pID0+IGZvcm0uaWQpXG4gICAgICAuZmlsdGVyKChmb3JtKSA9PiBmb3JtLmVsZW1lbnRzLmxlbmd0aCA+IDApXG4gICAgICAuZmlsdGVyKFxuICAgICAgICAoZm9ybSkgPT5cbiAgICAgICAgICBmb3JtLmdldEF0dHJpYnV0ZSh0aGlzLmJpbmRpbmcoUEhYX0FVVE9fUkVDT1ZFUikpICE9PSBcImlnbm9yZVwiLFxuICAgICAgKVxuICAgICAgLm1hcCgoZm9ybSkgPT4ge1xuICAgICAgICAvLyBXZSBuZWVkIHRvIGNsb25lIHRoZSB3aG9sZSBmb3JtLCBhcyByZWx5aW5nIG9uIGZvcm0uZWxlbWVudHMgY2FuIGxlYWQgdG9cbiAgICAgICAgLy8gc2l0dWF0aW9ucyB3aGVyZSB3ZSBoYXZlXG4gICAgICAgIC8vXG4gICAgICAgIC8vICAgPGZvcm0+PGZpZWxkc2V0IGRpc2FibGVkPjxpbnB1dCBuYW1lPVwiZm9vXCIgdmFsdWU9XCJiYXJcIj48L2ZpZWxkc2V0PjwvZm9ybT5cbiAgICAgICAgLy9cbiAgICAgICAgLy8gYW5kIGZvcm0uZWxlbWVudHMgcmV0dXJucyBib3RoIHRoZSBmaWVsZHNldCBhbmQgdGhlIGlucHV0IHNlcGFyYXRlbHkuXG4gICAgICAgIC8vIEJlY2F1c2UgdGhlIGZpZWxkc2V0IGlzIGRpc2FibGVkLCB0aGUgaW5wdXQgc2hvdWxkIE5PVCBiZSBzZW50IHRob3VnaC5cbiAgICAgICAgLy8gV2UgY2FuIG9ubHkgcmVsaWFibHkgc2VyaWFsaXplIHRoZSBmb3JtIGJ5IGNsb25pbmcgaXQgZnVsbHkuXG4gICAgICAgIGNvbnN0IGNsb25lZEZvcm0gPSBmb3JtLmNsb25lTm9kZSh0cnVlKTtcbiAgICAgICAgLy8gd2UgY2FsbCBtb3JwaGRvbSB0byBjb3B5IGFueSBzcGVjaWFsIHN0YXRlXG4gICAgICAgIC8vIGxpa2UgdGhlIHNlbGVjdGVkIG9wdGlvbiBvZiBhIDxzZWxlY3Q+IGVsZW1lbnQ7XG4gICAgICAgIC8vIGFueSBhbHNvIGNvcHkgb3ZlciBwcml2YXRlcyAod2hpY2ggY29udGFpbiBpbmZvcm1hdGlvbiBhYm91dCB0b3VjaGVkIGZpZWxkcylcbiAgICAgICAgbW9ycGhkb20oY2xvbmVkRm9ybSwgZm9ybSwge1xuICAgICAgICAgIG9uQmVmb3JlRWxVcGRhdGVkOiAoZnJvbUVsLCB0b0VsKSA9PiB7XG4gICAgICAgICAgICBET00uY29weVByaXZhdGVzKGZyb21FbCwgdG9FbCk7XG4gICAgICAgICAgICByZXR1cm4gdHJ1ZTtcbiAgICAgICAgICB9LFxuICAgICAgICB9KTtcbiAgICAgICAgLy8gbmV4dCB1cCwgd2UgYWxzbyBuZWVkIHRvIGNsb25lIGFueSBlbGVtZW50cyB3aXRoIGZvcm09XCJpZFwiIHBhcmFtZXRlclxuICAgICAgICBjb25zdCBleHRlcm5hbEVsZW1lbnRzID0gZG9jdW1lbnQucXVlcnlTZWxlY3RvckFsbChcbiAgICAgICAgICBgW2Zvcm09XCIke2Zvcm0uaWR9XCJdYCxcbiAgICAgICAgKTtcbiAgICAgICAgQXJyYXkuZnJvbShleHRlcm5hbEVsZW1lbnRzKS5mb3JFYWNoKChlbCkgPT4ge1xuICAgICAgICAgIGlmIChmb3JtLmNvbnRhaW5zKGVsKSkge1xuICAgICAgICAgICAgcmV0dXJuO1xuICAgICAgICAgIH1cbiAgICAgICAgICBjb25zdCBjbG9uZWRFbCA9IGVsLmNsb25lTm9kZSh0cnVlKTtcbiAgICAgICAgICBtb3JwaGRvbShjbG9uZWRFbCwgZWwpO1xuICAgICAgICAgIERPTS5jb3B5UHJpdmF0ZXMoY2xvbmVkRWwsIGVsKTtcbiAgICAgICAgICBjbG9uZWRGb3JtLmFwcGVuZENoaWxkKGNsb25lZEVsKTtcbiAgICAgICAgfSk7XG4gICAgICAgIHJldHVybiBjbG9uZWRGb3JtO1xuICAgICAgfSlcbiAgICAgIC5yZWR1Y2UoKGFjYywgZm9ybSkgPT4ge1xuICAgICAgICBhY2NbZm9ybS5pZF0gPSBmb3JtO1xuICAgICAgICByZXR1cm4gYWNjO1xuICAgICAgfSwge30pO1xuICB9XG5cbiAgbWF5YmVQdXNoQ29tcG9uZW50c0Rlc3Ryb3llZChkZXN0cm95ZWRDSURzKSB7XG4gICAgbGV0IHdpbGxEZXN0cm95Q0lEcyA9IGRlc3Ryb3llZENJRHMuZmlsdGVyKChjaWQpID0+IHtcbiAgICAgIHJldHVybiBET00uZmluZENvbXBvbmVudE5vZGVMaXN0KHRoaXMuZWwsIGNpZCkubGVuZ3RoID09PSAwO1xuICAgIH0pO1xuXG4gICAgY29uc3Qgb25FcnJvciA9IChlcnJvcikgPT4ge1xuICAgICAgaWYgKCF0aGlzLmlzRGVzdHJveWVkKCkpIHtcbiAgICAgICAgbG9nRXJyb3IoXCJGYWlsZWQgdG8gcHVzaCBjb21wb25lbnRzIGRlc3Ryb3llZFwiLCBlcnJvcik7XG4gICAgICB9XG4gICAgfTtcblxuICAgIGlmICh3aWxsRGVzdHJveUNJRHMubGVuZ3RoID4gMCkge1xuICAgICAgLy8gd2UgbXVzdCByZXNldCB0aGUgcmVuZGVyIGNoYW5nZSB0cmFja2luZyBmb3IgY2lkcyB0aGF0XG4gICAgICAvLyBjb3VsZCBiZSBhZGRlZCBiYWNrIGZyb20gdGhlIHNlcnZlciBzbyB3ZSBkb24ndCBza2lwIHRoZW1cbiAgICAgIHdpbGxEZXN0cm95Q0lEcy5mb3JFYWNoKChjaWQpID0+IHRoaXMucmVuZGVyZWQucmVzZXRSZW5kZXIoY2lkKSk7XG5cbiAgICAgIHRoaXMucHVzaFdpdGhSZXBseShudWxsLCBcImNpZHNfd2lsbF9kZXN0cm95XCIsIHsgY2lkczogd2lsbERlc3Ryb3lDSURzIH0pXG4gICAgICAgIC50aGVuKCgpID0+IHtcbiAgICAgICAgICAvLyB3ZSBtdXN0IHdhaXQgZm9yIHBlbmRpbmcgdHJhbnNpdGlvbnMgdG8gY29tcGxldGUgYmVmb3JlIGRldGVybWluaW5nXG4gICAgICAgICAgLy8gaWYgdGhlIGNpZHMgd2VyZSBhZGRlZCBiYWNrIHRvIHRoZSBET00gaW4gdGhlIG1lYW50aW1lICgjMzEzOSlcbiAgICAgICAgICB0aGlzLmxpdmVTb2NrZXQucmVxdWVzdERPTVVwZGF0ZSgoKSA9PiB7XG4gICAgICAgICAgICAvLyBTZWUgaWYgYW55IG9mIHRoZSBjaWRzIHdlIHdhbnRlZCB0byBkZXN0cm95IHdlcmUgYWRkZWQgYmFjayxcbiAgICAgICAgICAgIC8vIGlmIHRoZXkgd2VyZSBhZGRlZCBiYWNrLCB3ZSBkb24ndCBhY3R1YWxseSBkZXN0cm95IHRoZW0uXG4gICAgICAgICAgICBsZXQgY29tcGxldGVseURlc3Ryb3lDSURzID0gd2lsbERlc3Ryb3lDSURzLmZpbHRlcigoY2lkKSA9PiB7XG4gICAgICAgICAgICAgIHJldHVybiBET00uZmluZENvbXBvbmVudE5vZGVMaXN0KHRoaXMuZWwsIGNpZCkubGVuZ3RoID09PSAwO1xuICAgICAgICAgICAgfSk7XG5cbiAgICAgICAgICAgIGlmIChjb21wbGV0ZWx5RGVzdHJveUNJRHMubGVuZ3RoID4gMCkge1xuICAgICAgICAgICAgICB0aGlzLnB1c2hXaXRoUmVwbHkobnVsbCwgXCJjaWRzX2Rlc3Ryb3llZFwiLCB7XG4gICAgICAgICAgICAgICAgY2lkczogY29tcGxldGVseURlc3Ryb3lDSURzLFxuICAgICAgICAgICAgICB9KVxuICAgICAgICAgICAgICAgIC50aGVuKCh7IHJlc3AgfSkgPT4ge1xuICAgICAgICAgICAgICAgICAgdGhpcy5yZW5kZXJlZC5wcnVuZUNJRHMocmVzcC5jaWRzKTtcbiAgICAgICAgICAgICAgICB9KVxuICAgICAgICAgICAgICAgIC5jYXRjaChvbkVycm9yKTtcbiAgICAgICAgICAgIH1cbiAgICAgICAgICB9KTtcbiAgICAgICAgfSlcbiAgICAgICAgLmNhdGNoKG9uRXJyb3IpO1xuICAgIH1cbiAgfVxuXG4gIG93bnNFbGVtZW50KGVsKSB7XG4gICAgbGV0IHBhcmVudFZpZXdFbCA9IERPTS5jbG9zZXN0Vmlld0VsKGVsKTtcbiAgICByZXR1cm4gKFxuICAgICAgZWwuZ2V0QXR0cmlidXRlKFBIWF9QQVJFTlRfSUQpID09PSB0aGlzLmlkIHx8XG4gICAgICAocGFyZW50Vmlld0VsICYmIHBhcmVudFZpZXdFbC5pZCA9PT0gdGhpcy5pZCkgfHxcbiAgICAgICghcGFyZW50Vmlld0VsICYmIHRoaXMuaXNEZWFkKVxuICAgICk7XG4gIH1cblxuICBzdWJtaXRGb3JtKGZvcm0sIHRhcmdldEN0eCwgcGh4RXZlbnQsIHN1Ym1pdHRlciwgb3B0cyA9IHt9KSB7XG4gICAgRE9NLnB1dFByaXZhdGUoZm9ybSwgUEhYX0hBU19TVUJNSVRURUQsIHRydWUpO1xuICAgIGNvbnN0IGlucHV0cyA9IEFycmF5LmZyb20oZm9ybS5lbGVtZW50cyk7XG4gICAgaW5wdXRzLmZvckVhY2goKGlucHV0KSA9PiBET00ucHV0UHJpdmF0ZShpbnB1dCwgUEhYX0hBU19TVUJNSVRURUQsIHRydWUpKTtcbiAgICB0aGlzLmxpdmVTb2NrZXQuYmx1ckFjdGl2ZUVsZW1lbnQodGhpcyk7XG4gICAgdGhpcy5wdXNoRm9ybVN1Ym1pdChmb3JtLCB0YXJnZXRDdHgsIHBoeEV2ZW50LCBzdWJtaXR0ZXIsIG9wdHMsICgpID0+IHtcbiAgICAgIHRoaXMubGl2ZVNvY2tldC5yZXN0b3JlUHJldmlvdXNseUFjdGl2ZUZvY3VzKCk7XG4gICAgfSk7XG4gIH1cblxuICBiaW5kaW5nKGtpbmQpIHtcbiAgICByZXR1cm4gdGhpcy5saXZlU29ja2V0LmJpbmRpbmcoa2luZCk7XG4gIH1cblxuICAvLyBwaHgtcG9ydGFsXG4gIHB1c2hQb3J0YWxFbGVtZW50SWQoaWQpIHtcbiAgICB0aGlzLnBvcnRhbEVsZW1lbnRJZHMuYWRkKGlkKTtcbiAgfVxuXG4gIGRyb3BQb3J0YWxFbGVtZW50SWQoaWQpIHtcbiAgICB0aGlzLnBvcnRhbEVsZW1lbnRJZHMuZGVsZXRlKGlkKTtcbiAgfVxuXG4gIGRlc3Ryb3lQb3J0YWxFbGVtZW50cygpIHtcbiAgICB0aGlzLnBvcnRhbEVsZW1lbnRJZHMuZm9yRWFjaCgoaWQpID0+IHtcbiAgICAgIGNvbnN0IGVsID0gZG9jdW1lbnQuZ2V0RWxlbWVudEJ5SWQoaWQpO1xuICAgICAgaWYgKGVsKSB7XG4gICAgICAgIGVsLnJlbW92ZSgpO1xuICAgICAgfVxuICAgIH0pO1xuICB9XG59XG4iLCAiaW1wb3J0IHtcbiAgQklORElOR19QUkVGSVgsXG4gIENPTlNFQ1VUSVZFX1JFTE9BRFMsXG4gIERFRkFVTFRTLFxuICBGQUlMU0FGRV9KSVRURVIsXG4gIExPQURFUl9USU1FT1VULFxuICBESVNDT05ORUNURURfVElNRU9VVCxcbiAgTUFYX1JFTE9BRFMsXG4gIFBIWF9ERUJPVU5DRSxcbiAgUEhYX0RST1BfVEFSR0VULFxuICBQSFhfSEFTX0ZPQ1VTRUQsXG4gIFBIWF9LRVksXG4gIFBIWF9MSU5LX1NUQVRFLFxuICBQSFhfTElWRV9MSU5LLFxuICBQSFhfTFZfREVCVUcsXG4gIFBIWF9MVl9MQVRFTkNZX1NJTSxcbiAgUEhYX0xWX1BST0ZJTEUsXG4gIFBIWF9MVl9ISVNUT1JZX1BPU0lUSU9OLFxuICBQSFhfTUFJTixcbiAgUEhYX1BBUkVOVF9JRCxcbiAgUEhYX1ZJRVdfU0VMRUNUT1IsXG4gIFBIWF9ST09UX0lELFxuICBQSFhfVEhST1RUTEUsXG4gIFBIWF9UUkFDS19VUExPQURTLFxuICBQSFhfU0VTU0lPTixcbiAgUkVMT0FEX0pJVFRFUl9NSU4sXG4gIFJFTE9BRF9KSVRURVJfTUFYLFxuICBQSFhfUkVGX1NSQyxcbiAgUEhYX1JFTE9BRF9TVEFUVVMsXG4gIFBIWF9SVU5USU1FX0hPT0ssXG59IGZyb20gXCIuL2NvbnN0YW50c1wiO1xuXG5pbXBvcnQge1xuICBjbG9uZSxcbiAgY2xvc2VzdFBoeEJpbmRpbmcsXG4gIGNsb3N1cmUsXG4gIGRlYnVnLFxuICBtYXliZSxcbiAgbG9nRXJyb3IsXG59IGZyb20gXCIuL3V0aWxzXCI7XG5cbmltcG9ydCBCcm93c2VyIGZyb20gXCIuL2Jyb3dzZXJcIjtcbmltcG9ydCBET00gZnJvbSBcIi4vZG9tXCI7XG5pbXBvcnQgSG9va3MgZnJvbSBcIi4vaG9va3NcIjtcbmltcG9ydCBMaXZlVXBsb2FkZXIgZnJvbSBcIi4vbGl2ZV91cGxvYWRlclwiO1xuaW1wb3J0IFZpZXcgZnJvbSBcIi4vdmlld1wiO1xuaW1wb3J0IEpTIGZyb20gXCIuL2pzXCI7XG5pbXBvcnQganNDb21tYW5kcyBmcm9tIFwiLi9qc19jb21tYW5kc1wiO1xuXG5leHBvcnQgY29uc3QgaXNVc2VkSW5wdXQgPSAoZWwpID0+IERPTS5pc1VzZWRJbnB1dChlbCk7XG5cbmV4cG9ydCBkZWZhdWx0IGNsYXNzIExpdmVTb2NrZXQge1xuICBjb25zdHJ1Y3Rvcih1cmwsIHBoeFNvY2tldCwgb3B0cyA9IHt9KSB7XG4gICAgdGhpcy51bmxvYWRlZCA9IGZhbHNlO1xuICAgIGlmICghcGh4U29ja2V0IHx8IHBoeFNvY2tldC5jb25zdHJ1Y3Rvci5uYW1lID09PSBcIk9iamVjdFwiKSB7XG4gICAgICB0aHJvdyBuZXcgRXJyb3IoYFxuICAgICAgYSBwaG9lbml4IFNvY2tldCBtdXN0IGJlIHByb3ZpZGVkIGFzIHRoZSBzZWNvbmQgYXJndW1lbnQgdG8gdGhlIExpdmVTb2NrZXQgY29uc3RydWN0b3IuIEZvciBleGFtcGxlOlxuXG4gICAgICAgICAgaW1wb3J0IHtTb2NrZXR9IGZyb20gXCJwaG9lbml4XCJcbiAgICAgICAgICBpbXBvcnQge0xpdmVTb2NrZXR9IGZyb20gXCJwaG9lbml4X2xpdmVfdmlld1wiXG4gICAgICAgICAgbGV0IGxpdmVTb2NrZXQgPSBuZXcgTGl2ZVNvY2tldChcIi9saXZlXCIsIFNvY2tldCwgey4uLn0pXG4gICAgICBgKTtcbiAgICB9XG4gICAgdGhpcy5zb2NrZXQgPSBuZXcgcGh4U29ja2V0KHVybCwgb3B0cyk7XG4gICAgdGhpcy5iaW5kaW5nUHJlZml4ID0gb3B0cy5iaW5kaW5nUHJlZml4IHx8IEJJTkRJTkdfUFJFRklYO1xuICAgIHRoaXMub3B0cyA9IG9wdHM7XG4gICAgdGhpcy5wYXJhbXMgPSBjbG9zdXJlKG9wdHMucGFyYW1zIHx8IHt9KTtcbiAgICB0aGlzLnZpZXdMb2dnZXIgPSBvcHRzLnZpZXdMb2dnZXI7XG4gICAgdGhpcy5tZXRhZGF0YUNhbGxiYWNrcyA9IG9wdHMubWV0YWRhdGEgfHwge307XG4gICAgdGhpcy5kZWZhdWx0cyA9IE9iamVjdC5hc3NpZ24oY2xvbmUoREVGQVVMVFMpLCBvcHRzLmRlZmF1bHRzIHx8IHt9KTtcbiAgICB0aGlzLnByZXZBY3RpdmUgPSBudWxsO1xuICAgIHRoaXMuc2lsZW5jZWQgPSBmYWxzZTtcbiAgICB0aGlzLm1haW4gPSBudWxsO1xuICAgIHRoaXMub3V0Z29pbmdNYWluRWwgPSBudWxsO1xuICAgIHRoaXMuY2xpY2tTdGFydGVkQXRUYXJnZXQgPSBudWxsO1xuICAgIHRoaXMubGlua1JlZiA9IDE7XG4gICAgdGhpcy5yb290cyA9IHt9O1xuICAgIHRoaXMuaHJlZiA9IHdpbmRvdy5sb2NhdGlvbi5ocmVmO1xuICAgIHRoaXMucGVuZGluZ0xpbmsgPSBudWxsO1xuICAgIHRoaXMuY3VycmVudExvY2F0aW9uID0gY2xvbmUod2luZG93LmxvY2F0aW9uKTtcbiAgICB0aGlzLmhvb2tzID0gb3B0cy5ob29rcyB8fCB7fTtcbiAgICB0aGlzLnVwbG9hZGVycyA9IG9wdHMudXBsb2FkZXJzIHx8IHt9O1xuICAgIHRoaXMubG9hZGVyVGltZW91dCA9IG9wdHMubG9hZGVyVGltZW91dCB8fCBMT0FERVJfVElNRU9VVDtcbiAgICB0aGlzLmRpc2Nvbm5lY3RlZFRpbWVvdXQgPSBvcHRzLmRpc2Nvbm5lY3RlZFRpbWVvdXQgfHwgRElTQ09OTkVDVEVEX1RJTUVPVVQ7XG4gICAgLyoqXG4gICAgICogQHR5cGUge1JldHVyblR5cGU8dHlwZW9mIHNldFRpbWVvdXQ+IHwgbnVsbH1cbiAgICAgKi9cbiAgICB0aGlzLnJlbG9hZFdpdGhKaXR0ZXJUaW1lciA9IG51bGw7XG4gICAgdGhpcy5tYXhSZWxvYWRzID0gb3B0cy5tYXhSZWxvYWRzIHx8IE1BWF9SRUxPQURTO1xuICAgIHRoaXMucmVsb2FkSml0dGVyTWluID0gb3B0cy5yZWxvYWRKaXR0ZXJNaW4gfHwgUkVMT0FEX0pJVFRFUl9NSU47XG4gICAgdGhpcy5yZWxvYWRKaXR0ZXJNYXggPSBvcHRzLnJlbG9hZEppdHRlck1heCB8fCBSRUxPQURfSklUVEVSX01BWDtcbiAgICB0aGlzLmZhaWxzYWZlSml0dGVyID0gb3B0cy5mYWlsc2FmZUppdHRlciB8fCBGQUlMU0FGRV9KSVRURVI7XG4gICAgdGhpcy5sb2NhbFN0b3JhZ2UgPSBvcHRzLmxvY2FsU3RvcmFnZSB8fCB3aW5kb3cubG9jYWxTdG9yYWdlO1xuICAgIHRoaXMuc2Vzc2lvblN0b3JhZ2UgPSBvcHRzLnNlc3Npb25TdG9yYWdlIHx8IHdpbmRvdy5zZXNzaW9uU3RvcmFnZTtcbiAgICB0aGlzLmJvdW5kVG9wTGV2ZWxFdmVudHMgPSBmYWxzZTtcbiAgICB0aGlzLmJvdW5kRXZlbnROYW1lcyA9IG5ldyBTZXQoKTtcbiAgICB0aGlzLmJsb2NrUGh4Q2hhbmdlV2hpbGVDb21wb3NpbmcgPVxuICAgICAgb3B0cy5ibG9ja1BoeENoYW5nZVdoaWxlQ29tcG9zaW5nIHx8IGZhbHNlO1xuICAgIHRoaXMuc2VydmVyQ2xvc2VSZWYgPSBudWxsO1xuICAgIHRoaXMuZG9tQ2FsbGJhY2tzID0gT2JqZWN0LmFzc2lnbihcbiAgICAgIHtcbiAgICAgICAganNRdWVyeVNlbGVjdG9yQWxsOiBudWxsLFxuICAgICAgICBvblBhdGNoU3RhcnQ6IGNsb3N1cmUoKSxcbiAgICAgICAgb25QYXRjaEVuZDogY2xvc3VyZSgpLFxuICAgICAgICBvbk5vZGVBZGRlZDogY2xvc3VyZSgpLFxuICAgICAgICBvbkJlZm9yZUVsVXBkYXRlZDogY2xvc3VyZSgpLFxuICAgICAgfSxcbiAgICAgIG9wdHMuZG9tIHx8IHt9LFxuICAgICk7XG4gICAgdGhpcy50cmFuc2l0aW9ucyA9IG5ldyBUcmFuc2l0aW9uU2V0KCk7XG4gICAgdGhpcy5jdXJyZW50SGlzdG9yeVBvc2l0aW9uID1cbiAgICAgIHBhcnNlSW50KHRoaXMuc2Vzc2lvblN0b3JhZ2UuZ2V0SXRlbShQSFhfTFZfSElTVE9SWV9QT1NJVElPTikpIHx8IDA7XG4gICAgd2luZG93LmFkZEV2ZW50TGlzdGVuZXIoXCJwYWdlaGlkZVwiLCAoX2UpID0+IHtcbiAgICAgIHRoaXMudW5sb2FkZWQgPSB0cnVlO1xuICAgIH0pO1xuICAgIHRoaXMuc29ja2V0Lm9uT3BlbigoKSA9PiB7XG4gICAgICBpZiAodGhpcy5pc1VubG9hZGVkKCkpIHtcbiAgICAgICAgLy8gcmVsb2FkIHBhZ2UgaWYgYmVpbmcgcmVzdG9yZWQgZnJvbSBiYWNrL2ZvcndhcmQgY2FjaGUgYW5kIGJyb3dzZXIgZG9lcyBub3QgZW1pdCBcInBhZ2VzaG93XCJcbiAgICAgICAgd2luZG93LmxvY2F0aW9uLnJlbG9hZCgpO1xuICAgICAgfVxuICAgIH0pO1xuICB9XG5cbiAgLy8gcHVibGljXG5cbiAgdmVyc2lvbigpIHtcbiAgICByZXR1cm4gTFZfVlNOO1xuICB9XG5cbiAgaXNQcm9maWxlRW5hYmxlZCgpIHtcbiAgICByZXR1cm4gdGhpcy5zZXNzaW9uU3RvcmFnZS5nZXRJdGVtKFBIWF9MVl9QUk9GSUxFKSA9PT0gXCJ0cnVlXCI7XG4gIH1cblxuICBpc0RlYnVnRW5hYmxlZCgpIHtcbiAgICByZXR1cm4gdGhpcy5zZXNzaW9uU3RvcmFnZS5nZXRJdGVtKFBIWF9MVl9ERUJVRykgPT09IFwidHJ1ZVwiO1xuICB9XG5cbiAgaXNEZWJ1Z0Rpc2FibGVkKCkge1xuICAgIHJldHVybiB0aGlzLnNlc3Npb25TdG9yYWdlLmdldEl0ZW0oUEhYX0xWX0RFQlVHKSA9PT0gXCJmYWxzZVwiO1xuICB9XG5cbiAgZW5hYmxlRGVidWcoKSB7XG4gICAgdGhpcy5zZXNzaW9uU3RvcmFnZS5zZXRJdGVtKFBIWF9MVl9ERUJVRywgXCJ0cnVlXCIpO1xuICB9XG5cbiAgZW5hYmxlUHJvZmlsaW5nKCkge1xuICAgIHRoaXMuc2Vzc2lvblN0b3JhZ2Uuc2V0SXRlbShQSFhfTFZfUFJPRklMRSwgXCJ0cnVlXCIpO1xuICB9XG5cbiAgZGlzYWJsZURlYnVnKCkge1xuICAgIHRoaXMuc2Vzc2lvblN0b3JhZ2Uuc2V0SXRlbShQSFhfTFZfREVCVUcsIFwiZmFsc2VcIik7XG4gIH1cblxuICBkaXNhYmxlUHJvZmlsaW5nKCkge1xuICAgIHRoaXMuc2Vzc2lvblN0b3JhZ2UucmVtb3ZlSXRlbShQSFhfTFZfUFJPRklMRSk7XG4gIH1cblxuICBlbmFibGVMYXRlbmN5U2ltKHVwcGVyQm91bmRNcykge1xuICAgIHRoaXMuZW5hYmxlRGVidWcoKTtcbiAgICBjb25zb2xlLmxvZyhcbiAgICAgIFwibGF0ZW5jeSBzaW11bGF0b3IgZW5hYmxlZCBmb3IgdGhlIGR1cmF0aW9uIG9mIHRoaXMgYnJvd3NlciBzZXNzaW9uLiBDYWxsIGRpc2FibGVMYXRlbmN5U2ltKCkgdG8gZGlzYWJsZVwiLFxuICAgICk7XG4gICAgdGhpcy5zZXNzaW9uU3RvcmFnZS5zZXRJdGVtKFBIWF9MVl9MQVRFTkNZX1NJTSwgdXBwZXJCb3VuZE1zKTtcbiAgfVxuXG4gIGRpc2FibGVMYXRlbmN5U2ltKCkge1xuICAgIHRoaXMuc2Vzc2lvblN0b3JhZ2UucmVtb3ZlSXRlbShQSFhfTFZfTEFURU5DWV9TSU0pO1xuICB9XG5cbiAgZ2V0TGF0ZW5jeVNpbSgpIHtcbiAgICBjb25zdCBzdHIgPSB0aGlzLnNlc3Npb25TdG9yYWdlLmdldEl0ZW0oUEhYX0xWX0xBVEVOQ1lfU0lNKTtcbiAgICByZXR1cm4gc3RyID8gcGFyc2VJbnQoc3RyKSA6IG51bGw7XG4gIH1cblxuICBnZXRTb2NrZXQoKSB7XG4gICAgcmV0dXJuIHRoaXMuc29ja2V0O1xuICB9XG5cbiAgY29ubmVjdCgpIHtcbiAgICAvLyBlbmFibGUgZGVidWcgYnkgZGVmYXVsdCBpZiBvbiBsb2NhbGhvc3QgYW5kIG5vdCBleHBsaWNpdGx5IGRpc2FibGVkXG4gICAgaWYgKHdpbmRvdy5sb2NhdGlvbi5ob3N0bmFtZSA9PT0gXCJsb2NhbGhvc3RcIiAmJiAhdGhpcy5pc0RlYnVnRGlzYWJsZWQoKSkge1xuICAgICAgdGhpcy5lbmFibGVEZWJ1ZygpO1xuICAgIH1cbiAgICBjb25zdCBkb0Nvbm5lY3QgPSAoKSA9PiB7XG4gICAgICB0aGlzLnJlc2V0UmVsb2FkU3RhdHVzKCk7XG4gICAgICBpZiAodGhpcy5qb2luUm9vdFZpZXdzKCkpIHtcbiAgICAgICAgdGhpcy5iaW5kVG9wTGV2ZWxFdmVudHMoKTtcbiAgICAgICAgdGhpcy5zb2NrZXQuY29ubmVjdCgpO1xuICAgICAgfSBlbHNlIGlmICh0aGlzLm1haW4pIHtcbiAgICAgICAgdGhpcy5zb2NrZXQuY29ubmVjdCgpO1xuICAgICAgfSBlbHNlIHtcbiAgICAgICAgdGhpcy5iaW5kVG9wTGV2ZWxFdmVudHMoeyBkZWFkOiB0cnVlIH0pO1xuICAgICAgfVxuICAgICAgdGhpcy5qb2luRGVhZFZpZXcoKTtcbiAgICB9O1xuICAgIGlmIChcbiAgICAgIFtcImNvbXBsZXRlXCIsIFwibG9hZGVkXCIsIFwiaW50ZXJhY3RpdmVcIl0uaW5kZXhPZihkb2N1bWVudC5yZWFkeVN0YXRlKSA+PSAwXG4gICAgKSB7XG4gICAgICBkb0Nvbm5lY3QoKTtcbiAgICB9IGVsc2Uge1xuICAgICAgZG9jdW1lbnQuYWRkRXZlbnRMaXN0ZW5lcihcIkRPTUNvbnRlbnRMb2FkZWRcIiwgKCkgPT4gZG9Db25uZWN0KCkpO1xuICAgIH1cbiAgfVxuXG4gIGRpc2Nvbm5lY3QoY2FsbGJhY2spIHtcbiAgICBjbGVhclRpbWVvdXQodGhpcy5yZWxvYWRXaXRoSml0dGVyVGltZXIpO1xuICAgIC8vIHJlbW92ZSB0aGUgc29ja2V0IGNsb3NlIGxpc3RlbmVyIHRvIGF2b2lkIHRyeWluZyB0byBoYW5kbGVcbiAgICAvLyBhIHNlcnZlciBjbG9zZSBldmVudCB3aGVuIGl0IGlzIGFjdHVhbGx5IGNhdXNlZCBieSB1cyBkaXNjb25uZWN0aW5nXG4gICAgaWYgKHRoaXMuc2VydmVyQ2xvc2VSZWYpIHtcbiAgICAgIHRoaXMuc29ja2V0Lm9mZih0aGlzLnNlcnZlckNsb3NlUmVmKTtcbiAgICAgIHRoaXMuc2VydmVyQ2xvc2VSZWYgPSBudWxsO1xuICAgIH1cbiAgICB0aGlzLnNvY2tldC5kaXNjb25uZWN0KGNhbGxiYWNrKTtcbiAgfVxuXG4gIHJlcGxhY2VUcmFuc3BvcnQodHJhbnNwb3J0KSB7XG4gICAgY2xlYXJUaW1lb3V0KHRoaXMucmVsb2FkV2l0aEppdHRlclRpbWVyKTtcbiAgICB0aGlzLnNvY2tldC5yZXBsYWNlVHJhbnNwb3J0KHRyYW5zcG9ydCk7XG4gICAgdGhpcy5jb25uZWN0KCk7XG4gIH1cblxuICBleGVjSlMoZWwsIGVuY29kZWRKUywgZXZlbnRUeXBlID0gbnVsbCkge1xuICAgIGNvbnN0IGUgPSBuZXcgQ3VzdG9tRXZlbnQoXCJwaHg6ZXhlY1wiLCB7IGRldGFpbDogeyBzb3VyY2VFbGVtZW50OiBlbCB9IH0pO1xuICAgIHRoaXMub3duZXIoZWwsICh2aWV3KSA9PiBKUy5leGVjKGUsIGV2ZW50VHlwZSwgZW5jb2RlZEpTLCB2aWV3LCBlbCkpO1xuICB9XG5cbiAgLyoqXG4gICAqIFJldHVybnMgYW4gb2JqZWN0IHdpdGggbWV0aG9kcyB0byBtYW5pcGx1YXRlIHRoZSBET00gYW5kIGV4ZWN1dGUgSmF2YVNjcmlwdC5cbiAgICogVGhlIGFwcGxpZWQgY2hhbmdlcyBpbnRlZ3JhdGUgd2l0aCBzZXJ2ZXIgRE9NIHBhdGNoaW5nLlxuICAgKlxuICAgKiBAcmV0dXJucyB7aW1wb3J0KFwiLi9qc19jb21tYW5kc1wiKS5MaXZlU29ja2V0SlNDb21tYW5kc31cbiAgICovXG4gIGpzKCkge1xuICAgIHJldHVybiBqc0NvbW1hbmRzKHRoaXMsIFwianNcIik7XG4gIH1cblxuICAvLyBwcml2YXRlXG5cbiAgdW5sb2FkKCkge1xuICAgIGlmICh0aGlzLnVubG9hZGVkKSB7XG4gICAgICByZXR1cm47XG4gICAgfVxuICAgIGlmICh0aGlzLm1haW4gJiYgdGhpcy5pc0Nvbm5lY3RlZCgpKSB7XG4gICAgICB0aGlzLmxvZyh0aGlzLm1haW4sIFwic29ja2V0XCIsICgpID0+IFtcImRpc2Nvbm5lY3QgZm9yIHBhZ2UgbmF2XCJdKTtcbiAgICB9XG4gICAgdGhpcy51bmxvYWRlZCA9IHRydWU7XG4gICAgdGhpcy5kZXN0cm95QWxsVmlld3MoKTtcbiAgICB0aGlzLmRpc2Nvbm5lY3QoKTtcbiAgfVxuXG4gIHRyaWdnZXJET00oa2luZCwgYXJncykge1xuICAgIHRoaXMuZG9tQ2FsbGJhY2tzW2tpbmRdKC4uLmFyZ3MpO1xuICB9XG5cbiAgdGltZShuYW1lLCBmdW5jKSB7XG4gICAgaWYgKCF0aGlzLmlzUHJvZmlsZUVuYWJsZWQoKSB8fCAhY29uc29sZS50aW1lKSB7XG4gICAgICByZXR1cm4gZnVuYygpO1xuICAgIH1cbiAgICBjb25zb2xlLnRpbWUobmFtZSk7XG4gICAgY29uc3QgcmVzdWx0ID0gZnVuYygpO1xuICAgIGNvbnNvbGUudGltZUVuZChuYW1lKTtcbiAgICByZXR1cm4gcmVzdWx0O1xuICB9XG5cbiAgbG9nKHZpZXcsIGtpbmQsIG1zZ0NhbGxiYWNrKSB7XG4gICAgaWYgKHRoaXMudmlld0xvZ2dlcikge1xuICAgICAgY29uc3QgW21zZywgb2JqXSA9IG1zZ0NhbGxiYWNrKCk7XG4gICAgICB0aGlzLnZpZXdMb2dnZXIodmlldywga2luZCwgbXNnLCBvYmopO1xuICAgIH0gZWxzZSBpZiAodGhpcy5pc0RlYnVnRW5hYmxlZCgpKSB7XG4gICAgICBjb25zdCBbbXNnLCBvYmpdID0gbXNnQ2FsbGJhY2soKTtcbiAgICAgIGRlYnVnKHZpZXcsIGtpbmQsIG1zZywgb2JqKTtcbiAgICB9XG4gIH1cblxuICByZXF1ZXN0RE9NVXBkYXRlKGNhbGxiYWNrKSB7XG4gICAgdGhpcy50cmFuc2l0aW9ucy5hZnRlcihjYWxsYmFjayk7XG4gIH1cblxuICBhc3luY1RyYW5zaXRpb24ocHJvbWlzZSkge1xuICAgIHRoaXMudHJhbnNpdGlvbnMuYWRkQXN5bmNUcmFuc2l0aW9uKHByb21pc2UpO1xuICB9XG5cbiAgdHJhbnNpdGlvbih0aW1lLCBvblN0YXJ0LCBvbkRvbmUgPSBmdW5jdGlvbiAoKSB7fSkge1xuICAgIHRoaXMudHJhbnNpdGlvbnMuYWRkVHJhbnNpdGlvbih0aW1lLCBvblN0YXJ0LCBvbkRvbmUpO1xuICB9XG5cbiAgb25DaGFubmVsKGNoYW5uZWwsIGV2ZW50LCBjYikge1xuICAgIGNoYW5uZWwub24oZXZlbnQsIChkYXRhKSA9PiB7XG4gICAgICBjb25zdCBsYXRlbmN5ID0gdGhpcy5nZXRMYXRlbmN5U2ltKCk7XG4gICAgICBpZiAoIWxhdGVuY3kpIHtcbiAgICAgICAgY2IoZGF0YSk7XG4gICAgICB9IGVsc2Uge1xuICAgICAgICBzZXRUaW1lb3V0KCgpID0+IGNiKGRhdGEpLCBsYXRlbmN5KTtcbiAgICAgIH1cbiAgICB9KTtcbiAgfVxuXG4gIHJlbG9hZFdpdGhKaXR0ZXIodmlldywgbG9nKSB7XG4gICAgY2xlYXJUaW1lb3V0KHRoaXMucmVsb2FkV2l0aEppdHRlclRpbWVyKTtcbiAgICB0aGlzLmRpc2Nvbm5lY3QoKTtcbiAgICBjb25zdCBtaW5NcyA9IHRoaXMucmVsb2FkSml0dGVyTWluO1xuICAgIGNvbnN0IG1heE1zID0gdGhpcy5yZWxvYWRKaXR0ZXJNYXg7XG4gICAgbGV0IGFmdGVyTXMgPSBNYXRoLmZsb29yKE1hdGgucmFuZG9tKCkgKiAobWF4TXMgLSBtaW5NcyArIDEpKSArIG1pbk1zO1xuICAgIGNvbnN0IHRyaWVzID0gQnJvd3Nlci51cGRhdGVMb2NhbChcbiAgICAgIHRoaXMubG9jYWxTdG9yYWdlLFxuICAgICAgd2luZG93LmxvY2F0aW9uLnBhdGhuYW1lLFxuICAgICAgQ09OU0VDVVRJVkVfUkVMT0FEUyxcbiAgICAgIDAsXG4gICAgICAoY291bnQpID0+IGNvdW50ICsgMSxcbiAgICApO1xuICAgIGlmICh0cmllcyA+PSB0aGlzLm1heFJlbG9hZHMpIHtcbiAgICAgIGFmdGVyTXMgPSB0aGlzLmZhaWxzYWZlSml0dGVyO1xuICAgIH1cbiAgICB0aGlzLnJlbG9hZFdpdGhKaXR0ZXJUaW1lciA9IHNldFRpbWVvdXQoKCkgPT4ge1xuICAgICAgLy8gaWYgdmlldyBoYXMgcmVjb3ZlcmVkLCBzdWNoIGFzIHRyYW5zcG9ydCByZXBsYWNlZCwgdGhlbiBjYW5jZWxcbiAgICAgIGlmICh2aWV3LmlzRGVzdHJveWVkKCkgfHwgdmlldy5pc0Nvbm5lY3RlZCgpKSB7XG4gICAgICAgIHJldHVybjtcbiAgICAgIH1cbiAgICAgIHZpZXcuZGVzdHJveSgpO1xuICAgICAgbG9nXG4gICAgICAgID8gbG9nKClcbiAgICAgICAgOiB0aGlzLmxvZyh2aWV3LCBcImpvaW5cIiwgKCkgPT4gW1xuICAgICAgICAgICAgYGVuY291bnRlcmVkICR7dHJpZXN9IGNvbnNlY3V0aXZlIHJlbG9hZHNgLFxuICAgICAgICAgIF0pO1xuICAgICAgaWYgKHRyaWVzID49IHRoaXMubWF4UmVsb2Fkcykge1xuICAgICAgICB0aGlzLmxvZyh2aWV3LCBcImpvaW5cIiwgKCkgPT4gW1xuICAgICAgICAgIGBleGNlZWRlZCAke3RoaXMubWF4UmVsb2Fkc30gY29uc2VjdXRpdmUgcmVsb2Fkcy4gRW50ZXJpbmcgZmFpbHNhZmUgbW9kZWAsXG4gICAgICAgIF0pO1xuICAgICAgfVxuICAgICAgaWYgKHRoaXMuaGFzUGVuZGluZ0xpbmsoKSkge1xuICAgICAgICB3aW5kb3cubG9jYXRpb24gPSB0aGlzLnBlbmRpbmdMaW5rO1xuICAgICAgfSBlbHNlIHtcbiAgICAgICAgd2luZG93LmxvY2F0aW9uLnJlbG9hZCgpO1xuICAgICAgfVxuICAgIH0sIGFmdGVyTXMpO1xuICB9XG5cbiAgZ2V0SG9va0RlZmluaXRpb24obmFtZSkge1xuICAgIGlmICghbmFtZSkge1xuICAgICAgcmV0dXJuO1xuICAgIH1cbiAgICByZXR1cm4gKFxuICAgICAgdGhpcy5tYXliZUludGVybmFsSG9vayhuYW1lKSB8fFxuICAgICAgdGhpcy5ob29rc1tuYW1lXSB8fFxuICAgICAgdGhpcy5tYXliZVJ1bnRpbWVIb29rKG5hbWUpXG4gICAgKTtcbiAgfVxuXG4gIG1heWJlSW50ZXJuYWxIb29rKG5hbWUpIHtcbiAgICByZXR1cm4gbmFtZSAmJiBuYW1lLnN0YXJ0c1dpdGgoXCJQaG9lbml4LlwiKSAmJiBIb29rc1tuYW1lLnNwbGl0KFwiLlwiKVsxXV07XG4gIH1cblxuICBtYXliZVJ1bnRpbWVIb29rKG5hbWUpIHtcbiAgICBjb25zdCBydW50aW1lSG9vayA9IGRvY3VtZW50LnF1ZXJ5U2VsZWN0b3IoXG4gICAgICBgc2NyaXB0WyR7UEhYX1JVTlRJTUVfSE9PS309XCIke0NTUy5lc2NhcGUobmFtZSl9XCJdYCxcbiAgICApO1xuICAgIGlmICghcnVudGltZUhvb2spIHtcbiAgICAgIHJldHVybjtcbiAgICB9XG4gICAgbGV0IGNhbGxiYWNrcyA9IHdpbmRvd1tgcGh4X2hvb2tfJHtuYW1lfWBdO1xuICAgIGlmICghY2FsbGJhY2tzIHx8IHR5cGVvZiBjYWxsYmFja3MgIT09IFwiZnVuY3Rpb25cIikge1xuICAgICAgbG9nRXJyb3IoXCJhIHJ1bnRpbWUgaG9vayBtdXN0IGJlIGEgZnVuY3Rpb25cIiwgcnVudGltZUhvb2spO1xuICAgICAgcmV0dXJuO1xuICAgIH1cbiAgICBjb25zdCBob29rRGVmaW5pdG9uID0gY2FsbGJhY2tzKCk7XG4gICAgaWYgKFxuICAgICAgaG9va0RlZmluaXRvbiAmJlxuICAgICAgKHR5cGVvZiBob29rRGVmaW5pdG9uID09PSBcIm9iamVjdFwiIHx8IHR5cGVvZiBob29rRGVmaW5pdG9uID09PSBcImZ1bmN0aW9uXCIpXG4gICAgKSB7XG4gICAgICByZXR1cm4gaG9va0RlZmluaXRvbjtcbiAgICB9XG4gICAgbG9nRXJyb3IoXG4gICAgICBcInJ1bnRpbWUgaG9vayBtdXN0IHJldHVybiBhbiBvYmplY3Qgd2l0aCBob29rIGNhbGxiYWNrcyBvciBhbiBpbnN0YW5jZSBvZiBWaWV3SG9va1wiLFxuICAgICAgcnVudGltZUhvb2ssXG4gICAgKTtcbiAgfVxuXG4gIGlzVW5sb2FkZWQoKSB7XG4gICAgcmV0dXJuIHRoaXMudW5sb2FkZWQ7XG4gIH1cblxuICBpc0Nvbm5lY3RlZCgpIHtcbiAgICByZXR1cm4gdGhpcy5zb2NrZXQuaXNDb25uZWN0ZWQoKTtcbiAgfVxuXG4gIGdldEJpbmRpbmdQcmVmaXgoKSB7XG4gICAgcmV0dXJuIHRoaXMuYmluZGluZ1ByZWZpeDtcbiAgfVxuXG4gIGJpbmRpbmcoa2luZCkge1xuICAgIHJldHVybiBgJHt0aGlzLmdldEJpbmRpbmdQcmVmaXgoKX0ke2tpbmR9YDtcbiAgfVxuXG4gIGNoYW5uZWwodG9waWMsIHBhcmFtcykge1xuICAgIHJldHVybiB0aGlzLnNvY2tldC5jaGFubmVsKHRvcGljLCBwYXJhbXMpO1xuICB9XG5cbiAgam9pbkRlYWRWaWV3KCkge1xuICAgIGNvbnN0IGJvZHkgPSBkb2N1bWVudC5ib2R5O1xuICAgIGlmIChcbiAgICAgIGJvZHkgJiZcbiAgICAgICF0aGlzLmlzUGh4Vmlldyhib2R5KSAmJlxuICAgICAgIXRoaXMuaXNQaHhWaWV3KGRvY3VtZW50LmZpcnN0RWxlbWVudENoaWxkKVxuICAgICkge1xuICAgICAgY29uc3QgdmlldyA9IHRoaXMubmV3Um9vdFZpZXcoYm9keSk7XG4gICAgICB2aWV3LnNldEhyZWYodGhpcy5nZXRIcmVmKCkpO1xuICAgICAgdmlldy5qb2luRGVhZCgpO1xuICAgICAgaWYgKCF0aGlzLm1haW4pIHtcbiAgICAgICAgdGhpcy5tYWluID0gdmlldztcbiAgICAgIH1cbiAgICAgIHdpbmRvdy5yZXF1ZXN0QW5pbWF0aW9uRnJhbWUoKCkgPT4ge1xuICAgICAgICB2aWV3LmV4ZWNOZXdNb3VudGVkKCk7XG4gICAgICAgIC8vIHJlc3RvcmUgc2Nyb2xsIHBvc2l0aW9uIHdoZW4gbmF2aWdhdGluZyBmcm9tIGFuIGV4dGVybmFsIC8gbm9uLWxpdmUgcGFnZVxuICAgICAgICB0aGlzLm1heWJlU2Nyb2xsKGhpc3Rvcnkuc3RhdGU/LnNjcm9sbCk7XG4gICAgICB9KTtcbiAgICB9XG4gIH1cblxuICBqb2luUm9vdFZpZXdzKCkge1xuICAgIGxldCByb290c0ZvdW5kID0gZmFsc2U7XG4gICAgRE9NLmFsbChcbiAgICAgIGRvY3VtZW50LFxuICAgICAgYCR7UEhYX1ZJRVdfU0VMRUNUT1J9Om5vdChbJHtQSFhfUEFSRU5UX0lEfV0pYCxcbiAgICAgIChyb290RWwpID0+IHtcbiAgICAgICAgaWYgKCF0aGlzLmdldFJvb3RCeUlkKHJvb3RFbC5pZCkpIHtcbiAgICAgICAgICBjb25zdCB2aWV3ID0gdGhpcy5uZXdSb290Vmlldyhyb290RWwpO1xuICAgICAgICAgIC8vIHN0aWNraWVzIGNhbm5vdCBiZSBtb3VudGVkIGF0IHRoZSByb3V0ZXIgYW5kIHRoZXJlZm9yZSBzaG91bGQgbm90XG4gICAgICAgICAgLy8gZ2V0IGEgaHJlZiBzZXQgb24gdGhlbVxuICAgICAgICAgIGlmICghRE9NLmlzUGh4U3RpY2t5KHJvb3RFbCkpIHtcbiAgICAgICAgICAgIHZpZXcuc2V0SHJlZih0aGlzLmdldEhyZWYoKSk7XG4gICAgICAgICAgfVxuICAgICAgICAgIHZpZXcuam9pbigpO1xuICAgICAgICAgIGlmIChyb290RWwuaGFzQXR0cmlidXRlKFBIWF9NQUlOKSkge1xuICAgICAgICAgICAgdGhpcy5tYWluID0gdmlldztcbiAgICAgICAgICB9XG4gICAgICAgIH1cbiAgICAgICAgcm9vdHNGb3VuZCA9IHRydWU7XG4gICAgICB9LFxuICAgICk7XG4gICAgcmV0dXJuIHJvb3RzRm91bmQ7XG4gIH1cblxuICByZWRpcmVjdCh0bywgZmxhc2gsIHJlbG9hZFRva2VuKSB7XG4gICAgaWYgKHJlbG9hZFRva2VuKSB7XG4gICAgICBCcm93c2VyLnNldENvb2tpZShQSFhfUkVMT0FEX1NUQVRVUywgcmVsb2FkVG9rZW4sIDYwKTtcbiAgICB9XG4gICAgdGhpcy51bmxvYWQoKTtcbiAgICBCcm93c2VyLnJlZGlyZWN0KHRvLCBmbGFzaCk7XG4gIH1cblxuICByZXBsYWNlTWFpbihcbiAgICBocmVmLFxuICAgIGZsYXNoLFxuICAgIGNhbGxiYWNrID0gbnVsbCxcbiAgICBsaW5rUmVmID0gdGhpcy5zZXRQZW5kaW5nTGluayhocmVmKSxcbiAgKSB7XG4gICAgY29uc3QgbGl2ZVJlZmVyZXIgPSB0aGlzLmN1cnJlbnRMb2NhdGlvbi5ocmVmO1xuICAgIHRoaXMub3V0Z29pbmdNYWluRWwgPSB0aGlzLm91dGdvaW5nTWFpbkVsIHx8IHRoaXMubWFpbi5lbDtcblxuICAgIGNvbnN0IHN0aWNraWVzID0gRE9NLmZpbmRQaHhTdGlja3koZG9jdW1lbnQpIHx8IFtdO1xuICAgIGNvbnN0IHJlbW92ZUVscyA9IERPTS5hbGwoXG4gICAgICB0aGlzLm91dGdvaW5nTWFpbkVsLFxuICAgICAgYFske3RoaXMuYmluZGluZyhcInJlbW92ZVwiKX1dYCxcbiAgICApLmZpbHRlcigoZWwpID0+ICFET00uaXNDaGlsZE9mQW55KGVsLCBzdGlja2llcykpO1xuXG4gICAgY29uc3QgbmV3TWFpbkVsID0gRE9NLmNsb25lTm9kZSh0aGlzLm91dGdvaW5nTWFpbkVsLCBcIlwiKTtcbiAgICB0aGlzLm1haW4uc2hvd0xvYWRlcih0aGlzLmxvYWRlclRpbWVvdXQpO1xuICAgIHRoaXMubWFpbi5kZXN0cm95KCk7XG5cbiAgICB0aGlzLm1haW4gPSB0aGlzLm5ld1Jvb3RWaWV3KG5ld01haW5FbCwgZmxhc2gsIGxpdmVSZWZlcmVyKTtcbiAgICB0aGlzLm1haW4uc2V0UmVkaXJlY3QoaHJlZik7XG4gICAgdGhpcy50cmFuc2l0aW9uUmVtb3ZlcyhyZW1vdmVFbHMpO1xuICAgIHRoaXMubWFpbi5qb2luKChqb2luQ291bnQsIG9uRG9uZSkgPT4ge1xuICAgICAgaWYgKGpvaW5Db3VudCA9PT0gMSAmJiB0aGlzLmNvbW1pdFBlbmRpbmdMaW5rKGxpbmtSZWYpKSB7XG4gICAgICAgIHRoaXMucmVxdWVzdERPTVVwZGF0ZSgoKSA9PiB7XG4gICAgICAgICAgLy8gcmVtb3ZlIHBoeC1yZW1vdmUgZWxzIHJpZ2h0IGJlZm9yZSB3ZSByZXBsYWNlIHRoZSBtYWluIGVsZW1lbnRcbiAgICAgICAgICByZW1vdmVFbHMuZm9yRWFjaCgoZWwpID0+IGVsLnJlbW92ZSgpKTtcbiAgICAgICAgICBzdGlja2llcy5mb3JFYWNoKChlbCkgPT4gbmV3TWFpbkVsLmFwcGVuZENoaWxkKGVsKSk7XG4gICAgICAgICAgdGhpcy5vdXRnb2luZ01haW5FbC5yZXBsYWNlV2l0aChuZXdNYWluRWwpO1xuICAgICAgICAgIHRoaXMub3V0Z29pbmdNYWluRWwgPSBudWxsO1xuICAgICAgICAgIGNhbGxiYWNrICYmIGNhbGxiYWNrKGxpbmtSZWYpO1xuICAgICAgICAgIG9uRG9uZSgpO1xuICAgICAgICB9KTtcbiAgICAgIH1cbiAgICB9KTtcbiAgfVxuXG4gIHRyYW5zaXRpb25SZW1vdmVzKGVsZW1lbnRzLCBjYWxsYmFjaykge1xuICAgIGNvbnN0IHJlbW92ZUF0dHIgPSB0aGlzLmJpbmRpbmcoXCJyZW1vdmVcIik7XG4gICAgY29uc3Qgc2lsZW5jZUV2ZW50cyA9IChlKSA9PiB7XG4gICAgICBlLnByZXZlbnREZWZhdWx0KCk7XG4gICAgICBlLnN0b3BJbW1lZGlhdGVQcm9wYWdhdGlvbigpO1xuICAgIH07XG4gICAgZWxlbWVudHMuZm9yRWFjaCgoZWwpID0+IHtcbiAgICAgIC8vIHByZXZlbnQgYWxsIGxpc3RlbmVycyB3ZSBjYXJlIGFib3V0IGZyb20gYnViYmxpbmcgdG8gd2luZG93XG4gICAgICAvLyBzaW5jZSB3ZSBhcmUgcmVtb3ZpbmcgdGhlIGVsZW1lbnRcbiAgICAgIGZvciAoY29uc3QgZXZlbnQgb2YgdGhpcy5ib3VuZEV2ZW50TmFtZXMpIHtcbiAgICAgICAgZWwuYWRkRXZlbnRMaXN0ZW5lcihldmVudCwgc2lsZW5jZUV2ZW50cywgdHJ1ZSk7XG4gICAgICB9XG4gICAgICB0aGlzLmV4ZWNKUyhlbCwgZWwuZ2V0QXR0cmlidXRlKHJlbW92ZUF0dHIpLCBcInJlbW92ZVwiKTtcbiAgICB9KTtcbiAgICAvLyByZW1vdmUgdGhlIHNpbGVuY2VkIGxpc3RlbmVycyB3aGVuIHRyYW5zaXRpb25zIGFyZSBkb25lIGluY2FzZSB0aGUgZWxlbWVudCBpcyByZS11c2VkXG4gICAgLy8gYW5kIGNhbGwgY2FsbGVyJ3MgY2FsbGJhY2sgYXMgc29vbiBhcyB3ZSBhcmUgZG9uZSB3aXRoIHRyYW5zaXRpb25zXG4gICAgdGhpcy5yZXF1ZXN0RE9NVXBkYXRlKCgpID0+IHtcbiAgICAgIGVsZW1lbnRzLmZvckVhY2goKGVsKSA9PiB7XG4gICAgICAgIGZvciAoY29uc3QgZXZlbnQgb2YgdGhpcy5ib3VuZEV2ZW50TmFtZXMpIHtcbiAgICAgICAgICBlbC5yZW1vdmVFdmVudExpc3RlbmVyKGV2ZW50LCBzaWxlbmNlRXZlbnRzLCB0cnVlKTtcbiAgICAgICAgfVxuICAgICAgfSk7XG4gICAgICBjYWxsYmFjayAmJiBjYWxsYmFjaygpO1xuICAgIH0pO1xuICB9XG5cbiAgaXNQaHhWaWV3KGVsKSB7XG4gICAgcmV0dXJuIGVsLmdldEF0dHJpYnV0ZSAmJiBlbC5nZXRBdHRyaWJ1dGUoUEhYX1NFU1NJT04pICE9PSBudWxsO1xuICB9XG5cbiAgbmV3Um9vdFZpZXcoZWwsIGZsYXNoLCBsaXZlUmVmZXJlcikge1xuICAgIGNvbnN0IHZpZXcgPSBuZXcgVmlldyhlbCwgdGhpcywgbnVsbCwgZmxhc2gsIGxpdmVSZWZlcmVyKTtcbiAgICB0aGlzLnJvb3RzW3ZpZXcuaWRdID0gdmlldztcbiAgICByZXR1cm4gdmlldztcbiAgfVxuXG4gIG93bmVyKGNoaWxkRWwsIGNhbGxiYWNrKSB7XG4gICAgbGV0IHZpZXc7XG4gICAgY29uc3Qgdmlld0VsID0gRE9NLmNsb3Nlc3RWaWV3RWwoY2hpbGRFbCk7XG4gICAgaWYgKHZpZXdFbCkge1xuICAgICAgLy8gaXQgY2FuIGhhcHBlbiB0aGF0IHdlIGZpbmQgYSB2aWV3IHRoYXQgaXMgYWxyZWFkeSBkZXN0cm95ZWQ7XG4gICAgICAvLyBpbiB0aGF0IGNhc2Ugd2UgRE8gTk9UIHdhbnQgdG8gZmFsbGJhY2sgdG8gdGhlIG1haW4gZWxlbWVudFxuICAgICAgdmlldyA9IHRoaXMuZ2V0Vmlld0J5RWwodmlld0VsKTtcbiAgICB9IGVsc2Uge1xuICAgICAgdmlldyA9IHRoaXMubWFpbjtcbiAgICB9XG4gICAgcmV0dXJuIHZpZXcgJiYgY2FsbGJhY2sgPyBjYWxsYmFjayh2aWV3KSA6IHZpZXc7XG4gIH1cblxuICB3aXRoaW5Pd25lcnMoY2hpbGRFbCwgY2FsbGJhY2spIHtcbiAgICB0aGlzLm93bmVyKGNoaWxkRWwsICh2aWV3KSA9PiBjYWxsYmFjayh2aWV3LCBjaGlsZEVsKSk7XG4gIH1cblxuICBnZXRWaWV3QnlFbChlbCkge1xuICAgIGNvbnN0IHJvb3RJZCA9IGVsLmdldEF0dHJpYnV0ZShQSFhfUk9PVF9JRCk7XG4gICAgcmV0dXJuIG1heWJlKHRoaXMuZ2V0Um9vdEJ5SWQocm9vdElkKSwgKHJvb3QpID0+XG4gICAgICByb290LmdldERlc2NlbmRlbnRCeUVsKGVsKSxcbiAgICApO1xuICB9XG5cbiAgZ2V0Um9vdEJ5SWQoaWQpIHtcbiAgICByZXR1cm4gdGhpcy5yb290c1tpZF07XG4gIH1cblxuICBkZXN0cm95QWxsVmlld3MoKSB7XG4gICAgZm9yIChjb25zdCBpZCBpbiB0aGlzLnJvb3RzKSB7XG4gICAgICB0aGlzLnJvb3RzW2lkXS5kZXN0cm95KCk7XG4gICAgICBkZWxldGUgdGhpcy5yb290c1tpZF07XG4gICAgfVxuICAgIHRoaXMubWFpbiA9IG51bGw7XG4gIH1cblxuICBkZXN0cm95Vmlld0J5RWwoZWwpIHtcbiAgICBjb25zdCByb290ID0gdGhpcy5nZXRSb290QnlJZChlbC5nZXRBdHRyaWJ1dGUoUEhYX1JPT1RfSUQpKTtcbiAgICBpZiAocm9vdCAmJiByb290LmlkID09PSBlbC5pZCkge1xuICAgICAgcm9vdC5kZXN0cm95KCk7XG4gICAgICBkZWxldGUgdGhpcy5yb290c1tyb290LmlkXTtcbiAgICB9IGVsc2UgaWYgKHJvb3QpIHtcbiAgICAgIHJvb3QuZGVzdHJveURlc2NlbmRlbnQoZWwuaWQpO1xuICAgIH1cbiAgfVxuXG4gIGdldEFjdGl2ZUVsZW1lbnQoKSB7XG4gICAgcmV0dXJuIGRvY3VtZW50LmFjdGl2ZUVsZW1lbnQ7XG4gIH1cblxuICBkcm9wQWN0aXZlRWxlbWVudCh2aWV3KSB7XG4gICAgaWYgKHRoaXMucHJldkFjdGl2ZSAmJiB2aWV3Lm93bnNFbGVtZW50KHRoaXMucHJldkFjdGl2ZSkpIHtcbiAgICAgIHRoaXMucHJldkFjdGl2ZSA9IG51bGw7XG4gICAgfVxuICB9XG5cbiAgcmVzdG9yZVByZXZpb3VzbHlBY3RpdmVGb2N1cygpIHtcbiAgICBpZiAoXG4gICAgICB0aGlzLnByZXZBY3RpdmUgJiZcbiAgICAgIHRoaXMucHJldkFjdGl2ZSAhPT0gZG9jdW1lbnQuYm9keSAmJlxuICAgICAgdGhpcy5wcmV2QWN0aXZlIGluc3RhbmNlb2YgSFRNTEVsZW1lbnRcbiAgICApIHtcbiAgICAgIHRoaXMucHJldkFjdGl2ZS5mb2N1cygpO1xuICAgIH1cbiAgfVxuXG4gIGJsdXJBY3RpdmVFbGVtZW50KCkge1xuICAgIHRoaXMucHJldkFjdGl2ZSA9IHRoaXMuZ2V0QWN0aXZlRWxlbWVudCgpO1xuICAgIGlmIChcbiAgICAgIHRoaXMucHJldkFjdGl2ZSAhPT0gZG9jdW1lbnQuYm9keSAmJlxuICAgICAgdGhpcy5wcmV2QWN0aXZlIGluc3RhbmNlb2YgSFRNTEVsZW1lbnRcbiAgICApIHtcbiAgICAgIHRoaXMucHJldkFjdGl2ZS5ibHVyKCk7XG4gICAgfVxuICB9XG5cbiAgLyoqXG4gICAqIEBwYXJhbSB7e2RlYWQ/OiBib29sZWFufX0gW29wdGlvbnM9e31dXG4gICAqL1xuICBiaW5kVG9wTGV2ZWxFdmVudHMoeyBkZWFkIH0gPSB7fSkge1xuICAgIGlmICh0aGlzLmJvdW5kVG9wTGV2ZWxFdmVudHMpIHtcbiAgICAgIHJldHVybjtcbiAgICB9XG5cbiAgICB0aGlzLmJvdW5kVG9wTGV2ZWxFdmVudHMgPSB0cnVlO1xuICAgIC8vIGVudGVyIGZhaWxzYWZlIHJlbG9hZCBpZiBzZXJ2ZXIgaGFzIGdvbmUgYXdheSBpbnRlbnRpb25hbGx5LCBzdWNoIGFzIFwiZGlzY29ubmVjdFwiIGJyb2FkY2FzdFxuICAgIHRoaXMuc2VydmVyQ2xvc2VSZWYgPSB0aGlzLnNvY2tldC5vbkNsb3NlKChldmVudCkgPT4ge1xuICAgICAgLy8gZmFpbHNhZmUgcmVsb2FkIGlmIG5vcm1hbCBjbG9zdXJlIGFuZCB3ZSBzdGlsbCBoYXZlIGEgbWFpbiBMVlxuICAgICAgaWYgKGV2ZW50ICYmIGV2ZW50LmNvZGUgPT09IDEwMDAgJiYgdGhpcy5tYWluKSB7XG4gICAgICAgIHJldHVybiB0aGlzLnJlbG9hZFdpdGhKaXR0ZXIodGhpcy5tYWluKTtcbiAgICAgIH1cbiAgICB9KTtcbiAgICBkb2N1bWVudC5ib2R5LmFkZEV2ZW50TGlzdGVuZXIoXCJjbGlja1wiLCBmdW5jdGlvbiAoKSB7fSk7IC8vIGVuc3VyZSBhbGwgY2xpY2sgZXZlbnRzIGJ1YmJsZSBmb3IgbW9iaWxlIFNhZmFyaVxuICAgIHdpbmRvdy5hZGRFdmVudExpc3RlbmVyKFxuICAgICAgXCJwYWdlc2hvd1wiLFxuICAgICAgKGUpID0+IHtcbiAgICAgICAgaWYgKGUucGVyc2lzdGVkKSB7XG4gICAgICAgICAgLy8gcmVsb2FkIHBhZ2UgaWYgYmVpbmcgcmVzdG9yZWQgZnJvbSBiYWNrL2ZvcndhcmQgY2FjaGVcbiAgICAgICAgICB0aGlzLmdldFNvY2tldCgpLmRpc2Nvbm5lY3QoKTtcbiAgICAgICAgICB0aGlzLndpdGhQYWdlTG9hZGluZyh7IHRvOiB3aW5kb3cubG9jYXRpb24uaHJlZiwga2luZDogXCJyZWRpcmVjdFwiIH0pO1xuICAgICAgICAgIHdpbmRvdy5sb2NhdGlvbi5yZWxvYWQoKTtcbiAgICAgICAgfVxuICAgICAgfSxcbiAgICAgIHRydWUsXG4gICAgKTtcbiAgICBpZiAoIWRlYWQpIHtcbiAgICAgIHRoaXMuYmluZE5hdigpO1xuICAgIH1cbiAgICB0aGlzLmJpbmRDbGlja3MoKTtcbiAgICBpZiAoIWRlYWQpIHtcbiAgICAgIHRoaXMuYmluZEZvcm1zKCk7XG4gICAgfVxuICAgIHRoaXMuYmluZChcbiAgICAgIHsga2V5dXA6IFwia2V5dXBcIiwga2V5ZG93bjogXCJrZXlkb3duXCIgfSxcbiAgICAgIChlLCB0eXBlLCB2aWV3LCB0YXJnZXRFbCwgcGh4RXZlbnQsIF9waHhUYXJnZXQpID0+IHtcbiAgICAgICAgY29uc3QgbWF0Y2hLZXkgPSB0YXJnZXRFbC5nZXRBdHRyaWJ1dGUodGhpcy5iaW5kaW5nKFBIWF9LRVkpKTtcbiAgICAgICAgY29uc3QgcHJlc3NlZEtleSA9IGUua2V5ICYmIGUua2V5LnRvTG93ZXJDYXNlKCk7IC8vIGNocm9tZSBjbGlja2VkIGF1dG9jb21wbGV0ZXMgc2VuZCBhIGtleWRvd24gd2l0aG91dCBrZXlcbiAgICAgICAgaWYgKG1hdGNoS2V5ICYmIG1hdGNoS2V5LnRvTG93ZXJDYXNlKCkgIT09IHByZXNzZWRLZXkpIHtcbiAgICAgICAgICByZXR1cm47XG4gICAgICAgIH1cblxuICAgICAgICBjb25zdCBkYXRhID0geyBrZXk6IGUua2V5LCAuLi50aGlzLmV2ZW50TWV0YSh0eXBlLCBlLCB0YXJnZXRFbCkgfTtcbiAgICAgICAgSlMuZXhlYyhlLCB0eXBlLCBwaHhFdmVudCwgdmlldywgdGFyZ2V0RWwsIFtcInB1c2hcIiwgeyBkYXRhIH1dKTtcbiAgICAgIH0sXG4gICAgKTtcbiAgICB0aGlzLmJpbmQoXG4gICAgICB7IGJsdXI6IFwiZm9jdXNvdXRcIiwgZm9jdXM6IFwiZm9jdXNpblwiIH0sXG4gICAgICAoZSwgdHlwZSwgdmlldywgdGFyZ2V0RWwsIHBoeEV2ZW50LCBwaHhUYXJnZXQpID0+IHtcbiAgICAgICAgaWYgKCFwaHhUYXJnZXQpIHtcbiAgICAgICAgICBjb25zdCBkYXRhID0geyBrZXk6IGUua2V5LCAuLi50aGlzLmV2ZW50TWV0YSh0eXBlLCBlLCB0YXJnZXRFbCkgfTtcbiAgICAgICAgICBKUy5leGVjKGUsIHR5cGUsIHBoeEV2ZW50LCB2aWV3LCB0YXJnZXRFbCwgW1wicHVzaFwiLCB7IGRhdGEgfV0pO1xuICAgICAgICB9XG4gICAgICB9LFxuICAgICk7XG4gICAgdGhpcy5iaW5kKFxuICAgICAgeyBibHVyOiBcImJsdXJcIiwgZm9jdXM6IFwiZm9jdXNcIiB9LFxuICAgICAgKGUsIHR5cGUsIHZpZXcsIHRhcmdldEVsLCBwaHhFdmVudCwgcGh4VGFyZ2V0KSA9PiB7XG4gICAgICAgIC8vIGJsdXIgYW5kIGZvY3VzIGFyZSB0cmlnZ2VyZWQgb24gZG9jdW1lbnQgYW5kIHdpbmRvdy4gRGlzY2FyZCBvbmUgdG8gYXZvaWQgZHVwc1xuICAgICAgICBpZiAocGh4VGFyZ2V0ID09PSBcIndpbmRvd1wiKSB7XG4gICAgICAgICAgY29uc3QgZGF0YSA9IHRoaXMuZXZlbnRNZXRhKHR5cGUsIGUsIHRhcmdldEVsKTtcbiAgICAgICAgICBKUy5leGVjKGUsIHR5cGUsIHBoeEV2ZW50LCB2aWV3LCB0YXJnZXRFbCwgW1wicHVzaFwiLCB7IGRhdGEgfV0pO1xuICAgICAgICB9XG4gICAgICB9LFxuICAgICk7XG4gICAgdGhpcy5vbihcImRyYWdvdmVyXCIsIChlKSA9PiBlLnByZXZlbnREZWZhdWx0KCkpO1xuICAgIHRoaXMub24oXCJkcm9wXCIsIChlKSA9PiB7XG4gICAgICBlLnByZXZlbnREZWZhdWx0KCk7XG4gICAgICBjb25zdCBkcm9wVGFyZ2V0SWQgPSBtYXliZShcbiAgICAgICAgY2xvc2VzdFBoeEJpbmRpbmcoZS50YXJnZXQsIHRoaXMuYmluZGluZyhQSFhfRFJPUF9UQVJHRVQpKSxcbiAgICAgICAgKHRydWVUYXJnZXQpID0+IHtcbiAgICAgICAgICByZXR1cm4gdHJ1ZVRhcmdldC5nZXRBdHRyaWJ1dGUodGhpcy5iaW5kaW5nKFBIWF9EUk9QX1RBUkdFVCkpO1xuICAgICAgICB9LFxuICAgICAgKTtcbiAgICAgIGNvbnN0IGRyb3BUYXJnZXQgPSBkcm9wVGFyZ2V0SWQgJiYgZG9jdW1lbnQuZ2V0RWxlbWVudEJ5SWQoZHJvcFRhcmdldElkKTtcbiAgICAgIGNvbnN0IGZpbGVzID0gQXJyYXkuZnJvbShlLmRhdGFUcmFuc2Zlci5maWxlcyB8fCBbXSk7XG4gICAgICBpZiAoXG4gICAgICAgICFkcm9wVGFyZ2V0IHx8XG4gICAgICAgICEoZHJvcFRhcmdldCBpbnN0YW5jZW9mIEhUTUxJbnB1dEVsZW1lbnQpIHx8XG4gICAgICAgIGRyb3BUYXJnZXQuZGlzYWJsZWQgfHxcbiAgICAgICAgZmlsZXMubGVuZ3RoID09PSAwIHx8XG4gICAgICAgICEoZHJvcFRhcmdldC5maWxlcyBpbnN0YW5jZW9mIEZpbGVMaXN0KVxuICAgICAgKSB7XG4gICAgICAgIHJldHVybjtcbiAgICAgIH1cblxuICAgICAgTGl2ZVVwbG9hZGVyLnRyYWNrRmlsZXMoZHJvcFRhcmdldCwgZmlsZXMsIGUuZGF0YVRyYW5zZmVyKTtcbiAgICAgIGRyb3BUYXJnZXQuZGlzcGF0Y2hFdmVudChuZXcgRXZlbnQoXCJpbnB1dFwiLCB7IGJ1YmJsZXM6IHRydWUgfSkpO1xuICAgIH0pO1xuICAgIHRoaXMub24oUEhYX1RSQUNLX1VQTE9BRFMsIChlKSA9PiB7XG4gICAgICBjb25zdCB1cGxvYWRUYXJnZXQgPSBlLnRhcmdldDtcbiAgICAgIGlmICghRE9NLmlzVXBsb2FkSW5wdXQodXBsb2FkVGFyZ2V0KSkge1xuICAgICAgICByZXR1cm47XG4gICAgICB9XG4gICAgICBjb25zdCBmaWxlcyA9IEFycmF5LmZyb20oZS5kZXRhaWwuZmlsZXMgfHwgW10pLmZpbHRlcihcbiAgICAgICAgKGYpID0+IGYgaW5zdGFuY2VvZiBGaWxlIHx8IGYgaW5zdGFuY2VvZiBCbG9iLFxuICAgICAgKTtcbiAgICAgIExpdmVVcGxvYWRlci50cmFja0ZpbGVzKHVwbG9hZFRhcmdldCwgZmlsZXMpO1xuICAgICAgdXBsb2FkVGFyZ2V0LmRpc3BhdGNoRXZlbnQobmV3IEV2ZW50KFwiaW5wdXRcIiwgeyBidWJibGVzOiB0cnVlIH0pKTtcbiAgICB9KTtcbiAgfVxuXG4gIGV2ZW50TWV0YShldmVudE5hbWUsIGUsIHRhcmdldEVsKSB7XG4gICAgY29uc3QgY2FsbGJhY2sgPSB0aGlzLm1ldGFkYXRhQ2FsbGJhY2tzW2V2ZW50TmFtZV07XG4gICAgcmV0dXJuIGNhbGxiYWNrID8gY2FsbGJhY2soZSwgdGFyZ2V0RWwpIDoge307XG4gIH1cblxuICBzZXRQZW5kaW5nTGluayhocmVmKSB7XG4gICAgdGhpcy5saW5rUmVmKys7XG4gICAgdGhpcy5wZW5kaW5nTGluayA9IGhyZWY7XG4gICAgdGhpcy5yZXNldFJlbG9hZFN0YXR1cygpO1xuICAgIHJldHVybiB0aGlzLmxpbmtSZWY7XG4gIH1cblxuICAvLyBhbnl0aW1lIHdlIGFyZSBuYXZpZ2F0aW5nIG9yIGNvbm5lY3RpbmcsIGRyb3AgcmVsb2FkIGNvb2tpZSBpbiBjYXNlXG4gIC8vIHdlIGlzc3VlIHRoZSBjb29raWUgYnV0IHRoZSBuZXh0IHJlcXVlc3Qgd2FzIGludGVycnVwdGVkIGFuZCB0aGUgc2VydmVyIG5ldmVyIGRyb3BwZWQgaXRcbiAgcmVzZXRSZWxvYWRTdGF0dXMoKSB7XG4gICAgQnJvd3Nlci5kZWxldGVDb29raWUoUEhYX1JFTE9BRF9TVEFUVVMpO1xuICB9XG5cbiAgY29tbWl0UGVuZGluZ0xpbmsobGlua1JlZikge1xuICAgIGlmICh0aGlzLmxpbmtSZWYgIT09IGxpbmtSZWYpIHtcbiAgICAgIHJldHVybiBmYWxzZTtcbiAgICB9IGVsc2Uge1xuICAgICAgdGhpcy5ocmVmID0gdGhpcy5wZW5kaW5nTGluaztcbiAgICAgIHRoaXMucGVuZGluZ0xpbmsgPSBudWxsO1xuICAgICAgcmV0dXJuIHRydWU7XG4gICAgfVxuICB9XG5cbiAgZ2V0SHJlZigpIHtcbiAgICByZXR1cm4gdGhpcy5ocmVmO1xuICB9XG5cbiAgaGFzUGVuZGluZ0xpbmsoKSB7XG4gICAgcmV0dXJuICEhdGhpcy5wZW5kaW5nTGluaztcbiAgfVxuXG4gIGJpbmQoZXZlbnRzLCBjYWxsYmFjaykge1xuICAgIGZvciAoY29uc3QgZXZlbnQgaW4gZXZlbnRzKSB7XG4gICAgICBjb25zdCBicm93c2VyRXZlbnROYW1lID0gZXZlbnRzW2V2ZW50XTtcblxuICAgICAgdGhpcy5vbihicm93c2VyRXZlbnROYW1lLCAoZSkgPT4ge1xuICAgICAgICBjb25zdCBiaW5kaW5nID0gdGhpcy5iaW5kaW5nKGV2ZW50KTtcbiAgICAgICAgY29uc3Qgd2luZG93QmluZGluZyA9IHRoaXMuYmluZGluZyhgd2luZG93LSR7ZXZlbnR9YCk7XG4gICAgICAgIGNvbnN0IHRhcmdldFBoeEV2ZW50ID1cbiAgICAgICAgICBlLnRhcmdldC5nZXRBdHRyaWJ1dGUgJiYgZS50YXJnZXQuZ2V0QXR0cmlidXRlKGJpbmRpbmcpO1xuICAgICAgICBpZiAodGFyZ2V0UGh4RXZlbnQpIHtcbiAgICAgICAgICB0aGlzLmRlYm91bmNlKGUudGFyZ2V0LCBlLCBicm93c2VyRXZlbnROYW1lLCAoKSA9PiB7XG4gICAgICAgICAgICB0aGlzLndpdGhpbk93bmVycyhlLnRhcmdldCwgKHZpZXcpID0+IHtcbiAgICAgICAgICAgICAgY2FsbGJhY2soZSwgZXZlbnQsIHZpZXcsIGUudGFyZ2V0LCB0YXJnZXRQaHhFdmVudCwgbnVsbCk7XG4gICAgICAgICAgICB9KTtcbiAgICAgICAgICB9KTtcbiAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICBET00uYWxsKGRvY3VtZW50LCBgWyR7d2luZG93QmluZGluZ31dYCwgKGVsKSA9PiB7XG4gICAgICAgICAgICBjb25zdCBwaHhFdmVudCA9IGVsLmdldEF0dHJpYnV0ZSh3aW5kb3dCaW5kaW5nKTtcbiAgICAgICAgICAgIHRoaXMuZGVib3VuY2UoZWwsIGUsIGJyb3dzZXJFdmVudE5hbWUsICgpID0+IHtcbiAgICAgICAgICAgICAgdGhpcy53aXRoaW5Pd25lcnMoZWwsICh2aWV3KSA9PiB7XG4gICAgICAgICAgICAgICAgY2FsbGJhY2soZSwgZXZlbnQsIHZpZXcsIGVsLCBwaHhFdmVudCwgXCJ3aW5kb3dcIik7XG4gICAgICAgICAgICAgIH0pO1xuICAgICAgICAgICAgfSk7XG4gICAgICAgICAgfSk7XG4gICAgICAgIH1cbiAgICAgIH0pO1xuICAgIH1cbiAgfVxuXG4gIGJpbmRDbGlja3MoKSB7XG4gICAgdGhpcy5vbihcIm1vdXNlZG93blwiLCAoZSkgPT4gKHRoaXMuY2xpY2tTdGFydGVkQXRUYXJnZXQgPSBlLnRhcmdldCkpO1xuICAgIHRoaXMuYmluZENsaWNrKFwiY2xpY2tcIiwgXCJjbGlja1wiKTtcbiAgfVxuXG4gIGJpbmRDbGljayhldmVudE5hbWUsIGJpbmRpbmdOYW1lKSB7XG4gICAgY29uc3QgY2xpY2sgPSB0aGlzLmJpbmRpbmcoYmluZGluZ05hbWUpO1xuICAgIHdpbmRvdy5hZGRFdmVudExpc3RlbmVyKFxuICAgICAgZXZlbnROYW1lLFxuICAgICAgKGUpID0+IHtcbiAgICAgICAgbGV0IHRhcmdldCA9IG51bGw7XG4gICAgICAgIC8vIGEgc3ludGhldGljIGNsaWNrIGV2ZW50IChkZXRhaWwgMCkgd2lsbCBub3QgaGF2ZSBjYXVzZWQgYSBtb3VzZWRvd24gZXZlbnQsXG4gICAgICAgIC8vIHRoZXJlZm9yZSB0aGUgY2xpY2tTdGFydGVkQXRUYXJnZXQgaXMgc3RhbGVcbiAgICAgICAgaWYgKGUuZGV0YWlsID09PSAwKSB0aGlzLmNsaWNrU3RhcnRlZEF0VGFyZ2V0ID0gZS50YXJnZXQ7XG4gICAgICAgIGNvbnN0IGNsaWNrU3RhcnRlZEF0VGFyZ2V0ID0gdGhpcy5jbGlja1N0YXJ0ZWRBdFRhcmdldCB8fCBlLnRhcmdldDtcbiAgICAgICAgLy8gd2hlbiBzZWFyY2hpbmcgdGhlIHRhcmdldCBmb3IgdGhlIGNsaWNrIGV2ZW50LCB3ZSBhbHdheXMgd2FudCB0b1xuICAgICAgICAvLyB1c2UgdGhlIGFjdHVhbCBldmVudCB0YXJnZXQsIHNlZSAjMzM3MlxuICAgICAgICB0YXJnZXQgPSBjbG9zZXN0UGh4QmluZGluZyhlLnRhcmdldCwgY2xpY2spO1xuICAgICAgICB0aGlzLmRpc3BhdGNoQ2xpY2tBd2F5KGUsIGNsaWNrU3RhcnRlZEF0VGFyZ2V0KTtcbiAgICAgICAgdGhpcy5jbGlja1N0YXJ0ZWRBdFRhcmdldCA9IG51bGw7XG4gICAgICAgIGNvbnN0IHBoeEV2ZW50ID0gdGFyZ2V0ICYmIHRhcmdldC5nZXRBdHRyaWJ1dGUoY2xpY2spO1xuICAgICAgICBpZiAoIXBoeEV2ZW50KSB7XG4gICAgICAgICAgaWYgKERPTS5pc05ld1BhZ2VDbGljayhlLCB3aW5kb3cubG9jYXRpb24pKSB7XG4gICAgICAgICAgICB0aGlzLnVubG9hZCgpO1xuICAgICAgICAgIH1cbiAgICAgICAgICByZXR1cm47XG4gICAgICAgIH1cblxuICAgICAgICBpZiAodGFyZ2V0LmdldEF0dHJpYnV0ZShcImhyZWZcIikgPT09IFwiI1wiKSB7XG4gICAgICAgICAgZS5wcmV2ZW50RGVmYXVsdCgpO1xuICAgICAgICB9XG5cbiAgICAgICAgLy8gbm9vcCBpZiB3ZSBhcmUgaW4gdGhlIG1pZGRsZSBvZiBhd2FpdGluZyBhbiBhY2sgZm9yIHRoaXMgZWwgYWxyZWFkeVxuICAgICAgICBpZiAodGFyZ2V0Lmhhc0F0dHJpYnV0ZShQSFhfUkVGX1NSQykpIHtcbiAgICAgICAgICByZXR1cm47XG4gICAgICAgIH1cblxuICAgICAgICB0aGlzLmRlYm91bmNlKHRhcmdldCwgZSwgXCJjbGlja1wiLCAoKSA9PiB7XG4gICAgICAgICAgdGhpcy53aXRoaW5Pd25lcnModGFyZ2V0LCAodmlldykgPT4ge1xuICAgICAgICAgICAgSlMuZXhlYyhlLCBcImNsaWNrXCIsIHBoeEV2ZW50LCB2aWV3LCB0YXJnZXQsIFtcbiAgICAgICAgICAgICAgXCJwdXNoXCIsXG4gICAgICAgICAgICAgIHsgZGF0YTogdGhpcy5ldmVudE1ldGEoXCJjbGlja1wiLCBlLCB0YXJnZXQpIH0sXG4gICAgICAgICAgICBdKTtcbiAgICAgICAgICB9KTtcbiAgICAgICAgfSk7XG4gICAgICB9LFxuICAgICAgZmFsc2UsXG4gICAgKTtcbiAgfVxuXG4gIGRpc3BhdGNoQ2xpY2tBd2F5KGUsIGNsaWNrU3RhcnRlZEF0KSB7XG4gICAgY29uc3QgcGh4Q2xpY2tBd2F5ID0gdGhpcy5iaW5kaW5nKFwiY2xpY2stYXdheVwiKTtcbiAgICBET00uYWxsKGRvY3VtZW50LCBgWyR7cGh4Q2xpY2tBd2F5fV1gLCAoZWwpID0+IHtcbiAgICAgIGlmICghKGVsLmlzU2FtZU5vZGUoY2xpY2tTdGFydGVkQXQpIHx8IGVsLmNvbnRhaW5zKGNsaWNrU3RhcnRlZEF0KSkpIHtcbiAgICAgICAgdGhpcy53aXRoaW5Pd25lcnMoZWwsICh2aWV3KSA9PiB7XG4gICAgICAgICAgY29uc3QgcGh4RXZlbnQgPSBlbC5nZXRBdHRyaWJ1dGUocGh4Q2xpY2tBd2F5KTtcbiAgICAgICAgICBpZiAoSlMuaXNWaXNpYmxlKGVsKSAmJiBKUy5pc0luVmlld3BvcnQoZWwpKSB7XG4gICAgICAgICAgICBKUy5leGVjKGUsIFwiY2xpY2tcIiwgcGh4RXZlbnQsIHZpZXcsIGVsLCBbXG4gICAgICAgICAgICAgIFwicHVzaFwiLFxuICAgICAgICAgICAgICB7IGRhdGE6IHRoaXMuZXZlbnRNZXRhKFwiY2xpY2tcIiwgZSwgZS50YXJnZXQpIH0sXG4gICAgICAgICAgICBdKTtcbiAgICAgICAgICB9XG4gICAgICAgIH0pO1xuICAgICAgfVxuICAgIH0pO1xuICB9XG5cbiAgYmluZE5hdigpIHtcbiAgICBpZiAoIUJyb3dzZXIuY2FuUHVzaFN0YXRlKCkpIHtcbiAgICAgIHJldHVybjtcbiAgICB9XG4gICAgaWYgKGhpc3Rvcnkuc2Nyb2xsUmVzdG9yYXRpb24pIHtcbiAgICAgIGhpc3Rvcnkuc2Nyb2xsUmVzdG9yYXRpb24gPSBcIm1hbnVhbFwiO1xuICAgIH1cbiAgICBsZXQgc2Nyb2xsVGltZXIgPSBudWxsO1xuICAgIHdpbmRvdy5hZGRFdmVudExpc3RlbmVyKFwic2Nyb2xsXCIsIChfZSkgPT4ge1xuICAgICAgY2xlYXJUaW1lb3V0KHNjcm9sbFRpbWVyKTtcbiAgICAgIHNjcm9sbFRpbWVyID0gc2V0VGltZW91dCgoKSA9PiB7XG4gICAgICAgIEJyb3dzZXIudXBkYXRlQ3VycmVudFN0YXRlKChzdGF0ZSkgPT5cbiAgICAgICAgICBPYmplY3QuYXNzaWduKHN0YXRlLCB7IHNjcm9sbDogd2luZG93LnNjcm9sbFkgfSksXG4gICAgICAgICk7XG4gICAgICB9LCAxMDApO1xuICAgIH0pO1xuICAgIHdpbmRvdy5hZGRFdmVudExpc3RlbmVyKFxuICAgICAgXCJwb3BzdGF0ZVwiLFxuICAgICAgKGV2ZW50KSA9PiB7XG4gICAgICAgIGlmICghdGhpcy5yZWdpc3Rlck5ld0xvY2F0aW9uKHdpbmRvdy5sb2NhdGlvbikpIHtcbiAgICAgICAgICByZXR1cm47XG4gICAgICAgIH1cbiAgICAgICAgY29uc3QgeyB0eXBlLCBiYWNrVHlwZSwgaWQsIHNjcm9sbCwgcG9zaXRpb24gfSA9IGV2ZW50LnN0YXRlIHx8IHt9O1xuICAgICAgICBjb25zdCBocmVmID0gd2luZG93LmxvY2F0aW9uLmhyZWY7XG5cbiAgICAgICAgLy8gQ29tcGFyZSBwb3NpdGlvbnMgdG8gZGV0ZXJtaW5lIGRpcmVjdGlvblxuICAgICAgICBjb25zdCBpc0ZvcndhcmQgPSBwb3NpdGlvbiA+IHRoaXMuY3VycmVudEhpc3RvcnlQb3NpdGlvbjtcbiAgICAgICAgY29uc3QgbmF2VHlwZSA9IGlzRm9yd2FyZCA/IHR5cGUgOiBiYWNrVHlwZSB8fCB0eXBlO1xuXG4gICAgICAgIC8vIFVwZGF0ZSBjdXJyZW50IHBvc2l0aW9uXG4gICAgICAgIHRoaXMuY3VycmVudEhpc3RvcnlQb3NpdGlvbiA9IHBvc2l0aW9uIHx8IDA7XG4gICAgICAgIHRoaXMuc2Vzc2lvblN0b3JhZ2Uuc2V0SXRlbShcbiAgICAgICAgICBQSFhfTFZfSElTVE9SWV9QT1NJVElPTixcbiAgICAgICAgICB0aGlzLmN1cnJlbnRIaXN0b3J5UG9zaXRpb24udG9TdHJpbmcoKSxcbiAgICAgICAgKTtcblxuICAgICAgICBET00uZGlzcGF0Y2hFdmVudCh3aW5kb3csIFwicGh4Om5hdmlnYXRlXCIsIHtcbiAgICAgICAgICBkZXRhaWw6IHtcbiAgICAgICAgICAgIGhyZWYsXG4gICAgICAgICAgICBwYXRjaDogbmF2VHlwZSA9PT0gXCJwYXRjaFwiLFxuICAgICAgICAgICAgcG9wOiB0cnVlLFxuICAgICAgICAgICAgZGlyZWN0aW9uOiBpc0ZvcndhcmQgPyBcImZvcndhcmRcIiA6IFwiYmFja3dhcmRcIixcbiAgICAgICAgICB9LFxuICAgICAgICB9KTtcbiAgICAgICAgdGhpcy5yZXF1ZXN0RE9NVXBkYXRlKCgpID0+IHtcbiAgICAgICAgICBjb25zdCBjYWxsYmFjayA9ICgpID0+IHtcbiAgICAgICAgICAgIHRoaXMubWF5YmVTY3JvbGwoc2Nyb2xsKTtcbiAgICAgICAgICB9O1xuICAgICAgICAgIGlmIChcbiAgICAgICAgICAgIHRoaXMubWFpbi5pc0Nvbm5lY3RlZCgpICYmXG4gICAgICAgICAgICBuYXZUeXBlID09PSBcInBhdGNoXCIgJiZcbiAgICAgICAgICAgIGlkID09PSB0aGlzLm1haW4uaWRcbiAgICAgICAgICApIHtcbiAgICAgICAgICAgIHRoaXMubWFpbi5wdXNoTGlua1BhdGNoKGV2ZW50LCBocmVmLCBudWxsLCBjYWxsYmFjayk7XG4gICAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAgIHRoaXMucmVwbGFjZU1haW4oaHJlZiwgbnVsbCwgY2FsbGJhY2spO1xuICAgICAgICAgIH1cbiAgICAgICAgfSk7XG4gICAgICB9LFxuICAgICAgZmFsc2UsXG4gICAgKTtcbiAgICB3aW5kb3cuYWRkRXZlbnRMaXN0ZW5lcihcbiAgICAgIFwiY2xpY2tcIixcbiAgICAgIChlKSA9PiB7XG4gICAgICAgIGNvbnN0IHRhcmdldCA9IGNsb3Nlc3RQaHhCaW5kaW5nKGUudGFyZ2V0LCBQSFhfTElWRV9MSU5LKTtcbiAgICAgICAgY29uc3QgdHlwZSA9IHRhcmdldCAmJiB0YXJnZXQuZ2V0QXR0cmlidXRlKFBIWF9MSVZFX0xJTkspO1xuICAgICAgICBpZiAoIXR5cGUgfHwgIXRoaXMuaXNDb25uZWN0ZWQoKSB8fCAhdGhpcy5tYWluIHx8IERPTS53YW50c05ld1RhYihlKSkge1xuICAgICAgICAgIHJldHVybjtcbiAgICAgICAgfVxuXG4gICAgICAgIC8vIFdoZW4gd3JhcHBpbmcgYW4gU1ZHIGVsZW1lbnQgaW4gYW4gYW5jaG9yIHRhZywgdGhlIGhyZWYgY2FuIGJlIGFuIFNWR0FuaW1hdGVkU3RyaW5nXG4gICAgICAgIGNvbnN0IGhyZWYgPVxuICAgICAgICAgIHRhcmdldC5ocmVmIGluc3RhbmNlb2YgU1ZHQW5pbWF0ZWRTdHJpbmdcbiAgICAgICAgICAgID8gdGFyZ2V0LmhyZWYuYmFzZVZhbFxuICAgICAgICAgICAgOiB0YXJnZXQuaHJlZjtcblxuICAgICAgICBjb25zdCBsaW5rU3RhdGUgPSB0YXJnZXQuZ2V0QXR0cmlidXRlKFBIWF9MSU5LX1NUQVRFKTtcbiAgICAgICAgZS5wcmV2ZW50RGVmYXVsdCgpO1xuICAgICAgICBlLnN0b3BJbW1lZGlhdGVQcm9wYWdhdGlvbigpOyAvLyBkbyBub3QgYnViYmxlIGNsaWNrIHRvIHJlZ3VsYXIgcGh4LWNsaWNrIGJpbmRpbmdzXG4gICAgICAgIGlmICh0aGlzLnBlbmRpbmdMaW5rID09PSBocmVmKSB7XG4gICAgICAgICAgcmV0dXJuO1xuICAgICAgICB9XG5cbiAgICAgICAgdGhpcy5yZXF1ZXN0RE9NVXBkYXRlKCgpID0+IHtcbiAgICAgICAgICBpZiAodHlwZSA9PT0gXCJwYXRjaFwiKSB7XG4gICAgICAgICAgICB0aGlzLnB1c2hIaXN0b3J5UGF0Y2goZSwgaHJlZiwgbGlua1N0YXRlLCB0YXJnZXQpO1xuICAgICAgICAgIH0gZWxzZSBpZiAodHlwZSA9PT0gXCJyZWRpcmVjdFwiKSB7XG4gICAgICAgICAgICB0aGlzLmhpc3RvcnlSZWRpcmVjdChlLCBocmVmLCBsaW5rU3RhdGUsIG51bGwsIHRhcmdldCk7XG4gICAgICAgICAgfSBlbHNlIHtcbiAgICAgICAgICAgIHRocm93IG5ldyBFcnJvcihcbiAgICAgICAgICAgICAgYGV4cGVjdGVkICR7UEhYX0xJVkVfTElOS30gdG8gYmUgXCJwYXRjaFwiIG9yIFwicmVkaXJlY3RcIiwgZ290OiAke3R5cGV9YCxcbiAgICAgICAgICAgICk7XG4gICAgICAgICAgfVxuICAgICAgICAgIGNvbnN0IHBoeENsaWNrID0gdGFyZ2V0LmdldEF0dHJpYnV0ZSh0aGlzLmJpbmRpbmcoXCJjbGlja1wiKSk7XG4gICAgICAgICAgaWYgKHBoeENsaWNrKSB7XG4gICAgICAgICAgICB0aGlzLnJlcXVlc3RET01VcGRhdGUoKCkgPT4gdGhpcy5leGVjSlModGFyZ2V0LCBwaHhDbGljaywgXCJjbGlja1wiKSk7XG4gICAgICAgICAgfVxuICAgICAgICB9KTtcbiAgICAgIH0sXG4gICAgICBmYWxzZSxcbiAgICApO1xuICB9XG5cbiAgbWF5YmVTY3JvbGwoc2Nyb2xsKSB7XG4gICAgaWYgKHR5cGVvZiBzY3JvbGwgPT09IFwibnVtYmVyXCIpIHtcbiAgICAgIHJlcXVlc3RBbmltYXRpb25GcmFtZSgoKSA9PiB7XG4gICAgICAgIHdpbmRvdy5zY3JvbGxUbygwLCBzY3JvbGwpO1xuICAgICAgfSk7IC8vIHRoZSBib2R5IG5lZWRzIHRvIHJlbmRlciBiZWZvcmUgd2Ugc2Nyb2xsLlxuICAgIH1cbiAgfVxuXG4gIGRpc3BhdGNoRXZlbnQoZXZlbnQsIHBheWxvYWQgPSB7fSkge1xuICAgIERPTS5kaXNwYXRjaEV2ZW50KHdpbmRvdywgYHBoeDoke2V2ZW50fWAsIHsgZGV0YWlsOiBwYXlsb2FkIH0pO1xuICB9XG5cbiAgZGlzcGF0Y2hFdmVudHMoZXZlbnRzKSB7XG4gICAgZXZlbnRzLmZvckVhY2goKFtldmVudCwgcGF5bG9hZF0pID0+IHRoaXMuZGlzcGF0Y2hFdmVudChldmVudCwgcGF5bG9hZCkpO1xuICB9XG5cbiAgd2l0aFBhZ2VMb2FkaW5nKGluZm8sIGNhbGxiYWNrKSB7XG4gICAgRE9NLmRpc3BhdGNoRXZlbnQod2luZG93LCBcInBoeDpwYWdlLWxvYWRpbmctc3RhcnRcIiwgeyBkZXRhaWw6IGluZm8gfSk7XG4gICAgY29uc3QgZG9uZSA9ICgpID0+XG4gICAgICBET00uZGlzcGF0Y2hFdmVudCh3aW5kb3csIFwicGh4OnBhZ2UtbG9hZGluZy1zdG9wXCIsIHsgZGV0YWlsOiBpbmZvIH0pO1xuICAgIHJldHVybiBjYWxsYmFjayA/IGNhbGxiYWNrKGRvbmUpIDogZG9uZTtcbiAgfVxuXG4gIHB1c2hIaXN0b3J5UGF0Y2goZSwgaHJlZiwgbGlua1N0YXRlLCB0YXJnZXRFbCkge1xuICAgIGlmICghdGhpcy5pc0Nvbm5lY3RlZCgpIHx8ICF0aGlzLm1haW4uaXNNYWluKCkpIHtcbiAgICAgIHJldHVybiBCcm93c2VyLnJlZGlyZWN0KGhyZWYpO1xuICAgIH1cblxuICAgIHRoaXMud2l0aFBhZ2VMb2FkaW5nKHsgdG86IGhyZWYsIGtpbmQ6IFwicGF0Y2hcIiB9LCAoZG9uZSkgPT4ge1xuICAgICAgdGhpcy5tYWluLnB1c2hMaW5rUGF0Y2goZSwgaHJlZiwgdGFyZ2V0RWwsIChsaW5rUmVmKSA9PiB7XG4gICAgICAgIHRoaXMuaGlzdG9yeVBhdGNoKGhyZWYsIGxpbmtTdGF0ZSwgbGlua1JlZik7XG4gICAgICAgIGRvbmUoKTtcbiAgICAgIH0pO1xuICAgIH0pO1xuICB9XG5cbiAgaGlzdG9yeVBhdGNoKGhyZWYsIGxpbmtTdGF0ZSwgbGlua1JlZiA9IHRoaXMuc2V0UGVuZGluZ0xpbmsoaHJlZikpIHtcbiAgICBpZiAoIXRoaXMuY29tbWl0UGVuZGluZ0xpbmsobGlua1JlZikpIHtcbiAgICAgIHJldHVybjtcbiAgICB9XG5cbiAgICAvLyBJbmNyZW1lbnQgcG9zaXRpb24gZm9yIG5ldyBzdGF0ZVxuICAgIHRoaXMuY3VycmVudEhpc3RvcnlQb3NpdGlvbisrO1xuICAgIHRoaXMuc2Vzc2lvblN0b3JhZ2Uuc2V0SXRlbShcbiAgICAgIFBIWF9MVl9ISVNUT1JZX1BPU0lUSU9OLFxuICAgICAgdGhpcy5jdXJyZW50SGlzdG9yeVBvc2l0aW9uLnRvU3RyaW5nKCksXG4gICAgKTtcblxuICAgIC8vIHN0b3JlIHRoZSB0eXBlIGZvciBiYWNrIG5hdmlnYXRpb25cbiAgICBCcm93c2VyLnVwZGF0ZUN1cnJlbnRTdGF0ZSgoc3RhdGUpID0+ICh7IC4uLnN0YXRlLCBiYWNrVHlwZTogXCJwYXRjaFwiIH0pKTtcblxuICAgIEJyb3dzZXIucHVzaFN0YXRlKFxuICAgICAgbGlua1N0YXRlLFxuICAgICAge1xuICAgICAgICB0eXBlOiBcInBhdGNoXCIsXG4gICAgICAgIGlkOiB0aGlzLm1haW4uaWQsXG4gICAgICAgIHBvc2l0aW9uOiB0aGlzLmN1cnJlbnRIaXN0b3J5UG9zaXRpb24sXG4gICAgICB9LFxuICAgICAgaHJlZixcbiAgICApO1xuXG4gICAgRE9NLmRpc3BhdGNoRXZlbnQod2luZG93LCBcInBoeDpuYXZpZ2F0ZVwiLCB7XG4gICAgICBkZXRhaWw6IHsgcGF0Y2g6IHRydWUsIGhyZWYsIHBvcDogZmFsc2UsIGRpcmVjdGlvbjogXCJmb3J3YXJkXCIgfSxcbiAgICB9KTtcbiAgICB0aGlzLnJlZ2lzdGVyTmV3TG9jYXRpb24od2luZG93LmxvY2F0aW9uKTtcbiAgfVxuXG4gIGhpc3RvcnlSZWRpcmVjdChlLCBocmVmLCBsaW5rU3RhdGUsIGZsYXNoLCB0YXJnZXRFbCkge1xuICAgIGNvbnN0IGNsaWNrTG9hZGluZyA9IHRhcmdldEVsICYmIGUuaXNUcnVzdGVkICYmIGUudHlwZSAhPT0gXCJwb3BzdGF0ZVwiO1xuICAgIGlmIChjbGlja0xvYWRpbmcpIHtcbiAgICAgIHRhcmdldEVsLmNsYXNzTGlzdC5hZGQoXCJwaHgtY2xpY2stbG9hZGluZ1wiKTtcbiAgICB9XG4gICAgaWYgKCF0aGlzLmlzQ29ubmVjdGVkKCkgfHwgIXRoaXMubWFpbi5pc01haW4oKSkge1xuICAgICAgcmV0dXJuIEJyb3dzZXIucmVkaXJlY3QoaHJlZiwgZmxhc2gpO1xuICAgIH1cblxuICAgIC8vIGNvbnZlcnQgdG8gZnVsbCBocmVmIGlmIG9ubHkgcGF0aCBwcmVmaXhcbiAgICBpZiAoL15cXC8kfF5cXC9bXlxcL10rLiokLy50ZXN0KGhyZWYpKSB7XG4gICAgICBjb25zdCB7IHByb3RvY29sLCBob3N0IH0gPSB3aW5kb3cubG9jYXRpb247XG4gICAgICBocmVmID0gYCR7cHJvdG9jb2x9Ly8ke2hvc3R9JHtocmVmfWA7XG4gICAgfVxuICAgIGNvbnN0IHNjcm9sbCA9IHdpbmRvdy5zY3JvbGxZO1xuICAgIHRoaXMud2l0aFBhZ2VMb2FkaW5nKHsgdG86IGhyZWYsIGtpbmQ6IFwicmVkaXJlY3RcIiB9LCAoZG9uZSkgPT4ge1xuICAgICAgdGhpcy5yZXBsYWNlTWFpbihocmVmLCBmbGFzaCwgKGxpbmtSZWYpID0+IHtcbiAgICAgICAgaWYgKGxpbmtSZWYgPT09IHRoaXMubGlua1JlZikge1xuICAgICAgICAgIC8vIEluY3JlbWVudCBwb3NpdGlvbiBmb3IgbmV3IHN0YXRlXG4gICAgICAgICAgdGhpcy5jdXJyZW50SGlzdG9yeVBvc2l0aW9uKys7XG4gICAgICAgICAgdGhpcy5zZXNzaW9uU3RvcmFnZS5zZXRJdGVtKFxuICAgICAgICAgICAgUEhYX0xWX0hJU1RPUllfUE9TSVRJT04sXG4gICAgICAgICAgICB0aGlzLmN1cnJlbnRIaXN0b3J5UG9zaXRpb24udG9TdHJpbmcoKSxcbiAgICAgICAgICApO1xuXG4gICAgICAgICAgLy8gc3RvcmUgdGhlIHR5cGUgZm9yIGJhY2sgbmF2aWdhdGlvblxuICAgICAgICAgIEJyb3dzZXIudXBkYXRlQ3VycmVudFN0YXRlKChzdGF0ZSkgPT4gKHtcbiAgICAgICAgICAgIC4uLnN0YXRlLFxuICAgICAgICAgICAgYmFja1R5cGU6IFwicmVkaXJlY3RcIixcbiAgICAgICAgICB9KSk7XG5cbiAgICAgICAgICBCcm93c2VyLnB1c2hTdGF0ZShcbiAgICAgICAgICAgIGxpbmtTdGF0ZSxcbiAgICAgICAgICAgIHtcbiAgICAgICAgICAgICAgdHlwZTogXCJyZWRpcmVjdFwiLFxuICAgICAgICAgICAgICBpZDogdGhpcy5tYWluLmlkLFxuICAgICAgICAgICAgICBzY3JvbGw6IHNjcm9sbCxcbiAgICAgICAgICAgICAgcG9zaXRpb246IHRoaXMuY3VycmVudEhpc3RvcnlQb3NpdGlvbixcbiAgICAgICAgICAgIH0sXG4gICAgICAgICAgICBocmVmLFxuICAgICAgICAgICk7XG5cbiAgICAgICAgICBET00uZGlzcGF0Y2hFdmVudCh3aW5kb3csIFwicGh4Om5hdmlnYXRlXCIsIHtcbiAgICAgICAgICAgIGRldGFpbDogeyBocmVmLCBwYXRjaDogZmFsc2UsIHBvcDogZmFsc2UsIGRpcmVjdGlvbjogXCJmb3J3YXJkXCIgfSxcbiAgICAgICAgICB9KTtcbiAgICAgICAgICB0aGlzLnJlZ2lzdGVyTmV3TG9jYXRpb24od2luZG93LmxvY2F0aW9uKTtcbiAgICAgICAgfVxuICAgICAgICAvLyBleHBsaWNpdGx5IHVuZG8gY2xpY2stbG9hZGluZyBjbGFzc1xuICAgICAgICAvLyAoaW4gY2FzZSBpdCBvcmlnaW5hdGVkIGluIGEgc3RpY2t5IGxpdmUgdmlldywgb3RoZXJ3aXNlIGl0IHdvdWxkIGJlIHJlbW92ZWQgYW55d2F5KVxuICAgICAgICBpZiAoY2xpY2tMb2FkaW5nKSB7XG4gICAgICAgICAgdGFyZ2V0RWwuY2xhc3NMaXN0LnJlbW92ZShcInBoeC1jbGljay1sb2FkaW5nXCIpO1xuICAgICAgICB9XG4gICAgICAgIGRvbmUoKTtcbiAgICAgIH0pO1xuICAgIH0pO1xuICB9XG5cbiAgcmVnaXN0ZXJOZXdMb2NhdGlvbihuZXdMb2NhdGlvbikge1xuICAgIGNvbnN0IHsgcGF0aG5hbWUsIHNlYXJjaCB9ID0gdGhpcy5jdXJyZW50TG9jYXRpb247XG4gICAgaWYgKHBhdGhuYW1lICsgc2VhcmNoID09PSBuZXdMb2NhdGlvbi5wYXRobmFtZSArIG5ld0xvY2F0aW9uLnNlYXJjaCkge1xuICAgICAgcmV0dXJuIGZhbHNlO1xuICAgIH0gZWxzZSB7XG4gICAgICB0aGlzLmN1cnJlbnRMb2NhdGlvbiA9IGNsb25lKG5ld0xvY2F0aW9uKTtcbiAgICAgIHJldHVybiB0cnVlO1xuICAgIH1cbiAgfVxuXG4gIGJpbmRGb3JtcygpIHtcbiAgICBsZXQgaXRlcmF0aW9ucyA9IDA7XG4gICAgbGV0IGV4dGVybmFsRm9ybVN1Ym1pdHRlZCA9IGZhbHNlO1xuXG4gICAgLy8gZGlzYWJsZSBmb3JtcyBvbiBzdWJtaXQgdGhhdCB0cmFjayBwaHgtY2hhbmdlIGJ1dCBwZXJmb3JtIGV4dGVybmFsIHN1Ym1pdFxuICAgIHRoaXMub24oXCJzdWJtaXRcIiwgKGUpID0+IHtcbiAgICAgIGNvbnN0IHBoeFN1Ym1pdCA9IGUudGFyZ2V0LmdldEF0dHJpYnV0ZSh0aGlzLmJpbmRpbmcoXCJzdWJtaXRcIikpO1xuICAgICAgY29uc3QgcGh4Q2hhbmdlID0gZS50YXJnZXQuZ2V0QXR0cmlidXRlKHRoaXMuYmluZGluZyhcImNoYW5nZVwiKSk7XG4gICAgICBpZiAoIWV4dGVybmFsRm9ybVN1Ym1pdHRlZCAmJiBwaHhDaGFuZ2UgJiYgIXBoeFN1Ym1pdCkge1xuICAgICAgICBleHRlcm5hbEZvcm1TdWJtaXR0ZWQgPSB0cnVlO1xuICAgICAgICBlLnByZXZlbnREZWZhdWx0KCk7XG4gICAgICAgIHRoaXMud2l0aGluT3duZXJzKGUudGFyZ2V0LCAodmlldykgPT4ge1xuICAgICAgICAgIHZpZXcuZGlzYWJsZUZvcm0oZS50YXJnZXQpO1xuICAgICAgICAgIC8vIHNhZmFyaSBuZWVkcyBuZXh0IHRpY2tcbiAgICAgICAgICB3aW5kb3cucmVxdWVzdEFuaW1hdGlvbkZyYW1lKCgpID0+IHtcbiAgICAgICAgICAgIGlmIChET00uaXNVbmxvYWRhYmxlRm9ybVN1Ym1pdChlKSkge1xuICAgICAgICAgICAgICB0aGlzLnVubG9hZCgpO1xuICAgICAgICAgICAgfVxuICAgICAgICAgICAgZS50YXJnZXQuc3VibWl0KCk7XG4gICAgICAgICAgfSk7XG4gICAgICAgIH0pO1xuICAgICAgfVxuICAgIH0pO1xuXG4gICAgdGhpcy5vbihcInN1Ym1pdFwiLCAoZSkgPT4ge1xuICAgICAgY29uc3QgcGh4RXZlbnQgPSBlLnRhcmdldC5nZXRBdHRyaWJ1dGUodGhpcy5iaW5kaW5nKFwic3VibWl0XCIpKTtcbiAgICAgIGlmICghcGh4RXZlbnQpIHtcbiAgICAgICAgaWYgKERPTS5pc1VubG9hZGFibGVGb3JtU3VibWl0KGUpKSB7XG4gICAgICAgICAgdGhpcy51bmxvYWQoKTtcbiAgICAgICAgfVxuICAgICAgICByZXR1cm47XG4gICAgICB9XG4gICAgICBlLnByZXZlbnREZWZhdWx0KCk7XG4gICAgICBlLnRhcmdldC5kaXNhYmxlZCA9IHRydWU7XG4gICAgICB0aGlzLndpdGhpbk93bmVycyhlLnRhcmdldCwgKHZpZXcpID0+IHtcbiAgICAgICAgSlMuZXhlYyhlLCBcInN1Ym1pdFwiLCBwaHhFdmVudCwgdmlldywgZS50YXJnZXQsIFtcbiAgICAgICAgICBcInB1c2hcIixcbiAgICAgICAgICB7IHN1Ym1pdHRlcjogZS5zdWJtaXR0ZXIgfSxcbiAgICAgICAgXSk7XG4gICAgICB9KTtcbiAgICB9KTtcblxuICAgIGZvciAoY29uc3QgdHlwZSBvZiBbXCJjaGFuZ2VcIiwgXCJpbnB1dFwiXSkge1xuICAgICAgdGhpcy5vbih0eXBlLCAoZSkgPT4ge1xuICAgICAgICBpZiAoXG4gICAgICAgICAgZSBpbnN0YW5jZW9mIEN1c3RvbUV2ZW50ICYmXG4gICAgICAgICAgKGUudGFyZ2V0IGluc3RhbmNlb2YgSFRNTElucHV0RWxlbWVudCB8fFxuICAgICAgICAgICAgZS50YXJnZXQgaW5zdGFuY2VvZiBIVE1MU2VsZWN0RWxlbWVudCB8fFxuICAgICAgICAgICAgZS50YXJnZXQgaW5zdGFuY2VvZiBIVE1MVGV4dEFyZWFFbGVtZW50KSAmJlxuICAgICAgICAgIGUudGFyZ2V0LmZvcm0gPT09IHVuZGVmaW5lZFxuICAgICAgICApIHtcbiAgICAgICAgICAvLyB0aHJvdyBvbiBpbnZhbGlkIEpTLmRpc3BhdGNoIHRhcmdldCBhbmQgbm9vcCBpZiBDdXN0b21FdmVudCB0cmlnZ2VyZWQgb3V0c2lkZSBKUy5kaXNwYXRjaFxuICAgICAgICAgIGlmIChlLmRldGFpbCAmJiBlLmRldGFpbC5kaXNwYXRjaGVyKSB7XG4gICAgICAgICAgICB0aHJvdyBuZXcgRXJyb3IoXG4gICAgICAgICAgICAgIGBkaXNwYXRjaGluZyBhIGN1c3RvbSAke3R5cGV9IGV2ZW50IGlzIG9ubHkgc3VwcG9ydGVkIG9uIGlucHV0IGVsZW1lbnRzIGluc2lkZSBhIGZvcm1gLFxuICAgICAgICAgICAgKTtcbiAgICAgICAgICB9XG4gICAgICAgICAgcmV0dXJuO1xuICAgICAgICB9XG4gICAgICAgIGNvbnN0IHBoeENoYW5nZSA9IHRoaXMuYmluZGluZyhcImNoYW5nZVwiKTtcbiAgICAgICAgY29uc3QgaW5wdXQgPSBlLnRhcmdldDtcbiAgICAgICAgaWYgKHRoaXMuYmxvY2tQaHhDaGFuZ2VXaGlsZUNvbXBvc2luZyAmJiBlLmlzQ29tcG9zaW5nKSB7XG4gICAgICAgICAgY29uc3Qga2V5ID0gYGNvbXBvc2l0aW9uLWxpc3RlbmVyLSR7dHlwZX1gO1xuICAgICAgICAgIGlmICghRE9NLnByaXZhdGUoaW5wdXQsIGtleSkpIHtcbiAgICAgICAgICAgIERPTS5wdXRQcml2YXRlKGlucHV0LCBrZXksIHRydWUpO1xuICAgICAgICAgICAgaW5wdXQuYWRkRXZlbnRMaXN0ZW5lcihcbiAgICAgICAgICAgICAgXCJjb21wb3NpdGlvbmVuZFwiLFxuICAgICAgICAgICAgICAoKSA9PiB7XG4gICAgICAgICAgICAgICAgLy8gdHJpZ2dlciBhIG5ldyBpbnB1dC9jaGFuZ2UgZXZlbnRcbiAgICAgICAgICAgICAgICBpbnB1dC5kaXNwYXRjaEV2ZW50KG5ldyBFdmVudCh0eXBlLCB7IGJ1YmJsZXM6IHRydWUgfSkpO1xuICAgICAgICAgICAgICAgIERPTS5kZWxldGVQcml2YXRlKGlucHV0LCBrZXkpO1xuICAgICAgICAgICAgICB9LFxuICAgICAgICAgICAgICB7IG9uY2U6IHRydWUgfSxcbiAgICAgICAgICAgICk7XG4gICAgICAgICAgfVxuICAgICAgICAgIHJldHVybjtcbiAgICAgICAgfVxuICAgICAgICBjb25zdCBpbnB1dEV2ZW50ID0gaW5wdXQuZ2V0QXR0cmlidXRlKHBoeENoYW5nZSk7XG4gICAgICAgIGNvbnN0IGZvcm1FdmVudCA9IGlucHV0LmZvcm0gJiYgaW5wdXQuZm9ybS5nZXRBdHRyaWJ1dGUocGh4Q2hhbmdlKTtcbiAgICAgICAgY29uc3QgcGh4RXZlbnQgPSBpbnB1dEV2ZW50IHx8IGZvcm1FdmVudDtcbiAgICAgICAgaWYgKCFwaHhFdmVudCkge1xuICAgICAgICAgIHJldHVybjtcbiAgICAgICAgfVxuICAgICAgICBpZiAoXG4gICAgICAgICAgaW5wdXQudHlwZSA9PT0gXCJudW1iZXJcIiAmJlxuICAgICAgICAgIGlucHV0LnZhbGlkaXR5ICYmXG4gICAgICAgICAgaW5wdXQudmFsaWRpdHkuYmFkSW5wdXRcbiAgICAgICAgKSB7XG4gICAgICAgICAgcmV0dXJuO1xuICAgICAgICB9XG5cbiAgICAgICAgY29uc3QgZGlzcGF0Y2hlciA9IGlucHV0RXZlbnQgPyBpbnB1dCA6IGlucHV0LmZvcm07XG4gICAgICAgIGNvbnN0IGN1cnJlbnRJdGVyYXRpb25zID0gaXRlcmF0aW9ucztcbiAgICAgICAgaXRlcmF0aW9ucysrO1xuICAgICAgICBjb25zdCB7IGF0OiBhdCwgdHlwZTogbGFzdFR5cGUgfSA9XG4gICAgICAgICAgRE9NLnByaXZhdGUoaW5wdXQsIFwicHJldi1pdGVyYXRpb25cIikgfHwge307XG4gICAgICAgIC8vIEJyb3dzZXJzIHNob3VsZCBhbHdheXMgZmlyZSBhdCBsZWFzdCBvbmUgXCJpbnB1dFwiIGV2ZW50IGJlZm9yZSBldmVyeSBcImNoYW5nZVwiXG4gICAgICAgIC8vIElnbm9yZSBcImNoYW5nZVwiIGV2ZW50cywgdW5sZXNzIHRoZXJlIHdhcyBubyBwcmlvciBcImlucHV0XCIgZXZlbnQuXG4gICAgICAgIC8vIFRoaXMgY291bGQgaGFwcGVuIGlmIHVzZXIgY29kZSB0cmlnZ2VycyBhIFwiY2hhbmdlXCIgZXZlbnQsIG9yIGlmIHRoZSBicm93c2VyIGlzIG5vbi1jb25mb3JtaW5nLlxuICAgICAgICBpZiAoXG4gICAgICAgICAgYXQgPT09IGN1cnJlbnRJdGVyYXRpb25zIC0gMSAmJlxuICAgICAgICAgIHR5cGUgPT09IFwiY2hhbmdlXCIgJiZcbiAgICAgICAgICBsYXN0VHlwZSA9PT0gXCJpbnB1dFwiXG4gICAgICAgICkge1xuICAgICAgICAgIHJldHVybjtcbiAgICAgICAgfVxuXG4gICAgICAgIERPTS5wdXRQcml2YXRlKGlucHV0LCBcInByZXYtaXRlcmF0aW9uXCIsIHtcbiAgICAgICAgICBhdDogY3VycmVudEl0ZXJhdGlvbnMsXG4gICAgICAgICAgdHlwZTogdHlwZSxcbiAgICAgICAgfSk7XG5cbiAgICAgICAgdGhpcy5kZWJvdW5jZShpbnB1dCwgZSwgdHlwZSwgKCkgPT4ge1xuICAgICAgICAgIHRoaXMud2l0aGluT3duZXJzKGRpc3BhdGNoZXIsICh2aWV3KSA9PiB7XG4gICAgICAgICAgICBET00ucHV0UHJpdmF0ZShpbnB1dCwgUEhYX0hBU19GT0NVU0VELCB0cnVlKTtcbiAgICAgICAgICAgIEpTLmV4ZWMoZSwgXCJjaGFuZ2VcIiwgcGh4RXZlbnQsIHZpZXcsIGlucHV0LCBbXG4gICAgICAgICAgICAgIFwicHVzaFwiLFxuICAgICAgICAgICAgICB7IF90YXJnZXQ6IGUudGFyZ2V0Lm5hbWUsIGRpc3BhdGNoZXI6IGRpc3BhdGNoZXIgfSxcbiAgICAgICAgICAgIF0pO1xuICAgICAgICAgIH0pO1xuICAgICAgICB9KTtcbiAgICAgIH0pO1xuICAgIH1cbiAgICB0aGlzLm9uKFwicmVzZXRcIiwgKGUpID0+IHtcbiAgICAgIGNvbnN0IGZvcm0gPSBlLnRhcmdldDtcbiAgICAgIERPTS5yZXNldEZvcm0oZm9ybSk7XG4gICAgICBjb25zdCBpbnB1dCA9IEFycmF5LmZyb20oZm9ybS5lbGVtZW50cykuZmluZCgoZWwpID0+IGVsLnR5cGUgPT09IFwicmVzZXRcIik7XG4gICAgICBpZiAoaW5wdXQpIHtcbiAgICAgICAgLy8gd2FpdCB1bnRpbCBuZXh0IHRpY2sgdG8gZ2V0IHVwZGF0ZWQgaW5wdXQgdmFsdWVcbiAgICAgICAgd2luZG93LnJlcXVlc3RBbmltYXRpb25GcmFtZSgoKSA9PiB7XG4gICAgICAgICAgaW5wdXQuZGlzcGF0Y2hFdmVudChcbiAgICAgICAgICAgIG5ldyBFdmVudChcImlucHV0XCIsIHsgYnViYmxlczogdHJ1ZSwgY2FuY2VsYWJsZTogZmFsc2UgfSksXG4gICAgICAgICAgKTtcbiAgICAgICAgfSk7XG4gICAgICB9XG4gICAgfSk7XG4gIH1cblxuICBkZWJvdW5jZShlbCwgZXZlbnQsIGV2ZW50VHlwZSwgY2FsbGJhY2spIHtcbiAgICBpZiAoZXZlbnRUeXBlID09PSBcImJsdXJcIiB8fCBldmVudFR5cGUgPT09IFwiZm9jdXNvdXRcIikge1xuICAgICAgcmV0dXJuIGNhbGxiYWNrKCk7XG4gICAgfVxuXG4gICAgY29uc3QgcGh4RGVib3VuY2UgPSB0aGlzLmJpbmRpbmcoUEhYX0RFQk9VTkNFKTtcbiAgICBjb25zdCBwaHhUaHJvdHRsZSA9IHRoaXMuYmluZGluZyhQSFhfVEhST1RUTEUpO1xuICAgIGNvbnN0IGRlZmF1bHREZWJvdW5jZSA9IHRoaXMuZGVmYXVsdHMuZGVib3VuY2UudG9TdHJpbmcoKTtcbiAgICBjb25zdCBkZWZhdWx0VGhyb3R0bGUgPSB0aGlzLmRlZmF1bHRzLnRocm90dGxlLnRvU3RyaW5nKCk7XG5cbiAgICB0aGlzLndpdGhpbk93bmVycyhlbCwgKHZpZXcpID0+IHtcbiAgICAgIGNvbnN0IGFzeW5jRmlsdGVyID0gKCkgPT5cbiAgICAgICAgIXZpZXcuaXNEZXN0cm95ZWQoKSAmJiBkb2N1bWVudC5ib2R5LmNvbnRhaW5zKGVsKTtcbiAgICAgIERPTS5kZWJvdW5jZShcbiAgICAgICAgZWwsXG4gICAgICAgIGV2ZW50LFxuICAgICAgICBwaHhEZWJvdW5jZSxcbiAgICAgICAgZGVmYXVsdERlYm91bmNlLFxuICAgICAgICBwaHhUaHJvdHRsZSxcbiAgICAgICAgZGVmYXVsdFRocm90dGxlLFxuICAgICAgICBhc3luY0ZpbHRlcixcbiAgICAgICAgKCkgPT4ge1xuICAgICAgICAgIGNhbGxiYWNrKCk7XG4gICAgICAgIH0sXG4gICAgICApO1xuICAgIH0pO1xuICB9XG5cbiAgc2lsZW5jZUV2ZW50cyhjYWxsYmFjaykge1xuICAgIHRoaXMuc2lsZW5jZWQgPSB0cnVlO1xuICAgIGNhbGxiYWNrKCk7XG4gICAgdGhpcy5zaWxlbmNlZCA9IGZhbHNlO1xuICB9XG5cbiAgb24oZXZlbnQsIGNhbGxiYWNrKSB7XG4gICAgdGhpcy5ib3VuZEV2ZW50TmFtZXMuYWRkKGV2ZW50KTtcbiAgICB3aW5kb3cuYWRkRXZlbnRMaXN0ZW5lcihldmVudCwgKGUpID0+IHtcbiAgICAgIGlmICghdGhpcy5zaWxlbmNlZCkge1xuICAgICAgICBjYWxsYmFjayhlKTtcbiAgICAgIH1cbiAgICB9KTtcbiAgfVxuXG4gIGpzUXVlcnlTZWxlY3RvckFsbChzb3VyY2VFbCwgcXVlcnksIGRlZmF1bHRRdWVyeSkge1xuICAgIGNvbnN0IGFsbCA9IHRoaXMuZG9tQ2FsbGJhY2tzLmpzUXVlcnlTZWxlY3RvckFsbDtcbiAgICByZXR1cm4gYWxsID8gYWxsKHNvdXJjZUVsLCBxdWVyeSwgZGVmYXVsdFF1ZXJ5KSA6IGRlZmF1bHRRdWVyeSgpO1xuICB9XG59XG5cbmNsYXNzIFRyYW5zaXRpb25TZXQge1xuICBjb25zdHJ1Y3RvcigpIHtcbiAgICB0aGlzLnRyYW5zaXRpb25zID0gbmV3IFNldCgpO1xuICAgIHRoaXMucHJvbWlzZXMgPSBuZXcgU2V0KCk7XG4gICAgdGhpcy5wZW5kaW5nT3BzID0gW107XG4gIH1cblxuICByZXNldCgpIHtcbiAgICB0aGlzLnRyYW5zaXRpb25zLmZvckVhY2goKHRpbWVyKSA9PiB7XG4gICAgICBjbGVhclRpbWVvdXQodGltZXIpO1xuICAgICAgdGhpcy50cmFuc2l0aW9ucy5kZWxldGUodGltZXIpO1xuICAgIH0pO1xuICAgIHRoaXMucHJvbWlzZXMuY2xlYXIoKTtcbiAgICB0aGlzLmZsdXNoUGVuZGluZ09wcygpO1xuICB9XG5cbiAgYWZ0ZXIoY2FsbGJhY2spIHtcbiAgICBpZiAodGhpcy5zaXplKCkgPT09IDApIHtcbiAgICAgIGNhbGxiYWNrKCk7XG4gICAgfSBlbHNlIHtcbiAgICAgIHRoaXMucHVzaFBlbmRpbmdPcChjYWxsYmFjayk7XG4gICAgfVxuICB9XG5cbiAgYWRkVHJhbnNpdGlvbih0aW1lLCBvblN0YXJ0LCBvbkRvbmUpIHtcbiAgICBvblN0YXJ0KCk7XG4gICAgY29uc3QgdGltZXIgPSBzZXRUaW1lb3V0KCgpID0+IHtcbiAgICAgIHRoaXMudHJhbnNpdGlvbnMuZGVsZXRlKHRpbWVyKTtcbiAgICAgIG9uRG9uZSgpO1xuICAgICAgdGhpcy5mbHVzaFBlbmRpbmdPcHMoKTtcbiAgICB9LCB0aW1lKTtcbiAgICB0aGlzLnRyYW5zaXRpb25zLmFkZCh0aW1lcik7XG4gIH1cblxuICBhZGRBc3luY1RyYW5zaXRpb24ocHJvbWlzZSkge1xuICAgIHRoaXMucHJvbWlzZXMuYWRkKHByb21pc2UpO1xuICAgIHByb21pc2UudGhlbigoKSA9PiB7XG4gICAgICB0aGlzLnByb21pc2VzLmRlbGV0ZShwcm9taXNlKTtcbiAgICAgIHRoaXMuZmx1c2hQZW5kaW5nT3BzKCk7XG4gICAgfSk7XG4gIH1cblxuICBwdXNoUGVuZGluZ09wKG9wKSB7XG4gICAgdGhpcy5wZW5kaW5nT3BzLnB1c2gob3ApO1xuICB9XG5cbiAgc2l6ZSgpIHtcbiAgICByZXR1cm4gdGhpcy50cmFuc2l0aW9ucy5zaXplICsgdGhpcy5wcm9taXNlcy5zaXplO1xuICB9XG5cbiAgZmx1c2hQZW5kaW5nT3BzKCkge1xuICAgIGlmICh0aGlzLnNpemUoKSA+IDApIHtcbiAgICAgIHJldHVybjtcbiAgICB9XG4gICAgY29uc3Qgb3AgPSB0aGlzLnBlbmRpbmdPcHMuc2hpZnQoKTtcbiAgICBpZiAob3ApIHtcbiAgICAgIG9wKCk7XG4gICAgICB0aGlzLmZsdXNoUGVuZGluZ09wcygpO1xuICAgIH1cbiAgfVxufVxuIiwgIi8qXG49PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PVxuUGhvZW5peCBMaXZlVmlldyBKYXZhU2NyaXB0IENsaWVudFxuPT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT09PT1cblxuU2VlIHRoZSBoZXhkb2NzIGF0IGBodHRwczovL2hleGRvY3MucG0vcGhvZW5peF9saXZlX3ZpZXdgIGZvciBkb2N1bWVudGF0aW9uLlxuKi9cblxuaW1wb3J0IE9yaWdpbmFsTGl2ZVNvY2tldCwgeyBpc1VzZWRJbnB1dCB9IGZyb20gXCIuL2xpdmVfc29ja2V0XCI7XG5pbXBvcnQgRE9NIGZyb20gXCIuL2RvbVwiO1xuaW1wb3J0IHsgVmlld0hvb2sgfSBmcm9tIFwiLi92aWV3X2hvb2tcIjtcbmltcG9ydCBWaWV3IGZyb20gXCIuL3ZpZXdcIjtcblxuaW1wb3J0IHR5cGUgeyBMaXZlU29ja2V0SlNDb21tYW5kcyB9IGZyb20gXCIuL2pzX2NvbW1hbmRzXCI7XG5pbXBvcnQgdHlwZSB7IEhvb2ssIEhvb2tzT3B0aW9ucyB9IGZyb20gXCIuL3ZpZXdfaG9va1wiO1xuaW1wb3J0IHR5cGUgeyBTb2NrZXQgYXMgUGhvZW5peFNvY2tldCB9IGZyb20gXCJwaG9lbml4XCI7XG5cbi8qKlxuICogT3B0aW9ucyBmb3IgY29uZmlndXJpbmcgdGhlIExpdmVTb2NrZXQgaW5zdGFuY2UuXG4gKi9cbmV4cG9ydCBpbnRlcmZhY2UgTGl2ZVNvY2tldE9wdGlvbnMge1xuICAvKipcbiAgICogRGVmYXVsdHMgZm9yIHBoeC1kZWJvdW5jZSBhbmQgcGh4LXRocm90dGxlLlxuICAgKi9cbiAgZGVmYXVsdHM/OiB7XG4gICAgLyoqIFRoZSBtaWxsaXNlY29uZCBwaHgtZGVib3VuY2UgdGltZS4gRGVmYXVsdHMgMzAwICovXG4gICAgZGVib3VuY2U/OiBudW1iZXI7XG4gICAgLyoqIFRoZSBtaWxsaXNlY29uZCBwaHgtdGhyb3R0bGUgdGltZS4gRGVmYXVsdHMgMzAwICovXG4gICAgdGhyb3R0bGU/OiBudW1iZXI7XG4gIH07XG4gIC8qKlxuICAgKiBBbiBvYmplY3Qgb3IgZnVuY3Rpb24gZm9yIHBhc3NpbmcgY29ubmVjdCBwYXJhbXMuXG4gICAqIFRoZSBmdW5jdGlvbiByZWNlaXZlcyB0aGUgZWxlbWVudCBhc3NvY2lhdGVkIHdpdGggYSBnaXZlbiBMaXZlVmlldy4gRm9yIGV4YW1wbGU6XG4gICAqXG4gICAqICAgICAoZWwpID0+IHt2aWV3OiBlbC5nZXRBdHRyaWJ1dGUoXCJkYXRhLW15LXZpZXctbmFtZVwiLCB0b2tlbjogd2luZG93Lm15VG9rZW59XG4gICAqXG4gICAqL1xuICBwYXJhbXM/OlxuICAgIHwgKChlbDogSFRNTEVsZW1lbnQpID0+IHsgW2tleTogc3RyaW5nXTogYW55IH0pXG4gICAgfCB7IFtrZXk6IHN0cmluZ106IGFueSB9O1xuICAvKipcbiAgICogVGhlIG9wdGlvbmFsIHByZWZpeCB0byB1c2UgZm9yIGFsbCBwaHggRE9NIGFubm90YXRpb25zLlxuICAgKlxuICAgKiBEZWZhdWx0cyB0byBcInBoeC1cIi5cbiAgICovXG4gIGJpbmRpbmdQcmVmaXg/OiBzdHJpbmc7XG4gIC8qKlxuICAgKiBDYWxsYmFja3MgZm9yIExpdmVWaWV3IGhvb2tzLlxuICAgKlxuICAgKiBTZWUgW0NsaWVudCBob29rcyB2aWEgYHBoeC1ob29rYF0oaHR0cHM6Ly9oZXhkb2NzLnBtL3Bob2VuaXhfbGl2ZV92aWV3L2pzLWludGVyb3AuaHRtbCNjbGllbnQtaG9va3MtdmlhLXBoeC1ob29rKSBmb3IgbW9yZSBpbmZvcm1hdGlvbi5cbiAgICovXG4gIGhvb2tzPzogSG9va3NPcHRpb25zO1xuICAvKiogQ2FsbGJhY2tzIGZvciBMaXZlVmlldyB1cGxvYWRlcnMuICovXG4gIHVwbG9hZGVycz86IHsgW2tleTogc3RyaW5nXTogYW55IH07IC8vIFRPRE86IGRlZmluZSBtb3JlIHNwZWNpZmljYWxseVxuICAvKiogRGVsYXkgaW4gbWlsbGlzZWNvbmRzIGJlZm9yZSBhcHBseWluZyBsb2FkaW5nIHN0YXRlcy4gKi9cbiAgbG9hZGVyVGltZW91dD86IG51bWJlcjtcbiAgLyoqIERlbGF5IGluIG1pbGxpc2Vjb25kcyBiZWZvcmUgZXhlY3V0aW5nIHBoeC1kaXNjb25uZWN0ZWQgY29tbWFuZHMuICovXG4gIGRpc2Nvbm5lY3RlZFRpbWVvdXQ/OiBudW1iZXI7XG4gIC8qKiBNYXhpbXVtIHJlbG9hZHMgYmVmb3JlIGVudGVyaW5nIGZhaWxzYWZlIG1vZGUuICovXG4gIG1heFJlbG9hZHM/OiBudW1iZXI7XG4gIC8qKiBNaW5pbXVtIHRpbWUgYmV0d2VlbiBub3JtYWwgcmVsb2FkIGF0dGVtcHRzLiAqL1xuICByZWxvYWRKaXR0ZXJNaW4/OiBudW1iZXI7XG4gIC8qKiBNYXhpbXVtIHRpbWUgYmV0d2VlbiBub3JtYWwgcmVsb2FkIGF0dGVtcHRzLiAqL1xuICByZWxvYWRKaXR0ZXJNYXg/OiBudW1iZXI7XG4gIC8qKiBUaW1lIGJldHdlZW4gcmVsb2FkIGF0dGVtcHRzIGluIGZhaWxzYWZlIG1vZGUuICovXG4gIGZhaWxzYWZlSml0dGVyPzogbnVtYmVyO1xuICAvKipcbiAgICogRnVuY3Rpb24gdG8gbG9nIGRlYnVnIGluZm9ybWF0aW9uLiBGb3IgZXhhbXBsZTpcbiAgICpcbiAgICogICAgICh2aWV3LCBraW5kLCBtc2csIG9iaikgPT4gY29uc29sZS5sb2coYCR7dmlldy5pZH0gJHtraW5kfTogJHttc2d9IC0gYCwgb2JqKVxuICAgKi9cbiAgdmlld0xvZ2dlcj86ICh2aWV3OiBWaWV3LCBraW5kOiBzdHJpbmcsIG1zZzogc3RyaW5nLCBvYmo6IGFueSkgPT4gdm9pZDtcbiAgLyoqXG4gICAqIE9iamVjdCBtYXBwaW5nIGV2ZW50IG5hbWVzIHRvIGZ1bmN0aW9ucyBmb3IgcG9wdWxhdGluZyBldmVudCBtZXRhZGF0YS5cbiAgICpcbiAgICogICAgIG1ldGFkYXRhOiB7XG4gICAqICAgICAgIGNsaWNrOiAoZSwgZWwpID0+IHtcbiAgICogICAgICAgICByZXR1cm4ge1xuICAgKiAgICAgICAgICAgY3RybEtleTogZS5jdHJsS2V5LFxuICAgKiAgICAgICAgICAgbWV0YUtleTogZS5tZXRhS2V5LFxuICAgKiAgICAgICAgICAgZGV0YWlsOiBlLmRldGFpbCB8fCAxLFxuICAgKiAgICAgICAgIH1cbiAgICogICAgICAgfSxcbiAgICogICAgICAga2V5ZG93bjogKGUsIGVsKSA9PiB7XG4gICAqICAgICAgICAgcmV0dXJuIHtcbiAgICogICAgICAgICAgIGtleTogZS5rZXksXG4gICAqICAgICAgICAgICBjdHJsS2V5OiBlLmN0cmxLZXksXG4gICAqICAgICAgICAgICBtZXRhS2V5OiBlLm1ldGFLZXksXG4gICAqICAgICAgICAgICBzaGlmdEtleTogZS5zaGlmdEtleVxuICAgKiAgICAgICAgIH1cbiAgICogICAgICAgfVxuICAgKiAgICAgfVxuICAgKlxuICAgKi9cbiAgbWV0YWRhdGE/OiB7IFtldmVudE5hbWU6IHN0cmluZ106IChlOiBFdmVudCwgZWw6IEhUTUxFbGVtZW50KSA9PiBvYmplY3QgfTtcbiAgLyoqXG4gICAqIEFuIG9wdGlvbmFsIFN0b3JhZ2UgY29tcGF0aWJsZSBvYmplY3RcbiAgICogVXNlZnVsIHdoZW4gTGl2ZVZpZXcgd29uJ3QgaGF2ZSBhY2Nlc3MgdG8gYHNlc3Npb25TdG9yYWdlYC4gRm9yIGV4YW1wbGUsIFRoaXMgY291bGRcbiAgICogaGFwcGVuIGlmIGEgc2l0ZSBsb2FkcyBhIGNyb3NzLWRvbWFpbiBMaXZlVmlldyBpbiBhbiBpZnJhbWUuXG4gICAqXG4gICAqIEV4YW1wbGUgdXNhZ2U6XG4gICAqXG4gICAqICAgICBjbGFzcyBJbk1lbW9yeVN0b3JhZ2Uge1xuICAgKiAgICAgICBjb25zdHJ1Y3RvcigpIHsgdGhpcy5zdG9yYWdlID0ge30gfVxuICAgKiAgICAgICBnZXRJdGVtKGtleU5hbWUpIHsgcmV0dXJuIHRoaXMuc3RvcmFnZVtrZXlOYW1lXSB8fCBudWxsIH1cbiAgICogICAgICAgcmVtb3ZlSXRlbShrZXlOYW1lKSB7IGRlbGV0ZSB0aGlzLnN0b3JhZ2Vba2V5TmFtZV0gfVxuICAgKiAgICAgICBzZXRJdGVtKGtleU5hbWUsIGtleVZhbHVlKSB7IHRoaXMuc3RvcmFnZVtrZXlOYW1lXSA9IGtleVZhbHVlIH1cbiAgICogICAgIH1cbiAgICovXG4gIHNlc3Npb25TdG9yYWdlPzogU3RvcmFnZTtcbiAgLyoqXG4gICAqIEFuIG9wdGlvbmFsIFN0b3JhZ2UgY29tcGF0aWJsZSBvYmplY3RcbiAgICogVXNlZnVsIHdoZW4gTGl2ZVZpZXcgd29uJ3QgaGF2ZSBhY2Nlc3MgdG8gYGxvY2FsU3RvcmFnZWAuXG4gICAqXG4gICAqIFNlZSBgc2Vzc2lvblN0b3JhZ2VgIGZvciBhbiBleGFtcGxlLlxuICAgKi9cbiAgbG9jYWxTdG9yYWdlPzogU3RvcmFnZTtcbiAgLyoqXG4gICAqIElmIHNldCB0byBgdHJ1ZWAsIGBwaHgtY2hhbmdlYCBldmVudHMgd2lsbCBiZSBibG9ja2VkICh3aWxsIG5vdCBmaXJlKVxuICAgKiB3aGlsZSB0aGUgdXNlciBpcyBjb21wb3NpbmcgaW5wdXQgdXNpbmcgYW4gSU1FIChJbnB1dCBNZXRob2QgRWRpdG9yKS5cbiAgICogVGhpcyBpcyBkZXRlcm1pbmVkIGJ5IHRoZSBgZS5pc0NvbXBvc2luZ2AgcHJvcGVydHkgb24ga2V5Ym9hcmQgZXZlbnRzLFxuICAgKiB3aGljaCBpcyBgdHJ1ZWAgd2hlbiB0aGUgdXNlciBpcyBpbiB0aGUgcHJvY2VzcyBvZiBlbnRlcmluZyBjb21wb3NlZCBjaGFyYWN0ZXJzIChmb3IgZXhhbXBsZSxcbiAgICogd2hlbiB0eXBpbmcgSmFwYW5lc2Ugb3IgQ2hpbmVzZSB1c2luZyByb21hamkgb3IgcGlueWluIGlucHV0IG1ldGhvZHMpLlxuICAgKiBCeSBkZWZhdWx0LCBgcGh4LWNoYW5nZWAgd2lsbCBub3QgYmUgYmxvY2tlZCBkdXJpbmcgYSBjb21wb3NpdGlvbiBzZXNzaW9uLFxuICAgKiBidXQgbm90ZSB0aGF0IHRoZXJlIHdlcmUgaXNzdWVzIHJlcG9ydGVkIGluIG9sZGVyIHZlcnNpb25zIG9mIFNhZmFyaSxcbiAgICogd2hlcmUgYSBMaXZlVmlldyBwYXRjaCB0byB0aGUgaW5wdXQgY2F1c2VkIHVuZXhwZWN0ZWQgYmVoYXZpb3IuXG4gICAqXG4gICAqIEZvciBtb3JlIGluZm9ybWF0aW9uLCBzZWVcbiAgICogLSBodHRwczovL2RldmVsb3Blci5tb3ppbGxhLm9yZy9lbi1VUy9kb2NzL1dlYi9BUEkvS2V5Ym9hcmRFdmVudC9pc0NvbXBvc2luZ1xuICAgKiAtIGh0dHBzOi8vZ2l0aHViLmNvbS9waG9lbml4ZnJhbWV3b3JrL3Bob2VuaXhfbGl2ZV92aWV3L2lzc3Vlcy8zMzIyXG4gICAqXG4gICAqIERlZmF1bHRzIHRvIGBmYWxzZWAuXG4gICAqL1xuICBibG9ja1BoeENoYW5nZVdoaWxlQ29tcG9zaW5nPzogYm9vbGVhbjtcbiAgLyoqIERPTSBjYWxsYmFja3MuICovXG4gIGRvbT86IHtcbiAgICAvKipcbiAgICAgKiBBbiBvcHRpb25hbCBmdW5jdGlvbiB0byBtb2RpZnkgdGhlIGJlaGF2aW9yIG9mIHF1ZXJ5aW5nIGVsZW1lbnRzIGluIEpTIGNvbW1hbmRzLlxuICAgICAqIEBwYXJhbSBzb3VyY2VFbCAtIFRoZSBzb3VyY2UgZWxlbWVudCwgZS5nLiB0aGUgYnV0dG9uIHRoYXQgd2FzIGNsaWNrZWQuXG4gICAgICogQHBhcmFtIHF1ZXJ5IC0gVGhlIHF1ZXJ5IHZhbHVlLlxuICAgICAqIEBwYXJhbSBkZWZhdWx0UXVlcnkgLSBBIGRlZmF1bHQgcXVlcnkgZnVuY3Rpb24gdGhhdCBjYW4gYmUgdXNlZCBpZiBubyBjdXN0b20gcXVlcnkgc2hvdWxkIGJlIGFwcGxpZWQuXG4gICAgICogQHJldHVybnMgQSBsaXN0IG9mIERPTSBlbGVtZW50cy5cbiAgICAgKi9cbiAgICBqc1F1ZXJ5U2VsZWN0b3JBbGw/OiAoXG4gICAgICBzb3VyY2VFbDogSFRNTEVsZW1lbnQsXG4gICAgICBxdWVyeTogc3RyaW5nLFxuICAgICAgZGVmYXVsdFF1ZXJ5OiAoKSA9PiBFbGVtZW50W10sXG4gICAgKSA9PiBFbGVtZW50W107XG4gICAgLyoqXG4gICAgICogQ2FsbGVkIGltbWVkaWF0ZWx5IGJlZm9yZSBhIERPTSBwYXRjaCBpcyBhcHBsaWVkLlxuICAgICAqL1xuICAgIG9uUGF0Y2hTdGFydD86IChjb250YWluZXI6IEhUTUxFbGVtZW50KSA9PiB2b2lkO1xuICAgIC8qKlxuICAgICAqIENhbGxlZCBpbW1lZGlhdGVseSBhZnRlciBhIERPTSBwYXRjaCBpcyBhcHBsaWVkLlxuICAgICAqL1xuICAgIG9uUGF0Y2hFbmQ/OiAoY29udGFpbmVyOiBIVE1MRWxlbWVudCkgPT4gdm9pZDtcbiAgICAvKipcbiAgICAgKiBDYWxsZWQgd2hlbiBhIG5ldyBET00gbm9kZSBpcyBhZGRlZC5cbiAgICAgKi9cbiAgICBvbk5vZGVBZGRlZD86IChub2RlOiBOb2RlKSA9PiB2b2lkO1xuICAgIC8qKlxuICAgICAqIENhbGxlZCBiZWZvcmUgYW4gZWxlbWVudCBpcyB1cGRhdGVkLlxuICAgICAqL1xuICAgIG9uQmVmb3JlRWxVcGRhdGVkPzogKGZyb21FbDogRWxlbWVudCwgdG9FbDogRWxlbWVudCkgPT4gdm9pZDtcbiAgfTtcbiAgLyoqIEFsbG93IHBhc3N0aHJvdWdoIG9mIG90aGVyIG9wdGlvbnMgdG8gdGhlIFBob2VuaXggU29ja2V0IGNvbnN0cnVjdG9yLiAqL1xuICBba2V5OiBzdHJpbmddOiBhbnk7XG59XG5cbi8qKlxuICogSW50ZXJmYWNlIGRlc2NyaWJpbmcgdGhlIHB1YmxpYyBBUEkgb2YgYSBMaXZlU29ja2V0IGluc3RhbmNlLlxuICovXG5leHBvcnQgaW50ZXJmYWNlIExpdmVTb2NrZXRJbnN0YW5jZUludGVyZmFjZSB7XG4gIC8qKlxuICAgKiBSZXR1cm5zIHRoZSB2ZXJzaW9uIG9mIHRoZSBMaXZlVmlldyBjbGllbnQuXG4gICAqL1xuICB2ZXJzaW9uKCk6IHN0cmluZztcbiAgLyoqXG4gICAqIFJldHVybnMgdHJ1ZSBpZiBwcm9maWxpbmcgaXMgZW5hYmxlZC4gU2VlIGBlbmFibGVQcm9maWxpbmdgIGFuZCBgZGlzYWJsZVByb2ZpbGluZ2AuXG4gICAqL1xuICBpc1Byb2ZpbGVFbmFibGVkKCk6IGJvb2xlYW47XG4gIC8qKlxuICAgKiBSZXR1cm5zIHRydWUgaWYgZGVidWdnaW5nIGlzIGVuYWJsZWQuIFNlZSBgZW5hYmxlRGVidWdgIGFuZCBgZGlzYWJsZURlYnVnYC5cbiAgICovXG4gIGlzRGVidWdFbmFibGVkKCk6IGJvb2xlYW47XG4gIC8qKlxuICAgKiBSZXR1cm5zIHRydWUgaWYgZGVidWdnaW5nIGlzIGRpc2FibGVkLiBTZWUgYGVuYWJsZURlYnVnYCBhbmQgYGRpc2FibGVEZWJ1Z2AuXG4gICAqL1xuICBpc0RlYnVnRGlzYWJsZWQoKTogYm9vbGVhbjtcbiAgLyoqXG4gICAqIEVuYWJsZXMgZGVidWdnaW5nLlxuICAgKlxuICAgKiBXaGVuIGRlYnVnZ2luZyBpcyBlbmFibGVkLCB0aGUgTGl2ZVZpZXcgY2xpZW50IHdpbGwgbG9nIGRlYnVnIGluZm9ybWF0aW9uIHRvIHRoZSBjb25zb2xlLlxuICAgKiBTZWUgW0RlYnVnZ2luZyBjbGllbnQgZXZlbnRzXShodHRwczovL2hleGRvY3MucG0vcGhvZW5peF9saXZlX3ZpZXcvanMtaW50ZXJvcC5odG1sI2RlYnVnZ2luZy1jbGllbnQtZXZlbnRzKSBmb3IgbW9yZSBpbmZvcm1hdGlvbi5cbiAgICovXG4gIGVuYWJsZURlYnVnKCk6IHZvaWQ7XG4gIC8qKlxuICAgKiBFbmFibGVzIHByb2ZpbGluZy5cbiAgICpcbiAgICogV2hlbiBwcm9maWxpbmcgaXMgZW5hYmxlZCwgdGhlIExpdmVWaWV3IGNsaWVudCB3aWxsIGxvZyBwcm9maWxpbmcgaW5mb3JtYXRpb24gdG8gdGhlIGNvbnNvbGUuXG4gICAqL1xuICBlbmFibGVQcm9maWxpbmcoKTogdm9pZDtcbiAgLyoqXG4gICAqIERpc2FibGVzIGRlYnVnZ2luZy5cbiAgICovXG4gIGRpc2FibGVEZWJ1ZygpOiB2b2lkO1xuICAvKipcbiAgICogRGlzYWJsZXMgcHJvZmlsaW5nLlxuICAgKi9cbiAgZGlzYWJsZVByb2ZpbGluZygpOiB2b2lkO1xuICAvKipcbiAgICogRW5hYmxlcyBsYXRlbmN5IHNpbXVsYXRpb24uXG4gICAqXG4gICAqIFdoZW4gbGF0ZW5jeSBzaW11bGF0aW9uIGlzIGVuYWJsZWQsIHRoZSBMaXZlVmlldyBjbGllbnQgd2lsbCBhZGQgYSBkZWxheSB0byByZXF1ZXN0cyBhbmQgcmVzcG9uc2VzIGZyb20gdGhlIHNlcnZlci5cbiAgICogU2VlIFtTaW11bGF0aW5nIExhdGVuY3ldKGh0dHBzOi8vaGV4ZG9jcy5wbS9waG9lbml4X2xpdmVfdmlldy9qcy1pbnRlcm9wLmh0bWwjc2ltdWxhdGluZy1sYXRlbmN5KSBmb3IgbW9yZSBpbmZvcm1hdGlvbi5cbiAgICovXG4gIGVuYWJsZUxhdGVuY3lTaW0odXBwZXJCb3VuZE1zOiBudW1iZXIpOiB2b2lkO1xuICAvKipcbiAgICogRGlzYWJsZXMgbGF0ZW5jeSBzaW11bGF0aW9uLlxuICAgKi9cbiAgZGlzYWJsZUxhdGVuY3lTaW0oKTogdm9pZDtcbiAgLyoqXG4gICAqIFJldHVybnMgdGhlIGN1cnJlbnQgbGF0ZW5jeSBzaW11bGF0aW9uIHVwcGVyIGJvdW5kLlxuICAgKi9cbiAgZ2V0TGF0ZW5jeVNpbSgpOiBudW1iZXIgfCBudWxsO1xuICAvKipcbiAgICogUmV0dXJucyB0aGUgUGhvZW5peCBTb2NrZXQgaW5zdGFuY2UuXG4gICAqL1xuICBnZXRTb2NrZXQoKTogUGhvZW5peFNvY2tldDtcbiAgLyoqXG4gICAqIENvbm5lY3RzIHRvIHRoZSBMaXZlVmlldyBzZXJ2ZXIuXG4gICAqL1xuICBjb25uZWN0KCk6IHZvaWQ7XG4gIC8qKlxuICAgKiBEaXNjb25uZWN0cyBmcm9tIHRoZSBMaXZlVmlldyBzZXJ2ZXIuXG4gICAqL1xuICBkaXNjb25uZWN0KGNhbGxiYWNrPzogKCkgPT4gdm9pZCk6IHZvaWQ7XG4gIC8qKlxuICAgKiBDYW4gYmUgdXNlZCB0byByZXBsYWNlIHRoZSB0cmFuc3BvcnQgdXNlZCBieSB0aGUgdW5kZXJseWluZyBQaG9lbml4IFNvY2tldC5cbiAgICovXG4gIHJlcGxhY2VUcmFuc3BvcnQodHJhbnNwb3J0OiBhbnkpOiB2b2lkO1xuICAvKipcbiAgICogRXhlY3V0ZXMgYW4gZW5jb2RlZCBKUyBjb21tYW5kLCB0YXJnZXRpbmcgdGhlIGdpdmVuIGVsZW1lbnQuXG4gICAqXG4gICAqIFNlZSBbYFBob2VuaXguTGl2ZVZpZXcuSlNgXShodHRwczovL2hleGRvY3MucG0vcGhvZW5peF9saXZlX3ZpZXcvUGhvZW5peC5MaXZlVmlldy5KUy5odG1sKSBmb3IgbW9yZSBpbmZvcm1hdGlvbi5cbiAgICovXG4gIGV4ZWNKUyhlbDogSFRNTEVsZW1lbnQsIGVuY29kZWRKUzogc3RyaW5nLCBldmVudFR5cGU/OiBzdHJpbmcgfCBudWxsKTogdm9pZDtcbiAgLyoqXG4gICAqIFJldHVybnMgYW4gb2JqZWN0IHdpdGggbWV0aG9kcyB0byBtYW5pcGx1YXRlIHRoZSBET00gYW5kIGV4ZWN1dGUgSmF2YVNjcmlwdC5cbiAgICogVGhlIGFwcGxpZWQgY2hhbmdlcyBpbnRlZ3JhdGUgd2l0aCBzZXJ2ZXIgRE9NIHBhdGNoaW5nLlxuICAgKlxuICAgKiBTZWUgW0phdmFTY3JpcHQgaW50ZXJvcGVyYWJpbGl0eV0oaHR0cHM6Ly9oZXhkb2NzLnBtL3Bob2VuaXhfbGl2ZV92aWV3L2pzLWludGVyb3AuaHRtbCkgZm9yIG1vcmUgaW5mb3JtYXRpb24uXG4gICAqL1xuICBqcygpOiBMaXZlU29ja2V0SlNDb21tYW5kcztcbn1cblxuLyoqXG4gKiBJbnRlcmZhY2UgZGVzY3JpYmluZyB0aGUgTGl2ZVNvY2tldCBjb25zdHJ1Y3Rvci5cbiAqL1xuZXhwb3J0IGludGVyZmFjZSBMaXZlU29ja2V0Q29uc3RydWN0b3Ige1xuICAvKipcbiAgICogQ3JlYXRlcyBhIG5ldyBMaXZlU29ja2V0IGluc3RhbmNlLlxuICAgKlxuICAgKiBAcGFyYW0gZW5kcG9pbnQgLSBUaGUgc3RyaW5nIFdlYlNvY2tldCBlbmRwb2ludCwgaWUsIGBcIndzczovL2V4YW1wbGUuY29tL2xpdmVcImAsXG4gICAqICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICBgXCIvbGl2ZVwiYCAoaW5oZXJpdGVkIGhvc3QgJiBwcm90b2NvbClcbiAgICogQHBhcmFtIHNvY2tldCAtIHRoZSByZXF1aXJlZCBQaG9lbml4IFNvY2tldCBjbGFzcyBpbXBvcnRlZCBmcm9tIFwicGhvZW5peFwiLiBGb3IgZXhhbXBsZTpcbiAgICpcbiAgICogICAgIGltcG9ydCB7U29ja2V0fSBmcm9tIFwicGhvZW5peFwiXG4gICAqICAgICBpbXBvcnQge0xpdmVTb2NrZXR9IGZyb20gXCJwaG9lbml4X2xpdmVfdmlld1wiXG4gICAqICAgICBsZXQgbGl2ZVNvY2tldCA9IG5ldyBMaXZlU29ja2V0KFwiL2xpdmVcIiwgU29ja2V0LCB7Li4ufSlcbiAgICpcbiAgICogQHBhcmFtIG9wdHMgLSBPcHRpb25hbCBjb25maWd1cmF0aW9uLlxuICAgKi9cbiAgbmV3IChcbiAgICBlbmRwb2ludDogc3RyaW5nLFxuICAgIHNvY2tldDogdHlwZW9mIFBob2VuaXhTb2NrZXQsXG4gICAgb3B0cz86IExpdmVTb2NrZXRPcHRpb25zLFxuICApOiBMaXZlU29ja2V0SW5zdGFuY2VJbnRlcmZhY2U7XG59XG5cbi8vIGJlY2F1c2UgTGl2ZVNvY2tldCBpcyBpbiBKUyAoZm9yIG5vdyksIHdlIGNhc3QgaXQgdG8gb3VyIGRlZmluZWQgVHlwZVNjcmlwdCBjb25zdHJ1Y3Rvci5cbmNvbnN0IExpdmVTb2NrZXQgPSBPcmlnaW5hbExpdmVTb2NrZXQgYXMgdW5rbm93biBhcyBMaXZlU29ja2V0Q29uc3RydWN0b3I7XG5cbi8qKiBDcmVhdGVzIGEgaG9vayBpbnN0YW5jZSBmb3IgdGhlIGdpdmVuIGVsZW1lbnQgYW5kIGNhbGxiYWNrcy5cbiAqXG4gKiBAcGFyYW0gZWwgLSBUaGUgZWxlbWVudCB0byBhc3NvY2lhdGUgd2l0aCB0aGUgaG9vay5cbiAqIEBwYXJhbSBjYWxsYmFja3MgLSBUaGUgbGlzdCBvZiBob29rIGNhbGxiYWNrcywgc3VjaCBhcyBtb3VudGVkLFxuICogICB1cGRhdGVkLCBkZXN0cm95ZWQsIGV0Yy5cbiAqXG4gKiAqTm90ZSo6IGBjcmVhdGVIb29rYCBtdXN0IGJlIGNhbGxlZCBmcm9tIHRoZSBgY29ubmVjdGVkQ2FsbGJhY2tgIGxpZmVjeWNsZVxuICogd2hpY2ggaXMgdHJpZ2dlcmVkIGFmdGVyIHRoZSBlbGVtZW50IGhhcyBiZWVuIGFkZGVkIHRvIHRoZSBET00uIElmIHlvdSB0cnlcbiAqIHRvIGNhbGwgYGNyZWF0ZUhvb2tgIGZyb20gdGhlIGNvbnN0cnVjdG9yLCBhbiBlcnJvciB3aWxsIGJlIGxvZ2dlZC5cbiAqXG4gKiBAZXhhbXBsZVxuICpcbiAqIGNsYXNzIE15Q29tcG9uZW50IGV4dGVuZHMgSFRNTEVsZW1lbnQge1xuICogICBjb25uZWN0ZWRDYWxsYmFjaygpe1xuICogICAgIGxldCBvbkxpdmVWaWV3TW91bnRlZCA9ICgpID0+IHRoaXMuaG9vay5wdXNoRXZlbnQoLi4uKSlcbiAqICAgICB0aGlzLmhvb2sgPSBjcmVhdGVIb29rKHRoaXMsIHttb3VudGVkOiBvbkxpdmVWaWV3TW91bnRlZH0pXG4gKiAgIH1cbiAqIH1cbiAqXG4gKiBAcmV0dXJucyBSZXR1cm5zIHRoZSBIb29rIGluc3RhbmNlIGZvciB0aGUgY3VzdG9tIGVsZW1lbnQuXG4gKi9cbmZ1bmN0aW9uIGNyZWF0ZUhvb2soZWw6IEhUTUxFbGVtZW50LCBjYWxsYmFja3M6IEhvb2spOiBWaWV3SG9vayB7XG4gIGxldCBleGlzdGluZ0hvb2sgPSBET00uZ2V0Q3VzdG9tRWxIb29rKGVsKTtcbiAgaWYgKGV4aXN0aW5nSG9vaykge1xuICAgIHJldHVybiBleGlzdGluZ0hvb2s7XG4gIH1cblxuICBsZXQgaG9vayA9IG5ldyBWaWV3SG9vayhWaWV3LmNsb3Nlc3RWaWV3KGVsKSwgZWwsIGNhbGxiYWNrcyk7XG4gIERPTS5wdXRDdXN0b21FbEhvb2soZWwsIGhvb2spO1xuICByZXR1cm4gaG9vaztcbn1cblxuZXhwb3J0IHsgTGl2ZVNvY2tldCwgaXNVc2VkSW5wdXQsIGNyZWF0ZUhvb2ssIFZpZXdIb29rLCBIb29rLCBIb29rc09wdGlvbnMgfTtcbiIsICIvLyBJbmNsdWRlIHBob2VuaXhfaHRtbCB0byBoYW5kbGUgbWV0aG9kPVBVVC9ERUxFVEUgaW4gZm9ybXMgYW5kIGJ1dHRvbnMuXG5pbXBvcnQgXCJwaG9lbml4X2h0bWxcIlxuLy8gRXN0YWJsaXNoIFBob2VuaXggU29ja2V0IGFuZCBMaXZlVmlldyBjb25maWd1cmF0aW9uLlxuaW1wb3J0IHtTb2NrZXR9IGZyb20gXCJwaG9lbml4XCJcbmltcG9ydCB7TGl2ZVNvY2tldH0gZnJvbSBcInBob2VuaXhfbGl2ZV92aWV3XCJcblxuLy8gVGhlbWUgdG9nZ2xlIGhvb2sgZm9yIGRhcmsgbW9kZSB3aXRoIGxvY2FsU3RvcmFnZSBwZXJzaXN0ZW5jZVxuY29uc3QgVGhlbWVUb2dnbGUgPSB7XG4gIG1vdW50ZWQoKSB7XG4gICAgLy8gSW5pdGlhbGl6ZSB0aGVtZSBvbiBtb3VudCBiYXNlZCBvbiBsb2NhbFN0b3JhZ2Ugb3Igc3lzdGVtIHByZWZlcmVuY2VcbiAgICB0aGlzLmluaXRpYWxpemVUaGVtZSgpXG4gICAgXG4gICAgdGhpcy5oYW5kbGVFdmVudChcInRvZ2dsZV90aGVtZVwiLCAoe2Rhcmt9KSA9PiB7XG4gICAgICB0aGlzLnNldFRoZW1lKGRhcmsgPyBcImRhcmtcIiA6IFwibGlnaHRcIilcbiAgICB9KVxuICB9LFxuICBcbiAgaW5pdGlhbGl6ZVRoZW1lKCkge1xuICAgIGNvbnN0IHRoZW1lID0gbG9jYWxTdG9yYWdlLnRoZW1lID09PSBcImRhcmtcIiB8fCBcbiAgICAgICghKFwidGhlbWVcIiBpbiBsb2NhbFN0b3JhZ2UpICYmIHdpbmRvdy5tYXRjaE1lZGlhKFwiKHByZWZlcnMtY29sb3Itc2NoZW1lOiBkYXJrKVwiKS5tYXRjaGVzKVxuICAgICAgPyBcImRhcmtcIiA6IFwibGlnaHRcIlxuICAgIFxuICAgIHRoaXMuYXBwbHlUaGVtZSh0aGVtZSA9PT0gXCJkYXJrXCIpXG4gIH0sXG4gIFxuICBzZXRUaGVtZSh0aGVtZSkge1xuICAgIGxvY2FsU3RvcmFnZS50aGVtZSA9IHRoZW1lXG4gICAgdGhpcy5hcHBseVRoZW1lKHRoZW1lID09PSBcImRhcmtcIilcbiAgfSxcbiAgXG4gIGFwcGx5VGhlbWUoaXNEYXJrKSB7XG4gICAgaWYgKGlzRGFyaykge1xuICAgICAgZG9jdW1lbnQuZG9jdW1lbnRFbGVtZW50LnNldEF0dHJpYnV0ZShcImRhdGEtdGhlbWVcIiwgXCJkYXJrXCIpXG4gICAgfSBlbHNlIHtcbiAgICAgIGRvY3VtZW50LmRvY3VtZW50RWxlbWVudC5yZW1vdmVBdHRyaWJ1dGUoXCJkYXRhLXRoZW1lXCIpXG4gICAgfVxuICB9XG59XG5cbi8vIEltcG9ydCBjb2xvY2F0ZWQgaG9va3MgLSB0aGlzIHdpbGwgYmUgZ2VuZXJhdGVkIGJ5IFBob2VuaXggTGl2ZVZpZXcgMS4xK1xubGV0IGhvb2tzID0ge1RoZW1lVG9nZ2xlfVxudHJ5IHtcbiAgY29uc3QgY29sb2NhdGVkSG9va3MgPSBhd2FpdCBpbXBvcnQoXCJwaG9lbml4LWNvbG9jYXRlZC9wdWxzYXJcIilcbiAgaG9va3MgPSB7Li4uaG9va3MsIC4uLmNvbG9jYXRlZEhvb2tzLmhvb2tzfVxufSBjYXRjaCAoZSkge1xuICAvLyBDb2xvY2F0ZWQgaG9va3Mgbm90IGF2YWlsYWJsZSB5ZXQsIHRoYXQncyBva1xufVxuXG5sZXQgY3NyZlRva2VuID0gZG9jdW1lbnQucXVlcnlTZWxlY3RvcihcIm1ldGFbbmFtZT0nY3NyZi10b2tlbiddXCIpLmdldEF0dHJpYnV0ZShcImNvbnRlbnRcIilcbmxldCBsaXZlU29ja2V0ID0gbmV3IExpdmVTb2NrZXQoXCIvbGl2ZVwiLCBTb2NrZXQsIHtcbiAgbG9uZ1BvbGxGYWxsYmFja01zOiAyNTAwLFxuICBwYXJhbXM6IHtfY3NyZl90b2tlbjogY3NyZlRva2VufSxcbiAgaG9va3M6IGhvb2tzXG59KVxuXG4vLyBjb25uZWN0IGlmIHRoZXJlIGFyZSBhbnkgTGl2ZVZpZXdzIG9uIHRoZSBwYWdlXG5saXZlU29ja2V0LmNvbm5lY3QoKVxuXG4vLyBleHBvc2UgbGl2ZVNvY2tldCBvbiB3aW5kb3cgZm9yIHdlYiBjb25zb2xlIGRlYnVnIGxvZ3MgYW5kIGxhdGVuY3kgc2ltdWxhdGlvbjpcbi8vID4+IGxpdmVTb2NrZXQuZW5hYmxlRGVidWcoKVxuLy8gPj4gbGl2ZVNvY2tldC5lbmFibGVMYXRlbmN5U2ltKDEwMDApICAvLyBlbmFibGVkIGZvciBkdXJhdGlvbiBvZiBicm93c2VyIHNlc3Npb25cbi8vID4+IGxpdmVTb2NrZXQuZGlzYWJsZUxhdGVuY3lTaW0oKVxud2luZG93LmxpdmVTb2NrZXQgPSBsaXZlU29ja2V0Il0sCiAgIm1hcHBpbmdzIjogIjtDQUVDLFdBQVc7QUFDVixNQUFJLGdCQUFnQixpQkFBaUI7QUFFckMsV0FBUyxtQkFBbUI7QUFDMUIsUUFBSSxPQUFPLE9BQU8sZ0JBQWdCLFdBQVks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QyxXQUFLLFNBQVMsT0FBTyxTQUFTLE9BQU87QUFBQSxJQUN2QyxDQUFDO0FBQUEsRUFDSDtBQUFBLEVBRUEsa0JBQWtCO0FBQ2hCLFVBQU0sUUFBUSxhQUFhLFVBQVUsVUFDbEMsRUFBRSxXQUFXLGlCQUFpQixPQUFPLFdBQVcsOEJBQThCLEVBQUUsVUFDL0UsU0FBUztBQUViLFNBQUssV0FBVyxVQUFVLE1BQU07QUFBQSxFQUNsQztBQUFBLEVBRUEsU0FBUyxPQUFPO0FBQ2QsaUJBQWEsUUFBUTtBQUNyQixTQUFLLFdBQVcsVUFBVSxNQUFNO0FBQUEsRUFDbEM7QUFBQSxFQUVBLFdBQVcsUUFBUTtBQUNqQixRQUFJLFFBQVE7QUFDVixlQUFTLGdCQUFnQixhQUFhLGNBQWMsTUFBTTtBQUFBLElBQzVELE9BQU87QUFDTCxlQUFTLGdCQUFnQixnQkFBZ0IsWUFBWTtBQUFBLElBQ3ZEO0FBQUEsRUFDRjtBQUNGO0FBR0EsSUFBSSxRQUFRLEVBQUMsWUFBVztBQUN4QixJQUFJO0FBQ0YsUUFBTSxpQkFBaUIsTUFBTSxPQUFPLDBCQUEwQjtBQUM5RCxVQUFRLEVBQUMsR0FBRyxPQUFPLEdBQUcsZUFBZSxNQUFLO0FBQzVDLFNBQVMsR0FBRztBQUVaO0FBRUEsSUFBSSxZQUFZLFNBQVMsY0FBYyx5QkFBeUIsRUFBRSxhQUFhLFNBQVM7QUFDeEYsSUFBSSxhQUFhLElBQUksWUFBVyxTQUFTLFFBQVE7QUFBQSxFQUMvQyxvQkFBb0I7QUFBQSxFQUNwQixRQUFRLEVBQUMsYUFBYSxVQUFTO0FBQUEsRUFDL0I7QUFDRixDQUFDO0FBR0QsV0FBVyxRQUFRO0FBTW5CLE9BQU8sYUFBYTsiLAogICJuYW1lcyI6IFsiQ3VzdG9tRXZlbnQiLCAiY2xvc3VyZSIsICJsaXZlU29ja2V0IiwgImNsb3N1cmUiLCAibG9jYWxTdG9yYWdlIiwgImRvYyIsICJpc0VtcHR5IiwgImZpbGUiLCAibW9ycGhBdHRycyIsICJtb3JwaGRvbSIsICJjaGlsZHJlbk9ubHkiLCAidGFyZ2V0Q29udGFpbmVyIiwgImNsb25lIiwgImVsIiwgImlucHV0c1VudXNlZCIsICJvbmx5SGlkZGVuSW5wdXRzIiwgImhvb2tzIiwgImxvY2siLCAibG9hZGluZyIsICJlbnRyeSIsICJpbnB1dCIsICJjbG9zdXJlIiwgIkxpdmVTb2NrZXQiXQp9Cg==

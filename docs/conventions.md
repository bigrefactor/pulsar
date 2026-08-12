# Conventions

Cross-cutting patterns every Pulsar component follows. This document covers
**outgoing event callbacks** — how a component lets the host application react
when something happens inside it (a flash is dismissed, a sidebar opens, a badge
is removed).

## Outgoing callbacks resolve to `%JS{}`

A leaf component's callback attr is usually a `Phoenix.LiveView.JS` command,
never a string event name:

```elixir
attr :on_dismiss, JS, default: %JS{}
```

This matches Phoenix's own generated code, where interaction behavior is always
expressed as `%JS{}` and the server-push case is written as `JS.push(...)`. A
`%JS{}` attr is strictly more flexible than a string: the host can push a server
event, run pure client-side JS, or compose both in one pipeline.

```elixir
# server event
<.flash id="banner" on_dismiss={JS.push("lv:clear-flash", value: %{key: "info"})}>…</.flash>

# client-side only
<.flash id="banner" on_dismiss={JS.hide(to: "#banner")}>…</.flash>

# composed
<.flash id="banner" on_dismiss={JS.push("noted") |> JS.hide(to: "#banner")}>…</.flash>
```

There is no string form. "Send an event to the server" is `JS.push("event")`.
When one component renders several item-specific triggers, the callback can be
a 1-arity function that receives the item value and returns `%JS{}`.

## Three mechanisms, one callback contract

How the `%JS{}` runs depends on what triggers the callback.

| Trigger | Mechanism | Example |
|---|---|---|
| Real DOM event (click, change) | Compose the resolved callback straight into a `phx-*` binding — `phx-click` already runs `%JS{}` | `select` badge-remove button |
| Programmatic (timer, hook logic) | Store the attr in a `data-on-*` attribute; run it from the hook with `liveSocket.execJS` | `flash` auto/close dismiss, `sidebar` open/close |
| Fan-out over N items needing per-item data | Attr is a 1-arity function `(item) -> %JS{}`; the wrapper calls it per item and passes the result to the leaf | `flash_group` over Phoenix.Flash keys |

### Real DOM event

When every trigger shares one callback value, compose it directly into the
binding. When the trigger needs item-specific data, resolve a 1-arity callback
first, then compose the returned `%JS{}`:

```elixir
on_remove_badge={fn option -> JS.push("remove_tag", value: %{option: option}) end}

phx-click={remove_badge_js(@on_remove_badge, option.value)}
```

The component's own commands run whether the callback is present or not.
Internal controls nested below a component hook root use an untargeted dispatch
so the event bubbles to that hook. The nearest matching hook consumes the event
before acting so nested same-type components cannot both respond. Reserve `to:`
for triggers outside the hook subtree, such as public helpers that target a
component by ID.

### Programmatic trigger

When the callback fires from JS (a dismiss timer, a keyboard handler), render the
encoded struct into a data attribute and run it from the colocated hook:

```elixir
<div data-on-dismiss={@on_dismiss} phx-hook=".PulsarFlash">
```

```js
const encoded = this.el.dataset.onDismiss
if (encoded && encoded !== "[]" && this.liveSocket) {
  this.liveSocket.execJS(this.el, encoded)
}
```

Guard against the empty `"[]"` encoding (the serialized empty `%JS{}`) so a
component with no callback does nothing — or falls back to a sensible default,
the way `flash` removes itself from the DOM when no `on_dismiss` is supplied.
The sidebar's `runCallback/1` is the reference implementation.

### Fan-out wrapper

When one component renders many children that each need their own payload, a
single `%JS{}` can't carry per-child data. Take a function as well — the same
shape as Phoenix core_components' `row_click` — and call it per child. A plain
`%JS{}` is still accepted (applied to every child) for callers that don't need
per-child data:

```elixir
attr :on_dismiss, :any,
  default: nil,
  doc: "%JS{} for every child, or a 1-arity function (flash_key) -> %JS{}"

# per child:
on_dismiss={dismiss_callback(@on_dismiss, type)}

defp dismiss_callback(nil, key), do: JS.push("lv:clear-flash", value: %{key: key})
defp dismiss_callback(%JS{} = js, _key), do: js
defp dismiss_callback(fun, key) when is_function(fun, 1), do: fun.(key)
```

The leaf always receives a plain `%JS{}`; only the wrapper deals in functions.

## Rules

- **Callback attrs are typed `JS` with `default: %JS{}`** (or `:any` + a
  1-arity function for fan-out wrappers). Never `:string`.
- **Server-push is `JS.push(...)`**, written by the caller — components don't
  accept event names.
- **`execJS` paths guard the empty encoding** (`"[]"`) and pick a default
  behavior when there's no callback.

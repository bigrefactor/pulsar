# Conventions

Cross-cutting patterns every Pulsar component follows. This document covers
**outgoing event callbacks** — how a component lets the host application react
when something happens inside it (a flash is dismissed, a sidebar opens, a badge
is removed).

## Outgoing callbacks are `%JS{}`

A component's callback attr is a `Phoenix.LiveView.JS` command, never a string
event name:

```elixir
attr :on_dismiss, JS, default: %JS{}
```

This matches Phoenix's own generated code, where interaction behavior is always
expressed as `%JS{}` and the server-push case is written as `JS.push(...)`. A
`%JS{}` attr is strictly more flexible than a string: the host can push a server
event, run pure client-side JS, or compose both in one pipeline.

```elixir
# server event
<.flash on_dismiss={JS.push("clear_flash", value: %{key: "info"})}>…</.flash>

# client-side only
<.flash on_dismiss={JS.hide(to: "#banner")}>…</.flash>

# composed
<.flash on_dismiss={JS.push("noted") |> JS.hide(to: "#banner")}>…</.flash>
```

There is no string form. "Send an event to the server" is `JS.push("event")`.

## Three mechanisms, one attr type

How the `%JS{}` runs depends on what triggers the callback.

| Trigger | Mechanism | Example |
|---|---|---|
| Real DOM event (click, change) | Compose the attr straight into a `phx-*` binding — `phx-click` already runs `%JS{}` | `select` badge-remove button |
| Programmatic (timer, hook logic) | Store the attr in a `data-on-*` attribute; run it from the hook with `liveSocket.execJS` | `flash` auto/close dismiss, `sidebar` open/close |
| Fan-out over N items needing per-item data | Attr is a 1-arity function `(item) -> %JS{}`; the wrapper calls it per item and passes the result to the leaf | `flash_group` over Phoenix.Flash keys |

### Real DOM event

The simplest case — there is no hook. Compose the callback into the binding:

```elixir
phx-click={JS.dispatch(@on_remove_badge, "pulsar:remove-selection", to: ..., detail: ...)}
```

The empty `%JS{}` default contributes nothing, so the component's own commands
run either way.

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
on_dismiss={dismiss_callback(@on_dismiss, normalize_flash_key(type))}

defp dismiss_callback(nil, key), do: JS.push("clear_flash", value: %{key: key})
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

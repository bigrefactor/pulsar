# Localizing Pulsar components

Pulsar components render English text by default, but every user-facing and
screen-reader-facing string is translatable, and numeric output is
locale-formattable. This guide shows how to wire components up to
[Gettext](https://hexdocs.pm/gettext) and, optionally,
[ex_cldr](https://hexdocs.pm/ex_cldr).

## Translatable strings

Components expose their default labels as attributes. Pass `gettext/1` (or
`dgettext/2`) to translate them:

```heex
<.flash dismiss_label={gettext("Dismiss")}>{@message}</.flash>

<.select
  field={@form[:skills]}
  options={@skills}
  multiple
  remove_label={gettext("Remove")}
/>

<.label for="email" required sr_required_text={gettext("(required)")}>
  {gettext("Email")}
</.label>

<.textarea
  field={@form[:bio]}
  show_character_count
  max_length={500}
  remaining_label={gettext("remaining")}
  over_label={gettext("over")}
/>
```

| Component  | Attribute                          | Default        |
| ---------- | ---------------------------------- | -------------- |
| `flash`    | `dismiss_label`                    | `"Dismiss"`    |
| `select`   | `remove_label`                     | `"Remove"`     |
| `label`    | `sr_required_text`                 | `"(required)"` |
| `textarea` | `remaining_label`, `over_label`    | `"remaining"`, `"over"` |

## Form error messages

The `field` component (and the `input` that wraps it) translates changeset
errors through your application's Gettext backend using the `errors` domain,
including count-aware plural forms:

```heex
<.input field={@form[:email]} label={gettext("Email")} />
```

A changeset error such as `{"should be at least %{count} character(s)", count: 8}`
is translated with `Gettext.dngettext(MyAppWeb.Gettext, "errors", …)`. Add the
message to your `errors` domain (`priv/gettext/<locale>/LC_MESSAGES/errors.po`)
to localize it, exactly as you would for Phoenix's default form errors.

`core_components` also exposes `translate_error/1` and `translate_errors/2` for
parity with Phoenix's generated helpers.

## Number formatting (CLDR-compatible)

The `textarea` character counter renders its integers through a `format_count`
function, which defaults to `Integer.to_string/1`. To format counts for the
current locale, pass a CLDR formatter:

```heex
<.textarea
  field={@form[:bio]}
  show_character_count
  max_length={5000}
  format_count={&MyAppWeb.Cldr.Number.to_string!/1}
/>
```

Any single-argument `integer -> String.t()` function works, so CLDR is
optional — supply your own formatter, or leave the default in place.

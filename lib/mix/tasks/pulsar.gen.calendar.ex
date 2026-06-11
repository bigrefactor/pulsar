defmodule Mix.Tasks.Pulsar.Gen.Calendar do
  use Pulsar.Generator,
    component: :calendar,
    example: "mix pulsar.gen.calendar",
    long_doc: """
    Generates a locale-aware calendar grid for selecting a single date or a date range.

    Month/weekday names, the first day of the week, and display formatting come
    from the visitor's browser locale; the value the server receives is always
    ISO 8601. Use it inline or inside `date_picker`.

    ## Example

    ```sh
    mix pulsar.gen.calendar

    # With custom module namespace
    mix pulsar.gen.calendar --components-module=MyAppWeb.UI
    ```

    ## Features

    - Single and range selection (range across configurable month count)
    - Locale-aware via the browser Intl API — no server locale dependency
    - min/max, disabled_dates, and disable_weekends constraints
    - Full WAI-ARIA APG grid keyboard navigation

    ## Options

    * `--components-module=MODULE` or `-M` - Target module namespace (default: YourAppWeb.Components)
    """
end

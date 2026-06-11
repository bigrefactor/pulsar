defmodule Mix.Tasks.Pulsar.Gen.DatePicker do
  use Pulsar.Generator,
    component: :date_picker,
    example: "mix pulsar.gen.date_picker",
    long_doc: """
    Generates a date input with a locale-aware calendar popover (single date or range).

    The visible inputs accept typed dates in the visitor's locale; the value the
    server receives is ISO 8601 in hidden inputs. Composes `calendar` and
    `popover`, and plugs into `field` as `type="date"` / `type="daterange"`.

    ## Example

    ```sh
    mix pulsar.gen.date_picker
    ```

    ## Options

    * `--components-module=MODULE` or `-M` - Target module namespace (default: YourAppWeb.Components)
    """
end

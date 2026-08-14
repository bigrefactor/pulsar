defmodule Pulsar.Components.Command do
  @moduledoc """
  A searchable, keyboard-navigable list of options.

  Renders a query field over a filtered list and reports the chosen option to
  the caller. It holds no value of its own: pick an option, the caller acts on
  it, and the query resets.

  Use it inline, or inside a popover or modal that provides the surface.

  ## Examples

      <.command id="fields" options={@fields} on_select={JS.push("field_chosen")} />
  """

  use Phoenix.LiveComponent

  import Twm, only: [merge: 1]

  defmodule Option do
    @moduledoc """
    One row in a `command` list.

    `label` is the text shown and matched against; `value` is what the caller
    receives on select. `group` places the row under a heading.
    """

    @enforce_keys [:label, :value]
    defstruct [:description, :group, :icon, :label, :shortcut, :value, disabled: false]

    @type t :: %__MODULE__{
            label: String.t(),
            value: term(),
            group: String.t() | nil,
            icon: String.t() | nil,
            shortcut: String.t() | nil,
            description: String.t() | nil,
            disabled: boolean()
          }
  end

  @doc """
  Normalizes any accepted option shape into a flat list of `Option` structs.

  Accepts scalars, `{label, value}` tuples, keyword options with `:key` and
  `:value`, and `{group_label, options}` pairs whose second element is a list or
  map. Grouped input flattens, with each row carrying its group label.

  ## Examples

      options(["Admin", {"User", "user"}])
      options([{"Europe", ["UK", "Sweden"]}])
      options([[key: "Admin", value: "admin", icon: "hero-user"]])
  """
  @spec options(term()) :: [Option.t()]
  def options(input) when is_list(input) or is_map(input) do
    Enum.flat_map(input, &normalize_entry(&1, nil))
  end

  defp normalize_entry(%Option{} = option, group) do
    [%{option | label: to_string(option.label), group: option.group || group}]
  end

  defp normalize_entry({key, members}, nil) when is_list(members) or is_map(members) do
    if keyword_option?(members) do
      [build_option(members, nil)]
    else
      Enum.flat_map(members, &normalize_entry(&1, to_string(key)))
    end
  end

  defp normalize_entry({_key, members}, group) when (is_list(members) or is_map(members)) and is_binary(group) do
    raise ArgumentError,
          "nested groups are not supported; flatten the options under #{inspect(group)}"
  end

  defp normalize_entry(entry, group) when is_list(entry) or is_map(entry) do
    if keyword_option?(entry) do
      [build_option(entry, group)]
    else
      raise ArgumentError,
            "unsupported option: #{inspect(entry)} (expected a scalar, a {label, value} tuple, " <>
              "or a keyword list with :key and :value)"
    end
  end

  defp normalize_entry({label, value}, group) do
    [%Option{label: to_string(label), value: value, group: group}]
  end

  defp normalize_entry(scalar, group) when is_binary(scalar) or is_atom(scalar) or is_integer(scalar) do
    [%Option{label: to_string(scalar), value: scalar, group: group}]
  end

  defp normalize_entry(entry, _group) do
    raise ArgumentError,
          "unsupported option: #{inspect(entry)} (expected a scalar, a {label, value} tuple, " <>
            "or a keyword list with :key and :value)"
  end

  defp keyword_option?(entry) when is_list(entry), do: Keyword.keyword?(entry) and Keyword.has_key?(entry, :key)
  defp keyword_option?(_entry), do: false

  defp build_option(kw, group) do
    %Option{
      label: kw |> Keyword.fetch!(:key) |> to_string(),
      value: fetch_option_value!(kw),
      group: Keyword.get(kw, :group, group),
      icon: Keyword.get(kw, :icon),
      shortcut: Keyword.get(kw, :shortcut),
      description: Keyword.get(kw, :description),
      disabled: Keyword.get(kw, :disabled, false)
    }
  end

  defp fetch_option_value!(kw) do
    case Keyword.fetch(kw, :value) do
      {:ok, value} ->
        value

      :error ->
        raise ArgumentError,
              "keyword option #{inspect(kw)} is missing :value; keyword options require both :key and :value"
    end
  end

  @doc """
  The built-in matcher: a case-insensitive subsequence match on each label.

  Options whose label contains the query's characters in order are kept, ranked
  by how tightly the match is packed and then by how early it starts. An empty
  query keeps everything.
  """
  @spec default_filter(String.t(), [Option.t()]) :: [Option.t()]
  def default_filter(query, options) do
    query
    |> to_string()
    |> String.trim()
    |> String.downcase()
    |> case do
      "" ->
        options

      trimmed ->
        needle = String.graphemes(trimmed)

        options
        |> Enum.map(fn option -> {rank(option.label, needle), option} end)
        |> Enum.reject(fn {rank, _option} -> rank == nil end)
        |> Enum.sort_by(fn {rank, option} -> {rank, option.label} end)
        |> Enum.map(fn {_rank, option} -> option end)
    end
  end

  # {span beyond the needle, index of the first match}. Lower sorts first, so a
  # contiguous match beats a scattered one and an early match beats a late one.
  defp rank(label, needle) do
    label
    |> String.downcase()
    |> String.graphemes()
    |> match_positions(needle, 0, [])
    |> case do
      nil -> nil
      positions -> {List.last(positions) - hd(positions) - length(positions) + 1, hd(positions)}
    end
  end

  defp match_positions(_haystack, [], _index, acc), do: Enum.reverse(acc)
  defp match_positions([], _needle, _index, _acc), do: nil

  defp match_positions([char | rest], [char | needle_rest], index, acc) do
    match_positions(rest, needle_rest, index + 1, [index | acc])
  end

  defp match_positions([_char | rest], needle, index, acc) do
    match_positions(rest, needle, index + 1, acc)
  end

  attr(:id, :string, required: true, doc: "Root ID. Wires the query field to the list and its options.")
  attr(:options, :any, default: [], doc: "Options in Phoenix format. See `options/1` for accepted shapes.")

  attr(:filter, :any,
    default: nil,
    doc: "2-arity fun `(query, options)` returning options. Defaults to the built-in matcher."
  )

  attr(:label, :string, default: nil, doc: ~s{Accessible name for the query field. Defaults to a translated "Search".})
  attr(:placeholder, :string, default: nil, doc: "Placeholder for the query field.")
  attr(:class, :string, default: "", doc: "Additional CSS classes")
  attr(:rest, :global, doc: "Additional HTML attributes")

  @doc """
  Renders a searchable, keyboard-navigable option list.
  """
  def command(assigns) do
    ~H"""
    <.live_component
      module={__MODULE__}
      id={@id}
      options={@options}
      filter={@filter}
      label={@label}
      placeholder={@placeholder}
      class={@class}
      {@rest}
    />
    """
  end

  @impl Phoenix.LiveComponent
  def mount(socket) do
    {:ok, assign(socket, query: "", loading: false)}
  end

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:class, fn -> "" end)
      |> assign_new(:rest, fn -> %{} end)
      |> assign_new(:options, fn -> [] end)
      |> assign_new(:filter, fn -> nil end)
      |> assign_new(:label, fn -> nil end)
      |> assign_new(:placeholder, fn -> nil end)

    normalized = options(socket.assigns.options)

    {:ok,
     socket
     |> assign(:normalized, normalized)
     |> assign_results(run_filter(socket.assigns.filter, socket.assigns.query, normalized))}
  end

  defp run_filter(nil, query, options), do: default_filter(query, options)
  defp run_filter(filter, query, options) when is_function(filter, 2), do: options(filter.(query, options))

  defp assign_results(socket, results) do
    indexed = Enum.with_index(results)

    socket
    |> assign(:results, indexed)
    |> assign(:groups, group_results(indexed))
    |> assign(:active, first_enabled_index(indexed))
  end

  defp group_results(indexed) do
    indexed
    |> Enum.chunk_by(fn {option, _index} -> option.group end)
    |> Enum.with_index()
  end

  defp first_enabled_index(indexed) do
    Enum.find_value(indexed, fn {option, index} -> if !option.disabled, do: index end)
  end

  defp default_label, do: "Search"
  defp default_placeholder, do: "Search..."

  defp result_announcement(results), do: "#{length(results)} results"

  defp group_label([{option, _index} | _rest]), do: option.group
  defp group_label([]), do: nil

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div id={@id} phx-hook=".PulsarCommand" class={merge("flex flex-col " <> @class)} {@rest}>
      <label for={"#{@id}-input"} class="sr-only">{@label || default_label()}</label>
      <input
        type="text"
        id={"#{@id}-input"}
        role="combobox"
        aria-expanded="true"
        aria-controls={"#{@id}-listbox"}
        aria-activedescendant={@active && "#{@id}-option-#{@active}"}
        aria-autocomplete="list"
        autocomplete="off"
        placeholder={@placeholder || default_placeholder()}
        class="w-full bg-transparent text-foreground placeholder:text-muted-foreground focus-visible:outline-none"
      />
      <div id={"#{@id}-listbox"} role="listbox" aria-busy={@loading} class="overflow-y-auto">
        <div
          :for={{chunk, group_index} <- @groups}
          role="group"
          aria-labelledby={group_label(chunk) && "#{@id}-group-#{group_index}"}
        >
          <div
            :if={group_label(chunk)}
            id={"#{@id}-group-#{group_index}"}
            class="px-2 py-1.5 text-xs font-medium text-muted-foreground"
          >
            {group_label(chunk)}
          </div>
          <div
            :for={{option, index} <- chunk}
            id={"#{@id}-option-#{index}"}
            role="option"
            data-command-option
            data-active={to_string(index == @active)}
            aria-selected={to_string(index == @active)}
            aria-disabled={option.disabled && "true"}
            class="flex cursor-default items-center gap-2 px-2 py-1.5 text-sm text-foreground"
          >
            {option.label}
          </div>
        </div>
      </div>
      <div role="status" aria-live="polite" class="sr-only">{result_announcement(@results)}</div>
      <script :type={Phoenix.LiveView.ColocatedHook} name=".PulsarCommand">
        export default {
          mounted() {}
        }
      </script>
    </div>
    """
  end
end

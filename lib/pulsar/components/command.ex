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
  attr(:class, :string, default: "", doc: "Additional CSS classes")
  attr(:rest, :global, doc: "Additional HTML attributes")

  @doc """
  Renders a searchable, keyboard-navigable option list.
  """
  def command(assigns) do
    ~H"""
    <.live_component module={__MODULE__} id={@id} class={@class} {@rest} />
    """
  end

  @impl Phoenix.LiveComponent
  def update(assigns, socket) do
    socket =
      socket
      |> assign(assigns)
      |> assign_new(:class, fn -> "" end)
      |> assign_new(:rest, fn -> %{} end)

    {:ok, socket}
  end

  @impl Phoenix.LiveComponent
  def render(assigns) do
    ~H"""
    <div id={@id} class={merge("flex flex-col " <> @class)} {@rest}></div>
    """
  end
end

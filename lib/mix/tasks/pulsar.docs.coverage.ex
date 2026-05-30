defmodule Mix.Tasks.Pulsar.Docs.Coverage do
  @moduledoc """
  Fails when any public function in the `:pulsar` app lacks documentation intent.

  Replaces the brittle `grep`-ratio heuristic that conflated internal helpers
  with public API. This task introspects the *compiled* modules with
  `Code.fetch_docs/1` and requires every public function/macro to be either
  documented (`@doc "..."`) or explicitly hidden (`@doc false`). A bare public
  function with no `@doc` at all is the only failure mode — there is no
  arbitrary percentage threshold.

      mix pulsar.docs.coverage   # exit non-zero, listing any undocumented function

  This is a maintainer task for the Pulsar repository itself; it is not meant to
  be run inside an application that has installed Pulsar.
  """

  # No @shortdoc on purpose — keeps `mix help` limited to `pulsar.install` as the
  # public entry point, consistent with the `pulsar.gen.*` and `pulsar.sync` tasks.

  use Mix.Task

  @impl Mix.Task
  def run(_argv) do
    ensure_pulsar_repo!()
    Mix.Task.run("compile")

    case audit() do
      {total, []} ->
        Mix.shell().info("pulsar.docs.coverage: 100% — #{total} public function(s), 0 undocumented.")

      {total, missing} ->
        listing = Enum.map_join(missing, "\n", fn {m, f, a} -> "  * #{inspect(m)}.#{f}/#{a}" end)

        Mix.raise("""
        #{length(missing)} of #{total} public function(s) have no documentation intent:

        #{listing}

        Add `@doc "..."` to document each one, or `@doc false` to mark it internal.
        For generated components, edit priv/templates/<name>.ex.eex then run mix pulsar.sync.
        """)
    end
  end

  @doc false
  # Returns `{total_public_functions, undocumented}` where `undocumented` is a list
  # of `{module, name, arity}` tuples for public functions/macros whose `@doc` is
  # `:none` (neither documented nor `@doc false`). Behaviour callback
  # implementations are exempt: they are documented by the behaviour that declares
  # them, not the module that implements them (the same reason ExDoc hides
  # `@impl` callbacks).
  @spec audit() :: {non_neg_integer(), [{module(), atom(), arity()}]}
  def audit, do: audit(pulsar_modules())

  @doc false
  @spec audit([module()]) :: {non_neg_integer(), [{module(), atom(), arity()}]}
  def audit(modules) do
    for(
      mod <- modules,
      Code.ensure_loaded?(mod),
      callbacks = callback_set(mod),
      {{kind, name, arity}, _anno, _sig, doc, _meta} <- function_docs(mod),
      kind in [:function, :macro],
      reduce: {0, []}
    ) do
      {total, missing} ->
        if doc == :none and {name, arity} not in callbacks do
          {total + 1, [{mod, name, arity} | missing]}
        else
          {total + 1, missing}
        end
    end
    |> then(fn {total, missing} -> {total, Enum.sort(missing)} end)
  end

  defp function_docs(mod) do
    case Code.fetch_docs(mod) do
      {:docs_v1, _anno, _lang, _format, _moduledoc, _meta, docs} -> docs
      _ -> []
    end
  end

  # `{name, arity}` of every callback declared by a behaviour `mod` implements, so
  # callback implementations are not flagged as undocumented. Returned as a plain
  # list (membership is checked against a handful of entries) — a MapSet here trips
  # Dialyzer's opaque-type checking at the call site.
  @spec callback_set(module()) :: [{atom(), arity()}]
  defp callback_set(mod) do
    mod.module_info(:attributes)
    |> Keyword.get_values(:behaviour)
    |> List.flatten()
    |> Enum.filter(&Code.ensure_loaded?/1)
    |> Enum.flat_map(& &1.behaviour_info(:callbacks))
  rescue
    _ -> []
  end

  # Modules whose source lives under `lib/`. Excludes `test/support` fixtures
  # (e.g. the dev app / storybook stories) that belong to the `:pulsar`
  # application under MIX_ENV=test, so the gate measures the shipped library
  # surface identically in every environment.
  defp pulsar_modules do
    Application.load(:pulsar)
    lib_dir = Path.join(File.cwd!(), "lib")

    case :application.get_key(:pulsar, :modules) do
      {:ok, modules} -> Enum.filter(modules, &under?(&1, lib_dir))
      :undefined -> []
    end
  end

  defp under?(mod, lib_dir) do
    case Code.ensure_loaded(mod) do
      {:module, _} ->
        source = mod.module_info(:compile)[:source]
        is_list(source) and String.starts_with?(to_string(source), lib_dir)

      _ ->
        false
    end
  end

  defp ensure_pulsar_repo! do
    if Mix.Project.config()[:app] != :pulsar do
      Mix.raise(
        "mix pulsar.docs.coverage is a maintainer task for the Pulsar repository only. " <>
          "It is not meant to run inside an application that has installed Pulsar."
      )
    end
  end
end

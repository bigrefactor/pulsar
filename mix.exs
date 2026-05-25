defmodule Pulsar.MixProject do
  use Mix.Project

  alias Pulsar.Components.Badge
  alias Pulsar.Components.Button
  alias Pulsar.Components.Checkbox
  alias Pulsar.Components.Icon
  alias Pulsar.Components.Input
  alias Pulsar.Components.Label
  alias Pulsar.Components.Link
  alias Pulsar.Components.RadioGroup
  alias Pulsar.Components.Select
  alias Pulsar.Components.Switch
  alias Pulsar.Components.Textarea

  @version "0.1.0"
  @source_url "https://github.com/bigrefactor/pulsar"

  def project do
    [
      app: :pulsar,
      version: @version,
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix_live_view] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),

      # Hex.pm package configuration
      description: description(),
      package: package(),

      # Documentation configuration
      docs: docs(),

      # Test configuration
      test_coverage: [tool: ExCoveralls],

      # Dialyzer configuration
      dialyzer: [
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
        plt_add_apps: [:ex_unit, :mix, :igniter, :phoenix, :phoenix_live_view, :phoenix_html, :eex, :rewrite],
        # `list_unused_filters: true` is incompatible with the multi-version
        # CI matrix here: dialyzer in different Elixir/OTP versions categorizes
        # the same warning differently (e.g. invalid_contract on 1.19 shows
        # as an unparsed "Legacy warning" on 1.15), so filter entries that are
        # used on one version look "unused" on another and fail the build.
        ignore_warnings: ".dialyzer_ignore.exs"
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  def cli do
    [
      preferred_envs: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.cobertura": :test,
        test: :test,
        check: :test,
        "check.ci": :test,
        "test_app.server": :test,
        "assets.build": :test,
        "pulsar.test_app.theme": :test
      ]
    ]
  end

  defp deps do
    [
      {:igniter, "~> 0.6", optional: true},
      {:phoenix, "~> 1.8", optional: true},
      {:phoenix_live_view, "~> 1.1", optional: true},
      {:phoenix_html, "~> 4.0", optional: true},
      {:phoenix_html_helpers, "~> 1.0", optional: true},
      {:twm, "~> 0.1"},

      # Quality tools
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:quokka, "~> 2.11", only: [:dev, :test], runtime: false},
      {:mix_audit, "~> 2.1", only: [:dev, :test], runtime: false},

      # Documentation and testing
      {:ex_doc, "~> 0.36", only: :dev, runtime: false},
      {:excoveralls, "~> 0.18", only: :test},
      {:ecto, "~> 3.12", only: :test},
      {:phoenix_ecto, "~> 4.6", only: :test},
      {:phx_new, "~> 1.7", only: :test, runtime: false},
      {:lazy_html, ">= 0.1.0", only: :test},

      # Test app build pipeline (test/support/test_app) — never ships to consumers.
      # jason is pulled in transitively (ex_ast) so it's available in every env.
      {:bandit, "~> 1.5", only: [:dev, :test]},
      {:tailwind, "~> 0.3", only: [:dev, :test], runtime: false},
      {:esbuild, "~> 0.10", only: [:dev, :test], runtime: false},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.1.1",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1,
       only: [:dev, :test]}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp aliases do
    [
      setup: [
        "deps.get",
        "compile",
        "tailwind.install --if-missing",
        "esbuild.install --if-missing"
      ],
      "assets.build": [
        "pulsar.test_app.theme",
        "tailwind test_app",
        "esbuild test_app"
      ],
      "test_app.server": [
        "assets.build",
        "run --no-halt -e '{:ok, sup} = Pulsar.TestApp.Application.start(:normal, []); Process.unlink(sup)'"
      ],
      check: [
        "compile --warnings-as-errors",
        "format --check-formatted",
        "credo --strict",
        "dialyzer",
        "deps.audit",
        "test"
      ],
      "check.ci": [
        "format --check-formatted",
        "deps.unlock --check-unused",
        "compile --warnings-as-errors",
        "credo --strict",
        "dialyzer",
        "test --cover",
        "deps.audit"
      ]
    ]
  end

  defp description do
    """
    Beautiful, accessible Phoenix LiveView components.
    Single-dependency component library with production-ready, styled components
    providing full accessibility, security, and Phoenix integration.
    """
  end

  defp package do
    [
      name: "pulsar",
      maintainers: ["Your Name"],
      licenses: ["MIT"],
      links: %{
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md",
        "GitHub" => @source_url,
        "Sponsor" => "https://github.com/sponsors/bigrefactor"
      },
      files: ~w(
        lib
        priv/templates
        .formatter.exs
        mix.exs
        README.md
        CHANGELOG.md
        LICENSE
      )
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      extras: [
        "README.md",
        "CHANGELOG.md": [title: "Changelog"],
        LICENSE: [title: "License"]
      ],
      groups_for_modules: [
        Components: [
          Badge,
          Button,
          Checkbox,
          Icon,
          Input,
          Label,
          Link,
          RadioGroup,
          Select,
          Switch,
          Textarea
        ],
        Generators: [
          Mix.Tasks.Pulsar.Gen.Button,
          Mix.Tasks.Pulsar.Install
        ]
      ],
      groups_for_docs: [
        Components: &(&1[:section] == :components),
        Generators: &(&1[:section] == :generators),
        "Mix Tasks": &(&1[:section] == :mix_tasks)
      ]
    ]
  end
end

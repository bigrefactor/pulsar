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
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.cobertura": :test,
        test: :test
      ],

      # Dialyzer configuration
      dialyzer: [
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
        plt_add_apps: [:ex_unit, :mix],
        list_unused_filters: true,
        ignore_warnings: ".dialyzer_ignore.exs"
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:igniter, "~> 0.6", optional: true, runtime: false},
      {:phoenix, "~> 1.8"},
      {:phoenix_live_view, "~> 1.1"},
      {:phoenix_html, "~> 4.0"},
      {:phoenix_html_helpers, "~> 1.0"},
      {:tailwind_merge, github: "bigrefactor/tailwind_merge"},

      # Quality tools
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:quokka, "~> 2.11", only: [:dev, :test], runtime: false},
      {:mix_audit, "~> 2.1", only: [:dev, :test], runtime: false},

      # Documentation and testing
      {:ex_doc, "~> 0.36", only: :dev, runtime: false},
      {:excoveralls, "~> 0.18", only: :test},
      {:ecto, "~> 3.12", only: :test},
      {:phoenix_ecto, "~> 4.6", only: :test}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "compile"],
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
        priv
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

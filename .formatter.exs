# Used by "mix format"
[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  import_deps: [:phoenix, :phoenix_live_view],
  plugins: [Quokka, Phoenix.LiveView.HTMLFormatter],
  line_length: 120,
  quokka: [
    # Auto-sort defstruct field lists. :map was dropped because Quokka 2.13
    # expanded it to struct literals and maps-with-comments, which alphabetized
    # %Info{} blocks in pulsar.gen.* tasks and orphaned their inline field-doc
    # comments. Re-enable only after the affected scaffolds are restructured.
    autosort: [:defstruct],

    # Enforce separate alias lines (no multi-alias syntax)
    enforce_single_alias_per_line: true,

    # Exclude autosort for Ecto schemas. :tests excluded because Quokka 2.13's
    # tests rule strips single-line assertion-descriptor comments
    # (e.g. `# error -> danger` above an assert).
    exclude: [:autosort_ecto, :tests],

    # Sort function clauses by name and arity
    sort_functions: true,

    # Organize imports/aliases in consistent order
    organize_imports: true
  ]
]

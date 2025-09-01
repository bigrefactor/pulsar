# Used by "mix format"
[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  import_deps: [:phoenix, :phoenix_live_view],
  plugins: [Quokka, Phoenix.LiveView.HTMLFormatter],
  line_length: 120,
  quokka: [
    # Auto-sort maps and defstructs
    autosort: [:map, :defstruct],

    # Enforce separate alias lines (no multi-alias syntax)
    enforce_single_alias_per_line: true,

    # Exclude autosort for Ecto schemas as they have specific ordering needs
    exclude: [:autosort_ecto],

    # Sort function clauses by name and arity
    sort_functions: true,

    # Organize imports/aliases in consistent order
    organize_imports: true
  ]
]

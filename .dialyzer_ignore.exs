[
  # Ignore warnings from dependencies that we can't control
  ~r/.*(deps).*Elixir.*no_return/,
  
  # Ignore warnings from generated code or templates
  ~r/.*priv\/templates.*/,
  
  # Ignore warnings from test helper files
  ~r/.*test\/.*helper.*/,
  
  # Example: ignore specific warnings that are false positives
  # ~r/Function.*has no local return/
]
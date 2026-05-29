defmodule Pulsar.DevApp.TextareaLive do
  @moduledoc false
  use Pulsar.DevApp.Web, :live_view

  alias Pulsar.Components.Textarea

  @variants ~w(outline ghost solid)
  @colors ~w(neutral primary secondary success danger warning)
  @sizes ~w(sm md lg)
  @states [
    {"default", []},
    {"required", [required: true]},
    {"readonly", [readonly: true, value: "read only"]},
    {"disabled", [disabled: true, value: "disabled"]},
    {"invalid", [invalid: true]}
  ]

  def render(assigns) do
    assigns =
      assign(assigns, variants: @variants, colors: @colors, sizes: @sizes, states: @states)

    ~H"""
    <.fixture_page name="textarea" title="Textarea">
      <.fixture_section
        :for={variant <- @variants}
        name={"variant-#{variant}"}
        title={"variant: #{variant}"}
      >
        <div class="grid grid-cols-1 gap-3 md:grid-cols-2 w-full">
          <%= for color <- @colors, size <- @sizes, {state_label, state_attrs} <- @states do %>
            <Textarea.textarea
              id={"ta-#{variant}-#{color}-#{size}-#{state_label}"}
              name={"ta_#{variant}_#{color}_#{size}_#{state_label}"}
              variant={variant}
              color={color}
              size={size}
              placeholder={"#{color}/#{size}/#{state_label}"}
              rows={3}
              aria-label={"#{variant} #{color} #{size} #{state_label}"}
              data-fixture-cell={"#{variant}-#{color}-#{size}-#{state_label}"}
              {state_attrs}
            />
          <% end %>
        </div>
      </.fixture_section>
      <.fixture_section name="character-count" title="Character count + max length">
        <Textarea.textarea
          id="ta-cc"
          name="ta_cc"
          rows={3}
          show_character_count
          max_length={120}
          aria-label="character count"
          data-fixture-cell="character-count"
        />
      </.fixture_section>
    </.fixture_page>
    """
  end
end

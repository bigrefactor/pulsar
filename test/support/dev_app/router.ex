defmodule Pulsar.DevApp.Router do
  @moduledoc false
  use Phoenix.Router, helpers: false

  import Phoenix.LiveView.Router
  import PhoenixStorybook.Router

  alias Pulsar.DevApp.Layouts
  alias Pulsar.DevApp.Storybook

  scope "/" do
    storybook_assets()
  end

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/" do
    pipe_through :browser

    live_storybook("/storybook", backend_module: Storybook)
  end

  scope "/", Pulsar.DevApp do
    pipe_through :browser

    live "/", IndexLive, :index
    live "/components/badge", BadgeLive, :index
    live "/components/button", ButtonLive, :index
    live "/components/card", CardLive, :index
    live "/components/checkbox", CheckboxLive, :index
    live "/components/divider", DividerLive, :index
    live "/components/field", FieldLive, :index
    live "/components/flash", FlashLive, :index
    live "/components/flash_group", FlashGroupLive, :index
    live "/components/form", FormLive, :index
    live "/components/header", HeaderLive, :index
    live "/components/icon", IconLive, :index
    live "/components/input", InputLive, :index
    live "/components/label", LabelLive, :index
    live "/components/link", LinkLive, :index
    live "/components/list", ListLive, :index
    live "/components/radio_group", RadioGroupLive, :index
    live "/components/select", SelectLive, :index
    live "/components/switch", SwitchLive, :index
    live "/components/table", TableLive, :index
    live "/components/textarea", TextareaLive, :index

    live "/keyboard/button", Keyboard.ButtonLive, :index
    live "/keyboard/card", Keyboard.CardLive, :index
  end
end

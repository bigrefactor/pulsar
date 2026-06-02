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
    live "/components/flash/trigger", FlashTriggerLive, :index
    live "/components/flash_group", FlashGroupLive, :index
    live "/components/form", FormLive, :index
    live "/components/header", HeaderLive, :index
    live "/components/icon", IconLive, :index
    live "/components/input/outline", InputLive, :outline
    live "/components/input/ghost", InputLive, :ghost
    live "/components/input/solid", InputLive, :solid
    live "/components/label", LabelLive, :index
    live "/components/link", LinkLive, :index
    live "/components/list", ListLive, :index
    live "/components/menu", MenuLive, :index
    live "/components/navbar", NavbarLive, :index
    live "/components/popover", PopoverLive, :index
    live "/components/radio_group", RadioGroupLive, :index
    live "/components/select/outline", SelectLive, :outline
    live "/components/select/ghost", SelectLive, :ghost
    live "/components/select/solid", SelectLive, :solid
    live "/components/select/multi", SelectMultiLive, :index
    live "/components/select/removable", SelectRemoveLive, :index
    live "/components/sidebar", SidebarLive, :index
    live "/components/switch", SwitchLive, :index
    live "/components/table/outline", TableLive, :outline
    live "/components/table/ghost", TableLive, :ghost
    live "/components/table/solid", TableLive, :solid
    live "/components/textarea", TextareaLive, :index

    live "/keyboard/button", Keyboard.ButtonLive, :index
    live "/keyboard/card", Keyboard.CardLive, :index
    live "/keyboard/menu", Keyboard.MenuLive, :index
    live "/keyboard/popover", Keyboard.PopoverLive, :index
    live "/keyboard/radio_group", Keyboard.RadioGroupLive, :index
  end
end

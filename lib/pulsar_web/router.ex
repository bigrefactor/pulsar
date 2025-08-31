defmodule PulsarWeb.Router do
  use Phoenix.Router
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {PulsarWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/" do
    pipe_through :browser

    live "/", Pulsar.Storybook.CatalogLive
    live "/catalog", Pulsar.Storybook.CatalogLive
    live "/catalog/button", Pulsar.Storybook.ButtonLive
    live "/catalog/input", Pulsar.Storybook.InputLive
    live "/catalog/label", Pulsar.Storybook.LabelLive
    live "/catalog/link", Pulsar.Storybook.LinkLive
    live "/catalog/:component", Pulsar.Storybook.CatalogLive
  end
end

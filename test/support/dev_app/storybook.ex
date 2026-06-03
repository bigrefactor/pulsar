defmodule Pulsar.DevApp.Storybook do
  @moduledoc false
  use PhoenixStorybook,
    otp_app: :pulsar,
    content_path: Path.expand("storybook", __DIR__),
    title: "Pulsar",
    css_path: "/assets/app.css",
    js_path: "/assets/storybook.js",
    sandbox_class: "pulsar-sandbox",
    themes: [
      light: [name: "Light"],
      dark: [name: "Dark"]
    ]
end

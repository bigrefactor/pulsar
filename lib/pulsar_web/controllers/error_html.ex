defmodule PulsarWeb.ErrorHTML do
  use Phoenix.Component

  def render("404.html", assigns) do
    ~H"""
    <h1>Not Found</h1>
    """
  end

  def render("500.html", assigns) do
    ~H"""
    <h1>Internal Server Error</h1>
    """
  end
end
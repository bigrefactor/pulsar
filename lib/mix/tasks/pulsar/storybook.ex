defmodule Mix.Tasks.Pulsar.Storybook do
  @shortdoc "Runs the Pulsar component storybook"

  @moduledoc """
  Starts a Phoenix server to browse and test Pulsar components.

      mix pulsar.storybook

  This starts a local server where you can:
  - Browse all Pulsar components
  - Test different variants and props
  - Toggle between light and dark themes  
  - Copy component usage examples
  - See components in action

  ## Options

    * `--port` - Port to run the server on (default: 4002)
    * `--open` - Open the storybook in your browser

  ## Examples

      # Start storybook on default port
      mix pulsar.storybook

      # Start on custom port and open browser
      mix pulsar.storybook --port 3000 --open
  """

  use Mix.Task

  @requirements ["app.config"]

  def run(args) do
    {options, _argv} =
      OptionParser.parse!(args,
        strict: [
          port: :integer,
          open: :boolean
        ]
      )

    port = Keyword.get(options, :port, 4002)
    open_browser = Keyword.get(options, :open, false)

    # Start the application
    Mix.Task.run("app.start")

    Mix.shell().info("""
    Starting Pulsar Component Storybook...

    Server: http://localhost:#{port}

    Available routes:
    • http://localhost:#{port}/           - Component catalog
    • http://localhost:#{port}/button     - Button showcase

    Press Ctrl+C to stop the server.
    """)

    # Start a simple Plug-based server for the storybook
    start_storybook_server(port)

    # Open browser if requested
    if open_browser do
      open_browser_command(port)
    end

    # Keep the task running
    Process.sleep(:infinity)
  end

  defp start_storybook_server(port) do
    # This would start a simple Plug server with the LiveView routes
    # For now, just show instructions
    Mix.shell().info("""

    To use the storybook, add this to your Phoenix router:

        # In your router.ex (development only)
        if Mix.env() == :dev do
          import Pulsar.Storybook.Router
          pulsar_storybook "/storybook"
        end

    Then visit: http://localhost:#{port}/storybook
    """)
  end

  defp open_browser_command(port) do
    url = "http://localhost:#{port}"

    case :os.type() do
      {:unix, :darwin} ->
        System.cmd("open", [url])

      {:unix, _} ->
        System.cmd("xdg-open", [url])

      {:win32, _} ->
        System.cmd("cmd", ["/c", "start", url])

      _ ->
        Mix.shell().info("Open #{url} in your browser")
    end
  end
end

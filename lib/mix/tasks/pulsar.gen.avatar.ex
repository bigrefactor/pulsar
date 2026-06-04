defmodule Mix.Tasks.Pulsar.Gen.Avatar do
  use Pulsar.Generator,
    component: :avatar,
    example: "mix pulsar.gen.avatar",
    long_doc: """
    Generates an avatar component for users and entities with image, initials, or icon fallback.

    Creates a self-contained avatar component that renders an image when a `src`
    is given, falls back to initials derived from a `name`, and finally to a
    generic user icon. Avatars can be linked and composed into an overlapping
    group with an overflow counter.

    ## Example

    ```sh
    mix pulsar.gen.avatar

    # With custom module namespace
    mix pulsar.gen.avatar --components-module=MyAppWeb.UI
    ```

    ## Features

    - Image with fallback: `src` → initials from `name` → user icon
    - Sizes: xs, sm, md, lg, xl, 2xl
    - Variants: solid (filled) and outline (bordered)
    - Linkable via `href`, `navigate`, or `patch`
    - Group composition with `avatar_group/1` and a `+N` overflow counter

    ## Usage Examples

    ```elixir
    # Image avatar with initials fallback
    <.avatar src={@user.avatar_url} name={@user.name} />

    # Initials only
    <.avatar name="Jane Doe" size="lg" />

    # Linked avatar
    <.avatar name="Jane Doe" navigate={~p"/users/123"} />

    # Overlapping group with overflow
    <.avatar_group max={3}>
      <:item :for={user <- @users}>
        <.avatar src={user.avatar_url} name={user.name} />
      </:item>
    </.avatar_group>
    ```

    ## Options

    * `--components-module=MODULE` or `-M` - Target module namespace (default: YourAppWeb.Components)
    """
end

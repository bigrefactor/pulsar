defmodule Pulsar.Gettext do
  @moduledoc """
  Gettext backend used by Pulsar's reference components.

  In a generated app the components reference your application's own backend
  (for example `MyAppWeb.Gettext`); this backend stands in for it so the
  library's reference modules compile and run in isolation.
  """

  use Gettext.Backend, otp_app: :pulsar
end

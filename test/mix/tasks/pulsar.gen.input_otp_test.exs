defmodule Mix.Tasks.Pulsar.Gen.InputOtpTest do
  use ExUnit.Case, async: true

  import Igniter.Test

  describe "pulsar.gen.input_otp" do
    test "creates input_otp component with default naming" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.input_otp", [])
      |> assert_creates("lib/test_web/components/input_otp.ex")
      |> apply_igniter!()
    end

    test "respects custom components module option" do
      phx_test_project()
      |> Igniter.compose_task("pulsar.gen.input_otp", ["--components-module", "MyApp.CustomComponents"])
      |> assert_creates("lib/my_app/custom_components/input_otp.ex")
      |> apply_igniter!()
    end
  end
end

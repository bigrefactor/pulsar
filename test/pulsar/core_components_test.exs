defmodule Pulsar.CoreComponentsTest do
  use ExUnit.Case, async: true

  alias Pulsar.CoreComponents

  describe "translate_error/1" do
    test "interpolates non-count bindings via Gettext.dgettext" do
      assert CoreComponents.translate_error({"must be %{type}", [type: "valid"]}) ==
               "must be valid"
    end

    test "uses count-based plural interpolation via Gettext.dngettext" do
      assert CoreComponents.translate_error({"should be at least %{count} character(s)", [count: 8]}) ==
               "should be at least 8 character(s)"
    end
  end

  describe "translate_errors/2" do
    test "filters a form's full errors keyword list to one field and translates each" do
      errors = [
        name: {"can't be blank", []},
        age: {"is invalid", []},
        name: {"is too short", []}
      ]

      assert CoreComponents.translate_errors(errors, :name) == [
               "can't be blank",
               "is too short"
             ]
    end

    test "returns an empty list when the field has no errors" do
      assert CoreComponents.translate_errors([age: {"is invalid", []}], :name) == []
    end
  end
end

defmodule Pulsar.BackupTestHelper do
  @moduledoc """
  Test helper functions for asserting backup file creation in Igniter tests.

  This module provides utilities for testing that Pulsar generators properly
  back up existing files before overwriting them.
  """

  import ExUnit.Assertions

  @doc """
  Asserts that exactly one backup file matching the given path pattern exists.

  Returns the backup file's path and source for further assertions.

  ## Examples

      {path, source} = assert_backup_created(igniter, "lib/my_app_web/components/button.ex")
      assert path =~ ~r/button\.ex\.bak\.\d{8}T\d{6}/
  """
  def assert_backup_created(igniter, original_path) do
    backup_pattern = "#{original_path}.bak."

    backup_files =
      igniter.rewrite.sources
      |> Enum.filter(fn {path, _source} ->
        String.starts_with?(path, backup_pattern)
      end)

    assert length(backup_files) == 1,
           "Expected exactly one backup file for #{original_path}, found #{length(backup_files)}"

    hd(backup_files)
  end

  @doc """
  Asserts that a backup file was created and contains non-empty content.

  ## Examples

      assert_backup_has_content(igniter, "lib/my_app_web/components/button.ex")
  """
  def assert_backup_has_content(igniter, original_path) do
    {_path, source} = assert_backup_created(igniter, original_path)
    content = Rewrite.Source.get(source, :content)

    assert String.length(content) > 0, "Backup file should not be empty"

    content
  end

  @doc """
  Asserts that a backup file was created and contains the expected content pattern.

  ## Examples

      assert_backup_contains(igniter, "lib/my_app_web/components/button.ex", ~r/defmodule.*Button/)
  """
  def assert_backup_contains(igniter, original_path, pattern) do
    content = assert_backup_has_content(igniter, original_path)

    assert content =~ pattern,
           "Backup file should contain pattern: #{inspect(pattern)}"

    content
  end

  @doc """
  Asserts that no backup files were created for the given path.

  Useful for testing that new file generation doesn't create unnecessary backups.

  ## Examples

      assert_no_backup_created(igniter, "lib/my_app_web/components/new_component.ex")
  """
  def assert_no_backup_created(igniter, original_path) do
    backup_pattern = "#{original_path}.bak."

    backup_files =
      igniter.rewrite.sources
      |> Enum.filter(fn {path, _source} ->
        String.starts_with?(path, backup_pattern)
      end)

    assert Enum.empty?(backup_files),
           "Expected no backup files for #{original_path}, found #{length(backup_files)}"
  end

  @doc """
  Returns all backup files matching the given path pattern.

  Useful for debugging or more complex backup assertions.

  ## Examples

      backups = get_backup_files(igniter, "lib/my_app_web/components/button.ex")
      assert Enum.all?(backups, fn {path, _} -> String.contains?(path, ".bak.") end)
  """
  def get_backup_files(igniter, original_path) do
    backup_pattern = "#{original_path}.bak."

    igniter.rewrite.sources
    |> Enum.filter(fn {path, _source} ->
      String.starts_with?(path, backup_pattern)
    end)
  end
end

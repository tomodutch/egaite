defmodule Egaite.Release do
  @moduledoc """
  Used for executing DB release tasks when run in production without Mix
  installed.
  """
  @app :egaite

  def migrate do
    load_app()

    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  def seed do
    load_app()

    for repo <- repos() do
      seed_file = seed_path(repo)
      IO.puts("🔍 Checking for seed file at #{seed_file}")

      if File.exists?(seed_file) do
        IO.puts("🌱 Running seeds for #{inspect(repo)}")
        Code.eval_file(seed_file)
      else
        IO.puts("⚠️  No seed file found for #{inspect(repo)}")
      end
    end
  end

  def rollback(repo, version) do
    load_app()
    {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :down, to: version))
  end

  defp repos do
    Application.fetch_env!(@app, :ecto_repos)
  end

  defp load_app do
    Application.load(@app)
  end

  defp seed_path(repo), do: Path.join(priv_path(repo), "seeds.exs")

  defp priv_path(repo) do
    repo
    |> Module.split()
    |> List.first()
    |> Macro.underscore()
    |> (fn path -> Application.app_dir(@app, "priv/#{path}/repo") end).()
  end
end

defmodule Egaite.Repo do
  use Ecto.Repo,
    otp_app: :egaite,
    adapter: Ecto.Adapters.Postgres
end

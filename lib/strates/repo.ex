defmodule Strates.Repo do
  use Ecto.Repo,
    otp_app: :strates,
    adapter: Ecto.Adapters.Postgres
end

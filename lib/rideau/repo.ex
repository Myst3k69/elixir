defmodule Rideau.Repo do
  use Ecto.Repo,
    otp_app: :rideau,
    adapter: Ecto.Adapters.SQLite3
end

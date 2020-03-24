defmodule Solitaire.Repo do
  use Ecto.Repo,
    otp_app: :solitaire,
    adapter: Ecto.Adapters.Postgres
end

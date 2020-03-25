# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :solitaire,
  ecto_repos: [Solitaire.Repo]

# Configures the endpoint
config :solitaire, SolitaireWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "4Jjsq5FP9mb7hhetW06TAes6bOZgLfvqDGaR2wvDcrlTY/5W6RLTz7GkUHmQx66o",
  render_errors: [view: SolitaireWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Solitaire.PubSub, adapter: Phoenix.PubSub.PG2],
  live_view: [signing_salt: "SvfJcJBD"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"

# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :reservations,
  ecto_repos: [Reservations.Repo]

# Configures the endpoint
config :reservations, Reservations.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "BntQySnDJfYMZmnWnU9zPFCwzf8ZfcFbD2FkqP4FU+j++lVTYE9yaZH1NCkThwU3",
  render_errors: [view: Reservations.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Reservations.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"

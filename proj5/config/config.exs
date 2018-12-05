# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :proj5,
  ecto_repos: [Proj5.Repo]

# Configures the endpoint
config :proj5, Proj5Web.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "01HUtucpbYxuLM1V5nR4nZN7JFoTdXWc8iSlKNwBhUMfP4uRlI022p7dezOHUMhD",
  render_errors: [view: Proj5Web.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Proj5.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:user_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"

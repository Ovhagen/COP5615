# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :proj3, id_bits: 20,
               timeout: 1000,
               delay:   %{st: 3000,
                          ff: 1000,
                          cp: 5000},
               jitter:  100

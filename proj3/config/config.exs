# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :proj3, id_bits: 30,
               timeout: 5000,
               delay:   %{st: 3000,
                          ff: 5000,
                          cp: 7000},
               jitter:  100
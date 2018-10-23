# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :proj3, id_bits:     30,
               timeout:     3000,
               delay:       %{st: 2000,
                              ff: 4000,
                              cp: 6000},
               jitter:      100,
               replication: 3
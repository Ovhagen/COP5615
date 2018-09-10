# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

config :proj1, nodes:     [:"nodexl1@18.219.116.23",
                           :"nodexl2@18.188.181.236",
						   :"nodexl3@13.59.130.152",
						   :"nodexl4@18.222.164.217",
						   :"pontus@10.138.41.171"],
               benchmark: {20_000_000, 24},
			   timeout:   600000

# Node list:
# :"node1@18.223.149.189"
# :"node2@18.220.239.218"
# :"node3@18.219.232.208"
# :"node4@13.58.100.37"
# :"nodexl1@18.219.116.23"
# :"nodexl2@18.188.181.236"
# :"nodexl3@13.59.130.152"
# :"nodexl4@18.222.164.217"
# :"pontus@10.138.41.171"
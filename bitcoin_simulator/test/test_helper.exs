Application.load(:bitcoin_simulator)

for app <- Application.spec(:bitcoin_simulator, :applications) do
  Application.ensure_all_started(app)
end

ExUnit.start()
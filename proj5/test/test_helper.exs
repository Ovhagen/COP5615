

Application.load(:proj5) #(1)

for app <- Application.spec(:proj5,:applications) do #(2)
  Application.ensure_all_started(:proj5)
end

ExUnit.start()

Ecto.Adapters.SQL.Sandbox.mode(Proj5.Repo, :manual)

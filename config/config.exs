import Config

config :nostrum,
  token: System.get_env("DISCORD_TOKEN"),
  gateway_intents: :all

config :meu_bot,
  store_path: System.get_env("STORE_PATH") || "lembretes.json"

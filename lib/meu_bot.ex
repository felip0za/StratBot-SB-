defmodule MeuBot do
  @moduledoc """
  Ponto de entrada da aplicação. Define o Supervisor principal que
  gerencia os processos filhos: o Store (GenServer de persistência)
  e o Consumer (handler de eventos do Discord via Nostrum).
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      MeuBot.Store,
      MeuBot.Consumer
    ]

    opts = [strategy: :one_for_one, name: MeuBot.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

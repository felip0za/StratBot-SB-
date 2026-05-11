defmodule MeuBot.Store do
  @moduledoc """
  GenServer responsável pela persistência de dados em arquivo JSON local.
  Carrega o estado do arquivo ao iniciar e mantém os dados em memória
  durante a execução, gravando a cada operação de escrita.

  O estado é um Map com chave sendo o user_id (string) e valor uma
  lista de lembretes (strings).
  """

  use GenServer

  @store_path Application.compile_env(:meu_bot, :store_path, "lembretes.json")

  # ─── API Pública ────────────────────────────────────────────────────────────

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc "Adiciona um lembrete para o usuário informado."
  def adicionar(user_id, lembrete) do
    GenServer.call(__MODULE__, {:adicionar, to_string(user_id), lembrete})
  end

  @doc "Retorna a lista de lembretes do usuário informado."
  def listar(user_id) do
    GenServer.call(__MODULE__, {:listar, to_string(user_id)})
  end

  @doc "Remove todos os lembretes do usuário informado."
  def limpar(user_id) do
    GenServer.call(__MODULE__, {:limpar, to_string(user_id)})
  end

  # ─── Callbacks do GenServer ─────────────────────────────────────────────────

  @impl true
  def init(:ok) do
    state = carregar_arquivo()
    {:ok, state}
  end

  @impl true
  def handle_call({:adicionar, user_id, lembrete}, _from, state) do
    lista_atual = Map.get(state, user_id, [])
    novo_estado = Map.put(state, user_id, lista_atual ++ [lembrete])

    :ok = salvar_arquivo(novo_estado)

    {:reply, :ok, novo_estado}
  end

  @impl true
  def handle_call({:listar, user_id}, _from, state) do
    lembretes = Map.get(state, user_id, [])
    {:reply, lembretes, state}
  end

  @impl true
  def handle_call({:limpar, user_id}, _from, state) do
    novo_estado = Map.delete(state, user_id)

    :ok = salvar_arquivo(novo_estado)

    {:reply, :ok, novo_estado}
  end

  # ─── Funções Privadas ────────────────────────────────────────────────────────

  defp carregar_arquivo do
    case File.read(@store_path) do
      {:ok, conteudo} ->
        conteudo
        |> Jason.decode!()

      {:error, :enoent} ->
        %{}
    end
  end

  defp salvar_arquivo(state) do
    conteudo = Jason.encode!(state, pretty: true)
    File.write!(@store_path, conteudo)
    :ok
  end
end

defmodule MeuBot.Consumer do
  @moduledoc """
  Handler de eventos do Discord usando Nostrum.
  Escuta eventos de mensagem e despacha para o módulo Commands
  via pattern matching nas cláusulas de função handle_command/2.

  O prefixo "!" identifica comandos. Mensagens sem prefixo são ignoradas.
  Cada cláusula de handle_command/2 casa com um padrão diferente de tokens,
  garantindo separação clara de responsabilidades sem if/else.
  """

  use Nostrum.Consumer

  alias Nostrum.Api
  alias MeuBot.Commands

  @impl true
  def handle_event({:MESSAGE_CREATE, msg, _ws_state}) do
    if String.starts_with?(msg.content, "!") && !msg.author.bot do
      msg.content
      |> String.trim()
      |> String.split(" ", trim: true)
      |> handle_command(msg)
    end
  end

  def handle_event(_event), do: :noop

  # ─── Despacho de comandos por pattern matching ───────────────────────────────

  # !ping – sem parâmetros
  defp handle_command(["!ping"], msg) do
    Commands.ping(msg)
    |> responder(msg)
  end

  # !clima <cidade> – 1 parâmetro (pode ter espaços na cidade)
  defp handle_command(["!clima" | partes], msg) when partes != [] do
    cidade = Enum.join(partes, " ")

    Commands.clima(msg, cidade)
    |> responder(msg)
  end

  # !perfil <usuario> – 1 parâmetro
  defp handle_command(["!perfil", usuario], msg) do
    Commands.perfil(msg, usuario)
    |> responder(msg)
  end

  # !conv <valor> <de> <para> – 3 parâmetros (2+ exigidos)
  defp handle_command(["!conv", valor, origem, destino], msg) do
    Commands.conv(msg, valor, origem, destino)
    |> responder(msg)
  end

  # !traduzir <idioma> <texto...> – 2+ parâmetros
  defp handle_command(["!traduzir", idioma | palavras], msg) when palavras != [] do
    texto = Enum.join(palavras, " ")

    Commands.traduzir(msg, idioma, texto)
    |> responder(msg)
  end

  # !lembrar <texto...> – persistência: salva lembrete
  defp handle_command(["!lembrar" | palavras], msg) when palavras != [] do
    texto = Enum.join(palavras, " ")

    Commands.lembrar(msg, texto)
    |> responder(msg)
  end

  # !lembretes – persistência: lista lembretes
  defp handle_command(["!lembretes"], msg) do
    Commands.lembretes(msg)
    |> responder(msg)
  end

  # !esquecer – persistência: apaga todos os lembretes
  defp handle_command(["!esquecer"], msg) do
    Commands.esquecer(msg)
    |> responder(msg)
  end

  # !curiosidade – combina duas APIs
  defp handle_command(["!curiosidade"], msg) do
    Commands.curiosidade(msg)
    |> responder(msg)
  end

  # !piada – sem parâmetros
  defp handle_command(["!piada"], msg) do
    Commands.piada(msg)
    |> responder(msg)
  end

  # !ajuda – lista todos os comandos disponíveis
  defp handle_command(["!ajuda"], msg) do
    ajuda()
    |> responder(msg)
  end

  # Cláusula catch-all: comando desconhecido ou uso incorreto
  defp handle_command(["!" <> cmd | _], msg) do
    "❓ Comando `!#{cmd}` não reconhecido. Use `!ajuda` para ver os comandos disponíveis."
    |> responder(msg)
  end

  defp handle_command(_tokens, _msg), do: :noop

  # ─── Funções Auxiliares ──────────────────────────────────────────────────────

  defp responder(texto, msg) do
    Api.create_message(msg.channel_id, texto)
  end

  defp ajuda do
    """
    📖 **Comandos disponíveis:**

    `!ping` — Verifica se o bot está online
    `!clima <cidade>` — Clima atual da cidade (ex: `!clima Fortaleza`)
    `!perfil <usuario>` — Perfil público no GitHub (ex: `!perfil torvalds`)
    `!conv <valor> <de> <para>` — Converte moedas (ex: `!conv 100 USD BRL`)
    `!traduzir <idioma> <texto>` — Traduz texto do PT para outro idioma (ex: `!traduzir en Olá mundo`)
    `!lembrar <texto>` — Salva um lembrete pessoal (ex: `!lembrar Reunião às 10h`)
    `!lembretes` — Lista seus lembretes salvos
    `!esquecer` — Apaga todos os seus lembretes
    `!curiosidade` — Exibe uma curiosidade aleatória
    `!piada` — Conta uma piada aleatória em português
    """
  end
end

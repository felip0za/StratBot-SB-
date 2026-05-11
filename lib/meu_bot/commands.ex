defmodule MeuBot.Commands do
  @moduledoc """
  Implementa cada comando do bot como uma função pública.
  Todas as APIs utilizadas são gratuitas e não exigem chave de acesso.

  Comandos implementados:
    - ping        → sem parâmetro
    - piada       → sem parâmetro  (JokeAPI - sem chave)
    - clima       → 1 parâmetro   (Open-Meteo + Geocoding API - sem chave)
    - perfil      → 1 parâmetro   (GitHub API - sem chave)
    - conv        → 2+ parâmetros (Frankfurter API - sem chave)
    - traduzir    → 2+ parâmetros (MyMemory API - sem chave)
    - lembrar     → persistência  (Store GenServer + arquivo JSON)
    - lembretes   → persistência  (leitura)
    - esquecer    → persistência  (limpeza)
    - curiosidade → 2 APIs combinadas (JokeAPI categorias + piada - sem chave)
  """

  alias MeuBot.Store

  # ─── !ping ──────────────────────────────────────────────────────────────────
  # Sem parâmetros. Verifica se o bot está online.

  def ping(_msg) do
    "🏓 Pong! Bot online e respondendo."
  end

  # ─── !piada ─────────────────────────────────────────────────────────────────
  # Sem parâmetros. Busca piada aleatória via JokeAPI (sem chave).
  # API: https://v2.jokeapi.dev

  def piada(_msg) do
    url = "https://v2.jokeapi.dev/joke/Any?lang=pt&blacklistFlags=nsfw,racist,sexist"

    url
    |> HTTPoison.get()
    |> tratar_resposta_piada()
  end

  defp tratar_resposta_piada({:ok, %{status_code: 200, body: body}}) do
    body
    |> Jason.decode!()
    |> formatar_piada()
  end

  defp tratar_resposta_piada({:error, _}) do
    "❌ Não foi possível buscar uma piada agora."
  end

  defp formatar_piada(%{"type" => "single", "joke" => piada}) do
    "😂 #{piada}"
  end

  defp formatar_piada(%{"type" => "twopart", "setup" => pergunta, "delivery" => resposta}) do
    "😄 **#{pergunta}**\n||#{resposta}||"
  end

  defp formatar_piada(_), do: "❌ Formato de piada desconhecido."

  # ─── !clima <cidade> ────────────────────────────────────────────────────────
  # 1 parâmetro. Usa Open-Meteo + Geocoding API — ambas sem chave.
  # Fluxo: Geocoding converte nome da cidade em lat/lon → Open-Meteo retorna clima.
  # API Geocoding: https://geocoding-api.open-meteo.com
  # API Clima:     https://api.open-meteo.com

  def clima(_msg, cidade) do
    cidade
    |> geocodificar()
    |> buscar_clima_por_coordenadas()
  end

  defp geocodificar(cidade) do
    url = "https://geocoding-api.open-meteo.com/v1/search?name=#{URI.encode(cidade)}&count=1&language=pt&format=json"

    case HTTPoison.get(url) do
      {:ok, %{status_code: 200, body: body}} ->
        body
        |> Jason.decode!()
        |> extrair_coordenadas(cidade)

      _ ->
        {:error, "Não foi possível encontrar a cidade \"#{cidade}\"."}
    end
  end

  defp extrair_coordenadas(%{"results" => [primeiro | _]}, _cidade) do
    lat  = Map.get(primeiro, "latitude")
    lon  = Map.get(primeiro, "longitude")
    nome = Map.get(primeiro, "name")
    pais = Map.get(primeiro, "country", "")
    {:ok, lat, lon, "#{nome}, #{pais}"}
  end

  defp extrair_coordenadas(_, cidade) do
    {:error, "Cidade \"#{cidade}\" não encontrada."}
  end

  defp buscar_clima_por_coordenadas({:error, motivo}), do: "❌ #{motivo}"

  defp buscar_clima_por_coordenadas({:ok, lat, lon, nome}) do
    url = "https://api.open-meteo.com/v1/forecast?latitude=#{lat}&longitude=#{lon}&current=temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code&timezone=auto"

    case HTTPoison.get(url) do
      {:ok, %{status_code: 200, body: body}} ->
        body
        |> Jason.decode!()
        |> formatar_clima(nome)

      _ ->
        "❌ Não foi possível buscar o clima para #{nome}."
    end
  end

  defp formatar_clima(%{"current" => atual}, nome) do
    temp     = Map.get(atual, "temperature_2m", "?")
    umidade  = Map.get(atual, "relative_humidity_2m", "?")
    vento    = Map.get(atual, "wind_speed_10m", "?")
    codigo   = Map.get(atual, "weather_code", 0)
    condicao = interpretar_codigo_clima(codigo)

    """
    🌤️ **Clima em #{nome}**
    🌡️ Temperatura: #{temp}°C
    💧 Umidade: #{umidade}%
    💨 Vento: #{vento} km/h
    📋 Condição: #{condicao}
    """
  end

  defp formatar_clima(_, nome), do: "❌ Não foi possível interpretar o clima de #{nome}."

  defp interpretar_codigo_clima(code) when code == 0,      do: "Céu limpo"
  defp interpretar_codigo_clima(code) when code in 1..3,   do: "Parcialmente nublado"
  defp interpretar_codigo_clima(code) when code in 45..48, do: "Neblina"
  defp interpretar_codigo_clima(code) when code in 51..55, do: "Garoa"
  defp interpretar_codigo_clima(code) when code in 61..65, do: "Chuva"
  defp interpretar_codigo_clima(code) when code in 71..75, do: "Neve"
  defp interpretar_codigo_clima(code) when code in 80..82, do: "Pancadas de chuva"
  defp interpretar_codigo_clima(code) when code in 95..99, do: "Tempestade"
  defp interpretar_codigo_clima(_),                        do: "Condição variável"

  # ─── !perfil <usuario> ──────────────────────────────────────────────────────
  # 1 parâmetro. Busca perfil público no GitHub (sem chave).
  # API: https://api.github.com/users/{username}

  def perfil(_msg, usuario) do
    "https://api.github.com/users/#{URI.encode(usuario)}"
    |> HTTPoison.get([{"User-Agent", "MeuBotDiscord/1.0"}])
    |> tratar_resposta_perfil(usuario)
  end

  defp tratar_resposta_perfil({:ok, %{status_code: 200, body: body}}, _usuario) do
    body
    |> Jason.decode!()
    |> formatar_perfil()
  end

  defp tratar_resposta_perfil({:ok, %{status_code: 404}}, usuario) do
    "❌ Usuário \"#{usuario}\" não encontrado no GitHub."
  end

  defp tratar_resposta_perfil({:error, _}, _usuario) do
    "❌ Erro ao conectar com a API do GitHub."
  end

  defp formatar_perfil(dados) do
    nome       = Map.get(dados, "name") || Map.get(dados, "login")
    login      = Map.get(dados, "login")
    bio        = Map.get(dados, "bio") || "_sem bio_"
    repos      = Map.get(dados, "public_repos", 0)
    seguidores = Map.get(dados, "followers", 0)
    url        = Map.get(dados, "html_url")

    """
    👤 **Perfil GitHub: #{nome}**
    🔗 Login: #{login}
    📝 Bio: #{bio}
    📦 Repositórios públicos: #{repos}
    👥 Seguidores: #{seguidores}
    🌐 #{url}
    """
  end

  # ─── !conv <valor> <de> <para> ──────────────────────────────────────────────
  # 2+ parâmetros. Converte moedas via Open Exchange Rates (sem chave).
  # API: https://open.er-api.com (gratuita, suporta BRL e 160+ moedas)

  def conv(_msg, valor_str, moeda_origem, moeda_destino) do
    origem  = String.upcase(moeda_origem)
    destino = String.upcase(moeda_destino)
    url     = "https://open.er-api.com/v6/latest/#{origem}"

    with {valor, _} <- Float.parse(valor_str),
         {:ok, %{status_code: 200, body: body}} <- HTTPoison.get(url),
         {:ok, dados} <- Jason.decode(body),
         %{"rates" => rates} <- dados,
         taxa when not is_nil(taxa) <- Map.get(rates, destino) do
      resultado = Float.round(valor * taxa, 2)
      "💱 #{valor_str} #{origem} = **#{resultado} #{destino}**\n📈 Taxa: 1 #{origem} = #{taxa} #{destino}"
    else
      :error -> "❌ Valor inválido. Use números como: `!conv 100 USD BRL`"
      {:ok, %{status_code: 404}} -> "❌ Moeda não encontrada: #{moeda_origem}"
      nil -> "❌ Moeda de destino não suportada: #{destino}"
      _   -> "❌ Erro ao buscar taxa de câmbio."
    end
  end

  # ─── !traduzir <idioma> <texto...> ──────────────────────────────────────────
  # 2+ parâmetros. Traduz texto via MyMemory API (sem chave).
  # API: https://mymemory.translated.net
  # Exemplo: !traduzir en Bom dia

  def traduzir(_msg, idioma_destino, texto) do
    url = "https://api.mymemory.translated.net/get?q=#{URI.encode(texto)}&langpair=pt|#{idioma_destino}"

    url
    |> HTTPoison.get()
    |> tratar_resposta_traducao()
  end

  defp tratar_resposta_traducao({:ok, %{status_code: 200, body: body}}) do
    body
    |> Jason.decode!()
    |> formatar_traducao()
  end

  defp tratar_resposta_traducao({:error, _}) do
    "❌ Erro ao conectar com o serviço de tradução."
  end

  defp formatar_traducao(%{"responseStatus" => 200, "responseData" => %{"translatedText" => traduzido}}) do
    "🌐 **Tradução:**\n#{traduzido}"
  end

  defp formatar_traducao(_), do: "❌ Não foi possível realizar a tradução."

  # ─── !lembrar <texto> ───────────────────────────────────────────────────────
  # Persistência (escrita). Salva lembrete no arquivo JSON via Store GenServer.

  def lembrar(msg, texto) do
    user_id = msg.author.id

    :ok = Store.adicionar(user_id, texto)

    "📌 Anotado! Vou me lembrar disso: \"#{texto}\""
  end

  # ─── !lembretes ─────────────────────────────────────────────────────────────
  # Persistência (leitura). Lista lembretes salvos do usuário.

  def lembretes(msg) do
    msg.author.id
    |> Store.listar()
    |> formatar_lembretes()
  end

  defp formatar_lembretes([]) do
    "📭 Você não tem nenhum lembrete salvo. Use `!lembrar <texto>` para adicionar."
  end

  defp formatar_lembretes(lista) do
    itens =
      lista
      |> Enum.with_index(1)
      |> Enum.map(fn {item, idx} -> "#{idx}. #{item}" end)
      |> Enum.join("\n")

    "📋 **Seus lembretes:**\n#{itens}"
  end

  # ─── !esquecer ──────────────────────────────────────────────────────────────
  # Persistência (limpeza). Remove todos os lembretes do usuário.

  def esquecer(msg) do
    :ok = Store.limpar(msg.author.id)
    "🗑️ Todos os seus lembretes foram apagados."
  end

  # ─── !curiosidade ───────────────────────────────────────────────────────────
  # Combina 2 chamadas à JokeAPI (sem chave):
  #   1ª chamada: /categories → lista todas as categorias disponíveis
  #   2ª chamada: usa uma categoria aleatória (resultado da 1ª) para buscar piada
  # API: https://v2.jokeapi.dev

  def curiosidade(_msg) do
    with {:ok, categorias} <- buscar_categorias(),
         categoria          <- Enum.random(categorias),
         {:ok, piada}      <- buscar_piada_por_categoria(categoria) do
      "💡 **Curiosidade engraçada [#{categoria}]:**\n#{piada}"
    else
      {:error, motivo} -> "❌ Erro ao buscar curiosidade: #{motivo}"
    end
  end

  # 1ª chamada: retorna lista de categorias disponíveis na JokeAPI
  defp buscar_categorias do
    url = "https://v2.jokeapi.dev/categories"

    case HTTPoison.get(url) do
      {:ok, %{status_code: 200, body: body}} ->
        categorias =
          body
          |> Jason.decode!()
          |> Map.get("categories", [])

        {:ok, categorias}

      _ ->
        {:error, "não foi possível buscar as categorias"}
    end
  end

  # 2ª chamada: usa a categoria (vinda da 1ª) para buscar uma piada específica
  defp buscar_piada_por_categoria(categoria) do
    url = "https://v2.jokeapi.dev/joke/#{categoria}?blacklistFlags=nsfw,racist,sexist"

    case HTTPoison.get(url) do
      {:ok, %{status_code: 200, body: body}} ->
        piada =
          body
          |> Jason.decode!()
          |> extrair_texto_piada()

        {:ok, piada}

      _ ->
        {:error, "não foi possível buscar a piada"}
    end
  end

  defp extrair_texto_piada(%{"type" => "single", "joke" => texto}), do: texto
  defp extrair_texto_piada(%{"type" => "twopart", "setup" => p, "delivery" => r}), do: "#{p}\n||#{r}||"
  defp extrair_texto_piada(_), do: "Piada não encontrada."
end

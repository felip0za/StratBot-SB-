# MeuBot — Discord Bot em Elixir

Bot para Discord desenvolvido em Elixir com o framework **Nostrum**.
Implementa sete comandos funcionais, cada um consumindo uma API REST diferente,
com persistência de dados em JSON via GenServer.

---

## Pré-requisitos

- Elixir 1.15+
- Erlang/OTP 26+
- Conta no [Discord Developer Portal](https://discord.com/developers/applications)

---

## Configuração

### 1. Clone o repositório

```bash
git clone https://github.com/seu-usuario/meu_bot.git
cd meu_bot
```

### 2. Obtenha as chaves de API

| Variável de Ambiente | Serviço | Plano | Link |
|---|---|---|---|
| `DISCORD_TOKEN` | Discord Bot | Gratuito | [discord.com/developers](https://discord.com/developers/applications) |
| `WEATHER_API_KEY` | OpenWeatherMap | Gratuito (1000 req/dia) | [openweathermap.org](https://openweathermap.org/appid) |
| `EXCHANGE_API_KEY` | ExchangeRate-API | Gratuito (1500 req/mês) | [exchangerate-api.com](https://www.exchangerate-api.com/) |
| `NINJA_API_KEY` | API Ninjas | Gratuito | [api-ninjas.com](https://api-ninjas.com/) |

> A API do GitHub e a MyMemory (tradução) não exigem chave.

### 3. Configure as variáveis de ambiente

**Linux/macOS:**
```bash
export DISCORD_TOKEN="seu_token_aqui"
```

**Windows (PowerShell):**
```powershell
$env:DISCORD_TOKEN="seu_token_aqui"
```

### 4. Instale as dependências e execute

```bash
mix deps.get
mix run --no-halt
```

---

## Comandos

| Comando | Tipo | API | Descrição |
|---|---|---|---|
| `!ping` | Sem parâmetro | — | Verifica se o bot está online |
| `!clima <cidade>` | 1 parâmetro | OpenWeatherMap | Exibe o clima atual da cidade |
| `!perfil <usuario>` | 1 parâmetro | GitHub API | Exibe perfil público do GitHub |
| `!conv <valor> <de> <para>` | 2+ parâmetros | ExchangeRate-API | Converte entre moedas |
| `!traduzir <idioma> <texto>` | 2+ parâmetros | MyMemory API | Traduz texto do PT para outro idioma |
| `!lembrar <texto>` | Persistência | — | Salva um lembrete no arquivo JSON |
| `!lembretes` | Persistência | — | Lista seus lembretes salvos |
| `!esquecer` | Persistência | — | Apaga todos os seus lembretes |
| `!curiosidade` | 2 APIs combinadas | API Ninjas (×2) | Exibe uma curiosidade aleatória |
| `!ajuda` | Sem parâmetro | — | Lista todos os comandos |

### Exemplos de uso

```
!ping
!clima Fortaleza
!perfil torvalds
!conv 100 USD BRL
!traduzir en Bom dia a todos
!lembrar Reunião amanhã às 10h
!lembretes
!esquecer
!curiosidade
```

---

## Arquitetura

```
lib/
├── meu_bot.ex              # Application + Supervisor principal
└── meu_bot/
    ├── consumer.ex         # Handler de eventos Discord (pattern matching)
    ├── commands.ex         # Implementação de cada comando
    └── store.ex            # GenServer de persistência JSON
```

### Módulos

| Módulo | Responsabilidade |
|---|---|
| `MeuBot` | Ponto de entrada (`Application`), define o `Supervisor` com `one_for_one` |
| `MeuBot.Consumer` | Recebe eventos do Discord, extrai tokens e despacha via pattern matching |
| `MeuBot.Commands` | Uma função pública por comando, funções privadas para parsing/formatação |
| `MeuBot.Store` | GenServer que mantém lembretes em memória e persiste em `lembretes.json` |

### Persistência

O arquivo `lembretes.json` é lido na inicialização do `MeuBot.Store` e atualizado a cada operação de escrita. O formato é:

```json
{
  "123456789": ["Reunião às 10h", "Comprar leite"],
  "987654321": ["Estudar Elixir"]
}
```

A chave é o `user_id` do Discord (string), garantindo isolamento por usuário.

---

## Conceitos implementados

- **Pattern Matching**: despacho de comandos em `Consumer.handle_command/2`
- **Pipe operator (`|>`)**: encadeamento em `Commands` e `Store`
- **GenServer**: `Store` mantém estado sem variáveis globais
- **Supervisor**: `MeuBot` supervisiona `Store` e `Consumer` com `one_for_one`
- **HTTPoison**: requisições HTTP para todas as APIs externas
- **Jason**: serialização/deserialização JSON da persistência

---

## Estrutura de arquivos entregue

```
meu_bot/
├── lib/
│   ├── meu_bot.ex
│   └── meu_bot/
│       ├── consumer.ex
│       ├── commands.ex
│       └── store.ex
├── config/
│   └── config.exs
├── mix.exs
├── mix.lock
├── .gitignore
└── README.md
```

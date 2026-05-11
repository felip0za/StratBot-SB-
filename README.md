# StratBot — Discord Bot em Elixir

Bot para Discord desenvolvido em Elixir com o framework **Nostrum**.
Implementa dez comandos funcionais, cada um consumindo uma API REST diferente,
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
git clone https://github.com/felip0za/StratBot-SB-.git
cd StratBot-SB-
```

### 2. APIs utilizadas

Todas as APIs são **gratuitas e não exigem chave de acesso**, exceto o token do Discord.

| Serviço | Comando | Link |
|---|---|---|
| Discord Bot | Todos | [discord.com/developers](https://discord.com/developers/applications) |
| Open-Meteo + Geocoding | `!clima` | [open-meteo.com](https://open-meteo.com) |
| GitHub API | `!perfil` | [api.github.com](https://api.github.com) |
| Open Exchange Rates | `!conv` | [open.er-api.com](https://open.er-api.com) |
| MyMemory API | `!traduzir` | [mymemory.translated.net](https://mymemory.translated.net) |
| JokeAPI | `!piada` e `!curiosidade` | [v2.jokeapi.dev](https://v2.jokeapi.dev) |

### 3. Configure o token do Discord

**Windows (CMD):**
```cmd
set DISCORD_TOKEN=seu_token_aqui
```

**Linux/macOS:**
```bash
export DISCORD_TOKEN="seu_token_aqui"
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
| `!piada` | Sem parâmetro | JokeAPI | Conta uma piada aleatória em português |
| `!clima <cidade>` | 1 parâmetro | Open-Meteo + Geocoding | Exibe o clima atual da cidade |
| `!perfil <usuario>` | 1 parâmetro | GitHub API | Exibe perfil público do GitHub |
| `!conv <valor> <de> <para>` | 2+ parâmetros | Open Exchange Rates | Converte entre moedas |
| `!traduzir <idioma> <texto>` | 2+ parâmetros | MyMemory API | Traduz texto do PT para outro idioma |
| `!lembrar <texto>` | Persistência (escrita) | — | Salva um lembrete no arquivo JSON |
| `!lembretes` | Persistência (leitura) | — | Lista seus lembretes salvos |
| `!esquecer` | Persistência (limpeza) | — | Apaga todos os seus lembretes |
| `!curiosidade` | 2 APIs combinadas | JokeAPI (×2) | Busca categoria aleatória e exibe piada |
| `!ajuda` | Sem parâmetro | — | Lista todos os comandos disponíveis |

### Exemplos de uso

```
!ping
!piada
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
- **Imutabilidade**: nenhuma variável global ou estado mutável no código

---

## Estrutura de arquivos entregue

```
StratBot-SB-/
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

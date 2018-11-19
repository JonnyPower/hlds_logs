# HLDSLogs

  [![Build Status](https://travis-ci.org/JonnyPower/hlds_logs.svg?branch=master)](https://travis-ci.org/JonnyPower/hlds_logs)
  [![Hex.pm](https://img.shields.io/hexpm/v/hlds_logs.svg)](https://hex.pm/packages/hlds_logs)

  A library for connecting to Half-Life Dedicated Servers (a.k.a "HLDS") and using GenStage to produce structured
  log entries sent from the connected HLDS server.

## Installation

```elixir
def deps do
  [
    {:hlds_logs, "~> 0.1.0"}
  ]
end
```

## Quickstart

If you are running a HLDS server and want to consume log entries from the game server, you could connect and consume by 
calling `HLDSLogs.produce_logs/3`;

```elixir
HLDSLogs.produce_logs(
  %HLDSRcon.ServerInfo{
    host: "127.0.0.1",
    port: 27015
  },
  %HLDSLogs.ListenInfo{
    host: "127.0.0.1"
  },
  consumer_pid
)
```

Your consumer would then begin receiving `%HLDSLogs.LogEntry` structs as events, for you to carry out processing as you wish.

## Documentation

HexDocs at [https://hexdocs.pm/hlds_logs](https://hexdocs.pm/hlds_logs).
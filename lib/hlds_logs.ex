defmodule HLDSLogs do
  @moduledoc """
  A library for connecting to Half-Life Dedicated Servers (a.k.a "HLDS") and using GenStage to produce structured
  log entries sent from the connected HLDS server.

  Uses a `DynamicSupervisor` for creating producers. If you want to manage the producer supervision yourself you can use
  the `HLDSLogs.LogProducer` module directly, however it will still call `HLDSRcon.connect/2` which makes use of another
  `DynamicSupervisor`.

  ## Quickstart

  If you are running a HLDS server and want to consume log entries from the game server, you could connect and consume by
  calling `HLDSLogs.produce_logs/3`;

  ```
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

  """

  alias HLDSRcon.ServerInfo
  alias HLDSLogs.ListenInfo

  @doc """
    Similar to `produce_logs/3`, except no consumers will be subsrcibed to the producer immediately after starting
  """
  @spec produce_logs(%HLDSRcon.ServerInfo{}, %HLDSLogs.ListenInfo{}) :: {:ok, pid()}
  def produce_logs(
        %ServerInfo{} = from,
        %ListenInfo{} = to
      ) do
    produce_logs(from, to, [])
  end

  @doc """
    Creates a producer that will connect to the server specified by the `HLDSRcon.ServerInfo` struct in `from`, instructing
    HLDS to connect to the `HLDSLogs.ListenInfo` struct in `to`, where the information in `to` will be used for setting
    up a local UDP socket that must be reachable by the HLDS server.

    After the producer is set up, each consumer in `consumers` will be subscribed to the producer. Returns the producer pid.
  """
  @spec produce_logs(%HLDSRcon.ServerInfo{}, %HLDSLogs.ListenInfo{}, list()) :: {:ok, pid()}
  def produce_logs(
        %ServerInfo{} = from,
        %ListenInfo{} = to,
        consumers
      ) when is_list(consumers) do
    {:ok, pid} = DynamicSupervisor.start_child(HLDSLogs.ProducerSupervisor, {HLDSLogs.LogProducer, {from, to}})
    consumers
    |> Enum.map(&GenStage.sync_subscribe(&1, to: pid))
    {:ok, pid}
  end

  def produce_logs(
        %ServerInfo{} = from,
        %ListenInfo{} = to,
        consumer
      ) do
    produce_logs(from, to, [consumer])
  end

end

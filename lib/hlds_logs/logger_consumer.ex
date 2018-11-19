defmodule HLDSLogs.LoggerConsumer do
  @moduledoc false
  use GenStage

  require Logger

  def start_link() do
    GenStage.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    {:consumer, nil}
  end

  def handle_events(events, _from, nil) do
    events
    |> Enum.map(fn log_entry -> log_entry.body end)
    |> Enum.map(&Logger.info/1)
    {:noreply, [], nil}
  end

end
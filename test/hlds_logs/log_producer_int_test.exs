defmodule HLDSLogs.LogProducerIntegrationTest do
  use ExUnit.Case

  @sample_log_lines 5000

  defmodule TestConsumer do
    use GenStage

    def start_link(test_pid) do
      GenStage.start_link(__MODULE__, test_pid)
    end

    def init(test_pid) do
      {:consumer, test_pid}
    end

    def handle_events(events, _from, test_pid) do
      events
      |> Enum.map(fn result ->
        send test_pid, {:log, result}
      end)
      {:noreply, [], test_pid}
    end
  end

  setup do
    {:ok, pid} = MockHLDSServer.start_link()
    port = GenServer.call(pid, :get_port)
    {:ok, mock_pid: pid, mock_port: port}
  end

  test "producer integration: log entries produced", context do
    {:ok, consumer_pid} = TestConsumer.start_link(self())
    {:ok, producer_pid} = HLDSLogs.LogProducer.start_link({
      %HLDSRcon.ServerInfo{
        host: "127.0.0.1",
        port: context[:mock_port]
      },
      %HLDSLogs.ListenInfo{
        host: "127.0.0.1"
      }
    })
    GenStage.sync_subscribe(consumer_pid, to: producer_pid)
    await_logs(0)
  end

  defp await_logs(seen_count) do
    receive do
      {:log, %HLDSLogs.LogEntry{} = log_entry} ->
        assert_log_entry(log_entry)
        await_logs(seen_count + 1)
    after 5_000 ->
      assert seen_count == @sample_log_lines
    end
  end

  defp assert_log_entry(log_entry) do
    assert log_entry.datetime != nil
    assert log_entry.body != nil
  end

end
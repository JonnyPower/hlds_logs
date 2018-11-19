defmodule HLDSLogsTest do
  use ExUnit.Case
  doctest HLDSLogs

  defmodule TestConsumer do
    use GenStage
    def start_link(test_pid), do: GenStage.start_link(__MODULE__, test_pid)
    def init(test_pid), do: {:consumer, test_pid}
    def handle_events(_events, _from, test_pid), do: {:noreply, [], test_pid}
    def handle_subscribe(:producer, _options, _from, test_pid) do
      send test_pid, :subscribed
      {:manual, test_pid}
    end
  end

  setup do
    {:ok, pid} = MockHLDSServer.start_link()
    port = GenServer.call(pid, :get_port)
    {:ok, mock_pid: pid, mock_port: port}
  end

  test "consumer subscribed", context do
    {:ok, dummy_consumer} = TestConsumer.start_link(self())
    {:ok, producer_pid} = HLDSLogs.produce_logs(
      %HLDSRcon.ServerInfo{
        host: "127.0.0.1",
        port: context[:mock_port]
      },
      %HLDSLogs.ListenInfo{
        host: "127.0.0.1"
      },
      dummy_consumer
    )
    receive do
      :subscribed -> nil
    after 0 -> flunk "was not subscribed"
    end
    DynamicSupervisor.terminate_child(HLDSLogs.ProducerSupervisor, producer_pid)
  end

  test "produce many", context do
    {:ok, other_mock_pid} = MockHLDSServer.start_link()
    other_mock_port = GenServer.call(other_mock_pid, :get_port)

    {:ok, _} = HLDSLogs.produce_logs(
      %HLDSRcon.ServerInfo{
        host: "127.0.0.1",
        port: context[:mock_port]
      },
      %HLDSLogs.ListenInfo{
        host: "127.0.0.1"
      }
    )

    {:ok, _} = HLDSLogs.produce_logs(
      %HLDSRcon.ServerInfo{
        host: "127.0.0.1",
        port: other_mock_port
      },
      %HLDSLogs.ListenInfo{
        host: "127.0.0.1"
      }
    )
  end

end

defmodule HLDSLogs.LogProducerTest do
  use ExUnit.Case
  doctest HLDSLogs.LogProducer

  @sample_log_lines 5000

  defmodule MockHLDSServer do
    use GenServer

    def start_link() do
      GenServer.start_link(__MODULE__, :ok)
    end

    def init(:ok) do
      {:ok, hlds_socket} = :gen_udp.open(0, [:binary, active: true])
      {:ok, hlds_port} = :inet.port(hlds_socket)
      {:ok, %{
        socket: hlds_socket,
        port: hlds_port
      }}
    end

    # getchallenge
    def handle_info({:udp, _socket, from_addr, from_port, <<255, 255, 255, 255>> <> "getchallenge" <> _}, state) do
      :gen_udp.send(state.socket, from_addr, from_port, <<255, 255, 255, 255>> <> "A12345678 1234567890 0\n\0")
      {:noreply, state}
    end

    def handle_info({:udp, _socket, from_addr, from_port, <<255, 255, 255, 255>> <> "rcon 1234567890 foo logaddress_add 127.0.0.1 " <> log_port_string}, state) do
      {log_port, _} = Integer.parse(log_port_string)
      :gen_udp.send(state.socket, from_addr, from_port, <<255, 255, 255, 255, 108>> <> "\n\0")

      File.stream!("test/test_sample.log")
      |> Stream.map(fn line ->
        :gen_udp.send(state.socket, from_addr, log_port, <<255, 255, 255, 255, 108>> <> line)
        Process.sleep(2)
      end)
      |> Stream.run()

      {:noreply, state}
    end

    def handle_call(:get_port, _from, state) do
      {:reply, state.port, state}
    end

  end

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
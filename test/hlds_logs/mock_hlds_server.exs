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
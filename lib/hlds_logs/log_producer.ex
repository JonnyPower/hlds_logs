defmodule HLDSLogs.LogProducer do
  @moduledoc """
  A `GenStage` producer that connects to a HLDS server and sets up log forwarding to itself. Should only be calling this
  module directly if you want to manage the supervision of these processes yourself, otherwise the functions in
  `HLDSLogs` will create processes under a dynamic supervisor.

  When a process is started, it is provided with host:port informtion for the HLDS server, and self-referenial host:port
  information to provide to the HLDS server. The self-referencial host information must be reachable from the HLDS server.

  ## Log Forwarding

  HLDS provides a mechanisim for forwarding logged messages over UDP to a designated host:port. This is set up with the
  `logaddress` console commands. This module will use `HLDSRcon` to set up an rcon connection to the HLDS server, then it
  will issue the `logaddress_add` command with the self-referencial host information it was provided - this will cause
  HLDS to forward all log entries to this process.

  ## Producer

  This producer will create a single event, represented by the `HLDSLogs.LogEntry` struct, for each log entry it recieves.
  It does not respond to consumer demand, and instead creates events as soon as possible, based on the log activity from
  the HLDS server.

  ## Example Consumer

  This example module is set up to simply forward log bodies from HLDS to `Logger.info/1`.

  ```
  defmodule LoggerConsumer do
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
  ```

  """
  use GenStage

  @global_name_prefix "HLDSLogs.LogProducer:"
  @logaddress_add_command "logaddress_add"

  alias HLDSRcon.ServerInfo
  alias HLDSLogs.ListenInfo

  @doc """
    Creates a producer that will connect to the server.

    Server and listener information is given in a tuple, where the first element is a `HLDSRcon.ServerInfo` struct defining
    the HLDS host:port information, and the second element in the tuple is a `HLDSLogs.ListenInfo` struct defining the host:port
    information for this process.

    The `HLDSLogs.ListenInfo` struct is used to create a UDP socket by this process, and for informing the HLDS server where
    to forward logs. If a port is not specified, a port will be select by the OS.
  """
  @spec start_link({%HLDSRcon.ServerInfo{}, %HLDSLogs.ListenInfo{}}) :: GenServer.on_start()
  def start_link({%ServerInfo{} = server_info, %ListenInfo{} = listen_info}) do
    GenStage.start_link(
      __MODULE__,
      {server_info, listen_info},
      name: {
        :global, get_global_name(server_info, listen_info)
      }
    )
  end

  @doc false
  def init({
        %ServerInfo{} = server_info,
        %ListenInfo{
          port: listen_port
        } = listen_info
  }) do
    {:ok, socket} = :gen_udp.open(listen_port, [:binary, active: true])
    # Could be OS assigned if 0, not necessarily the same as listen_port
    {:ok, assigned_port} = :inet.port(socket)
    :ok = establish_logaddress(server_info, listen_info, assigned_port)
    {
      :producer,
      %{
        server_info: server_info,
        listen_info: listen_info,
        assigned_port: assigned_port,
        socket: socket
      }
    }
  end

  @doc """
    Get the UDP port used by the processes socket to recieve log messages. Useful to determine port when OS assigned.
  """
  def handle_call(:get_port, _from, state) do
    {:reply, state.assigned_port, [], state}
  end

  @doc false
  def handle_info({:udp, _socket, _address, _port, data}, state) do
    {
      :noreply,
      data
      |> String.chunk(:printable)
      |> Enum.filter(&String.valid?/1)
      |> Enum.filter(fn s -> s != "" end)
      |> Enum.map(&HLDSLogs.LogEntry.from/1)
      |> Enum.filter(fn s -> s != nil end),
      state
    }
  end

  @doc false
  def handle_demand(_demand, state) do
    {:noreply, [], state}
  end

  @doc false
  defp establish_logaddress(%ServerInfo{} = server_info, %ListenInfo{
    host: listen_host
  }, assigned_port) do
    {:ok, _pid} = HLDSRcon.connect(server_info)
    {:ok, _resp} = HLDSRcon.command(
      server_info.host,
      server_info.port,
      @logaddress_add_command <> " " <> listen_host <> " " <> Integer.to_string(assigned_port)
    )
    :ok
  end

  defp get_global_name(%ServerInfo{} = server_info, %ListenInfo{} = listen_info) do
    @global_name_prefix <> "from:" <> server_info.host <> ":" <> Integer.to_string(server_info.port) <> ":to:" <> listen_info.host <> ":" <> Integer.to_string(listen_info.port)
  end

end

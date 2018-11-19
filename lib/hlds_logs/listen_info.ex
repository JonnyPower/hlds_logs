defmodule HLDSLogs.ListenInfo do
  @moduledoc """
    A struct to represent log address information. `host` defaults to "127.0.0.1" and `port` defaults to 0.

    ```
    iex(1)> %HLDSLogs.ListenInfo{}
    %HLDSLogs.ListenInfo{host: "127.0.0.1", port: 0}
    ```

  """
  defstruct host: "127.0.0.1", port: 0
end

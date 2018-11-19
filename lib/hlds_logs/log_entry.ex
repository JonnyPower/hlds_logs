defmodule HLDSLogs.LogEntry do
  @moduledoc """
  A struct representing a HLDS log entry. Simply holds a parsed `NaiveDateTime`, `datetime` and a binary string `body`.

    ```
    iex(1)> HLDSLogs.LogEntry.from(
    ...(1)>   "L 05/10/2018 - 18:14:39: \\"player18<7><STEAM_0:0:0000000000><marine1team>\\" triggered \\"structure_built\\" (type \\"resourcetower\\")"
    ...(1)> )
    %HLDSLogs.LogEntry{
      body: "\\"player18<7><STEAM_0:0:0000000000><marine1team>\\" triggered \\"structure_built\\" (type \\"resourcetower\\")",
      datetime: ~N[2018-05-10 18:14:39]
    }
    ```

  ## Why NaiveDateTime?

  HLDS does not provide timezone information with it's forwarded logs, so this can't be discerned. It's up to the caller
  to understand where servers are, what timezone the box is in, and deal with the resulting datetimes accordingly.
  """
  defstruct datetime: nil, body: nil

  @capture_date_and_entry ~r/^.*?L ([0-9]{2}\/[0-9]{2}\/[0-9]{4}) - ([0-9]{2}:[0-9]{2}:[0-9]{2}): (.*)/s
  @capture_date_parts ~r/([0-9]{2})\/([0-9]{2})\/([0-9]{4})/

  @doc """
  Create a `HLDSLogs.LogEntry` struct from a raw string received by a HLDS server
  """
  @spec from(String.t()) :: %HLDSLogs.LogEntry{} | nil
  def from(raw_log_entry) when is_binary(raw_log_entry) do
    case Regex.run(
      @capture_date_and_entry,
      raw_log_entry,
      capture: :all_but_first
    ) do
      [date_string, time_string, body] ->
        {:ok, datetime} = NaiveDateTime.new(
          date_string
          |> date_iso8601_from_log,
          Time.from_iso8601!(time_string)
        )
        %HLDSLogs.LogEntry{
          datetime: datetime,
          body: body
        }
      _ -> nil
    end
  end

  defp date_iso8601_from_log(date_string) do
    Date.from_iso8601!(
      Regex.run(
        @capture_date_parts,
        date_string,
        capture: :all_but_first
      )
      |> (fn [month, day, year] -> year <> "-" <> month <> "-" <> day end).()
    )
  end

end

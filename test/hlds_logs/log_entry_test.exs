defmodule HLDSLogs.LogEntryTest do
  use ExUnit.Case
  doctest HLDSLogs.LogEntry

  test "sample produces entries" do
    File.stream!("test/test_sample.log")
    |> Stream.map(&HLDSLogs.LogEntry.from/1)
    |> Stream.map(fn result ->
      assert result.datetime != nil
      assert result.body != nil
    end)
    |> Stream.run
  end

  test "datetime" do
    entry = HLDSLogs.LogEntry.from(
      "L 05/10/2018 - 18:14:39: \"player18<7><STEAM_0:0:0000000000><marine1team>\" triggered \"structure_built\" (type \"resourcetower\")"
    )
    assert entry.datetime == ~N[2018-05-10 18:14:39]
  end

  test "body" do
    entry = HLDSLogs.LogEntry.from(
      "L 05/10/2018 - 18:14:39: \"player18<7><STEAM_0:0:0000000000><marine1team>\" triggered \"structure_built\" (type \"resourcetower\")"
    )
    assert entry.body == "\"player18<7><STEAM_0:0:0000000000><marine1team>\" triggered \"structure_built\" (type \"resourcetower\")"
  end

end

defmodule HLDSLogs.LogProducerTest do
  use ExUnit.Case
  doctest HLDSLogs.LogProducer

  test "events from udp message" do
    assert {:noreply, [%HLDSLogs.LogEntry{}], nil} = HLDSLogs.LogProducer.handle_info(
      {
        :udp,
        nil,
        nil,
        nil,
        <<255, 255, 255, 255, 108>> <> "L 05/10/2018 - 18:14:39: \"player18<7><STEAM_0:0:0000000000><marine1team>\" triggered \"structure_built\" (type \"resourcetower\")"
      },
      nil
    )
  end

end
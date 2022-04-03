defmodule OGNSim.Object do
  use GenServer
  require Logger

  @impl true
  def init([id, counters_tid]) do
    Registry.register(Registry.Objects, "objects", nil)

    {:ok, %{id: id, counters_tid: counters_tid}}
  end

  @impl true
  def handle_info(:send_packet, state) do
    # (1000 * :rand.uniform()) |> round |> :timer.sleep()
    {_, {h, m, s}} = :calendar.universal_time()
    h_str = h |> Integer.to_string() |> String.pad_leading(2, "0")
    m_str = m |> Integer.to_string() |> String.pad_leading(2, "0")
    s_str = s |> Integer.to_string() |> String.pad_leading(2, "0")

    time_str = <<h_str::bytes, m_str::bytes, s_str::bytes, "h">>
    ogn_id = :binary.encode_unsigned(0x10000 + state.id) |> Base.encode16()
    ogn_id_str = "id07" <> ogn_id
    aprs_id_str = "OGN" <> ogn_id

    # OGN123456>OGNTRK,qAS,EPKA:/123456h5001.02N/02004.05E'000/000/A=001234 !W11! id07EDD94C +000fpm 0.0rot 10.0dB 0e +1.0kHz gps3x3

    line_endl =
      "#{aprs_id_str}>OGNTRK,qAS,EPKA:/#{time_str}5001.02N/02004.05E'000/000/A=001234 !W11! #{ogn_id_str} +000fpm 0.0rot 10.0dB 0e +1.0kHz gps3x3\r\n"

    :ets.update_counter(state.counters_tid, :pkt_counter, {2, 1})
    :ets.update_counter(state.counters_tid, :pkt_len_counter, {2, byte_size(line_endl)})

    Registry.dispatch(Registry.ConnectionsTCP, "conns", fn entries ->
      for {pid, _} <- entries, do: send(pid, {:aprs, line_endl})
    end)

    {:noreply, state}
  end

  # -----------------------------

  def start(id, counters_tid) do
    GenServer.start(__MODULE__, [id, counters_tid])
  end
end

defmodule OGNSim.APRSConnection do
  # Server will send KA every 20 seconds
  @server_ka_timer_msec 20_000
  # Client should send any message ay least every 5 minutes
  @client_ka_timer_msec 300_000
  # non-full buffer TX timeout
  @tx_timeout_msec 250

  use GenServer
  require Logger

  # ----- ConnectionTCP API -----
  def start(object_id, socket) do
    GenServer.start(__MODULE__, [object_id, socket])
  end

  def disconnect(pid) do
    GenServer.cast(pid, :disconnect)
  end

  # ----- ConnectionTCP callbacks -----
  @impl true
  def init([object_id, socket]) do
    :ok = :inet.setopts(socket, active: true, nodelay: true)
    {:ok, {{ip1, ip2, ip3, ip4}, port}} = :inet.peername(socket)
    peer_str = "#{ip1}.#{ip2}.#{ip3}.#{ip4}:#{port}"
    {:ok, _} = Registry.register(Registry.ConnectionsTCP, "conns", {object_id, peer_str})
    IO.puts("APRS connection #{inspect(object_id)}: started.")
    server_ka_timer_ref = :erlang.send_after(@server_ka_timer_msec, self(), :server_ka_timer_exp)
    client_ka_timer_ref = :erlang.send_after(@client_ka_timer_msec, self(), :client_ka_timer_exp)
    last_rx_time = :erlang.system_time(:millisecond)
    last_tx_time = :erlang.system_time(:millisecond)
    {:ok, tx_tout_tref} = :timer.send_interval(@tx_timeout_msec, :tx_tout_check)

    state = %{
      object_id: object_id,
      socket: socket,
      server_ka_timer_ref: server_ka_timer_ref,
      client_ka_timer_ref: client_ka_timer_ref,
      last_rx_time: last_rx_time,
      last_tx_time: last_tx_time,
      tx_tout_tref: tx_tout_tref,
      aprs_packets: []
    }

    {:ok, state}
  end

  @impl true
  def handle_info(:disconnect, state) do
    IO.puts("APRS connection #{inspect(state.object_id)}: disconnect.")
    :gen_tcp.close(state.socket)
    {:stop, :normal, %{}}
  end

  def handle_info({:aprs, packet}, state) do
    new_packets = state.aprs_packets ++ [packet]

    if :erlang.iolist_size(new_packets) > 4096 do
      case :gen_tcp.send(state.socket, new_packets) do
        :ok -> :ok
        # During heavy traffic TCP connection could be disconnected before receiving :tcp_closed msg 
        {:error, :closed} -> :ok
      end

      {:noreply, %{state | last_tx_time: :erlang.system_time(:millisecond), aprs_packets: []}}
    else
      {:noreply, %{state | aprs_packets: new_packets}}
    end
  end

  def handle_info({:tcp, _port, packet}, state) do
    last_rx_time = :erlang.system_time(:millisecond)

    case packet do
      <<"#", _::bytes>> -> :ok
      pkt -> IO.puts("Warning: APRS server is read only, got: #{pkt}")
    end

    {:noreply, %{state | last_rx_time: last_rx_time}}
  end

  def handle_info(:tx_tout_check, state) when length(state.aprs_packets) > 0 do
    curr_time = :erlang.system_time(:millisecond)

    if curr_time - state.last_tx_time > @tx_timeout_msec do
      :ok = :gen_tcp.send(state.socket, state.aprs_packets)
      {:noreply, %{state | last_tx_time: curr_time, aprs_packets: []}}
    else
      {:noreply, state}
    end
  end

  def handle_info(:tx_tout_check, state), do: {:noreply, state}

  def handle_info(:server_ka_timer_exp, state) do
    ka_pkt = "# ognsim 0.1.0\r\n"
    :ok = :gen_tcp.send(state.socket, ka_pkt)
    server_ka_timer_ref = :erlang.send_after(@server_ka_timer_msec, self(), :server_ka_timer_exp)
    {:noreply, %{state | server_ka_timer_ref: server_ka_timer_ref}}
  end

  def handle_info(:client_ka_timer_exp, state) do
    if :erlang.system_time(:millisecond) - state.last_rx_time > @client_ka_timer_msec do
      IO.puts("APRS connection #{inspect(state.object_id)}: client timeout, disconnecting.")

      :gen_tcp.close(state.socket)
      {:stop, :normal, %{}}
    else
      client_ka_timer_ref =
        :erlang.send_after(@client_ka_timer_msec, self(), :client_ka_timer_exp)

      {:noreply, %{state | client_ka_timer_ref: client_ka_timer_ref}}
    end
  end

  def handle_info({:tcp_closed, _port}, state) do
    IO.puts("APRS connection #{inspect(state.object_id)}: closed.")
    {:stop, :normal, %{}}
  end

  def handle_info({:error, :closed}, state) do
    IO.puts("APRS connection #{inspect(state.object_id)}: closed with error.")
    {:stop, :normal, %{}}
  end
end

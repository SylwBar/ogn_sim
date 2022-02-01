defmodule OGNSim.APRSServer do
  @login_timeout_ms 5000

  use GenServer
  require Logger
  import NimbleParsec

  # ----- APRSServer API -----

  def start(port, name) do
    case :gen_tcp.listen(port, [:binary, active: false]) do
      {:ok, listen_socket} ->
        :gen_tcp.close(listen_socket)

      {:error, :eaddrinuse} ->
        IO.puts(
          "APRS server: port #{port} in use, possible causes:
          - other app is using it,
          - TCP TIME_WAIT timer is active - connection was not properly disconnected.
            Check /proc/sys/net/ipv4/tcp_fin_timeout value and retry after it expires (60-120 seconds)."
        )

        System.stop(0)
        :timer.sleep(:infinity)

      {:error, error} ->
        IO.puts("APRS server: error: #{inspect(error)}")
        System.stop(0)
        :timer.sleep(:infinity)
    end

    GenServer.start(__MODULE__, [port, name], name: __MODULE__)
  end

  # ----- APRSServer callbacks -----

  # ----- APRSServer process init. function -----
  @impl true
  def init([port, name]) do
    case :gen_tcp.listen(port, [:binary, active: false]) do
      {:ok, listen_socket} ->
        spawn(fn -> acceptor(listen_socket) end)
        state = %{server_port: port, listen_socket: listen_socket, server_name: name}
        IO.puts("APRS server #{name} started, listening on port: #{port}")
        {:ok, state}

      {:error, error} ->
        IO.puts("APRS server: error: #{inspect(error)}")
        System.stop(0)
        :timer.sleep(:infinity)
    end
  end

  # ----- private functions -----
  defp acceptor(listen_socket) do
    case :gen_tcp.accept(listen_socket) do
      {:ok, socket} ->
        spawn(fn -> acceptor(listen_socket) end)
        handle(socket)

      error ->
        Logger.error("OGNSim.APRSServer: #{inspect(error)}")
    end
  end

  defp handle(socket) do
    :gen_tcp.send(socket, "# ogn_sim 0.0.1\r\n")

    case :gen_tcp.recv(socket, 0, @login_timeout_ms) do
      {:ok, data} ->
        {user, _password} = parse_login(data)
        :gen_tcp.send(socket, "# logresp #{user} verified, server OGNSIM\r\n")
        {:ok, connection_pid} = OGNSim.APRSConnection.start(user, socket)
        :ok = :gen_tcp.controlling_process(socket, connection_pid)

      {:error, error} ->
        Logger.debug("OGNSim.APRSServer: receive error #{inspect(error)}")
        :error
    end
  end

  # ----- APRS parsing functions -----
  user_id = ascii_string([?A..?Z, ?a..?z, ?0..?9, ?-], min: 1)
  password = integer(min: 1, max: 5)

  # example: user SQ9PCB pass 23201 vers aprsc 2.1.10-gd72a17c\r\n
  defparsec(
    :aprs_login,
    ignore(string("user "))
    |> concat(user_id)
    |> ignore(string(" pass "))
    |> concat(password),
    debug: false
  )

  def parse_login(login) do
    {:ok, [user, password], _rest, _, _, _} = OGNSim.APRSServer.aprs_login(login)
    {user, password}
  end
end

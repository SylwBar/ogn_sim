defmodule OgnSim do
  @def_aprs_server_port 10152
  @def_aprs_server_name "OGNSIM"

  def parse_args(argv) do
    try do
      {opt_list, _arg_list} =
        OptionParser.parse!(argv,
          strict: [
            help: :boolean,
            port: :integer,
            name: :string,
            objs: :integer,
            file: :string,
            multi: :string,
            log: :string,
            rate: :boolean
          ],
          aliases: [
            h: :help,
            p: :port,
            n: :name,
            o: :objs,
            f: :file,
            m: :multi,
            l: :log,
            r: :rate
          ]
        )

      opts = :proplists.to_map(opt_list)
      help = Map.get(opts, :help, false)

      if help do
        print_help()
        :help
      else
        port = Map.get(opts, :port, @def_aprs_server_port)
        name = Map.get(opts, :name, @def_aprs_server_name)
        objs = Map.get(opts, :objs, 0)
        file = Map.get(opts, :file)
        multi = Map.get(opts, :multi)
        log = Map.get(opts, :log)
        rate = Map.get(opts, :rate, false)

        if multi != nil and file == nil do
          raise "Error: --multi used without --file selected."
        end

        multi_opt =
          if multi != nil do
            File.read!(multi) |> Poison.decode!()
          else
            nil
          end

        {:ok,
         %{port: port, name: name, objs: objs, file: file, multi: multi_opt, log: log, rate: rate}}
      end
    rescue
      e in File.Error ->
        IO.puts("Can't access file: #{e.path}")
        :error

      e in OptionParser.ParseError ->
        IO.puts(e.message)
        :error

      _e in Poison.ParseError ->
        IO.puts("Can't parse multi JSON")
        :error

      e in RuntimeError ->
        IO.puts(e.message)
        :error
    end
  end

  defp print_help() do
    IO.puts("""
    ogn_sim args:
    --help,  -h: print help,
    --port,  -p: APRS server listen TCP port, default: #{@def_aprs_server_port},
    --name,  -n: APRS server name, default: #{@def_aprs_server_name},
    --objs,  -o: number of simulated OGN objects, default: 0,
    --file,  -f: simulate traffic from selected APRS log file,
    --multi, -m: multipy traffic from --file using provided JSON schema,
    --log,   -l: log output to provided file,
    --rate,  -r: show packet rates.
    """)
  end

  defp print_cmd_help() do
    IO.puts("""
    ogn_sim commands:
    h: help,
    q: quit program,
    c: APRS clients list,
    r: toggle packet rate display.
    """)
  end

  def run(config) do
    :ets.new(:ogn_sim_rates, [:set, :public, :named_table])
    :ets.insert(:ogn_sim_rates, {:pkt_counter, 0})
    :ets.insert(:ogn_sim_rates, {:pkt_len_counter, 0})
    :ets.insert(:ogn_sim_rates, {:show, config.rate})

    IO.puts("OGN APRS traffic simulator.")

    OGNSim.APRSServer.start(config.port, config.name)
    OGNSim.ObjectTimer.start()

    if config.objs > 0 do
      IO.puts("Starting #{config.objs} object(s)")
      for obj_id <- 1..config.objs, do: OGNSim.Object.start(obj_id)
    end

    if config.file != nil do
      IO.puts("Starting #{config.file} file")
      {:ok, log_reader} = APRSLog.Reader.start_link(config.file)
      {:ok, log_buffer} = APRSLog.Buffer.start_link()
      {:ok, log_multi} = APRSLog.Multi.start_link(config.multi)
      {:ok, log_sender} = APRSLog.Sender.start_link(config.log)
      GenStage.sync_subscribe(log_buffer, to: log_reader)
      GenStage.sync_subscribe(log_multi, to: log_buffer)
      GenStage.sync_subscribe(log_sender, to: log_multi)
    end

    :timer.apply_interval(1000, OgnSim, :handle_rate, [])
    IO.puts("Enter h - for help")
    command_loop()
  end

  defp command_loop() do
    case IO.gets("Enter command: ") |> String.trim("\n") do
      "q" ->
        :ok

      "h" ->
        print_cmd_help()
        command_loop()

      "c" ->
        print_connections()
        command_loop()

      "r" ->
        toggle_rate_show()
        command_loop()

      cmd ->
        IO.puts("Not recognized command: #{cmd}")
        command_loop()
    end
  end

  defp print_connections() do
    conns =
      Registry.select(Registry.ConnectionsTCP, [
        {{:"$1", :"$2", :"$3"}, [], [:"$3"]}
      ])

    if conns == [] do
      IO.puts("No APRS client connections.")
    else
      IO.puts("APRS client(s):")

      Enum.map(conns, fn {client_id, client_ip} ->
        IO.puts("id: #{client_id}, IP: #{client_ip}")
      end)
    end
  end

  defp toggle_rate_show() do
    case :ets.lookup(:ogn_sim_rates, :show) do
      [show: false] ->
        IO.puts("Rate show enabled.")
        :ets.insert(:ogn_sim_rates, {:show, true})

      [show: true] ->
        IO.puts("Rate show disabled.")
        :ets.insert(:ogn_sim_rates, {:show, false})
    end
  end

  def handle_rate() do
    [pkt_counter: pkt_counter] = :ets.lookup(:ogn_sim_rates, :pkt_counter)
    [pkt_len_counter: pkt_len_counter] = :ets.lookup(:ogn_sim_rates, :pkt_len_counter)
    :ets.insert(:ogn_sim_rates, {:pkt_counter, 0})
    :ets.insert(:ogn_sim_rates, {:pkt_len_counter, 0})

    if :ets.lookup(:ogn_sim_rates, :show) == [show: true] do
      IO.puts("Rate: pkts/sec: #{pkt_counter}, \tpkt_bytes/sec: #{pkt_len_counter}")
    end
  end
end

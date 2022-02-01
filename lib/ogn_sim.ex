defmodule OgnSim do
  @def_aprs_server_port 10152
  @def_aprs_server_name "OGNSIM"

  def parse_args(argv) do
    try do
      {opt_list, _arg_list} =
        OptionParser.parse!(argv,
          strict: [help: :boolean, port: :integer, name: :string, objs: :integer, file: :string],
          aliases: [h: :help, p: :port, n: :name, o: :objs, f: :file]
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

        {:ok, %{port: port, name: name, objs: objs, file: file}}
      end
    rescue
      e in OptionParser.ParseError ->
        IO.puts(e.message)
        :error

      e in RuntimeError ->
        IO.puts(e.message)
        :error
    end
  end

  defp print_help() do
    IO.puts("""
    ogn_sim args:
    --help, -h: print help,
    --port, -p: APRS server listen TCP port, default: #{@def_aprs_server_port},
    --name, -n: APRS server name, default: #{@def_aprs_server_name},
    --objs, -o: number of simulated OGN objects, default: 0,
    --file, -f: simulate traffic from selected APRS log file.
    """)
  end

  defp print_cmd_help() do
    IO.puts("""
    ogn_sim commands:
    h: help,
    q: quit program,
    c: APRS clients list
    """)
  end

  def run(config) do
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
      {:ok, log_sender} = APRSLog.Sender.start_link("debug.txt")
      GenStage.sync_subscribe(log_buffer, to: log_reader)
      GenStage.sync_subscribe(log_sender, to: log_buffer)
    end

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

      cmd ->
        IO.puts("Not recognized command: #{cmd}")
        command_loop()
    end
  end

  defp print_connections() do
    conns =
      Registry.select(Registry.ConnectionsTCP, [
        {{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$2", :"$3"}}]}
      ])

    IO.inspect(conns)
  end
end
defmodule APRSLog.Sender do
  use GenStage

  @max_demand 10
  @tick_time_ms 1000

  def start_link(log_file_name) do
    log_file =
      if log_file_name != nil do
        {:ok, file} = File.open(log_file_name, [:write])
        file
      else
        nil
      end

    GenStage.start_link(__MODULE__, [log_file], name: __MODULE__)
  end

  def init([log_file]) do
    :timer.send_interval(@tick_time_ms, :tick)
    {:consumer, %{data: [], subscription: nil, log_file: log_file}}
  end

  def handle_subscribe(:producer, _options, from, state) do
    {:manual, %{state | subscription: from}}
  end

  def handle_events(events, _from, state) do
    {:noreply, [], %{state | data: state.data ++ events}}
  end

  def handle_info(:tick, state) when length(state.data) == 0 do
    if state.subscription != nil, do: GenStage.ask(state.subscription, @max_demand)
    {:noreply, [], state}
  end

  def handle_info(:tick, state) do
    [event | rest] = state.data
    #    IO.inspect("Rate: #{length(event)}")

    for e <- event do
      case e do
        :eof ->
          IO.puts("End of file.")

          if state.log_file != nil, do: File.close(state.log_file)

        line ->
          aprs_line = {:aprs, line <> "\r\n"}
          if state.log_file != nil, do: IO.write(state.log_file, line <> "\r\n")

          Registry.dispatch(Registry.ConnectionsTCP, "conns", fn entries ->
            for {pid, _} <- entries, do: send(pid, aprs_line)
          end)
      end
    end

    if length(rest) <= div(@max_demand, 2),
      do: GenStage.ask(state.subscription, div(@max_demand, 2))

    {:noreply, [], %{state | data: rest}}
  end
end

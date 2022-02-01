defmodule APRSLog.Sender do
  use GenStage

  @max_demand 10
  @tick_time_ms 1000

  def start_link(out_file) do
    {:ok, file} = File.open(out_file, [:write])
    GenStage.start_link(__MODULE__, [file], name: __MODULE__)
  end

  def init([file]) do
    :timer.send_interval(@tick_time_ms, :tick)
    {:consumer, %{data: [], subscription: nil, file: file}}
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
    # IO.inspect("Rate: #{length(event)}")

    for e <- event do
      case e do
        :eof ->
          IO.puts("End of file.")
          File.close(state.file)

        line ->
          aprs_line = {:aprs, line <> "\r\n"}

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

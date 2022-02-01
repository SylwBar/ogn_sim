defmodule APRSLog.Buffer do
  use GenStage
  @validity_window_sec 15

  def start_link() do
    GenStage.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_), do: {:producer_consumer, %{buff_time: nil, buff_lines: []}}

  def handle_events(lines, _from, state) do
    # IO.puts("APRSLog.Buffer: lines #{length(lines)}")
    {buff_time, buff_lines, events} = process(lines, state.buff_time, state.buff_lines)
    {:noreply, events, %{state | buff_time: buff_time, buff_lines: buff_lines}}
  end

  # process(lines, buff_time, buff_lines)
  # * input:
  # lines - list of lines to process
  # buff_time - current buffer time
  # buff_lines - current buffer time lines
  # list of events to be returned
  # * output:
  # buff_time,
  # buff_lines - TBD
  # events

  defp process(lines, buff_time, buff_lines), do: process(lines, buff_time, buff_lines, [])

  # processing start - buffer time nil
  defp process([{:ok, time, line} | rest], nil, [], out_events) do
    process(rest, time, [line], out_events)
  end

  # processing in the middle - received line matching current buffer time
  defp process([{:ok, time, line} | rest], buff_time, buff_lines, out_events)
       when time <= buff_time do
    process(rest, buff_time, buff_lines ++ [line], out_events)
  end

  # processing in the middle - received line ahead of validity window
  defp process([{:ok, time, line} | rest], buff_time, buff_lines, out_events)
       when time - buff_time >= @validity_window_sec do
    process(rest, buff_time, buff_lines ++ [line], out_events)
  end

  # processing in the middle - received line time ahead of current buffer time
  defp process([{:ok, time, line} | rest], buff_time, buff_lines, out_events) do
    empty_events_num = time - buff_time - 1
    empty_events = List.duplicate([], empty_events_num)
    process(rest, time, [line], out_events ++ [buff_lines] ++ empty_events)
  end

  # processing special events: APRS comment
  defp process([{:comment, _line} | rest], buff_time, buff_lines, out_events) do
    # Ignore comments
    process(rest, buff_time, buff_lines, out_events)
  end

  # processing special events: APRS errors
  defp process([{:error, line} | rest], buff_time, buff_lines, out_events) do
    # Add to buffer at current time
    process(rest, buff_time, buff_lines ++ [line], out_events)
  end

  # processing special events: end of file
  defp process([:eof | []], buff_time, buff_lines, out_events) do
    {buff_time, [], out_events ++ [buff_lines ++ [:eof]]}
  end

  # processing finish.
  defp process([], buff_time, buff_lines, out_events) do
    {buff_time, buff_lines, out_events}
  end
end

defmodule APRSLog.Reader do
  use GenStage

  def start_link(file_name) do
    case File.open(file_name, [:read, :compressed]) do
      {:ok, file} ->
        GenStage.start_link(__MODULE__, [file], name: __MODULE__)

      {:error, reason} ->
        IO.puts("Can't open file #{file_name}: #{reason}")
        System.halt(0)
        {:error, reason}
    end
  end

  def init([file]), do: {:producer, %{file: file}}

  def handle_demand(demand, state) do
    lines = read_lines(demand, state.file)
    {:noreply, lines, state}
  end

  defp read_lines(lines_num, file), do: read_lines(lines_num, file, [])

  defp read_lines(0, _file, out_lines), do: out_lines

  defp read_lines(n, file, out_lines) do
    case IO.gets(file, "") do
      :eof ->
        out_lines ++ [:eof]

      line ->
        trim_line = trim_endl(line)

        param_line =
          case APRS.get_params(trim_line) do
            {:ok, params, rest} ->
              case params.type do
                "/" ->
                  case APRS.get_aprs_position(rest) do
                    {:ok, {lat, lon, s1}, pos_rest} ->
                      {:ok, Map.merge(params, %{lat: lat, lon: lon, s1: s1, rest: pos_rest}),
                       trim_line}

                    _ ->
                      {:error, trim_line}
                      # {:ok, Map.put(params, :rest, rest), trim_line}
                  end

                _ ->
                  {:ok, Map.put(params, :rest, rest), trim_line}
              end

            :comment ->
              {:comment, trim_line}

            :error ->
              {:error, trim_line}
          end

        read_lines(n - 1, file, out_lines ++ [param_line])
    end
  end

  defp trim_endl(line), do: String.trim_trailing(line, "\n")
end

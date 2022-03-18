defmodule APRSLog.Multi do
  use GenStage

  @lat_scale 6000
  @lon_scale 6000

  def start_link(multi_opts) do
    GenStage.start_link(__MODULE__, [multi_opts], name: __MODULE__)
  end

  def init([stream_list]) do
    {:producer_consumer, stream_list}
  end

  def handle_events(param_line_events, _from, nil) do
    lines = Enum.map(param_line_events, &copy_param_line_list(&1))
    {:noreply, lines, nil}
  end

  def handle_events(param_line_events, _from, stream_list) do
    lines = Enum.map(param_line_events, &multiply_param_line_list(&1, stream_list))
    {:noreply, lines, stream_list}
  end

  defp copy_param_line_list(param_line_list) do
    Enum.map(param_line_list, &copy_param_line(&1))
  end

  defp copy_param_line({:ok, _param, line}), do: line
  defp copy_param_line(:eof), do: :eof

  defp multiply_param_line_list(param_line_list, stream_list) do
    Enum.map(param_line_list, &multiply_param_line(&1, stream_list)) |> :lists.flatten()
  end

  defp multiply_param_line({:ok, param, line}, stream_list) do
    Enum.map(stream_list, &generate_stream(&1, param, line))
  end

  defp multiply_param_line(:eof, _stream_list), do: :eof

  defp generate_stream(stream, param, _line) do
    stream_id = Map.get(stream, "id")
    stream_lat_off = Map.get(stream, "lat_off")
    stream_lon_off = Map.get(stream, "lon_off")
    new_aprs_id = aprs_id_map(param.aprs_id, stream_id)
    new_path = Enum.map(param.path, &aprs_id_map(&1, stream_id)) |> Enum.join(",")
    new_dest_id = aprs_id_map(param.dest_id, stream_id)
    time_str = APRS.sec_to_aprs_time_str(param.time)

    address_part =
      new_aprs_id <>
        param.status <> new_path <> "," <> new_dest_id <> ":" <> param.type <> time_str

    case param.type do
      "/" ->
        new_lat = (param.lat + round(stream_lat_off * @lat_scale)) |> unwrap_lat()
        new_lon = (param.lon + round(stream_lon_off * @lon_scale)) |> unwrap_lon()
        lat_str = APRS.lat_to_aprs_lat_str(new_lat)
        lon_str = APRS.lon_to_aprs_lon_str(new_lon)
        address_part <> lat_str <> <<param.s1>> <> lon_str <> param.rest

      _ ->
        address_part <> param.rest
    end
  end

  defp unwrap_lat(lat) when lat > 90 * @lat_scale, do: 90 * @lat_scale
  defp unwrap_lat(lat) when lat < -90 * @lat_scale, do: -90 * @lat_scale
  defp unwrap_lat(lat), do: lat

  defp unwrap_lon(lon) when lon > 180 * @lon_scale, do: unwrap_lon(lon - 360 * @lon_scale)
  defp unwrap_lon(lon) when lon < -180 * @lon_scale, do: unwrap_lon(lon + 360 * @lon_scale)
  defp unwrap_lon(lon), do: lon

  defp aprs_id_map(<<"GLIDERN", _::bytes>> = id, _stream_id), do: id
  defp aprs_id_map("OGNSDR" = id, _stream_id), do: id
  defp aprs_id_map("OGNTRK" = id, _stream_id), do: id
  defp aprs_id_map("APRS" = id, _stream_id), do: id
  defp aprs_id_map("TCPIP*" = id, _stream_id), do: id
  defp aprs_id_map("qAC" = id, _stream_id), do: id
  defp aprs_id_map("qAS" = id, _stream_id), do: id
  defp aprs_id_map(aprs_id, _stream_id), do: aprs_id
end

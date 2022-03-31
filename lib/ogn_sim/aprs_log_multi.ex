defmodule APRSLog.Multi do
  use GenStage

  @lat_scale 6000
  @lon_scale 6000

  def start_link(multi_opts) do
    GenStage.start_link(__MODULE__, [multi_opts], name: __MODULE__)
  end

  def init([stream_list]) do
    :ets.new(:ogn_id_map, [:set, :protected, :named_table])
    :ets.insert(:ogn_id_map, {:counter, 0})
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
    stream_id =
      case Map.get(stream, "id", nil) do
        nil -> nil
        id when is_integer(id) -> Integer.to_string(id, 16)
      end

    stream_lat_off = Map.get(stream, "lat_offset", 0)
    stream_lon_off = Map.get(stream, "lon_offset", 0)
    {new_aprs_id, ogn_id_map} = aprs_id_map(param.aprs_id, stream_id)
    new_path = Enum.map(param.path, &aprs_path_map(&1, stream_id)) |> Enum.join(",")
    new_dest_id = aprs_dest_map(param.dest_id, stream_id)
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

        new_rest =
          case ogn_id_map do
            nil -> param.rest
            {ogn_id, map_id} -> String.replace(param.rest, ogn_id, map_id)
          end

        address_part <> lat_str <> <<param.s1>> <> lon_str <> new_rest

      _ ->
        address_part <> param.rest
    end
  end

  defp unwrap_lat(lat) when lat > 90 * @lat_scale, do: unwrap_lat(180 * @lat_scale - lat)
  defp unwrap_lat(lat) when lat < -90 * @lat_scale, do: unwrap_lat(-180 * @lat_scale - lat)
  defp unwrap_lat(lat), do: lat

  defp unwrap_lon(lon) when lon > 180 * @lon_scale, do: unwrap_lon(lon - 360 * @lon_scale)
  defp unwrap_lon(lon) when lon < -180 * @lon_scale, do: unwrap_lon(lon + 360 * @lon_scale)
  defp unwrap_lon(lon), do: lon

  defp get_ogn_id_map_stream(ogn_id, stream_id) do
    get_ogn_id_map(ogn_id) <> stream_id
  end

  defp get_ogn_id_map(ogn_id) do
    case :ets.lookup(:ogn_id_map, ogn_id) do
      [{_ogn_id, map_id}] ->
        map_id

      [] ->
        new_id =
          :ets.update_counter(:ogn_id_map, :counter, {2, 1})
          |> Integer.to_string(16)
          |> String.pad_leading(5, "0")

        :ets.insert(:ogn_id_map, {ogn_id, new_id})
        new_id
    end
  end

  defp aprs_id_map(aprs_id, nil), do: {aprs_id, nil}

  defp aprs_id_map(<<"FLR", ogn_id::bytes-size(6)>>, stream_id),
    do: aprs_id_map2("FLR", ogn_id, stream_id)

  defp aprs_id_map(<<"ICA", ogn_id::bytes-size(6)>>, stream_id),
    do: aprs_id_map2("ICA", ogn_id, stream_id)

  defp aprs_id_map(<<"OGN", ogn_id::bytes-size(6)>>, stream_id),
    do: aprs_id_map2("OGN", ogn_id, stream_id)

  defp aprs_id_map(<<"PAW", ogn_id::bytes-size(6)>>, stream_id),
    do: aprs_id_map2("PAW", ogn_id, stream_id)

  defp aprs_id_map(<<"SKY", ogn_id::bytes-size(6)>>, stream_id),
    do: aprs_id_map2("SKY", ogn_id, stream_id)

  defp aprs_id_map(<<"FMT", ogn_id::bytes-size(6)>>, stream_id),
    do: aprs_id_map2("FMT", ogn_id, stream_id)

  defp aprs_id_map(aprs_id, stream_id), do: {aprs_id <> stream_id, nil}

  def aprs_id_map2(ogn_id_prefix, ogn_id, stream_id) do
    map_stream_id = get_ogn_id_map_stream(ogn_id, stream_id)
    {ogn_id_prefix <> map_stream_id, {ogn_id, map_stream_id}}
  end

  defp aprs_path_map(aprs_id, _stream_id), do: aprs_id

  defp aprs_dest_map(aprs_id, nil), do: aprs_id
  defp aprs_dest_map(<<"GLIDERN", _::bytes>> = aprs_id, _stream_id), do: aprs_id
  defp aprs_dest_map(<<"SafeSky", _::bytes>> = aprs_id, _stream_id), do: aprs_id
  defp aprs_dest_map(<<"NAVITER", _::bytes>> = aprs_id, _stream_id), do: aprs_id
  defp aprs_dest_map(<<"FLYMASTER", _::bytes>> = aprs_id, _stream_id), do: aprs_id
  defp aprs_dest_map(aprs_id, stream_id), do: aprs_id <> stream_id
end

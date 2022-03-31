defmodule APRS do
  import NimbleParsec

  # -------- APRS address header with time --------
  aprs_id = ascii_string([?A..?Z, ?a..?z, ?0..?9, ?-, ?*], min: 1)
  status = string(">")
  sep = string(",")
  msg = string(":")
  type = choice([string("/"), string(">")])

  path_elem = aprs_id |> ignore(sep)

  time = integer(2) |> integer(2) |> integer(2) |> ignore(string("h"))

  # parse APRS address: examples:
  # EPKA>OGNSDR,TCPIP*,qAC,GLIDERN1:
  # FLR123456>OGFLR,qAS,EPKA:

  defparsec(
    :ps_aprs_addr_time,
    aprs_id
    |> concat(status)
    |> tag(times(path_elem, min: 2), :path)
    |> concat(aprs_id)
    |> ignore(msg)
    |> concat(type)
    |> concat(time),
    debug: false
  )

  def get_params(<<"#", _::bytes>>), do: :comment

  def get_params(aprs_packet) do
    case ps_aprs_addr_time(aprs_packet) do
      {:ok, [aprs_id, status, {:path, path}, dest_id, type, h, m, s], rest, _context, _position,
       _byte_offset} ->
        {:ok,
         %{
           aprs_id: aprs_id,
           status: status,
           path: path,
           dest_id: dest_id,
           type: type,
           time: h * 3600 + m * 60 + s
         }, rest}

      {:error, _reason, _rest, _context, _position, _byte_offset} ->
        :error
    end
  end

  # -------- APRS position  --------
  # "1234.56NI12345.67E"

  latitude =
    integer(2)
    |> integer(2)
    |> ignore(string("."))
    |> integer(2)
    |> choice([string("N"), string("S")])

  longitude =
    integer(3)
    |> integer(2)
    |> ignore(string("."))
    |> integer(2)
    |> choice([string("E"), string("W")])

  # APRS101.pdf page 91
  # Symbol Table Identifier
  symbol1 = ascii_char([0..255])

  # position with timestamp
  defparsec(
    :aprs_position,
    latitude
    |> concat(symbol1)
    |> concat(longitude),
    debug: false
  )

  def get_aprs_position(aprs_packet) do
    case aprs_position(aprs_packet) do
      {:ok,
       [
         lat_deg,
         lat_min,
         lat_min_d100,
         lat_n_s,
         s1,
         lon_deg,
         lon_min,
         lon_min_d100,
         lon_e_w
       ], rest, _context, _position, _byte_offset} ->
        abs_lat = lat_min_d100 + lat_min * 100 + lat_deg * 6000
        abs_lon = lon_min_d100 + lon_min * 100 + lon_deg * 6000

        lat =
          case lat_n_s do
            "N" -> abs_lat
            "S" -> -abs_lat
          end

        lon =
          case lon_e_w do
            "E" -> abs_lon
            "W" -> -abs_lon
          end

        {:ok, {lat, lon, s1}, rest}

      {:error, _reason, _rest, _context, _position, _byte_offset} ->
        :error
    end
  end

  def sec_to_aprs_time_str(secs) do
    h_str = div(secs, 3600) |> Integer.to_string() |> String.pad_leading(2, "0")
    ms = rem(secs, 3600)
    m_str = div(ms, 60) |> Integer.to_string() |> String.pad_leading(2, "0")
    s_str = rem(ms, 60) |> Integer.to_string() |> String.pad_leading(2, "0")
    h_str <> m_str <> s_str <> "h"
  end

  def lat_to_aprs_lat_str(lat) do
    abs_lat = abs(lat)
    deg_str = div(abs_lat, 6000) |> Integer.to_string() |> String.pad_leading(2, "0")
    mins = rem(abs_lat, 6000)
    min_str = div(mins, 100) |> Integer.to_string() |> String.pad_leading(2, "0")
    min_d100_str = rem(mins, 100) |> Integer.to_string() |> String.pad_leading(2, "0")

    hemi_str =
      if lat >= 0 do
        "N"
      else
        "S"
      end

    deg_str <> min_str <> "." <> min_d100_str <> hemi_str
  end

  def lon_to_aprs_lon_str(lon) do
    abs_lon = abs(lon)
    deg_str = div(abs_lon, 6000) |> Integer.to_string() |> String.pad_leading(3, "0")
    mins = rem(abs_lon, 6000)
    min_str = div(mins, 100) |> Integer.to_string() |> String.pad_leading(2, "0")
    min_d100_str = rem(mins, 100) |> Integer.to_string() |> String.pad_leading(2, "0")

    hemi_str =
      if lon >= 0 do
        "E"
      else
        "W"
      end

    deg_str <> min_str <> "." <> min_d100_str <> hemi_str
  end
end

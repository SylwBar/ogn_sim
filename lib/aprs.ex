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
    ignore(aprs_id)
    |> ignore(status)
    |> ignore(times(path_elem, min: 2))
    |> ignore(aprs_id)
    |> ignore(msg)
    |> ignore(type)
    |> concat(time),
    debug: false
  )

  def get_time(<<"#", _::bytes>>), do: :comment

  def get_time(aprs_packet) do
    case ps_aprs_addr_time(aprs_packet) do
      {:ok, [h, m, s], _rest, _context, _position, _byte_offset} ->
        {:ok, h * 3600 + m * 60 + s}

      {:error, _reason, _rest, _context, _position, _byte_offset} ->
        :error
    end
  end
end

defmodule OGNSim.ObjectTimer do
  use GenServer

  @impl true
  def init([]) do
    {:ok, tref} = :timer.send_interval(1000, :sec_timer)
    {:ok, %{tref: tref}}
  end

  @impl true
  def handle_info(:sec_timer, state) do
    Registry.dispatch(Registry.Objects, "objects", fn entries ->
      for {pid, _} <- entries, do: send(pid, :send_packet)
    end)

    {:noreply, state}
  end

  # -----------------------------

  def start() do
    GenServer.start(__MODULE__, [])
  end
end

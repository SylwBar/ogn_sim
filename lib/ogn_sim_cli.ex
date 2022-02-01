defmodule OGNSim.CLI do
  def main(argv) do
    case OgnSim.parse_args(argv) do
      {:ok, config} -> OgnSim.run(config)
      :help -> :ok
      :error -> :error
    end
  end
end

defmodule Replica do

  def start(config, database, monitor) do
    receive do
      { :bind, leaders } ->
        %{
          leaders: leaders,
          slot_in: 0,
          slot_out: 0,
          requests: [],
          proposals: [],
          decisions: []
        }
        |> next(config, database, monitor)
    end
  end

  def next(state, config, database, monitor) do
    receive do
      { :client_request, cmd } -> propose(cmd, state, config, database)
    end
  end

  defp propose(cmd, state, config, database) do
    
  end

end

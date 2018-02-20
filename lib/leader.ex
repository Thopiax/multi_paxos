# Rafael Toletti Ballestiero (rb2215) and Norbert Podsadowski (np1815)

defmodule Leader do
  def start(config) do
    receive do
      { :bind, acceptors, replicas } ->
        pn = {0, self()}

        spawn Scout, :start, [config, self(), acceptors, pn]

        %{
          acceptors: acceptors,
          replicas: replicas,
          active: false,
          pn: pn
        }
        |> next(config, MapSet.new())
    end
  end

  def next(state, config, proposals) do
    receive do
      { :propose, sn, c } ->
        if pair_in_set(proposals, sn) do
          if state.active do
            spawn Commander, :start, [config, self(), state.acceptors, state.replicas, { state.pn, sn, c}]
          end
          
          next(state, config, MapSet.put(proposals, {sn, c}))
        end
    end
  end

  defp pair_in_set(set, key) do
    set
    |> MapSet.to_list
    |> Map.new
    |> Map.get(key) != nil
  end

end

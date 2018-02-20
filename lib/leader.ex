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
          if state.active, do: spawn_commander(state, config, state.pn, sn, c)
          next(state, config, MapSet.put(proposals, {sn, c}))
        end

      { :adopted, pn, pvals } ->
        new_proposals = update_sets(proposals, pmax(pvals))

        Enum.each(new_proposals, fn ({sn, c}) ->
          spawn Commander, :start, [config, self(), state.acceptors, state.replicas, { pn, sn, c}]
        end)

        state
        |> Map.put(:active, true)
        |> next(config, new_proposals)

      { :preempted, pn = {r, _l} } ->
        # i.e. data > state.pn
        if Util.max(pn, state.pn) == pn do
          state
          |> Map.put(:active, false)
          |> Map.put(:pn, {r + 1, self()})
          |> spawn_scout(config)
          |> next(config, proposals)
        end
    end
  end

  # Spawns a Scout and returns the given state
  defp spawn_scout(state, config) do
    spawn Scout, :start, [config, self(), state.acceptors, state.pn]

    state
  end

  defp spawn_commander(state, config, pn, sn, c) do
    spawn Commander, :start, [config, self(), state.acceptors, state.replicas, {pn, sn, c}]

    state
  end

  def handle_adoption(state, config, proposals, pn, pvals) do

  end

  def pmax(pvals), do: calculate_pmax(pvals, %{})

  def update_sets(x, y) do
    y_map = Map.new(y)
    for {s, c} <- x, into: y_map do
      {s, y_map[s] || c}
    end
    |> Map.to_list
  end

  defp calculate_pmax([], result) do
    result
    |> Enum.map(fn ({sn, {_pn, c}}) -> {sn, c} end)
  end
  defp calculate_pmax([{pn, sn, c} | pvals], new_vals) do
    result =
      with { res_pn, _res_c } <- new_vals[sn]
      do
        (if res_pn < pn, do: Map.put(new_vals, sn, {pn, c}), else: new_vals)
      else
        nil -> Map.put(new_vals, sn, {pn, c})
      end
    calculate_pmax(pvals, result)
  end

  defp pair_in_set(set, key) do
    set
    |> MapSet.to_list
    |> Map.new
    |> Map.get(key) != nil
  end

end

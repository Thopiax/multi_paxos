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
        # Util.inspect(config, "PROPOSE: slot number #{inspect(sn)} and c = #{inspect(c)}")
        unless Util.key_in_set?(proposals, sn) do
          if state.active do
            spawn_commander(state, config, state.pn, sn, c)
          end
        end
        next(state, config, MapSet.put(proposals, {sn, c}))

      { :adopted, pn, pvals } ->
        Util.inspect(config, "ADOPTED: proposal for pn = #{inspect(pn)} and pvals = #{inspect(pvals)}")
        new_proposals = update_sets(proposals, pmax(pvals))

        Enum.each(new_proposals, fn ({sn, c}) -> spawn_commander(state, config, pn, sn, c) end)

        state
        |> Map.put(:active, true)
        |> next(config, new_proposals)

      { :preempted, pn = {r, _l} } ->
        # Util.inspect(config, "PREEMPTED: PN = #{inspect(pn)}, NEW_PN = #{inspect {r + 1, self()}}")
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
    # Util.inspect(config, "SPAWN: SCOUT with PN=#{inspect state.pn})")
    spawn Scout, :start, [config, self(), state.acceptors, state.pn]

    state
  end

  defp spawn_commander(state, config, pn, sn, c) do
    # Util.inspect(config, "SPAWN: COMMANDER with PN=#{inspect state.pn}, SN=#{sn} and C=#{inspect c}")
    spawn Commander, :start, [config, self(), state.acceptors, state.replicas, {pn, sn, c}]

    state
  end

  def pmax(pvals), do: calculate_pmax(MapSet.to_list(pvals), %{})

  def update_sets(x, y) do
    y_map = Map.new(y)
    for {s, c} <- x, into: y_map do
      {s, y_map[s] || c}
    end
    |> MapSet.new
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
end

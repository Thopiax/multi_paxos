# Rafael Toletti Ballestiero (rb2215) and Norbert Podsadowski (np1815)

defmodule Replica do
  @window 10000

  def start(config, database, monitor) do
    receive do
      { :bind, leaders } ->
        %{
          leaders: leaders,
          slot_in: 1,
          slot_out: 1,
          database: database,
          monitor: monitor
        }
        |> next(config, MapSet.new, MapSet.new, MapSet.new)
    end
  end

  def next(state, config, requests, proposals, decisions) do
    receive do
      { :client_request, cmd } ->
        new_reqs = MapSet.put(requests, cmd)
        send state.monitor, { :client_request, config.server_num }

        propose(state, config, new_reqs, proposals, decisions)
      { :decision, sn, cmd } ->
        # Util.inspect(config, "DECISION: SN=#{sn} with CMD=#{inspect(cmd)}")
        new_decs = MapSet.put(decisions, {sn, cmd})

        state
        |> handle_decision(config, requests, proposals, new_decs)
        |> propose(config, requests, proposals, new_decs)
    end
  end

  defp perform_decision(state, config, c, requests, proposals, decisions) do
    state
    |> perform(config, c, decisions)
    |> handle_decision(config, requests, proposals, decisions)
  end

  defp handle_decision(state = %{slot_out: slot_out}, config, requests, proposals, decisions) do
    with true     <- Util.key_in_set?(decisions, slot_out),
         {_s, c1} <- Util.fetch_tuple(decisions, slot_out),
         {_s, c2} <- Util.fetch_tuple(proposals, slot_out)
    do
      props = MapSet.delete(proposals, {slot_out, c2})
      reqs  = (if c1 != c2, do: MapSet.put(requests, c2), else: requests)

      perform_decision(state, config, c1, reqs, props, decisions)
    else
      nil ->
        # i.e. there is no c2 in proposals
        {_s, c} = Util.fetch_tuple(decisions, slot_out)
        perform_decision(state, config, c, requests, proposals, decisions)
      false ->
        # i.e. no slot_out decision in decisions
        state
    end
  end

  def propose(state = %{slot_in: slot_in, slot_out: slot_out},
               config,
               requests,
               proposals,
               decisions) when slot_in < (slot_out + @window) do
    if Enum.empty?(requests) do
      next(state, config, requests, proposals, decisions)
    else
      c = Enum.at(requests, 0)
      rest = MapSet.delete(requests, c)

      {new_reqs, new_props} =
        if Util.key_in_set?(decisions, slot_in) do
          {requests, proposals}
        else
          for leader <- state.leaders, do: send leader, { :propose, state.slot_in, c }
          {rest, MapSet.put(proposals, {state.slot_in, c})}
        end

      state
      |> Map.put(:slot_in, slot_in + 1)
      |> propose(config, new_reqs, new_props, decisions)
    end
  end
  def propose(state, config, requests, proposals, decisions) do
    next(state, config, requests, proposals, decisions)
  end

  def perform(state, _config, cmd = { cl, cid, op }, decisions) do
    # check if there aren't any elements in decisions with the same command and a lower slot_out
    unless Enum.any?(decisions, fn ({s, c}) -> (s < state.slot_out and c == cmd) end) do
      send state.database, { :execute, op }
      send cl,             { :reply, cid, nil}
    end
    state
    |> Map.put(:slot_out, state.slot_out + 1)
  end
end

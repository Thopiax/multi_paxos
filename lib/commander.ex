# Rafael Toletti Ballestiero (rb2215) and Norbert Podsadowski (np1815)

defmodule Commander do
  def start(config, leader, acceptors, replicas, data = {pn, sn, c}) do
    for ac <- acceptors do
      send ac, { :p2a, self(), data }
    end
    %{
      leader: leader,
      acceptors: acceptors,
      replicas: replicas,
      pn: pn,
      sn: sn,
      c: c
    }
    |> next(config, MapSet.new(acceptors))
  end

  defp next(state, config, waitfor) do
    receive do
      { :p2b, ac, pn } ->
        Util.inspect(config, "Received [p2b] from A#{inspect(ac)}, PN = #{inspect pn}, STATE_PN = #{inspect state.pn} ")
        if pn == state.pn do
          new_waitfor = MapSet.delete(waitfor, ac)
          Util.inspect(config, "WAITFOR=#{inspect new_waitfor} and ACCEPTORS=#{inspect state.acceptors}")
          if MapSet.size(new_waitfor) < (length(state.acceptors) / 2) do
            # Util.inspect(config, "DECIDED: Commander <#{inspect state.pn}, #{state.sn}, #{inspect(state.c)}> for Leader #{inspect(state.leader)}")
            for r <- state.replicas, do: send r, { :decision, state.s, state.c }
            exit(0)
          end
        else
          Util.inspect(config, "PREEMPTED: PN = #{inspect(pn)}, STATE_PN = #{inspect state.pn}")
          Util.thread_preempt(state.leader, pn)
        end
    end
  end
end

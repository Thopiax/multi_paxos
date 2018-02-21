# Rafael Toletti Ballestiero (rb2215) and Norbert Podsadowski (np1815)

defmodule Scout do
  def start(config, leader, acceptors, pn) do
    for ac <- acceptors do
      send ac, { :p1a, self(), pn }
    end

    %{
      leader: leader,
      acceptors: acceptors,
      pn: pn
    }
    |> next(config, MapSet.new(acceptors), MapSet.new())
  end

  def next(state, config, waitfor, pvalues) do
    receive do
      { :p1b, ac, pn, vals } ->
        # Util.inspect(config, "Received [p1b] from STATE_PN = #{inspect state.pn} with PN #{inspect(pn)}")
        if pn == state.pn do
          # Update sets
          new_pvalues = MapSet.union(pvalues, vals)

          new_waitfor = MapSet.delete(waitfor, ac)
          # Util.inspect(config, "WAITFOR = #{inspect(new_waitfor)} and ACCEPTORS=#{inspect(state.acceptors)} and DIFF = #{MapSet.size(new_waitfor) < (length(state.acceptors) / 2)}")

          # Check if majority has responded
          if MapSet.size(new_waitfor) < (length(state.acceptors) / 2) do
            # Util.inspect(config, "SENDING ADOPTION to #{inspect(state.leader)}")
            send state.leader, { :adopted, pn, new_pvalues }
            exit(0)
          end
          # Loop back
          next(state, config, new_waitfor, new_pvalues)
        else
          # Util.inspect(config, "PREEMPTED: Scout PN=#{inspect(state.pn)} for Leader #{inspect(state.leader)}")
          Util.thread_preempt(state.leader, pn)
        end
    end
  end
end

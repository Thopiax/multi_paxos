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
    |> next(config, acceptors, MapSet.new())
  end

  def next(state, config, waitfor, pvalues) do
    receive do
      { :p1b, ac, pn, val } ->
        Util.inspect(config, "Received [p1b] from A\##{inspect(ac)} with PN #{inspect pn} and val #{val}")
        if pn == state.pn do
          # Update sets
          new_pvalues = MapSet.put(pvalues, val)
          new_waitfor = MapSet.delete(waitfor, ac)
          # Check if majority has responded
          if MapSet.size(new_waitfor) < (MapSet.size(state.acceptors) / 2) do
            send state.leader, { :adopted, pn, new_pvalues }
            exit(0)
          end
          # Loop back
          next(state, config, new_waitfor, new_pvalues)
        else
          Util.inspect(config, "PREEMPTED: Scout PN=#{inspect state.pn} for Leader #{inspect(state.leader)}")
          Util.thread_preempt(state.leader, pn)
        end
    end
  end
end

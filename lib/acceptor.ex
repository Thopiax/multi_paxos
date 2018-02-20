# Rafael Toletti Ballestiero (rb2215) and Norbert Podsadowski (np1815)

defmodule Acceptor do
  def start(config), do: next(-1, MapSet.new(), config)

  def next(pn, accepted, config) do
    receive do
      { :p1a, leader, r_pn } ->
        Util.inspect(config, "Received [p1a] from #{inspect(leader)} with ballot_number #{r_pn}")
        new_pn = Util.max(pn, r_pn)
        send leader, { :p1b, self(), new_pn, accepted }

        next(new_pn, accepted, config)
      { :p2a, leader, msg = { r_pn, _sn, _c }} ->
        Util.inspect(config, "Received [p2a] from #{inspect(leader)} with ballot_number #{r_pn}")

        if pn == r_pn, do: MapSet.put(accepted, msg)

        send leader, { :p2b, self(), pn }
        next(pn, accepted, config)
    end
  end
end

# Rafael Toletti Ballestiero (rb2215) and Norbert Podsadowski (np1815)

defmodule Acceptor do
  def start(config), do: next(-1, MapSet.new(), config)

  def next(ballot_num, accepted, config) do
    receive do
      { :p1a, leader, bn } ->
        Util.inspect(config, "Received [p1a] from #{leader} with ballot_number #{bn}")
        new_ballot_num = max(ballot_num, bn)
        send leader, { :p1b, self(), new_ballot_num, accepted }

        next(new_ballot_num, accepted, config)
      { :p2a, leader, msg = { bn, _sn, _c }} ->
        Util.inspect(config, "Received [p2a] from #{leader} with ballot_number #{bn}")

        if bn == ballot_num, do: MapSet.put(accepted, msg)

        send leader, { :p2b, self(), ballot_num }
        next(ballot_num, accepted, config)
    end
  end
end

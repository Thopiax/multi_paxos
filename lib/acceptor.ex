# Rafael Toletti Ballestiero (rb2215) and Norbert Podsadowski (np1815)

defmodule Acceptor do
  def start(config), do: next(nil, MapSet.new(), config)

  def next(pn, accepted, config) do
    receive do
      { :p1a, scout, r_pn } ->
        Util.inspect(config, "Received [p1a] R_PN=#{inspect(r_pn)} vs PN=#{inspect(pn)}")
        new_pn = (if Util.greater?(r_pn, pn), do: r_pn, else: pn)

        send scout, { :p1b, self(), new_pn, accepted }

        next(new_pn, accepted, config)
      { :p2a, commander, msg = { r_pn, _sn, _c }} ->
        # Util.inspect(config, "Received [p2a] R_PN=#{inspect(msg)} vs PN=#{inspect(pn)}")
        new_acc = (if pn == r_pn, do: MapSet.put(accepted, msg), else: accepted)

        send commander, { :p2b, self(), pn }
        next(pn, new_acc, config)
    end
  end
end

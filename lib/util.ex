# Rafael Toletti Ballestiero (rb2215) and Norbert Podsadowski (np1815)

defmodule Util do
  def inspect(%{debug_level: 0}, _msg), do: nil
  def inspect(%{debug_level: 1}, msg),  do: IO.puts "#{inspect(self())} -- #{inspect(msg)}"

  def thread_preempt(leader, pn) do
    send leader, { :preempted, pn }
    exit(0)
  end

  def max(a, nil), do: a
  def max(nil, b), do: b
  def max(a = {x1, y1}, b = {x2, y2}) do
    cond do
      x1 < x2    -> b
      x2 > x1    -> a
      :otherwise -> if y1 > y2, do: a, else: b
    end
  end

  def fetch_tuple(set, key) do
    Map.new(set)[key]
  end

  def key_in_set?(set, key) do
    set
    |> Map.new
    |> Map.get(key) != nil
  end
end

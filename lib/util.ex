# Rafael Toletti Ballestiero (rb2215) and Norbert Podsadowski (np1815)

defmodule Util do
  def inspect(%{debug_level: 0}, _msg), do: nil
  def inspect(%{debug_level: 1}, msg),  do: IO.puts "#{inspect(self())} -- #{inspect(msg)}"

  def thread_preempt(leader, pn) do
    send leader, { :preempted, pn }
    exit(0)
  end

  def max(a, b) do
    if greater?(a, b), do: a, else: b
  end

  def greater?(_a, nil), do: true
  def greater?(nil, _b), do: false
  def greater?({x1, y1}, {x2, y2}) do
    cond do
      x1 < x2    -> false
      x1 > x2    -> true
      :otherwise -> (if y1 > y2, do: true, else: false)
    end
  end

  def fetch_tuple(set, key) do
    case Map.new(set)[key] do
      nil -> nil
      val -> {key, val}
    end
  end

  def key_in_set?(set, key) do
    set
    |> Map.new
    |> Map.get(key) != nil
  end
end

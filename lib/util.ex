# Rafael Toletti Ballestiero (rb2215) and Norbert Podsadowski (np1815)

defmodule Util do
  def inspect(%{debug_level: 0}, _msg), do: nil
  def inspect(%{debug_level: 1}, msg),  do: IO.puts "#{inspect(self())} -- #{inspect(msg)}"
end

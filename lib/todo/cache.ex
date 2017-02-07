defmodule Todo.Cache do
  use GenServer

  def delete(list_name) when is_binary(list_name) do
    :ets.delete(__MODULE__, list)
  end

  def save(list) do
    :ets.insert(__MODULE__, {list.name, list})
  end

  def find(list_name) do
    case :ets.lookup(__MODULE__, list_name) do
      [{_id, value}] -> value
      [] -> nil
    end
  end

  # Based on http://stackoverflow.com/a/35125529/470451
  def list() do
    first_key = :ets.first(__MODULE__)
    list(first_key, [first_key])
  end

  def clear do
    :ets.delete_all_objects(__MODULE__)
  end

  ###
  # GenServer API
  ###

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    table = :ets.new(__MODULE__, [:named_table, :public])
    {:ok, table}
  end

  ## Private Functions

  defp list(:"$end_of_table", [:"$end_of_table" | acc]), do: acc
  defp list(current_key, acc) do
      next_key = :ets.next(__MODULE__, current_key)
      list(next_key, [next_key | acc])
  end
end

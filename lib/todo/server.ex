defmodule Todo.Server do
  alias Todo.{Cache, List}

  use Supervisor

  def add_list(name) do
    Supervisor.start_child(__MODULE__, [name])
  end

  def find_list(name) do
    Enum.find lists, fn(child) ->
      Todo.List.name(child) == name
    end
  end

  def delete_list(list_pid) when is_pid(list_pid) do
    list_name = List.name(list_pid)
    Supervisor.terminate_child(__MODULE__, list_pid)
    Cache.delete(list_name)
  end

  def lists do
    resurrect()
    alive()
  end

  ###
  # Supervisor API
  ###

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    children = [
      worker(List, [], restart: :transient)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end

  ## Private Functions

  defp alive do
    __MODULE__
    |> Supervisor.which_children
    |> Enum.map(fn({_, child, _, _}) -> child end)
  end

  defp alive_names, do: Enum.map(alive(), &List.name(&1))

  defp resurrect do
    alive_name_set = Enum.into(alive_names(), MapSet.new)
    full_name_set = Enum.into(Cache.list(), MapSet.new)

    dead_name_set = MapSet.difference(full_name_set, alive_name_set)

    Enum.each(dead_name_set, &add_list(&1))
  end
end

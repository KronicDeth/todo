defmodule Todo.ServerTest do
  use ExUnit.Case

  alias Todo.{Item, List, Server}

  setup do
    on_exit fn ->
      Enum.each Server.lists, fn(list) ->
        Server.delete_list(list)
      end
    end
  end

  test ".add_list adds a new supervised todo list" do
    Server.add_list("Home")
    Server.add_list("Work")

    counts = Supervisor.count_children(Server)

    assert counts.active == 2
  end

  test ".find_list gets a list by its name" do
    Server.add_list("find-by-name")
    list = Server.find_list("find-by-name")

    assert is_pid(list)
  end

  test ".delete_list deletes a list by its name" do
    Server.add_list("delete-me")
    list = Server.find_list("delete-me")

    Server.delete_list(list)
    counts = Supervisor.count_children(Server)

    assert counts.active == 0, "Cache.list = #{inspect Todo.Cache.list}"
  end

  test "killing the server does not lose any list data" do
    Server.add_list("resurrected")
    list_pid_before = Server.find_list("resurrected")
    List.add(list_pid_before, Item.new("Resurrect"))
    list_items_before = List.items(list_pid_before)

    before_server_pid = Process.whereis(Server)

    GenServer.stop(Server)

    Process.sleep 10

    after_server_pid = Process.whereis(Server)

    assert is_pid(after_server_pid)
    refute after_server_pid == before_server_pid

    list_pid_after = Server.find_list("resurrected")

    assert is_pid(list_pid_after)
    refute list_pid_after == list_pid_before

    list_items_after = List.items(list_pid_after)

    assert list_items_after == list_items_before
  end
end

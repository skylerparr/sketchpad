defmodule SketchpadWeb.PadChannelTest do 
  use SketchpadWeb.ChannelCase
  alias SketchpadWeb.PadChannel
  import Phoenix.Socket

  setup do 
    socket = assign(socket(), :user_id, "foobar")
    assert {:ok, _, socket} =
      subscribe_and_join(socket, PadChannel, "pad:lobby", %{})

    {:ok, socket: socket}
  end

  test "clear event is broadcat to everyone but self", %{socket: socket} do 
    ref = push socket, "clear", %{}
    assert_reply(ref, :ok)

    assert_broadcast "clear", %{}
  end

  test "message include publishing user", %{socket: socket} do 
    ref = push socket, "new_message", %{body: "hello!"}
    assert_reply ref, :ok
    assert_broadcast "new_message", %{
      body: "hello!",
      user_id: "foobar"
    }
  end
end

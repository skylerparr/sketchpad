defmodule SketchpadWeb.PadChannel do 
  use SketchpadWeb, :channel 

  alias Sketchpad.PadServer

  def broadcast_clear(topic, user_id) do 
    SketchpadWeb.Endpoint.broadcast!(topic, "clear", 
      %{
        user_id: user_id
      }
    )
  end

  def broadcast_stroke(topic, user_id, stroke) do
    SketchpadWeb.Endpoint.broadcast!(topic, "stroke", %{
      stroke: stroke,
      user_id: user_id
    })
  end

  def join("pad:" <> pad_id, _params, socket) do 
    {:ok, pid} = PadServer.find(pad_id)

    send(self(), :after_join)

    socket = 
      socket
      |> assign(:pad_id, pad_id)
      |> assign(:pad, pid)

    {:ok, %{}, socket}
  end

  def handle_in("stroke", stroke, socket) do 
    PadServer.put_stroke(socket.assigns.pad, socket.assigns.user_id, stroke)
    {:reply, :ok, socket}
  end

  def handle_in("clear", _data, socket) do 
    PadServer.clear(socket.assigns.pad, socket.assigns.user_id)
    {:reply, :ok, socket}
  end

  def handle_in("new_message", %{"body" => body}, socket) do 
    broadcast!(socket, "new_message", %{user_id: socket.assigns.user_id, body: body})
    {:reply, :ok, socket}
  end

  def handle_info(:after_join, socket) do 
    pad = socket.assigns.pad
    for {user_id, %{strokes: strokes}} <- PadServer.render(pad) do
      for stroke <- Enum.reverse(strokes) do
        push(socket, "stroke", %{user_id: user_id, stroke: stroke})
      end
    end
    {:noreply, socket}
  end
end

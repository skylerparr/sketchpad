defmodule Sketchpad.PadServer do 
  use GenServer

  alias SketchpadWeb.PadChannel

  def start_link(pad_id) do
    GenServer.start_link(__MODULE__, [pad_id], 
                         name: {:global, topic(pad_id)})
  end

  def init([pad_id]) do 
    {:ok, %{
      pad_id: pad_id, 
      users: %{},
      topic: topic(pad_id)
    }}
  end

  defp topic(pad_id), do: "pad:#{pad_id}"

  def find(pad_id) do 
    case :global.whereis_name(topic(pad_id)) do
      pid when is_pid(pid) -> {:ok, pid}
      :undefined -> {:error, :noprocess}
    end
  end

  def put_stroke(pid, user_id, stroke) do
    GenServer.call(pid, {:put_stroke, user_id, stroke})
  end

  def render(pid) do 
    GenServer.call(pid, :render)
  end

  def clear(pid, user_id) do 
    GenServer.call(pid, {:clear, user_id})
  end

  def handle_call({:clear, user_id}, _from, state) do 
    PadChannel.broadcast_clear(state.topic, user_id)
    {:reply, :ok, %{state | users: %{}}}
  end

  def handle_call({:put_stroke, user_id, stroke}, _from, state) do 
    PadChannel.broadcast_stroke(state.topic, user_id, stroke)
    {:reply, :ok, put_user_stroke(state, user_id, stroke)}
  end

  def handle_call(:render, _from, state) do 
    {:reply, state.users, state}
  end

  defp put_user_stroke(%{users: users} = state, user_id, stroke) do 
    users = Map.put_new(users, user_id, %{id: user_id, strokes: []})
    users = update_in(users, [user_id, :strokes], fn(strokes) ->
      [stroke | strokes]
    end)
    %{state | users: users}
  end
end

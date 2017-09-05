defmodule SketchpadWeb.UserSocket do
  use Phoenix.Socket

  ## Channels
  channel "pad:*", SketchpadWeb.PadChannel

  ## Transports
  transport :websocket, Phoenix.Transports.WebSocket

  def connect(%{"token" => token}, socket) do
    case Phoenix.Token.verify(socket, "user token", token, max_age: 86400) do
      {:ok, user_id} -> 
        IO.inspect ">> Verified #{user_id}"
        {:ok, assign(socket, :user_id, user_id)}

      {:error, _reason} -> 
        IO.inspect ">> failed to verify user"
        :error
    end
  end

  def id(_socket), do: nil
end

defmodule SketchpadWeb.PageController do
  use SketchpadWeb, :controller

  plug :require_user when not action in [:signin]

  def index(conn, _params) do
    render conn, "index.html"
  end

  def signin(conn, %{"user" => %{"username" => user}}) do 
    conn
    |> put_session(:user_id, user)
    |> redirect(to: "/")
  end

  defp require_user(conn, _optional_params) do 
    if(user = get_session(conn, :user_id)) do 
      conn
      |> assign(:user_id, user)
      |> assign(:user_token, Phoenix.Token.sign(conn, "user token", user))
    else
      conn
      |> put_flash(:error, "Please signin")
      |> render("signin.html")
      |> halt()
    end
  end
end

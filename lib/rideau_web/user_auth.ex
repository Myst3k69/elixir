defmodule RideauWeb.UserAuth do
  @moduledoc false

  import Phoenix.Component
  import Phoenix.LiveView
  use RideauWeb, :verified_routes

  alias Rideau.Accounts

  def on_mount(:mount_current_user, _params, session, socket) do
    {:cont, assign_user(socket, session)}
  end

  def on_mount(:ensure_authenticated, _params, session, socket) do
    socket = assign_user(socket, session)

    if socket.assigns.current_user do
      {:cont, socket}
    else
      {:halt,
       socket
       |> put_flash(:error, "Connectez-vous pour entrer en régie.")
       |> redirect(to: ~p"/connexion")}
    end
  end

  def on_mount(:redirect_if_authenticated, _params, session, socket) do
    socket = assign_user(socket, session)

    if socket.assigns.current_user do
      {:halt, redirect(socket, to: ~p"/saison")}
    else
      {:cont, socket}
    end
  end

  defp assign_user(socket, session) do
    user =
      case session["user_id"] do
        id when is_integer(id) -> Accounts.get_user(id)
        _ -> nil
      end

    assign(socket, :current_user, user)
  end
end

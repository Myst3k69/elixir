defmodule RideauWeb.SessionController do
  use RideauWeb, :controller

  alias Rideau.Accounts

  def create(conn, %{"user" => %{"email" => email, "password" => password}})
      when is_binary(email) and is_binary(password) do
    if user = Accounts.get_user_by_email_and_password(email, password) do
      conn
      |> put_session(:user_id, user.id)
      |> configure_session(renew: true)
      |> redirect(to: ~p"/saison")
    else
      conn
      |> put_flash(:error, "Adresse ou mot de passe incorrect.")
      |> redirect(to: ~p"/connexion")
    end
  end

  def create(conn, _params) do
    conn
    |> put_flash(:error, "Indiquez une adresse et un mot de passe.")
    |> redirect(to: ~p"/connexion")
  end

  def delete(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> redirect(to: ~p"/")
  end
end

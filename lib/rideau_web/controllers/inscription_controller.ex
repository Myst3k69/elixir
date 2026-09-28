defmodule RideauWeb.InscriptionController do
  use RideauWeb, :controller

  alias Rideau.Accounts

  def create(conn, %{"inscription" => params}) when is_map(params) do
    case Accounts.register_compagnie(params) do
      {:ok, user} ->
        conn
        |> put_session(:user_id, user.id)
        |> configure_session(renew: true)
        |> put_flash(:info, "La compagnie est ouverte. L'essai couvre un spectacle.")
        |> redirect(to: ~p"/saison")

      {:error, changeset} ->
        conn
        |> put_flash(:error, message_erreur(changeset))
        |> redirect(to: ~p"/inscription")
    end
  end

  def create(conn, _params) do
    conn
    |> put_flash(:error, "Le formulaire est incomplet.")
    |> redirect(to: ~p"/inscription")
  end

  defp message_erreur(changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(fn {msg, _opts} -> msg end)
    |> Enum.map_join(" ", fn {field, messages} ->
      "#{label(field)} #{Enum.join(messages, ", ")}."
    end)
    |> case do
      "" -> "Inscription impossible."
      message -> message
    end
  end

  defp label(:email), do: "L'adresse"
  defp label(:nom), do: "Le nom"
  defp label(:password), do: "Le mot de passe"
  defp label(:nom_compagnie), do: "La compagnie"
  defp label(other), do: to_string(other)
end

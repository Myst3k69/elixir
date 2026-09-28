defmodule RideauWeb.InscriptionLive do
  use RideauWeb, :live_view

  alias Rideau.Accounts

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Ouvrir une compagnie",
       form: to_form(Accounts.change_inscription(), as: :inscription),
       trigger: false
     )}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user} tone="paper">
      <main class="etroit">
        <p class="kicker">Essai</p>
        <h1>Ouvrir la compagnie.</h1>
        <p class="chapo chapo-court">
          L'essai couvre un spectacle, le pupitre et tous les postes. Le compte est actif
          tout de suite : aucun e-mail de confirmation n'est envoyé.
        </p>

        <.form
          for={@form}
          id="inscription"
          action={~p"/inscription"}
          method="post"
          phx-submit="save"
          phx-change="validate"
          phx-trigger-action={@trigger}
          class="fiche"
        >
          <.champ field={@form[:nom]} label="Votre nom" autocomplete="name" required />
          <.champ field={@form[:nom_compagnie]} label="Nom de la compagnie" required />
          <.champ field={@form[:email]} type="email" label="Adresse" autocomplete="email" required />
          <.champ
            field={@form[:password]}
            type="password"
            label="Mot de passe"
            autocomplete="new-password"
            required
          />
          <button class="bouton bouton-sang" type="submit" phx-disable-with="Ouverture…">
            Créer l'essai
          </button>
        </.form>

        <p class="bas-de-page">
          Déjà un compte ? <.link navigate={~p"/connexion"}>Entrer</.link>
        </p>
      </main>
    </Layouts.app>
    """
  end

  def handle_event("validate", %{"inscription" => params}, socket) do
    form =
      params
      |> Accounts.change_inscription()
      |> Map.put(:action, :validate)
      |> to_form(as: :inscription)

    {:noreply, assign(socket, form: form, trigger: false)}
  end

  def handle_event("save", %{"inscription" => params}, socket) do
    changeset = Accounts.change_inscription(params)

    if changeset.valid? do
      {:noreply, assign(socket, trigger: true, form: to_form(params, as: :inscription))}
    else
      {:noreply, assign(socket, form: to_form(%{changeset | action: :insert}, as: :inscription))}
    end
  end
end

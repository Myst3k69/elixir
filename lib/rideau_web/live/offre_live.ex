defmodule RideauWeb.OffreLive do
  use RideauWeb, :live_view

  alias Rideau.Accounts

  def mount(_params, _session, socket) do
    {:ok, reload(socket)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user} tone="paper">
      <main class="offre">
        <p class="kicker">Offre</p>
        <h1>On paie quand le deuxième spectacle arrive.</h1>
        <p class="chapo">
          L'essai conduit un spectacle, avec le pupitre et tous les postes. La soirée
          en ajoute un. La saison lève la limite pour toute la compagnie.
        </p>
        <p class="note-demo">
          Paiement simulé. Aucune carte n'est demandée, aucun montant n'est débité.
          L'offre choisie est enregistrée sur la compagnie : le parcours est vrai, le prélèvement ne l'est pas.
        </p>

        <div class="prix prix-page">
          <article>
            <h2>Essai</h2>
            <p class="montant">0 €</p>
            <ul>
              <li>Un spectacle</li>
              <li>Pupitre, postes, feuille de soirée</li>
              <li>Actif dès l'inscription</li>
            </ul>
          </article>
          <article>
            <h2>Soirée</h2>
            <p class="montant">19 €</p>
            <ul>
              <li>Un spectacle supplémentaire</li>
              <li>Sans abonnement</li>
              <li>Pour une date, une lecture, une reprise</li>
            </ul>
            <%= if regie?(@current_user) && @current_user.compagnie.plan != "saison" do %>
              <button
                :if={@confirmation != "soiree"}
                type="button"
                class="bouton bouton-encre"
                phx-click="choisir"
                phx-value-plan="soiree"
              >
                Choisir la soirée
              </button>
            <% end %>
          </article>
          <article class="prix-fort">
            <h2>Saison</h2>
            <p class="montant">49 € <span>/ mois</span></p>
            <ul>
              <li>Spectacles illimités</li>
              <li>Toute la compagnie</li>
              <li>La feuille de chaque soir</li>
            </ul>
            <%= if regie?(@current_user) && @current_user.compagnie.plan != "saison" do %>
              <button
                :if={@confirmation != "saison"}
                type="button"
                class="bouton bouton-sang"
                phx-click="choisir"
                phx-value-plan="saison"
              >
                Choisir la saison
              </button>
            <% end %>
            <p :if={@current_user && @current_user.compagnie.plan == "saison"} class="deja">
              Saison déjà active sur cette compagnie.
            </p>
          </article>
        </div>

        <section :if={@confirmation} class="confirmation" aria-live="polite">
          <h2>Confirmer l'offre {label_plan(@confirmation)}</h2>
          <p>
            {format_prix(Accounts.offre(@confirmation).montant_centimes)} — {Accounts.offre(
              @confirmation
            ).libelle}
          </p>
          <div class="actions">
            <button
              type="button"
              class="bouton bouton-or"
              phx-click="confirmer"
              phx-disable-with="Enregistrement…"
            >
              Enregistrer l'offre simulée
            </button>
            <button type="button" class="bouton bouton-fantome" phx-click="annuler">
              Annuler
            </button>
          </div>
        </section>

        <section :if={!@current_user} class="vide">
          <h2>Pour enregistrer une offre, ouvrez d'abord la compagnie.</h2>
          <.link navigate={~p"/inscription"} class="bouton bouton-sang">Créer un essai</.link>
        </section>

        <section :if={@current_user} class="historique">
          <h2>Offres enregistrées</h2>
          <p :if={@souscriptions == []} class="muted">
            Aucune offre enregistrée. L'essai en cours n'est pas une facture.
          </p>
          <ol :if={@souscriptions != []}>
            <li :for={souscription <- @souscriptions}>
              <span>{label_plan(souscription.plan)}</span>
              <span>{format_prix(souscription.montant_centimes)}</span>
              <span>{souscription.libelle}</span>
              <time datetime={DateTime.to_iso8601(souscription.inserted_at)}>
                {format_heure(souscription.inserted_at)}
              </time>
            </li>
          </ol>
        </section>
      </main>
    </Layouts.app>
    """
  end

  def handle_event("choisir", %{"plan" => plan}, socket) when plan in ["soiree", "saison"] do
    if socket.assigns.current_user && socket.assigns.current_user.role == "regie" do
      {:noreply, assign(socket, :confirmation, plan)}
    else
      {:noreply, put_flash(socket, :error, "Seule la régie engage une offre pour la compagnie.")}
    end
  end

  def handle_event("annuler", _, socket), do: {:noreply, assign(socket, :confirmation, nil)}

  def handle_event("confirmer", _, socket) do
    plan = socket.assigns.confirmation
    user = socket.assigns.current_user

    case Accounts.souscrire(user.compagnie, user, plan) do
      {:ok, _compagnie} ->
        {:noreply,
         socket
         |> reload()
         |> assign(:confirmation, nil)
         |> put_flash(:info, "Offre enregistrée. Aucun montant n'a été débité.")}

      {:error, :deja} ->
        {:noreply, put_flash(socket, :error, "La saison est déjà active.")}

      {:error, :interdit} ->
        {:noreply, put_flash(socket, :error, "Seule la régie peut enregistrer une offre.")}
    end
  end

  defp regie?(nil), do: false
  defp regie?(user), do: user.role == "regie"

  defp reload(socket) do
    user =
      if socket.assigns.current_user do
        Accounts.get_user(socket.assigns.current_user.id)
      end

    souscriptions =
      if user do
        Accounts.list_souscriptions(user.compagnie_id)
      else
        []
      end

    assign(socket,
      page_title: "Offre",
      current_user: user,
      souscriptions: souscriptions,
      confirmation: nil
    )
  end
end

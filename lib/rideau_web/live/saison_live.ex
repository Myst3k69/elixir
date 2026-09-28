defmodule RideauWeb.SaisonLive do
  use RideauWeb, :live_view

  alias Rideau.{Accounts, Conduite}

  def mount(_params, _session, socket) do
    {:ok, load(socket)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user} tone="paper">
      <main class="saison">
        <header class="saison-entete">
          <div>
            <p class="kicker">{@current_user.compagnie.nom}</p>
            <h1>La saison.</h1>
            <p class="muted">{phrase_quota(@current_user.compagnie, @nombre)}</p>
          </div>
          <.link
            :if={@current_user.role == "regie"}
            navigate={~p"/spectacles/nouveau"}
            class="bouton bouton-sang"
          >
            Ouvrir un spectacle
          </.link>
        </header>

        <p :if={@current_user.compagnie.demonstration} class="note-demo">
          Compagnie de démonstration. Le spectacle ci-dessous est un jeu de données écrit pour RIDEAU, pas une production réelle.
        </p>

        <section :if={@spectacles == []} class="vide">
          <h2>La saison est vide.</h2>
          <p>
            L'essai couvre un spectacle. Ouvrez-le, écrivez le conducteur, appelez le premier top.
          </p>
          <.link
            :if={@current_user.role == "regie"}
            navigate={~p"/spectacles/nouveau"}
            class="bouton bouton-or"
          >
            Écrire la fiche
          </.link>
        </section>

        <ul class="affiches">
          <li :for={spectacle <- @spectacles} class="affiche">
            <p class="kicker">
              {format_date(spectacle.prochaine_le)}
              <span :if={spectacle.demonstration}>· démonstration</span>
            </p>
            <h2>
              <.link navigate={~p"/spectacles/#{spectacle.id}"}>{spectacle.titre}</.link>
            </h2>
            <p :if={spectacle.sous_titre} class="sous-titre">{spectacle.sous_titre}</p>
            <p class="muted">
              {[spectacle.auteur, spectacle.salle, spectacle.ville]
              |> Enum.reject(&is_nil/1)
              |> Enum.join(" · ")}
            </p>
            <p class={"phase phase-#{spectacle.phase}"}>{label_phase(spectacle.phase)}</p>
            <div class="affiche-liens">
              <.link navigate={~p"/spectacles/#{spectacle.id}"}>Conducteur</.link>
              <.link
                :if={@current_user.role == "regie"}
                navigate={~p"/spectacles/#{spectacle.id}/pupitre"}
              >
                Pupitre
              </.link>
              <.link navigate={~p"/spectacles/#{spectacle.id}/poste/#{@poste}"}>
                Poste {Rideau.Departement.label(@poste)}
              </.link>
              <.link navigate={~p"/spectacles/#{spectacle.id}/rapport"}>Feuille</.link>
            </div>
          </li>
        </ul>
      </main>
    </Layouts.app>
    """
  end

  defp load(socket) do
    user = Accounts.get_user(socket.assigns.current_user.id)
    spectacles = Conduite.list_spectacles(user.compagnie_id)
    poste = user.departement || "lumiere"

    assign(socket,
      page_title: "Saison",
      current_user: user,
      spectacles: spectacles,
      nombre: length(spectacles),
      poste: poste
    )
  end
end

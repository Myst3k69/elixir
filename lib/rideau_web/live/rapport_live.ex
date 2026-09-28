defmodule RideauWeb.RapportLive do
  use RideauWeb, :live_view

  alias Rideau.{Conduite, Departement}
  alias RideauWeb.Plateau

  def mount(%{"id" => id}, _session, socket) do
    user = socket.assigns.current_user

    case Conduite.fetch_spectacle(user.compagnie_id, id) do
      :error ->
        {:ok,
         socket
         |> put_flash(:error, "Ce spectacle n'est pas dans votre saison.")
         |> redirect(to: ~p"/saison")}

      {:ok, spectacle} ->
        socket =
          socket
          |> assign(:page_title, "Feuille · #{spectacle.titre}")
          |> assign(:regie, user.role == "regie")
          |> Plateau.follow(
            spectacle,
            user,
            if(user.role == "regie", do: "Régie", else: Departement.label(user.departement))
          )
          |> refresh(spectacle)

        {:ok, socket}
    end
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user} tone="paper">
      <.barre_scene spectacle={@spectacle} current="rapport" regie={@regie} />
      <main class="rapport">
        <header>
          <p class="kicker">Feuille de soirée</p>
          <h1>{@spectacle.titre}</h1>
          <p class="muted">
            Chaque préparez et chaque top est horodaté à l'heure de Paris, au moment où la régie l'appelle.
          </p>
        </header>

        <section :if={@appels == []} class="vide">
          <h2>La feuille est blanche.</h2>
          <p>Elle s'écrit au premier préparez. Rien ici n'est inventé à l'avance.</p>
          <.link
            :if={@regie}
            navigate={~p"/spectacles/#{@spectacle.id}/pupitre"}
            class="bouton bouton-sang"
          >
            Aller au pupitre
          </.link>
        </section>

        <ol :if={@appels != []} class="feuille">
          <li :for={appel <- @appels} id={"appel-#{appel.id}"} class={"action-#{appel.action}"}>
            <time datetime={DateTime.to_iso8601(appel.inserted_at)}>{format_heure(appel.inserted_at)}</time>
            <span class="action">{label_action(appel.action)}</span>
            <span class={"dept dept-#{appel.departement}"}>{Departement.label(appel.departement)}</span>
            <span class="libelle">{appel.libelle}</span>
            <span class="muted">{appel.user && appel.user.nom}</span>
          </li>
        </ol>
      </main>
    </Layouts.app>
    """
  end

  def handle_info({:plateau, _event, _cue_id}, socket), do: {:noreply, refresh(socket)}

  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff"}, socket) do
    {:noreply, Plateau.assign_presents(socket)}
  end

  defp refresh(socket, spectacle \\ nil) do
    spectacle =
      spectacle ||
        case Conduite.fetch_spectacle(
               socket.assigns.current_user.compagnie_id,
               socket.assigns.spectacle.id
             ) do
          {:ok, spectacle} -> spectacle
        end

    assign(socket, spectacle: spectacle, appels: Conduite.list_appels(spectacle))
  end
end

defmodule RideauWeb.PupitreLive do
  use RideauWeb, :live_view

  alias Rideau.{Conduite, Departement}
  alias RideauWeb.Plateau

  def mount(%{"id" => id}, _session, socket) do
    user = socket.assigns.current_user

    cond do
      user.role != "regie" ->
        {:ok,
         socket
         |> put_flash(:error, "Le pupitre est réservé à la régie.")
         |> redirect(to: ~p"/saison")}

      true ->
        case Conduite.fetch_spectacle(user.compagnie_id, id) do
          :error ->
            {:ok,
             socket
             |> put_flash(:error, "Ce spectacle n'est pas dans votre saison.")
             |> redirect(to: ~p"/saison")}

          {:ok, spectacle} ->
            socket =
              socket
              |> assign(:page_title, "Pupitre · #{spectacle.titre}")
              |> assign(:salve, nil)
              |> Plateau.follow(spectacle, user, "Régie")
              |> load(spectacle)

            {:ok, socket}
        end
    end
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user} tone="scene">
      <div id="pupitre-clavier" phx-hook="Pupitre">
        <.barre_scene spectacle={@spectacle} current="pupitre" regie={true} />
        <div
          :if={@salve}
          id={"salve-#{@salve.token}"}
          class={"salve salve-#{@salve.kind}"}
          aria-live="assertive"
        >
          <p class="salve-mot">{@salve.word}</p>
          <p class="salve-detail">{@salve.detail}</p>
        </div>

        <main class="pupitre">
          <aside class="pupitre-cote">
            <p class={"phase phase-#{@spectacle.phase}"}>{label_phase(@spectacle.phase)}</p>
            <div class="presents" aria-label="Postes en ligne">
              <span>En ligne</span>
              <ul>
                <li :for={present <- @presents}>
                  <strong>{present.nom}</strong>
                  <span>{present.poste}</span>
                </li>
              </ul>
              <p :if={length(@presents) < 2} class="muted">
                Ouvrez un poste dans un autre onglet : le top y arrive en direct.
              </p>
            </div>
            <div class="touches-phase">
              <button
                :if={@spectacle.phase != "entracte"}
                type="button"
                phx-click="phase"
                phx-value-phase="entracte"
                disabled={@spectacle.phase == "clos"}
              >
                Entracte
              </button>
              <button
                :if={@spectacle.phase == "entracte"}
                type="button"
                phx-click="phase"
                phx-value-phase="jeu"
              >
                On reprend
              </button>
              <button
                :if={@spectacle.phase != "clos"}
                type="button"
                phx-click="phase"
                phx-value-phase="clos"
              >
                Clore
              </button>
              <button
                :if={@spectacle.phase == "clos"}
                type="button"
                phx-click="phase"
                phx-value-phase="jeu"
              >
                Rouvrir
              </button>
              <button type="button" phx-click="rappeler">Rappel</button>
            </div>
            <p class="raccourcis">P prépare · T ou espace top · R rappelle</p>
          </aside>

          <section :if={@total == 0} class="vide vide-scene">
            <p class="kicker">Conducteur vierge</p>
            <h1>Rien à appeler.</h1>
            <p>Écrivez d'abord les cues, puis revenez au pupitre.</p>
            <.link navigate={~p"/spectacles/#{@spectacle.id}"} class="bouton bouton-or">
              Écrire le conducteur
            </.link>
          </section>

          <section :if={@total > 0 && is_nil(@courant)} class="vide vide-scene">
            <p class="kicker">Fin de conducteur</p>
            <h1>Plus rien à appeler.</h1>
            <p>Toutes les cues sont passées. La feuille de soirée garde l'heure de chaque top.</p>
            <.link navigate={~p"/spectacles/#{@spectacle.id}/rapport"} class="bouton bouton-or">
              Lire la feuille
            </.link>
          </section>

          <section :if={@courant} class="cue-hero">
            <p class="kicker">
              À appeler <span :if={@rang}>{@rang} / {@total}</span>
            </p>
            <p class={"dept dept-#{@courant.departement}"}>
              {Departement.label(@courant.departement)}
            </p>
            <p class="hero-numero">{@courant.numero}</p>
            <h1>{@courant.intitule}</h1>
            <p :if={@courant.note} class="hero-note">{@courant.note}</p>
            <p :if={@courant.repere} class="muted">Repère · {@courant.repere}</p>
            <p :if={@spectacle.phase == "clos"} class="alerte-clos">
              La représentation est close. Rouvrez la conduite pour appeler.
            </p>
            <div class="hero-actions">
              <button
                id="bouton-preparer"
                type="button"
                class={["bouton", "bouton-ambre", @courant.statut == "prepare" && "arme"]}
                phx-click="preparer"
                phx-disable-with="Préparez…"
                disabled={@spectacle.phase == "clos"}
                aria-keyshortcuts="P"
              >
                {if @courant.statut == "prepare", do: "Préparez — déjà envoyé", else: "Préparez"}
              </button>
              <button
                id="bouton-top"
                type="button"
                class="bouton bouton-top"
                phx-click="appeler"
                phx-disable-with="Top…"
                disabled={@spectacle.phase == "clos"}
                aria-keyshortcuts="T"
              >
                Top
              </button>
            </div>
          </section>

          <section :if={@courant} class="suite">
            <h2>Ensuite</h2>
            <ol>
              <li :for={cue <- @suivants} class={"dept-#{cue.departement}"}>
                <span>{cue.numero}</span>
                <span>{Departement.label(cue.departement)}</span>
                <span>{cue.intitule}</span>
              </li>
            </ol>
            <p :if={@suivants == []} class="muted">Dernière cue du conducteur.</p>
            <h2 :if={@precedents != []}>Déjà passé</h2>
            <ol :if={@precedents != []} class="passes">
              <li :for={cue <- @precedents}>
                <span>{cue.numero}</span>
                <span>{cue.intitule}</span>
              </li>
            </ol>
          </section>
        </main>
      </div>
    </Layouts.app>
    """
  end

  def handle_event("preparer", _, socket), do: agir(socket, :preparer)
  def handle_event("appeler", _, socket), do: agir(socket, :appeler_top)
  def handle_event("rappeler", _, socket), do: agir(socket, :rappeler)

  def handle_event("phase", %{"phase" => phase}, socket)
      when phase in ["jeu", "entracte", "clos"] do
    case Conduite.changer_phase(socket.assigns.spectacle, phase, socket.assigns.current_user) do
      {:ok, _} -> {:noreply, socket}
      {:error, _} -> {:noreply, put_flash(socket, :error, "La phase n'a pas changé.")}
    end
  end

  def handle_info({:plateau, event, cue_id}, socket) do
    socket = reload(socket)
    cue = Enum.find(socket.assigns.cues, &(&1.id == cue_id))
    {:noreply, salve(socket, event, cue)}
  end

  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff"}, socket) do
    {:noreply, Plateau.assign_presents(socket)}
  end

  def handle_info({:clear_salve, token}, socket) do
    {:noreply, Plateau.clear_salve(socket, token)}
  end

  defp agir(socket, fun) do
    case apply(Conduite, fun, [socket.assigns.spectacle, socket.assigns.current_user]) do
      {:ok, _} ->
        {:noreply, socket}

      {:error, :clos} ->
        {:noreply,
         put_flash(
           socket,
           :error,
           "La représentation est close. Rouvrez la conduite pour appeler."
         )}

      {:error, :vide} ->
        {:noreply, put_flash(socket, :error, "Aucune cue à appeler.")}

      {:error, :rien} ->
        {:noreply, put_flash(socket, :error, "Rien à rappeler.")}
    end
  end

  defp load(socket, spectacle) do
    etat = Conduite.etat_plateau(spectacle)

    assign(socket,
      spectacle: spectacle,
      courant: etat.courant,
      suivants: etat.suivants,
      precedents: etat.precedents,
      total: etat.total,
      rang: etat.rang,
      cues: etat.cues
    )
  end

  defp reload(socket) do
    {:ok, spectacle} =
      Conduite.fetch_spectacle(
        socket.assigns.current_user.compagnie_id,
        socket.assigns.spectacle.id
      )

    load(socket, spectacle)
  end

  defp salve(socket, :prepare, %{} = cue),
    do: Plateau.put_salve(socket, "prepare", "Préparez", detail(cue))

  defp salve(socket, :top, %{} = cue), do: Plateau.put_salve(socket, "top", "Top", detail(cue))

  defp salve(socket, :rappel, %{} = cue),
    do: Plateau.put_salve(socket, "rappel", "Rappel", detail(cue))

  defp salve(socket, :reprise, %{} = cue),
    do: Plateau.put_salve(socket, "reprise", "Reprise", detail(cue))

  defp salve(socket, :entracte, _),
    do: Plateau.put_salve(socket, "entracte", "Entracte", "Le plateau attend")

  defp salve(socket, :reprise_jeu, _),
    do: Plateau.put_salve(socket, "reprise", "On reprend", "La conduite reprend")

  defp salve(socket, :cloture, _),
    do: Plateau.put_salve(socket, "cloture", "Clos", "La feuille de soirée est écrite")

  defp salve(socket, _event, _cue), do: socket

  defp detail(cue) do
    "#{cue.numero} · #{Departement.label(cue.departement)} — #{cue.intitule}"
  end
end

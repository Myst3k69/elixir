defmodule RideauWeb.PosteLive do
  use RideauWeb, :live_view

  alias Rideau.{Conduite, Departement}
  alias RideauWeb.Plateau

  def mount(%{"id" => id, "departement" => departement}, _session, socket) do
    user = socket.assigns.current_user

    cond do
      not Departement.valid?(departement) ->
        {:ok,
         socket
         |> put_flash(:error, "Ce poste n'existe pas.")
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
              |> assign(:page_title, "#{Departement.label(departement)} · #{spectacle.titre}")
              |> assign(:departement, departement)
              |> assign(:salve, nil)
              |> assign(:echo, nil)
              |> Plateau.follow(spectacle, user, Departement.label(departement))
              |> load(spectacle)

            {:ok, socket}
        end
    end
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user} tone="scene">
      <.barre_scene
        spectacle={@spectacle}
        current={@departement}
        regie={@current_user.role == "regie"}
      />
      <div
        :if={@salve}
        id={"salve-#{@salve.token}"}
        class={"salve salve-#{@salve.kind}"}
        aria-live="assertive"
      >
        <p class="salve-mot">{@salve.word}</p>
        <p class="salve-detail">{@salve.detail}</p>
      </div>
      <main class="poste">
        <%= cond do %>
          <% @spectacle.phase == "entracte" -> %>
            <section class="poste-plein poste-entracte">
              <p class="kicker">{Departement.label(@departement)}</p>
              <h1>Entracte</h1>
              <p>Le plateau attend. On ne joue pas tant que la régie n'a pas repris.</p>
            </section>
          <% @spectacle.phase == "clos" -> %>
            <section class="poste-plein poste-clos">
              <p class="kicker">{Departement.label(@departement)}</p>
              <h1>Clos</h1>
              <p>La représentation est fermée. La feuille de soirée garde les tops.</p>
            </section>
          <% @courant && @courant.departement == @departement && @courant.statut == "prepare" -> %>
            <section class={"poste-plein poste-prepare dept-#{@departement}"}>
              <p class="poste-ordre">Préparez</p>
              <p class="kicker">{Departement.label(@departement)} · cue {@courant.numero}</p>
              <p class="hero-numero">{@courant.numero}</p>
              <h1>{@courant.intitule}</h1>
              <p :if={@courant.note}>{@courant.note}</p>
              <p :if={@courant.repere} class="muted">Repère · {@courant.repere}</p>
            </section>
          <% @courant && @courant.departement == @departement -> %>
            <section class={"poste-plein dept-#{@departement}"}>
              <p class="kicker">Votre cue · en attente du préparez</p>
              <p class="hero-numero">{@courant.numero}</p>
              <h1>{@courant.intitule}</h1>
              <p :if={@courant.note}>{@courant.note}</p>
            </section>
          <% true -> %>
            <section class="poste-attente">
              <p class="kicker">{Departement.label(@departement)} en attente</p>
              <h1 :if={@courant}>
                En cours · {Departement.label(@courant.departement)} {@courant.numero}
              </h1>
              <p :if={@courant}>{@courant.intitule}</p>
              <h1 :if={!@courant}>Rien en cours</h1>
              <p :if={@echo} class="echo">{@echo}</p>
              <article :if={@prochaine} class="prochaine">
                <p class="kicker">Votre prochaine</p>
                <p class="hero-numero">{@prochaine.numero}</p>
                <h2>{@prochaine.intitule}</h2>
                <p :if={@prochaine.note}>{@prochaine.note}</p>
              </article>
              <p :if={!@prochaine} class="muted">
                Plus de cue {Departement.label(@departement)} dans ce conducteur.
              </p>
            </section>
        <% end %>

        <section class="mes-cues">
          <h2>Cues {Departement.label(@departement)}</h2>
          <ol>
            <li :for={cue <- @miennes} class={"statut-#{cue.statut}"}>
              <span>{cue.numero}</span>
              <span>{cue.intitule}</span>
              <span>{label_statut(cue.statut)}</span>
            </li>
          </ol>
          <p :if={@miennes == []} class="muted">Aucune cue pour ce poste.</p>
        </section>
        <p class="raccourcis">Ce poste ne conduit pas. Seule la régie appelle le top.</p>
      </main>
    </Layouts.app>
    """
  end

  def handle_info({:plateau, event, cue_id}, socket) do
    socket = reload(socket)
    cue = Enum.find(socket.assigns.cues, &(&1.id == cue_id))
    {:noreply, reagir(socket, event, cue)}
  end

  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff"}, socket) do
    {:noreply, Plateau.assign_presents(socket)}
  end

  def handle_info({:clear_salve, token}, socket) do
    {:noreply, Plateau.clear_salve(socket, token)}
  end

  defp reagir(socket, event, _cue) when event in [:entracte, :reprise_jeu, :cloture] do
    word =
      case event do
        :entracte -> "Entracte"
        :reprise_jeu -> "On reprend"
        :cloture -> "Clos"
      end

    Plateau.put_salve(
      socket,
      Atom.to_string(event),
      word,
      Departement.label(socket.assigns.departement)
    )
  end

  defp reagir(socket, event, %{departement: dept} = cue)
       when event in [:prepare, :top, :rappel, :reprise] do
    if dept == socket.assigns.departement do
      {kind, word} =
        case event do
          :prepare -> {"prepare", "Préparez"}
          :top -> {"top", "Top"}
          :rappel -> {"rappel", "Rappel"}
          :reprise -> {"reprise", "Reprise"}
        end

      Plateau.put_salve(socket, kind, word, "#{cue.numero} · #{cue.intitule}")
    else
      echo =
        case event do
          :top -> "Top #{Departement.label(dept)} · #{cue.numero} #{cue.intitule}"
          :prepare -> "Préparez #{Departement.label(dept)} · #{cue.numero}"
          _ -> nil
        end

      assign(socket, :echo, echo)
    end
  end

  defp reagir(socket, _event, _cue), do: socket

  defp load(socket, spectacle) do
    etat = Conduite.etat_plateau(spectacle)
    dept = socket.assigns.departement
    miennes = Enum.filter(etat.cues, &(&1.departement == dept))

    prochaine =
      Enum.find(miennes, fn cue ->
        cue.statut != "passe" && (is_nil(etat.courant) || cue.id != etat.courant.id)
      end)

    assign(socket,
      spectacle: spectacle,
      courant: etat.courant,
      cues: etat.cues,
      miennes: miennes,
      prochaine: prochaine
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
end

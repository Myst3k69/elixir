defmodule RideauWeb.ConducteurLive do
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
          |> assign(:page_title, "Conducteur · #{spectacle.titre}")
          |> assign(:regie, user.role == "regie")
          |> assign(:confirm_delete, nil)
          |> assign(:editing, :new)
          |> assign(:form, to_form(Conduite.change_cue()))
          |> Plateau.follow(spectacle, user, poste_label(user))
          |> refresh(spectacle)

        {:ok, socket}
    end
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user} tone="paper">
      <.barre_scene spectacle={@spectacle} current="conducteur" regie={@regie} />
      <main class="conducteur">
        <header class="conducteur-entete">
          <div>
            <p class="kicker">
              {label_phase(@spectacle.phase)}
              <span :if={@spectacle.demonstration}>· démonstration</span>
            </p>
            <h1>{@spectacle.titre}</h1>
            <p :if={@spectacle.sous_titre}>{@spectacle.sous_titre}</p>
            <p class="muted">
              {[@spectacle.auteur, @spectacle.salle, @spectacle.ville]
              |> Enum.reject(&is_nil/1)
              |> Enum.join(" · ")}
              <span :if={@spectacle.prochaine_le}>· {format_date(@spectacle.prochaine_le)}</span>
            </p>
          </div>
          <div class="actions">
            <.link
              :if={@regie}
              navigate={~p"/spectacles/#{@spectacle.id}/pupitre"}
              class="bouton bouton-sang"
            >
              Ouvrir le pupitre
            </.link>
            <.link
              :if={@regie}
              navigate={~p"/spectacles/#{@spectacle.id}/fiche"}
              class="bouton bouton-fantome"
            >
              Modifier la fiche
            </.link>
          </div>
        </header>

        <p :if={@spectacle.demonstration} class="note-demo">
          Conducteur de démonstration, texte original écrit pour RIDEAU.
        </p>
        <p :if={!@regie} class="note-demo">
          Vous suivez ce conducteur. Le pupitre est réservé à la régie. Votre poste : {Departement.label(
            @current_user.departement
          )}.
        </p>

        <div class="presents presents-papier" aria-label="Postes en ligne">
          <span>En ligne</span>
          <ul>
            <li :for={present <- @presents}>{present.nom} · {present.poste}</li>
          </ul>
          <p :if={@presents == []} class="muted">Personne n'est encore relié à ce spectacle.</p>
        </div>

        <section :if={@cues == []} class="vide">
          <h2>Le conducteur est vierge.</h2>
          <p>Ajoutez la première cue. Le pupitre l'appellera quand la salle sera noire.</p>
        </section>

        <ol class="cues">
          <li
            :for={cue <- @cues}
            id={"cue-#{cue.id}"}
            class={[
              "cue",
              "dept-#{cue.departement}",
              cue.id == @spectacle.cue_courant_id && "cue-courante",
              "statut-#{cue.statut}"
            ]}
          >
            <div class="cue-index">
              <span class="cue-numero">{cue.numero}</span>
              <span class="cue-dept">{Departement.label(cue.departement)}</span>
            </div>
            <div class="cue-corps">
              <h2>{cue.intitule}</h2>
              <p :if={cue.note}>{cue.note}</p>
              <p :if={cue.repere} class="muted">Repère · {cue.repere}</p>
              <p class="statut">{label_statut(cue.statut)}</p>
            </div>
            <div :if={@regie} class="cue-actions">
              <button
                type="button"
                phx-click="move"
                phx-value-id={cue.id}
                phx-value-direction="up"
                aria-label={"Monter la cue #{cue.numero}"}
              >
                Monter
              </button>
              <button
                type="button"
                phx-click="move"
                phx-value-id={cue.id}
                phx-value-direction="down"
                aria-label={"Descendre la cue #{cue.numero}"}
              >
                Descendre
              </button>
              <button type="button" phx-click="edit" phx-value-id={cue.id}>Modifier</button>
              <button type="button" phx-click="reprendre" phx-value-id={cue.id}>Reprendre ici</button>
              <button
                :if={@confirm_delete != cue.id}
                type="button"
                phx-click="demander_retrait"
                phx-value-id={cue.id}
              >
                Retirer
              </button>
              <button
                :if={@confirm_delete == cue.id}
                type="button"
                class="danger"
                phx-click="retirer"
                phx-value-id={cue.id}
              >
                Confirmer le retrait
              </button>
            </div>
          </li>
        </ol>

        <section :if={@regie} class="fiche fiche-cue">
          <h2>{if @editing == :new, do: "Ajouter une cue", else: "Modifier la cue"}</h2>
          <.form for={@form} id="form-cue" phx-submit="save" phx-change="validate">
            <.champ field={@form[:numero]} label="Numéro" required />
            <.champ
              field={@form[:departement]}
              type="select"
              label="Département"
              options={Departement.options()}
              required
            />
            <.champ field={@form[:intitule]} label="Intitulé" required />
            <.champ field={@form[:note]} type="textarea" label="Note de conduite" />
            <.champ field={@form[:repere]} label="Repère" placeholder="Après le rire, p. 12…" />
            <div class="actions">
              <button class="bouton bouton-encre" type="submit" phx-disable-with="Écriture…">
                {if @editing == :new, do: "Ajouter au conducteur", else: "Enregistrer"}
              </button>
              <button
                :if={@editing != :new}
                type="button"
                class="bouton bouton-fantome"
                phx-click="annuler"
              >
                Annuler
              </button>
            </div>
          </.form>
        </section>
      </main>
    </Layouts.app>
    """
  end

  def handle_event("validate", %{"cue" => params}, socket) do
    base =
      case socket.assigns.editing do
        :new -> %Conduite.Cue{}
        id -> Conduite.get_cue!(socket.assigns.spectacle, id)
      end

    form =
      base
      |> Conduite.change_cue(params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("save", %{"cue" => params}, socket) do
    result =
      case socket.assigns.editing do
        :new -> Conduite.create_cue(socket.assigns.spectacle, params)
        id -> socket.assigns.spectacle |> Conduite.get_cue!(id) |> Conduite.update_cue(params)
      end

    case result do
      {:ok, _cue} ->
        {:noreply,
         socket
         |> refresh()
         |> assign(editing: :new, form: to_form(Conduite.change_cue()), confirm_delete: nil)
         |> put_flash(:info, "Conducteur mis à jour.")}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  def handle_event("edit", %{"id" => id}, socket) do
    cue = Conduite.get_cue!(socket.assigns.spectacle, id)

    {:noreply,
     assign(socket,
       editing: cue.id,
       form: to_form(Conduite.change_cue(cue)),
       confirm_delete: nil
     )}
  end

  def handle_event("annuler", _, socket) do
    {:noreply, assign(socket, editing: :new, form: to_form(Conduite.change_cue()))}
  end

  def handle_event("demander_retrait", %{"id" => id}, socket) do
    {:noreply, assign(socket, :confirm_delete, parse_id(id))}
  end

  def handle_event("retirer", %{"id" => id}, socket) do
    cue = Conduite.get_cue!(socket.assigns.spectacle, id)
    :ok = Conduite.delete_cue(cue)

    {:noreply,
     socket
     |> refresh()
     |> assign(confirm_delete: nil, editing: :new, form: to_form(Conduite.change_cue()))
     |> put_flash(:info, "Cue retirée du conducteur.")}
  end

  def handle_event("move", %{"id" => id, "direction" => direction}, socket) do
    cue = Conduite.get_cue!(socket.assigns.spectacle, id)
    sens = if direction == "up", do: :up, else: :down

    case Conduite.move_cue(cue, sens) do
      {:ok, _} ->
        {:noreply, refresh(socket)}

      {:error, :bord} ->
        {:noreply, put_flash(socket, :error, "Cette cue est déjà au bord du conducteur.")}
    end
  end

  def handle_event("reprendre", %{"id" => id}, socket) do
    cue = Conduite.get_cue!(socket.assigns.spectacle, id)

    case Conduite.reprendre(socket.assigns.spectacle, cue, socket.assigns.current_user) do
      {:ok, _} ->
        {:noreply,
         socket
         |> refresh()
         |> put_flash(:info, "Reprise à la cue #{cue.numero}. Les suivantes sont à venir.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Reprise impossible.")}
    end
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

    etat = Conduite.etat_plateau(spectacle)
    assign(socket, spectacle: spectacle, cues: etat.cues, courant_id: spectacle.cue_courant_id)
  end

  defp poste_label(%{role: "regie"}), do: "Régie"
  defp poste_label(%{departement: code}), do: Departement.label(code)

  defp parse_id(id) do
    case Integer.parse(to_string(id)) do
      {int, _} -> int
      :error -> nil
    end
  end
end

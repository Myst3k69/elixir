defmodule RideauWeb.SpectacleFormLive do
  use RideauWeb, :live_view

  alias Rideau.{Accounts, Conduite}

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :confirm, false)}
  end

  def handle_params(params, _uri, socket) do
    user = Accounts.get_user(socket.assigns.current_user.id)

    if user.role != "regie" do
      {:noreply,
       socket
       |> put_flash(:error, "La fiche du spectacle est réservée à la régie.")
       |> redirect(to: ~p"/saison")}
    else
      {:noreply,
       apply_action(assign(socket, :current_user, user), socket.assigns.live_action, params)}
    end
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user} tone="paper">
      <main class="etroit">
        <p class="kicker">Fiche</p>
        <h1 :if={@quota}>L'essai est plein.</h1>
        <h1 :if={!@quota && @live_action == :new}>Ouvrir un spectacle</h1>
        <h1 :if={!@quota && @live_action == :edit}>{@spectacle.titre}</h1>

        <section :if={@quota} class="vide">
          <p>
            L'essai couvre un spectacle. La soirée en ajoute un, sans abonnement.
            La saison lève la limite.
          </p>
          <.link navigate={~p"/offre"} class="bouton bouton-sang">Voir les offres</.link>
          <.link navigate={~p"/saison"} class="bouton bouton-fantome">Retour à la saison</.link>
        </section>

        <.form
          :if={!@quota}
          for={@form}
          id="fiche-spectacle"
          phx-submit="save"
          phx-change="validate"
          class="fiche"
        >
          <.champ field={@form[:titre]} label="Titre" required />
          <.champ field={@form[:sous_titre]} label="Sous-titre" />
          <.champ field={@form[:auteur]} label="Auteur ou autrice" />
          <.champ field={@form[:salle]} label="Salle" />
          <.champ field={@form[:ville]} label="Ville" />
          <.champ field={@form[:prochaine_le]} type="date" label="Prochaine date" />
          <button class="bouton bouton-sang" type="submit" phx-disable-with="Enregistrement…">
            Enregistrer la fiche
          </button>
        </.form>

        <section :if={@live_action == :edit && !@quota} class="zone-danger">
          <h2>Retirer de la saison</h2>
          <p class="muted">
            Le conducteur et la feuille de soirée de ce spectacle seront effacés. Le crédit d'essai, s'il y en avait un, redevient disponible.
          </p>
          <button
            :if={!@confirm}
            type="button"
            class="bouton bouton-fantome"
            phx-click="demander_suppression"
          >
            Retirer ce spectacle
          </button>
          <div :if={@confirm} class="confirmation">
            <p>Retirer « {@spectacle.titre} » de la saison ?</p>
            <button type="button" class="bouton bouton-sang" phx-click="supprimer">
              Oui, retirer
            </button>
            <button type="button" class="bouton bouton-fantome" phx-click="annuler_suppression">
              Annuler
            </button>
          </div>
        </section>
      </main>
    </Layouts.app>
    """
  end

  def handle_event("validate", %{"spectacle" => params}, socket) do
    base = socket.assigns.spectacle || %Conduite.Spectacle{}

    form =
      base
      |> Conduite.change_spectacle(params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, :form, form)}
  end

  def handle_event("save", %{"spectacle" => params}, socket) do
    result =
      case socket.assigns.live_action do
        :new ->
          compagnie = Accounts.get_user(socket.assigns.current_user.id).compagnie
          Conduite.create_spectacle(compagnie, params)

        :edit ->
          Conduite.update_spectacle(socket.assigns.spectacle, params)
      end

    case result do
      {:ok, spectacle} ->
        {:noreply,
         socket
         |> put_flash(:info, "Fiche enregistrée.")
         |> push_navigate(to: ~p"/spectacles/#{spectacle.id}")}

      {:error, :quota} ->
        {:noreply, assign(socket, :quota, true)}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  def handle_event("demander_suppression", _, socket),
    do: {:noreply, assign(socket, :confirm, true)}

  def handle_event("annuler_suppression", _, socket),
    do: {:noreply, assign(socket, :confirm, false)}

  def handle_event("supprimer", _, socket) do
    {:ok, _} = Conduite.delete_spectacle(socket.assigns.spectacle)

    {:noreply,
     socket
     |> put_flash(:info, "Spectacle retiré de la saison.")
     |> push_navigate(to: ~p"/saison")}
  end

  defp apply_action(socket, :new, _params) do
    if Accounts.peut_ouvrir_spectacle?(socket.assigns.current_user.compagnie) do
      socket
      |> assign(:page_title, "Nouveau spectacle")
      |> assign(:spectacle, nil)
      |> assign(:quota, false)
      |> assign(:form, to_form(Conduite.change_spectacle()))
    else
      socket
      |> assign(:page_title, "Essai plein")
      |> assign(:spectacle, nil)
      |> assign(:quota, true)
      |> assign(:form, nil)
    end
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    case Conduite.fetch_spectacle(socket.assigns.current_user.compagnie_id, id) do
      {:ok, spectacle} ->
        socket
        |> assign(:page_title, "Fiche · #{spectacle.titre}")
        |> assign(:spectacle, spectacle)
        |> assign(:quota, false)
        |> assign(:form, to_form(Conduite.change_spectacle(spectacle)))

      :error ->
        socket
        |> put_flash(:error, "Ce spectacle n'est pas dans votre saison.")
        |> redirect(to: ~p"/saison")
    end
  end
end

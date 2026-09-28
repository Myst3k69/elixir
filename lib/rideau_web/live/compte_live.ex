defmodule RideauWeb.CompteLive do
  use RideauWeb, :live_view

  alias Rideau.Accounts
  alias Rideau.Conduite

  def mount(_params, _session, socket) do
    {:ok, load(socket)}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user} tone="paper">
      <main class="compte">
        <p class="kicker">Compte</p>
        <h1>{@current_user.compagnie.nom}</h1>
        <p class="chapo chapo-court">{phrase_quota(@current_user.compagnie, @nombre)}</p>
        <p>
          <.link navigate={~p"/offre"}>Voir ou changer l'offre</.link>
        </p>

        <section>
          <h2>Le plateau</h2>
          <ul class="membres">
            <li :for={membre <- @membres}>
              <span class="membre-nom">{membre.nom}</span>
              <span>{if membre.role == "regie",
                do: "Régie",
                else: Rideau.Departement.label(membre.departement)}</span>
              <span class="muted">{membre.email}</span>
            </li>
          </ul>
        </section>

        <section :if={@current_user.role == "regie"}>
          <h2>Ajouter quelqu'un au plateau</h2>
          <p class="muted">
            La personne se connecte avec l'adresse et le mot de passe choisis ici. Rien n'est envoyé par e-mail.
          </p>
          <.form for={@form} id="membre" phx-submit="save" class="fiche">
            <.champ field={@form[:nom]} label="Nom" required />
            <.champ field={@form[:email]} type="email" label="Adresse" required />
            <.champ field={@form[:password]} type="password" label="Mot de passe" required />
            <.champ
              field={@form[:departement]}
              type="select"
              label="Poste"
              options={Rideau.Departement.options()}
              required
            />
            <button class="bouton bouton-encre" type="submit" phx-disable-with="Ajout…">
              Ajouter au plateau
            </button>
          </.form>
        </section>

        <section :if={@souscriptions != []}>
          <h2>Offres enregistrées</h2>
          <ol class="historique-liste">
            <li :for={souscription <- @souscriptions}>
              {label_plan(souscription.plan)} · {format_prix(souscription.montant_centimes)} · {souscription.libelle}
            </li>
          </ol>
        </section>
      </main>
    </Layouts.app>
    """
  end

  def handle_event("save", %{"user" => params}, socket) do
    case Accounts.add_membre(socket.assigns.current_user.compagnie, params) do
      {:ok, membre} ->
        {:noreply,
         socket
         |> load()
         |> put_flash(
           :info,
           "#{membre.nom} peut se connecter avec #{membre.email}. Le mot de passe est celui que vous venez de choisir."
         )}

      {:error, changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp load(socket) do
    user = Accounts.get_user(socket.assigns.current_user.id)

    assign(socket,
      page_title: "Compte",
      current_user: user,
      membres: Accounts.list_membres(user.compagnie_id),
      souscriptions: Accounts.list_souscriptions(user.compagnie_id),
      nombre: Conduite.count_spectacles(user.compagnie_id),
      form: to_form(Accounts.change_membre(), as: :user)
    )
  end
end

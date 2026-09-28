defmodule RideauWeb.ConnexionLive do
  use RideauWeb, :live_view

  alias Rideau.Accounts

  @demos [
    %{nom: "Aurel", role: "Régie", email: "aurel@quai-des-brumes.fr", password: "rideau-rouge"},
    %{
      nom: "Camille",
      role: "Lumière",
      email: "camille@quai-des-brumes.fr",
      password: "poursuite"
    },
    %{nom: "Nour", role: "Son", email: "nour@quai-des-brumes.fr", password: "casque"}
  ]

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Connexion",
       form: to_form(%{"email" => "", "password" => ""}, as: :user),
       trigger: false,
       demos: @demos
     )}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user} tone="paper">
      <main class="etroit">
        <p class="kicker">Entrer</p>
        <h1>La régie est de ce côté.</h1>
        <p class="chapo chapo-court">
          Les trois comptes ci-dessous appartiennent à la compagnie de démonstration.
          Un compte créé à l'inscription est le vôtre.
        </p>

        <.form
          for={@form}
          id="connexion"
          action={~p"/connexion"}
          method="post"
          phx-submit="save"
          phx-trigger-action={@trigger}
          class="fiche"
        >
          <.champ field={@form[:email]} type="email" label="Adresse" autocomplete="username" required />
          <.champ
            field={@form[:password]}
            type="password"
            label="Mot de passe"
            autocomplete="current-password"
            required
          />
          <button class="bouton bouton-sang" type="submit" phx-disable-with="Vérification…">
            Entrer
          </button>
        </.form>

        <section class="demos" aria-label="Comptes de démonstration">
          <h2>Comptes de démonstration</h2>
          <ul>
            <li :for={demo <- @demos}>
              <form action={~p"/connexion"} method="post">
                <input type="hidden" name="_csrf_token" value={get_csrf_token()} />
                <input type="hidden" name="user[email]" value={demo.email} />
                <input type="hidden" name="user[password]" value={demo.password} />
                <button type="submit" class="bouton bouton-fantome">
                  {demo.nom} · {demo.role}
                </button>
              </form>
              <p class="muted">{demo.email}</p>
            </li>
          </ul>
        </section>

        <p class="bas-de-page">
          Pas encore de compagnie ? <.link navigate={~p"/inscription"}>Ouvrir un essai</.link>
        </p>
      </main>
    </Layouts.app>
    """
  end

  def handle_event("save", %{"user" => params}, socket) do
    if Accounts.get_user_by_email_and_password(params["email"] || "", params["password"] || "") do
      {:noreply, assign(socket, trigger: true, form: to_form(params, as: :user))}
    else
      {:noreply,
       socket
       |> assign(form: to_form(params, as: :user))
       |> put_flash(:error, "Adresse ou mot de passe incorrect.")}
    end
  end
end

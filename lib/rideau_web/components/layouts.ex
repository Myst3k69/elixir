defmodule RideauWeb.Layouts do
  @moduledoc false
  use RideauWeb, :html

  embed_templates "layouts/*"

  attr :flash, :map, required: true
  attr :current_user, :map, default: nil
  attr :tone, :string, default: "paper"
  slot :inner_block, required: true

  def app(assigns) do
    ~H"""
    <div id="ambiance" class={"tone-#{@tone}"} data-tone={@tone} phx-hook="Ambiance">
      <header :if={@tone == "paper"} class="mast">
        <.link navigate={if @current_user, do: ~p"/saison", else: ~p"/"} class="wordmark">
          RIDEAU
        </.link>
        <nav class="mast-nav" aria-label="Navigation">
          <.link navigate={~p"/"}>Programme</.link>
          <.link navigate={~p"/offre"}>Offre</.link>
          <%= if @current_user do %>
            <.link navigate={~p"/saison"}>Saison</.link>
            <.link navigate={~p"/compte"}>Compte</.link>
            <.link href={~p"/deconnexion"} method="delete">Sortir</.link>
          <% else %>
            <.link navigate={~p"/connexion"}>Connexion</.link>
            <.link navigate={~p"/inscription"} class="nav-fort">Ouvrir une compagnie</.link>
          <% end %>
        </nav>
      </header>

      {render_slot(@inner_block)}

      <div class="flash-pile" aria-live="polite">
        <.flash kind={:info} flash={@flash} />
        <.flash kind={:error} flash={@flash} />
      </div>

      <div
        id="liaison-coupee"
        class="liaison"
        role="status"
        hidden
        phx-disconnected={
          JS.show(to: "#liaison-coupee")
          |> JS.remove_attribute("hidden", to: "#liaison-coupee")
        }
        phx-connected={
          JS.hide(to: "#liaison-coupee")
          |> JS.set_attribute({"hidden", ""}, to: "#liaison-coupee")
        }
      >
        <strong>Liaison coupée.</strong>
        <span>Les tops ne partent plus. Reconnexion en cours.</span>
      </div>
    </div>
    """
  end
end

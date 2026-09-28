defmodule RideauWeb.CoreComponents do
  @moduledoc """
  Pièces d'interface de RIDEAU. Pas de thème générique : chaque composant
  porte la direction du programme de salle et du pupitre.
  """
  use Phoenix.Component
  use RideauWeb, :verified_routes

  alias Phoenix.LiveView.JS

  attr :field, Phoenix.HTML.FormField, required: true
  attr :label, :string, required: true
  attr :type, :string, default: "text"
  attr :options, :list, default: []
  attr :rest, :global, include: ~w(autocomplete required placeholder rows inputmode)

  def champ(%{type: "select"} = assigns) do
    ~H"""
    <div class="champ">
      <label for={@field.id}>{@label}</label>
      <select name={@field.name} id={@field.id} {@rest}>
        <option value="">Choisir</option>
        <option
          :for={{label, value} <- @options}
          value={value}
          selected={to_string(@field.value || "") == to_string(value)}
        >
          {label}
        </option>
      </select>
      <.erreurs field={@field} />
    </div>
    """
  end

  def champ(%{type: "textarea"} = assigns) do
    ~H"""
    <div class="champ">
      <label for={@field.id}>{@label}</label>
      <textarea name={@field.name} id={@field.id} rows="3" {@rest}>{@field.value}</textarea>
      <.erreurs field={@field} />
    </div>
    """
  end

  def champ(assigns) do
    ~H"""
    <div class="champ">
      <label for={@field.id}>{@label}</label>
      <input
        type={@type}
        name={@field.name}
        id={@field.id}
        value={valeur(@field)}
        {@rest}
      />
      <.erreurs field={@field} />
    </div>
    """
  end

  attr :field, Phoenix.HTML.FormField, required: true

  defp erreurs(assigns) do
    ~H"""
    <p :for={msg <- messages(@field)} class="champ-erreur">{msg}</p>
    """
  end

  attr :rest, :global, include: ~w(href navigate patch method disabled name value type)
  attr :variant, :string, default: "sang"
  slot :inner_block, required: true

  def bouton(%{rest: rest} = assigns) do
    if rest[:href] || rest[:navigate] || rest[:patch] do
      ~H"""
      <.link class={"bouton bouton-#{@variant}"} {@rest}>
        {render_slot(@inner_block)}
      </.link>
      """
    else
      assigns =
        assigns
        |> assign(:type, rest[:type] || "button")
        |> assign(:rest, Map.drop(rest, [:type]))

      ~H"""
      <button type={@type} class={"bouton bouton-#{@variant}"} {@rest}>
        {render_slot(@inner_block)}
      </button>
      """
    end
  end

  attr :id, :string, default: nil
  attr :flash, :map, default: %{}
  attr :kind, :atom, values: [:info, :error]
  attr :rest, :global

  slot :inner_block

  def flash(assigns) do
    assigns = assign(assigns, :id, assigns.id || "flash-#{assigns.kind}")

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      role="alert"
      class={"flash flash-#{@kind}"}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> JS.hide(to: "##{@id}")}
      {@rest}
    >
      <p>{msg}</p>
      <button type="button" aria-label="Fermer le message">×</button>
    </div>
    """
  end

  attr :spectacle, :map, required: true
  attr :current, :string, required: true
  attr :regie, :boolean, default: false

  def barre_scene(assigns) do
    ~H"""
    <header class="barre-scene">
      <div class="barre-gauche">
        <.link navigate={~p"/saison"} class="wordmark">RIDEAU</.link>
        <p class="barre-titre">{@spectacle.titre}</p>
      </div>
      <nav class="barre-nav" aria-label="Spectacle">
        <.link
          navigate={~p"/spectacles/#{@spectacle.id}"}
          class={[@current == "conducteur" && "ici"]}
        >
          Conducteur
        </.link>
        <.link
          :if={@regie}
          navigate={~p"/spectacles/#{@spectacle.id}/pupitre"}
          class={[@current == "pupitre" && "ici"]}
        >
          Pupitre
        </.link>
        <.link
          navigate={~p"/spectacles/#{@spectacle.id}/rapport"}
          class={[@current == "rapport" && "ici"]}
        >
          Feuille
        </.link>
        <.link
          :for={dept <- Rideau.Departement.all()}
          navigate={~p"/spectacles/#{@spectacle.id}/poste/#{dept.code}"}
          class={[@current == dept.code && "ici"]}
        >
          {dept.label}
        </.link>
      </nav>
      <p
        class="horloge"
        id={"horloge-#{@spectacle.id}-#{@current}"}
        phx-hook="Horloge"
        phx-update="ignore"
      >
        --:--:--
      </p>
    </header>
    """
  end

  defp valeur(field) do
    case field.value do
      nil -> ""
      %Date{} = date -> Date.to_iso8601(date)
      other -> to_string(other)
    end
  end

  defp messages(field) do
    Enum.map(field.errors, fn
      {msg, _opts} -> msg
      msg when is_binary(msg) -> msg
    end)
  end
end

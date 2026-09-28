defmodule RideauWeb.Plateau do
  @moduledoc false

  import Phoenix.Component

  alias Rideau.Conduite

  def follow(socket, spectacle, user, poste) do
    if Phoenix.LiveView.connected?(socket) do
      Conduite.subscribe(spectacle.id)

      {:ok, _} =
        RideauWeb.Presence.track(
          self(),
          Conduite.topic(spectacle.id),
          Integer.to_string(user.id),
          %{nom: user.nom, poste: poste}
        )
    end

    socket
    |> assign(:spectacle_id, spectacle.id)
    |> assign_presents()
  end

  def assign_presents(socket) do
    assign(socket, :presents, Conduite.presents(socket.assigns.spectacle_id))
  end

  def put_salve(socket, kind, word, detail) do
    token = System.unique_integer([:positive])
    Process.send_after(self(), {:clear_salve, token}, 1400)
    assign(socket, :salve, %{token: token, kind: kind, word: word, detail: detail})
  end

  def clear_salve(socket, token) do
    if match?(%{token: ^token}, socket.assigns[:salve]) do
      assign(socket, :salve, nil)
    else
      socket
    end
  end
end

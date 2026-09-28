defmodule Rideau.Conduite do
  @moduledoc """
  Le conducteur et les appels. Chaque top est une transaction, puis un
  message PubSub : les pupitres et les postes du même spectacle se mettent
  à jour ensemble.
  """

  import Ecto.Query
  alias Rideau.Conduite.{Appel, Cue, Spectacle}
  alias Rideau.Repo

  def topic(spectacle_id), do: "spectacle:#{spectacle_id}"

  def subscribe(spectacle_id) do
    Phoenix.PubSub.subscribe(Rideau.PubSub, topic(spectacle_id))
  end

  def count_spectacles(compagnie_id) do
    Spectacle |> where(compagnie_id: ^compagnie_id) |> Repo.aggregate(:count)
  end

  def list_spectacles(compagnie_id) do
    Spectacle
    |> where(compagnie_id: ^compagnie_id)
    |> order_by([s], asc: s.prochaine_le, asc: s.inserted_at)
    |> Repo.all()
  end

  def fetch_spectacle(compagnie_id, id) do
    case Repo.get_by(Spectacle, id: id, compagnie_id: compagnie_id) do
      nil -> :error
      spectacle -> {:ok, spectacle}
    end
  end

  def change_spectacle(spectacle \\ %Spectacle{}, attrs \\ %{}) do
    Spectacle.changeset(spectacle, attrs)
  end

  def create_spectacle(compagnie, attrs) do
    if Rideau.Accounts.peut_ouvrir_spectacle?(compagnie) do
      %Spectacle{}
      |> Spectacle.changeset(attrs)
      |> Ecto.Changeset.put_change(:compagnie_id, compagnie.id)
      |> Repo.insert()
    else
      {:error, :quota}
    end
  end

  def update_spectacle(%Spectacle{} = spectacle, attrs) do
    spectacle
    |> Spectacle.changeset(attrs)
    |> Repo.update()
  end

  def delete_spectacle(%Spectacle{} = spectacle) do
    Repo.delete(spectacle)
  end

  def mark_demonstration(%Spectacle{} = spectacle) do
    spectacle
    |> Ecto.Changeset.change(%{demonstration: true})
    |> Repo.update!()
  end

  def list_cues(%Spectacle{id: id}), do: list_cues(id)

  def list_cues(spectacle_id) do
    Cue
    |> where(spectacle_id: ^spectacle_id)
    |> order_by(asc: :position, asc: :id)
    |> Repo.all()
  end

  def change_cue(cue \\ %Cue{}, attrs \\ %{}) do
    Cue.changeset(cue, attrs)
  end

  def get_cue!(%Spectacle{id: spectacle_id}, id) do
    Repo.get_by!(Cue, id: id, spectacle_id: spectacle_id)
  end

  def create_cue(%Spectacle{id: spectacle_id}, attrs) do
    spectacle = Repo.get!(Spectacle, spectacle_id)
    position = next_position(spectacle.id)

    result =
      %Cue{}
      |> Cue.changeset(
        attrs
        |> Map.new(fn {k, v} -> {to_string(k), v} end)
        |> Map.merge(%{"spectacle_id" => spectacle.id, "position" => position})
      )
      |> Repo.insert()

    with {:ok, cue} <- result do
      maybe_arm(spectacle, cue)
      diffuser(spectacle.id, :conducteur, cue.id)
      {:ok, cue}
    end
  end

  def update_cue(%Cue{} = cue, attrs) do
    case cue |> Cue.changeset(attrs) |> Repo.update() do
      {:ok, cue} ->
        diffuser(cue.spectacle_id, :conducteur, cue.id)
        {:ok, cue}

      other ->
        other
    end
  end

  def delete_cue(%Cue{} = cue) do
    spectacle = Repo.get!(Spectacle, cue.spectacle_id)

    Repo.transaction(fn ->
      Repo.delete!(cue)

      if spectacle.cue_courant_id == cue.id do
        suivant = first_pending(spectacle.id) || last_cue(spectacle.id)

        spectacle
        |> Ecto.Changeset.change(%{cue_courant_id: suivant && suivant.id})
        |> Repo.update!()
      end

      :ok
    end)

    diffuser(spectacle.id, :conducteur, nil)
    :ok
  end

  def move_cue(%Cue{} = cue, direction) when direction in [:up, :down] do
    voisin = voisin(cue, direction)

    if voisin do
      Repo.transaction(fn ->
        cue_pos = cue.position
        voisin_pos = voisin.position
        Repo.update!(Ecto.Changeset.change(cue, %{position: -1}))
        Repo.update!(Ecto.Changeset.change(voisin, %{position: cue_pos}))
        Repo.update!(Ecto.Changeset.change(cue, %{position: voisin_pos}))
      end)

      diffuser(cue.spectacle_id, :conducteur, cue.id)
      {:ok, cue}
    else
      {:error, :bord}
    end
  end

  def etat_plateau(%Spectacle{} = spectacle) do
    cues = list_cues(spectacle)
    courant = Enum.find(cues, &(&1.id == spectacle.cue_courant_id))

    index =
      if courant do
        Enum.find_index(cues, &(&1.id == courant.id))
      end

    suivants = if index, do: Enum.slice(cues, index + 1, 3), else: []

    precedents =
      if index do
        cues |> Enum.slice(0, index) |> Enum.take(-2)
      else
        []
      end

    %{
      cues: cues,
      courant: courant,
      suivants: suivants,
      precedents: precedents,
      total: length(cues),
      rang: if(index, do: index + 1, else: nil)
    }
  end

  def preparer(%Spectacle{id: id}, user), do: agir(id, user, :prepare)
  def appeler_top(%Spectacle{id: id}, user), do: agir(id, user, :top)

  def rappeler(%Spectacle{id: id}, user) do
    result =
      Repo.transaction(fn ->
        spectacle = Repo.get!(Spectacle, id)
        fait = derniere_cue(spectacle.id, "passe")

        if is_nil(fait) do
          Repo.rollback(:rien)
        else
          if spectacle.cue_courant_id do
            from(c in Cue,
              where: c.id == ^spectacle.cue_courant_id and c.statut != "passe"
            )
            |> Repo.update_all(set: [statut: "a_venir"])
          end

          cue =
            fait
            |> Ecto.Changeset.change(%{statut: "prepare"})
            |> Repo.update!()

          spectacle
          |> Ecto.Changeset.change(%{cue_courant_id: cue.id, phase: "jeu"})
          |> Repo.update!()

          insert_appel!(spectacle, cue, user, "rappel")
          cue
        end
      end)

    diffuser_cue(result, id, :rappel)
  end

  def reprendre(%Spectacle{} = spectacle, %Cue{} = cue, user) do
    if cue.spectacle_id != spectacle.id do
      {:error, :hors_spectacle}
    else
      result =
        Repo.transaction(fn ->
          from(c in Cue, where: c.spectacle_id == ^spectacle.id and c.position < ^cue.position)
          |> Repo.update_all(set: [statut: "passe"])

          from(c in Cue, where: c.spectacle_id == ^spectacle.id and c.position >= ^cue.position)
          |> Repo.update_all(set: [statut: "a_venir"])

          cue = Repo.get!(Cue, cue.id)

          spectacle
          |> Ecto.Changeset.change(%{cue_courant_id: cue.id, phase: "jeu"})
          |> Repo.update!()

          insert_appel!(spectacle, cue, user, "reprise")
          cue
        end)

      diffuser_cue(result, spectacle.id, :reprise)
    end
  end

  def changer_phase(%Spectacle{id: id}, phase, user) when phase in ["jeu", "entracte", "clos"] do
    result =
      Repo.transaction(fn ->
        spectacle = Repo.get!(Spectacle, id)
        spectacle = spectacle |> Ecto.Changeset.change(%{phase: phase}) |> Repo.update!()
        cue = if spectacle.cue_courant_id, do: Repo.get(Cue, spectacle.cue_courant_id)
        action = phase_action(phase)
        insert_appel!(spectacle, cue, user, action)
        spectacle
      end)

    case result do
      {:ok, spectacle} ->
        event =
          case phase do
            "entracte" -> :entracte
            "jeu" -> :reprise_jeu
            "clos" -> :cloture
          end

        diffuser(id, event, spectacle.cue_courant_id)
        {:ok, spectacle}

      other ->
        other
    end
  end

  def list_appels(%Spectacle{id: id}), do: list_appels(id)

  def list_appels(spectacle_id) do
    Appel
    |> where(spectacle_id: ^spectacle_id)
    |> order_by(asc: :inserted_at, asc: :id)
    |> preload(:user)
    |> Repo.all()
  end

  def presents(spectacle_id) do
    spectacle_id
    |> topic()
    |> RideauWeb.Presence.list()
    |> Enum.map(fn {_id, %{metas: [meta | _]}} -> meta end)
    |> Enum.sort_by(& &1.nom)
  end

  defp agir(spectacle_id, user, :prepare) do
    result =
      Repo.transaction(fn ->
        spectacle = Repo.get!(Spectacle, spectacle_id)

        cond do
          spectacle.phase == "clos" ->
            Repo.rollback(:clos)

          is_nil(spectacle.cue_courant_id) ->
            Repo.rollback(:vide)

          true ->
            cue = Repo.get!(Cue, spectacle.cue_courant_id)
            cue = cue |> Ecto.Changeset.change(%{statut: "prepare"}) |> Repo.update!()
            insert_appel!(spectacle, cue, user, "prepare")
            cue
        end
      end)

    diffuser_cue(result, spectacle_id, :prepare)
  end

  defp agir(spectacle_id, user, :top) do
    result =
      Repo.transaction(fn ->
        spectacle = Repo.get!(Spectacle, spectacle_id)

        cond do
          spectacle.phase == "clos" ->
            Repo.rollback(:clos)

          is_nil(spectacle.cue_courant_id) ->
            Repo.rollback(:vide)

          true ->
            cue = Repo.get!(Cue, spectacle.cue_courant_id)
            cue = cue |> Ecto.Changeset.change(%{statut: "passe"}) |> Repo.update!()

            suivant =
              Cue
              |> where([c], c.spectacle_id == ^spectacle.id and c.position > ^cue.position)
              |> order_by(asc: :position)
              |> limit(1)
              |> Repo.one()

            spectacle
            |> Ecto.Changeset.change(%{cue_courant_id: suivant && suivant.id})
            |> Repo.update!()

            insert_appel!(spectacle, cue, user, "top")
            cue
        end
      end)

    diffuser_cue(result, spectacle_id, :top)
  end

  defp maybe_arm(%Spectacle{cue_courant_id: nil} = spectacle, %Cue{} = cue) do
    spectacle
    |> Ecto.Changeset.change(%{cue_courant_id: cue.id})
    |> Repo.update!()
  end

  defp maybe_arm(%Spectacle{}, %Cue{}), do: :ok

  defp next_position(spectacle_id) do
    (Repo.aggregate(from(c in Cue, where: c.spectacle_id == ^spectacle_id), :max, :position) || 0) +
      1
  end

  defp first_pending(spectacle_id) do
    Cue
    |> where([c], c.spectacle_id == ^spectacle_id and c.statut != "passe")
    |> order_by(asc: :position)
    |> limit(1)
    |> Repo.one()
  end

  defp last_cue(spectacle_id) do
    Cue
    |> where(spectacle_id: ^spectacle_id)
    |> order_by(desc: :position)
    |> limit(1)
    |> Repo.one()
  end

  defp derniere_cue(spectacle_id, statut) do
    Cue
    |> where(spectacle_id: ^spectacle_id, statut: ^statut)
    |> order_by(desc: :position)
    |> limit(1)
    |> Repo.one()
  end

  defp voisin(%Cue{} = cue, :up) do
    Cue
    |> where([c], c.spectacle_id == ^cue.spectacle_id and c.position < ^cue.position)
    |> order_by(desc: :position)
    |> limit(1)
    |> Repo.one()
  end

  defp voisin(%Cue{} = cue, :down) do
    Cue
    |> where([c], c.spectacle_id == ^cue.spectacle_id and c.position > ^cue.position)
    |> order_by(asc: :position)
    |> limit(1)
    |> Repo.one()
  end

  defp insert_appel!(spectacle, cue, user, action) do
    {libelle, departement, cue_id} =
      case cue do
        %Cue{} = cue ->
          {"#{cue.numero} · #{cue.intitule}", cue.departement, cue.id}

        nil ->
          {libelle_phase(action), "regie", nil}
      end

    %Appel{}
    |> Appel.changeset(%{
      spectacle_id: spectacle.id,
      cue_id: cue_id,
      user_id: user.id,
      action: action,
      libelle: libelle,
      departement: departement
    })
    |> Repo.insert!()
  end

  defp phase_action("entracte"), do: "entracte"
  defp phase_action("jeu"), do: "reprise_jeu"
  defp phase_action("clos"), do: "cloture"

  defp libelle_phase("entracte"), do: "Entracte"
  defp libelle_phase("reprise_jeu"), do: "On reprend"
  defp libelle_phase("cloture"), do: "Représentation close"
  defp libelle_phase(other), do: other

  defp diffuser_cue({:ok, %Cue{} = cue}, spectacle_id, event) do
    diffuser(spectacle_id, event, cue.id)
    {:ok, cue}
  end

  defp diffuser_cue({:error, reason}, _spectacle_id, _event), do: {:error, reason}

  defp diffuser(spectacle_id, event, cue_id) do
    Phoenix.PubSub.broadcast(Rideau.PubSub, topic(spectacle_id), {:plateau, event, cue_id})
  end
end

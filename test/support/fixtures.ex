defmodule Rideau.Fixtures do
  @moduledoc false

  alias Rideau.Accounts.{Compagnie, User}
  alias Rideau.Conduite
  alias Rideau.Repo

  def compagnie_fixture(attrs \\ %{}) do
    nom = Map.get(attrs, :nom, "Compagnie #{System.unique_integer([:positive])}")

    %Compagnie{}
    |> Compagnie.changeset(%{nom: nom, plan: "essai", credits: Map.get(attrs, :credits, 1)})
    |> Repo.insert!()
  end

  def user_fixture(compagnie, attrs \\ %{}) do
    n = System.unique_integer([:positive])

    %User{}
    |> User.changeset(%{
      nom: attrs[:nom] || "Régie #{n}",
      email: attrs[:email] || "regie-#{n}@exemple.fr",
      password: attrs[:password] || "motdepasse",
      role: attrs[:role] || "regie",
      departement: attrs[:departement],
      compagnie_id: compagnie.id
    })
    |> Repo.insert!()
    |> Repo.preload(:compagnie)
  end

  def spectacle_fixture(compagnie, attrs \\ %{}) do
    {:ok, spectacle} =
      Conduite.create_spectacle(compagnie, %{
        "titre" => attrs[:titre] || "Spectacle #{System.unique_integer([:positive])}",
        "salle" => "Salle test",
        "ville" => "Lyon"
      })

    spectacle
  end

  def cue_fixture(spectacle, attrs \\ %{}) do
    n = System.unique_integer([:positive])

    {:ok, cue} =
      Conduite.create_cue(spectacle, %{
        "numero" => attrs[:numero] || Integer.to_string(n),
        "departement" => attrs[:departement] || "son",
        "intitule" => attrs[:intitule] || "Cue #{n}",
        "note" => attrs[:note]
      })

    cue
  end

  def plateau_fixture do
    compagnie = compagnie_fixture()
    regie = user_fixture(compagnie, %{nom: "Aurel"})

    son =
      user_fixture(compagnie, %{
        nom: "Nour",
        role: "poste",
        departement: "son",
        email: "nour-#{System.unique_integer([:positive])}@exemple.fr"
      })

    spectacle = spectacle_fixture(compagnie, %{titre: "Le Bal"})

    cue_son =
      cue_fixture(spectacle, %{numero: "1", departement: "son", intitule: "Souffle de salle"})

    cue_lumiere =
      cue_fixture(spectacle, %{numero: "2", departement: "lumiere", intitule: "Découverte"})

    spectacle = Rideau.Repo.get!(Rideau.Conduite.Spectacle, spectacle.id)

    %{
      compagnie: compagnie,
      regie: regie,
      son: son,
      spectacle: spectacle,
      cue_son: cue_son,
      cue_lumiere: cue_lumiere
    }
  end
end

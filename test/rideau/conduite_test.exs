defmodule Rideau.ConduiteTest do
  use Rideau.DataCase, async: false

  alias Rideau.{Accounts, Conduite}

  test "préparez puis top avance le conducteur et s'écrit dans la feuille" do
    %{spectacle: spectacle, regie: regie, cue_son: cue_son} = plateau_fixture()
    Conduite.subscribe(spectacle.id)

    assert {:ok, prepare} = Conduite.preparer(spectacle, regie)
    assert prepare.statut == "prepare"
    assert_receive {:plateau, :prepare, id} when id == cue_son.id

    assert {:ok, appele} = Conduite.appeler_top(spectacle, regie)
    assert appele.statut == "passe"
    assert_receive {:plateau, :top, _}

    spectacle = Rideau.Repo.get!(Conduite.Spectacle, spectacle.id)
    assert spectacle.cue_courant_id != cue_son.id

    feuille = Conduite.list_appels(spectacle)
    assert Enum.map(feuille, & &1.action) == ["prepare", "top"]
    assert hd(Enum.reverse(feuille)).libelle =~ "Souffle"
  end

  test "le rappel ramène la dernière cue appelée en préparez" do
    %{spectacle: spectacle, regie: regie, cue_son: cue_son} = plateau_fixture()
    assert {:ok, _} = Conduite.appeler_top(spectacle, regie)
    assert {:ok, ramene} = Conduite.rappeler(spectacle, regie)
    assert ramene.id == cue_son.id
    assert ramene.statut == "prepare"

    spectacle = Rideau.Repo.get!(Conduite.Spectacle, spectacle.id)
    assert spectacle.cue_courant_id == cue_son.id
  end

  test "l'essai refuse un deuxième spectacle, la saison l'accepte" do
    compagnie = compagnie_fixture()
    regie = user_fixture(compagnie)
    assert {:ok, _} = Conduite.create_spectacle(compagnie, %{"titre" => "Premier"})
    assert {:error, :quota} = Conduite.create_spectacle(compagnie, %{"titre" => "Second"})

    assert {:ok, saison} = Accounts.souscrire(compagnie, regie, "saison")
    assert saison.plan == "saison"
    assert {:ok, second} = Conduite.create_spectacle(saison, %{"titre" => "Second"})
    assert second.titre == "Second"
  end

  test "la soirée ajoute un crédit sans passer en saison" do
    compagnie = compagnie_fixture()
    regie = user_fixture(compagnie)
    assert {:ok, _} = Conduite.create_spectacle(compagnie, %{"titre" => "Premier"})
    assert {:ok, apres} = Accounts.souscrire(compagnie, regie, "soiree")
    assert apres.plan == "essai"
    assert apres.credits == 2
    assert {:ok, _} = Conduite.create_spectacle(apres, %{"titre" => "Date unique"})
  end

  test "une représentation close n'accepte plus de top" do
    %{spectacle: spectacle, regie: regie} = plateau_fixture()
    assert {:ok, clos} = Conduite.changer_phase(spectacle, "clos", regie)
    assert clos.phase == "clos"
    assert {:error, :clos} = Conduite.appeler_top(clos, regie)
  end
end

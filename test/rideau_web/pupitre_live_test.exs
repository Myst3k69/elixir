defmodule RideauWeb.PupitreLiveTest do
  use RideauWeb.ConnCase, async: false

  test "le top de la régie arrive sur le poste son", %{conn: conn} do
    %{spectacle: spectacle, regie: regie, son: son} = plateau_fixture()

    {:ok, pupitre, _html} = live(log_in(conn, regie), ~p"/spectacles/#{spectacle.id}/pupitre")

    {:ok, poste, _html} =
      live(log_in(build_conn(), son), ~p"/spectacles/#{spectacle.id}/poste/son")

    assert render(pupitre) =~ "Souffle de salle"
    assert render(poste) =~ "Souffle de salle"

    render_click(pupitre, "preparer")
    assert render(poste) =~ "Préparez"

    render_click(pupitre, "appeler")
    assert render(poste) =~ "Top"
    assert render(pupitre) =~ "Découverte"
  end

  test "un poste ne conduit pas le pupitre", %{conn: conn} do
    %{spectacle: spectacle, son: son} = plateau_fixture()

    assert {:error, {:redirect, %{to: "/saison"}}} =
             live(log_in(conn, son), ~p"/spectacles/#{spectacle.id}/pupitre")
  end

  test "la saison exige une connexion", %{conn: conn} do
    assert {:error, {:redirect, %{to: "/connexion"}}} = live(conn, ~p"/saison")
  end

  test "l'essai plein montre l'offre au lieu d'un formulaire vide", %{conn: conn} do
    compagnie = compagnie_fixture()
    regie = user_fixture(compagnie)
    assert {:ok, _} = Rideau.Conduite.create_spectacle(compagnie, %{"titre" => "Déjà là"})

    {:ok, view, _html} = live(log_in(conn, regie), ~p"/spectacles/nouveau")
    html = render(view)
    assert html =~ "essai est plein"
    assert html =~ "Voir les offres"
    refute html =~ "Enregistrer la fiche"
  end

  test "la connexion refuse un mot de passe faux", %{conn: conn} do
    compagnie = compagnie_fixture()
    user = user_fixture(compagnie, %{email: "lea@exemple.fr", password: "motdepasse"})

    conn =
      post(conn, ~p"/connexion", %{
        "user" => %{"email" => user.email, "password" => "mauvais-mot"}
      })

    assert redirected_to(conn) == "/connexion"
    assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "incorrect"
  end
end

alias Rideau.Accounts.{Compagnie, User}
alias Rideau.Conduite
alias Rideau.Repo

if Rideau.Accounts.get_user_by_email("aurel@quai-des-brumes.fr") do
  IO.puts("Démo déjà en place — rien à réécrire.")
else
  compagnie =
    %Compagnie{}
    |> Compagnie.changeset(%{
      nom: "Compagnie du Quai des Brumes",
      plan: "essai",
      credits: 1,
      demonstration: true
    })
    |> Repo.insert!()

  aurel =
    %User{}
    |> User.changeset(%{
      nom: "Aurel",
      email: "aurel@quai-des-brumes.fr",
      password: "rideau-rouge",
      role: "regie",
      compagnie_id: compagnie.id
    })
    |> Repo.insert!()

  for membre <- [
        %{
          nom: "Camille",
          email: "camille@quai-des-brumes.fr",
          password: "poursuite",
          departement: "lumiere"
        },
        %{
          nom: "Nour",
          email: "nour@quai-des-brumes.fr",
          password: "casque-son",
          departement: "son"
        }
      ] do
    %User{}
    |> User.changeset(Map.merge(membre, %{role: "poste", compagnie_id: compagnie.id}))
    |> Repo.insert!()
  end

  {:ok, spectacle} =
    Conduite.create_spectacle(compagnie, %{
      "titre" => "Le Bal des Ombres",
      "sous_titre" => "Pièce en un acte",
      "auteur" => "texte original écrit pour RIDEAU",
      "salle" => "Théâtre des Chartreux",
      "ville" => "Marseille",
      "prochaine_le" => Date.add(Date.utc_today(), 3)
    })

  Conduite.mark_demonstration(spectacle)

  cues = [
    %{
      "numero" => "1",
      "departement" => "plateau",
      "intitule" => "Ouverture de toile, lente",
      "note" =>
        "Deux mains, pas de à-coup. On s'arrête à mi-hauteur si Irène n'est pas en place.",
      "repere" => "Noir salle"
    },
    %{
      "numero" => "2",
      "departement" => "lumiere",
      "intitule" => "Découverte ambre cour",
      "note" => "Face froide jardin à 30 %. Le cyclorama reste éteint.",
      "repere" => "Toile à mi-hauteur"
    },
    %{
      "numero" => "3",
      "departement" => "son",
      "intitule" => "Souffle de salle",
      "note" => "Très bas, presque un doute. Pas de musique.",
      "repere" => "Avec la découverte"
    },
    %{
      "numero" => "4",
      "departement" => "comedien",
      "intitule" => "Entrée Irène",
      "note" => "Elle ne parle pas. Manteau rouge boutonné.",
      "repere" => "Jardin, dans le noir"
    },
    %{
      "numero" => "5",
      "departement" => "lumiere",
      "intitule" => "Poursuite sur le manteau",
      "note" => "Pas de plein feu. On lit le rouge, pas le visage.",
      "repere" => "Trois pas après l'entrée"
    },
    %{
      "numero" => "6",
      "departement" => "son",
      "intitule" => "Horloge désaccordée",
      "note" => "Trois coups, irréguliers. Le troisième plus loin.",
      "repere" => "Elle s'arrête"
    },
    %{
      "numero" => "7",
      "departement" => "plateau",
      "intitule" => "Chaise au centre, à vue",
      "note" => "Le plateau entre, pose, sort. Pas de salut.",
      "repere" => "Après le troisième coup"
    },
    %{
      "numero" => "8",
      "departement" => "lumiere",
      "intitule" => "Noir progressif, 8 secondes",
      "note" => "On garde uniquement la poursuite. Compter à voix haute en régie.",
      "repere" => "Elle s'assoit"
    },
    %{
      "numero" => "9",
      "departement" => "son",
      "intitule" => "Verre brisé, off",
      "note" => "Un seul. Cour, pas au-dessus de la tête.",
      "repere" => "Fin du noir"
    },
    %{
      "numero" => "10",
      "departement" => "comedien",
      "intitule" => "Réplique d'Irène",
      "note" => "« Ce n'est pas ma maison. » Ne pas enchaîner si le rire tient.",
      "repere" => "Après le verre"
    },
    %{
      "numero" => "11",
      "departement" => "video",
      "intitule" => "Ombre sur le cyclorama",
      "note" => "La silhouette est plus grande qu'Irène. Entrée par la gauche de l'image.",
      "repere" => "Sur la fin de la réplique"
    },
    %{
      "numero" => "12",
      "departement" => "lumiere",
      "intitule" => "Retour général, plus froid",
      "note" => "On casse l'ambre. La poursuite meurt en quatre secondes.",
      "repere" => "L'ombre est en place"
    },
    %{
      "numero" => "13",
      "departement" => "son",
      "intitule" => "Pluie sur la verrière",
      "note" => "Montée en dix secondes. On reste sous la voix.",
      "repere" => "Avec le retour général"
    },
    %{
      "numero" => "14",
      "departement" => "plateau",
      "intitule" => "Volet jardin",
      "note" => "Fermeture franche. Le claquement est voulu.",
      "repere" => "Sur le mot « dehors »"
    },
    %{
      "numero" => "15",
      "departement" => "lumiere",
      "intitule" => "Noir franc",
      "note" => "Tout, y compris la sortie de secours si la salle le permet.",
      "repere" => "Fin de la pluie"
    },
    %{
      "numero" => "16",
      "departement" => "son",
      "intitule" => "Note tenue, violoncelle",
      "note" => "Une note, pas une phrase. Elle meurt sous le rideau.",
      "repere" => "Dans le noir"
    },
    %{
      "numero" => "17",
      "departement" => "plateau",
      "intitule" => "Rideau, rapide",
      "note" => "Plus vite que l'ouverture. On ne reprend pas si quelqu'un est dans le passage.",
      "repere" => "Sous la note"
    },
    %{
      "numero" => "18",
      "departement" => "lumiere",
      "intitule" => "Rappels",
      "note" => "Chaud, face salle, pas de poursuite. On attend le top de régie.",
      "repere" => "Toile fermée"
    }
  ]

  Enum.each(cues, fn attrs ->
    {:ok, _} = Conduite.create_cue(spectacle, attrs)
  end)

  IO.puts("""
  Démo RIDEAU prête.
  Régie   aurel@quai-des-brumes.fr   / rideau-rouge
  Lumière camille@quai-des-brumes.fr / poursuite
  Son     nour@quai-des-brumes.fr    / casque-son
  Spectacle : Le Bal des Ombres (#{aurel.nom})
  """)
end

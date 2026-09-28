# RIDEAU

Pupitre de conduite pour le spectacle vivant.

La régie prépare, dit **top**, et chaque poste — lumière, son, plateau, comédiens, vidéo — reçoit le même appel au même instant. Phoenix LiveView et PubSub tiennent la liaison. La présence montre qui est en ligne. Si la liaison tombe, l'écran le dit : un top qui ne part pas doit se voir.

## Pour qui

La régisseuse générale d'une compagnie indépendante, le soir de la représentation. L'essai conduit **un** spectacle. On paie une **soirée** (19 €, un spectacle de plus) ou la **saison** (49 € / mois, spectacles illimités) quand le deuxième spectacle de la saison est annoncé.

Dans cette version, le paiement est **simulé** : aucune carte, aucun débit. L'offre est enregistrée pour de vrai sur la compagnie.

## Lancer

Elixir 1.17 ou plus récent, OTP, et SQLite.

```bash
mix setup
mix phx.server
```

Ouvrir [http://localhost:4000](http://localhost:4000).

`mix setup` crée la base, joue les migrations, écrit la démo et compile les assets.

## Démo en trois minutes

1. Sur l'accueil, entrer en régie.
2. Choisir **Aurel · Régie** (ou `aurel@quai-des-brumes.fr` / `rideau-rouge`).
3. Ouvrir **Le Bal des Ombres**, puis le **pupitre**.
4. Dans un autre onglet, le poste **Lumière** avec Camille (`camille@quai-des-brumes.fr` / `poursuite`) ou le poste **Son** avec Nour (`nour@quai-des-brumes.fr` / `casque-son`). On peut aussi ouvrir un poste sans changer de compte : la régie voit tous les postes.
5. Au pupitre : **Préparez**, puis **Top** (ou les touches `P` et `T`). Le poste concerné s'allume. La **feuille** de soirée prend l'heure.
6. Revenir à la saison et **ouvrir un spectacle** : l'essai est plein. L'offre **Saison** (paiement simulé) lève la limite.

Le spectacle et la compagnie semés sont marqués comme démonstration. Le conducteur est un texte original, pas une production réelle.

## Tests

```bash
mix test
```

Le parcours critique : préparer, envoyer le top, le voir arriver sur l'autre LiveView, bloquer un deuxième spectacle tant que l'essai n'est pas levé.

## Limites

- Paiement simulé, pas de prestataire.
- Pas d'e-mail (pas de confirmation, pas de mot de passe oublié).
- Une compagnie par compte, interface en français.

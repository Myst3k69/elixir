defmodule RideauWeb.ProgrammeLive do
  use RideauWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "Le pupitre de conduite")}
  end

  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_user={@current_user} tone="paper">
      <main class="programme">
        <section class="une">
          <p class="kicker">Pupitre de conduite · spectacle vivant</p>
          <h1>Le top part de la régie. <em>Tout le plateau l'entend.</em></h1>
          <p class="chapo">
            RIDEAU est le pupitre des compagnies qui jouent ce soir. On prépare, on dit top,
            la lumière, le son et le plateau reçoivent le même appel, au même instant —
            sur l'ordinateur de régie comme sur le téléphone des coulisses.
          </p>
          <div class="actions">
            <.link :if={!@current_user} navigate={~p"/connexion"} class="bouton bouton-sang">
              Entrer en régie
            </.link>
            <.link :if={@current_user} navigate={~p"/saison"} class="bouton bouton-sang">
              Ouvrir la saison
            </.link>
            <.link navigate={~p"/offre"} class="bouton bouton-encre">Voir l'offre</.link>
          </div>
          <div class="tenture" aria-hidden="true">
            <div class="panneau panneau-gauche"></div>
            <div class="fente"></div>
            <div class="panneau panneau-droit"></div>
          </div>
        </section>

        <section class="mesures" aria-label="Les trois temps de l'appel">
          <article>
            <p class="numero">01</p>
            <h2>Préparez</h2>
            <p>
              La cue en cours passe en attente. Le poste concerné s'allume en ambre.
              Les autres voient que ce n'est pas à eux.
            </p>
          </article>
          <article>
            <p class="numero">02</p>
            <h2>Top</h2>
            <p>
              Un seul geste, au clavier ou au doigt. Le top est écrit dans la feuille
              de soirée et diffusé à tous les postes reliés.
            </p>
          </article>
          <article>
            <p class="numero">03</p>
            <h2>Le poste</h2>
            <p>
              Lumière, son, plateau, comédiens, vidéo : chacun suit son extrait du
              conducteur, en grand, lisible dans le noir.
            </p>
          </article>
        </section>

        <section class="apercu" aria-label="Aperçu du pupitre">
          <div class="apercu-texte">
            <p class="kicker">L'instrument</p>
            <h2>Un pupitre, pas un tableau de bord.</h2>
            <p>
              La régisseuse générale conduit depuis un coin noir, souvent avec un
              conducteur annoté au crayon et des talkies qui se marchent dessus.
              RIDEAU garde la feuille dans l'ordre, appelle le top, et montre qui est
              en ligne : régie, lumière, son.
            </p>
            <p>
              Si la liaison tombe, l'écran le dit tout de suite. Un top qui ne part
              pas doit se voir.
            </p>
          </div>
          <div class="maquette" aria-hidden="true">
            <p class="maquette-kicker">À appeler · 08 / 18</p>
            <p class="maquette-dept">Lumière</p>
            <p class="maquette-numero">08</p>
            <p class="maquette-titre">Noir progressif, 8 secondes</p>
            <p class="maquette-note">On garde uniquement la poursuite.</p>
            <div class="maquette-touches">
              <span>Préparez</span>
              <span class="top">Top</span>
            </div>
          </div>
        </section>

        <section class="offre-bande">
          <div>
            <p class="kicker">Quand on paie</p>
            <h2>L'essai conduit un spectacle. La saison conduit la compagnie.</h2>
          </div>
          <div class="prix">
            <article>
              <h3>Soirée</h3>
              <p class="montant">19 €</p>
              <p>Un spectacle de plus. Pour une date unique, une lecture, une reprise.</p>
            </article>
            <article class="prix-fort">
              <h3>Saison</h3>
              <p class="montant">49 € <span>/ mois</span></p>
              <p>Spectacles illimités. Toute la compagnie, toute la saison.</p>
            </article>
          </div>
          <p class="note-demo">
            Dans cette version, le paiement est simulé : aucune carte, aucun débit.
            L'offre est enregistrée pour de vrai sur la compagnie, afin de montrer le parcours.
          </p>
          <.link navigate={~p"/offre"} class="bouton bouton-or">Lire l'offre en détail</.link>
        </section>

        <footer class="colophon">
          <p>RIDEAU · le pupitre qui dit top.</p>
          <p>Écrit pour la régie générale du spectacle vivant.</p>
        </footer>
      </main>
    </Layouts.app>
    """
  end
end

defmodule RideauWeb.Router do
  use RideauWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {RideauWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", RideauWeb do
    pipe_through :browser

    live_session :public, on_mount: [{RideauWeb.UserAuth, :mount_current_user}] do
      live "/", ProgrammeLive
      live "/offre", OffreLive
    end

    live_session :guest, on_mount: [{RideauWeb.UserAuth, :redirect_if_authenticated}] do
      live "/connexion", ConnexionLive
      live "/inscription", InscriptionLive
    end

    post "/connexion", SessionController, :create
    post "/inscription", InscriptionController, :create
    delete "/deconnexion", SessionController, :delete

    live_session :plateau, on_mount: [{RideauWeb.UserAuth, :ensure_authenticated}] do
      live "/saison", SaisonLive
      live "/compte", CompteLive
      live "/spectacles/nouveau", SpectacleFormLive, :new
      live "/spectacles/:id", ConducteurLive
      live "/spectacles/:id/fiche", SpectacleFormLive, :edit
      live "/spectacles/:id/pupitre", PupitreLive
      live "/spectacles/:id/poste/:departement", PosteLive
      live "/spectacles/:id/rapport", RapportLive
    end
  end
end

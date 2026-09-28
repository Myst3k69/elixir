defmodule Rideau.Conduite.Appel do
  use Ecto.Schema
  import Ecto.Changeset

  schema "appels" do
    field :action, :string
    field :libelle, :string
    field :departement, :string

    belongs_to :spectacle, Rideau.Conduite.Spectacle
    belongs_to :cue, Rideau.Conduite.Cue
    belongs_to :user, Rideau.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(appel, attrs) do
    appel
    |> cast(attrs, [:action, :libelle, :departement, :spectacle_id, :cue_id, :user_id])
    |> validate_required([:action, :libelle, :departement, :spectacle_id, :user_id],
      message: "doit être rempli"
    )
    |> validate_inclusion(:action, ~w(prepare top rappel reprise entracte reprise_jeu cloture))
  end
end

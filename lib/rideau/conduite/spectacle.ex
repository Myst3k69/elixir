defmodule Rideau.Conduite.Spectacle do
  use Ecto.Schema
  import Ecto.Changeset

  schema "spectacles" do
    field :titre, :string
    field :sous_titre, :string
    field :auteur, :string
    field :salle, :string
    field :ville, :string
    field :prochaine_le, :date
    field :phase, :string, default: "jeu"
    field :cue_courant_id, :id
    field :demonstration, :boolean, default: false

    belongs_to :compagnie, Rideau.Accounts.Compagnie
    has_many :cues, Rideau.Conduite.Cue
    has_many :appels, Rideau.Conduite.Appel

    timestamps(type: :utc_datetime)
  end

  def changeset(spectacle, attrs) do
    spectacle
    |> cast(attrs, [:titre, :sous_titre, :auteur, :salle, :ville, :prochaine_le])
    |> validate_required([:titre], message: "doit être rempli")
    |> validate_length(:titre, min: 2, max: 120, message: "doit faire entre 2 et 120 caractères")
    |> validate_length(:sous_titre, max: 160)
    |> validate_length(:auteur, max: 120)
    |> validate_length(:salle, max: 120)
    |> validate_length(:ville, max: 80)
  end
end

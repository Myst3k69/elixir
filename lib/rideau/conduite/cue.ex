defmodule Rideau.Conduite.Cue do
  use Ecto.Schema
  import Ecto.Changeset

  schema "cues" do
    field :position, :integer
    field :numero, :string
    field :departement, :string
    field :intitule, :string
    field :note, :string
    field :repere, :string
    field :statut, :string, default: "a_venir"

    belongs_to :spectacle, Rideau.Conduite.Spectacle

    timestamps(type: :utc_datetime)
  end

  def changeset(cue, attrs) do
    cue
    |> cast(attrs, [:numero, :departement, :intitule, :note, :repere, :spectacle_id, :position])
    |> validate_required([:numero, :departement, :intitule, :spectacle_id, :position],
      message: "doit être rempli"
    )
    |> validate_length(:numero, min: 1, max: 12)
    |> validate_length(:intitule,
      min: 2,
      max: 160,
      message: "doit faire entre 2 et 160 caractères"
    )
    |> validate_length(:note, max: 400)
    |> validate_length(:repere, max: 120)
    |> validate_inclusion(:departement, Rideau.Departement.codes(),
      message: "n'est pas un poste du plateau"
    )
    |> validate_inclusion(:statut, ["a_venir", "prepare", "passe"])
  end
end

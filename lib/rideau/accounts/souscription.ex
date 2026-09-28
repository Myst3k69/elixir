defmodule Rideau.Accounts.Souscription do
  use Ecto.Schema
  import Ecto.Changeset

  schema "souscriptions" do
    field :plan, :string
    field :montant_centimes, :integer
    field :mode, :string, default: "simule"
    field :libelle, :string

    belongs_to :compagnie, Rideau.Accounts.Compagnie
    belongs_to :user, Rideau.Accounts.User

    timestamps(type: :utc_datetime)
  end

  def changeset(souscription, attrs) do
    souscription
    |> cast(attrs, [:plan, :montant_centimes, :mode, :libelle, :compagnie_id, :user_id])
    |> validate_required([:plan, :montant_centimes, :mode, :libelle, :compagnie_id, :user_id],
      message: "doit être rempli"
    )
    |> validate_inclusion(:plan, ["soiree", "saison"])
    |> validate_inclusion(:mode, ["simule"])
  end
end

defmodule Rideau.Accounts.Compagnie do
  use Ecto.Schema
  import Ecto.Changeset

  schema "compagnies" do
    field :nom, :string
    field :plan, :string, default: "essai"
    field :credits, :integer, default: 1
    field :demonstration, :boolean, default: false

    has_many :users, Rideau.Accounts.User
    has_many :spectacles, Rideau.Conduite.Spectacle
    has_many :souscriptions, Rideau.Accounts.Souscription

    timestamps(type: :utc_datetime)
  end

  def changeset(compagnie, attrs) do
    compagnie
    |> cast(attrs, [:nom, :plan, :credits, :demonstration])
    |> validate_required([:nom, :plan, :credits], message: "doit être rempli")
    |> validate_length(:nom, min: 2, max: 80, message: "doit faire entre 2 et 80 caractères")
    |> validate_inclusion(:plan, ["essai", "saison"], message: "n'est pas une offre connue")
    |> validate_number(:credits, greater_than_or_equal_to: 0)
  end
end

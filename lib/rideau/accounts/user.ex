defmodule Rideau.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :nom, :string
    field :email, :string
    field :hashed_password, :string, redact: true
    field :password, :string, virtual: true, redact: true
    field :role, :string, default: "regie"
    field :departement, :string

    belongs_to :compagnie, Rideau.Accounts.Compagnie

    timestamps(type: :utc_datetime)
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:nom, :email, :password, :role, :departement, :compagnie_id])
    |> update_change(:email, fn email ->
      email |> to_string() |> String.trim() |> String.downcase()
    end)
    |> validate_required([:nom, :email, :password, :role, :compagnie_id],
      message: "doit être rempli"
    )
    |> validate_length(:nom, min: 2, max: 80, message: "doit faire entre 2 et 80 caractères")
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "n'est pas une adresse")
    |> validate_length(:password, min: 8, max: 72, message: "doit faire au moins 8 caractères")
    |> validate_inclusion(:role, ["regie", "poste"], message: "n'est pas un rôle connu")
    |> validate_departement()
    |> unique_constraint(:email, message: "est déjà utilisé")
    |> hash_password()
  end

  defp validate_departement(changeset) do
    if get_field(changeset, :role) == "poste" do
      changeset
      |> validate_required([:departement], message: "doit être choisi")
      |> validate_inclusion(:departement, Rideau.Departement.codes(),
        message: "n'est pas un poste du plateau"
      )
    else
      put_change(changeset, :departement, nil)
    end
  end

  defp hash_password(changeset) do
    password = get_change(changeset, :password)

    if password && changeset.valid? do
      put_change(changeset, :hashed_password, Bcrypt.hash_pwd_salt(password))
    else
      changeset
    end
  end
end

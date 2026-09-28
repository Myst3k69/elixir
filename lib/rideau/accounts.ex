defmodule Rideau.Accounts do
  @moduledoc """
  Compagnies, comptes du plateau, et offres (essai, soirée, saison).
  Le paiement est simulé : on enregistre l'offre, on ne débite personne.
  """

  import Ecto.Query
  alias Rideau.Accounts.{Compagnie, Souscription, User}
  alias Rideau.Repo

  @offres %{
    "soiree" => %{
      montant_centimes: 1900,
      libelle: "Soirée — un spectacle de plus. Paiement simulé, aucun débit."
    },
    "saison" => %{
      montant_centimes: 4900,
      libelle: "Saison — spectacles illimités. Paiement simulé, aucun débit."
    }
  }

  def offre(plan) when plan in ["soiree", "saison"], do: Map.fetch!(@offres, plan)

  def get_user(id) when is_integer(id) do
    User |> Repo.get(id) |> preload_compagnie()
  end

  def get_user(_), do: nil

  def get_user_by_email(email) when is_binary(email) do
    User
    |> Repo.get_by(email: email |> String.trim() |> String.downcase())
    |> preload_compagnie()
  end

  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = get_user_by_email(email)

    if user && Bcrypt.verify_pass(password, user.hashed_password) do
      user
    else
      Bcrypt.no_user_verify()
      nil
    end
  end

  def regie?(%User{role: "regie"}), do: true
  def regie?(_), do: false

  def list_membres(compagnie_id) do
    User
    |> where(compagnie_id: ^compagnie_id)
    |> order_by([u], asc: u.nom)
    |> Repo.all()
  end

  def list_souscriptions(compagnie_id) do
    Souscription
    |> where(compagnie_id: ^compagnie_id)
    |> order_by([s], desc: s.inserted_at)
    |> preload(:user)
    |> Repo.all()
  end

  def change_inscription(attrs \\ %{}) do
    {%{}, %{nom: :string, email: :string, password: :string, nom_compagnie: :string}}
    |> Ecto.Changeset.cast(attrs, [:nom, :email, :password, :nom_compagnie])
    |> Ecto.Changeset.validate_required([:nom, :email, :password, :nom_compagnie],
      message: "doit être rempli"
    )
    |> Ecto.Changeset.validate_length(:nom, min: 2, max: 80)
    |> Ecto.Changeset.validate_length(:nom_compagnie, min: 2, max: 80)
    |> Ecto.Changeset.validate_length(:password,
      min: 8,
      max: 72,
      message: "doit faire au moins 8 caractères"
    )
    |> Ecto.Changeset.validate_format(:email, ~r/^[^\s]+@[^\s]+$/,
      message: "n'est pas une adresse"
    )
    |> Ecto.Changeset.update_change(:email, &(&1 |> String.trim() |> String.downcase()))
  end

  def register_compagnie(attrs) do
    changeset = change_inscription(attrs)

    if changeset.valid? do
      data = Ecto.Changeset.apply_changes(changeset)

      Ecto.Multi.new()
      |> Ecto.Multi.insert(:compagnie, fn _ ->
        Compagnie.changeset(%Compagnie{}, %{
          nom: data.nom_compagnie,
          plan: "essai",
          credits: 1,
          demonstration: false
        })
      end)
      |> Ecto.Multi.insert(:user, fn %{compagnie: compagnie} ->
        User.changeset(%User{}, %{
          nom: data.nom,
          email: data.email,
          password: data.password,
          role: "regie",
          compagnie_id: compagnie.id
        })
      end)
      |> Repo.transaction()
      |> case do
        {:ok, %{user: user}} -> {:ok, preload_compagnie(user)}
        {:error, :user, user_changeset, _} -> {:error, map_user_errors(changeset, user_changeset)}
        {:error, :compagnie, compagnie_changeset, _} -> {:error, compagnie_changeset}
      end
    else
      {:error, %{changeset | action: :insert}}
    end
  end

  def change_membre(attrs \\ %{}) do
    User.changeset(%User{}, attrs)
  end

  def add_membre(%Compagnie{} = compagnie, attrs) do
    attrs =
      attrs
      |> Map.new(fn {k, v} -> {to_string(k), v} end)
      |> Map.merge(%{"role" => "poste", "compagnie_id" => compagnie.id})

    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  def peut_ouvrir_spectacle?(%Compagnie{plan: "saison"}), do: true

  def peut_ouvrir_spectacle?(%Compagnie{id: id, credits: credits}) do
    Rideau.Conduite.count_spectacles(id) < credits
  end

  def souscrire(%Compagnie{} = compagnie, %User{role: "regie"} = user, plan)
      when plan in ["soiree", "saison"] do
    offre = offre(plan)

    Repo.transaction(fn ->
      compagnie = Repo.get!(Compagnie, compagnie.id)

      if compagnie.plan == "saison" do
        Repo.rollback(:deja)
      end

      compagnie =
        case plan do
          "saison" ->
            compagnie |> Ecto.Changeset.change(%{plan: "saison"}) |> Repo.update!()

          "soiree" ->
            compagnie
            |> Ecto.Changeset.change(%{credits: compagnie.credits + 1})
            |> Repo.update!()
        end

      %Souscription{}
      |> Souscription.changeset(%{
        compagnie_id: compagnie.id,
        user_id: user.id,
        plan: plan,
        montant_centimes: offre.montant_centimes,
        mode: "simule",
        libelle: offre.libelle
      })
      |> Repo.insert!()

      compagnie
    end)
  end

  def souscrire(_, _, _), do: {:error, :interdit}

  defp preload_compagnie(nil), do: nil
  defp preload_compagnie(user), do: Repo.preload(user, :compagnie)

  defp map_user_errors(form_changeset, user_changeset) do
    Enum.reduce(user_changeset.errors, form_changeset, fn {field, error}, acc ->
      Ecto.Changeset.add_error(acc, field, elem(error, 0))
    end)
    |> Map.put(:action, :insert)
  end
end

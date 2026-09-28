defmodule Rideau.Repo.Migrations.CreateRideau do
  use Ecto.Migration

  def change do
    create table(:compagnies) do
      add :nom, :string, null: false
      add :plan, :string, null: false, default: "essai"
      add :credits, :integer, null: false, default: 1
      add :demonstration, :boolean, null: false, default: false

      timestamps(type: :utc_datetime)
    end

    create table(:users) do
      add :nom, :string, null: false
      add :email, :string, null: false
      add :hashed_password, :string, null: false
      add :role, :string, null: false, default: "regie"
      add :departement, :string
      add :compagnie_id, references(:compagnies, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:users, [:email])
    create index(:users, [:compagnie_id])

    create table(:spectacles) do
      add :titre, :string, null: false
      add :sous_titre, :string
      add :auteur, :string
      add :salle, :string
      add :ville, :string
      add :prochaine_le, :date
      add :phase, :string, null: false, default: "jeu"
      add :cue_courant_id, :integer
      add :demonstration, :boolean, null: false, default: false
      add :compagnie_id, references(:compagnies, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:spectacles, [:compagnie_id])

    create table(:cues) do
      add :position, :integer, null: false
      add :numero, :string, null: false
      add :departement, :string, null: false
      add :intitule, :string, null: false
      add :note, :text
      add :repere, :string
      add :statut, :string, null: false, default: "a_venir"
      add :spectacle_id, references(:spectacles, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:cues, [:spectacle_id, :position])

    create table(:appels) do
      add :action, :string, null: false
      add :libelle, :string, null: false
      add :departement, :string, null: false
      add :spectacle_id, references(:spectacles, on_delete: :delete_all), null: false
      add :cue_id, references(:cues, on_delete: :nilify_all)
      add :user_id, references(:users), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:appels, [:spectacle_id, :inserted_at])

    create table(:souscriptions) do
      add :plan, :string, null: false
      add :montant_centimes, :integer, null: false
      add :mode, :string, null: false, default: "simule"
      add :libelle, :string, null: false
      add :compagnie_id, references(:compagnies, on_delete: :delete_all), null: false
      add :user_id, references(:users), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:souscriptions, [:compagnie_id])
  end
end

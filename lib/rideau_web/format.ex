defmodule RideauWeb.Format do
  @moduledoc false

  @months ~w(janvier février mars avril mai juin juillet août septembre octobre novembre décembre)

  def format_date(nil), do: "Date à fixer"

  def format_date(%Date{} = date) do
    "#{date.day} #{Enum.at(@months, date.month - 1)} #{date.year}"
  end

  def format_heure(nil), do: "—"

  def format_heure(%DateTime{} = datetime) do
    datetime
    |> DateTime.shift_zone!("Europe/Paris")
    |> Calendar.strftime("%H:%M:%S")
  end

  def format_prix(centimes) when is_integer(centimes) do
    "#{div(centimes, 100)} €"
  end

  def label_phase("jeu"), do: "En jeu"
  def label_phase("entracte"), do: "Entracte"
  def label_phase("clos"), do: "Clos"
  def label_phase(_), do: "—"

  def label_statut("a_venir"), do: "À venir"
  def label_statut("prepare"), do: "Préparez"
  def label_statut("passe"), do: "Passé"
  def label_statut(_), do: "—"

  def label_action("prepare"), do: "Préparez"
  def label_action("top"), do: "Top"
  def label_action("rappel"), do: "Rappel"
  def label_action("reprise"), do: "Reprise"
  def label_action("entracte"), do: "Entracte"
  def label_action("reprise_jeu"), do: "On reprend"
  def label_action("cloture"), do: "Clôture"
  def label_action(other), do: other

  def label_plan("essai"), do: "Essai"
  def label_plan("soiree"), do: "Soirée"
  def label_plan("saison"), do: "Saison"
  def label_plan(other), do: other

  def phrase_quota(%{plan: "saison"}, _count), do: "Saison active — spectacles illimités"

  def phrase_quota(%{credits: credits}, count) do
    "Essai — #{accord_spectacle(count)} ouvert sur #{credits} inclus"
  end

  defp accord_spectacle(1), do: "1 spectacle"
  defp accord_spectacle(n), do: "#{n} spectacles"
end

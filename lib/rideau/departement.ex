defmodule Rideau.Departement do
  @moduledoc """
  Postes du plateau. Les codes voyagent dans l'URL et dans la base.
  """

  @items [
    %{code: "lumiere", label: "Lumière"},
    %{code: "son", label: "Son"},
    %{code: "plateau", label: "Plateau"},
    %{code: "comedien", label: "Comédiens"},
    %{code: "video", label: "Vidéo"}
  ]

  def all, do: @items

  def codes, do: Enum.map(@items, & &1.code)

  def valid?(code), do: code in codes()

  def label(code) do
    Enum.find_value(@items, code, fn item ->
      if item.code == code, do: item.label
    end)
  end

  def options do
    Enum.map(@items, &{&1.label, &1.code})
  end
end

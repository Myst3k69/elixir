defmodule RideauWeb.Presence do
  @moduledoc """
  Qui est relié à un spectacle : régie, lumière, son, plateau.
  """
  use Phoenix.Presence,
    otp_app: :rideau,
    pubsub_server: Rideau.PubSub
end

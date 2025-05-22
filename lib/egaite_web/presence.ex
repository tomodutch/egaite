defmodule EgaiteWeb.Presence do
  use Phoenix.Presence,
    otp_app: :egaite,
    pubsub_server: Egaite.PubSub
end

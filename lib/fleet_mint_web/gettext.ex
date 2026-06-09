defmodule FleetMintWeb.Gettext do
  use Gettext.Backend, otp_app: :fleet_mint

  def gettext(msg), do: Gettext.gettext(__MODULE__, msg)
end

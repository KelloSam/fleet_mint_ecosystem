defmodule BusCashingSystemWeb.Gettext do
  use Gettext.Backend, otp_app: :bus_cashing_system

  def gettext(msg), do: Gettext.gettext(__MODULE__, msg)
end

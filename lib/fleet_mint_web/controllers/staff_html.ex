defmodule FleetMintWeb.StaffHTML do
  use FleetMintWeb, :html
  embed_templates "staff_html/*"

  def initials(user) do
    (user.full_name || user.username || "?")
    |> String.split()
    |> Enum.take(2)
    |> Enum.map(&String.first/1)
    |> Enum.join()
    |> String.upcase()
  end
end

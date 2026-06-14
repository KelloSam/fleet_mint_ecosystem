defmodule FleetMintWeb.ComplaintHTML do
  use FleetMintWeb, :html
  import Ecto.Changeset, only: [get_field: 2]
  embed_templates "complaint_html/*"
end

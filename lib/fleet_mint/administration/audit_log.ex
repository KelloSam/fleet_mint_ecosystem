defmodule FleetMint.Administration.AuditLog do
  use Ecto.Schema
  import Ecto.Changeset

  schema "audit_logs" do
    field :event,       :string
    field :actor_id,    :integer
    field :actor_email, :string
    field :target_type, :string
    field :target_id,   :string
    field :metadata,    :map, default: %{}
    field :ip_address,  :string

    # Derived server-side from the actor's own organisation at the time
    # of the event (see Administration.log/2) - never accepted as a
    # caller-supplied attr. nil means either no known actor (a failed
    # login against an unknown email) or a genuinely platform-level actor
    # - both correctly platform-only visible, never guessed into a tenant.
    belongs_to :organisation, FleetMint.Identity.Organisation

    timestamps(updated_at: false)
  end

  def changeset(log, attrs) do
    log
    |> cast(attrs, [:event, :actor_id, :actor_email, :target_type, :target_id, :metadata, :ip_address, :organisation_id])
    |> validate_required([:event])
    |> foreign_key_constraint(:organisation_id)
  end
end

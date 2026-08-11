defmodule FleetMint.Administration.Complaint do
  use Ecto.Schema
  import Ecto.Changeset

  schema "complaints" do
    field :type, :string, default: "complaint"
    field :category, :string, default: "bus_service"
    field :passenger_name, :string
    field :passenger_phone, :string
    field :booking_reference, :string
    field :staff_member_name, :string
    field :subject, :string
    field :description, :string
    field :status, :string, default: "pending"
    field :resolution_notes, :string

    belongs_to :reviewed_by, FleetMint.Identity.User

    # Derived server-side in Administration.create_complaint/1 by
    # resolving booking_reference to a real booking, never accepted as a
    # caller-supplied attr - the submission form is public/unauthenticated,
    # so letting the client set this directly would let a submitter point
    # a complaint at any organisation. nil means no resolvable booking
    # (no reference given, or it didn't match a real one) and is
    # correctly platform-only visible, not guessed into a tenant.
    belongs_to :organisation, FleetMint.Identity.Organisation

    timestamps()
  end

  @types ~w(complaint suggestion)
  @categories ~w(driver conductor bus_service punctuality other)
  @statuses ~w(pending reviewed resolved dismissed)

  def changeset(complaint, attrs) do
    complaint
    |> cast(attrs, [
      :type,
      :category,
      :passenger_name,
      :passenger_phone,
      :booking_reference,
      :staff_member_name,
      :subject,
      :description,
      :status,
      :resolution_notes,
      :reviewed_by_id
    ])
    |> validate_required([:type, :passenger_name, :description])
    |> validate_inclusion(:type, @types)
    |> validate_inclusion(:category, @categories)
    |> validate_inclusion(:status, @statuses)
    |> validate_length(:description, min: 10, max: 2000)
  end
end

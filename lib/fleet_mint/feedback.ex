defmodule FleetMint.Feedback do
  import Ecto.Query
  alias FleetMint.Repo
  alias FleetMint.Feedback.Complaint

  def list_complaints(opts \\ []) do
    Complaint
    |> maybe_filter_type(opts[:type])
    |> maybe_filter_status(opts[:status])
    |> order_by([c], desc: c.inserted_at)
    |> preload(:reviewed_by)
    |> Repo.all()
  end

  def get_complaint!(id), do: Repo.get!(Complaint, id) |> Repo.preload(:reviewed_by)

  def create_complaint(attrs \\ %{}) do
    %Complaint{} |> Complaint.changeset(attrs) |> Repo.insert()
  end

  def update_complaint(%Complaint{} = complaint, attrs) do
    complaint |> Complaint.changeset(attrs) |> Repo.update()
  end

  def delete_complaint(%Complaint{} = complaint), do: Repo.delete(complaint)

  def change_complaint(%Complaint{} = complaint, attrs \\ %{}),
    do: Complaint.changeset(complaint, attrs)

  def count_pending do
    Repo.aggregate(from(c in Complaint, where: c.status == "pending"), :count)
  end

  defp maybe_filter_type(query, nil), do: query
  defp maybe_filter_type(query, type), do: where(query, [c], c.type == ^type)

  defp maybe_filter_status(query, nil), do: query
  defp maybe_filter_status(query, status), do: where(query, [c], c.status == ^status)
end

defmodule FleetMint.Pagination do
  import Ecto.Query
  alias FleetMint.Repo

  @per_page 25

  def paginate(queryable, page, per_page \\ @per_page) do
    page = max(1, page)
    per_page = min(per_page, 100)
    offset = (page - 1) * per_page
    total = Repo.aggregate(subquery(queryable), :count)
    entries = queryable |> limit(^per_page) |> offset(^offset) |> Repo.all()

    %{
      entries: entries,
      page: page,
      per_page: per_page,
      total: total,
      total_pages: max(1, ceil(total / per_page))
    }
  end

  def parse_page(params) do
    case Integer.parse(params["page"] || "1") do
      {n, ""} when n > 0 -> n
      _ -> 1
    end
  end
end

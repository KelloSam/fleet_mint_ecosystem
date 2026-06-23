defmodule FleetMint.Pagination do
  import Ecto.Query
  alias FleetMint.Repo

  @per_page 25

  def paginate(queryable, page, per_page \\ @per_page) do
    page = max(1, page)
    per_page = min(per_page, 100)
    offset = (page - 1) * per_page
    count_query =
      queryable
      |> exclude(:preload)
      |> exclude(:order_by)
      |> exclude(:select)
      |> exclude(:limit)
      |> exclude(:offset)

    total = Repo.aggregate(count_query, :count)
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

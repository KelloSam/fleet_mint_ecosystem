defmodule FleetMintWeb.RoutesLive do
  use FleetMintWeb, :live_view

  alias FleetMint.Transport.Routes
  alias FleetMintWeb.RouteHTML

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :page_title, "Routes")}
  end

  def handle_params(params, _uri, socket) do
    status = Map.get(params, "status")
    page = FleetMint.Pagination.parse_page(params)

    paged = Routes.list_routes_paginated(page, status: status)
    fare_ranges = Routes.fare_ranges_for_routes(Enum.map(paged.entries, & &1.id))

    {:noreply,
     socket
     |> assign(:paged, paged)
     |> assign(:filter_status, status || "")
     |> assign(:fare_ranges, fare_ranges)}
  end

  defp route_page_path(1, ""), do: ~p"/routes"
  defp route_page_path(page, ""), do: ~p"/routes?page=#{page}"
  defp route_page_path(page, status), do: ~p"/routes?page=#{page}&status=#{status}"

  def render(assigns) do
    ~H"""
    <div class="mb-6 flex items-center justify-between">
      <div>
        <h1 class="text-2xl font-bold text-gray-800">Routes</h1>
        <p class="text-sm text-gray-500 mt-1">Manage all bus routes and fares</p>
      </div>
      <.link
        :if={@current_user.role in ["platform_admin", "tenant_admin", "manager"]}
        href={~p"/routes/new"}
      >
        <.button class="bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded-lg text-sm font-medium">
          + Add Route
        </.button>
      </.link>
    </div>

    <div id="status-filters" class="mb-4 flex gap-2">
      <.link
        :for={{label, val} <- [{"All", ""}, {"Active", "active"}, {"Inactive", "inactive"}]}
        patch={route_page_path(1, val)}
        class={[
          "px-3 py-1.5 rounded-full text-xs font-medium border",
          if(@filter_status == val,
            do: "bg-blue-600 text-white border-blue-600",
            else: "bg-white text-gray-600 border-gray-300 hover:border-blue-400"
          )
        ]}
      >
        <%= label %>
      </.link>
    </div>

    <div class="bg-white rounded-lg shadow overflow-hidden">
      <div :if={@paged.entries == []} class="text-center py-16 text-gray-500">
        <svg
          class="mx-auto h-12 w-12 text-gray-300 mb-4"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="1.5"
            d="M9 20l-5.447-2.724A1 1 0 013 16.382V5.618a1 1 0 011.447-.894L9 7m0 13l6-3m-6 3V7m6 10l4.553 2.276A1 1 0 0021 18.382V7.618a1 1 0 00-.553-.894L15 4m0 13V4m0 0L9 7"
          />
        </svg>
        <p class="font-medium">No routes found</p>
        <p class="text-sm mt-1">Add your first route to get started.</p>
      </div>

      <table :if={@paged.entries != []} class="min-w-full divide-y divide-gray-200">
        <thead class="bg-gray-50">
          <tr>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Route Name
            </th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              From → To
            </th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Distance
            </th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Duration
            </th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Fare Range
            </th>
            <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">
              Status
            </th>
            <th class="px-6 py-3 text-right text-xs font-medium text-gray-500 uppercase tracking-wider">
              Actions
            </th>
          </tr>
        </thead>
        <tbody class="bg-white divide-y divide-gray-100">
          <tr :for={route <- @paged.entries} class="hover:bg-gray-50">
            <td class="px-6 py-4 text-sm font-semibold text-gray-900">
              <.link navigate={~p"/routes/#{route}"} class="hover:text-blue-600">
                <%= route.name %>
              </.link>
            </td>
            <td class="px-6 py-4 text-sm text-gray-700">
              <span class="text-gray-900"><%= route.start_location || "—" %></span>
              <span class="mx-2 text-gray-400">→</span>
              <span class="text-gray-900"><%= route.end_location || "—" %></span>
            </td>
            <td class="px-6 py-4 text-sm text-gray-700">
              <%= RouteHTML.format_distance(route.distance) %>
            </td>
            <td class="px-6 py-4 text-sm text-gray-700">
              <%= RouteHTML.format_duration(route.duration) %>
            </td>
            <td class="px-6 py-4 text-sm font-medium text-gray-900">
              <%= RouteHTML.format_fare_range(@fare_ranges[route.id], route.fare) %>
            </td>
            <td class="px-6 py-4">
              <RouteHTML.status_badge status={route.status} />
            </td>
            <td class="px-6 py-4 text-right text-sm">
              <span :if={@current_user.role in ["platform_admin", "tenant_admin", "manager"]}>
                <.link
                  navigate={~p"/routes/#{route}/edit"}
                  title="Edit"
                  class="text-gray-400 hover:text-blue-600 mr-3"
                >
                  <.icon name="hero-pencil-square" class="h-4 w-4" /> <span class="sr-only">Edit</span>
                </.link>
                <.link
                  href={~p"/routes/#{route}"}
                  method="delete"
                  data-confirm={"Delete route \"#{route.name}\"?"}
                  title="Delete"
                  class="text-gray-400 hover:text-red-600"
                >
                  <.icon name="hero-trash" class="h-4 w-4" /> <span class="sr-only">Delete</span>
                </.link>
              </span>
            </td>
          </tr>
        </tbody>
      </table>

      <div :if={@paged.entries != []} class="px-6 py-3 bg-gray-50 border-t text-xs text-gray-500">
        <%= @paged.total %> route<%= if @paged.total != 1, do: "s" %> total
      </div>

      <.pagination
        :if={@paged.entries != []}
        page={@paged.page}
        total_pages={@paged.total_pages}
        patch={true}
        path={&route_page_path(&1, @filter_status)}
      />
    </div>
    """
  end
end

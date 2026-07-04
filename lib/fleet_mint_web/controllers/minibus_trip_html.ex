defmodule FleetMintWeb.MinibusTripHTML do
  use FleetMintWeb, :html
  embed_templates "minibus_trip_html/*"

  slot :inner_block, required: true
  slot :subtitle
  slot :actions

  def header(assigns) do
    ~H"""
    <header class="px-4 sm:px-6 lg:px-8">
      <div class="flex items-center justify-between border-b border-zinc-100 py-3 mb-6">
        <div class="flex-1">
          <h1 class="text-xl font-semibold leading-7 text-zinc-800"><%= render_slot(@inner_block) %></h1>
          <%= if @subtitle != [], do: render_slot(@subtitle) %>
        </div>
        <div class="flex-none"><%= render_slot(@actions) %></div>
      </div>
    </header>
    """
  end

  attr :navigate, :string, required: true
  slot :inner_block, required: true

  def back(assigns) do
    ~H"""
    <div class="mt-6">
      <.link navigate={@navigate} class="text-sm font-semibold leading-6 text-zinc-600 hover:text-zinc-700">
        &larr; <%= render_slot(@inner_block) %>
      </.link>
    </div>
    """
  end

  def trip_form(assigns), do: ~H"""
  <.simple_form :let={f} for={@changeset} action={@action}>
    <.error :if={@changeset.action}>Please check the errors below.</.error>
    <.input field={f[:date]} type="date" label="Date" />
    <.input field={f[:bus_id]} type="select" label="Bus"
      options={Enum.map(@buses, &{"#{&1.registration_number} (#{&1.model})", &1.id})}
      prompt="Select bus" />
    <.input field={f[:route_id]} type="select" label="Route"
      options={Enum.map(@routes, &{"#{&1.name} — ZMW #{&1.fare}", &1.id})}
      prompt="Select route" />
    <.input field={f[:driver_id]} type="select" label="Driver"
      options={Enum.map(@drivers, &{&1.name, &1.id})}
      prompt="Select driver" />
    <.input field={f[:status]} type="select" label="Status"
      options={FleetMint.Transit.MinibusTrip.status_options()} />
    <.input field={f[:passengers_count]} type="number" label="Passengers Count" />
    <.input field={f[:fare_collected]} type="number" label="Fare Collected (ZMW)" step="0.01" />
    <.input field={f[:fuel_cost]} type="number" label="Fuel Cost (ZMW)" step="0.01" />
    <.input field={f[:notes]} type="textarea" label="Notes" />
    <:actions>
      <.button>Save Trip</.button>
    </:actions>
  </.simple_form>
  """
end

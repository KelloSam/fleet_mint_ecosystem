defmodule FleetMintWeb.FuelLogHTML do
  use FleetMintWeb, :html
  embed_templates "fuel_log_html/*"

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

  def fuel_log_form(assigns), do: ~H"""
  <.simple_form :let={f} for={@changeset} action={@action}>
    <.error :if={@changeset.action}>Please check the errors below.</.error>
    <.input field={f[:vehicle_id]} type="select" label="Vehicle"
      options={Enum.map(@vehicles, &{"#{&1.registration_number} #{&1.make} #{&1.model}", &1.id})}
      prompt="Select vehicle" />
    <.input field={f[:log_date]} type="date" label="Date" />
    <.input field={f[:fuel_type]} type="select" label="Fuel Type"
      options={FleetMint.Fleet.FuelLog.fuel_type_options()} />
    <.input field={f[:liters]} type="number" label="Litres" step="0.01" />
    <.input field={f[:cost_per_liter]} type="number" label="Cost per Litre (ZMW)" step="0.01" />
    <.input field={f[:total_cost]} type="number" label="Total Cost (ZMW) — auto-calculated" step="0.01" />
    <.input field={f[:mileage]} type="number" label="Mileage / Odometer (km)" />
    <.input field={f[:fuel_station]} type="text" label="Fuel Station" />
    <.input field={f[:driver_id]} type="select" label="Driver (optional)"
      options={Enum.map(@drivers, &{&1.full_name || &1.username, &1.id})}
      prompt="Select driver" />
    <.input field={f[:notes]} type="textarea" label="Notes" />
    <:actions>
      <.button>Save Fuel Log</.button>
    </:actions>
  </.simple_form>
  """
end

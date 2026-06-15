defmodule FleetMintWeb.DriverHTML do
  use FleetMintWeb, :html
  embed_templates "driver_html/*"

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

  attr :changeset, :map, required: true
  attr :action, :string, required: true

  def driver_form(assigns) do
    ~H"""
    <.simple_form :let={f} for={@changeset} action={@action}>
      <.error :if={@changeset.action}>Please check the errors below.</.error>
      <.input field={f[:name]} type="text" label="Full Name" />
      <.input field={f[:phone]} type="text" label="Phone Number" />
      <.input field={f[:license_number]} type="text" label="Driver's License Number" />
      <.input field={f[:license_expiry]} type="date" label="License Expiry Date" />
      <.input field={f[:daily_rate]} type="number" label="Daily Rate (ZMW)" step="0.01" />
      <.input field={f[:date_hired]} type="date" label="Date Hired" />
      <.input field={f[:status]} type="select" label="Status"
        options={FleetMint.Operations.Driver.status_options()} />
      <.input field={f[:notes]} type="textarea" label="Notes" />
      <:actions>
        <.button>Save Driver</.button>
      </:actions>
    </.simple_form>
    """
  end
end

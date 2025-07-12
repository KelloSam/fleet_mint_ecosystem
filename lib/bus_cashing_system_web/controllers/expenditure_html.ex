defmodule BusCashingSystemWeb.ExpenditureHTML do
  use BusCashingSystemWeb, :html
  
  # Import core components
  import BusCashingSystemWeb.CoreComponents

  embed_templates "expenditure_html/*"

  # Header component definition
  # ---------------------------------------------------------------------------
  attr :title, :string, required: true

  slot :subtitle, doc: "the optional subtitle to display under the title"
  slot :actions, doc: "the slot for showing user actions in the header"
  slot :inner_block, doc: "the optional inner block that renders the header content"

  def header(assigns) do
    ~H"""
    <header class="px-4 sm:px-6 lg:px-8">
      <div class="flex items-center justify-between border-b border-zinc-100 py-3">
        <div class="flex-1">
          <h1 class="text-lg font-semibold leading-7 text-zinc-800">
            <%= @title %>
          </h1>
          <%= if @subtitle != [] do %>
            <p class="mt-1 text-sm leading-6 text-zinc-600">
              <%= render_slot(@subtitle) %>
            </p>
          <% end %>
          <%= render_slot(@inner_block) %>
        </div>
        <div class="flex-none">
          <%= render_slot(@actions) %>
        </div>
      </div>
    </header>
    """
  end

  # Custom components
  # ---------------------------------------------------------------------------
  
  attr :title, :string, required: true
  slot :subtitle, doc: "the optional subtitle to display under the title"
  slot :inner_block, required: false
  
  def expenditure_header(assigns) do
    ~H"""
    <.header title={@title}>
      <:subtitle><%= render_slot(@subtitle) %></:subtitle>
      <%= render_slot(@inner_block) %>
    </.header>
    """
  end

  attr :changeset, :map, required: true
  attr :action, :string, required: true

  def expenditure_form_component(assigns) do
    ~H"""
    <.simple_form :let={f} for={@changeset} action={@action}>
      <.error :if={@changeset.action}>
        Oops, something went wrong! Please check the errors below.
      </.error>
      <.input field={f[:amount]} type="number" step="0.01" label="Amount" />
      <.input field={f[:description]} type="text" label="Description" />
      <.input field={f[:date]} type="date" label="Date" />
      <:actions>
        <.button>Save Expenditure</.button>
      </:actions>
    </.simple_form>
    """
  end

  attr :navigate, :string, required: true
  slot :inner_block, required: true

  def expenditure_back_button(assigns) do
    ~H"""
    <.link navigate={@navigate} class="text-sm font-semibold leading-6 text-zinc-600 hover:text-zinc-700">
      <.icon name="hero-arrow-left-solid" class="h-3 w-3" />
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end

  # Helper functions
  # ---------------------------------------------------------------------------
  
  @doc """
  Formats the date for display.
  """
  def format_date(date) when is_nil(date), do: "N/A"
  def format_date(date) do
    date
    |> Calendar.strftime("%Y-%m-%d")
  rescue
    _ -> "N/A"
  end

  @doc """
  Formats the amount for display.
  """
  def format_amount(amount) when is_nil(amount), do: "N/A"
  def format_amount(amount) do
    "$#{Decimal.to_string(amount)}"
  rescue
    _ -> "N/A"
  end
end

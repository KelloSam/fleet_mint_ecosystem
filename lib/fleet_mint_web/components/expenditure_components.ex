defmodule FleetMintWeb.ExpenditureComponents do
  use Phoenix.Component
  
  import FleetMintWeb.CoreComponents
  alias FleetMint.Finance

  # Attributes for expenditure_form_component
  attr :changeset, Ecto.Changeset, required: true, doc: "the changeset for the expenditure form"
  attr :action, :string, required: true, doc: "the form action URL"

  @doc """
  Renders a expenditure form.
  """
  def expenditure_form_component(assigns) do
    ~H"""
    <.simple_form :let={f} for={@changeset} action={@action}>
      <.error :if={@changeset.action}>
        Oops, something went wrong! Please check the errors below.
      </.error>
      <.input field={f[:amount]} type="number" label="Amount" step="any" />
      <.input field={f[:description]} type="text" label="Description" />
      <.input field={f[:date]} type="datetime-local" label="Date" />
      <.input field={f[:cashing_report_id]} type="select" label="Cashing Report" options={cashing_report_options()} />
      <:actions>
        <.button>Save Expenditure</.button>
      </:actions>
    </.simple_form>
    """
  end

  # Attributes for expenditure_header component
  attr :title, :string, required: true, doc: "the title of the header"
  attr :class, :string, default: nil, doc: "optional CSS class for the header"
  slot :subtitle, doc: "optional subtitle content for the header"
  slot :actions, doc: "optional action buttons for the header"

  @doc """
  Renders a header with title.
  """
  def expenditure_header(assigns) do
    ~H"""
    <header class={[@class]}>
      <h1 class="text-lg font-semibold leading-8 text-zinc-800">
        <%= @title %>
      </h1>
      <%= render_slot(@subtitle) %>
      <div class="actions">
        <%= render_slot(@actions) %>
      </div>
    </header>
    """
  end

  # Attributes for expenditure_back_button component
  attr :navigate, :string, required: true, doc: "the URL to navigate to when clicking back"
  slot :inner_block, doc: "the content to display in the back link"

  @doc """
  Renders a back navigation link.
  """
  def expenditure_back_button(assigns) do
    ~H"""
    <div class="mt-16">
      <.link navigate={@navigate} class="text-sm font-semibold leading-6 text-zinc-900 hover:text-zinc-700">
        <%= render_slot(@inner_block) || "Back to expenditures" %>
      </.link>
    </div>
    """
  end

  # Attributes for expenditure_item_list component
  attr :items, :list, default: [], doc: "the list of items to display"
  slot :item, required: true, doc: "the template for each item" do
    attr :title, :string, required: true, doc: "the title of the item"
  end

  @doc """
  Renders a list of items.
  """
  def expenditure_item_list(assigns) do
    ~H"""
    <div class="mt-14">
      <ul class="mt-4 divide-y divide-zinc-100">
        <li :for={item <- @items} class="flex gap-4 py-4">
          <%= render_slot(@item, item) %>
        </li>
      </ul>
    </div>
    """
  end

  # Helper function needed by components
  defp cashing_report_options do
    Finance.list_cashing_reports()
    |> Enum.map(fn cr -> 
      display_text = "Report ##{cr.id} #{cr.description || ""}"
      {display_text, cr.id} 
    end)
  end
end


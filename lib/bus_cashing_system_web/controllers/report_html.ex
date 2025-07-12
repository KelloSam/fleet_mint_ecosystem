defmodule BusCashingSystemWeb.ReportHTML do
  use Phoenix.Component
  use BusCashingSystemWeb, :html

  import BusCashingSystemWeb.CoreComponents
  @doc """
  Renders a report form.
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true
  def report_form(assigns) do
    ~H"""
    <.simple_form :let={f} for={@changeset} action={@action}>
      <.error :if={@changeset.action}>
        Oops, something went wrong! Please check the errors below.
      </.error>
      <.input field={f[:description]} type="text" label="Description" />
      <.input field={f[:details]} type="textarea" label="Details" />
      <:actions>
        <.button>Save Report</.button>
      </:actions>
    </.simple_form>
    """
  end

  @doc """
  Renders a header with title.
  """
  attr :title, :string, required: true
  attr :class, :string, default: nil
  slot :subtitle, required: false
  slot :actions, required: false  # Add this line
  def header(assigns) do
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

  @doc """
  Renders a back navigation link.
  """
  attr :navigate, :string, required: true
  slot :inner_block, required: false
  def back(assigns) do
    ~H"""
    <div class="mt-16">
      <.link navigate={@navigate} class="text-sm font-semibold leading-6 text-zinc-900 hover:text-zinc-700">
        <%= render_slot(@inner_block) || "Back to reports" %>
      </.link>
    </div>
    """
  end

  @doc """
  Renders a list of items.
  """
  attr :items, :list, required: true
  slot :item, required: true
  def item_list(assigns) do
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

  embed_templates "report_html/*"
end

defmodule FleetMintWeb.CoreComponents do
  use Phoenix.Component
  import FleetMintWeb.Gettext, only: [gettext: 1]
  alias Phoenix.LiveView.JS

  # ... (your existing attributes and slots) ...

  # Helper functions to handle modal visibility
  defp show_modal(id) do
    JS.show(to: "##{id}", transition: "fade-in")
  end

  defp hide_modal(id) do
    JS.hide(to: "##{id}", transition: "fade-out")
  end

  # Function definitions
  def modal(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && show_modal(@id)}
      phx-remove={hide_modal(@id)}
      data-cancel={JS.exec(@on_cancel, "phx-remove")}
      class="relative z-50 hidden"
    >
      <div id={@id}-bg class="bg-zinc-50/90 fixed inset-0 transition-opacity" aria-hidden="true" />
      <div
        class="fixed inset-0 overflow-y-auto"
        aria-labelledby={@id}-title
        aria-describedby={@id}-description
        role="dialog"
        aria-modal="true"
        tabindex="0"
      >
        <div class="flex min-h-full items-center justify-center">
          <div class="w-full max-w-3xl p-4 sm:p-6 lg:py-8">
            <div class="absolute top-6 right-5">
              <button
                phx-click={JS.exec("data-cancel", to: "##{@id}")}
                type="button"
                class="-m-3 flex-none p-3 opacity-20 hover:opacity-40"
                aria-label={gettext("close")}
              >
                <.icon name="hero-x-mark-solid" class="h-5 w-5" />
              </button>
            </div>
            <.focus_wrap
              id={"#{@id}-content"}
              phx-window-keydown={JS.exec("data-cancel", to: "##{@id}")}
              phx-key="escape"
              phx-click-away={JS.exec("data-cancel", to: "##{@id}")}
              class="shadow-zinc-700/10 ring-zinc-700/10 relative hidden rounded-2xl bg-white p-14 shadow-lg ring-1 transition"
            >
              <div id={"#{@id}-container"}>
                <%= render_slot(@inner_block) %>
              </div>
            </.focus_wrap>
          </div>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders flash notices.

  ## Examples

      <.flash kind={:info} flash={@flash} />
      <.flash kind={:info} phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :id, :string, doc: "the optional id of flash container"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> JS.hide(to: "##{@id}")}
      role="alert"
      class={[
        "fixed top-2 right-2 mr-2 w-80 sm:w-96 z-50 rounded-lg p-3 ring-1",
        @kind == :info && "bg-emerald-50 text-emerald-800 ring-emerald-500 fill-cyan-900",
        @kind == :error && "bg-rose-50 text-rose-900 shadow-md ring-rose-500 fill-rose-900"
      ]}
      {@rest}
    >
      <p :if={@title} class="flex items-center gap-1.5 text-sm font-semibold leading-6">
        <.icon :if={@kind == :info} name="hero-information-circle-mini" class="h-4 w-4" />
        <.icon :if={@kind == :error} name="hero-exclamation-circle-mini" class="h-4 w-4" />
        <%= @title %>
      </p>
      <p class="mt-2 text-sm leading-5"><%= msg %></p>
      <button type="button" class="group absolute top-1 right-1 p-2" aria-label={gettext("close")}>
        <.icon name="hero-x-mark-solid" class="h-5 w-5 opacity-40 group-hover:opacity-70" />
      </button>
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr :flash, :map, required: true, doc: "the map of flash messages"
  attr :id, :string, default: "flash-group", doc: "the optional id of flash container"

  def flash_group(assigns) do
    ~H"""
    <div id={@id}>
      <.flash kind={:info} title={gettext("Success!")} flash={@flash} />
      <.flash kind={:error} title={gettext("Error!")} flash={@flash} />
      <.flash
        id="client-error"
        kind={:error}
        title={gettext("We can't find the internet")}
        phx-disconnected={JS.show(to: ".phx-client-error #client-error")}
        phx-connected={JS.hide(to: "#client-error")}
        hidden
      >
        <%= gettext("Attempting to reconnect") %>
        <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={JS.show(to: ".phx-server-error #server-error")}
        phx-connected={JS.hide(to: "#server-error")}
        hidden
      >
        <%= gettext("Attempting to reconnect") %>
        <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title={gettext("Something went wrong!")}
        phx-disconnected={JS.show(to: ".phx-server-error #server-error")}
        phx-connected={JS.hide(to: "#server-error")}
        hidden
      >
        <%= gettext("Hang in there") %>
        <%= gettext("Hang in there while we get back on track") %>
        <.icon name="hero-arrow-path" class="ml-1 h-3 w-3 animate-spin" />
      </.flash>
    </div>
    """
  end

  @doc """
  Renders a simple form.

  ## Examples

      <.simple_form for={@form} phx-change="validate" phx-submit="save">
        <.input field={@form[:email]} label="Email"/>
        <.input field={@form[:username]} label="Username" />
        <:actions>
          <.button>Save</.button>
        </:actions>
      </.simple_form>
  """
  attr :for, :any, required: true, doc: "the data structure for the form"
  attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"
  attr :rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target multipart),
    doc: "the arbitrary HTML attributes to apply to the form tag"

  slot :inner_block, required: true
  slot :actions, doc: "the slot for form actions, such as a submit button"

  def simple_form(assigns) do
    ~H"""
    <.form :let={f} for={@for} as={@as} {@rest}>
      <div class="mt-10 space-y-8 bg-white">
        <%= render_slot(@inner_block, f) %>
        <div :for={action <- @actions} class="mt-2 flex items-center justify-between gap-6">
          <%= render_slot(action, f) %>
        </div>
      </div>
    </.form>
    """
  end

  @doc """
  Renders a simple input.

  ## Examples

      <.input field={@form[:email]} label="Email"/>
      <.input field={@form[:password]} label="Password" error={@form.errors[:password]}/>
  """
  attr :field, :any, required: true, doc: "the form field to be rendered"
  attr :label, :string, required: true, doc: "the label for the input field"
  attr :error, :string, doc: "the optional error message for the input field"
  attr :type, :string, default: "text", doc: "the type of the input field"
  attr :step, :string, doc: "the step for numeric input fields"
  attr :options, :list, doc: "the options for a select input"
  attr :required, :boolean, default: false, doc: "whether the field is required"
  attr :rest, :global, include: ~w(placeholder min max autocomplete rows cols)

  def input(assigns) do
    assigns = assign_new(assigns, :step, fn -> nil end)
    ~H"""
    <div phx-feedback-for={@field.name}>
      <label for={@field.id} class="block text-sm font-medium text-gray-700"><%= @label %></label>
      <div class="mt-1">
        <%= if @type == "select" do %>
          <select
            name={@field.name}
            id={@field.id}
            class={[
              "block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm",
              @field.errors != [] && "border-red-300"
            ]}
          >
            <%= for {option_label, option_value} <- @options || [] do %>
              <option value={option_value} selected={@field.value == to_string(option_value)}>
                <%= option_label %>
              </option>
            <% end %>
          </select>
        <% else %>
          <input
            type={@type}
            name={@field.name}
            id={@field.id}
            value={@field.value}
            step={@step}
            required={@required}
            class={[
              "block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm",
              @field.errors != [] && "border-red-300"
            ]}
            {@rest}
          />
        <% end %>
      </div>
      <div class="mt-2 text-sm text-red-600">
        <%= for {msg, _opts} <- @field.errors do %>
          <div><%= msg %></div>
        <% end %>
      </div>
    </div>
    """
  end

  @doc """
  Renders a button.

  ## Examples

      <.button>Click me</.button>
      <.button phx-click="submit">Submit</.button>
  """
  attr :rest, :global, doc: "any other HTML attributes for the button"

  slot :inner_block, required: true 

  def button(assigns) do
    ~H"""
    <button
      type="submit"
      class="inline-flex items-center justify-center rounded-md border border-transparent bg-indigo-600 px-4 py-2 text-sm font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2"
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  @doc """
  Renders an error message.

  ## Examples

      <.error message={@form.errors[:email]} />
      <.error>Error message</.error>
  """
  attr :message, :string, default: nil, doc: "the error message to display"
  
  slot :inner_block, doc: "the optional inner block that renders the error message"

  def error(assigns) do
    ~H"""
    <p class="mt-1 text-sm text-red-600">
      <%= render_slot(@inner_block) || @message %>
    </p>
    """
  end

  @doc """
  Renders a table with generic styling.

  ## Examples

      <.table rows={@users}>
        <:col :let={user} label="Name"><%= user.name %></:col>
        <:col :let={user} label="Email"><%= user.email %></:col>
      </.table>
  """
  attr :id, :string, default: nil
  attr :rows, :list, required: true
  attr :row_click, :any, default: nil
  attr :row_id, :any, default: nil
  attr :headers, :list, default: [], doc: "list of header labels for the table"
  slot :col, required: true do
    attr :label, :string
  end

  slot :action, doc: "the slot for showing user actions in the last table column"

  def table(assigns) do
    ~H"""
    <table class="min-w-full divide-y divide-gray-200">
      <thead>
        <tr>
          <th :for={col <- @col} class="px-6 py-3 text-left text-xs font-medium uppercase tracking-wider text-gray-500">
            <%= col[:label] %>
          </th>
          <th :if={@action != []} class="relative p-0 pb-4">
            <span class="sr-only">Actions</span>
          </th>
        </tr>
      </thead>
      <tbody class="divide-y divide-gray-200">
        <tr :for={row <- @rows} id={@row_id && @row_id.(row)} class="group hover:bg-gray-50">
          <td :for={col <- @col} class="whitespace-nowrap px-6 py-4 text-sm text-gray-500">
            <%= render_slot(col, row) %>
          </td>
          <td :if={@action != []} class="relative whitespace-nowrap py-4 pl-3 pr-4 text-right text-sm font-medium">
            <div class="relative whitespace-nowrap py-4 pl-3 pr-4 text-right text-sm font-medium">
              <span class="absolute -inset-y-px -right-4 left-0 group-hover:bg-gray-50 sm:rounded-r-xl" />
              <span class="relative inline-flex gap-3">
                <%= render_slot(@action, row) %>
              </span>
            </div>
          </td>
        </tr>
      </tbody>
    </table>
    """
  end

  @doc """
  Renders a list with items.

  ## Examples

      <.list>
        <:item title="Title">Content</:item>
      </.list>
  """
  attr :class, :string, default: nil

  slot :item, required: true do
    attr :title, :string, required: true
  end

  def list(assigns) do
    ~H"""
    <div class={[@class]}>
      <dl class="-my-4 divide-y divide-zinc-100">
        <%= for item <- @item do %>
          <div class="flex gap-4 py-4 text-sm leading-6 sm:gap-8">
            <dt class="w-1/4 flex-none text-zinc-500"><%= item.title %></dt>
            <dd class="text-zinc-700"><%= render_slot(item) %></dd>
          </div>
        <% end %>
      </dl>
    </div>
    """
  end

  @doc """
  Renders a back link.

  ## Examples

      <.back_link to={Routes.page_path(@conn, :index)}>Back</.back_link>
  """
  attr :to, :string, required: true, doc: "the path to navigate back to"

  def back_link(assigns) do
    ~H"""
    <a href={@to} class="text-indigo-600 hover:text-indigo-500">
      <.icon name="hero-arrow-left" class="h-5 w-5" />
      <span>Back</span>
    </a>
    """
  end

  @doc """
  Renders an icon.

  ## Examples

      <.icon name="hero-arrow-left" />
  """
  attr :name, :string, required: true, doc: "the name of the icon"
  attr :rest, :global, doc: "any other HTML attributes for the icon"

  def icon(assigns) do
    ~H"""
    <svg
      class="h-5 w-5"
      xmlns="http://www.w3.org/2000/svg"
      fill="none"
      viewBox="0 0 24 24"
      stroke="currentColor"
      aria-hidden="true"
      {@rest}
    >
      <use href={"#{"#"}{@name}"} />
    </svg>
    """
  end
end

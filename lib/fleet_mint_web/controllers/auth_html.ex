defmodule FleetMintWeb.AuthHTML do
  use FleetMintWeb, :html

  embed_templates "auth_html/*"

  @doc """
  Renders a login form.
  """
  attr :error_message, :string, default: nil

  def login_form(assigns) do
    ~H"""
    <.simple_form :let={f} for={%{}} as={:user} action={~p"/login"}>
      <.error :if={@error_message}><%= @error_message %></.error>
      <.input field={f[:email]} type="email" label="Email" required />
      <.input field={f[:password]} type="password" label="Password" required />

      <:actions>
        <.button class="w-full">Sign In</.button>
      </:actions>
    </.simple_form>
    <div class="mt-6 text-center">
      <.link href={~p"/register"} class="text-sm font-semibold leading-6 text-zinc-900 hover:text-zinc-700">
        Need an account? Register here
      </.link>
    </div>
    """
  end

  @doc """
  Renders a user registration form.
  """
  attr :changeset, Ecto.Changeset, required: true

  def user_form(assigns) do
    ~H"""
    <.simple_form :let={f} for={@changeset} action={~p"/register"}>
      <.error :if={@changeset.action}>
        Something went wrong. Please check the errors below.
      </.error>
      <.input field={f[:full_name]} type="text" label="Full Name" required />
      <.input field={f[:username]} type="text" label="Username" required />
      <.input field={f[:email]} type="email" label="Email" required />
      <.input field={f[:password]} type="password" label="Password" required />
      <.input field={f[:role]} type="select" label="Role" options={[{"Admin", "admin"}, {"Manager", "manager"}, {"Cashier", "cashier"}, {"Operator", "operator"}]} required />

      <:actions>
        <.button class="w-full">Register</.button>
      </:actions>
    </.simple_form>
    <div class="mt-6 text-center">
      <.link href={~p"/login"} class="text-sm font-semibold leading-6 text-zinc-900 hover:text-zinc-700">
        Already have an account? Login here
      </.link>
    </div>
    """
  end
end


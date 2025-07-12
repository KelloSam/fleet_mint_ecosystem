defmodule BusCashingSystemWeb.PageHTML do
  @moduledoc """
  This module contains pages rendered by PageController.

  See the `page_html` directory for all templates available.
  """
  use BusCashingSystemWeb, :html

  embed_templates "page_html/*"
  
  @doc """
  Formats a date for display in the dashboard.
  """
  def format_date(datetime) when is_struct(datetime) do
    Calendar.strftime(datetime, "%b %d, %Y")
  end
  
  def format_date(_), do: "-"
  
  @doc """
  Formats a currency amount for display.
  """
  def format_currency(amount) when is_number(amount) do
    "KES #{:erlang.float_to_binary(amount, [decimals: 2])}"
  end
  
  def format_currency(amount) when is_binary(amount) do
    case Float.parse(amount) do
      {num, _} -> format_currency(num)
      :error -> "KES 0.00"
    end
  end
  
  def format_currency(_), do: "KES 0.00"
  
  @doc """
  Determines if a user has admin privileges.
  """
  def is_admin?(user) do
    user && user.role == "admin"
  end
  
  @doc """
  Returns a CSS class for a transaction type.
  """
  def transaction_color("income"), do: "text-green-600"
  def transaction_color("expense"), do: "text-red-600"
  def transaction_color(_), do: "text-gray-600"
end

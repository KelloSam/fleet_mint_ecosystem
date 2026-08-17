defmodule FleetMintWeb.PageHTML do
  @moduledoc """
  This module contains pages rendered by PageController.

  See the `page_html` directory for all templates available.
  """
  use FleetMintWeb, :html

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
    "KES #{:erlang.float_to_binary(amount, decimals: 2)}"
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
    user && user.role in ["platform_admin", "tenant_admin"]
  end

  @doc """
  Returns a CSS class for a transaction type.
  """
  def transaction_color("income"), do: "text-green-600"
  def transaction_color("expense"), do: "text-red-600"
  def transaction_color(_), do: "text-gray-600"

  # ── Weekly revenue trend chart ────────────────────────────────────────────
  #
  # Builds SVG geometry for Finance.weekly_revenue_trend/2's output. Kept as
  # plain data (points + a polyline string) rather than a Phoenix.Component
  # so the template stays a straightforward SVG literal — the only logic
  # here is the coordinate math.

  @chart_width 520
  @chart_height 150
  @chart_pad_top 16
  @chart_pad_bottom 28
  @chart_pad_x 10

  @doc """
  Turns a `Finance.weekly_revenue_trend/2` result into chart-ready geometry:
  each point's `x`/`y`/`value`/`label`, the polyline's `points` string, an
  area-fill polygon closed to the baseline, and the axis extremes. Returns
  `nil` for an empty trend (no weekly reports exist yet).
  """
  def revenue_chart([]), do: nil

  def revenue_chart(trend) when is_list(trend) do
    plot_top = @chart_pad_top
    plot_bottom = @chart_height - @chart_pad_bottom
    plot_left = @chart_pad_x
    plot_right = @chart_width - @chart_pad_x
    plot_height = plot_bottom - plot_top

    values = Enum.map(trend, &decimal_to_float(&1.revenue))
    max_value = values |> Enum.max() |> max(0.0)

    count = length(trend)
    step = if count > 1, do: (plot_right - plot_left) / (count - 1), else: 0

    points =
      trend
      |> Enum.zip(values)
      |> Enum.with_index()
      |> Enum.map(fn {{report, value}, i} ->
        y =
          if max_value > 0 do
            plot_bottom - value / max_value * plot_height
          else
            plot_bottom
          end

        %{
          x: plot_left + step * i,
          y: y,
          value: report.revenue,
          label: Calendar.strftime(report.start_date, "%b %-d")
        }
      end)

    polyline = Enum.map_join(points, " ", fn p -> "#{p.x},#{p.y}" end)

    area_points =
      "#{plot_left},#{plot_bottom} " <> polyline <> " #{plot_right},#{plot_bottom}"

    %{
      points: points,
      polyline: polyline,
      area_points: area_points,
      max_value: max_value,
      baseline_y: plot_bottom,
      top_y: plot_top,
      plot_left: plot_left,
      plot_right: plot_right,
      width: @chart_width,
      height: @chart_height
    }
  end

  defp decimal_to_float(%Decimal{} = d), do: Decimal.to_float(d)
  defp decimal_to_float(n) when is_number(n), do: n * 1.0
  defp decimal_to_float(_), do: 0.0

  @doc """
  Formats a currency amount with thousands separators, e.g. `8200.5` ->
  `"8,200.50"`. Used for the revenue chart's axis/tooltip figures.
  """
  def format_zmw(%Decimal{} = amount), do: amount |> Decimal.to_float() |> format_zmw()

  def format_zmw(amount) when is_number(amount) do
    [whole, decimals] =
      amount
      |> :erlang.float_to_binary(decimals: 2)
      |> String.split(".")

    grouped =
      whole
      |> String.to_charlist()
      |> Enum.reverse()
      |> Enum.chunk_every(3)
      |> Enum.map_join(",", &List.to_string/1)
      |> String.reverse()

    grouped <> "." <> decimals
  end

  def format_zmw(_), do: "0.00"
end

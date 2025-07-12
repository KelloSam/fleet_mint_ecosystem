defmodule BusCashingSystem.Expenditures do
  import Ecto.Query, warn: false
  alias BusCashingSystem.Repo
  alias BusCashingSystem.Expenditures.Expenditure

  def create_expenditure(attrs \\ %{}) do
    %Expenditure{}
    |> Expenditure.changeset(attrs)
    |> Repo.insert()
  end
end

defmodule FleetMint.Payments do
  @moduledoc """
  DEAD CODE: zero callers anywhere in the app (confirmed 2026-07-04). Its
  schema, FleetMint.Payments.Transaction, belongs_to a Ticket via a
  `ticket_id` column that no migration ever added to the `transactions`
  table — this code has never run end-to-end. Left at this path rather
  than merged into FleetMint.Finance so Finance doesn't inherit broken,
  unexercised code under a legitimate-looking name. Candidate for deletion
  in a future pass.
  """
  
  import Ecto.Query, warn: false
  alias FleetMint.Repo
  alias FleetMint.Payments.Transaction
  alias FleetMint.Ticketing
  alias FleetMint.Ticketing.Ticket
  
  @doc """
  Returns the list of transactions.
  
  ## Examples
  
      iex> list_transactions()
      [%Transaction{}, ...]
  
  """
  def list_transactions do
    Repo.all(Transaction)
    |> Repo.preload([:ticket, :user])
  end
  
  @doc """
  Gets a single transaction.
  
  Raises `Ecto.NoResultsError` if the Transaction does not exist.
  
  ## Examples
  
      iex> get_transaction!(123)
      %Transaction{}
      
      iex> get_transaction!(456)
      ** (Ecto.NoResultsError)
  
  """
  def get_transaction!(id) do
    Repo.get!(Transaction, id)
    |> Repo.preload([:ticket, :user])
  end
  
  @doc """
  Gets a single transaction.
  
  Returns nil if the Transaction does not exist.
  
  ## Examples
  
      iex> get_transaction(123)
      %Transaction{}
      
      iex> get_transaction(456)
      nil
  
  """
  def get_transaction(id) do
    Repo.get(Transaction, id)
    |> case do
      nil -> nil
      transaction -> Repo.preload(transaction, [:ticket, :user])
    end
  end
  
  @doc """
  Gets a transaction by its reference number.
  
  Returns nil if no transaction is found with the given reference number.
  
  ## Examples
  
      iex> get_transaction_by_reference("TXN-20250406123456-ABC123")
      %Transaction{}
      
      iex> get_transaction_by_reference("NONEXISTENT")
      nil
  
  """
  def get_transaction_by_reference(reference_number) when is_binary(reference_number) do
    Repo.get_by(Transaction, reference_number: reference_number)
    |> case do
      nil -> nil
      transaction -> Repo.preload(transaction, [:ticket, :user])
    end
  end
  
  @doc """
  Creates a transaction.
  
  ## Examples
  
      iex> create_transaction(%{field: value})
      {:ok, %Transaction{}}
      
      iex> create_transaction(%{field: bad_value})
      {:error, %Ecto.Changeset{}}
  
  """
  def create_transaction(attrs \\ %{}) do
    %Transaction{}
    |> Transaction.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, transaction} -> {:ok, Repo.preload(transaction, [:ticket, :user])}
      error -> error
    end
  end
  
  @doc """
  Updates a transaction.
  
  ## Examples
  
      iex> update_transaction(transaction, %{field: new_value})
      {:ok, %Transaction{}}
      
      iex> update_transaction(transaction, %{field: bad_value})
      {:error, %Ecto.Changeset{}}
  
  """
  def update_transaction(%Transaction{} = transaction, attrs) do
    transaction
    |> Transaction.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, transaction} -> {:ok, Repo.preload(transaction, [:ticket, :user])}
      error -> error
    end
  end
  
  @doc """
  Deletes a transaction.
  
  ## Examples
  
      iex> delete_transaction(transaction)
      {:ok, %Transaction{}}
      
      iex> delete_transaction(transaction)
      {:error, %Ecto.Changeset{}}
  
  """
  def delete_transaction(%Transaction{} = transaction) do
    Repo.delete(transaction)
  end
  
  @doc """
  Returns an `%Ecto.Changeset{}` for tracking transaction changes.
  
  ## Examples
  
      iex> change_transaction(transaction)
      %Ecto.Changeset{data: %Transaction{}}
  
  """
  def change_transaction(%Transaction{} = transaction, attrs \\ %{}) do
    Transaction.changeset(transaction, attrs)
  end
  
  @doc """
  Process a payment for a ticket.
  
  Creates a transaction for the payment and returns both the transaction and the ticket.
  
  ## Examples
  
      iex> process_payment(ticket, %{payment_method: "cash", amount: 100.0, user_id: 1})
      {:ok, %{transaction: %Transaction{}, ticket: %Ticket{}}}
      
      iex> process_payment(ticket, %{payment_method: "invalid", amount: -10.0, user_id: 1})
      {:error, :transaction, %Ecto.Changeset{}, %{}}
  
  """
  def process_payment(%Ticket{} = ticket, payment_attrs) do
    # Ensure the payment amount matches the ticket fare
    payment_attrs = Map.put(payment_attrs, "ticket_id", ticket.id)
    
    Repo.transaction(fn ->
      with {:ok, transaction} <- create_transaction(payment_attrs) do
        ticket = Ticketing.get_ticket!(ticket.id)
        %{transaction: transaction, ticket: ticket}
      else
        {:error, changeset} -> Repo.rollback({:transaction, changeset})
      end
    end)
  end
  
  @doc """
  Update a transaction status.
  
  ## Examples
  
      iex> update_transaction_status(transaction, "success")
      {:ok, %Transaction{}}
      
      iex> update_transaction_status(transaction, "invalid_status")
      {:error, %Ecto.Changeset{}}
  
  """
  def update_transaction_status(%Transaction{} = transaction, status) when is_binary(status) do
    update_transaction(transaction, %{status: status})
  end
  
  @doc """
  Returns the list of transactions with a specific status.
  
  ## Examples
  
      iex> list_transactions_by_status("success")
      [%Transaction{}, ...]
  
  """
  def list_transactions_by_status(status) when is_binary(status) do
    query = from t in Transaction,
            where: t.status == ^status,
            order_by: [desc: t.transaction_date]
    
    Repo.all(query)
    |> Repo.preload([:ticket, :user])
  end
  
  @doc """
  Returns the list of transactions for a specific date.
  
  ## Examples
  
      iex> list_transactions_by_date(~D[2025-04-06])
      [%Transaction{}, ...]
  
  """
  def list_transactions_by_date(date) do
    start_datetime = date |> DateTime.new!(~T[00:00:00.000], "Etc/UTC") |> DateTime.truncate(:second)
    end_datetime = date |> DateTime.new!(~T[23:59:59.999], "Etc/UTC") |> DateTime.truncate(:second)
    
    query = from t in Transaction,
            where: t.transaction_date >= ^start_datetime and t.transaction_date <= ^end_datetime,
            order_by: [desc: t.transaction_date]
    
    Repo.all(query)
    |> Repo.preload([:ticket, :user])
  end
  
  @doc """
  Returns the list of transactions for a date range.
  
  ## Examples
  
      iex> list_transactions_by_date_range(~D[2025-04-01], ~D[2025-04-07])
      [%Transaction{}, ...]
  
  """
  def list_transactions_by_date_range(start_date, end_date) do
    start_datetime = start_date |> DateTime.new!(~T[00:00:00.000], "Etc/UTC") |> DateTime.truncate(:second)
    end_datetime = end_date |> DateTime.new!(~T[23:59:59.999], "Etc/UTC") |> DateTime.truncate(:second)
    
    query = from t in Transaction,
            where: t.transaction_date >= ^start_datetime and t.transaction_date <= ^end_datetime,
            order_by: [asc: t.transaction_date]
    
    Repo.all(query)
    |> Repo.preload([:ticket, :user])
  end
  
  @doc """
  Returns the list of transactions for a specific payment method.
  
  ## Examples
  
      iex> list_transactions_by_payment_method("cash")
      [%Transaction{}, ...]
  
  """
  def list_transactions_by_payment_method(payment_method) when is_binary(payment_method) do
    query = from t in Transaction,
            where: t.payment_method == ^payment_method,
            order_by: [desc: t.transaction_date]
    
    Repo.all(query)
    |> Repo.preload([:ticket, :user])
  end
  
  @doc """
  Returns the list of transactions processed by a specific user (cashier).
  
  ## Examples
  
      iex> list_transactions_by_user(user_id)
      [%Transaction{}, ...]
  
  """
  def list_transactions_by_user(user_id) do
    query = from t in Transaction,
            where: t.user_id == ^user_id,
            order_by: [desc: t.transaction_date]
    
    Repo.all(query)
    |> Repo.preload([:ticket, :user])
  end
  
  @doc """
  Returns the list of transactions for a specific ticket.
  
  ## Examples
  
      iex> list_transactions_by_ticket(ticket_id)
      [%Transaction{}, ...]
  
  """
  def list_transactions_by_ticket(ticket_id) do
    query = from t in Transaction,
            where: t.ticket_id == ^ticket_id,
            order_by: [desc: t.transaction_date]
    
    Repo.all(query)
    |> Repo.preload([:ticket, :user])
  end
  
  @doc """
  Returns the total number of transactions for a specific date.
  
  ## Examples
  
      iex> count_transactions_by_date(~D[2025-04-06])
      42
  
  """
  def count_transactions_by_date(date) do
    start_datetime = date |> DateTime.new!(~T[00:00:00.000], "Etc/UTC") |> DateTime.truncate(:second)
    end_datetime = date |> DateTime.new!(~T[23:59:59.999], "Etc/UTC") |> DateTime.truncate(:second)
    
    query = from t in Transaction,
            where: t.transaction_date >= ^start_datetime and t.transaction_date <= ^end_datetime,
            select: count(t.id)
    
    Repo.one(query) || 0
  end
  
  @doc """
  Calculates the total amount for transactions on a specific date.
  
  ## Examples
  
      iex> calculate_total_amount_by_date(~D[2025-04-06])
      #Decimal<1050.00>
  
  """
  def calculate_total_amount_by_date(date) do
    start_datetime = date |> DateTime.new!(~T[00:00:00.000], "Etc/UTC") |> DateTime.truncate(:second)
    end_datetime = date |> DateTime.new!(~T[23:59:59.999], "Etc/UTC") |> DateTime.truncate(:second)
    
    query = from t in Transaction,
            where: t.transaction_date >= ^start_datetime and 
                   t.transaction_date <= ^end_datetime and 
                   t.status == "success",
            select: sum(t.amount)
    
    Repo.one(query) || Decimal.new("0.00")
  end
  
  @doc """
  Calculates the total amount for transactions in a date range.
  
  ## Examples
  
      iex> calculate_total_amount_by_date_range(~D[2025-04-01], ~D[2025-04-07])
      #Decimal<7350.00>
  
  """
  def calculate_total_amount_by_date_range(start_date, end_date) do
    start_datetime = start_date |> DateTime.new!(~T[00:00:00.000], "Etc/UTC") |> DateTime.truncate(:second)
    end_datetime = end_date |> DateTime.new!(~T[23:59:59.999], "Etc/UTC") |> DateTime.truncate(:second)
    
    query = from t in Transaction,
            where: t.transaction_date >= ^start_datetime and 
                   t.transaction_date <= ^end_datetime and 
                   t.status == "success",
            select: sum(t.amount)
    
    Repo.one(query) || Decimal.new("0.00")
  end
  
  @doc """
  Generates a daily transaction report.
  
  ## Examples
  
      iex> generate_daily_transaction_report(~D[2025-04-06])
      %{
        date: ~D[2025-04-06],
        total_transactions: 42,
        total_amount: #Decimal<1050.00>,
        transactions_by_status: [
          %{status: "success", count: 40, amount: #Decimal<1000.00>},
          %{status: "failed", count: 2, amount: #Decimal<50.00>}
        ],
        transactions_by_payment_method: [
          %{payment_method: "cash", count: 30, amount: #Decimal<750.00>},
          %{payment_method: "card", count: 10, amount: #Decimal<250.00>},
          %{payment_method: "mobile_money", count: 2, amount: #Decimal<50.00>}
        ]
      }
  
  """
  def generate_daily_transaction_report(date) do
    start_datetime = date |> DateTime.new!(~T[00:00:00.000], "Etc/UTC") |> DateTime.truncate(:second)
    end_datetime = date |> DateTime.new!(~T[23:59:59.999], "Etc/UTC") |> DateTime.truncate(:second)
    
    # Get total transactions and amount
    total_transactions = count_transactions_by_date(date)
    total_amount = calculate_total_amount_by_date(date)
    
    # Get transactions by status
    transactions_by_status_query = 
      from t in Transaction,
      where: t.transaction_date >= ^start_datetime and t.transaction_date <= ^end_datetime,
      select: %{
        status: t.status,
        count: count(t.id),
        amount: sum(t.amount)
      }
    
    transactions_by_status = Repo.all(transactions_by_status_query) || []
    
    # Get transactions by payment method
    transactions_by_payment_method_query = 
      from t in Transaction,
      where: t.transaction_date >= ^start_datetime and t.transaction_date <= ^end_datetime,
      group_by: t.payment_method,
      select: %{
        payment_method: t.payment_method,
        count: count(t.id),
        amount: sum(t.amount)
      }
    
    transactions_by_payment_method = Repo.all(transactions_by_payment_method_query) || []
    
    # Construct and return the report
    %{
      date: date,
      total_transactions: total_transactions,
      total_amount: total_amount,
      transactions_by_status: transactions_by_status,
      transactions_by_payment_method: transactions_by_payment_method
    }
  end
end  # End of module FleetMint.Payments

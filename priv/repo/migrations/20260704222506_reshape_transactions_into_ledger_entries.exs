defmodule FleetMint.Repo.Migrations.ReshapeTransactionsIntoLedgerEntries do
  use Ecto.Migration

  def up do
    drop constraint(:transactions, :transactions_status_check)
    drop constraint(:transactions, :transactions_payment_method_check)
    drop constraint(:transactions, :amount_must_be_positive)

    # Superseded by the new ledger_entries indexes created below.
    drop index(:transactions, [:reference_number])
    drop index(:transactions, [:user_id])
    drop index(:transactions, [:user_id, :payment_method])

    rename table(:transactions), :user_id, to: :recorded_by_id
    rename table(:transactions), :transaction_date, to: :occurred_at
    rename table(:transactions), to: table(:ledger_entries)

    # `ticket_id` was never added by any migration (dead Payments.Transaction
    # schema referenced a column that doesn't exist in version control) but
    # may be present on databases where it was added out-of-band; drop it if so.
    execute "ALTER TABLE ledger_entries DROP COLUMN IF EXISTS ticket_id"

    alter table(:ledger_entries) do
      add :entry_type, :string
      add :source_type, :string
      add :source_id, :bigint
      add :description, :string
      add :reverses_entry_id, references(:ledger_entries, on_delete: :nilify_all)
      remove :status
      modify :occurred_at, :utc_datetime, null: false
      modify :payment_method, :string, null: true
    end

    # Table is empty in practice (it only ever backed dead code), but backfill
    # defensively in case of stray rows before tightening the NOT NULL below.
    execute "UPDATE ledger_entries SET entry_type = 'adjustment', source_type = 'Legacy', source_id = id WHERE entry_type IS NULL"

    alter table(:ledger_entries) do
      modify :entry_type, :string, null: false
      modify :source_type, :string, null: false
      modify :source_id, :bigint, null: false
    end

    create index(:ledger_entries, [:source_type, :source_id])
    create index(:ledger_entries, [:entry_type])
    create index(:ledger_entries, [:occurred_at])
    create index(:ledger_entries, [:reverses_entry_id])
    create index(:ledger_entries, [:recorded_by_id])
    create unique_index(:ledger_entries, [:reference_number], where: "reference_number IS NOT NULL")

    create constraint(:ledger_entries, :ledger_entries_entry_type_check,
             check: "entry_type IN ('revenue','expense','refund','adjustment')")

    create constraint(:ledger_entries, :ledger_entries_payment_method_check,
             check:
               "payment_method IS NULL OR payment_method IN ('cash','card','mobile_money','airtel_money','mtn_money','bank_transfer')")

    create constraint(:ledger_entries, :ledger_entries_amount_sign_check,
             check: "entry_type = 'adjustment' OR amount >= 0")
  end

  def down do
    drop constraint(:ledger_entries, :ledger_entries_amount_sign_check)
    drop constraint(:ledger_entries, :ledger_entries_payment_method_check)
    drop constraint(:ledger_entries, :ledger_entries_entry_type_check)

    drop_if_exists unique_index(:ledger_entries, [:reference_number])
    drop_if_exists index(:ledger_entries, [:recorded_by_id])
    drop_if_exists index(:ledger_entries, [:reverses_entry_id])
    drop_if_exists index(:ledger_entries, [:occurred_at])
    drop_if_exists index(:ledger_entries, [:entry_type])
    drop_if_exists index(:ledger_entries, [:source_type, :source_id])

    alter table(:ledger_entries) do
      add :status, :string, default: "success"
      modify :payment_method, :string, null: false
      remove :reverses_entry_id
      remove :description
      remove :source_id
      remove :source_type
      remove :entry_type
    end

    rename table(:ledger_entries), to: table(:transactions)
    rename table(:transactions), :occurred_at, to: :transaction_date
    rename table(:transactions), :recorded_by_id, to: :user_id

    create constraint(:transactions, :transactions_status_check,
             check: "status IN ('success','failed','pending')")

    create constraint(:transactions, :transactions_payment_method_check,
             check: "payment_method IN ('cash','card','mobile_money')")

    create constraint(:transactions, :amount_must_be_positive, check: "amount > 0")

    create unique_index(:transactions, [:reference_number], where: "reference_number IS NOT NULL")
    create index(:transactions, [:user_id])
    create index(:transactions, [:user_id, :payment_method])
  end
end

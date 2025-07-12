defmodule BusCashingSystem.Repo.Migrations.OptimizeCoreTables do
  use Ecto.Migration

  def up do
    # 1. User table optimizations
    # Add unique index on email
    create unique_index(:users, [:email])
    
    # Add index on role for role-based lookups
    create index(:users, [:role])
    
    # 2. Bus table optimizations
    # Add unique index on bus number
    create unique_index(:buses, [:number])
    
    # Add constraint for positive capacity
    create constraint(:buses, :capacity_must_be_positive, check: "capacity > 0")
    
    # 3. Routes table optimizations
    # Add index on name for faster lookups
    create index(:routes, [:name])
    
    # Add indexes on start_point and end_point for location searches
    create index(:routes, [:start_point])
    create index(:routes, [:end_point])
    
    # 4. Transactions table optimizations
    # Update foreign key to use on_delete: :delete_all
    drop_if_exists index(:transactions, [:user_id])
    execute "ALTER TABLE transactions DROP CONSTRAINT IF EXISTS transactions_user_id_fkey"
    
    alter table(:transactions) do
      modify :user_id, references(:users, on_delete: :delete_all)
    end
    
    # Add index on user_id again
    create index(:transactions, [:user_id])
    
    # Add composite index on user_id and type for filtering transactions
    create index(:transactions, [:user_id, :type])
    
    # Add constraint for positive amount
    create constraint(:transactions, :amount_must_be_positive, check: "amount > 0")
    
    # 5. Create relationship between buses and routes
    # Add route_id to buses table (assuming a bus is assigned to a route)
    alter table(:buses) do
      add :route_id, references(:routes, on_delete: :nilify_all)
    end
    
    # Add index for the new foreign key
    create index(:buses, [:route_id])
  end

  def down do
    # 5. Remove relationship between buses and routes
    drop_if_exists index(:buses, [:route_id])
    
    alter table(:buses) do
      remove :route_id
    end
    
    # 4. Revert transactions table optimizations
    drop_if_exists constraint(:transactions, :amount_must_be_positive)
    drop_if_exists index(:transactions, [:user_id, :type])
    drop_if_exists index(:transactions, [:user_id])
    
    execute "ALTER TABLE transactions DROP CONSTRAINT IF EXISTS transactions_user_id_fkey"
    
    alter table(:transactions) do
      modify :user_id, references(:users, on_delete: :nothing)
    end
    
    create index(:transactions, [:user_id])
    
    # 3. Revert routes table optimizations
    drop_if_exists index(:routes, [:end_point])
    drop_if_exists index(:routes, [:start_point])
    drop_if_exists index(:routes, [:name])
    
    # 2. Revert bus table optimizations
    drop_if_exists constraint(:buses, :capacity_must_be_positive)
    drop_if_exists index(:buses, [:number])
    
    # 1. Revert user table optimizations
    drop_if_exists index(:users, [:role])
    drop_if_exists index(:users, [:email])
  end
  
  def change do
    # Migration uses up/down methods instead for better control
  end
end

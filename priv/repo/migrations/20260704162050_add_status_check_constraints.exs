defmodule FleetMint.Repo.Migrations.AddStatusCheckConstraints do
  use Ecto.Migration

  @doc false
  def change do
    create constraint(:buses, :buses_status_check,
      check: "status IN ('active','inactive','maintenance')")

    create constraint(:vehicles, :vehicles_vehicle_type_check,
      check: "vehicle_type IN ('bus','truck')")
    create constraint(:vehicles, :vehicles_status_check,
      check: "status IN ('active','inactive','maintenance','decommissioned')")

    create constraint(:bus_profiles, :bus_profiles_route_type_check,
      check: "route_type IN ('urban','intercity','rural','express')")

    create constraint(:drivers, :drivers_status_check,
      check: "status IN ('active','inactive','suspended')")

    create constraint(:schedules, :schedules_status_check,
      check: "status IN ('active','cancelled','suspended')")
    create constraint(:schedules, :schedules_validation_mode_check,
      check: "validation_mode IN ('static','live')")

    create constraint(:minibus_trips, :minibus_trips_status_check,
      check: "status IN ('scheduled','in_progress','completed','cancelled')")

    create constraint(:bookings, :bookings_status_check,
      check: "status IN ('confirmed','cancelled','checked_in','no_show')")
    create constraint(:bookings, :bookings_payment_method_check,
      check: "payment_method IN ('cash','airtel_money','mtn_money','card','bank_transfer')")

    create constraint(:tickets, :tickets_status_check,
      check: "status IN ('issued','boarded','cancelled','expired')")

    create constraint(:complaints, :complaints_type_check,
      check: "type IN ('complaint','suggestion')")
    create constraint(:complaints, :complaints_category_check,
      check: "category IN ('driver','conductor','bus_service','punctuality','other')")
    create constraint(:complaints, :complaints_status_check,
      check: "status IN ('pending','reviewed','resolved','dismissed')")

    create constraint(:freight_clients, :freight_clients_client_type_check,
      check: "client_type IN ('mining_company','farm','general_business','individual','government','ngo')")
    create constraint(:freight_clients, :freight_clients_status_check,
      check: "status IN ('active','suspended','blacklisted')")

    create constraint(:freight_orders, :freight_orders_status_check,
      check: "status IN ('pending','assigned','loading','in_transit','delivered','cancelled')")
    create constraint(:freight_orders, :freight_orders_cargo_type_check,
      check: "cargo_type IN ('copper_ore','coal','cobalt_ore','agricultural_produce','maize','fertilizer','cement','fuel','general_cargo','hazardous','refrigerated','timber','steel')")

    create constraint(:freight_trips, :freight_trips_status_check,
      check: "status IN ('scheduled','loading','in_transit','delivered','cancelled')")

    create constraint(:freight_invoices, :freight_invoices_status_check,
      check: "status IN ('draft','issued','paid','overdue','cancelled')")

    create constraint(:truck_profiles, :truck_profiles_truck_category_check,
      check: "truck_category IN ('rigid','articulated','tipper','flatbed','tanker','lowbed')")

    create constraint(:vehicle_maintenances, :vehicle_maintenances_service_type_check,
      check: "service_type IN ('oil_change','tire_replacement','brake_service','full_service','engine_repair','transmission','gearbox','electrical','bodywork','inspection','other')")
    create constraint(:vehicle_maintenances, :vehicle_maintenances_status_check,
      check: "status IN ('scheduled','in_progress','completed')")

    create constraint(:operation_logs, :operation_logs_category_check,
      check: "category IN ('general','incident','maintenance','finance','staff','passenger')")

    create constraint(:fuel_logs, :fuel_logs_fuel_type_check,
      check: "fuel_type IN ('diesel','petrol')")

    create constraint(:users, :users_role_check,
      check: "role IN ('admin','manager','cashier','operator')")

    create constraint(:transactions, :transactions_status_check,
      check: "status IN ('success','failed','pending')")
    create constraint(:transactions, :transactions_payment_method_check,
      check: "payment_method IN ('cash','card','mobile_money')")
  end
end

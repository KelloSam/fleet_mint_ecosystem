# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     FleetMint.Repo.insert!(%FleetMint.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.
alias FleetMint.Repo
alias FleetMint.Finance.Report
alias FleetMint.Finance.CashingReport

# Real data from Madithel Bus - May to July 2024
weeks = [
  %{
    start_date: ~D[2024-05-01], end_date: ~D[2024-05-04],
    days_worked: 4, expected_cashing: 6000, received_cashing: 2000,
    airtel_id: "CI240505.1200.G26935", debt_balance: 4000,
    expenditure: 2000, description: nil
  },
  %{
    start_date: ~D[2024-05-06], end_date: ~D[2024-05-11],
    days_worked: 6, expected_cashing: 9000, received_cashing: 4000,
    airtel_id: "CI240512.1105.K45009", debt_balance: 5000,
    expenditure: nil, description: "Driver change"
  },
  %{
    start_date: ~D[2024-05-13], end_date: ~D[2024-05-18],
    days_worked: 4, expected_cashing: 4000, received_cashing: 4000,
    airtel_id: "PP240518.2145.H91177", debt_balance: 0,
    expenditure: 2000, description: "New driver started"
  },
  %{
    start_date: ~D[2024-05-20], end_date: ~D[2024-05-25],
    days_worked: 6, expected_cashing: 6000, received_cashing: 3000,
    airtel_id: "PP240529.1943.H23716", debt_balance: 3000,
    expenditure: 1700, description: "Lusaka trip"
  },
  %{
    start_date: ~D[2024-05-27], end_date: ~D[2024-06-01],
    days_worked: 6, expected_cashing: 6000, received_cashing: 3780,
    airtel_id: "Cash in hand", debt_balance: 2220,
    expenditure: 2000, description: nil
  },
  %{
    start_date: ~D[2024-06-03], end_date: ~D[2024-06-09],
    days_worked: 7, expected_cashing: 6000, received_cashing: 3500,
    airtel_id: "PP240612.0152.M47821", debt_balance: 2500,
    expenditure: 5000, description: nil
  },
  %{
    start_date: ~D[2024-06-10], end_date: ~D[2024-06-15],
    days_worked: 4, expected_cashing: 6000, received_cashing: 1600,
    airtel_id: "PP240617.1156.L89442", debt_balance: 1400,
    expenditure: 3000, description: nil
  },
  %{
    start_date: ~D[2024-06-17], end_date: ~D[2024-06-22],
    days_worked: 6, expected_cashing: 6000, received_cashing: 5100,
    airtel_id: "PP240626.0241.J90853", debt_balance: 900,
    expenditure: 1000, description: nil
  },
  %{
    start_date: ~D[2024-07-01], end_date: ~D[2024-07-06],
    days_worked: 6, expected_cashing: 6000, received_cashing: 0,
    airtel_id: nil, debt_balance: 6000,
    expenditure: 2000, description: "No cashing collected"
  },
  %{
    start_date: ~D[2024-07-08], end_date: ~D[2024-07-13],
    days_worked: 6, expected_cashing: 6000, received_cashing: 0,
    airtel_id: nil, debt_balance: 6000,
    expenditure: nil, description: nil
  }
]

for week <- weeks do
  {:ok, report} = Repo.insert(%Report{
    start_date: week.start_date,
    end_date: week.end_date
  })

  Repo.insert!(%CashingReport{
    report_id: report.id,
    days_worked: week.days_worked,
    expected_cashing: week.expected_cashing,
    received_cashing: week.received_cashing,
    airtel_id: week.airtel_id,
    debt_balance: week.debt_balance,
    expenditure: week.expenditure,
    description: week.description
  })
end

IO.puts "Seeded #{length(weeks)} weeks of Madithel bus cashing data"

# Weeks 12-25 (July - October 2024)
remaining_weeks = [
  %{
    start_date: ~D[2024-07-15], end_date: ~D[2024-07-21],
    days_worked: nil, expected_cashing: nil, received_cashing: nil,
    airtel_id: nil, debt_balance: nil,
    expenditure: nil, description: nil
  },
  %{
    start_date: ~D[2024-07-22], end_date: ~D[2024-07-28],
    days_worked: nil, expected_cashing: nil, received_cashing: nil,
    airtel_id: nil, debt_balance: nil,
    expenditure: nil, description: nil
  },
  %{
    start_date: ~D[2024-07-29], end_date: ~D[2024-08-04],
    days_worked: nil, expected_cashing: nil, received_cashing: nil,
    airtel_id: nil, debt_balance: nil,
    expenditure: nil, description: nil
  },
  %{
    start_date: ~D[2024-08-05], end_date: ~D[2024-08-10],
    days_worked: nil, expected_cashing: nil, received_cashing: nil,
    airtel_id: nil, debt_balance: nil,
    expenditure: nil, description: nil
  },
  %{
    start_date: ~D[2024-08-11], end_date: ~D[2024-08-17],
    days_worked: nil, expected_cashing: nil, received_cashing: nil,
    airtel_id: nil, debt_balance: nil,
    expenditure: nil, description: nil
  },
  %{
    start_date: ~D[2024-08-18], end_date: ~D[2024-08-24],
    days_worked: 0, expected_cashing: 0, received_cashing: 0,
    airtel_id: nil, debt_balance: 0,
    expenditure: 0, description: "Week of accident"
  },
  %{
    start_date: ~D[2024-08-25], end_date: ~D[2024-08-31],
    days_worked: 0, expected_cashing: 0, received_cashing: 0,
    airtel_id: nil, debt_balance: 0,
    expenditure: 0, description: "Week of accident"
  },
  %{
    start_date: ~D[2024-09-02], end_date: ~D[2024-09-08],
    days_worked: nil, expected_cashing: nil, received_cashing: nil,
    airtel_id: nil, debt_balance: nil,
    expenditure: nil, description: nil
  },
  %{
    start_date: ~D[2024-09-09], end_date: ~D[2024-09-15],
    days_worked: nil, expected_cashing: nil, received_cashing: nil,
    airtel_id: nil, debt_balance: nil,
    expenditure: nil, description: nil
  },
  %{
    start_date: ~D[2024-09-16], end_date: ~D[2024-09-22],
    days_worked: nil, expected_cashing: nil, received_cashing: nil,
    airtel_id: nil, debt_balance: nil,
    expenditure: nil, description: nil
  },
  %{
    start_date: ~D[2024-09-23], end_date: ~D[2024-09-28],
    days_worked: nil, expected_cashing: nil, received_cashing: nil,
    airtel_id: nil, debt_balance: nil,
    expenditure: nil, description: nil
  },
  %{
    start_date: ~D[2024-09-29], end_date: ~D[2024-10-06],
    days_worked: 0, expected_cashing: 0, received_cashing: 0,
    airtel_id: nil, debt_balance: 0,
    expenditure: 0, description: "Driver in police cell"
  },
  %{
    start_date: ~D[2024-10-07], end_date: ~D[2024-10-13],
    days_worked: 0, expected_cashing: 0, received_cashing: 0,
    airtel_id: nil, debt_balance: 0,
    expenditure: 0, description: "Bus packed at police"
  },
  %{
    start_date: ~D[2024-10-14], end_date: ~D[2024-10-18],
    days_worked: nil, expected_cashing: nil, received_cashing: nil,
    airtel_id: nil, debt_balance: nil,
    expenditure: nil, description: "New driver started in Solwezi"
  }
]

for week <- remaining_weeks do
  {:ok, report} = Repo.insert(%Report{
    start_date: week.start_date,
    end_date: week.end_date
  })

  Repo.insert!(%CashingReport{
    report_id: report.id,
    days_worked: week.days_worked,
    expected_cashing: week.expected_cashing,
    received_cashing: week.received_cashing,
    airtel_id: week.airtel_id,
    debt_balance: week.debt_balance,
    expenditure: week.expenditure,
    description: week.description
  })
end

IO.puts "Seeded #{length(remaining_weeks)} more weeks (weeks 12-25)"

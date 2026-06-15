# FLEET MINT ECOSYSTEM
## Complete System Documentation

**Product Name:** Fleet Mint Ecosystem
**Built With:** Elixir / Phoenix Framework, PostgreSQL Database, Tailwind CSS
**Currency:** Zambian Kwacha (ZMW)
**Primary Client:** Madithel Bus Services — Zambia
**Purpose:** An all-in-one transport management and public booking system for bus companies and freight operators in Zambia

---

# TABLE OF CONTENTS

1. System Overview
2. User Roles and Access Levels
3. Module 1 — Authentication and Login
4. Module 2 — Dashboard
5. Module 3 — Fleet Management (Vehicles and Routes)
6. Module 4 — Passenger Transit (Schedules, Bookings, QR Tickets)
7. Module 5 — Freight and Haulage
8. Module 6 — Finance (Cashing Reports and Expenditures)
9. Module 7 — PDF Reports
10. Module 8 — Bus Companies (Operators)
11. Module 9 — Public Client Booking Portal
12. Module 10 — Seat Selection
13. Module 11 — Pickup and Boarding Stations
14. Module 12 — Real-Time Bus and Parcel Tracking
15. Module 13 — Real-Time Booking Notifications
16. Module 14 — Mobile App (Progressive Web App)
17. System Workflow — How Everything Connects
18. Developer / Installer Setup Guide

---

# 1. SYSTEM OVERVIEW

The Fleet Mint Ecosystem is a complete transport management platform designed for bus and freight companies operating in Zambia. It was built to solve a specific real-world problem: bus companies were managing their operations manually, using paper tickets, handwritten reports, and phone calls to track vehicles and communicate with passengers.

The system brings together every part of a transport business into one platform:

- Staff log in and manage their daily operations through a secure admin portal
- Passengers visit the public booking portal on their phone or computer, choose their bus company, select a route, pick their seat, and receive a QR-coded ticket — all without needing to create an account
- Staff receive instant notifications when a booking is made
- Drivers or conductors can post location updates so passengers and parcel senders can track the bus in real time
- Finance staff record daily cashing reports and expenditures and print PDF reports
- The system supports multiple bus companies on the same installation — each company gets its own page on the public portal

The system is also designed to scale beyond buses. The same platform handles truck freight operations, car hire fleet tracking, and parcel delivery tracking through a shared codebase.

---

# 2. USER ROLES AND ACCESS LEVELS

The system has four built-in staff roles. Each role controls what the user can see and do after logging in.

**Admin**
The highest level of access. An admin can do everything in the system including adding and removing users, managing bus companies, editing routes, schedules, vehicles, reports, and all financial records. There is typically one or two admins per company.

**Manager**
A manager has the same broad access as an admin but cannot delete or remove other users. A manager oversees operations, monitors bookings and revenue, and can post bus location updates. Managers can also add and edit bus companies (operators) and schedules.

**Cashier**
A cashier handles the daily booking counter operations. They can create bookings, print tickets, record cashing reports and expenditures, and view schedules. They cannot change system configuration or access user management.

**Driver / Conductor (planned)**
The system is built to support driver accounts for posting bus location checkpoint updates directly from their phone. Currently location updates are posted by any logged-in staff member from the schedule management page.

---

# 3. MODULE 1 — AUTHENTICATION AND LOGIN

**How to access:** Open the system URL in a browser and go to /login

The login page is a split-screen design. The left side shows the company branding and a bus graphic. The right side contains the login form. The page also displays the current date automatically.

Staff log in using their username or email address and their password.

**What happens after login:**
- The system records the exact time the staff member logged in. This is used to show who is currently on duty on the dashboard.
- The system checks the staff role and loads the correct dashboard view.
- The staff member is taken to the main dashboard.

**Staff ID:**
Every staff member has an auto-generated Staff ID shown as STAFF-0001, STAFF-0002, and so on. This is displayed on their dashboard profile card.

**Security:**
- All passwords are encrypted using industry-standard bcrypt hashing. No plain passwords are ever stored.
- Sessions are managed securely. Logging out clears the session completely.
- All internal pages require login. Anyone who tries to access a protected page without logging in is redirected to the login page.

---

# 4. MODULE 2 — DASHBOARD

**How to access:** After login, staff are taken to /dashboard automatically

The dashboard is the first screen a staff member sees after logging in. It shows everything relevant to the current day at a glance.

**Duty Profile Card**
At the top of the dashboard is a personal profile card for the logged-in staff member. It shows:
- Full name
- Staff ID (e.g. STAFF-0042)
- Role (Cashier, Manager, Admin)
- Phone number (if recorded)
- On duty since — the exact time they logged in today

**Today's Statistics**
Two live counters show the current day's activity:
- Total bookings made today
- Total revenue collected today in ZMW

These numbers update each time the dashboard is loaded.

**On Duty Today Panel**
This section shows a list of every staff member who has logged in today. It shows their name, role, and phone number. This helps managers know who is working at any given time without making phone calls.

**Quick Actions**
Shortcut buttons to the most commonly used parts of the system: New Booking, Schedules, Cashing Reports, Print Reports.

**Client Mobile App Advisory**
The dashboard includes instructions for how passengers can install the public booking portal on their phone as a mobile app (Android and iPhone). This helps staff guide passengers who ask how to use the app.

---

# 5. MODULE 3 — FLEET MANAGEMENT

Fleet Management covers two things: the physical vehicles and the routes they travel on.

---

## 5A. VEHICLES

**How to access:** Admin sidebar → All Vehicles

The system tracks two types of vehicles in a unified fleet register:

**Bus** — used for passenger transit
**Truck** — used for freight and haulage

Each vehicle record stores:
- Registration number (number plate)
- Make and model
- Year of manufacture
- Status: Active, Maintenance, or Inactive

**Bus Profile** (additional details for buses):
- Seating capacity (total number of seats)
- Bus type (standard, luxury, minibus, etc.)

**Truck Profile** (additional details for trucks):
- Payload capacity in tonnes
- Body type (flatbed, enclosed, refrigerated, etc.)

The vehicle register feeds directly into the scheduling system. When creating a schedule, staff select which bus is assigned to that trip. The seating capacity of that bus becomes the available seats for booking.

---

## 5B. ROUTES

**How to access:** Admin sidebar → Routes

Routes define the paths that buses travel. Each route record contains:

- **Route Name** — a short descriptive name, e.g. "Lusaka–Johannesburg Express"
- **Start Location** — the origin city or town, e.g. "Lusaka"
- **End Location** — the destination city or town, e.g. "Johannesburg, South Africa"
- **Distance** — in kilometres
- **Duration** — estimated travel time in minutes
- **Base Fare** — in ZMW
- **Status** — Active or Inactive
- **Description** — optional notes about the route
- **Intermediate Stops** — a list of towns or checkpoints the bus passes through, e.g. Kafue, Chirundu, Beit Bridge, Musina, Pretoria

The intermediate stops serve two important purposes:
1. On the public booking portal, passengers can select which stop they will board from
2. On the tracking page, the stops appear as a visual progress bar showing where the bus has reached

**International Routes:**
The system automatically detects international routes by checking if the destination contains known country names such as "South Africa", "Zimbabwe", "Botswana", "Namibia", "Mozambique", "Tanzania", "Malawi", "Congo", or "Angola". International routes are displayed in a separate section on the public portal with a passport and visa reminder.

---

# 6. MODULE 4 — PASSENGER TRANSIT

Passenger Transit covers the full cycle of a bus journey: from scheduling to booking to issuing a QR ticket.

---

## 6A. SCHEDULES

**How to access:** Admin sidebar → Transit → Schedules

A schedule represents one specific bus departure. It links together a bus company (operator), a route, and a vehicle, and defines when it runs.

Each schedule record contains:
- **Schedule Code** — auto-generated unique code, e.g. SCH-00123
- **Operator** — which bus company operates this trip (Power Tools, Jordan, Likili, etc.)
- **Route** — which route the bus travels
- **Vehicle** — which bus is assigned
- **Departure Time** — time of departure, e.g. 06:00
- **Estimated Arrival Time** — expected arrival time
- **Fare** — price in ZMW for this specific departure
- **Available Seats** — total seats that can be booked
- **Days of Operation** — which days of the week the bus runs (Mon, Tue, Wed, Thu, Fri, Sat, Sun)
- **Status** — Active, Suspended, or Cancelled
- **Notes** — optional instructions for staff or passengers

**Posting a Bus Location Update:**
From the schedule detail page, any logged-in staff member (driver, conductor, cashier, or manager) can post a location checkpoint. This is the mechanism that powers the public tracking system. Staff click a pre-loaded stop button or type the current location manually, optionally add a note (e.g. "30 minute delay at border"), and click Post Update. The location immediately becomes visible to anyone tracking that booking reference.

---

## 6B. BOOKINGS

**How to access:** Admin sidebar → Transit → Bookings

A booking is a confirmed seat reservation for a passenger. Bookings can be created in two ways:
1. By the cashier at the counter using the admin booking form
2. By the passenger themselves through the public booking portal

Each booking record stores:
- **Booking Reference** — a unique code starting with BK-, e.g. BK-0012345. This is the reference used for tracking.
- **Passenger Name**
- **Passenger Phone**
- **Passenger Email** (optional)
- **Seat Number** — the specific seat selected by the passenger
- **Pickup / Boarding Station** — the intermediate stop where the passenger will board (if they are not starting at the origin)
- **Travel Date** — the date of travel
- **Fare Paid** — amount paid in ZMW
- **Payment Method** — Cash, Airtel Money, MTN Money, Card, or Bank Transfer
- **Payment Reference** — mobile money transaction ID (optional)
- **Status** — Confirmed, Checked In, Cancelled, or No Show
- **Notes** — any special instructions

**Booking Status Flow:**
Confirmed → Checked In (when passenger boards) → journey complete
Confirmed → No Show (if passenger does not board) or Cancelled (if booking is cancelled)

---

## 6C. QR TICKETS

**How to access:** Tickets are generated automatically when a booking is created

Every confirmed booking automatically generates a QR-coded ticket. The ticket contains:
- Booking reference number
- Passenger name
- Travel date
- Route (From → To)
- Seat number
- Boarding station (pickup point)
- Fare paid
- QR code — encodes the booking reference and a security token

The conductor scans the QR code when the passenger boards. The system validates the ticket and confirms the passenger is on the correct bus for the correct date.

Tickets can be printed (the passenger clicks Print Ticket) or saved as a screenshot on a phone.

---

# 7. MODULE 5 — FREIGHT AND HAULAGE

**How to access:** Admin sidebar → Freight section

The freight module manages the truck side of the business. It is designed for companies that run both passenger buses and cargo trucks.

**Freight Clients**
A register of companies or individuals who regularly send cargo. Each client record stores their contact details and company name.

**Freight Orders**
A cargo order links a client to a specific shipment. It records what is being shipped, from where, to where, the agreed rate, and the current status.

**Freight Trips**
A trip is a physical truck journey. It is assigned to a vehicle and a driver. As the truck moves, milestones are posted (like checkpoints) showing progress. The trip status can be updated to: Planned, In Progress, Delivered, or Cancelled.

**Freight Invoices**
After a trip is complete, an invoice is generated for the client. The system records whether the invoice has been paid.

---

# 8. MODULE 6 — FINANCE

---

## 8A. CASHING REPORTS

**How to access:** Admin sidebar → Finance → Cashing Reports

A cashing report is the daily record of money collected versus money expected for a specific bus or service. The cashier fills this in at the end of each working day or period.

Each report records:
- **Report Date** — the date the cashing covers (defaults to today)
- **Expected Cashing** — the amount the bus should have collected based on tickets sold
- **Received Cashing** — the amount actually handed in
- **Variance** — the difference (automatically calculated)
- **Airtel/MTN Transaction ID** — the mobile money reference for the payment
- **Debt Balance** — any outstanding amount carried over
- **Expenditure** — any costs deducted
- **Description** — notes about the day (e.g. "Driver changed", "Lusaka trip")

These reports feed directly into the PDF daily and weekly reports for management review.

---

## 8B. EXPENDITURES

**How to access:** Admin sidebar → Finance → Expenditures

Expenditures record money spent on operational costs. Each entry captures:
- Date
- Category (Fuel, Maintenance, Driver Allowance, etc.)
- Amount in ZMW
- Description
- Approved by

---

# 9. MODULE 7 — PDF REPORTS

**How to access:** Admin sidebar → Reports → Print / PDF Reports

The system can generate professional PDF documents for printing or saving. All PDFs open in a new browser tab and can be printed or downloaded.

**Daily Report**
A summary of all cashing activity for a selected date. Shows each cashier's expected versus received amounts, variances, and the daily total. Used by management for daily financial oversight.

**Weekly Report**
A detailed week-by-week breakdown of revenue, expenditure, and debt balance. Shows profit/loss trends over time. Used for management meetings and financial planning.

**Receipt**
A printable receipt for an individual cashing report entry. Given to drivers or cashiers as proof of payment submission.

**Expenditure Report**
A summary of all costs incurred within a selected period. Used for accounting and budget reviews.

---

# 10. MODULE 8 — BUS COMPANIES (OPERATORS)

**How to access:** Admin sidebar → Transit → Bus Companies

The Operators module allows the system to serve multiple bus companies from one installation. This is the foundation of the public multi-company booking portal.

Each operator record contains:
- **Company Name** — e.g. Jordan Bus Services
- **URL Slug** — a short web address identifier, e.g. "jordan" (used in /book/jordan)
- **Tagline** — a short motto shown on the portal, e.g. "Your Journey, Our Priority"
- **Contact Phone** — displayed on the portal so passengers can call
- **Contact Email** — displayed on the portal
- **Brand Color** — a color chosen by or for the company, shown as their color badge on the portal
- **Active Status** — only active companies appear on the public portal

**Pre-loaded companies in the system:**
1. Power Tools Bus Services (red)
2. Jordan Bus Services (green)
3. Likili Bus Services (purple)
4. Rayon Bus Services (orange)
5. Oasis Bus Services (teal)
6. Madithel Bus Services (blue)

Additional companies can be added at any time by an admin or manager.

**How operators connect to schedules:**
When a schedule is created, the admin assigns it to an operator. That schedule then automatically appears on that company's page on the public portal. If no operator is assigned, the schedule only appears in the internal admin view.

---

# 11. MODULE 9 — PUBLIC CLIENT BOOKING PORTAL

**How to access:** /book (no login required)

The public booking portal is the passenger-facing side of the system. Any person with a phone or computer can visit /book without creating an account or logging in.

The portal works in four screens:

---

**Screen 1 — Choose a Bus Company (/book)**

The passenger sees a grid of all active bus companies. Each company is shown as a card with:
- Company initial letter in their brand color
- Company name and tagline
- Number of active routes

At the bottom of the page there is a "How to Book" step-by-step guide and a tip on how to install the portal as a mobile app.

---

**Screen 2 — Choose a Route (/book/company-name)**

After selecting a company (e.g. Jordan), the passenger sees all routes that company operates. Routes are grouped into two sections:
- **Domestic Routes** — all destinations within Zambia
- **International / Cross-border Routes** — destinations in South Africa, Zimbabwe, Botswana, and other neighbouring countries. International routes show a passport and visa reminder notice.

Each route card displays:
- Origin and destination (e.g. Lusaka → Johannesburg, South Africa)
- Departure time
- Estimated arrival time (or travel duration)
- Fare in ZMW
- Number of available seats (turns orange when 5 or fewer seats remain, shows "Fully Booked" when 0)
- Days of operation shown as colored day circles (M T W T F S S)
- Bus registration number and seat capacity
- "Select Seat" button

---

**Screen 3 — Choose a Date, Seat, and Enter Details (/book/company-name/schedule-id)**

This is the booking form. It has four sections:

**Travel Date**
A date picker defaults to today. The passenger selects their travel date. Changing the date reloads the seat map to show current availability for that date.

**Seat Map**
A visual diagram of the bus interior. Seats are arranged in rows of four (columns A, B, aisle, C, D). Each seat is shown as a numbered box:
- Green = available
- Red = already booked (cannot be selected)
- Blue = the passenger's selected seat

The passenger taps their preferred seat. The seat number is automatically recorded.

**Pickup / Boarding Station** (shown only when the route has intermediate stops)
If the route passes through towns between origin and destination, the passenger sees a list of stops as radio buttons. They tap the town where they will board. This is important for passengers who are not starting from the main origin city — for example, a passenger in Chirundu selecting a bus going from Lusaka to Johannesburg.

**Passenger Details**
Full name and phone number (required). Email is optional.

**Payment**
The passenger selects their payment method (Cash at Counter, Airtel Money, MTN Mobile Money, or Card). The fare is displayed clearly. Payment is confirmed at the bus counter or via mobile money before boarding.

---

**Screen 4 — Ticket (/book/ticket/BK-XXXXXXX)**

After submitting the booking form, the passenger receives their QR ticket. The ticket shows:
- Booking reference (e.g. BK-0012345)
- QR code for conductor scanning
- Passenger name
- Travel date
- Route (From → To)
- Seat number
- Boarding point (if an intermediate stop was selected)
- Fare paid and payment method

The ticket has two action buttons:
- **Print Ticket** — opens the browser print dialog. The QR code prints cleanly.
- **Track This Bus** — takes the passenger directly to the tracking page with their reference pre-loaded.
- **Book Another Journey** — returns to the company list.

---

# 12. MODULE 10 — SEAT SELECTION

The seat map system ensures that no two passengers can book the same seat on the same bus for the same date.

**How it works:**
When the booking form is loaded, the server checks the database for all existing bookings on that schedule for the selected date. Any seat that already has a confirmed or checked-in booking is marked as taken (shown in red). The passenger can only click seats shown in green.

When the passenger selects a seat and submits the form, the system saves the seat number to the booking record. If two passengers somehow try to book the same seat at exactly the same time, the unique constraint in the database ensures only one succeeds.

**Seat numbering:**
Seats are numbered 1 through to the total capacity of the bus (e.g. 1–44 for a 44-seat bus). The numbering goes left to right, front to back: seat 1 is front-left (column A), seat 2 is front-second-left (column B), seat 3 is front-right-centre (column C), seat 4 is front-right (column D), then seat 5 starts the next row.

---

# 13. MODULE 11 — PICKUP AND BOARDING STATIONS

This feature solves a common problem in long-distance bus travel: not all passengers start from the main origin city. A bus running Lusaka → Johannesburg passes through many towns, and passengers in those towns need to board along the way.

**How it is set up (admin):**
When creating or editing a route, the admin adds intermediate stops in order. For example, for the Lusaka–Johannesburg route, the stops might be:
Kafue → Chirundu → Beit Bridge → Musina → Pretoria → Johannesburg

These are entered one by one in the route form under "Intermediate Stops." The origin (Lusaka) and destination (Johannesburg) are added automatically to the full list.

**How the passenger uses it:**
On the booking form, if the route has stops, a "Pickup / Boarding Point" section appears. The passenger taps the town where they will board. This selection is saved with the booking and printed on the QR ticket.

**On the QR ticket:**
The boarding station is shown clearly with a pin icon: 📍 Chirundu

**On the tracking page:**
All stops appear in order as a vertical progress bar. The passenger's personal boarding stop is labelled "Your pickup point" so they can also see how far the bus is from their boarding point.

**Conductor's role:**
The conductor sees all boarding stations for the day's passengers. When the bus reaches Chirundu, they know which passengers are boarding there and can verify their QR tickets.

---

# 14. MODULE 12 — REAL-TIME BUS AND PARCEL TRACKING

**Public URL:** /track (no login required)

The tracking system lets anyone follow the real-time location of a bus using a booking reference number. It serves three groups of users:

---

**Passengers**
A passenger who has booked a seat can track the bus before their travel date or on the day of travel. They go to /track, enter their booking reference (e.g. BK-0012345), and see exactly where the bus currently is.

---

**Parcel Senders and Recipients**
Bus companies in Zambia regularly carry small parcels for customers. A person sends a package on the bus and the recipient wants to know where it is and when it will arrive.

**How it works for parcels:**
When a parcel is handed to the cashier or conductor, the staff create a booking in the system. The passenger name field is filled with the sender's name or "PARCEL – [recipient name]". The staff give the booking reference to the parcel sender. The sender (or recipient) goes to /track and enters that reference to follow the bus.

---

**Car Hire and Fleet Companies**
Car hire operators who have vehicles running on registered routes can use the same tracking system. If the vehicle's trip is logged in the system, they use the booking reference to track the vehicle's movements.

---

**How location updates are posted (staff side):**

Drivers, conductors, cashiers, or managers can post a location update from the schedule detail page in the admin portal. The page shows:

1. **Quick-pick stop buttons** — the full list of route stops is shown as clickable buttons. The staff member simply taps "Chirundu" and the location field fills in automatically.
2. **Free text field** — for locations not on the scheduled stops (e.g. "Chirundi Police Checkpoint" or "Petroda Petrol Station, Beit Bridge")
3. **Notes field** — for additional information, e.g. "Border queue — approximately 2 hour delay" or "Bus has resumed journey after tyre change"

After posting, the update is saved with the timestamp and the name of the staff member who posted it. It immediately appears on the public tracking page.

---

**What the tracking page shows:**

**Current Location Card** — shows the most recent location in large text with the time it was reported and who reported it. If no update has been posted yet, it says "Not Yet Departed."

**Route Progress Bar** — a vertical list of all stops on the route. Each stop shows as a circle:
- Blue filled circle with a tick mark = already passed
- Green circle with a dot = current location (the bus is here now)
- Empty grey circle = not yet reached

The passenger's boarding station is highlighted with "Your pickup point."

**Location History** — all updates posted for that day are listed below in reverse order (newest first), showing the time and any notes.

**Call the Company Button** — at the bottom of the tracking page, a button allows the passenger to call the bus company directly with one tap.

---

# 15. MODULE 13 — REAL-TIME BOOKING NOTIFICATIONS

This feature is designed for cashiers and managers working at the counter. When a passenger books a ticket through the public portal, a notification toast (popup) appears on the screen of every logged-in staff member without them needing to refresh the page.

**How it works:**
The notification system runs silently in the background of every admin page. Every 30 seconds, the system checks for new bookings. When a new booking is found, a green popup appears in the top-right corner of the screen showing:
- Passenger name
- Seat number (if selected)
- Travel date
- Booking reference

The popup automatically disappears after 8 seconds or can be dismissed manually. A shrinking bar at the bottom of the popup shows the time remaining.

This means that even when a cashier is busy at the counter with another customer, they will see the popup and know that a new booking has just come in from the portal.

---

# 16. MODULE 14 — MOBILE APP (PROGRESSIVE WEB APP)

**The public booking portal at /book works as a mobile app without needing the Google Play Store or Apple App Store.**

This is achieved using Progressive Web App (PWA) technology. The app can be installed directly from the browser.

**How to install on Android:**
1. Open /book in Google Chrome
2. Tap the three dots menu in the top-right corner
3. Select "Add to Home Screen"
4. The app icon appears on the home screen
5. Tap it to open — it launches like a regular app, full screen, no browser bar

**How to install on iPhone:**
1. Open /book in Safari
2. Tap the Share button (the box with an arrow pointing up)
3. Scroll down and tap "Add to Home Screen"
4. Tap Add
5. The app icon appears on the home screen

The app icon is named "MadithBus" with a dark blue background. Once installed, it opens in standalone mode — it looks and feels like a native app.

**Who should install the app:**
- Regular commuters who frequently book tickets
- People in remote areas who want quick access to booking
- Parcel senders who want to track their deliveries easily

Staff on the dashboard can guide passengers through the installation steps. The dashboard also shows a QR code process that explains how the QR ticket works from booking to boarding.

---

# 17. SYSTEM WORKFLOW — HOW EVERYTHING CONNECTS

The following describes the complete journey of a passenger booking, from first visit to boarding:

**Step 1 — Passenger visits /book on phone**
The passenger opens the public portal. They see all bus companies. They tap Jordan Bus Services.

**Step 2 — Passenger selects a route**
They see all Jordan routes. They find "Lusaka → Johannesburg" with a departure at 06:00, fare ZMW 850, and 32 available seats. It runs Monday, Wednesday, Friday. They tap "Select Seat."

**Step 3 — Passenger fills in the booking form**
- They select a travel date
- The seat map loads — red seats are taken, green seats are free
- They tap Seat 14 — it turns blue
- They scroll to Pickup/Boarding Station and tap "Chirundu" — they will board the bus there, not in Lusaka
- They enter their name and phone number
- They select "Airtel Money" as payment method
- They tap "Confirm Booking · ZMW 850"

**Step 4 — Booking is saved and ticket generated**
The system saves the booking with reference BK-0098765. A QR ticket is generated instantly. The passenger sees their ticket with the QR code, their seat (14), and boarding point (Chirundu).

**Step 5 — Staff receive a notification**
Within 30 seconds, every logged-in cashier and manager sees a green popup: "New Booking! — [Passenger Name] · Seat 14 · 2026-06-15 · BK-0098765"

**Step 6 — Passenger tracks the bus**
On the morning of travel, the passenger goes to /track or taps "Track This Bus" on their ticket. They enter BK-0098765. The page shows the bus is currently at "Kafue" — it has left Lusaka and is on the way to Chirundu.

**Step 7 — Staff post location updates**
A cashier or conductor at each checkpoint posts an update. They go to Admin → Schedules → view the schedule → tap "Chirundu" in the quick-pick buttons → click Post Update. The tracking page updates immediately.

**Step 8 — Passenger boards in Chirundu**
The conductor sees in their booking list that seat 14 (BK-0098765) boards at Chirundu. The passenger shows their QR code. The conductor scans it. The booking status changes to Checked In.

**Step 9 — Journey continues to Johannesburg**
The bus continues posting checkpoints: Beit Bridge, Musina, Pretoria, Johannesburg. Anyone tracking the booking can follow the full journey.

---

# 18. DEVELOPER / INSTALLER SETUP GUIDE

This section is written for the software developer or installer who sets up the system for a new client bus company.

---

## What you do ONCE when you install the system:

**1. Set up the database and server**
The system runs on an Elixir/Phoenix server with a PostgreSQL database. Run `mix ecto.migrate` to create all database tables.

**2. Create the first admin user**
Add the first admin account through the database seed file or registration page. All subsequent users are created by this admin from within the system.

**3. Add bus companies (operators)**
Go to Admin → Bus Companies → Add Company. For each company:
- Enter the company name, URL slug (e.g. "jordan" for /book/jordan), tagline, contact phone, contact email, and choose a brand color
- Set Active to yes

Five companies are pre-loaded in the seed data: Power Tools, Jordan, Likili, Rayon, Oasis, and Madithel.

**4. Enter routes for each company**
Go to Admin → Routes → Add New Route. For each route the company operates:
- Route name, e.g. "Lusaka–Johannesburg"
- Start location: Lusaka
- End location: Johannesburg, South Africa
- Distance: 1,900 km
- Duration: 1,200 minutes (20 hours)
- Base fare: (can be overridden per schedule)
- Intermediate stops: Kafue, Chirundu, Beit Bridge, Musina, Pretoria (add each one with the + Add stop button)

**5. Register vehicles**
Go to Admin → All Vehicles → Add Vehicle. For each bus:
- Registration number (plate)
- Make, model, year
- Vehicle type: Bus
- Bus profile: seating capacity (e.g. 44), bus type

**6. Create schedules**
Go to Admin → Schedules → New Schedule. For each departure:
- Assign it to the operator (company)
- Assign the route
- Assign the vehicle
- Set departure time, estimated arrival, fare, available seats, days of week

As soon as a schedule is saved and set to Active, it immediately appears on the public booking portal under that company's page.

---

## What the client (bus company) does themselves after training:

- Post daily location updates from the schedule page
- Record cashing reports at end of each day
- Record expenditures
- Create counter bookings for walk-in passengers
- Print daily and weekly PDF reports
- Add staff accounts for new employees
- Update available seats when a vehicle is changed

---

## Summary of web addresses:

| Address | Who uses it | What it does |
|---|---|---|
| /login | Staff | Staff login page |
| /dashboard | Staff | Main admin dashboard |
| /schedules | Staff | Manage bus schedules |
| /bookings | Staff | View and manage all bookings |
| /routes | Staff | Manage routes |
| /vehicles | Staff | Manage fleet |
| /operators | Staff | Manage bus companies |
| /cashing_reports | Staff | Daily cashing records |
| /expenditures | Staff | Expense records |
| /admin/reports | Staff | Print PDF reports |
| /book | Public | Passenger booking portal |
| /book/jordan | Public | Jordan's routes and bookings |
| /track | Public | Track a bus or parcel |
| /book/ticket/BK-xxx | Public | View a QR ticket |

---

*End of Documentation*

**System:** Fleet Mint Ecosystem
**Version:** 1.0
**Developer:** Built with Elixir / Phoenix Framework
**Date:** June 2026

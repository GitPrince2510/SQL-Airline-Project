# Airline Reservation System (MySQL)

## Overview
A small airline reservation SQL project built with MySQL. It models Flights, Seats, Customers and Bookings with triggers to manage seat allocation and cancellation.

## Contents
- `schema/` — create DB & tables
- `data/` — sample data inserts
- `triggers/` — booking/cancellation triggers
- `queries/` — flight search, available seats, booking report
- `diagrams/` — ER diagram export

## How to run
1. Open MySQL Workbench and connect.
2. Execute script in this order:
   - `schema/01_create_database`
   - `schema/02_create_tables`
   - `schema/03_constraints_indexes`
   - `data/04_insert_sample_data`
   - `triggers/05_triggers`
3. Run queries from `queries/` to test.

## Notes
- Using `InnoDB` for FK and transactional behavior.
- Triggers enforce seat availability and auto-free seats on cancellation/deletion.
- Booking reference needs to be unique — you can generate `BRxxxx` values externally.

## Author
Praveen Kumar Mahawar

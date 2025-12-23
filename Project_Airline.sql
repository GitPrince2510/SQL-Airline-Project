USE airline_db;
-- Table creation
CREATE TABLE Customer (
  customer_id INT AUTO_INCREMENT PRIMARY KEY,
  first_name VARCHAR(80) NOT NULL,
  last_name VARCHAR(80) NOT NULL,
  email VARCHAR(150) UNIQUE,
  phone VARCHAR(20),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE Flight (
  flight_id INT AUTO_INCREMENT PRIMARY KEY,
  flight_number VARCHAR(10) NOT NULL UNIQUE,
  origin VARCHAR(100) NOT NULL,
  destination VARCHAR(100) NOT NULL,
  departure_datetime DATETIME NOT NULL,
  arrival_datetime DATETIME NOT NULL,
  aircraft VARCHAR(100),
  total_seats INT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)ENGINE=InnoDB;

CREATE TABLE Seat (
  seat_id INT AUTO_INCREMENT PRIMARY KEY,
  flight_id INT NOT NULL,
  seat_number VARCHAR(6) NOT NULL,
  seat_class ENUM('Economy','Premium','Business','First') DEFAULT 'Economy',
  fare DECIMAL(10,2) NOT NULL,
  is_available BOOLEAN DEFAULT 1,
  CONSTRAINT uniq_flight_seat UNIQUE (flight_id, seat_number),
  FOREIGN KEY (flight_id) REFERENCES Flight(flight_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Booking (
  booking_id INT AUTO_INCREMENT PRIMARY KEY,
  booking_reference VARCHAR(12) NOT NULL UNIQUE,
  customer_id INT NOT NULL,
  flight_id INT NOT NULL,
  seat_id INT,                        
  booking_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  status ENUM('CONFIRMED','CANCELLED','PENDING') DEFAULT 'PENDING',
  amount_paid DECIMAL(10,2) DEFAULT 0.00,
  CONSTRAINT fk_booking_customer FOREIGN KEY (customer_id) REFERENCES Customer(customer_id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_booking_flight FOREIGN KEY (flight_id) REFERENCES Flight(flight_id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_booking_seat FOREIGN KEY (seat_id) REFERENCES Seat(seat_id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

CREATE INDEX idx_flight_route ON Flight (origin, destination, departure_datetime);
CREATE INDEX idx_seat_flight_class ON Seat (flight_id, seat_class, is_available);


ALTER TABLE Flight
ADD CONSTRAINT chk_times CHECK (arrival_datetime > departure_datetime);

-- Sample data entries
INSERT INTO Customer (first_name, last_name, email, phone)
VALUES
('Aditya', 'Sharma', 'adi24@gmail.com', '9678452321'),
('Barkha', 'Bisht', 'barkha12@gmail.com', '7456218391'),
('Chirayu', 'Kumar', 'chirayu56@gmail.com', '9785437681'),
('Keshav', 'Shukla', 'shukla23@outlook.com', '9887456123'),
('Hardik', 'Kushwah', 'hdkush46@yahoo.com', '9865798645'),
('Gunjan', 'Verma', 'gjverma78@gmail.com', '7976234581'),
('Praveen', 'Mahawar', 'pmahawar25@gmail.com', '9660450789'),
('Shilpi', 'DSouza', 'shilpi07@outlook.com', '7649524616');

INSERT INTO Flight (flight_number, origin, destination, departure_datetime, arrival_datetime, aircraft, total_seats)
VALUES
('AI101','Delhi','Mumbai','2025-12-05 08:00:00','2025-12-05 10:00:00','A320', 6),
('AI202','Mumbai','Bengaluru','2025-12-06 13:30:00','2025-12-06 15:10:00','A320', 6);

-- Seats for flight AI101
INSERT INTO Seat (flight_id, seat_number, seat_class, fare)
VALUES
(1,'1A','Business', 8000.00),
(1,'1B','Business', 8000.00),
(1,'2A','Economy', 3500.00),
(1,'2B','Economy', 3500.00),
(1,'3A','Economy', 3500.00),
(1,'3B','Economy', 3500.00);

-- Seats for flight AI202
INSERT INTO Seat (flight_id, seat_number, seat_class, fare)
VALUES
(2,'1A','Business', 9000.00),
(2,'1B','Business', 9000.00),
(2,'2A','Economy', 4000.00),
(2,'2B','Economy', 4000.00),
(2,'3A','Economy', 4000.00),
(2,'3B','Economy', 4000.00);

-- 05_triggers.sql

DELIMITER $$

-- Prevent booking a seat that is already unavailable
CREATE TRIGGER before_booking_insert
BEFORE INSERT ON Booking
FOR EACH ROW
BEGIN
 DECLARE v_available TINYINT;

  IF NEW.seat_id IS NOT NULL THEN
    SELECT is_available
    INTO v_available
    FROM Seat
    WHERE seat_id = NEW.seat_id
    FOR UPDATE;

    IF v_available <> 1 THEN
      SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Seat not available';
    END IF;
  END IF;
END$$

-- After booking: mark seat unavailable when booking is CONFIRMED
CREATE TRIGGER after_booking_insert
AFTER INSERT ON Booking
FOR EACH ROW
BEGIN
  IF NEW.seat_id IS NOT NULL AND NEW.status = 'CONFIRMED' THEN
    UPDATE Seat SET is_available = 0 WHERE seat_id = NEW.seat_id;
  END IF;
END$$

-- On booking status change: when changed to CANCELLED -> free seat
CREATE TRIGGER after_booking_update
AFTER UPDATE ON Booking
FOR EACH ROW
BEGIN
 DECLARE v_available2 TINYINT;
  -- If status changed from non-cancelled to cancelled, free seat
  IF OLD.status <> 'CANCELLED' AND NEW.status = 'CANCELLED' AND OLD.seat_id IS NOT NULL THEN
    UPDATE Seat SET is_available = 1 WHERE seat_id = OLD.seat_id;
  END IF;

  -- If status changed from CANCELLED to CONFIRMED and seat is available, reserve it
  IF OLD.status = 'CANCELLED' AND NEW.status = 'CONFIRMED' AND NEW.seat_id IS NOT NULL THEN
    
    SELECT is_available INTO v_available2 FROM Seat WHERE seat_id = NEW.seat_id FOR UPDATE;
    IF v_available2 <> 1 THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Seat not available to re-confirm';
    ELSE
      UPDATE Seat SET is_available = 0 WHERE seat_id = NEW.seat_id;
    END IF;
  END IF;
END$$

-- Optional: On DELETE booking -> free seat (if deleted)
CREATE TRIGGER after_booking_delete
AFTER DELETE ON Booking
FOR EACH ROW
BEGIN
  IF OLD.seat_id IS NOT NULL AND OLD.status = 'CONFIRMED' THEN
    UPDATE Seat SET is_available = 1 WHERE seat_id = OLD.seat_id;
  END IF;
END$$

DELIMITER ;

INSERT INTO Booking (booking_reference, customer_id, flight_id, seat_id, status, amount_paid)
VALUES ('BR1001', 1, 1, 5, 'CONFIRMED', 3500.00),
('BR1002', 2, 1, 2, 'CONFIRMED', 8000.0),
('BR2001', 4, 2, 11, 'CONFIRMED', 4000.0),
('BR2002', 3, 2, 7, 'CONFIRMED', 9000.0),
('BR1003', 7, 1, 1, 'CONFIRMED', 8000.0),
('BR2003', 8, 2, 12, 'CONFIRMED', 4000.0);

-- Queries/06_flight_search_and_seats
-- 1) Search flights by origin, destination, and date
-- Example: search Delhi -> Mumbai on 2025-12-05
SELECT * FROM Flight
WHERE origin = 'Delhi' AND destination = 'Mumbai'
  AND DATE(departure_datetime) = '2025-12-05';

-- 2) Available seats for a flight (all classes)
SELECT seat_id, seat_number, seat_class, fare
FROM Seat
WHERE flight_id = 1 AND is_available = 1
ORDER BY seat_class DESC, seat_number;

-- 3) Available seats by class and cheapest first
SELECT seat_id, seat_number, fare
FROM Seat
WHERE flight_id = 1 AND seat_class = 'Economy' AND is_available = 1
ORDER BY fare ASC;

-- 4) Book a seat (example)
-- Note: make sure seat is available; triggers will check it
INSERT INTO Booking (booking_reference, customer_id, flight_id, seat_id, status, amount_paid)
VALUES ('BR1002', 2, 1, 2, 'CONFIRMED', 3500.00);

-- Queries/07_reports_and_summary
CREATE OR REPLACE VIEW booking_summary AS
SELECT
  b.booking_id,
  b.booking_reference,
  b.booking_date,
  b.status,
  c.customer_id,
  CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
  f.flight_id,
  f.flight_number,
  f.origin,
  f.destination,
  f.departure_datetime,
  s.seat_number,
  s.seat_class,
  b.amount_paid
FROM Booking b
LEFT JOIN Customer c ON b.customer_id = c.customer_id
LEFT JOIN Flight f ON b.flight_id = f.flight_id
LEFT JOIN Seat s ON b.seat_id = s.seat_id;

-- Show all confirmed bookings
SELECT * FROM booking_summary WHERE status = 'CONFIRMED';
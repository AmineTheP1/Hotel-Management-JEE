
   ========================= */
CREATE TABLE room_types (
    room_type_id   INT AUTO_INCREMENT PRIMARY KEY,
    hotel_id       BIGINT       NOT NULL,
    name           VARCHAR(100) NOT NULL,             -- Standard, Deluxe, Suite…
    description    TEXT,
    max_guests     INT          NOT NULL,
    base_price     DECIMAL(10,2) NOT NULL,            -- prix par nuit de base
    FOREIGN KEY (hotel_id) REFERENCES hotels(hotel_id)
);

CREATE TABLE rooms (
    room_id        BIGINT AUTO_INCREMENT PRIMARY KEY,
    hotel_id       BIGINT NOT NULL,
    room_type_id   INT    NOT NULL,
    room_number    VARCHAR(20) NOT NULL,
    floor          INT,
    status         ENUM('available','occupied','maintenance','cleaning','out_of_service') DEFAULT 'available',
    last_status_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(room_number, hotel_id),
    FOREIGN KEY (hotel_id)     REFERENCES hotels(hotel_id),
    FOREIGN KEY (room_type_id) REFERENCES room_types(room_type_id)
);

CREATE TABLE room_status_history (
    id            BIGINT AUTO_INCREMENT PRIMARY KEY,
    room_id       BIGINT    NOT NULL,
    previous_status ENUM('available','occupied','maintenance','cleaning','out_of_service'),
    new_status    ENUM('available','occupied','maintenance','cleaning','out_of_service') NOT NULL,
    changed_by    BIGINT    NOT NULL,                -- user_id
    changed_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (room_id)    REFERENCES rooms(room_id),
    FOREIGN KEY (changed_by) REFERENCES users(user_id)
);

/* =========================
   4. RÉSERVATIONS & SÉJOURS
   ========================= */
CREATE TABLE bookings (
    booking_id     BIGINT AUTO_INCREMENT PRIMARY KEY,
    client_id      BIGINT    NOT NULL,
    hotel_id       BIGINT    NOT NULL,
    room_id        BIGINT,
    check_in_date  DATE      NOT NULL,
    check_out_date DATE      NOT NULL,
    guests         INT       DEFAULT 1,
    status         ENUM('pending','confirmed','checked_in','checked_out','cancelled','no_show') DEFAULT 'pending',
    created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (client_id) REFERENCES users(user_id),
    FOREIGN KEY (hotel_id)  REFERENCES hotels(hotel_id),
    FOREIGN KEY (room_id)   REFERENCES rooms(room_id)
);

CREATE TABLE booking_guests (           -- pour gérer >1 invité par réservation
    booking_id  BIGINT NOT NULL,
    full_name   VARCHAR(150) NOT NULL,
    passport_no VARCHAR(40),
    PRIMARY KEY (booking_id, full_name),
    FOREIGN KEY (booking_id) REFERENCES bookings(booking_id)
);

/* =========================
   5. PAIEMENTS
   ========================= */
CREATE TABLE payment_methods (          -- carte, crypto, cash, etc.
    method_id    INT AUTO_INCREMENT PRIMARY KEY,
    name         VARCHAR(50) NOT NULL,  -- Visa, MasterCard, BTC
    type         ENUM('card','crypto','cash','transfer') NOT NULL
);

CREATE TABLE payments (
    payment_id    BIGINT AUTO_INCREMENT PRIMARY KEY,
    booking_id    BIGINT  NOT NULL,
    method_id     INT     NOT NULL,
    amount        DECIMAL(10,2) NOT NULL,
    currency      CHAR(3) DEFAULT 'EUR',
    paid_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_partial    TINYINT(1) DEFAULT 0,
    tx_hash       VARCHAR(255),          -- pour crypto
    processed_by  BIGINT,                -- réceptionniste/user_id
    FOREIGN KEY (booking_id) REFERENCES bookings(booking_id),
    FOREIGN KEY (method_id)  REFERENCES payment_methods(method_id),
    FOREIGN KEY (processed_by) REFERENCES users(user_id)
);

/* =========================
   6. ARRIVÉES / CHECK-IN
   ========================= */
CREATE TABLE arrivals (
    arrival_id    BIGINT AUTO_INCREMENT PRIMARY KEY,
    booking_id    BIGINT NOT NULL,
    receptionist_id BIGINT NOT NULL,
    arrived_at    DATETIME NOT NULL,
    notes         TEXT,
    FOREIGN KEY (booking_id)     REFERENCES bookings(booking_id),
    FOREIGN KEY (receptionist_id) REFERENCES users(user_id)
);

/* =========================
   7. ENTRETIEN & TÂCHES EMPLOYÉS
   ========================= */
CREATE TABLE housekeeping_tasks (
    task_id     BIGINT AUTO_INCREMENT PRIMARY KEY,
    room_id     BIGINT  NOT NULL,
    assigned_to BIGINT,                  -- employé
    task_type   ENUM('cleaning','maintenance','inspection') NOT NULL,
    status      ENUM('todo','in_progress','done','cancelled') DEFAULT 'todo',
    scheduled_for DATE    NOT NULL,
    completed_at DATETIME,
    notes       TEXT,
    FOREIGN KEY (room_id)     REFERENCES rooms(room_id),
    FOREIGN KEY (assigned_to) REFERENCES users(user_id)
);

/* =========================
   8. NOTIFICATIONS & LOGS
   ========================= */
CREATE TABLE notifications (
    notification_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id     BIGINT NOT NULL,
    title       VARCHAR(150) NOT NULL,
    message     TEXT         NOT NULL,
    category    ENUM('info','success','warning','error') DEFAULT 'info',
    is_read     TINYINT(1)   DEFAULT 0,
    created_at  TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE audit_logs (
    log_id      BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id     BIGINT,
    action      VARCHAR(120) NOT NULL,
    target_type VARCHAR(60),         -- 'booking','room', etc.
    target_id   BIGINT,
    ip_address  VARCHAR(45),
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

/* =========================
   9. AVIS & NOTES (évolution)
   ========================= */
CREATE TABLE reviews (
    review_id   BIGINT AUTO_INCREMENT PRIMARY KEY,
    booking_id  BIGINT NOT NULL,
    rating      INT    CHECK(rating BETWEEN 1 AND 5),
    comment     TEXT,
    created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (booking_id) REFERENCES bookings(booking_id)
);

/* =========================
   10. VUES & INDICES POUR ANALYTIQUE
   ========================= */

/* Ex. : Vue du chiffre d’affaires par hôtel et par mois */
CREATE VIEW v_revenue_monthly AS
SELECT   h.hotel_id,
         DATE_FORMAT(p.paid_at,'%Y-%m-01') AS month,
         SUM(p.amount) AS total_revenue
FROM     payments p
JOIN     bookings b  ON b.booking_id = p.booking_id
JOIN     hotels   h  ON h.hotel_id   = b.hotel_id
GROUP BY h.hotel_id, month;

/* Indexes utiles pour la recherche rapide */
CREATE INDEX idx_bookings_status          ON bookings(status);
CREATE INDEX idx_rooms_status             ON rooms(status);
CREATE INDEX idx_payments_booking_method  ON payments(booking_id, method_id);
CREATE INDEX idx_notifications_user_read  ON notifications(user_id, is_read);

-- =====================================================================
-- Web-Based ECU Tuning Service and Sales Management System
-- with Payment and Sales Analytics for Ranao Moto
-- Database: ranao_moto_db   (MySQL 8.0+ / MariaDB 10.5+)
-- Based on: REVISED_CAPSTONE_ERD
-- =====================================================================

DROP DATABASE IF EXISTS ranao_moto_db;
CREATE DATABASE ranao_moto_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE ranao_moto_db;

-- ---------------------------------------------------------------------
-- 1. LOOKUP / REFERENCE TABLES
-- ---------------------------------------------------------------------

CREATE TABLE roles (
  role_id      INT UNSIGNED NOT NULL AUTO_INCREMENT,
  role_name    VARCHAR(50)  NOT NULL,
  description  VARCHAR(255) NULL,
  status       ENUM('active','inactive') NOT NULL DEFAULT 'active',
  PRIMARY KEY (role_id),
  UNIQUE KEY uq_roles_name (role_name)
) ENGINE=InnoDB;

CREATE TABLE address (
  address_id   INT UNSIGNED NOT NULL AUTO_INCREMENT,
  barangay     VARCHAR(100) NOT NULL,
  PRIMARY KEY (address_id)
) ENGINE=InnoDB;

CREATE TABLE categories (
  category_id    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  category_name  VARCHAR(100) NOT NULL,
  description    VARCHAR(255) NULL,
  status         ENUM('active','inactive') NOT NULL DEFAULT 'active',
  PRIMARY KEY (category_id),
  UNIQUE KEY uq_categories_name (category_name)
) ENGINE=InnoDB;

CREATE TABLE payment_method (
  payment_method_id  INT UNSIGNED NOT NULL AUTO_INCREMENT,
  method_name        VARCHAR(50)  NOT NULL,
  description        VARCHAR(255) NULL,
  status             ENUM('active','inactive') NOT NULL DEFAULT 'active',
  PRIMARY KEY (payment_method_id),
  UNIQUE KEY uq_payment_method_name (method_name)
) ENGINE=InnoDB;

CREATE TABLE motorcycle_brand (
  motorcycle_brand_id  INT UNSIGNED NOT NULL AUTO_INCREMENT,
  model                VARCHAR(100) NOT NULL,
  year                 YEAR         NULL,
  PRIMARY KEY (motorcycle_brand_id)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 2. USERS (owner, staff, mechanic) AND CUSTOMERS
-- ---------------------------------------------------------------------

CREATE TABLE users (
  user_id     INT UNSIGNED NOT NULL AUTO_INCREMENT,
  role_id     INT UNSIGNED NOT NULL,
  username    VARCHAR(50)  NOT NULL,
  password    VARCHAR(255) NOT NULL,            -- store a hashed password only
  first_name  VARCHAR(100) NOT NULL,
  last_name   VARCHAR(100) NOT NULL,
  status      ENUM('active','inactive') NOT NULL DEFAULT 'active',
  created_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (user_id),
  UNIQUE KEY uq_users_username (username),
  KEY idx_users_role (role_id),
  CONSTRAINT fk_users_role
    FOREIGN KEY (role_id) REFERENCES roles (role_id)
) ENGINE=InnoDB;

CREATE TABLE customers (
  customer_id     INT UNSIGNED NOT NULL AUTO_INCREMENT,
  customer_name   VARCHAR(150) NOT NULL,
  contact_number  VARCHAR(20)  NULL,
  address_id      INT UNSIGNED NULL,
  status          ENUM('active','inactive') NOT NULL DEFAULT 'active',
  created_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (customer_id),
  KEY idx_customers_address (address_id),
  CONSTRAINT fk_customers_address
    FOREIGN KEY (address_id) REFERENCES address (address_id)
) ENGINE=InnoDB;

CREATE TABLE motorcycles (
  motorcycle_id        INT UNSIGNED NOT NULL AUTO_INCREMENT,
  customer_id          INT UNSIGNED NOT NULL,
  plate_number         VARCHAR(20)  NOT NULL,
  motorcycle_brand_id  INT UNSIGNED NOT NULL,
  color                VARCHAR(50)  NULL,
  status               ENUM('active','inactive') NOT NULL DEFAULT 'active',
  created_at           TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (motorcycle_id),
  UNIQUE KEY uq_motorcycles_plate (plate_number),
  KEY idx_motorcycles_customer (customer_id),
  KEY idx_motorcycles_brand (motorcycle_brand_id),
  CONSTRAINT fk_motorcycles_customer
    FOREIGN KEY (customer_id) REFERENCES customers (customer_id),
  CONSTRAINT fk_motorcycles_brand
    FOREIGN KEY (motorcycle_brand_id) REFERENCES motorcycle_brand (motorcycle_brand_id)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 3. SERVICES
-- ---------------------------------------------------------------------

CREATE TABLE services (
  service_id     INT UNSIGNED NOT NULL AUTO_INCREMENT,
  category_id    INT UNSIGNED NOT NULL,
  service_name   VARCHAR(150) NOT NULL,
  service_price  DECIMAL(10,2) NOT NULL DEFAULT 0.00,
  description    VARCHAR(255) NULL,
  status         ENUM('active','inactive') NOT NULL DEFAULT 'active',
  PRIMARY KEY (service_id),
  KEY idx_services_category (category_id),
  CONSTRAINT fk_services_category
    FOREIGN KEY (category_id) REFERENCES categories (category_id)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 4. SALES AND ECU TUNING
-- ---------------------------------------------------------------------

CREATE TABLE sales (
  sale_id       INT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id       INT UNSIGNED NOT NULL,          -- staff who recorded the sale
  customer_id   INT UNSIGNED NOT NULL,
  sale_date     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  total_amount  DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  status        ENUM('pending','completed','cancelled') NOT NULL DEFAULT 'pending',
  created_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (sale_id),
  KEY idx_sales_user (user_id),
  KEY idx_sales_customer (customer_id),
  KEY idx_sales_date (sale_date),
  CONSTRAINT fk_sales_user
    FOREIGN KEY (user_id) REFERENCES users (user_id),
  CONSTRAINT fk_sales_customer
    FOREIGN KEY (customer_id) REFERENCES customers (customer_id)
) ENGINE=InnoDB;

CREATE TABLE sale_details (
  sale_detail_id  INT UNSIGNED NOT NULL AUTO_INCREMENT,
  sale_id         INT UNSIGNED NOT NULL,
  service_id      INT UNSIGNED NOT NULL,
  motorcycle_id   INT UNSIGNED NOT NULL,
  quantity        INT UNSIGNED NOT NULL DEFAULT 1,
  unit_price      DECIMAL(10,2) NOT NULL,
  subtotal        DECIMAL(12,2) NOT NULL,
  PRIMARY KEY (sale_detail_id),
  KEY idx_sd_sale (sale_id),
  KEY idx_sd_service (service_id),
  KEY idx_sd_motorcycle (motorcycle_id),
  CONSTRAINT fk_sd_sale
    FOREIGN KEY (sale_id) REFERENCES sales (sale_id),
  CONSTRAINT fk_sd_service
    FOREIGN KEY (service_id) REFERENCES services (service_id),
  CONSTRAINT fk_sd_motorcycle
    FOREIGN KEY (motorcycle_id) REFERENCES motorcycles (motorcycle_id)
) ENGINE=InnoDB;

CREATE TABLE ecu_tuning (
  tuning_id       INT UNSIGNED NOT NULL AUTO_INCREMENT,
  sale_detail_id  INT UNSIGNED NOT NULL,
  motorcycle_id   INT UNSIGNED NOT NULL,
  user_id         INT UNSIGNED NOT NULL,        -- mechanic who did the tuning
  tuning_date     DATETIME NULL,
  ecu_type        VARCHAR(100) NULL,
  ecu_before      TEXT NULL,                    -- ECU map / values before tuning
  ecu_after       TEXT NULL,                    -- ECU map / values after tuning
  tuning_status   ENUM('pending','in_progress','completed','cancelled')
                  NOT NULL DEFAULT 'pending',
  PRIMARY KEY (tuning_id),
  KEY idx_tuning_sale_detail (sale_detail_id),
  KEY idx_tuning_motorcycle (motorcycle_id),
  KEY idx_tuning_user (user_id),
  CONSTRAINT fk_tuning_sale_detail
    FOREIGN KEY (sale_detail_id) REFERENCES sale_details (sale_detail_id),
  CONSTRAINT fk_tuning_motorcycle
    FOREIGN KEY (motorcycle_id) REFERENCES motorcycles (motorcycle_id),
  CONSTRAINT fk_tuning_user
    FOREIGN KEY (user_id) REFERENCES users (user_id)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 5. PURCHASES
-- ---------------------------------------------------------------------

CREATE TABLE purchases (
  purchase_id       INT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id           INT UNSIGNED NOT NULL,
  purchase_date     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  reference_number  VARCHAR(50) NULL,
  total_amount      DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  status            ENUM('pending','received','cancelled') NOT NULL DEFAULT 'pending',
  created_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at        TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (purchase_id),
  KEY idx_purchases_user (user_id),
  CONSTRAINT fk_purchases_user
    FOREIGN KEY (user_id) REFERENCES users (user_id)
) ENGINE=InnoDB;

CREATE TABLE purchase_details (
  purchase_detail_id  INT UNSIGNED NOT NULL AUTO_INCREMENT,
  purchase_id         INT UNSIGNED NOT NULL,
  quantity            INT UNSIGNED NOT NULL DEFAULT 1,
  unit_cost           DECIMAL(10,2) NOT NULL,
  subtotal            DECIMAL(12,2) NOT NULL,
  PRIMARY KEY (purchase_detail_id),
  KEY idx_pd_purchase (purchase_id),
  CONSTRAINT fk_pd_purchase
    FOREIGN KEY (purchase_id) REFERENCES purchases (purchase_id)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 6. PAYMENTS (for a sale OR a purchase)
-- ---------------------------------------------------------------------

CREATE TABLE payments (
  payment_id         INT UNSIGNED NOT NULL AUTO_INCREMENT,
  sale_id            INT UNSIGNED NULL,
  purchase_id        INT UNSIGNED NULL,
  payment_method_id  INT UNSIGNED NOT NULL,
  received_by        INT UNSIGNED NOT NULL,     -- user who received/recorded the payment
  amount_paid        DECIMAL(12,2) NOT NULL,
  reference_number   VARCHAR(50) NULL,
  payment_status     ENUM('pending','paid','failed','refunded') NOT NULL DEFAULT 'pending',
  payment_date       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (payment_id),
  KEY idx_payments_sale (sale_id),
  KEY idx_payments_purchase (purchase_id),
  KEY idx_payments_method (payment_method_id),
  KEY idx_payments_received_by (received_by),
  CONSTRAINT fk_payments_sale
    FOREIGN KEY (sale_id) REFERENCES sales (sale_id),
  CONSTRAINT fk_payments_purchase
    FOREIGN KEY (purchase_id) REFERENCES purchases (purchase_id),
  CONSTRAINT fk_payments_method
    FOREIGN KEY (payment_method_id) REFERENCES payment_method (payment_method_id),
  CONSTRAINT fk_payments_received_by
    FOREIGN KEY (received_by) REFERENCES users (user_id),
  CONSTRAINT chk_payments_source
    CHECK (sale_id IS NOT NULL OR purchase_id IS NOT NULL)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 7. NOTIFICATIONS AND ACTIVITY LOGS
-- ---------------------------------------------------------------------

CREATE TABLE notifications (
  notification_id    INT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id            INT UNSIGNED NOT NULL,
  notification_type  VARCHAR(50)  NOT NULL,
  message            TEXT NOT NULL,
  created_at         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (notification_id),
  KEY idx_notifications_user (user_id),
  CONSTRAINT fk_notifications_user
    FOREIGN KEY (user_id) REFERENCES users (user_id)
) ENGINE=InnoDB;

CREATE TABLE activity_logs (
  log_id       INT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id      INT UNSIGNED NOT NULL,
  action       VARCHAR(100) NOT NULL,
  module       VARCHAR(100) NOT NULL,
  description  TEXT NULL,
  ip_address   VARCHAR(45) NULL,                -- fits IPv4 and IPv6
  created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (log_id),
  KEY idx_logs_user (user_id),
  KEY idx_logs_created (created_at),
  CONSTRAINT fk_logs_user
    FOREIGN KEY (user_id) REFERENCES users (user_id)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 8. STARTER DATA
-- ---------------------------------------------------------------------

INSERT INTO roles (role_name, description) VALUES
  ('Owner',    'Full access: users, services, reports and sales analytics'),
  ('Staff',    'Handles customers, sales, payments and purchases'),
  ('Mechanic', 'Performs ECU tuning and updates job status');

INSERT INTO payment_method (method_name, description) VALUES
  ('Cash',          'Cash payment at the shop'),
  ('GCash',         'Mobile wallet payment'),
  ('Bank Transfer', 'Online or over-the-counter bank transfer');

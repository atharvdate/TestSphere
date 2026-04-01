-- ============================================================
--  TestSphere v2 — Complete Database Setup
--  Run this entire script in MySQL Workbench
--  Database: testsphere_v2
-- ============================================================

CREATE DATABASE IF NOT EXISTS testsphere_v2
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE testsphere_v2;

-- App user
CREATE USER IF NOT EXISTS 'DB_USER'@'localhost'
  IDENTIFIED BY 'DB_PASS';
GRANT ALL PRIVILEGES ON testsphere_v2.* TO 'DB_USER'@'localhost';
FLUSH PRIVILEGES;

-- ── COLLEGES ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS colleges (
  id           INT AUTO_INCREMENT PRIMARY KEY,
  name         VARCHAR(200) NOT NULL,
  city         VARCHAR(100) NOT NULL,
  college_code VARCHAR(30)  NOT NULL UNIQUE,
  status       ENUM('PENDING','APPROVED','REJECTED') DEFAULT 'PENDING',
  created_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ── USERS ────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  username        VARCHAR(50)  NOT NULL UNIQUE,
  email           VARCHAR(150) NOT NULL UNIQUE,
  password_hash   VARCHAR(255) NOT NULL,
  role            ENUM('ADMIN','RECRUITER','STUDENT','COLLEGE_ADMIN') NOT NULL,
  status          ENUM('PENDING','ACTIVE','REJECTED','INACTIVE') DEFAULT 'PENDING',
  full_name       VARCHAR(150) NOT NULL,
  phone           VARCHAR(15),

  -- Recruiter fields
  company_name    VARCHAR(150),
  company_website VARCHAR(255),
  official_email  VARCHAR(150),

  -- Student fields
  college_id      INT,
  year_of_study   ENUM('1st Year','2nd Year','3rd Year','Final Year'),
  branch          ENUM('CSE','IT','ECE','EEE','MECH','CIVIL','MBA','MCA','OTHER'),
  cgpa            DECIMAL(4,2) DEFAULT 0.00,
  backlogs        INT          DEFAULT 0,

  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (college_id) REFERENCES colleges(id) ON DELETE SET NULL
);

-- ── DRIVES ──────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS drives (
  id                       INT AUTO_INCREMENT PRIMARY KEY,
  title                    VARCHAR(200) NOT NULL,
  job_role                 VARCHAR(100) NOT NULL,
  description              TEXT,
  package_lpa              VARCHAR(50),
  recruiter_id             INT NOT NULL,
  college_id               INT NOT NULL,

  -- Eligibility
  eligibility_year         VARCHAR(50)  DEFAULT 'Final Year',
  eligibility_min_cgpa     DECIMAL(4,2) DEFAULT 0.00,
  eligibility_max_backlogs INT          DEFAULT 99,
  eligibility_branches     VARCHAR(200) DEFAULT 'ALL',

  -- Access control
  invite_token             VARCHAR(100) NOT NULL UNIQUE,
  registration_deadline    DATETIME     NOT NULL,

  status                   ENUM('DRAFT','ACTIVE','CLOSED') DEFAULT 'DRAFT',
  created_at               TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (recruiter_id) REFERENCES users(id) ON DELETE CASCADE,
  FOREIGN KEY (college_id)   REFERENCES colleges(id) ON DELETE CASCADE
);

-- ── DRIVE ROUNDS ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS drive_rounds (
  id              INT AUTO_INCREMENT PRIMARY KEY,
  drive_id        INT NOT NULL,
  round_number    INT NOT NULL,
  round_type      ENUM('APTITUDE','GD','TECHNICAL','HR') NOT NULL,
  title           VARCHAR(150) NOT NULL,
  instructions    TEXT,

  -- Aptitude only
  start_time      DATETIME,
  end_time        DATETIME,
  cutoff_type     ENUM('TOP_N','MIN_PERCENT'),
  cutoff_value    VARCHAR(20),
  result_released TINYINT(1) DEFAULT 0,

  cutoff_type     ENUM('TOP_N','MIN_PERCENT'),
  cutoff_value    VARCHAR(20),
  status          ENUM('PENDING','ACTIVE','COMPLETED') DEFAULT 'PENDING',
  created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

  FOREIGN KEY (drive_id) REFERENCES drives(id) ON DELETE CASCADE
);

-- ── QUESTIONS ─────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS questions (
  id             INT AUTO_INCREMENT PRIMARY KEY,
  round_id       INT          NOT NULL,
  question_text  TEXT         NOT NULL,
  option_a       VARCHAR(500) NOT NULL,
  option_b       VARCHAR(500) NOT NULL,
  option_c       VARCHAR(500) NOT NULL,
  option_d       VARCHAR(500) NOT NULL,
  correct_option CHAR(1)      NOT NULL,
  FOREIGN KEY (round_id) REFERENCES drive_rounds(id) ON DELETE CASCADE
);

-- ── DRIVE APPLICATIONS ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS drive_applications (
  id                INT AUTO_INCREMENT PRIMARY KEY,
  drive_id          INT NOT NULL,
  student_id        INT NOT NULL,
  status            ENUM('ACTIVE','ELIMINATED','SELECTED') DEFAULT 'ACTIVE',
  recruiter_status  ENUM('PENDING','SHORTLISTED','REJECTED') DEFAULT 'PENDING',
  current_round     INT DEFAULT 0,
  resume_path       VARCHAR(500),
  ai_score          INT DEFAULT NULL,
  ai_reason         TEXT,
  applied_at        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_application (drive_id, student_id),
  FOREIGN KEY (drive_id)   REFERENCES drives(id) ON DELETE CASCADE,
  FOREIGN KEY (student_id) REFERENCES users(id)  ON DELETE CASCADE
);

-- ── ROUND RESULTS ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS round_results (
  id               INT AUTO_INCREMENT PRIMARY KEY,
  application_id   INT NOT NULL,
  round_id         INT NOT NULL,

  -- Aptitude score (auto)
  score            INT DEFAULT 0,
  total_questions  INT DEFAULT 0,

  -- All round types
  pass_fail        ENUM('PASS','FAIL'),
  recruiter_notes  TEXT,
  submitted_at     DATETIME,

  UNIQUE KEY uq_result (application_id, round_id),
  FOREIGN KEY (application_id) REFERENCES drive_applications(id) ON DELETE CASCADE,
  FOREIGN KEY (round_id)       REFERENCES drive_rounds(id)       ON DELETE CASCADE
);

-- ── NOTIFICATIONS ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS notifications (
  id         INT AUTO_INCREMENT PRIMARY KEY,
  user_id    INT          NOT NULL,
  title      VARCHAR(200) NOT NULL,
  message    TEXT         NOT NULL,
  is_read    TINYINT(1)   DEFAULT 0,
  created_at TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ── SUPER ADMIN ACCOUNT ───────────────────────────────────────
-- Password is: Default password is hashed. Change after setup.
-- To use a different password: run HashGenerator.java with your desired password and replace the hash
INSERT IGNORE INTO users
  (username, email, password_hash, role, status, full_name)
VALUES (
  'admin',
  'admin@testsphere.com',
  '$2a$12$cBFRlFDRTw1W5I0YWPWT3.fWj1T8CzmTWJ8XMvmB0sLJhWGJJqfMa',
  'ADMIN',
  'ACTIVE',
  'Super Admin'
);


-- ── HOW TO CHANGE THE ADMIN PASSWORD ─────────────────────────
-- Option A (Quick): Log in using username='admin', password= 'Default Password'
--
-- Option B (Recommended): Set a strong password
--   1. Run HashGenerator.java with your desired password to get a BCrypt hash
--   2. Run the UPDATE below with the new hash:
--
-- UPDATE users
--   SET password_hash = 'PASTE_YOUR_NEW_HASH_HERE'
--   WHERE username = 'admin';

-- ── FILE STORAGE ─────────────────────────────────────────────
-- Create this directory on your server and give Tomcat write permission:
--   mkdir -p /opt/testsphere/resumes
--   chown -R tomcat:tomcat /opt/testsphere/resumes
-- Or update RESUME_UPLOAD_DIR in ResumeUploadConfig.java to your preferred path.


-- ── MIGRATION: Run these if you already have the DB set up ────
-- (Safe to run multiple times — uses IF NOT EXISTS pattern)
-- Add new columns to drive_applications
ALTER TABLE drive_applications
  ADD COLUMN IF NOT EXISTS recruiter_status ENUM('PENDING','SHORTLISTED','REJECTED') DEFAULT 'PENDING',
  ADD COLUMN IF NOT EXISTS resume_path VARCHAR(500),
  ADD COLUMN IF NOT EXISTS ai_score INT DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS ai_reason TEXT;

-- Add new columns to drive_rounds
ALTER TABLE drive_rounds
  ADD COLUMN IF NOT EXISTS cutoff_type ENUM('TOP_N','MIN_PERCENT'),
  ADD COLUMN IF NOT EXISTS cutoff_value VARCHAR(20);

-- ── END MIGRATION ─────────────────────────────────────────────

-- ── VERIFY ────────────────────────────────────────────────────
SELECT 'Setup complete!' AS status;
SHOW TABLES;
SELECT username, role, status FROM users;

-- =====================================================
-- Water Polo Referees Association — Database Schema
-- 01_tables.sql
-- =====================================================
-- Στάδιο: Core μέλη & ρόλοι
-- =====================================================

-- ---------------------------------------------------
-- Πίνακας: members
-- Όλα τα μέλη του συνδέσμου (Διαιτητές, Παρατηρητές, Γραμματεία)
-- ---------------------------------------------------
CREATE TABLE members (
    member_id         NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name        VARCHAR2(60)  NOT NULL,
    last_name         VARCHAR2(60)  NOT NULL,
    category          VARCHAR2(20)  NOT NULL,   -- 'ΔΙΑΙΤΗΤΗΣ', 'ΠΑΡΑΤΗΡΗΤΗΣ', 'ΓΡΑΜΜΑΤΕΙΑ'
    experience_level  VARCHAR2(2),              -- 'Α','Β','Γ','Δ' — μόνο για διαιτητές (NULL για τους άλλους)
    registration_year NUMBER(4),                -- έτος εγγραφής στο μητρώο — καθορίζει αρχαιότητα εντός ίδιας κατηγορίας
    is_international  VARCHAR2(1) DEFAULT 'N' NOT NULL,  -- 'Y'/'N' — υπερισχύει της αρχαιότητας σε σύγκριση μεταξύ ίδιας κατηγορίας
    gender            VARCHAR2(1),              -- 'M'/'F' — χρησιμοποιείται π.χ. για σωστό άρθρο σε μηνύματα ("Ο"/"Η")
    status            VARCHAR2(10) DEFAULT 'INACTIVE' NOT NULL,  -- 'ACTIVE' / 'INACTIVE'
    email             VARCHAR2(120),
    phone             VARCHAR2(20),
    created_at        DATE DEFAULT SYSDATE,
    CONSTRAINT chk_member_category   CHECK (category IN ('ΔΙΑΙΤΗΤΗΣ','ΠΑΡΑΤΗΡΗΤΗΣ','ΓΡΑΜΜΑΤΕΙΑ')),
    CONSTRAINT chk_member_status     CHECK (status IN ('ACTIVE','INACTIVE')),
    CONSTRAINT chk_experience_level  CHECK (experience_level IN ('Α','Β','Γ','Δ') OR experience_level IS NULL),
    CONSTRAINT chk_is_international  CHECK (is_international IN ('Y','N')),
    CONSTRAINT chk_gender            CHECK (gender IN ('M','F') OR gender IS NULL)
);

-- ---------------------------------------------------
-- Πίνακας: roles
-- Ρόλοι που μπορεί να αναλάβει ένα μέλος ΑΝΑ ΑΓΩΝΑ
-- (ανεξάρτητος από το category — π.χ. διαιτητής μπορεί
--  να πάρει ρόλο SECRETARY σε συγκεκριμένο αγώνα)
-- ---------------------------------------------------
CREATE TABLE roles (
    role_id     NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    role_code   VARCHAR2(30) NOT NULL UNIQUE,   -- π.χ. 'REFEREE_A', 'REFEREE_B', 'OBSERVER', 'SECRETARY'
    description VARCHAR2(100)
);

-- ---------------------------------------------------
-- Seed data: βασικοί ρόλοι
-- ---------------------------------------------------
INSERT INTO roles (role_code, description) VALUES ('REFEREE_A', 'Διαιτητής Α');
INSERT INTO roles (role_code, description) VALUES ('REFEREE_B', 'Διαιτητής Β');
INSERT INTO roles (role_code, description) VALUES ('OBSERVER', 'Παρατηρητής Διαιτησίας');
INSERT INTO roles (role_code, description) VALUES ('SECRETARY', 'Γραμματέας Αγώνα');

COMMIT;

-- ---------------------------------------------------
-- Γρήγορος έλεγχος
-- ---------------------------------------------------
-- SELECT * FROM members;
-- SELECT * FROM roles;

-- ---------------------------------------------------
-- Κανόνας αρχαιότητας (business rule — θα υλοποιηθεί
-- αργότερα σε function/procedure):
-- Μεταξύ δύο διαιτητών ΙΔΙΑΣ κατηγορίας (π.χ. και οι δύο Α'),
-- θεωρείται "πιο έμπειρος" αυτός με μικρότερο registration_year,
-- ΕΚΤΟΣ αν ο νεότερος είναι is_international = 'Y', οπότε
-- υπερισχύει αυτός ανεξαρτήτως έτους εγγραφής.
--
-- Παράδειγμα ταξινόμησης διαιτητών ίδιας κατηγορίας κατά αρχαιότητα:
-- SELECT first_name, last_name, experience_level, registration_year, is_international
-- FROM members
-- WHERE category = 'REFEREE' AND experience_level = 'Α'
-- ORDER BY is_international DESC, registration_year ASC;
-- ---------------------------------------------------

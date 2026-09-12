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
    category          VARCHAR2(20)  NOT NULL,   -- 'REFEREE', 'OBSERVER', 'SECRETARY'
    experience_level  VARCHAR2(2),              -- 'Α','Β','Γ','Δ' — μόνο για διαιτητές (NULL για τους άλλους)
    registration_year NUMBER(4),                -- έτος εγγραφής στο μητρώο — καθορίζει αρχαιότητα εντός ίδιας κατηγορίας
    is_international  VARCHAR2(1) DEFAULT 'N' NOT NULL,  -- 'Y'/'N' — υπερισχύει της αρχαιότητας σε σύγκριση μεταξύ ίδιας κατηγορίας
    status            VARCHAR2(10) DEFAULT 'INACTIVE' NOT NULL,  -- 'ACTIVE' / 'INACTIVE'
    email             VARCHAR2(120),
    phone             VARCHAR2(20),
    created_at        DATE DEFAULT SYSDATE,
    CONSTRAINT chk_member_category   CHECK (category IN ('REFEREE','OBSERVER','SECRETARY')),
    CONSTRAINT chk_member_status     CHECK (status IN ('ACTIVE','INACTIVE')),
    CONSTRAINT chk_experience_level  CHECK (experience_level IN ('Α','Β','Γ','Δ') OR experience_level IS NULL),
    CONSTRAINT chk_is_international  CHECK (is_international IN ('Y','N'))
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
SELECT * FROM members;
SELECT * FROM roles;


-- =====================================================
-- Water Polo Referees Association — Database Schema
-- 02_matches.sql
-- =====================================================
-- Στάδιο: Αγώνες & Ορισμοί μελών σε αγώνες
-- =====================================================

-- ---------------------------------------------------
-- Πίνακας: matches
-- Ένας αγώνας υδατοσφαίρισης
-- ---------------------------------------------------


CREATE TABLE matches (
    match_id        NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    match_date      DATE NOT NULL,
    venue           varchar2(100),
    competition     varchar2(100),
    home_team       varchar2(100),
    away_team       varchar2(100),
    status          varchar2(15) DEFAULT 'SCHEDULED' NOT NULL,
    constraint      chk_match_status CHECK (status IN ('SCHEDULED', 'COMPLETED', 'CANCELLED'))
);


-- ---------------------------------------------------
-- Πίνακας: match_assignments
-- Ποιο μέλος (διαιτητής/παρατηρητής/γραμματέας) έχει
-- ποιο ρόλο σε ΣΥΓΚΕΚΡΙΜΕΝΟ αγώνα.
-- Ένα μέλος μπορεί σε άλλο αγώνα να έχει άλλο ρόλο
-- (π.χ. διαιτητής που κάνει χρέη γραμματέα).
-- ---------------------------------------------------

CREATE TABLE match_assignments (
    assignment_id            number generated always as identity primary key,
    match_id                 number not null,
    member_id                number not null,
    role_id                  number not null,
    constraint fk_assignment_match   foreign key (match_id) references matches(match_id),
    constraint fk_assignment_member  foreign key (member_id) references members(member_id),
    CONSTRAINT fk_assignment_role   FOREIGN KEY (role_id)   REFERENCES roles(role_id),
    -- Ένα μέλος δεν μπορεί να εμφανίζεται δύο φορές στον ΙΔΙΟ αγώνα
    -- (π.χ. να είναι ταυτόχρονα και Διαιτητής Α' και Γραμματέας στο ίδιο ματς)
    CONSTRAINT uq_match_member UNIQUE (match_id, member_id)
);


-- ---------------------------------------------------
-- Γρήγορος έλεγχος
-- ---------------------------------------------------
-- SELECT * FROM matches;
-- SELECT * FROM match_assignments;con

-- ---------------------------------------------------
-- Παράδειγμα: όλοι όσοι έχουν οριστεί σε έναν αγώνα, με το ρόλο τους
-- ---------------------------------------------------
-- SELECT m.first_name, m.last_name, r.description AS role
-- FROM match_assignments ma
-- JOIN members m ON m.member_id = ma.member_id
-- JOIN roles   r ON r.role_id   = ma.role_id
-- WHERE ma.match_id = 1;

-- =====================================================
-- Water Polo Referees Association — Database Schema
-- 03_sample_data.sql
-- =====================================================
-- Δοκιμαστικά δεδομένα για να δούμε τη σχέση matches <-> members
-- μέσω του match_assignments να δουλεύει σωστά
-- =====================================================

-- =====================================================
-- Water Polo Referees Association — Database Schema
-- 03_sample_data.sql
-- =====================================================
-- Δοκιμαστικά δεδομένα για να δούμε τη σχέση matches <-> members
-- μέσω του match_assignments να δουλεύει σωστά
-- =====================================================

-- ---------------------------------------------------
-- Λίγα δοκιμαστικά μέλη
-- ---------------------------------------------------
INSERT INTO members (first_name, last_name, category, experience_level, registration_year, is_international, status, email)
VALUES ('Γιώργος', 'Παπαδόπουλος', 'REFEREE', 'Α', 2015, 'Y', 'ACTIVE', 'gpapadopoulos@example.com');

INSERT INTO members (first_name, last_name, category, experience_level, registration_year, is_international, status, email)
VALUES ('Νίκος', 'Ιωάννου', 'REFEREE', 'Α', 2020, 'N', 'ACTIVE', 'nioannou@example.com');

INSERT INTO members (first_name, last_name, category, experience_level, registration_year, is_international, status, email)
VALUES ('Μαρία', 'Κωνσταντίνου', 'OBSERVER', NULL, 2018, 'N', 'ACTIVE', 'mkonstantinou@example.com');

INSERT INTO members (first_name, last_name, category, experience_level, registration_year, is_international, status, email)
VALUES ('Ελένη', 'Δημητρίου', 'SECRETARY', NULL, 2021, 'N', 'ACTIVE', 'edimitriou@example.com');

COMMIT;

-- ---------------------------------------------------
-- Ρύθμιση εμφάνισης ημερομηνιών για το session (μία φορά ανά worksheet)
-- ---------------------------------------------------
ALTER SESSION SET NLS_DATE_FORMAT = 'DD-MM-YYYY HH24:MI';

-- ---------------------------------------------------
-- Ένας δοκιμαστικός αγώνας
-- match_date: DD-MM-YYYY HH24:MI -- π.χ. 20-09-2026, ώρα 18:30 (24ωρη μορφή)
-- ---------------------------------------------------
INSERT INTO matches (match_date, venue, competition, home_team, away_team, status)
VALUES (TO_DATE('20-09-2026 18:30', 'DD-MM-YYYY HH24:MI'), 'Κολυμβητήριο Πάτρας', 'Α1 Εθνική Ανδρών', 'ΝΟ Πάτρας', 'ΝΟ Πατρών', 'SCHEDULED');

COMMIT;

-- ---------------------------------------------------
-- Ορισμοί μελών στον αγώνα (match_id = 1 -- πρώτος αγώνας που μπήκε)
-- ---------------------------------------------------
-- Γιώργος Παπαδόπουλος (member_id = 1) ως Διαιτητής Α' (role_id = 1)
INSERT INTO match_assignments (match_id, member_id, role_id) VALUES (1, 1, 1);

-- Νίκος Ιωάννου (member_id = 2) ως Διαιτητής Β' (role_id = 2)
INSERT INTO match_assignments (match_id, member_id, role_id) VALUES (1, 2, 2);

-- Μαρία Κωνσταντίνου (member_id = 3) ως Παρατηρήτρια (role_id = 3)
INSERT INTO match_assignments (match_id, member_id, role_id) VALUES (1, 3, 3);

-- Ελένη Δημητρίου (member_id = 4) ως Γραμματέας (role_id = 4)
INSERT INTO match_assignments (match_id, member_id, role_id) VALUES (1, 4, 4);

COMMIT;

-- ---------------------------------------------------
-- Έλεγχος: όλοι όσοι έχουν οριστεί στον αγώνα, με το ρόλο τους
-- ---------------------------------------------------
SELECT ma.match_id, mt.match_date, m.first_name, m.last_name, r.description AS role_description
FROM match_assignments ma
JOIN members m  ON m.member_id  = ma.member_id
JOIN roles   r  ON r.role_id    = ma.role_id
JOIN matches mt ON mt.match_id  = ma.match_id
WHERE ma.match_id = 1
ORDER BY r.role_id;

-- =====================================================
-- Water Polo Referees Association — Database Schema
-- 04_triggers.sql
-- =====================================================
-- Trigger: όριο μελών ανά κατηγορία ρόλου, ανά αγώνα
-- Διαιτητές (REFEREE_A + REFEREE_B μαζί): max 2
-- Παρατηρητές (OBSERVER): max 2
-- Γραμματείς (SECRETARY): max 10
-- =====================================================

CREATE OR REPLACE TRIGGER trg_check_role_limits
BEFORE INSERT ON match_assignments
FOR EACH ROW
declare
    v_role_code   roles.ROLE_CODE%TYPE;
    v_category    varchar2(20);
    v_max         number;
    v_count       number;
begin
    -- Βρες τον κωδικό ρόλου που πάει να μπει
    select role_code into v_role_code
    from roles
    where role_id = :NEW.role_id;

    -- Ομαδοποίησε σε κατηγορία και όρισε το μέγιστο όριο
    IF v_role_code in ('REFEREE_A', 'REFEREE_B') then
        v_category := 'REFEREE';
        v_max := 2;
    ELSIF v_role_code = 'OBSERVER' THEN
        v_category := 'OBSERVER';
        v_max := 2;
    ELSIF v_role_code = 'SECRETARY' THEN
        v_category := 'SECRETARY';
        v_max := 10;
    END IF;

    -- Μέτρησε πόσοι υπάρχουν ήδη στον ίδιο αγώνα, ίδια κατηγορία
    SELECT COUNT (*)
    INTO v_count
    FROM match_assignments ma
    JOIN roles r ON r.role_id = ma.role_id
    WHERE ma.match_id = :NEW.match_id
        AND (
                (v_category = 'REFEREE' AND r.role_code IN ('REFEREE_A','REFEREE_B'))
            OR (v_category = 'OBSERVER'  AND r.role_code = 'OBSERVER')
            OR (v_category = 'SECRETARY' AND r.role_code = 'SECRETARY')
            );

    IF v_count >= v_max THEN
            RAISE_APPLICATION_ERROR(
                -20001,
                'Έχει ήδη συμπληρωθεί το μέγιστο όριο (' || v_max || ') για την κατηγορία ' || v_category || ' σε αυτόν τον αγώνα.'
            );
        END IF;
    END;
    /

-- ---------------------------------------------------
-- Δοκιμή: πρόσθεσε ένα 3ο μέλος ως παρατηρητή στον αγώνα 1
-- (θα έπρεπε να αποτύχει, μιας και έχει ήδη 1 παρατηρητή
--  και το όριο είναι 2 -- δοκίμασε 2 φορές για να δεις πότε σκάει)
-- ---------------------------------------------------
INSERT INTO match_assignments (match_id, member_id, role_id) VALUES (1, 3, 3); -- 2ος παρατηρητής, OK
INSERT INTO match_assignments (match_id, member_id, role_id) VALUES (1, 3, 3); -- 3ος, θα σκάσει

INSERT INTO match_assignments (match_id, member_id, role_id) VALUES (1, 4, 1);

-- DROP TRIGGER trg_check_role_limits;


-- =====================================================
-- Water Polo Referees Association — Database Schema
-- 05_declarations.sql
-- =====================================================
-- Δήλωση Ενέργειας ανά μέλος, ανά αγωνιστική περίοδο (σεζόν)
-- Τα πεδία της δήλωσης είναι ΕΛΕΥΘΕΡΑ/JSON, ώστε να αλλάζουν
-- κάθε χρόνο χωρίς να πειράζεται το schema.
-- =====================================================

-- ---------------------------------------------------
-- Πίνακας: seasons
-- Οι αγωνιστικές περίοδοι
-- ---------------------------------------------------
CREATE TABLE seasons (
    season_id    NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    season_name  VARCHAR2(20) NOT NULL UNIQUE,   -- π.χ. '2026-2027'
    start_date   DATE,
    end_date     DATE
);

-- ---------------------------------------------------
-- Πίνακας: member_declarations
-- Η δήλωση ενέργειας ενός μέλους για μια συγκεκριμένη σεζόν.
-- declaration_data: JSON με όποια πεδία χρειάζεται η φετινή φόρμα
-- π.χ. {"home_base": "Πάτρα", "phone": "6981234567",
--       "relation_to_sport": "Ενεργός Διαιτητής",
--       "has_relative_in_team": true, "relative_team": "ΝΟ Πατρών"}
-- ---------------------------------------------------
CREATE TABLE member_declarations (
    declaration_id     NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    member_id          NUMBER NOT NULL,
    season_id          NUMBER NOT NULL,
    submitted_at       DATE DEFAULT SYSDATE NOT NULL,
    declaration_data   CLOB NOT NULL,
    CONSTRAINT fk_decl_member  FOREIGN KEY (member_id) REFERENCES members(member_id),
    CONSTRAINT fk_decl_season  FOREIGN KEY (season_id) REFERENCES seasons(season_id),
    -- Ένα μέλος μπορεί να υποβάλει ΜΙΑ δήλωση ανά σεζόν
    CONSTRAINT uq_member_season UNIQUE (member_id, season_id),
    -- Επιβάλλει το declaration_data να είναι πάντα ΈΓΚΥΡΟ JSON
    CONSTRAINT chk_decl_json CHECK (declaration_data IS JSON)
);

-- ---------------------------------------------------
-- Δοκιμαστικά δεδομένα
-- ---------------------------------------------------
INSERT INTO seasons (season_name, start_date, end_date)
VALUES ('2026-2027', DATE '2026-09-01', DATE '2027-06-30');

COMMIT;

-- Ο Γιώργος Παπαδόπουλος (member_id=1) υποβάλλει δήλωση για τη σεζόν 2026-2027
INSERT INTO member_declarations (member_id, season_id, declaration_data)
VALUES (
    1,
    1,
    '{
        "home_base": "Πάτρα",
        "phone": "6981234567",
        "relation_to_sport": "Ενεργός Διαιτητής",
        "has_relative_in_team": true,
        "relative_team": "ΝΟ Πατρών"
    }'
);

COMMIT;

-- ---------------------------------------------------
-- Πώς διαβάζεις συγκεκριμένα πεδία από το JSON: JSON_VALUE
-- ---------------------------------------------------
SELECT
    m.first_name,
    m.last_name,
    JSON_VALUE(d.declaration_data, '$.home_base')            AS home_base,
    JSON_VALUE(d.declaration_data, '$.phone')                AS phone,
    JSON_VALUE(d.declaration_data, '$.has_relative_in_team')  AS has_relative
FROM member_declarations d
JOIN members m ON m.member_id = d.member_id
WHERE d.season_id = 1;


-- =====================================================
-- Water Polo Referees Association — Database Schema
-- 06_declaration_trigger.sql
-- =====================================================
-- Στάδιο: Αυτόματη ενεργοποίηση μέλους + ειδοποίηση
-- προέδρου/γραμματέα μόλις υποβληθεί δήλωση ενέργειας
-- =====================================================

-- ---------------------------------------------------
-- Πίνακας: association_officials
-- Ποιος/ποια κατέχει διοικητική θέση στον σύνδεσμο
-- (ανεξάρτητο από το category/role του μέλους σε αγώνες)
-- ---------------------------------------------------

CREATE TABLE association_officials (
    official_id           NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    member_id             NUMBER NOT NULL,
    position              VARCHAR2(30) NOT NULL, -- 'PRESIDENT', 'SECRETARY_GENERAL'
    constraint fk_official_member FOREIGN KEY (member_id) REFERENCES members(member_id),
    CONSTRAINT chk_official_position CHECK (position IN ('PRESIDENT','SECRETARY_GENERAL'))
);

-- ---------------------------------------------------
-- Πίνακας: notifications
-- Απλό inbox ειδοποιήσεων μέσα στο σύστημα
-- ---------------------------------------------------
CREATE TABLE notifications (
    notification_id   NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    recipient_member_id NUMBER NOT NULL,
    message            VARCHAR2(500) NOT NULL,
    related_member_id  NUMBER,
    created_at         DATE DEFAULT SYSDATE NOT NULL,
    is_read            VARCHAR2(1) DEFAULT 'N' NOT NULL,
    CONSTRAINT fk_notif_recipient FOREIGN KEY (recipient_member_id) REFERENCES members(member_id),
    CONSTRAINT fk_notif_related   FOREIGN KEY (related_member_id)   REFERENCES members(member_id),
    CONSTRAINT chk_notif_read CHECK (is_read IN ('Y','N'))
);

-- ---------------------------------------------------
-- Trigger: μόλις υποβληθεί δήλωση ενέργειας
--   1) το μέλος γίνεται αυτόματα ACTIVE
--   2) ειδοποιούνται όλοι οι association_officials
-- ---------------------------------------------------
CREATE OR REPLACE TRIGGER trg_declaration_submitted
AFTER INSERT ON member_declarations
FOR EACH ROW
DECLARE
    v_full_name  VARCHAR2(120);
BEGIN
    -- 1) Ενεργοποίηση μέλους
    UPDATE members
    SET status = 'ACTIVE'
    WHERE member_id = :NEW.member_id;

    -- Πάρε το ονοματεπώνυμο για το μήνυμα ειδοποίησης
    SELECT first_name || ' ' || last_name
    INTO v_full_name
    FROM members
    WHERE member_id = :NEW.member_id;

    -- 2) Ειδοποίηση σε όλους τους αξιωματούχους (πρόεδρος, γεν. γραμματέας)
    FOR official IN (SELECT member_id FROM association_officials) LOOP
        INSERT INTO notifications (recipient_member_id, message, related_member_id)
        VALUES (
            official.member_id,
            'Ο/Η ' || v_full_name || ' υπέβαλε δήλωση ενέργειας.',
            :NEW.member_id
        );
    END LOOP;
END;
/

-- ---------------------------------------------------
-- Δοκιμαστικά δεδομένα: όρισε την Ελένη Δημητρίου (member_id=4)
-- ως Γενική Γραμματέα του συνδέσμου
-- ---------------------------------------------------
INSERT INTO association_officials (member_id, position) VALUES (4, 'SECRETARY_GENERAL');
COMMIT;

-- ---------------------------------------------------
-- Δοκιμή: υπέβαλε δήλωση για τον Νίκο Ιωάννου (member_id=2)
-- Πριν: SELECT status FROM members WHERE member_id = 2;  -- θα δείξει INACTIVE
-- ---------------------------------------------------
INSERT INTO member_declarations (member_id, season_id, declaration_data)
VALUES (2, 1, '{"home_base": "Πάτρα", "phone": "6971112233"}');
COMMIT;

-- Μετά: επιβεβαίωση ότι δούλεψε
SELECT status FROM members WHERE member_id = 2;  -- τώρα θα πρέπει να δείξει ACTIVE
SELECT * FROM notifications;                      -- θα δεις νέα ειδοποίηση

-- =====================================================
-- Water Polo Referees Association — Database Schema
-- 07_member_gender.sql
-- =====================================================
-- Προσθήκη φύλου στα μέλη + σωστό άρθρο (Ο/Η) στο μήνυμα
-- ειδοποίησης δήλωσης ενέργειας
-- =====================================================

-- ---------------------------------------------------
-- Migration: προσθήκη στήλης σε ΥΠΑΡΧΟΝΤΑ πίνακα
-- (χρησιμοποιείται όταν ο πίνακας ήδη υπάρχει με δεδομένα,
--  αντί να τον ξαναφτιάξεις από την αρχή)
-- ---------------------------------------------------
ALTER TABLE members ADD gender VARCHAR2(1);
ALTER TABLE members ADD CONSTRAINT chk_gender CHECK (gender IN ('M','F') OR gender IS NULL);

-- ---------------------------------------------------
-- Ενημέρωση υπαρχόντων δοκιμαστικών μελών
-- ---------------------------------------------------
UPDATE members SET gender = 'M' WHERE member_id = 1;  -- Γιώργος Παπαδόπουλος
UPDATE members SET gender = 'M' WHERE member_id = 2;  -- Νίκος Ιωάννου
UPDATE members SET gender = 'F' WHERE member_id = 3;  -- Μαρία Κωνσταντίνου
UPDATE members SET gender = 'F' WHERE member_id = 4;  -- Ελένη Δημητρίου
COMMIT;

-- ---------------------------------------------------
-- Ενημερωμένο trigger: σωστό άρθρο βάσει φύλου
-- ---------------------------------------------------
CREATE OR REPLACE TRIGGER trg_declaration_submitted
AFTER INSERT ON member_declarations
FOR EACH ROW
DECLARE
    v_full_name  VARCHAR2(120);
    v_gender     members.gender%TYPE;
    v_article    VARCHAR2(2);
BEGIN
    -- 1) Ενεργοποίηση μέλους
    UPDATE members
    SET status = 'ACTIVE'
    WHERE member_id = :NEW.member_id;

    -- Πάρε ονοματεπώνυμο και φύλο για το μήνυμα ειδοποίησης
    SELECT first_name || ' ' || last_name, gender
    INTO v_full_name, v_gender
    FROM members
    WHERE member_id = :NEW.member_id;

    -- Σωστό άρθρο ανάλογα με το φύλο (fallback "Το μέλος" αν δεν έχει δηλωθεί)
    IF v_gender = 'M' THEN
        v_article := 'Ο';
    ELSIF v_gender = 'F' THEN
        v_article := 'Η';
    ELSE
        v_article := NULL;
    END IF;

    -- 2) Ειδοποίηση σε όλους τους αξιωματούχους (πρόεδρος, γεν. γραμματέας)
    FOR official IN (SELECT member_id FROM association_officials) LOOP
        INSERT INTO notifications (recipient_member_id, message, related_member_id)
        VALUES (
            official.member_id,
            CASE
                WHEN v_article IS NOT NULL THEN v_article || ' ' || v_full_name || ' υπέβαλε δήλωση ενέργειας.'
                ELSE 'Το μέλος ' || v_full_name || ' υπέβαλε δήλωση ενέργειας.'
            END,
            :NEW.member_id
        );
    END LOOP;
END;
/

-- ---------------------------------------------------
-- Δοκιμή: υπέβαλε νέα δήλωση για τη Μαρία Κωνσταντίνου (member_id=3)
-- ---------------------------------------------------
INSERT INTO member_declarations (member_id, season_id, declaration_data)
VALUES (3, 1, '{"home_base": "Πάτρα"}');
COMMIT;

-- Επιβεβαίωση: SELECT * FROM notifications ORDER BY notification_id DESC;
-- Θα πρέπει να δεις "Η Μαρία Κωνσταντίνου υπέβαλε δήλωση ενέργειας."

--DROP TABLE member_transactions;
--DROP TABLE fee_categories;

-- DROP VIEW member_role_financials;
-- DROP VIEW member_dues_summary;
-- DROP TABLE member_transactions;
-- DROP TABLE fee_categories;

-- =====================================================
-- Water Polo Referees Association — Database Schema
-- 08_financials.sql
-- =====================================================
-- Οικονομικά: αμοιβές, κρατήσεις 8%, συνδρομές.
-- Κάθε κατηγορία έχει ΔΥΟ πλευρές -- τι ΟΦΕΙΛΕΤΑΙ και τι
-- ΕΙΣΠΡΑΧΘΗΚΕ/ΠΛΗΡΩΘΗΚΕ -- ακριβώς όπως η πραγματική
-- "Καρτέλα Μέλους" (Ποσό / Είσπραξη / Υπόλοιπο).
--
-- Σύμβαση: όλα τα amount είναι ΘΕΤΙΚΑ ποσά (μεγέθη).
-- Το ΤΙ σημαίνουν το καθορίζει το transaction_type,
-- όχι το πρόσημο -- πιο απλό, πιο κοντά στην πραγματική
-- αναφορά, λιγότερο επιρρεπές σε λάθη πρόσημου.
-- =====================================================


-- =====================================================
-- ΜΕΡΟΣ 1 — Πίνακες
-- =====================================================

CREATE TABLE fee_categories (
    fee_category_id  NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    competition       VARCHAR2(100) NOT NULL,
    role_code         VARCHAR2(30) NOT NULL,
    amount            NUMBER(8,2) NOT NULL,
    CONSTRAINT fk_feecat_role FOREIGN KEY (role_code) REFERENCES roles(role_code),
    CONSTRAINT uq_feecat UNIQUE (competition, role_code)
);

-- ---------------------------------------------------
-- member_transactions: το "βιβλίο κινήσεων" κάθε μέλους.
-- Τύποι κίνησης (όλα τα amount ΘΕΤΙΚΑ):
--   MATCH_FEE               -> αμοιβή που ΟΦΕΙΛΕΤΑΙ στο μέλος
--   MATCH_FEE_PAYMENT       -> αμοιβή που ΠΛΗΡΩΘΗΚΕ στο μέλος
--   ASSOCIATION_RETENTION   -> κράτηση 8% που ΟΦΕΙΛΕΙ το μέλος
--   RETENTION_COLLECTION    -> κράτηση 8% που ΕΙΣΠΡΑΧΘΗΚΕ από το μέλος
--   ANNUAL_SUBSCRIPTION     -> συνδρομή που ΟΦΕΙΛΕΙ το μέλος
--   SUBSCRIPTION_COLLECTION -> συνδρομή που ΕΙΣΠΡΑΧΘΗΚΕ
--   FINE                    -> πρόστιμο που ΟΦΕΙΛΕΙ το μέλος
-- ---------------------------------------------------
CREATE TABLE member_transactions (
    transaction_id     NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    member_id          NUMBER NOT NULL,
    transaction_type   VARCHAR2(25) NOT NULL,
    amount             NUMBER(8,2) NOT NULL CHECK (amount >= 0),
    match_id           NUMBER,
    description        VARCHAR2(300),
    transaction_date   DATE DEFAULT SYSDATE NOT NULL,
    CONSTRAINT fk_trans_member FOREIGN KEY (member_id) REFERENCES members(member_id),
    CONSTRAINT fk_trans_match  FOREIGN KEY (match_id)  REFERENCES matches(match_id),
    CONSTRAINT chk_trans_type CHECK (transaction_type IN (
        'MATCH_FEE', 'MATCH_FEE_PAYMENT',
        'ASSOCIATION_RETENTION', 'RETENTION_COLLECTION',
        'ANNUAL_SUBSCRIPTION', 'SUBSCRIPTION_COLLECTION',
        'FINE'
    ))
);


-- =====================================================
-- ΜΕΡΟΣ 2 — Seed δεδομένα αμοιβών
-- =====================================================
INSERT INTO fee_categories (competition, role_code, amount) VALUES ('Α1 Εθνική Ανδρών', 'REFEREE_A', 80.00);
INSERT INTO fee_categories (competition, role_code, amount) VALUES ('Α1 Εθνική Ανδρών', 'REFEREE_B', 80.00);
INSERT INTO fee_categories (competition, role_code, amount) VALUES ('Α1 Εθνική Ανδρών', 'OBSERVER',  50.00);
INSERT INTO fee_categories (competition, role_code, amount) VALUES ('Α1 Εθνική Ανδρών', 'SECRETARY', 30.00);
COMMIT;


-- =====================================================
-- ΜΕΡΟΣ 3 — Procedure: αυτόματος υπολογισμός ΟΦΕΙΛΟΜΕΝΗΣ
-- αμοιβής + ΟΦΕΙΛΟΜΕΝΗΣ κράτησης 8%, για όλους τους
-- ορισμένους σε έναν αγώνα. Η πληρωμή/είσπραξη είναι
-- ξεχωριστό, μεταγενέστερο βήμα (δεν συμβαίνει αυτόματα).
-- =====================================================
CREATE OR REPLACE PROCEDURE generate_match_fees (
    p_match_id IN matches.match_id%TYPE
) AS
    v_retention_rate CONSTANT NUMBER := 0.08;
    v_fee            NUMBER;
BEGIN
    FOR assignment IN (
        SELECT ma.member_id, r.role_code, m.competition
        FROM match_assignments ma
        JOIN roles   r ON r.role_id  = ma.role_id
        JOIN matches m ON m.match_id = ma.match_id
        WHERE ma.match_id = p_match_id
    ) LOOP

        BEGIN
            SELECT amount INTO v_fee
            FROM fee_categories
            WHERE competition = assignment.competition
              AND role_code   = assignment.role_code;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_fee := NULL;
        END;

        IF v_fee IS NOT NULL THEN
            -- Οφειλόμενη αμοιβή
            INSERT INTO member_transactions (member_id, transaction_type, amount, match_id, description)
            VALUES (
                assignment.member_id, 'MATCH_FEE', v_fee, p_match_id,
                'Αμοιβή αγώνα -- ' || assignment.competition
            );

            -- Οφειλόμενη κράτηση 8%
            INSERT INTO member_transactions (member_id, transaction_type, amount, match_id, description)
            VALUES (
                assignment.member_id, 'ASSOCIATION_RETENTION', ROUND(v_fee * v_retention_rate, 2), p_match_id,
                'Κράτηση 8% επί αμοιβής αγώνα'
            );
        END IF;

    END LOOP;

    COMMIT;
END generate_match_fees;
/


-- =====================================================
-- ΜΕΡΟΣ 4 — Views: συγκεντρωτική "Καρτέλα Μέλους",
-- ΑΚΡΙΒΩΣ όπως Ποσό / Είσπραξη / Υπόλοιπο
-- =====================================================

-- Αμοιβές ανά ρόλο (Διαιτητής / Παρατηρητής / Γραμματέας)
CREATE OR REPLACE VIEW member_role_financials AS
SELECT
    mt.member_id,
    CASE
        WHEN ma.role_id IS NULL THEN 'ΓΕΝΙΚΑ'
        WHEN r.role_code IN ('REFEREE_A','REFEREE_B') THEN 'ΔΙΑΙΤΗΤΗΣ'
        WHEN r.role_code = 'OBSERVER'  THEN 'ΠΑΡΑΤΗΡΗΤΗΣ'
        WHEN r.role_code = 'SECRETARY' THEN 'ΓΡΑΜΜΑΤΕΑΣ'
    END AS role_category,
    COUNT(DISTINCT CASE WHEN mt.transaction_type = 'MATCH_FEE' THEN mt.match_id END) AS participations,
    SUM(CASE WHEN mt.transaction_type = 'MATCH_FEE'         THEN mt.amount ELSE 0 END) AS amount_owed,
    SUM(CASE WHEN mt.transaction_type = 'MATCH_FEE_PAYMENT' THEN mt.amount ELSE 0 END) AS amount_paid
FROM member_transactions mt
LEFT JOIN match_assignments ma
       ON ma.match_id = mt.match_id AND ma.member_id = mt.member_id
LEFT JOIN roles r
       ON r.role_id = ma.role_id
WHERE mt.transaction_type IN ('MATCH_FEE', 'MATCH_FEE_PAYMENT')
GROUP BY
    mt.member_id,
    CASE
        WHEN ma.role_id IS NULL THEN 'ΓΕΝΙΚΑ'
        WHEN r.role_code IN ('REFEREE_A','REFEREE_B') THEN 'ΔΙΑΙΤΗΤΗΣ'
        WHEN r.role_code = 'OBSERVER'  THEN 'ΠΑΡΑΤΗΡΗΤΗΣ'
        WHEN r.role_code = 'SECRETARY' THEN 'ΓΡΑΜΜΑΤΕΑΣ'
    END;

-- Παρακρατήσεις: Ποσό / Είσπραξη / Υπόλοιπο
CREATE OR REPLACE VIEW member_retention_summary AS
SELECT
    member_id,
    SUM(CASE WHEN transaction_type = 'ASSOCIATION_RETENTION' THEN amount ELSE 0 END) AS amount_owed,
    SUM(CASE WHEN transaction_type = 'RETENTION_COLLECTION'  THEN amount ELSE 0 END) AS amount_collected
FROM member_transactions
WHERE transaction_type IN ('ASSOCIATION_RETENTION', 'RETENTION_COLLECTION')
GROUP BY member_id;

-- Συνδρομές: Ποσό / Είσπραξη / Υπόλοιπο
CREATE OR REPLACE VIEW member_subscription_summary AS
SELECT
    member_id,
    SUM(CASE WHEN transaction_type = 'ANNUAL_SUBSCRIPTION'     THEN amount ELSE 0 END) AS amount_owed,
    SUM(CASE WHEN transaction_type = 'SUBSCRIPTION_COLLECTION' THEN amount ELSE 0 END) AS amount_collected
FROM member_transactions
WHERE transaction_type IN ('ANNUAL_SUBSCRIPTION', 'SUBSCRIPTION_COLLECTION')
GROUP BY member_id;


-- =====================================================
-- ΜΕΡΟΣ 5 — Δοκιμή από την αρχή, καθαρά
-- =====================================================

-- 1) Αυτόματη δημιουργία οφειλόμενης αμοιβής + κράτησης για τον αγώνα 1
EXEC generate_match_fees(1);

-- 2) Ο σύνδεσμος πληρώνει την αμοιβή στον Γιώργο Παπαδόπουλο (member_id=1)
INSERT INTO member_transactions (member_id, transaction_type, amount, match_id, description)
VALUES (1, 'MATCH_FEE_PAYMENT', 80.00, 1, 'Πληρωμή αμοιβής αγώνα');

-- 3) Ο Γιώργος αποδίδει την κράτηση 8% πίσω στον σύνδεσμο
INSERT INTO member_transactions (member_id, transaction_type, amount, match_id, description)
VALUES (1, 'RETENTION_COLLECTION', 6.40, 1, 'Απόδοση κράτησης 8%');

COMMIT;

-- Καρτέλα -- Αμοιβές ανά ρόλο
SELECT role_category, participations, amount_owed, amount_paid,
       (amount_owed - amount_paid) AS balance
FROM member_role_financials
WHERE member_id = 1;

-- Καρτέλα -- Παρακρατήσεις
SELECT amount_owed, amount_collected,
       (amount_owed - amount_collected) AS balance
FROM member_retention_summary
WHERE member_id = 1;

-- Καρτέλα -- Συνδρομές
SELECT amount_owed, amount_collected,
       (amount_owed - amount_collected) AS balance
FROM member_subscription_summary
WHERE member_id = 1;


-- =====================================================
-- Water Polo Referees Association — Database Schema
-- 10_seniority_function.sql
-- =====================================================
-- Function: ποιος από δύο διαιτητές ΙΔΙΑΣ κατηγορίας
-- είναι "πιο έμπειρος" -- μικρότερο registration_year,
-- ΕΚΤΟΣ αν ο νεότερος είναι is_international = 'Y'
-- =====================================================

CREATE OR REPLACE FUNCTION get_senior_referee (
    p_ref1_id IN members.member_id%TYPE,
    p_ref2_id IN members.member_id%TYPE
) RETURN members.member_id%TYPE
AS
    v_ref1 members%ROWTYPE;
    v_ref2 members%ROWTYPE;
BEGIN
    SELECT * INTO v_ref1 FROM members WHERE member_id = p_ref1_id;
    SELECT * INTO v_ref2 FROM members WHERE member_id = p_ref2_id;

    -- Βασικός έλεγχος εγκυρότητας: πρέπει να είναι διαιτητές ίδιας κατηγορίας
    IF v_ref1.category != 'REFEREE' OR v_ref2.category != 'REFEREE' THEN
        RAISE_APPLICATION_ERROR(-20010, 'Και τα δύο μέλη πρέπει να είναι διαιτητές.');
    END IF;

    IF v_ref1.experience_level != v_ref2.experience_level THEN
        RAISE_APPLICATION_ERROR(-20011, 'Η σύγκριση αρχαιότητας ισχύει μόνο μεταξύ διαιτητών ΙΔΙΑΣ κατηγορίας.');
    END IF;

    -- Κανόνας 1: αν μόνο ο ένας είναι διεθνής, αυτός υπερισχύει
    IF v_ref1.is_international = 'Y' AND v_ref2.is_international = 'N' THEN
        RETURN v_ref1.member_id;
    ELSIF v_ref2.is_international = 'Y' AND v_ref1.is_international = 'N' THEN
        RETURN v_ref2.member_id;
    END IF;

    -- Κανόνας 2: αλλιώς, μικρότερο registration_year = πιο παλιός/έμπειρος
    IF v_ref1.registration_year < v_ref2.registration_year THEN
        RETURN v_ref1.member_id;
    ELSIF v_ref2.registration_year < v_ref1.registration_year THEN
        RETURN v_ref2.member_id;
    ELSE
        -- Ίδιο έτος εγγραφής και τα δύο -- δεν υπάρχει σαφής "πιο έμπειρος"
        RETURN NULL;
    END IF;
END get_senior_referee;
/

-- ---------------------------------------------------
-- Δοκιμή 1: Γιώργος (member_id=1, 2015, διεθνής) vs Νίκος (member_id=2, 2020, όχι διεθνής)
-- Αναμενόμενο: ο Γιώργος (και τα δύο κριτήρια συμφωνούν)
-- ---------------------------------------------------
SELECT get_senior_referee(1, 2) AS senior_member_id FROM dual;

-- ---------------------------------------------------
-- Δοκιμή 2: πρόσθεσε έναν νεότερο, ΔΙΕΘΝΗ διαιτητή, για να δεις το override
-- ---------------------------------------------------
INSERT INTO members (first_name, last_name, category, experience_level, registration_year, is_international, gender, status, email)
VALUES ('Παύλος', 'Αντωνίου', 'REFEREE', 'Α', 2023, 'Y', 'M', 'ACTIVE', 'pantoniou@example.com');
COMMIT;

-- Νίκος (2020, όχι διεθνής) vs Παύλος (2023, διεθνής)
-- Αναμενόμενο: ο Παύλος, ΠΑΡΟΛΟ που είναι νεότερος -- λόγω is_international
SELECT get_senior_referee(2, 5) AS senior_member_id FROM dual;

SELECT member_id, first_name, last_name, experience_level, registration_year, is_international
FROM members
WHERE member_id IN (2, 5);

SELECT member_id, first_name, last_name, category, registration_year, is_international
FROM members
ORDER BY member_id;

-- Πρώτα δες τι θα διαγραφεί (ασφαλές, δεν αλλάζει τίποτα)
SELECT * FROM members WHERE member_id IN (21,22,23,24);

-- Αν είναι όντως τα διπλότυπα, διάγραψέ τα
DELETE FROM members WHERE member_id IN (21,22,23,24);
COMMIT;

SELECT get_senior_referee(2, 41) AS senior_member_id FROM dual;

-- =====================================================
-- Water Polo Referees Association — Database Schema
-- 11_cleanup_members.sql
-- =====================================================
-- Καθαρισμός διπλότυπων μελών (IDs 21-24) και επαναφορά
-- του μετρητή IDENTITY σε λογικό σημείο
-- =====================================================

-- ---------------------------------------------------
-- Βήμα 1: έλεγξε ΠΡΩΤΑ αν τα διπλότυπα (21-24) συνδέονται
-- κάπου αλλού (foreign keys) -- αν έχουν, θα σκάσει το DELETE
-- ---------------------------------------------------
SELECT 'match_assignments' AS tbl, COUNT(*) FROM match_assignments WHERE member_id IN (21,22,23,24)
UNION ALL
SELECT 'member_declarations', COUNT(*) FROM member_declarations WHERE member_id IN (21,22,23,24)
UNION ALL
SELECT 'member_transactions', COUNT(*) FROM member_transactions WHERE member_id IN (21,22,23,24)
UNION ALL
SELECT 'association_officials', COUNT(*) FROM association_officials WHERE member_id IN (21,22,23,24)
UNION ALL
SELECT 'notifications', COUNT(*) FROM notifications WHERE member_id IN (21,22,23,24);
-- Αν όλα δείχνουν 0, είναι ασφαλές να διαγραφούν

-- ---------------------------------------------------
-- Βήμα 2: διαγραφή διπλότυπων
-- ---------------------------------------------------
DELETE FROM members WHERE member_id IN (21,22,23,24);
COMMIT;

-- ---------------------------------------------------
-- Βήμα 3: επαναφορά του μετρητή IDENTITY.
-- Ο Παύλος έχει ήδη ID=41, οπότε ξεκινάμε τον μετρητή
-- από το 42, ώστε το επόμενο νέο μέλος να πάρει 42
-- (χωρίς να συγκρουστεί με υπάρχον ID)
-- ---------------------------------------------------
ALTER TABLE members MODIFY member_id GENERATED ALWAYS AS IDENTITY (RESTART START WITH 42);

-- ---------------------------------------------------
-- Επιβεβαίωση
-- ---------------------------------------------------
SELECT member_id, first_name, last_name, category
FROM members
ORDER BY member_id;

SELECT get_senior_referee(2, 41) AS senior_member_id FROM dual;
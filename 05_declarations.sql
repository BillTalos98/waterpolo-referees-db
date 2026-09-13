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

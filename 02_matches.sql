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
    match_id      NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    match_date    DATE NOT NULL,
    venue         VARCHAR2(100),
    competition   VARCHAR2(100),           -- π.χ. κατηγορία πρωταθλήματος
    home_team     VARCHAR2(100),
    away_team     VARCHAR2(100),
    status        VARCHAR2(15) DEFAULT 'SCHEDULED' NOT NULL,
    CONSTRAINT chk_match_status CHECK (status IN ('SCHEDULED','COMPLETED','CANCELLED'))
);

-- ---------------------------------------------------
-- Πίνακας: match_assignments
-- Ποιο μέλος (διαιτητής/παρατηρητής/γραμματέας) έχει
-- ποιο ρόλο σε ΣΥΓΚΕΚΡΙΜΕΝΟ αγώνα.
-- Ένα μέλος μπορεί σε άλλο αγώνα να έχει άλλο ρόλο
-- (π.χ. διαιτητής που κάνει χρέη γραμματέα).
-- ---------------------------------------------------
CREATE TABLE match_assignments (
    assignment_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    match_id      NUMBER NOT NULL,
    member_id     NUMBER NOT NULL,
    role_id       NUMBER NOT NULL,
    CONSTRAINT fk_assignment_match  FOREIGN KEY (match_id)  REFERENCES matches(match_id),
    CONSTRAINT fk_assignment_member FOREIGN KEY (member_id) REFERENCES members(member_id),
    CONSTRAINT fk_assignment_role   FOREIGN KEY (role_id)   REFERENCES roles(role_id),
    -- Ένα μέλος δεν μπορεί να εμφανίζεται δύο φορές στον ΙΔΙΟ αγώνα
    -- (π.χ. να είναι ταυτόχρονα και Διαιτητής Α' και Γραμματέας στο ίδιο ματς)
    CONSTRAINT uq_match_member UNIQUE (match_id, member_id)
);

-- ---------------------------------------------------
-- Γρήγορος έλεγχος
-- ---------------------------------------------------
-- SELECT * FROM matches;
-- SELECT * FROM match_assignments;

-- ---------------------------------------------------
-- Παράδειγμα: όλοι όσοι έχουν οριστεί σε έναν αγώνα, με το ρόλο τους
-- ---------------------------------------------------
-- SELECT m.first_name, m.last_name, r.description AS role
-- FROM match_assignments ma
-- JOIN members m ON m.member_id = ma.member_id
-- JOIN roles   r ON r.role_id   = ma.role_id
-- WHERE ma.match_id = 1;

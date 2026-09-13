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

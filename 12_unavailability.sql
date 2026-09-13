-- =====================================================
-- Water Polo Referees Association — Database Schema
-- 12_unavailability.sql
-- =====================================================
-- Δήλωση Κωλυμάτων (βασισμένο στην πραγματική φόρμα ΣΕΔΥ):
-- - Πάγιο ή Προσωρινό κώλυμα
-- - Αιτιολογία (5 προκαθορισμένες κατηγορίες)
-- - Διάστημα ημερομηνιών
-- - Προαιρετικά: συγκεκριμένες ΗΜΕΡΕΣ της εβδομάδας μέσα
--   στο διάστημα (π.χ. "κάθε Τρίτη, 01.10-20.12")
--
-- ΣΗΜΕΙΩΣΗ ΓΙΑ ΤΑ TEST SCRIPTS: δεν χρησιμοποιούμε ΠΟΤΕ
-- hardcoded IDs (π.χ. "match_id = 3"), γιατί το IDENTITY
-- counter προχωράει ανεξάρτητα από το πόσες γραμμές
-- υπάρχουν στην πραγματικότητα (κάθε αποτυχημένο INSERT
-- το "καίει" ένα νούμερο). Αντ' αυτού, βρίσκουμε το σωστό
-- ID ΔΥΝΑΜΙΚΑ, μέσω κάποιου μοναδικού χαρακτηριστικού
-- (π.χ. ημερομηνία αγώνα) -- ακριβώς όπως θα έκανε και το
-- πραγματικό API αργότερα.
-- =====================================================

-- ---------------------------------------------------
-- Πίνακας: member_unavailability
-- ---------------------------------------------------
CREATE TABLE member_unavailability (
    unavailability_id    NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    member_id             NUMBER NOT NULL,
    unavailability_type   VARCHAR2(20) NOT NULL,   -- 'PERMANENT' (πάγιο) / 'TEMPORARY' (προσωρινό)
    reason_code            NUMBER(1) NOT NULL,      -- 1-5, βλ. σχόλιο παρακάτω
    notes                  VARCHAR2(300),            -- "Διευκρινήσεις" ελεύθερο κείμενο
    start_date              DATE NOT NULL,
    end_date                 DATE NOT NULL,
    created_at               DATE DEFAULT SYSDATE NOT NULL,
    CONSTRAINT fk_unavail_member  FOREIGN KEY (member_id) REFERENCES members(member_id),
    CONSTRAINT chk_unavail_dates  CHECK (end_date >= start_date),
    CONSTRAINT chk_unavail_type   CHECK (unavailability_type IN ('PERMANENT','TEMPORARY')),
    CONSTRAINT chk_unavail_reason CHECK (reason_code BETWEEN 1 AND 5)
    -- reason_code: 1=Συμμετοχή σε αγώνες εξωτερικού, 2=Εργασία,
    --              3=Προσωπικοί/Οικογενειακοί λόγοι, 4=Εξετάσεις στο Πανεπιστήμιο, 5=Άλλοι λόγοι
);

-- ---------------------------------------------------
-- Πίνακας: member_unavailability_days
-- Προαιρετικές ΣΥΓΚΕΚΡΙΜΕΝΕΣ ημέρες εβδομάδας μέσα στο
-- διάστημα. Αν ΔΕΝ υπάρχει καμία γραμμή για ένα κώλυμα,
-- σημαίνει "μπλοκάρει ΟΛΕΣ τις ημέρες" του διαστήματος.
-- ---------------------------------------------------
CREATE TABLE member_unavailability_days (
    unavailability_id  NUMBER NOT NULL,
    day_of_week         VARCHAR2(3) NOT NULL,   -- 'MON','TUE','WED','THU','FRI','SAT','SUN'
    CONSTRAINT fk_unavail_days  FOREIGN KEY (unavailability_id)
        REFERENCES member_unavailability(unavailability_id) ON DELETE CASCADE,
    CONSTRAINT pk_unavail_days  PRIMARY KEY (unavailability_id, day_of_week),
    CONSTRAINT chk_day_of_week  CHECK (day_of_week IN ('MON','TUE','WED','THU','FRI','SAT','SUN'))
);

-- ---------------------------------------------------
-- Trigger: εμποδίζει ορισμό μέλους σε αγώνα αν η
-- ημερομηνία (ΚΑΙ, αν έχει δηλωθεί, η συγκεκριμένη ημέρα
-- εβδομάδας) πέφτει μέσα σε δηλωμένο κώλυμα
-- ---------------------------------------------------
CREATE OR REPLACE TRIGGER trg_check_unavailability
BEFORE INSERT ON match_assignments
FOR EACH ROW
DECLARE
    v_match_date  matches.match_date%TYPE;
    v_match_day   VARCHAR2(3);
    v_conflict    NUMBER;
BEGIN
    SELECT match_date INTO v_match_date
    FROM matches
    WHERE match_id = :NEW.match_id;

    v_match_day := UPPER(TO_CHAR(v_match_date, 'DY', 'NLS_DATE_LANGUAGE=AMERICAN'));

    SELECT COUNT(*) INTO v_conflict
    FROM member_unavailability u
    WHERE u.member_id = :NEW.member_id
      AND TRUNC(v_match_date) BETWEEN u.start_date AND u.end_date
      AND (
            NOT EXISTS (
                SELECT 1 FROM member_unavailability_days d
                WHERE d.unavailability_id = u.unavailability_id
            )
            OR
            EXISTS (
                SELECT 1 FROM member_unavailability_days d
                WHERE d.unavailability_id = u.unavailability_id
                  AND d.day_of_week = v_match_day
            )
          );

    IF v_conflict > 0 THEN
        RAISE_APPLICATION_ERROR(
            -20002,
            'Το μέλος έχει δηλώσει κώλυμα για αυτή την ημερομηνία -- δεν μπορεί να οριστεί.'
        );
    END IF;
END;
/

-- =====================================================
-- Δοκιμαστικά δεδομένα -- δύο σενάρια
-- =====================================================

-- Σενάριο Α: ΠΡΟΣΩΡΙΝΟ κώλυμα, ΟΛΕΣ οι ημέρες μπλοκαρισμένες
-- Ο Νίκος Ιωάννου (member_id=2) -- ταξίδι εξωτερικού, 18-22/09/2026
INSERT INTO member_unavailability (member_id, unavailability_type, reason_code, notes, start_date, end_date)
VALUES (2, 'TEMPORARY', 1, 'Συμμετοχή σε αγώνες εξωτερικού με την Εθνική', DATE '2026-09-18', DATE '2026-09-22');

-- Σενάριο Β: ΠΑΓΙΟ κώλυμα, ΜΟΝΟ συγκεκριμένες ημέρες
-- Η Μαρία Κωνσταντίνου (member_id=3) -- μάθημα κάθε Τρίτη & Πέμπτη, 01/10 - 20/12/2026
INSERT INTO member_unavailability (member_id, unavailability_type, reason_code, notes, start_date, end_date)
VALUES (3, 'PERMANENT', 4, 'Εργαστηριακό μάθημα Πανεπιστημίου κάθε Τρίτη και Πέμπτη', DATE '2026-10-01', DATE '2026-12-20');

-- Ημέρες για το κώλυμα της Μαρίας -- βρίσκουμε το ID ΔΥΝΑΜΙΚΑ (όχι hardcoded)
INSERT INTO member_unavailability_days (unavailability_id, day_of_week)
SELECT unavailability_id, 'TUE' FROM member_unavailability
WHERE member_id = 3 AND reason_code = 4;

INSERT INTO member_unavailability_days (unavailability_id, day_of_week)
SELECT unavailability_id, 'THU' FROM member_unavailability
WHERE member_id = 3 AND reason_code = 4;

COMMIT;


-- =====================================================
-- ΔΟΚΙΜΕΣ -- όλες με ΔΥΝΑΜΙΚΗ εύρεση ID, καμία hardcoded τιμή
-- =====================================================

-- ---------------------------------------------------
-- Δοκιμή 1: ο υπάρχων αγώνας «Α1 Εθνική Ανδρών» στις 20/09/2026
-- Ο Νίκος έχει κώλυμα ΟΛΕΣ τις ημέρες εκείνο το διάστημα -> ΘΑ ΣΚΑΣΕΙ
-- ---------------------------------------------------
-- Καθάρισε πρώτα τυχόν υπάρχουσα ανάθεσή του σε αυτόν τον αγώνα
DELETE FROM match_assignments
WHERE member_id = 2
  AND match_id = (SELECT match_id FROM matches WHERE match_date = TO_DATE('20-09-2026 18:30','DD-MM-YYYY HH24:MI'));
COMMIT;

-- Ξαναδοκίμασε τον ορισμό -- αναμενόμενο: ORA-20002
INSERT INTO match_assignments (match_id, member_id, role_id)
SELECT match_id, 2, 2
FROM matches
WHERE match_date = TO_DATE('20-09-2026 18:30','DD-MM-YYYY HH24:MI');

-- ---------------------------------------------------
-- Δοκιμή 2: ΝΕΟΣ αγώνας ΤΡΙΤΗ 06/10/2026 -- η Μαρία έχει
-- κώλυμα ΜΟΝΟ Τρίτη/Πέμπτη μέσα σε αυτό το διάστημα -> ΘΑ ΣΚΑΣΕΙ
-- ---------------------------------------------------
INSERT INTO matches (match_date, venue, competition, home_team, away_team, status)
VALUES (TO_DATE('06-10-2026 19:00','DD-MM-YYYY HH24:MI'), 'Κολυμβητήριο Πάτρας', 'Α1 Εθνική Ανδρών', 'ΝΟ Πάτρας', 'ΝΟ Πατρών', 'SCHEDULED');
COMMIT;

INSERT INTO match_assignments (match_id, member_id, role_id)
SELECT match_id, 3, 3
FROM matches
WHERE match_date = TO_DATE('06-10-2026 19:00','DD-MM-YYYY HH24:MI');
-- Αναμενόμενο: ORA-20002 (Τρίτη = μία από τις δηλωμένες ημέρες)

-- ---------------------------------------------------
-- Δοκιμή 3: η ΙΔΙΑ Μαρία, σε αγώνα ΤΕΤΑΡΤΗ 07/10/2026 -> ΘΑ ΠΕΡΑΣΕΙ
-- (η Τετάρτη δεν είναι μέσα στις δηλωμένες ημέρες κωλύματος)
-- ---------------------------------------------------
INSERT INTO matches (match_date, venue, competition, home_team, away_team, status)
VALUES (TO_DATE('07-10-2026 19:00','DD-MM-YYYY HH24:MI'), 'Κολυμβητήριο Πάτρας', 'Α1 Εθνική Ανδρών', 'ΝΟ Πάτρας', 'ΝΟ Πατρών', 'SCHEDULED');
COMMIT;

INSERT INTO match_assignments (match_id, member_id, role_id)
SELECT match_id, 3, 3
FROM matches
WHERE match_date = TO_DATE('07-10-2026 19:00','DD-MM-YYYY HH24:MI');
COMMIT;
-- Αναμενόμενο: OK, χωρίς σφάλμα -- επιβεβαίωσε:
SELECT * FROM match_assignments
WHERE member_id = 3
  AND match_id = (SELECT match_id FROM matches WHERE match_date = TO_DATE('07-10-2026 19:00','DD-MM-YYYY HH24:MI'));

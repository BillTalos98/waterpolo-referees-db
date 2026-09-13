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

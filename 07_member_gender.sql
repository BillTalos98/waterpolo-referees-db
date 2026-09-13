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

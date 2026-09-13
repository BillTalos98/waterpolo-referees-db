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
    official_id  NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    member_id    NUMBER NOT NULL,
    position     VARCHAR2(30) NOT NULL,   -- 'PRESIDENT', 'SECRETARY_GENERAL'
    CONSTRAINT fk_official_member FOREIGN KEY (member_id) REFERENCES members(member_id),
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
-- SELECT status FROM members WHERE member_id = 2;  -- θα δείξει ACTIVE
-- SELECT * FROM notifications;                      -- θα δεις ειδοποίηση προς την Ελένη

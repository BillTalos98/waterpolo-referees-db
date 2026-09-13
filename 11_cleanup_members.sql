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

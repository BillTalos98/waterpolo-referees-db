-- =====================================================
-- Water Polo Referees Association — Database Schema
-- 04_triggers.sql
-- =====================================================
-- Trigger: όριο μελών ανά κατηγορία ρόλου, ανά αγώνα
-- Διαιτητές (REFEREE_A + REFEREE_B μαζί): max 2
-- Παρατηρητές (OBSERVER): max 2
-- Γραμματείς (SECRETARY): max 10
--
-- Υλοποιημένο ως COMPOUND TRIGGER, ώστε να δουλεύει σωστά
-- τόσο με INSERT ... VALUES όσο και με INSERT ... SELECT
-- (η δεύτερη μορφή θα προκαλούσε ORA-04091 "mutating table"
-- αν το BEFORE ROW έκανε απευθείας SELECT COUNT στον ίδιο
-- πίνακα -- λεπτομέρειες στα σχόλια παρακάτω).
-- =====================================================

CREATE OR REPLACE TRIGGER trg_check_role_limits
FOR INSERT ON match_assignments
COMPOUND TRIGGER

    -- Σύνολο (χωρίς διπλότυπα) των match_id που επηρεάζονται
    -- από αυτή την εντολή INSERT
    TYPE t_match_set IS TABLE OF BOOLEAN INDEX BY PLS_INTEGER;
    v_touched_matches t_match_set;

    BEFORE EACH ROW IS
    BEGIN
        v_touched_matches(:NEW.match_id) := TRUE;
    END BEFORE EACH ROW;

    -- Ο έλεγχος γίνεται ΜΕΤΑ την ολοκλήρωση όλης της εντολής,
    -- όχι ανά γραμμή -- εκεί επιτρέπεται να διαβάσουμε ελεύθερα
    -- τον πίνακα match_assignments χωρίς mutating table error
    AFTER STATEMENT IS
        v_match_id NUMBER;
        v_max      NUMBER;
    BEGIN
        v_match_id := v_touched_matches.FIRST;

        WHILE v_match_id IS NOT NULL LOOP

            FOR cat_check IN (
                SELECT
                    CASE
                        WHEN r.role_code IN ('REFEREE_A','REFEREE_B') THEN 'REFEREE'
                        WHEN r.role_code = 'OBSERVER'  THEN 'OBSERVER'
                        WHEN r.role_code = 'SECRETARY' THEN 'SECRETARY'
                    END AS category,
                    COUNT(*) AS cnt
                FROM match_assignments ma
                JOIN roles r ON r.role_id = ma.role_id
                WHERE ma.match_id = v_match_id
                GROUP BY
                    CASE
                        WHEN r.role_code IN ('REFEREE_A','REFEREE_B') THEN 'REFEREE'
                        WHEN r.role_code = 'OBSERVER'  THEN 'OBSERVER'
                        WHEN r.role_code = 'SECRETARY' THEN 'SECRETARY'
                    END
            ) LOOP
                v_max := CASE cat_check.category
                            WHEN 'REFEREE'   THEN 2
                            WHEN 'OBSERVER'  THEN 2
                            WHEN 'SECRETARY' THEN 10
                         END;

                IF cat_check.cnt > v_max THEN
                    RAISE_APPLICATION_ERROR(
                        -20001,
                        'Έχει ξεπεραστεί το μέγιστο όριο (' || v_max || ') για την κατηγορία '
                        || cat_check.category || ' στον αγώνα ' || v_match_id || '.'
                    );
                END IF;
            END LOOP;

            v_match_id := v_touched_matches.NEXT(v_match_id);
        END LOOP;
    END AFTER STATEMENT;

END trg_check_role_limits;
/

-- ---------------------------------------------------
-- Δοκιμή: πρόσθεσε ένα 3ο μέλος ως παρατηρητή στον αγώνα 1
-- (θα έπρεπε να αποτύχει, μιας και έχει ήδη 2 παρατηρητές
--  και το όριο είναι 2)
-- ---------------------------------------------------
-- INSERT INTO match_assignments (match_id, member_id, role_id) VALUES (1, 4, 3);

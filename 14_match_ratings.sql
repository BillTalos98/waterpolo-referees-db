-- =====================================================
-- Water Polo Referees Association — Database Schema
-- 14_match_ratings.sql
-- =====================================================
-- Βαθμολογίες παρατηρητών προς διαιτητές, ανά αγώνα.
-- Ένας παρατηρητής βαθμολογεί έναν διαιτητή για τη
-- συγκεκριμένη εμφάνισή του σε συγκεκριμένο αγώνα.
-- =====================================================

CREATE TABLE match_ratings (
    rating_id      NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    match_id       NUMBER NOT NULL,
    referee_id     NUMBER NOT NULL,   -- ποιος διαιτητής βαθμολογείται
    observer_id    NUMBER NOT NULL,   -- ποιος παρατηρητής βαθμολόγησε
    score          NUMBER(3,1) NOT NULL,   -- π.χ. 8.5
    comments       VARCHAR2(500),
    rated_at       DATE DEFAULT SYSDATE NOT NULL,
    CONSTRAINT fk_rating_match    FOREIGN KEY (match_id)    REFERENCES matches(match_id),
    CONSTRAINT fk_rating_referee  FOREIGN KEY (referee_id)  REFERENCES members(member_id),
    CONSTRAINT fk_rating_observer FOREIGN KEY (observer_id) REFERENCES members(member_id),
    CONSTRAINT chk_rating_score   CHECK (score BETWEEN 0 AND 10),
    -- Ένας παρατηρητής δεν βαθμολογεί δύο φορές τον ίδιο διαιτητή στον ίδιο αγώνα
    CONSTRAINT uq_rating UNIQUE (match_id, referee_id, observer_id)
);

-- ---------------------------------------------------
-- Δοκιμαστικά δεδομένα: η Μαρία Κωνσταντίνου (member_id=3,
-- παρατηρήτρια) βαθμολογεί τον Γιώργο Παπαδόπουλο (member_id=1)
-- για τον αγώνα «Α1 Εθνική Ανδρών» στις 20/09/2026
-- ---------------------------------------------------
INSERT INTO match_ratings (match_id, referee_id, observer_id, score, comments)
SELECT match_id, 1, 3, 8.5, 'Πολύ καλή διαχείριση αγώνα, σταθερή διαιτησία.'
FROM matches
WHERE match_date = TO_DATE('20-09-2026 18:30','DD-MM-YYYY HH24:MI');
COMMIT;

-- ---------------------------------------------------
-- Ιστορικό βαθμολογιών ενός διαιτητή -- η "καρτέλα αξιολόγησης" του
-- ---------------------------------------------------
SELECT
    mt.match_date,
    mt.competition,
    obs.first_name || ' ' || obs.last_name AS observer_name,
    mr.score,
    mr.comments
FROM match_ratings mr
JOIN matches mt  ON mt.match_id = mr.match_id
JOIN members obs ON obs.member_id = mr.observer_id
WHERE mr.referee_id = 1
ORDER BY mt.match_date DESC;

-- ---------------------------------------------------
-- Μέσος όρος βαθμολογίας ανά διαιτητή (χρήσιμο για κατάταξη)
-- ---------------------------------------------------
SELECT
    m.first_name, m.last_name,
    COUNT(*) AS ratings_count,
    ROUND(AVG(mr.score), 2) AS average_score
FROM match_ratings mr
JOIN members m ON m.member_id = mr.referee_id
GROUP BY m.first_name, m.last_name
ORDER BY average_score DESC;

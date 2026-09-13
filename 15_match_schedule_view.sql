-- =====================================================
-- Water Polo Referees Association — Database Schema
-- 15_match_schedule_view.sql
-- =====================================================
-- Πρόγραμμα Αγώνων: view που δείχνει κάθε αγώνα μαζί με
-- όλους τους ορισμένους σε αυτόν, σε μία γραμμή ανά αγώνα
-- (χρησιμοποιεί LISTAGG για να "μαζέψει" πολλά ονόματα σε
-- ένα string -- ιδανικό για προβολή σε calendar/πρόγραμμα)
-- =====================================================

CREATE OR REPLACE VIEW match_schedule AS
SELECT
    m.match_id,
    m.match_date,
    m.venue,
    m.competition,
    m.home_team,
    m.away_team,
    m.status,
    LISTAGG(
        r.description || ': ' || mb.first_name || ' ' || mb.last_name,
        ' | '
    ) WITHIN GROUP (ORDER BY r.role_id) AS assigned_officials
FROM matches m
LEFT JOIN match_assignments ma ON ma.match_id = m.match_id
LEFT JOIN members mb           ON mb.member_id = ma.member_id
LEFT JOIN roles r              ON r.role_id = ma.role_id
GROUP BY
    m.match_id, m.match_date, m.venue, m.competition,
    m.home_team, m.away_team, m.status;

-- ---------------------------------------------------
-- Πλήρες πρόγραμμα, ταξινομημένο χρονολογικά
-- ---------------------------------------------------
SELECT match_date, venue, competition, home_team, away_team, status, assigned_officials
FROM match_schedule
ORDER BY match_date;

-- ---------------------------------------------------
-- Πρόγραμμα ενός συγκεκριμένου μέλους -- "οι δικοί μου αγώνες"
-- (π.χ. η Μαρία, member_id=3)
-- ---------------------------------------------------
SELECT ms.match_date, ms.venue, ms.competition, ms.home_team, ms.away_team
FROM match_schedule ms
WHERE ms.match_id IN (
    SELECT match_id FROM match_assignments WHERE member_id = 3
)
ORDER BY ms.match_date;

-- ---------------------------------------------------
-- Μόνο επερχόμενοι αγώνες (από σήμερα και μετά)
-- ---------------------------------------------------
SELECT match_date, venue, competition, home_team, away_team, assigned_officials
FROM match_schedule
WHERE match_date >= TRUNC(SYSDATE)
ORDER BY match_date;

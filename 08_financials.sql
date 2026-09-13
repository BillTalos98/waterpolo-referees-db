-- =====================================================
-- Water Polo Referees Association — Database Schema
-- 08_financials.sql
-- =====================================================
-- Οικονομικά: αμοιβές, κρατήσεις 8%, συνδρομές.
-- Κάθε κατηγορία έχει ΔΥΟ πλευρές -- τι ΟΦΕΙΛΕΤΑΙ και τι
-- ΕΙΣΠΡΑΧΘΗΚΕ/ΠΛΗΡΩΘΗΚΕ -- ακριβώς όπως η πραγματική
-- "Καρτέλα Μέλους" (Ποσό / Είσπραξη / Υπόλοιπο).
--
-- Σύμβαση: όλα τα amount είναι ΘΕΤΙΚΑ ποσά (μεγέθη).
-- Το ΤΙ σημαίνουν το καθορίζει το transaction_type,
-- όχι το πρόσημο -- πιο απλό, πιο κοντά στην πραγματική
-- αναφορά, λιγότερο επιρρεπές σε λάθη πρόσημου.
-- =====================================================


-- =====================================================
-- ΜΕΡΟΣ 1 — Πίνακες
-- =====================================================

CREATE TABLE fee_categories (
    fee_category_id  NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    competition       VARCHAR2(100) NOT NULL,
    role_code         VARCHAR2(30) NOT NULL,
    amount            NUMBER(8,2) NOT NULL,
    CONSTRAINT fk_feecat_role FOREIGN KEY (role_code) REFERENCES roles(role_code),
    CONSTRAINT uq_feecat UNIQUE (competition, role_code)
);

-- ---------------------------------------------------
-- member_transactions: το "βιβλίο κινήσεων" κάθε μέλους.
-- Τύποι κίνησης (όλα τα amount ΘΕΤΙΚΑ):
--   MATCH_FEE               -> αμοιβή που ΟΦΕΙΛΕΤΑΙ στο μέλος
--   MATCH_FEE_PAYMENT       -> αμοιβή που ΠΛΗΡΩΘΗΚΕ στο μέλος
--   ASSOCIATION_RETENTION   -> κράτηση 8% που ΟΦΕΙΛΕΙ το μέλος
--   RETENTION_COLLECTION    -> κράτηση 8% που ΕΙΣΠΡΑΧΘΗΚΕ από το μέλος
--   ANNUAL_SUBSCRIPTION     -> συνδρομή που ΟΦΕΙΛΕΙ το μέλος
--   SUBSCRIPTION_COLLECTION -> συνδρομή που ΕΙΣΠΡΑΧΘΗΚΕ
--   FINE                    -> πρόστιμο που ΟΦΕΙΛΕΙ το μέλος
-- ---------------------------------------------------
CREATE TABLE member_transactions (
    transaction_id     NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    member_id          NUMBER NOT NULL,
    transaction_type   VARCHAR2(25) NOT NULL,
    amount             NUMBER(8,2) NOT NULL CHECK (amount >= 0),
    match_id           NUMBER,
    description        VARCHAR2(300),
    transaction_date   DATE DEFAULT SYSDATE NOT NULL,
    CONSTRAINT fk_trans_member FOREIGN KEY (member_id) REFERENCES members(member_id),
    CONSTRAINT fk_trans_match  FOREIGN KEY (match_id)  REFERENCES matches(match_id),
    CONSTRAINT chk_trans_type CHECK (transaction_type IN (
        'MATCH_FEE', 'MATCH_FEE_PAYMENT',
        'ASSOCIATION_RETENTION', 'RETENTION_COLLECTION',
        'ANNUAL_SUBSCRIPTION', 'SUBSCRIPTION_COLLECTION',
        'FINE'
    ))
);


-- =====================================================
-- ΜΕΡΟΣ 2 — Seed δεδομένα αμοιβών
-- =====================================================
INSERT INTO fee_categories (competition, role_code, amount) VALUES ('Α1 Εθνική Ανδρών', 'REFEREE_A', 80.00);
INSERT INTO fee_categories (competition, role_code, amount) VALUES ('Α1 Εθνική Ανδρών', 'REFEREE_B', 80.00);
INSERT INTO fee_categories (competition, role_code, amount) VALUES ('Α1 Εθνική Ανδρών', 'OBSERVER',  50.00);
INSERT INTO fee_categories (competition, role_code, amount) VALUES ('Α1 Εθνική Ανδρών', 'SECRETARY', 30.00);
COMMIT;


-- =====================================================
-- ΜΕΡΟΣ 3 — Procedure: αυτόματος υπολογισμός ΟΦΕΙΛΟΜΕΝΗΣ
-- αμοιβής + ΟΦΕΙΛΟΜΕΝΗΣ κράτησης 8%, για όλους τους
-- ορισμένους σε έναν αγώνα. Η πληρωμή/είσπραξη είναι
-- ξεχωριστό, μεταγενέστερο βήμα (δεν συμβαίνει αυτόματα).
-- =====================================================
CREATE OR REPLACE PROCEDURE generate_match_fees (
    p_match_id IN matches.match_id%TYPE
) AS
    v_retention_rate CONSTANT NUMBER := 0.08;
    v_fee            NUMBER;
BEGIN
    FOR assignment IN (
        SELECT ma.member_id, r.role_code, m.competition
        FROM match_assignments ma
        JOIN roles   r ON r.role_id  = ma.role_id
        JOIN matches m ON m.match_id = ma.match_id
        WHERE ma.match_id = p_match_id
    ) LOOP

        BEGIN
            SELECT amount INTO v_fee
            FROM fee_categories
            WHERE competition = assignment.competition
              AND role_code   = assignment.role_code;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_fee := NULL;
        END;

        IF v_fee IS NOT NULL THEN
            -- Οφειλόμενη αμοιβή
            INSERT INTO member_transactions (member_id, transaction_type, amount, match_id, description)
            VALUES (
                assignment.member_id, 'MATCH_FEE', v_fee, p_match_id,
                'Αμοιβή αγώνα -- ' || assignment.competition
            );

            -- Οφειλόμενη κράτηση 8%
            INSERT INTO member_transactions (member_id, transaction_type, amount, match_id, description)
            VALUES (
                assignment.member_id, 'ASSOCIATION_RETENTION', ROUND(v_fee * v_retention_rate, 2), p_match_id,
                'Κράτηση 8% επί αμοιβής αγώνα'
            );
        END IF;

    END LOOP;

    COMMIT;
END generate_match_fees;
/


-- =====================================================
-- ΜΕΡΟΣ 4 — Views: συγκεντρωτική "Καρτέλα Μέλους",
-- ΑΚΡΙΒΩΣ όπως Ποσό / Είσπραξη / Υπόλοιπο
-- =====================================================

-- Αμοιβές ανά ρόλο (Διαιτητής / Παρατηρητής / Γραμματέας)
CREATE OR REPLACE VIEW member_role_financials AS
SELECT
    mt.member_id,
    CASE
        WHEN ma.role_id IS NULL THEN 'ΓΕΝΙΚΑ'
        WHEN r.role_code IN ('REFEREE_A','REFEREE_B') THEN 'ΔΙΑΙΤΗΤΗΣ'
        WHEN r.role_code = 'OBSERVER'  THEN 'ΠΑΡΑΤΗΡΗΤΗΣ'
        WHEN r.role_code = 'SECRETARY' THEN 'ΓΡΑΜΜΑΤΕΑΣ'
    END AS role_category,
    COUNT(DISTINCT CASE WHEN mt.transaction_type = 'MATCH_FEE' THEN mt.match_id END) AS participations,
    SUM(CASE WHEN mt.transaction_type = 'MATCH_FEE'         THEN mt.amount ELSE 0 END) AS amount_owed,
    SUM(CASE WHEN mt.transaction_type = 'MATCH_FEE_PAYMENT' THEN mt.amount ELSE 0 END) AS amount_paid
FROM member_transactions mt
LEFT JOIN match_assignments ma
       ON ma.match_id = mt.match_id AND ma.member_id = mt.member_id
LEFT JOIN roles r
       ON r.role_id = ma.role_id
WHERE mt.transaction_type IN ('MATCH_FEE', 'MATCH_FEE_PAYMENT')
GROUP BY
    mt.member_id,
    CASE
        WHEN ma.role_id IS NULL THEN 'ΓΕΝΙΚΑ'
        WHEN r.role_code IN ('REFEREE_A','REFEREE_B') THEN 'ΔΙΑΙΤΗΤΗΣ'
        WHEN r.role_code = 'OBSERVER'  THEN 'ΠΑΡΑΤΗΡΗΤΗΣ'
        WHEN r.role_code = 'SECRETARY' THEN 'ΓΡΑΜΜΑΤΕΑΣ'
    END;

-- Παρακρατήσεις: Ποσό / Είσπραξη / Υπόλοιπο
CREATE OR REPLACE VIEW member_retention_summary AS
SELECT
    member_id,
    SUM(CASE WHEN transaction_type = 'ASSOCIATION_RETENTION' THEN amount ELSE 0 END) AS amount_owed,
    SUM(CASE WHEN transaction_type = 'RETENTION_COLLECTION'  THEN amount ELSE 0 END) AS amount_collected
FROM member_transactions
WHERE transaction_type IN ('ASSOCIATION_RETENTION', 'RETENTION_COLLECTION')
GROUP BY member_id;

-- Συνδρομές: Ποσό / Είσπραξη / Υπόλοιπο
CREATE OR REPLACE VIEW member_subscription_summary AS
SELECT
    member_id,
    SUM(CASE WHEN transaction_type = 'ANNUAL_SUBSCRIPTION'     THEN amount ELSE 0 END) AS amount_owed,
    SUM(CASE WHEN transaction_type = 'SUBSCRIPTION_COLLECTION' THEN amount ELSE 0 END) AS amount_collected
FROM member_transactions
WHERE transaction_type IN ('ANNUAL_SUBSCRIPTION', 'SUBSCRIPTION_COLLECTION')
GROUP BY member_id;


-- =====================================================
-- ΜΕΡΟΣ 5 — Δοκιμή από την αρχή, καθαρά
-- =====================================================

-- 1) Αυτόματη δημιουργία οφειλόμενης αμοιβής + κράτησης για τον αγώνα 1
EXEC generate_match_fees(1);

-- 2) Ο σύνδεσμος πληρώνει την αμοιβή στον Γιώργο Παπαδόπουλο (member_id=1)
INSERT INTO member_transactions (member_id, transaction_type, amount, match_id, description)
VALUES (1, 'MATCH_FEE_PAYMENT', 80.00, 1, 'Πληρωμή αμοιβής αγώνα');

-- 3) Ο Γιώργος αποδίδει την κράτηση 8% πίσω στον σύνδεσμο
INSERT INTO member_transactions (member_id, transaction_type, amount, match_id, description)
VALUES (1, 'RETENTION_COLLECTION', 6.40, 1, 'Απόδοση κράτησης 8%');

COMMIT;

-- Καρτέλα -- Αμοιβές ανά ρόλο
SELECT role_category, participations, amount_owed, amount_paid,
       (amount_owed - amount_paid) AS balance
FROM member_role_financials
WHERE member_id = 1;

-- Καρτέλα -- Παρακρατήσεις
SELECT amount_owed, amount_collected,
       (amount_owed - amount_collected) AS balance
FROM member_retention_summary
WHERE member_id = 1;

-- Καρτέλα -- Συνδρομές
SELECT amount_owed, amount_collected,
       (amount_owed - amount_collected) AS balance
FROM member_subscription_summary
WHERE member_id = 1;

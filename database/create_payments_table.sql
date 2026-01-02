-- Table pour gérer les paiements mensuels
CREATE TABLE IF NOT EXISTS payments (
    id SERIAL PRIMARY KEY,
    enrollment_id INTEGER NOT NULL,
    parent_id VARCHAR(255) NOT NULL,
    nursery_id VARCHAR(255) NOT NULL,
    child_id INTEGER NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    payment_month INTEGER NOT NULL, -- Mois (1-12)
    payment_year INTEGER NOT NULL,  -- Année
    payment_status VARCHAR(50) DEFAULT 'unpaid', -- 'paid' ou 'unpaid'
    payment_date TIMESTAMP,
    card_last_digits VARCHAR(4), -- 4 derniers chiffres de la carte
    transaction_id VARCHAR(255),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    CONSTRAINT fk_enrollment FOREIGN KEY (enrollment_id) REFERENCES enrollments(id) ON DELETE CASCADE,
    CONSTRAINT fk_parent FOREIGN KEY (parent_id) REFERENCES parents(id) ON DELETE CASCADE,
    CONSTRAINT fk_nursery FOREIGN KEY (nursery_id) REFERENCES nurseries(id) ON DELETE CASCADE,
    CONSTRAINT fk_child FOREIGN KEY (child_id) REFERENCES children(id) ON DELETE CASCADE,
    UNIQUE(enrollment_id, payment_month, payment_year) -- Un seul paiement par mois par inscription
);

-- Index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_payments_parent ON payments(parent_id);
CREATE INDEX IF NOT EXISTS idx_payments_nursery ON payments(nursery_id);
CREATE INDEX IF NOT EXISTS idx_payments_status ON payments(payment_status);
CREATE INDEX IF NOT EXISTS idx_payments_month_year ON payments(payment_month, payment_year);

-- Vue pour faciliter les requêtes
CREATE OR REPLACE VIEW payment_details AS
SELECT 
    p.id,
    p.enrollment_id,
    p.parent_id,
    p.nursery_id,
    p.child_id,
    p.amount,
    p.payment_month,
    p.payment_year,
    p.payment_status,
    p.payment_date,
    p.card_last_digits,
    par.name as parent_name,
    par.email as parent_email,
    c.child_name,
    n.name as nursery_name,
    n.monthly_fee
FROM payments p
JOIN parents par ON p.parent_id = par.id
JOIN children c ON p.child_id = c.id
JOIN nurseries n ON p.nursery_id = n.id;

-- Fonction pour créer automatiquement les paiements mensuels
CREATE OR REPLACE FUNCTION create_monthly_payments()
RETURNS void AS $$
DECLARE
    current_month INTEGER := EXTRACT(MONTH FROM CURRENT_DATE);
    current_year INTEGER := EXTRACT(YEAR FROM CURRENT_DATE);
BEGIN
    -- Créer les paiements pour tous les enrollments acceptés qui n'ont pas encore de paiement ce mois-ci
    INSERT INTO payments (enrollment_id, parent_id, nursery_id, child_id, amount, payment_month, payment_year, payment_status)
    SELECT 
        e.id,
        e.parent_id,
        e.nursery_id,
        e.child_id,
        n.monthly_fee,
        current_month,
        current_year,
        'unpaid'
    FROM enrollments e
    JOIN nurseries n ON e.nursery_id = n.id
    WHERE e.status = 'accepted'
    AND NOT EXISTS (
        SELECT 1 FROM payments p 
        WHERE p.enrollment_id = e.id 
        AND p.payment_month = current_month 
        AND p.payment_year = current_year
    );
END;
$$ LANGUAGE plpgsql;

-- Commentaires pour documentation
COMMENT ON TABLE payments IS 'Gestion des paiements mensuels des parents';
COMMENT ON COLUMN payments.payment_status IS 'Statut: paid ou unpaid';
COMMENT ON COLUMN payments.payment_month IS 'Mois du paiement (1-12)';
COMMENT ON COLUMN payments.payment_year IS 'Année du paiement';

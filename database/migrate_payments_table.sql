-- Migration pour adapter la table payments au suivi financier mensuel

-- Ajouter les nouvelles colonnes si elles n'existent pas
DO $$
BEGIN
    -- Ajouter nursery_id
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='payments' AND column_name='nursery_id') THEN
        ALTER TABLE payments ADD COLUMN nursery_id UUID;
        ALTER TABLE payments ADD CONSTRAINT fk_payments_nursery 
            FOREIGN KEY (nursery_id) REFERENCES nurseries(id) ON DELETE CASCADE;
        CREATE INDEX IF NOT EXISTS idx_payments_nursery ON payments(nursery_id);
    END IF;

    -- Ajouter child_id
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='payments' AND column_name='child_id') THEN
        ALTER TABLE payments ADD COLUMN child_id UUID;
        ALTER TABLE payments ADD CONSTRAINT fk_payments_child 
            FOREIGN KEY (child_id) REFERENCES children(id) ON DELETE CASCADE;
    END IF;

    -- Ajouter payment_month
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='payments' AND column_name='payment_month') THEN
        ALTER TABLE payments ADD COLUMN payment_month INTEGER;
    END IF;

    -- Ajouter payment_year
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='payments' AND column_name='payment_year') THEN
        ALTER TABLE payments ADD COLUMN payment_year INTEGER;
    END IF;

    -- Ajouter card_last_digits
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='payments' AND column_name='card_last_digits') THEN
        ALTER TABLE payments ADD COLUMN card_last_digits VARCHAR(4);
    END IF;

    -- Ajouter payment_status (renommer status)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name='payments' AND column_name='payment_status') THEN
        ALTER TABLE payments ADD COLUMN payment_status VARCHAR(50) DEFAULT 'unpaid';
    END IF;
END $$;

-- Mettre à jour les paiements existants avec les données du mois courant
UPDATE payments 
SET 
    payment_month = EXTRACT(MONTH FROM COALESCE(payment_date, CURRENT_DATE)),
    payment_year = EXTRACT(YEAR FROM COALESCE(payment_date, CURRENT_DATE)),
    payment_status = CASE 
        WHEN status = 'completed' THEN 'paid'
        ELSE 'unpaid'
    END
WHERE payment_month IS NULL OR payment_year IS NULL;

-- Ajouter nursery_id et child_id aux paiements existants depuis enrollments
UPDATE payments p
SET 
    nursery_id = e.nursery_id,
    child_id = e.child_id
FROM enrollments e
WHERE p.enrollment_id = e.id AND (p.nursery_id IS NULL OR p.child_id IS NULL);

-- Créer un index unique pour un seul paiement par mois par inscription
DROP INDEX IF EXISTS idx_payments_unique_monthly;
CREATE UNIQUE INDEX idx_payments_unique_monthly 
ON payments(enrollment_id, payment_month, payment_year);

-- Index sur le mois/année pour les requêtes
CREATE INDEX IF NOT EXISTS idx_payments_month_year ON payments(payment_month, payment_year);

-- Supprimer l'ancienne contrainte de status si elle existe
ALTER TABLE payments DROP CONSTRAINT IF EXISTS payments_status_check;

-- Vue pour faciliter les requêtes (supprimer si existe)
DROP VIEW IF EXISTS payment_details;

CREATE VIEW payment_details AS
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
    p.transaction_id,
    u.name as parent_name,
    u.email as parent_email,
    c.name as child_name,
    n.name as nursery_name,
    n.price_per_month
FROM payments p
JOIN users u ON p.parent_id = u.id
JOIN children c ON p.child_id = c.id
JOIN nurseries n ON p.nursery_id = n.id;

-- Supprimer et recréer la fonction pour créer automatiquement les paiements mensuels
DROP FUNCTION IF EXISTS create_monthly_payments();

CREATE FUNCTION create_monthly_payments()
RETURNS INTEGER AS $$
DECLARE
    current_month INTEGER := EXTRACT(MONTH FROM CURRENT_DATE);
    current_year INTEGER := EXTRACT(YEAR FROM CURRENT_DATE);
    inserted_count INTEGER;
BEGIN
    -- Créer les paiements pour tous les enrollments acceptés qui n'ont pas encore de paiement ce mois-ci
    WITH inserted AS (
        INSERT INTO payments (enrollment_id, parent_id, nursery_id, child_id, amount, payment_month, payment_year, payment_status)
        SELECT 
            e.id,
            c.parent_id,
            e.nursery_id,
            e.child_id,
            COALESCE(n.price_per_month, 100.00),
            current_month,
            current_year,
            'unpaid'
        FROM enrollments e
        JOIN nurseries n ON e.nursery_id = n.id
        JOIN children c ON e.child_id = c.id
        WHERE e.status = 'accepted'
        AND NOT EXISTS (
            SELECT 1 FROM payments p 
            WHERE p.enrollment_id = e.id 
            AND p.payment_month = current_month 
            AND p.payment_year = current_year
        )
        RETURNING id
    )
    SELECT COUNT(*) INTO inserted_count FROM inserted;
    
    RETURN inserted_count;
END;
$$ LANGUAGE plpgsql;

-- Générer les paiements pour le mois en cours
SELECT create_monthly_payments() as payments_created;

COMMENT ON TABLE payments IS 'Gestion des paiements mensuels des parents';
COMMENT ON COLUMN payments.payment_status IS 'Statut: paid ou unpaid';
COMMENT ON COLUMN payments.payment_month IS 'Mois du paiement (1-12)';
COMMENT ON COLUMN payments.payment_year IS 'Année du paiement';

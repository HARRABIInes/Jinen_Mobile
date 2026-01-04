// Script pour vérifier le paiement de hanen
const { Pool } = require('pg');

const pool = new Pool({
  user: 'nursery_admin',
  host: 'localhost',
  database: 'nursery_db',
  password: 'nursery_password_2025',
  port: 5432,
});

async function checkPayment() {
  try {
    console.log('🔍 Vérification du paiement de hanen...\n');
    
    // Obtenir le payment détaillé
    const query = `
      SELECT 
        p.id as payment_id,
        p.enrollment_id,
        p.parent_id,
        p.nursery_id,
        p.child_id,
        p.amount,
        p.payment_status,
        p.payment_month,
        p.payment_year,
        p.created_at,
        u.name as parent_name,
        c.name as child_name,
        n.name as nursery_name,
        n.owner_id,
        e.status as enrollment_status
      FROM payments p
      JOIN users u ON p.parent_id = u.id
      JOIN children c ON p.child_id = c.id
      JOIN nurseries n ON p.nursery_id = n.id
      JOIN enrollments e ON p.enrollment_id = e.id
      WHERE LOWER(u.name) = 'hanen'
    `;
    
    const result = await pool.query(query);
    
    if (result.rows.length === 0) {
      console.log('❌ Aucun paiement trouvé pour hanen\n');
      return;
    }
    
    console.log('💰 Paiement trouvé:\n');
    const payment = result.rows[0];
    
    console.log('   INFORMATIONS DU PAIEMENT:');
    console.log(`   - Payment ID: ${payment.payment_id}`);
    console.log(`   - Parent: ${payment.parent_name} (ID: ${payment.parent_id})`);
    console.log(`   - Enfant: ${payment.child_name} (ID: ${payment.child_id})`);
    console.log(`   - Garderie: ${payment.nursery_name} (ID: ${payment.nursery_id})`);
    console.log(`   - Owner ID: ${payment.owner_id}`);
    console.log(`   - Montant: ${payment.amount} TND`);
    console.log(`   - Status paiement: ${payment.payment_status}`);
    console.log(`   - Status inscription: ${payment.enrollment_status}`);
    console.log(`   - Mois: ${payment.payment_month}`);
    console.log(`   - Année: ${payment.payment_year}`);
    console.log(`   - Créé le: ${payment.created_at}\n`);
    
    // Tester la requête du parent
    console.log('🔍 Test de la requête parent (GET /api/payments/parent/:parentId/status):\n');
    
    const parentQuery = `
      SELECT 
        p.id,
        p.enrollment_id,
        p.amount,
        p.payment_status,
        p.payment_date,
        p.payment_month,
        p.payment_year,
        c.name as child_name,
        n.name as nursery_name,
        n.id as nursery_id
      FROM payments p
      JOIN enrollments e ON p.enrollment_id = e.id
      JOIN children c ON e.child_id = c.id
      JOIN nurseries n ON p.nursery_id = n.id
      WHERE p.parent_id = $1 
        AND e.status IN ('pending', 'active')
      ORDER BY c.name
    `;
    
    const parentResult = await pool.query(parentQuery, [payment.parent_id]);
    
    console.log(`   Résultats: ${parentResult.rows.length} paiement(s) trouvé(s)`);
    if (parentResult.rows.length > 0) {
      parentResult.rows.forEach(p => {
        console.log(`   - ${p.child_name} à ${p.nursery_name}: ${p.amount} TND (${p.payment_status})`);
      });
    }
    console.log('');
    
    // Tester la requête de la garderie
    console.log('🔍 Test de la requête garderie (GET /api/payments/owner/:ownerId):\n');
    
    const ownerQuery = `
      SELECT 
        p.id,
        p.amount,
        p.payment_status,
        p.payment_date,
        p.payment_month,
        p.payment_year,
        p.card_last_digits,
        c.name as child_name,
        u.name as parent_name,
        u.email as parent_email,
        u.phone as parent_phone
      FROM payments p
      JOIN nurseries n ON p.nursery_id = n.id
      JOIN enrollments e ON p.enrollment_id = e.id
      JOIN children c ON e.child_id = c.id
      JOIN users u ON p.parent_id = u.id
      WHERE n.owner_id = $1 
        AND e.status IN ('pending', 'active')
      ORDER BY p.payment_status, c.name
    `;
    
    const ownerResult = await pool.query(ownerQuery, [payment.owner_id]);
    
    console.log(`   Résultats: ${ownerResult.rows.length} paiement(s) trouvé(s)`);
    if (ownerResult.rows.length > 0) {
      ownerResult.rows.forEach(p => {
        console.log(`   - ${p.child_name} (parent: ${p.parent_name}): ${p.amount} TND (${p.payment_status})`);
      });
    }
    console.log('');
    
    // Diagnostic
    console.log('🔍 DIAGNOSTIC:\n');
    
    if (payment.enrollment_status !== 'active' && payment.enrollment_status !== 'pending') {
      console.log(`   ⚠️  PROBLÈME: Status inscription "${payment.enrollment_status}" invalide`);
      console.log(`   Les requêtes filtrent sur: e.status IN ('pending', 'active')`);
    } else {
      console.log('   ✅ Status inscription OK');
    }
    
    if (parentResult.rows.length === 0) {
      console.log('   ❌ Le paiement n\'apparaît PAS dans la requête parent');
    } else {
      console.log('   ✅ Le paiement apparaît dans la requête parent');
    }
    
    if (ownerResult.rows.length === 0) {
      console.log('   ❌ Le paiement n\'apparaît PAS dans la requête propriétaire');
    } else {
      console.log('   ✅ Le paiement apparaît dans la requête propriétaire');
    }
    
  } catch (error) {
    console.error('❌ Erreur:', error.message);
  } finally {
    await pool.end();
  }
}

checkPayment();

// Script pour créer manuellement le paiement de hanen
const { Pool } = require('pg');

const pool = new Pool({
  user: 'nursery_admin',
  host: 'localhost',
  database: 'nursery_db',
  password: 'nursery_password_2025',
  port: 5432,
});

async function createHanenPayment() {
  const client = await pool.connect();
  
  try {
    await client.query('BEGIN');
    
    console.log('🔍 Recherche de l\'inscription de hanen...\n');
    
    // Trouver l'inscription de hanen
    const enrollmentQuery = `
      SELECT e.id as enrollment_id, c.parent_id, e.nursery_id, e.child_id, 
             n.price_per_month, c.name as child_name, n.name as nursery_name
      FROM enrollments e
      JOIN children c ON e.child_id = c.id
      JOIN nurseries n ON e.nursery_id = n.id
      JOIN users u ON c.parent_id = u.id
      WHERE LOWER(u.name) = 'hanen'
        AND e.status = 'active'
    `;
    
    const enrollmentResult = await client.query(enrollmentQuery);
    
    if (enrollmentResult.rows.length === 0) {
      console.log('❌ Aucune inscription active trouvée pour hanen\n');
      await client.query('ROLLBACK');
      return;
    }
    
    console.log('✅ Inscription trouvée:');
    const enrollment = enrollmentResult.rows[0];
    console.log(`   - Inscription ID: ${enrollment.enrollment_id}`);
    console.log(`   - Enfant: ${enrollment.child_name}`);
    console.log(`   - Garderie: ${enrollment.nursery_name}`);
    console.log(`   - Parent ID: ${enrollment.parent_id}`);
    console.log(`   - Montant: ${enrollment.price_per_month} TND\n`);
    
    // Vérifier si un paiement existe déjà
    const existingPayment = await client.query(
      'SELECT id FROM payments WHERE enrollment_id = $1',
      [enrollment.enrollment_id]
    );
    
    if (existingPayment.rows.length > 0) {
      console.log('⚠️  Un paiement existe déjà pour cette inscription!');
      console.log(`   Payment ID: ${existingPayment.rows[0].id}\n`);
      await client.query('ROLLBACK');
      return;
    }
    
    // Créer le paiement
    console.log('💰 Création du paiement...\n');
    
    const insertQuery = `
      INSERT INTO payments (enrollment_id, parent_id, nursery_id, child_id, amount, payment_status)
      VALUES ($1, $2, $3, $4, $5, $6)
      RETURNING id, amount, payment_status
    `;
    
    const insertResult = await client.query(insertQuery, [
      enrollment.enrollment_id,
      enrollment.parent_id,
      enrollment.nursery_id,
      enrollment.child_id,
      enrollment.price_per_month || 100.00,
      'unpaid'
    ]);
    
    await client.query('COMMIT');
    
    console.log('✅ PAIEMENT CRÉÉ AVEC SUCCÈS!');
    console.log(`   - Payment ID: ${insertResult.rows[0].id}`);
    console.log(`   - Montant: ${insertResult.rows[0].amount} TND`);
    console.log(`   - Status: ${insertResult.rows[0].payment_status}\n`);
    
    console.log('🎉 Le paiement devrait maintenant apparaître dans l\'application!');
    
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('❌ Erreur:', error.message);
    console.error('\nDétails:', error);
  } finally {
    client.release();
    await pool.end();
  }
}

createHanenPayment();

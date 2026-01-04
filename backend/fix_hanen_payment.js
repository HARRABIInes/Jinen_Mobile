// Script pour corriger le paiement de hanen
const { Pool } = require('pg');

const pool = new Pool({
  user: 'nursery_admin',
  host: 'localhost',
  database: 'nursery_db',
  password: 'nursery_password_2025',
  port: 5432,
});

async function fixHanenPayment() {
  const client = await pool.connect();
  
  try {
    await client.query('BEGIN');
    
    console.log('🔧 Correction du paiement de hanen...\n');
    
    // Mettre à jour les paiements avec nursery_id et child_id NULL
    const updateQuery = `
      UPDATE payments p
      SET 
        nursery_id = e.nursery_id,
        child_id = e.child_id
      FROM enrollments e
      WHERE p.enrollment_id = e.id
        AND (p.nursery_id IS NULL OR p.child_id IS NULL)
      RETURNING p.id, p.enrollment_id, p.nursery_id, p.child_id
    `;
    
    const result = await client.query(updateQuery);
    
    console.log(`✅ ${result.rows.length} paiement(s) corrigé(s):\n`);
    
    result.rows.forEach(p => {
      console.log(`   Payment ID: ${p.id}`);
      console.log(`   - enrollment_id: ${p.enrollment_id}`);
      console.log(`   - nursery_id: ${p.nursery_id} (maintenant rempli)`);
      console.log(`   - child_id: ${p.child_id} (maintenant rempli)\n`);
    });
    
    await client.query('COMMIT');
    
    console.log('🎉 Correction terminée!');
    console.log('✅ Le paiement devrait maintenant apparaître dans l\'application\n');
    
    // Vérifier que tout est OK maintenant
    console.log('🔍 Vérification finale...\n');
    
    const verifyQuery = `
      SELECT 
        p.id,
        p.enrollment_id,
        p.amount,
        p.payment_status,
        c.name as child_name,
        n.name as nursery_name
      FROM payments p
      JOIN enrollments e ON p.enrollment_id = e.id
      JOIN children c ON e.child_id = c.id
      JOIN nurseries n ON p.nursery_id = n.id
      WHERE p.parent_id = '09b612fb-8fb1-4c13-a17c-9c973aa71da3'
    `;
    
    const verifyResult = await client.query(verifyQuery);
    
    if (verifyResult.rows.length > 0) {
      console.log('✅ Le paiement est maintenant visible avec les JOIN:');
      verifyResult.rows.forEach(p => {
        console.log(`   - ${p.child_name} à ${p.nursery_name}: ${p.amount} TND (${p.payment_status})`);
      });
    } else {
      console.log('❌ Problème: le paiement n\'est toujours pas visible');
    }
    
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('❌ Erreur:', error.message);
  } finally {
    client.release();
    await pool.end();
  }
}

fixHanenPayment();

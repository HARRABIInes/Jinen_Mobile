// Script pour vérifier l'état de l'inscription de hanen
const { Pool } = require('pg');

const pool = new Pool({
  user: 'nursery_admin',
  host: 'localhost',
  database: 'nursery_db',
  password: 'nursery_password_2025',
  port: 5432,
});

async function checkHanen() {
  try {
    console.log('🔍 Recherche de l\'utilisateur "hanen"...\n');
    
    // Trouver l'utilisateur hanen
    const userQuery = `
      SELECT id, name, email, user_type 
      FROM users 
      WHERE LOWER(name) LIKE '%hanen%' OR LOWER(email) LIKE '%hanen%'
    `;
    const userResult = await pool.query(userQuery);
    
    if (userResult.rows.length === 0) {
      console.log('❌ Aucun utilisateur "hanen" trouvé\n');
      return;
    }
    
    console.log('👤 Utilisateur(s) trouvé(s):');
    userResult.rows.forEach(user => {
      console.log(`   - ID: ${user.id}, Nom: ${user.name}, Email: ${user.email}, Type: ${user.user_type}`);
    });
    console.log('');
    
    const hanenId = userResult.rows[0].id;
    
    // Trouver les enfants de hanen
    const childQuery = `
      SELECT id, name, parent_id 
      FROM children 
      WHERE parent_id = $1
    `;
    const childResult = await pool.query(childQuery, [hanenId]);
    
    console.log(`👶 Enfant(s) de hanen (${childResult.rows.length}):`);
    if (childResult.rows.length === 0) {
      console.log('   Aucun enfant trouvé\n');
    } else {
      childResult.rows.forEach(child => {
        console.log(`   - ID: ${child.id}, Nom: ${child.name}`);
      });
      console.log('');
    }
    
    // Trouver les inscriptions
    const enrollmentQuery = `
      SELECT e.id, e.status, e.created_at, e.updated_at, 
             c.name as child_name, n.name as nursery_name, n.id as nursery_id
      FROM enrollments e
      JOIN children c ON e.child_id = c.id
      JOIN nurseries n ON e.nursery_id = n.id
      WHERE c.parent_id = $1
      ORDER BY e.created_at DESC
    `;
    const enrollmentResult = await pool.query(enrollmentQuery, [hanenId]);
    
    console.log(`📝 Inscription(s) de hanen (${enrollmentResult.rows.length}):`);
    if (enrollmentResult.rows.length === 0) {
      console.log('   Aucune inscription trouvée\n');
    } else {
      enrollmentResult.rows.forEach(enr => {
        console.log(`   - ID: ${enr.id}`);
        console.log(`     Enfant: ${enr.child_name}`);
        console.log(`     Garderie: ${enr.nursery_name} (ID: ${enr.nursery_id})`);
        console.log(`     Status: ${enr.status}`);
        console.log(`     Créée: ${enr.created_at}`);
        console.log(`     Mise à jour: ${enr.updated_at}`);
        console.log('');
      });
    }
    
    // Trouver les paiements
    const paymentQuery = `
      SELECT p.id, p.enrollment_id, p.amount, p.payment_status, p.created_at,
             c.name as child_name, n.name as nursery_name
      FROM payments p
      JOIN enrollments e ON p.enrollment_id = e.id
      JOIN children c ON e.child_id = c.id
      JOIN nurseries n ON p.nursery_id = n.id
      WHERE p.parent_id = $1
      ORDER BY p.created_at DESC
    `;
    const paymentResult = await pool.query(paymentQuery, [hanenId]);
    
    console.log(`💰 Paiement(s) de hanen (${paymentResult.rows.length}):`);
    if (paymentResult.rows.length === 0) {
      console.log('   ❌ Aucun paiement trouvé - C\'EST LE PROBLÈME!\n');
    } else {
      paymentResult.rows.forEach(pay => {
        console.log(`   - ID: ${pay.id}`);
        console.log(`     Inscription ID: ${pay.enrollment_id}`);
        console.log(`     Enfant: ${pay.child_name}`);
        console.log(`     Garderie: ${pay.nursery_name}`);
        console.log(`     Montant: ${pay.amount} TND`);
        console.log(`     Status: ${pay.payment_status}`);
        console.log(`     Créé: ${pay.created_at}`);
        console.log('');
      });
    }
    
    // Vérifier pourquoi le paiement n'est pas créé
    if (enrollmentResult.rows.length > 0 && paymentResult.rows.length === 0) {
      console.log('🔍 DIAGNOSTIC:');
      enrollmentResult.rows.forEach(enr => {
        console.log(`\n   Inscription ID ${enr.id}:`);
        console.log(`   - Status actuel: "${enr.status}"`);
        console.log(`   - Status attendu: "active" ou "pending"`);
        
        if (enr.status !== 'active' && enr.status !== 'pending') {
          console.log(`   ⚠️  PROBLÈME: Le status "${enr.status}" n'est pas géré par la synchronisation`);
        }
      });
    }
    
  } catch (error) {
    console.error('❌ Erreur:', error.message);
  } finally {
    await pool.end();
  }
}

checkHanen();

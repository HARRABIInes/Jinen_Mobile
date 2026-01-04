// Script simple pour vérifier la table payments
const { Pool } = require('pg');

const pool = new Pool({
  user: 'nursery_admin',
  host: 'localhost',
  database: 'nursery_db',
  password: 'nursery_password_2025',
  port: 5432,
});

async function checkDatabase() {
  try {
    console.log('🔍 Vérification complète de la base de données...\n');
    
    // 1. Tous les paiements
    console.log('1️⃣ TOUS LES PAIEMENTS:');
    const allPayments = await pool.query('SELECT * FROM payments LIMIT 10');
    console.log(`   Total: ${allPayments.rows.length} paiements\n`);
    
    if (allPayments.rows.length > 0) {
      console.log('   Colonnes de la table payments:');
      console.log('   ', Object.keys(allPayments.rows[0]).join(', '));
      console.log('');
      
      allPayments.rows.forEach((p, i) => {
        console.log(`   Paiement ${i + 1}:`);
        console.log(`   - ID: ${p.id}`);
        console.log(`   - enrollment_id: ${p.enrollment_id}`);
        console.log(`   - parent_id: ${p.parent_id}`);
        console.log(`   - nursery_id: ${p.nursery_id}`);
        console.log(`   - child_id: ${p.child_id}`);
        console.log(`   - amount: ${p.amount}`);
        console.log(`   - payment_status: ${p.payment_status}`);
        console.log('');
      });
    }
    
    // 2. Vérifier l'utilisateur hanen
    console.log('2️⃣ UTILISATEUR HANEN:');
    const user = await pool.query(
      "SELECT id, name, email FROM users WHERE LOWER(name) LIKE '%hanen%'"
    );
    if (user.rows.length > 0) {
      console.log(`   ID: ${user.rows[0].id}`);
      console.log(`   Nom: ${user.rows[0].name}`);
      console.log(`   Email: ${user.rows[0].email}\n`);
      
      // 3. Paiements de hanen
      console.log('3️⃣ PAIEMENTS DE HANEN (recherche directe par parent_id):');
      const hanenPayments = await pool.query(
        'SELECT * FROM payments WHERE parent_id = $1',
        [user.rows[0].id]
      );
      console.log(`   Total: ${hanenPayments.rows.length} paiement(s)\n`);
      
      if (hanenPayments.rows.length > 0) {
        hanenPayments.rows.forEach(p => {
          console.log(`   Payment ID: ${p.id}`);
          console.log(`   - enrollment_id: ${p.enrollment_id}`);
          console.log(`   - child_id: ${p.child_id}`);
          console.log(`   - nursery_id: ${p.nursery_id}`);
          console.log(`   - amount: ${p.amount}`);
          console.log(`   - payment_status: ${p.payment_status}\n`);
        });
      }
      
      // 4. Vérifier l'inscription
      if (hanenPayments.rows.length > 0) {
        const enrollmentId = hanenPayments.rows[0].enrollment_id;
        console.log(`4️⃣ INSCRIPTION ${enrollmentId}:`);
        
        const enrollment = await pool.query(
          'SELECT * FROM enrollments WHERE id = $1',
          [enrollmentId]
        );
        
        if (enrollment.rows.length > 0) {
          console.log(`   Status: ${enrollment.rows[0].status}`);
          console.log(`   child_id: ${enrollment.rows[0].child_id}`);
          console.log(`   nursery_id: ${enrollment.rows[0].nursery_id}\n`);
        } else {
          console.log('   ❌ Inscription introuvable!\n');
        }
        
        // 5. Vérifier l'enfant
        const childId = hanenPayments.rows[0].child_id;
        console.log(`5️⃣ ENFANT ${childId}:`);
        
        const child = await pool.query(
          'SELECT * FROM children WHERE id = $1',
          [childId]
        );
        
        if (child.rows.length > 0) {
          console.log(`   Nom: ${child.rows[0].name}`);
          console.log(`   parent_id: ${child.rows[0].parent_id}\n`);
        } else {
          console.log('   ❌ Enfant introuvable!\n');
        }
        
        // 6. Vérifier la garderie
        const nurseryId = hanenPayments.rows[0].nursery_id;
        console.log(`6️⃣ GARDERIE ${nurseryId}:`);
        
        const nursery = await pool.query(
          'SELECT * FROM nurseries WHERE id = $1',
          [nurseryId]
        );
        
        if (nursery.rows.length > 0) {
          console.log(`   Nom: ${nursery.rows[0].name}`);
          console.log(`   owner_id: ${nursery.rows[0].owner_id}\n`);
        } else {
          console.log('   ❌ Garderie introuvable!\n');
        }
      }
    } else {
      console.log('   ❌ Utilisateur hanen introuvable!\n');
    }
    
  } catch (error) {
    console.error('❌ Erreur:', error.message);
    console.error(error);
  } finally {
    await pool.end();
  }
}

checkDatabase();

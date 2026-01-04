// Script pour synchroniser les paiements
const axios = require('axios');

async function syncPayments() {
  try {
    console.log('🔄 Synchronisation des paiements en cours...');
    const response = await axios.post('http://localhost:3000/api/payments/sync');
    console.log('✅ Résultat:', JSON.stringify(response.data, null, 2));
  } catch (error) {
    console.error('❌ Erreur:', error.message);
    if (error.response) {
      console.error('Détails:', error.response.data);
    }
  }
}

syncPayments();

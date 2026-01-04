// Test de synchronisation des paiements
const http = require('http');

const options = {
  hostname: 'localhost',
  port: 3000,
  path: '/api/payments/sync',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json'
  }
};

console.log('📞 Appel de l\'API de synchronisation...\n');

const req = http.request(options, (res) => {
  let data = '';

  res.on('data', (chunk) => {
    data += chunk;
  });

  res.on('end', () => {
    console.log('📊 Réponse du serveur:');
    console.log(JSON.stringify(JSON.parse(data), null, 2));
    console.log('\n✅ Synchronisation terminée!');
  });
});

req.on('error', (error) => {
  console.error('❌ Erreur:', error.message);
  console.log('\n⚠️  Assurez-vous que le serveur backend est en cours d\'exécution sur le port 3000');
});

req.end();

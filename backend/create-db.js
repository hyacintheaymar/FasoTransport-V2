const { Client } = require('pg');

const client = new Client({
  user: 'postgres',
  host: 'localhost',
  database: 'postgres',
  password: 'postgres',
  port: 5432,
});

async function createDb() {
  try {
    await client.connect();
    console.log('Connected to PostgreSQL successfully.');
    
    const res = await client.query("SELECT datname FROM pg_database WHERE datname = 'fasotransport'");
    if (res.rowCount > 0) {
      console.log('Database "fasotransport" already exists.');
    } else {
      await client.query('CREATE DATABASE fasotransport');
      console.log('Database "fasotransport" created successfully!');
    }
  } catch (err) {
    if (err.message.includes('password authentication failed')) {
      console.error('\nERREUR: Le mot de passe pour l\'utilisateur "postgres" est incorrect. Si vous avez choisi un autre mot de passe lors de l\'installation, mettez à jour le fichier .env !');
    } else {
      console.error('\nERREUR:', err.message);
    }
  } finally {
    await client.end();
  }
}

createDb();

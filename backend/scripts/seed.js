const bcrypt = require('bcryptjs');
const { Client } = require('pg');
const { randomUUID } = require('crypto');

const client = new Client(
  process.env.DATABASE_URL
    ? { connectionString: process.env.DATABASE_URL }
    : {
        host: process.env.DB_HOST || 'localhost',
        port: Number(process.env.DB_PORT || 5432),
        user: process.env.DB_USERNAME || 'postgres',
        password: process.env.DB_PASSWORD || 'postgres',
        database: process.env.DB_DATABASE || 'fasotransport',
      },
);

async function ensureSchema() {
  await client.query('CREATE EXTENSION IF NOT EXISTS pgcrypto');

  await client.query(`
    CREATE TABLE IF NOT EXISTS users (
      id uuid PRIMARY KEY,
      "fullName" text NOT NULL,
      email text NOT NULL UNIQUE,
      phone text NOT NULL,
      "passwordHash" text NOT NULL,
      role text NOT NULL,
      "isActive" boolean NOT NULL DEFAULT true,
      "refreshToken" text,
      "avatarUrl" text,
      "createdAt" timestamptz NOT NULL DEFAULT NOW(),
      "updatedAt" timestamptz NOT NULL DEFAULT NOW()
    )
  `);

  await client.query(`
    CREATE TABLE IF NOT EXISTS routes (
      id uuid PRIMARY KEY,
      origin text NOT NULL,
      destination text NOT NULL,
      "distanceKm" integer NOT NULL,
      "durationMin" integer NOT NULL,
      "basePrice" integer NOT NULL,
      "isActive" boolean NOT NULL DEFAULT true,
      "createdAt" timestamptz NOT NULL DEFAULT NOW(),
      "updatedAt" timestamptz NOT NULL DEFAULT NOW()
    )
  `);

  await client.query(`
    CREATE TABLE IF NOT EXISTS buses (
      id uuid PRIMARY KEY,
      label text NOT NULL,
      "plateNumber" text NOT NULL,
      capacity integer NOT NULL,
      "companyName" text NOT NULL,
      "isActive" boolean NOT NULL DEFAULT true,
      "createdAt" timestamptz NOT NULL DEFAULT NOW(),
      "updatedAt" timestamptz NOT NULL DEFAULT NOW()
    )
  `);

  await client.query(`
    CREATE TABLE IF NOT EXISTS schedules (
      id uuid PRIMARY KEY,
      "routeId" uuid NOT NULL REFERENCES routes(id) ON DELETE RESTRICT,
      "busLabel" text NOT NULL,
      "agentId" uuid REFERENCES users(id) ON DELETE SET NULL,
      "departureTime" timestamptz NOT NULL,
      "arrivalTime" timestamptz NOT NULL,
      "availableSeats" integer NOT NULL,
      "totalSeats" integer NOT NULL,
      status text NOT NULL,
      price integer NOT NULL,
      "createdAt" timestamptz NOT NULL DEFAULT NOW(),
      "updatedAt" timestamptz NOT NULL DEFAULT NOW()
    )
  `);

  await client.query(`
    CREATE TABLE IF NOT EXISTS bookings (
      id uuid PRIMARY KEY,
      "passengerId" uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      "scheduleId" uuid NOT NULL REFERENCES schedules(id) ON DELETE CASCADE,
      "bookingCode" text NOT NULL UNIQUE,
      "seatNumber" integer NOT NULL,
      amount integer NOT NULL,
      "paymentStatus" text NOT NULL,
      "qrData" text NOT NULL,
      "qrImageBase64" text NOT NULL,
      "validatedAt" timestamptz,
      "createdAt" timestamptz NOT NULL DEFAULT NOW(),
      "updatedAt" timestamptz NOT NULL DEFAULT NOW()
    )
  `);

  await client.query(`
    CREATE TABLE IF NOT EXISTS chat_messages (
      id uuid PRIMARY KEY,
      "userId" uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      "userName" text NOT NULL,
      message text NOT NULL,
      "senderType" text NOT NULL,
      "isResolved" boolean NOT NULL DEFAULT false,
      "resolvedAt" timestamptz,
      category text,
      "createdAt" timestamptz NOT NULL DEFAULT NOW(),
      "updatedAt" timestamptz NOT NULL DEFAULT NOW()
    )
  `);
}

async function main() {
  await client.connect();
  await ensureSchema();

  await client.query('TRUNCATE TABLE bookings, chat_messages, schedules, buses, routes, users RESTART IDENTITY CASCADE');

  const passwordHash = await bcrypt.hash('Password123!', 10);

  const adminId = randomUUID();
  const agentId = randomUUID();
  const agent2Id = randomUUID();
  const passengerId = randomUUID();
  const route1Id = randomUUID();
  const route2Id = randomUUID();
  const bus1Id = randomUUID();
  const schedule1Id = randomUUID();
  const schedule2Id = randomUUID();
  const schedule3Id = randomUUID();

  await client.query(
    `INSERT INTO users (id, "fullName", email, phone, "passwordHash", role, "isActive") VALUES
      ($1, $2, $3, $4, $5, $6, $7),
      ($8, $9, $10, $11, $12, $13, $14),
      ($15, $16, $17, $18, $19, $20, $21),
      ($22, $23, $24, $25, $26, $27, $28)`,
    [
      adminId, 'Admin FasoTransport', 'admin@fasotransport.bf', '70000000', passwordHash, 'ADMIN', true,
      agentId, 'Agent Terrain', 'agent@fasotransport.bf', '71000000', passwordHash, 'AGENT', true,
      agent2Id, 'I. Kone', 'i.kone@faso.bf', '71111111', passwordHash, 'AGENT', true,
      passengerId, 'Passager Demo', 'passager@fasotransport.bf', '72000000', passwordHash, 'PASSENGER', true,
    ],
  );

  await client.query(
    `INSERT INTO routes (id, origin, destination, "distanceKm", "durationMin", "basePrice", "isActive") VALUES
      ($1, $2, $3, $4, $5, $6, $7),
      ($8, $9, $10, $11, $12, $13, $14)`,
    [
      route1Id, 'Ouagadougou', 'Bobo-Dioulasso', 350, 360, 7000, true,
      route2Id, 'Ouagadougou', 'Koudougou', 100, 120, 2500, true,
    ],
  );

  await client.query(
    `INSERT INTO buses (id, label, "plateNumber", capacity, "companyName", "isActive") VALUES
      ($1, $2, $3, $4, $5, $6)`,
    [bus1Id, 'Faso Bus 01', 'BF-1234-AZ', 30, 'Faso Transport', true],
  );

  await client.query(
    `INSERT INTO schedules (id, "routeId", "busLabel", "agentId", "departureTime", "arrivalTime", "availableSeats", "totalSeats", status, price) VALUES
      ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10),
      ($11, $12, $13, $14, $15, $16, $17, $18, $19, $20),
      ($21, $22, $23, $24, $25, $26, $27, $28, $29, $30)`,
    [
      schedule1Id, route1Id, 'Faso Bus 01', agentId, '2026-04-20T06:00:00.000Z', '2026-04-20T12:00:00.000Z', 30, 30, 'SCHEDULED', 7000,
      schedule2Id, route2Id, 'Faso Bus 02', agentId, '2026-04-20T09:00:00.000Z', '2026-04-20T11:00:00.000Z', 25, 25, 'SCHEDULED', 2500,
      schedule3Id, route1Id, 'Faso Bus 03', agent2Id, '2026-04-21T06:00:00.000Z', '2026-04-21T12:00:00.000Z', 28, 30, 'SCHEDULED', 7000,
    ],
  );

  console.log('Seed completed');
  console.log('Admin: admin@fasotransport.bf / Password123!');
  console.log('Agent: agent@fasotransport.bf / Password123!');
  console.log('Agent: i.kone@faso.bf / Password123!');
  console.log('Passenger: passager@fasotransport.bf / Password123!');

  await client.end();
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});

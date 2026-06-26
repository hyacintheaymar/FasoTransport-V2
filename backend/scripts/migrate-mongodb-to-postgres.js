/* eslint-disable no-console */

const { MongoClient } = require('mongodb');
const { Client } = require('pg');
const { randomUUID } = require('crypto');

const mongoUri =
  process.env.MONGO_URI ||
  process.env.MONGODB_URI ||
  'mongodb://localhost:27017/fasotransport';

const postgresClient = process.env.DATABASE_URL
  ? new Client({ connectionString: process.env.DATABASE_URL })
  : new Client({
      host: process.env.DB_HOST || 'localhost',
      port: Number(process.env.DB_PORT || 5432),
      user: process.env.DB_USERNAME || 'postgres',
      password: process.env.DB_PASSWORD || 'postgres',
      database: process.env.DB_DATABASE || 'fasotransport',
    });

function getId(value) {
  if (!value) {
    return null;
  }

  if (typeof value === 'string') {
    return value;
  }

  if (typeof value.toString === 'function') {
    return value.toString();
  }

  return String(value);
}

async function ensureTargetSchema(client) {
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

async function insertRow(client, queryText, values) {
  await client.query(queryText, values);
}

async function ensureUserMapping(pgClient, userIdMap, oldUserId, options = {}) {
  const legacyId = getId(oldUserId);
  if (!legacyId) {
    return null;
  }

  const existing = userIdMap.get(legacyId);
  if (existing) {
    return existing;
  }

  const placeholderId = randomUUID();
  const placeholderEmail = `legacy-${legacyId}@import.local`;
  const placeholderRole = options.role || 'PASSENGER';
  const placeholderName = options.fullName || `Legacy ${placeholderRole.toLowerCase()}`;

  userIdMap.set(legacyId, placeholderId);

  await insertRow(
    pgClient,
    `INSERT INTO users (id, "fullName", email, phone, "passwordHash", role, "isActive", "refreshToken", "avatarUrl", "createdAt", "updatedAt")
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)`,
    [
      placeholderId,
      placeholderName,
      placeholderEmail,
      options.phone || '00000000',
      '__migrated_from_mongodb__',
      placeholderRole,
      false,
      null,
      null,
      new Date(),
      new Date(),
    ],
  );

  return placeholderId;
}

async function main() {
  const mongoClient = new MongoClient(mongoUri);

  await mongoClient.connect();
  try {
    await postgresClient.connect();
  } catch (error) {
    if (error && (error.code === 'ECONNREFUSED' || error.code === 'ENOTFOUND')) {
      throw new Error(
        `Unable to connect to PostgreSQL at ${process.env.DATABASE_URL || `${process.env.DB_HOST || 'localhost'}:${process.env.DB_PORT || 5432}`}. ` +
          'Start PostgreSQL first, then rerun: npm run migrate:mongo -- --truncate',
      );
    }

    throw error;
  }
  await ensureTargetSchema(postgresClient);

  const mongoDb = mongoClient.db();
  const users = await mongoDb.collection('users').find({}).toArray();
  const routes = await mongoDb.collection('routes').find({}).toArray();
  const buses = await mongoDb.collection('buses').find({}).toArray();
  const schedules = await mongoDb.collection('schedules').find({}).toArray();
  const bookings = await mongoDb.collection('bookings').find({}).toArray();
  const chatMessages = await mongoDb.collection('chat_messages').find({}).toArray();

  const userIdMap = new Map();
  const routeIdMap = new Map();
  const scheduleIdMap = new Map();

  await postgresClient.query('BEGIN');
  try {
    await postgresClient.query('TRUNCATE TABLE bookings, chat_messages, schedules, buses, routes, users RESTART IDENTITY CASCADE');

    for (const user of users) {
      const newId = randomUUID();
      userIdMap.set(getId(user._id), newId);

      await insertRow(
        postgresClient,
        `INSERT INTO users (id, "fullName", email, phone, "passwordHash", role, "isActive", "refreshToken", "avatarUrl", "createdAt", "updatedAt")
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)`,
        [
          newId,
          user.fullName,
          String(user.email || '').toLowerCase(),
          user.phone,
          user.passwordHash,
          user.role,
          user.isActive ?? true,
          user.refreshToken ?? null,
          user.avatarUrl ?? null,
          user.createdAt ? new Date(user.createdAt) : new Date(),
          user.updatedAt ? new Date(user.updatedAt) : new Date(),
        ],
      );
    }

    for (const route of routes) {
      const newId = randomUUID();
      routeIdMap.set(getId(route._id), newId);

      await insertRow(
        postgresClient,
        `INSERT INTO routes (id, origin, destination, "distanceKm", "durationMin", "basePrice", "isActive", "createdAt", "updatedAt")
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
        [
          newId,
          route.origin,
          route.destination,
          route.distanceKm,
          route.durationMin,
          route.basePrice,
          route.isActive ?? true,
          route.createdAt ? new Date(route.createdAt) : new Date(),
          route.updatedAt ? new Date(route.updatedAt) : new Date(),
        ],
      );
    }

    for (const bus of buses) {
      await insertRow(
        postgresClient,
        `INSERT INTO buses (id, label, "plateNumber", capacity, "companyName", "isActive", "createdAt", "updatedAt")
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
        [
          randomUUID(),
          bus.label,
          bus.plateNumber,
          bus.capacity,
          bus.companyName,
          bus.isActive ?? true,
          bus.createdAt ? new Date(bus.createdAt) : new Date(),
          bus.updatedAt ? new Date(bus.updatedAt) : new Date(),
        ],
      );
    }

    for (const schedule of schedules) {
      const newId = randomUUID();
      scheduleIdMap.set(getId(schedule._id), newId);

      const routeId = routeIdMap.get(getId(schedule.routeId));
      if (!routeId) {
        throw new Error(`Missing route mapping for schedule ${getId(schedule._id)}`);
      }

      const agentId = schedule.agentId
        ? await ensureUserMapping(postgresClient, userIdMap, schedule.agentId, {
            role: 'AGENT',
            fullName: 'Legacy agent',
          })
        : null;

      await insertRow(
        postgresClient,
        `INSERT INTO schedules (id, "routeId", "busLabel", "agentId", "departureTime", "arrivalTime", "availableSeats", "totalSeats", status, price, "createdAt", "updatedAt")
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)`,
        [
          newId,
          routeId,
          schedule.busLabel,
          agentId,
          schedule.departureTime ? new Date(schedule.departureTime) : new Date(),
          schedule.arrivalTime ? new Date(schedule.arrivalTime) : new Date(),
          schedule.availableSeats,
          schedule.totalSeats,
          schedule.status || 'SCHEDULED',
          schedule.price,
          schedule.createdAt ? new Date(schedule.createdAt) : new Date(),
          schedule.updatedAt ? new Date(schedule.updatedAt) : new Date(),
        ],
      );
    }

    for (const booking of bookings) {
      const passengerId = await ensureUserMapping(postgresClient, userIdMap, booking.passengerId, {
        role: 'PASSENGER',
        fullName: 'Legacy passenger',
      });
      const scheduleId = scheduleIdMap.get(getId(booking.scheduleId));

      if (!passengerId || !scheduleId) {
        throw new Error(`Missing relation mapping for booking ${getId(booking._id)}`);
      }

      await insertRow(
        postgresClient,
        `INSERT INTO bookings (id, "passengerId", "scheduleId", "bookingCode", "seatNumber", amount, "paymentStatus", "qrData", "qrImageBase64", "validatedAt", "createdAt", "updatedAt")
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)`,
        [
          randomUUID(),
          passengerId,
          scheduleId,
          booking.bookingCode,
          booking.seatNumber,
          booking.amount,
          booking.paymentStatus || 'PAID',
          booking.qrData,
          booking.qrImageBase64,
          booking.validatedAt ? new Date(booking.validatedAt) : null,
          booking.createdAt ? new Date(booking.createdAt) : new Date(),
          booking.updatedAt ? new Date(booking.updatedAt) : new Date(),
        ],
      );
    }

    for (const message of chatMessages) {
      const userId = await ensureUserMapping(postgresClient, userIdMap, message.userId, {
        role: 'PASSENGER',
        fullName: 'Legacy chat user',
      });

      await insertRow(
        postgresClient,
        `INSERT INTO chat_messages (id, "userId", "userName", message, "senderType", "isResolved", "resolvedAt", category, "createdAt", "updatedAt")
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)`,
        [
          randomUUID(),
          userId,
          message.userName,
          message.message,
          message.senderType || 'PASSENGER',
          message.isResolved ?? false,
          message.resolvedAt ? new Date(message.resolvedAt) : null,
          message.category ?? null,
          message.createdAt ? new Date(message.createdAt) : new Date(),
          message.updatedAt ? new Date(message.updatedAt) : new Date(),
        ],
      );
    }

    await postgresClient.query('COMMIT');

    console.log(`Migrated ${users.length} users, ${routes.length} routes, ${buses.length} buses, ${schedules.length} schedules, ${bookings.length} bookings, ${chatMessages.length} chat messages.`);
  } catch (error) {
    await postgresClient.query('ROLLBACK');
    throw error;
  } finally {
    await mongoClient.close();
    await postgresClient.end();
  }
}

main().catch((error) => {
  console.error('MongoDB to PostgreSQL migration failed');
  console.error(error);
  process.exit(1);
});
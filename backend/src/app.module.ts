import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { RoutesModule } from './routes/routes.module';
import { SchedulesModule } from './schedules/schedules.module';
import { BookingsModule } from './bookings/bookings.module';
import { DashboardModule } from './dashboard/dashboard.module';
import { HealthModule } from './health/health.module';
import { BusesModule } from './buses/buses.module';
import { ChatModule } from './chatbot/chat.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        type: 'postgres',
        url: config.get<string>('DATABASE_URL') || undefined,
        host: config.get<string>('DB_HOST') || 'localhost',
        port: Number(config.get<string>('DB_PORT') || 5432),
        username: config.get<string>('DB_USERNAME') || 'postgres',
        password: config.get<string>('DB_PASSWORD') || 'postgres',
        database: config.get<string>('DB_DATABASE') || 'fasotransport',
        synchronize: config.get<string>('DB_SYNCHRONIZE') !== 'false',
        logging: config.get<string>('DB_LOGGING') === 'true',
        ssl:
          config.get<string>('DB_SSL') === 'true'
            ? { rejectUnauthorized: false }
            : false,
        autoLoadEntities: true,
      }),
    }),
    UsersModule,
    AuthModule,
    RoutesModule,
    SchedulesModule,
    BookingsModule,
    DashboardModule,
    HealthModule,
    BusesModule,
    ChatModule,
  ],
})
export class AppModule {}

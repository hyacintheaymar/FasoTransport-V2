import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { BookingEntity } from '../bookings/booking.schema';
import { DashboardService } from './dashboard.service';
import { DashboardController } from './dashboard.controller';

@Module({
  imports: [TypeOrmModule.forFeature([BookingEntity])],
  providers: [DashboardService],
  controllers: [DashboardController],
})
export class DashboardModule {}

import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { BookingEntity } from './booking.schema';
import { BookingsService } from './bookings.service';
import { BookingsController } from './bookings.controller';
import { SchedulesModule } from '../schedules/schedules.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([BookingEntity]),
    SchedulesModule,
  ],
  providers: [BookingsService],
  controllers: [BookingsController],
})
export class BookingsModule {}

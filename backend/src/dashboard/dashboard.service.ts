import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { BookingEntity } from '../bookings/booking.schema';

@Injectable()
export class DashboardService {
  constructor(@InjectRepository(BookingEntity) private readonly bookingRepository: Repository<BookingEntity>) {}

  async getOverview() {
    const totalBookings = await this.bookingRepository.count();
    const result = await this.bookingRepository
      .createQueryBuilder('booking')
      .select('COALESCE(SUM(booking.amount), 0)', 'totalRevenue')
      .getRawOne<{ totalRevenue: string }>();

    const totalRevenue = Number(result?.totalRevenue || 0);

    return {
      totalBookings,
      totalRevenue,
      currency: 'XOF',
    };
  }
}

import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as QRCode from 'qrcode';
import { BookingEntity } from './booking.schema';
import { SchedulesService } from '../schedules/schedules.service';
import { CreateBookingDto } from './dto/create-booking.dto';

@Injectable()
export class BookingsService {
  constructor(
    @InjectRepository(BookingEntity) private readonly bookingRepository: Repository<BookingEntity>,
    private readonly schedulesService: SchedulesService,
  ) {}

  async create(passengerId: string, dto: CreateBookingDto) {
    const schedule = await this.schedulesService.decreaseSeat(dto.scheduleId);

    const bookingCode = `FT-${Date.now()}-${Math.floor(Math.random() * 1000)}`;
    const seatNumber = dto.seatNumber;
    const qrData = JSON.stringify({ bookingCode, passengerId, scheduleId: dto.scheduleId });
    const qrImageBase64 = await QRCode.toDataURL(qrData);

    return this.bookingRepository.save(this.bookingRepository.create({
      passenger: { id: passengerId } as any,
      schedule: { id: dto.scheduleId } as any,
      bookingCode,
      seatNumber,
      amount: schedule.price,
      paymentStatus: 'PAID',
      qrData,
      qrImageBase64,
    }));
  }

  findMine(passengerId: string) {
    return this.bookingRepository.find({
      where: { passenger: { id: passengerId } as any },
      order: { createdAt: 'DESC' },
    });
  }

  findAll() {
    return this.bookingRepository.find({ order: { createdAt: 'DESC' } });
  }

  async validateQr(qrData: string) {
    const booking = await this.bookingRepository.findOne({ where: { qrData } });
    if (!booking) {
      return { valid: false, message: 'QR invalide' };
    }

    if (booking.validatedAt) {
      return {
        valid: false,
        message: 'Billet deja valide',
        booking,
      };
    }

    booking.validatedAt = new Date();
    await this.bookingRepository.save(booking);

    return {
      valid: true,
      message: 'Billet valide',
      booking,
    };
  }
}

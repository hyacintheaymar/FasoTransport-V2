import { Body, Controller, Get, Post, Req, UseGuards } from '@nestjs/common';
import { Request } from 'express';
import { BookingsService } from './bookings.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Role } from '../common/enums/role.enum';
import { Roles } from '../common/decorators/roles.decorator';
import { CreateBookingDto } from './dto/create-booking.dto';

@Controller('bookings')
@UseGuards(JwtAuthGuard)
export class BookingsController {
  constructor(private readonly bookingsService: BookingsService) {}

  @Post()
  @UseGuards(RolesGuard)
  @Roles(Role.PASSENGER)
  create(@Req() req: Request, @Body() dto: CreateBookingDto) {
    const user = req.user as { userId: string };
    return this.bookingsService.create(user.userId, dto);
  }

  @Get('mine')
  @UseGuards(RolesGuard)
  @Roles(Role.PASSENGER)
  findMine(@Req() req: Request) {
    const user = req.user as { userId: string };
    return this.bookingsService.findMine(user.userId);
  }

  @Post('validate-qr')
  @UseGuards(RolesGuard)
  @Roles(Role.AGENT, Role.ADMIN)
  validateQr(@Body() payload: { qrData: string }) {
    return this.bookingsService.validateQr(payload.qrData);
  }

  @Get()
  @UseGuards(RolesGuard)
  @Roles(Role.ADMIN)
  findAll() {
    return this.bookingsService.findAll();
  }
}

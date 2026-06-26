import { Body, Controller, Get, Post, UseGuards, Delete, Param } from '@nestjs/common';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { Role } from '../common/enums/role.enum';
import { BusesService } from './buses.service';
import { CreateBusDto } from './dto/create-bus.dto';

@Controller('buses')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(Role.ADMIN)
export class BusesController {
  constructor(private readonly busesService: BusesService) {}

  @Get()
  findAll() {
    return this.busesService.findAll();
  }

  @Post()
  create(@Body() dto: CreateBusDto) {
    return this.busesService.create(dto);
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    return this.busesService.remove(id);
  }
}

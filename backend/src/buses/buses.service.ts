import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { BusEntity } from './bus.schema';
import { CreateBusDto } from './dto/create-bus.dto';

@Injectable()
export class BusesService {
  constructor(@InjectRepository(BusEntity) private readonly busRepository: Repository<BusEntity>) {}

  create(dto: CreateBusDto) {
    const bus = this.busRepository.create(dto);
    return this.busRepository.save(bus);
  }

  findAll() {
    return this.busRepository.find({ order: { createdAt: 'DESC' } });
  }

  async remove(id: string) {
    try {
      const result = await this.busRepository.delete(id);
      if (result.affected === 0) {
        throw new NotFoundException('Bus introuvable');
      }
      return { success: true };
    } catch (error: any) {
      if (error.code === '23503') {
        throw new BadRequestException('Impossible de supprimer ce bus car il est utilisé par des horaires.');
      }
      throw error;
    }
  }
}

import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { RouteEntity } from './route.schema';
import { CreateRouteDto } from './dto/create-route.dto';

@Injectable()
export class RoutesService {
  constructor(@InjectRepository(RouteEntity) private readonly routeRepository: Repository<RouteEntity>) {}

  create(dto: CreateRouteDto) {
    const route = this.routeRepository.create(dto);
    return this.routeRepository.save(route);
  }

  findAll() {
    return this.routeRepository.find({ order: { createdAt: 'DESC' } });
  }

  async remove(id: string) {
    try {
      const result = await this.routeRepository.delete(id);
      if (result.affected === 0) {
        throw new NotFoundException('Route introuvable');
      }
      return { success: true };
    } catch (error: any) {
      if (error.code === '23503') { // Postgres foreign key violation
        throw new BadRequestException('Impossible de supprimer cette route car elle est utilisée par des horaires.');
      }
      throw error;
    }
  }
}

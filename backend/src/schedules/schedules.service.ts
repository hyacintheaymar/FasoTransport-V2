import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ScheduleEntity } from './schedule.schema';
import { CreateScheduleDto } from './dto/create-schedule.dto';

@Injectable()
export class SchedulesService {
  constructor(@InjectRepository(ScheduleEntity) private readonly scheduleRepository: Repository<ScheduleEntity>) {}

  create(dto: CreateScheduleDto) {
    const schedule = this.scheduleRepository.create({
      busLabel: dto.busLabel,
      route: { id: dto.routeId } as any,
      agent: dto.agentId ? ({ id: dto.agentId } as any) : null,
      departureTime: new Date(dto.departureTime),
      arrivalTime: new Date(dto.arrivalTime),
      availableSeats: dto.availableSeats,
      totalSeats: dto.totalSeats,
      price: dto.price,
    });

    return this.scheduleRepository.save(schedule);
  }

  findAll() {
    return this.scheduleRepository.find({
      relations: {
        route: true,
        agent: true,
      },
      order: { departureTime: 'ASC' },
    }).then((schedules) =>
      schedules.map((schedule) => ({
        ...schedule,
        origin: schedule.route?.origin,
        destination: schedule.route?.destination,
        distanceKm: schedule.route?.distanceKm,
        durationMin: schedule.route?.durationMin,
        basePrice: schedule.route?.basePrice,
        agentName: schedule.agent ? schedule.agent.fullName : null,
        agentEmail: schedule.agent ? schedule.agent.email : null,
      })),
    );
  }


  async decreaseSeat(scheduleId: string) {
    const schedule = await this.scheduleRepository.findOne({ where: { id: scheduleId } });
    if (!schedule) {
      throw new NotFoundException('Horaire introuvable');
    }

    if (schedule.availableSeats <= 0) {
      throw new NotFoundException('Plus de places disponibles');
    }

    schedule.availableSeats -= 1;
    await this.scheduleRepository.save(schedule);

    return schedule;
  }

  async remove(id: string) {
    try {
      const result = await this.scheduleRepository.delete(id);
      if (result.affected === 0) {
        throw new NotFoundException('Horaire introuvable');
      }
      return { success: true };
    } catch (error: any) {
      throw error;
    }
  }
}

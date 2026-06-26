import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from './user.schema';
import { Role } from '../common/enums/role.enum';

@Injectable()
export class UsersService {
  constructor(@InjectRepository(User) private readonly userRepository: Repository<User>) {}

  findByEmail(email: string) {
    return this.userRepository.findOne({ where: { email: email.toLowerCase() } });
  }

  findById(id: string) {
    return this.userRepository.findOne({ where: { id } });
  }

  async updateRefreshToken(userId: string, refreshTokenHash: string | null) {
    await this.userRepository.update({ id: userId }, { refreshToken: refreshTokenHash });
  }

  create(payload: Partial<User>) {
    const user = this.userRepository.create({
      ...payload,
      email: payload.email?.toLowerCase(),
    });

    return this.userRepository.save(user);
  }

  findAgents() {
    return this.userRepository.find({
      where: { role: Role.AGENT, isActive: true },
      select: {
        id: true,
        fullName: true,
        email: true,
        phone: true,
        role: true,
        isActive: true,
        avatarUrl: true,
      },
      order: { fullName: 'ASC' },
    });
  }

  updateAvatar(userId: string, avatarUrl: string | null) {
    return this.userRepository
      .update({ id: userId }, { avatarUrl: avatarUrl || null })
      .then(() => this.findById(userId));
  }
}

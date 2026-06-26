import { Injectable, UnauthorizedException, ConflictException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcryptjs';
import { UsersService } from '../users/users.service';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';
import { RefreshTokenDto } from './dto/refresh-token.dto';

@Injectable()
export class AuthService {
  constructor(
    private readonly usersService: UsersService,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
  ) {}

  async register(dto: RegisterDto) {
    const existing = await this.usersService.findByEmail(dto.email);
    if (existing) {
      throw new ConflictException('Email deja utilise');
    }

    const passwordHash = await bcrypt.hash(dto.password, 10);
    const user = await this.usersService.create({
      fullName: dto.fullName,
      email: dto.email,
      phone: dto.phone,
      passwordHash,
      role: dto.role,
      isActive: true,
    });

    return this.buildAuthResponse(user);
  }

  async login(dto: LoginDto) {
    const user = await this.usersService.findByEmail(dto.email);
    if (!user || !user.isActive) {
      throw new UnauthorizedException('Identifiants invalides');
    }

    const ok = await bcrypt.compare(dto.password, user.passwordHash);
    if (!ok) {
      throw new UnauthorizedException('Identifiants invalides');
    }

    return this.buildAuthResponse(user);
  }

  async refresh(dto: RefreshTokenDto) {
    const secret = this.configService.get<string>('JWT_REFRESH_SECRET') || 'change-me-refresh';

    let payload: { sub: string; email: string; role: string };
    try {
      payload = await this.jwtService.verifyAsync(dto.refreshToken, { secret });
    } catch {
      throw new UnauthorizedException('Refresh token invalide');
    }

    const user = await this.usersService.findById(payload.sub);
    if (!user || !user.isActive || !user.refreshToken) {
      throw new UnauthorizedException('Session invalide');
    }

    const matches = await bcrypt.compare(dto.refreshToken, user.refreshToken);
    if (!matches) {
      throw new UnauthorizedException('Session invalide');
    }

    return this.buildAuthResponse(user);
  }

  async logout(userId: string) {
    await this.usersService.updateRefreshToken(userId, null);
    return { success: true };
  }

  async me(userId: string) {
    const user = await this.usersService.findById(userId);
    if (!user || !user.isActive) {
      throw new UnauthorizedException('Utilisateur invalide');
    }

    return {
      id: user.id,
      fullName: user.fullName,
      email: user.email,
      phone: user.phone,
      role: user.role,
      isActive: user.isActive,
      avatarUrl: user.avatarUrl,
      createdAt: user.createdAt,
    };
  }

  async updateMyAvatar(userId: string, avatarUrl: string | null) {
    const user = await this.usersService.updateAvatar(userId, avatarUrl);
    if (!user || !user.isActive) {
      throw new UnauthorizedException('Utilisateur invalide');
    }

    return {
      id: user.id,
      fullName: user.fullName,
      email: user.email,
      phone: user.phone,
      role: user.role,
      isActive: user.isActive,
      avatarUrl: user.avatarUrl,
      createdAt: user.createdAt,
    };
  }

  private async buildAuthResponse(user: {
    id?: string;
    _id?: { toString(): string } | string;
    email: string;
    role: string;
    fullName: string;
    avatarUrl?: string | null;
  }) {
    const userId = user.id ?? user._id?.toString();
    if (!userId) {
      throw new UnauthorizedException('Utilisateur invalide');
    }

    const accessToken = this.jwtService.sign({ sub: userId, email: user.email, role: user.role });
    const refreshToken = this.jwtService.sign(
      { sub: userId, email: user.email, role: user.role },
      {
        secret: this.configService.get<string>('JWT_REFRESH_SECRET') || 'change-me-refresh',
        expiresIn: this.configService.get<string>('JWT_REFRESH_EXPIRES_IN') || '7d',
      },
    );

    const refreshTokenHash = await bcrypt.hash(refreshToken, 10);
    await this.usersService.updateRefreshToken(userId, refreshTokenHash);

    return {
      accessToken,
      refreshToken,
      user: {
        id: userId,
        email: user.email,
        role: user.role,
        fullName: user.fullName,
        avatarUrl: user.avatarUrl ?? undefined,
      },
    };
  }
}

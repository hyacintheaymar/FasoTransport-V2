import { IsOptional, IsString, MaxLength } from 'class-validator';

export class UpdateAvatarDto {
  @IsOptional()
  @IsString()
  @MaxLength(3000000)
  avatarUrl?: string;
}

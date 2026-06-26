import { IsBoolean, IsNotEmpty, IsNumber, IsOptional, IsString, Min } from 'class-validator';

export class CreateRouteDto {
  @IsString()
  @IsNotEmpty()
  origin: string;

  @IsString()
  @IsNotEmpty()
  destination: string;

  @IsNumber()
  @Min(1)
  distanceKm: number;

  @IsNumber()
  @Min(1)
  durationMin: number;

  @IsNumber()
  @Min(1)
  basePrice: number;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

import { IsDateString, IsNotEmpty, IsNumber, IsOptional, IsString, IsUUID, Min } from 'class-validator';

export class CreateScheduleDto {
  @IsUUID()
  routeId: string;

  @IsString()
  @IsNotEmpty()
  busLabel: string;

  @IsOptional()
  @IsUUID()
  agentId?: string;

  @IsDateString()
  departureTime: string;

  @IsDateString()
  arrivalTime: string;

  @IsNumber()
  @Min(1)
  availableSeats: number;

  @IsNumber()
  @Min(1)
  totalSeats: number;

  @IsNumber()
  @Min(1)
  price: number;
}

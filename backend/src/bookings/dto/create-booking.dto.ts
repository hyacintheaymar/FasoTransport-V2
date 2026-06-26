import { IsNumber, Min, Max, IsUUID } from 'class-validator';

export class CreateBookingDto {
  @IsUUID()
  scheduleId: string;

  @IsNumber()
  @Min(1)
  @Max(41)
  seatNumber: number;
}

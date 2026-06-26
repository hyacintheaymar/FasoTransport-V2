import { IsBoolean, IsNotEmpty, IsNumber, IsOptional, IsString, Min } from 'class-validator';

export class CreateBusDto {
  @IsString()
  @IsNotEmpty()
  label: string;

  @IsString()
  @IsNotEmpty()
  plateNumber: string;

  @IsNumber()
  @Min(1)
  capacity: number;

  @IsString()
  @IsNotEmpty()
  companyName: string;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

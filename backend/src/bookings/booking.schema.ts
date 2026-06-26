import { Column, CreateDateColumn, Entity, JoinColumn, ManyToOne, PrimaryGeneratedColumn, UpdateDateColumn } from 'typeorm';
import { User } from '../users/user.schema';
import { ScheduleEntity } from '../schedules/schedule.schema';

export type PaymentStatus = 'PENDING' | 'PAID' | 'FAILED' | 'CANCELLED';

@Entity({ name: 'bookings' })
export class BookingEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => User, { eager: true, nullable: false, onDelete: 'CASCADE' })
  @JoinColumn({ name: 'passengerId' })
  passenger: User;

  @ManyToOne(() => ScheduleEntity, { eager: true, nullable: false, onDelete: 'CASCADE' })
  @JoinColumn({ name: 'scheduleId' })
  schedule: ScheduleEntity;

  @Column({ unique: true })
  bookingCode: string;

  @Column('int')
  seatNumber: number;

  @Column('int')
  amount: number;

  @Column({ type: 'enum', enum: ['PENDING', 'PAID', 'FAILED', 'CANCELLED'], default: 'PAID' })
  paymentStatus: PaymentStatus;

  @Column('text')
  qrData: string;

  @Column('text')
  qrImageBase64: string;

  @Column({ type: 'timestamptz', nullable: true })
  validatedAt?: Date;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}

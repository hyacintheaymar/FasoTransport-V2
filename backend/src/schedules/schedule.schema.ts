import { Column, CreateDateColumn, Entity, JoinColumn, ManyToOne, PrimaryGeneratedColumn, UpdateDateColumn } from 'typeorm';
import { RouteEntity } from '../routes/route.schema';
import { User } from '../users/user.schema';

export type ScheduleStatus = 'SCHEDULED' | 'DEPARTED' | 'COMPLETED' | 'CANCELLED';

@Entity({ name: 'schedules' })
export class ScheduleEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => RouteEntity, { eager: true, nullable: false, onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'routeId' })
  route: RouteEntity;

  @Column()
  busLabel: string;

  @ManyToOne(() => User, { eager: true, nullable: true, onDelete: 'SET NULL' })
  @JoinColumn({ name: 'agentId' })
  agent?: User | null;

  @Column({ type: 'timestamptz' })
  departureTime: Date;

  @Column({ type: 'timestamptz' })
  arrivalTime: Date;

  @Column('int')
  availableSeats: number;

  @Column('int')
  totalSeats: number;

  @Column({ type: 'enum', enum: ['SCHEDULED', 'DEPARTED', 'COMPLETED', 'CANCELLED'], default: 'SCHEDULED' })
  status: ScheduleStatus;

  @Column('int')
  price: number;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}

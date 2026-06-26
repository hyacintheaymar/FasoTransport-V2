import { Column, CreateDateColumn, Entity, Index, PrimaryGeneratedColumn, UpdateDateColumn } from 'typeorm';
import { Role } from '../common/enums/role.enum';

@Entity({ name: 'users' })
@Index(['email'], { unique: true })
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  fullName: string;

  @Column({ unique: true })
  email: string;

  @Column()
  phone: string;

  @Column()
  passwordHash: string;

  @Column({ type: 'enum', enum: Role, default: Role.PASSENGER })
  role: Role;

  @Column({ default: true })
  isActive: boolean;

  @Column({ type: 'text', nullable: true })
  refreshToken?: string | null;

  @Column({ type: 'text', nullable: true })
  avatarUrl?: string | null;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}

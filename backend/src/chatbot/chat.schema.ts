import { Column, CreateDateColumn, Entity, JoinColumn, ManyToOne, PrimaryGeneratedColumn, UpdateDateColumn } from 'typeorm';
import { User } from '../users/user.schema';

export type SenderType = 'PASSENGER' | 'SUPPORT';

@Entity({ name: 'chat_messages' })
export class ChatMessageEntity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @ManyToOne(() => User, { eager: true, nullable: false, onDelete: 'CASCADE' })
  @JoinColumn({ name: 'userId' })
  user: User;

  @Column()
  userName: string;

  @Column('text')
  message: string;

  @Column({ type: 'enum', enum: ['PASSENGER', 'SUPPORT'], default: 'PASSENGER' })
  senderType: SenderType;

  @Column({ default: false })
  isResolved: boolean;

  @Column({ type: 'timestamptz', nullable: true })
  resolvedAt?: Date;

  @Column({ type: 'text', nullable: true })
  category?: string | null;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}

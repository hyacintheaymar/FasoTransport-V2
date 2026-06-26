import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ChatMessageEntity } from './chat.schema';
import { ChatService } from './chat.service';
import { ChatController } from './chat.controller';
import { AiService } from './ai.service';
import { SchedulesModule } from '../schedules/schedules.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([ChatMessageEntity]),
    SchedulesModule,
  ],
  providers: [ChatService, AiService],
  controllers: [ChatController],
  exports: [ChatService],
})
export class ChatModule { }
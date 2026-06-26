import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ChatMessageEntity } from './chat.schema';
import { AiService } from './ai.service';
import { SchedulesService } from '../schedules/schedules.service';

@Injectable()
export class ChatService {
  constructor(
    @InjectRepository(ChatMessageEntity)
    private chatRepository: Repository<ChatMessageEntity>,
    private aiService: AiService,
    private schedulesService: SchedulesService,
  ) {}

  async sendMessage(
    userId: string,
    userName: string,
    message: string,
    category?: string,
  ): Promise<{ passengerMessage: ChatMessageEntity; supportMessage: ChatMessageEntity }> {
    const passengerMessage = this.chatRepository.create({
      user: { id: userId } as any,
      userName,
      message,
      category,
      senderType: 'PASSENGER',
    });

    const savedPassengerMessage = await this.chatRepository.save(passengerMessage);

    // Fetch conversation history for context
    const history = await this.chatRepository.find({
      where: { user: { id: userId } as any },
      order: { createdAt: 'ASC' },
      take: 10,
    });

    const historyForAi = history.map((msg) => ({
      role: msg.senderType,
      content: msg.message,
    }));

    // Fetch schedules to provide context to the AI
    const schedules = await this.schedulesService.findAll();
    const schedulesContext = schedules
      .map(
        (s: any) =>
          `- ${s.origin} vers ${s.destination}: Départ à ${new Date(s.departureTime).toLocaleString('fr-FR')}, Prix: ${s.basePrice} FCFA, Places dispo: ${s.availableSeats}`,
      )
      .join('\n');

    const aiReplyText = await this.aiService.generateResponse(message, historyForAi, schedulesContext);

    const supportMessage = this.chatRepository.create({
      user: { id: userId } as any,
      userName: 'AI Support',
      message: aiReplyText,
      senderType: 'SUPPORT',
      category: 'AI_RESPONSE',
    });

    const savedSupportMessage = await this.chatRepository.save(supportMessage);

    return {
      passengerMessage: savedPassengerMessage,
      supportMessage: savedSupportMessage,
    };
  }

  async getConversation(userId: string): Promise<ChatMessageEntity[]> {
    return this.chatRepository.find({
      where: { user: { id: userId } as any },
      order: { createdAt: 'DESC' },
      take: 50,
    });
  }

  async addSupportReply(
    originalMessageId: string,
    replyText: string,
  ): Promise<ChatMessageEntity | null> {
    const originalMessage = await this.chatRepository.findOne({ where: { id: originalMessageId } });
    if (!originalMessage) {
      return null;
    }

    const newReply = this.chatRepository.create({
      user: originalMessage.user,
      userName: 'Support TransChat',
      message: replyText,
      senderType: 'SUPPORT',
      category: 'SYSTEM_REPLY',
    });
    return this.chatRepository.save(newReply);
  }


  async getAllMessages(limit = 100): Promise<ChatMessageEntity[]> {
    return this.chatRepository.find({ order: { createdAt: 'DESC' }, take: limit });
  }

  async resolveMessage(messageId: string): Promise<ChatMessageEntity | null> {
    const message = await this.chatRepository.findOne({ where: { id: messageId } });
    if (!message) {
      return null;
    }

    message.isResolved = true;
    message.resolvedAt = new Date();
    return this.chatRepository.save(message);
  }
}

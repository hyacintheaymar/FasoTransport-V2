import {
  Controller,
  Post,
  Get,
  Body,
  UseGuards,
  Req,
  Param,
} from '@nestjs/common';
import { Request } from 'express';
import { ChatService } from './chat.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@Controller('chat')
export class ChatController {
  constructor(private readonly chatService: ChatService) {}

  @UseGuards(JwtAuthGuard)
  @Post('send')
  async sendMessage(
    @Req() req: Request & { user: any },
    @Body() body: { message: string; category?: string },
  ) {
    const userId = req.user.userId || req.user.id;
    const userName = req.user.fullName || req.user.email;
    const result = await this.chatService.sendMessage(
      userId,
      userName,
      body.message,
      body.category,
    );
    return { success: true, data: result };
  }

  @UseGuards(JwtAuthGuard)
  @Get('conversation')
  async getConversation(@Req() req: Request & { user: any }) {
    const userId = req.user.userId || req.user.id;
    const messages = await this.chatService.getConversation(userId);
    return { success: true, data: messages };
  }

  @UseGuards(JwtAuthGuard)
  @Get('all')
  async getAllMessages(@Req() req: Request & { user: any }) {
    if (req.user.role !== 'ADMIN') {
      return { success: false, error: 'Forbidden' };
    }
    const messages = await this.chatService.getAllMessages();
    return { success: true, data: messages };
  }

  @Post('reply/:messageId')
  @UseGuards(JwtAuthGuard)
  async addReply(
    @Req() req: Request & { user: any },
    @Param('messageId') messageId: string,
    @Body() body: { reply: string },
  ) {
    if (req.user.role !== 'ADMIN') {
      return { success: false, error: 'Forbidden' };
    }
    const result = await this.chatService.addSupportReply(messageId, body.reply);
    return { success: true, data: result };
  }
}

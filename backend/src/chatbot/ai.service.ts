import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { GoogleGenerativeAI } from '@google/generative-ai';

@Injectable()
export class AiService {
  private readonly logger = new Logger(AiService.name);
  private genAI: GoogleGenerativeAI | null = null;
  private model: any = null;

  constructor(private configService: ConfigService) {
    const apiKey = this.configService.get<string>('GEMINI_API_KEY');
    if (apiKey) {
      this.genAI = new GoogleGenerativeAI(apiKey);
      this.model = this.genAI.getGenerativeModel({
        model: 'gemini-2.0-flash',
        systemInstruction: `
          Tu es l'assistant de support intelligent de FasoTransport.
          Ton role est d'aider les voyageurs avec leurs preoccupations
          concernant les horaires, les tarifs, les reservations et les problemes techniques.
          Reponds principalement en francais. Sois poli et professionnel.
        `,
      });
    } else {
      this.logger.warn('GEMINI_API_KEY is not defined. AI Chat will not work.');
    }
  }

  async generateResponse(
    userMessage: string,
    history: { role: string; content: string }[] = [],
    context: string = '',
  ): Promise<string> {
    if (!this.model) {
      return "L'assistant IA n'est pas disponible pour le moment.";
    }
    try {
      const fullMessage = context
        ? `Informations disponibles :\n${context}\n\nQuestion : ${userMessage}`
        : userMessage;

      const chat = this.model.startChat({
        history: history.map((h) => ({
          role: h.role === 'PASSENGER' ? 'user' : 'model',
          parts: [{ text: h.content }],
        })),
      });

      const result = await chat.sendMessage(fullMessage);
      const response = await result.response;
      return response.text();
    } catch (error) {
      this.logger.error('Error generating AI response:', error);
      return "Une erreur s'est produite. Veuillez reessayer.";
    }
  }
}
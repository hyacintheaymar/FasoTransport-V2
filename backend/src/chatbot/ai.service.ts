import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { GoogleGenerativeAI } from '@google/generative-ai';

@Injectable()
export class AiService {
  private readonly logger = new Logger(AiService.name);
  private genAI: GoogleGenerativeAI | null = null;
  private model: any = null;

  constructor(private configService: ConfigService) {
    const apiKey = this.configService.get<string>('GOOGLE_API_KEY');
    if (apiKey) {
      this.genAI = new GoogleGenerativeAI(apiKey);
      this.model = this.genAI.getGenerativeModel({
        model: 'gemini-2.0-flash',
        systemInstruction: `
          Tu es l'assistant de support intelligent de FasoTransport, une plateforme de gestion de transport de bus au Burkina Faso.
          Ton rôle est d'aider les voyageurs avec leurs préoccupations concernant les horaires, les tarifs, les réservations et les problèmes techniques.
          
          Directives :
          1. Sois toujours poli, professionnel et aidant.
          2. Réponds principalement en français.
          3. Utilise les informations de contexte fournies (horaires, trajets) pour répondre précisément. 
          4. Si une information n'est pas dans le contexte, dis-le poliment et suggère de contacter le support humain.
          5. Garde tes réponses concises et pertinentes.
          
          Contexte de l'entreprise :
          - Nom : FasoTransport
          - Services : Réservation de tickets de bus, consultation d'horaires en temps réel.
        `,
      });
    } else {
      this.logger.warn('GOOGLE_API_KEY is not defined. AI Chat will not work.');
    }
  }

  async generateResponse(userMessage: string, history: { role: string; content: string }[] = [], context: string = ''): Promise<string> {
    if (!this.model) {
      return this.buildFallbackResponse(context);
    }

    try {
      const fullMessage = context ? `Voici les informations actuelles sur les horaires et trajets :\n${context}\n\nQuestion de l'utilisateur : ${userMessage}` : userMessage;

      const chat = this.model.startChat({
        history: history.map(h => ({
          role: h.role === 'PASSENGER' ? 'user' : 'model',
          parts: [{ text: h.content }],
        })),
      });

      const result = await chat.sendMessage(fullMessage);
      const response = await result.response;
      return response.text();
    } catch (error) {
      this.logger.error('Error generating AI response:', error);
      return this.buildFallbackResponse(context);
    }
  }

  private buildFallbackResponse(context: string): string {
    const lines = context
      .split('\n')
      .map((line) => line.trim())
      .filter((line) => line.startsWith('- '))
      .slice(0, 3);

    if (lines.length === 0) {
      return "Je n'arrive pas à joindre l'assistant IA pour le moment. Un agent humain peut vous aider, ou vous pouvez essayer de préciser la ville de départ, la destination ou l'horaire souhaité.";
    }

    return `Je n'arrive pas à joindre l'assistant IA pour le moment, mais voici quelques trajets disponibles :\n${lines.join('\n')}\n\nSi vous voulez, je peux aussi vous aider à chercher un trajet précis.`;
  }
}

'use client';

import { useState, useEffect } from 'react';
import { MessageCircle, Send, X, Minimize2, Maximize2 } from 'lucide-react';
import { apiGet, apiPost } from '../lib/api';
import { getAdminToken } from '../lib/auth';

interface ChatMessage {
  _id?: string;
  message: string;
  userName: string;
  senderType: 'PASSENGER' | 'SUPPORT';
  createdAt?: string;
}

export default function TransChat() {
  const [mounted, setMounted] = useState(false);
  const [hasToken, setHasToken] = useState(false);
  const [isOpen, setIsOpen] = useState(false);
  const [isMinimized, setIsMinimized] = useState(false);
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [inputMessage, setInputMessage] = useState('');
  const [loading, setLoading] = useState(false);
  const [category, setCategory] = useState('GENERAL');

  useEffect(() => {
    setMounted(true);
    setHasToken(Boolean(getAdminToken()));
  }, []);

  useEffect(() => {
    if (isOpen) {
      loadConversation();
    }
  }, [isOpen]);

  const loadConversation = async () => {
    try {
      const token = getAdminToken();
      if (!token) return;
      
      const response = await apiGet('/chat/conversation', token);
      if (response.success) {
        setMessages(response.data.reverse());
      }
    } catch (error) {
      console.error('Failed to load conversation:', error);
    }
  };

  const sendMessage = async () => {
    if (!inputMessage.trim()) return;

    const token = getAdminToken();
    if (!token) {
      console.error('No token found');
      return;
    }

    const newMessage: ChatMessage = {
      message: inputMessage,
      userName: 'Vous',
      senderType: 'PASSENGER',
    };

    setMessages((prev) => [...prev, newMessage]);
    setInputMessage('');
    setLoading(true);

    try {
      const response = await apiPost(
        '/chat/send',
        { message: inputMessage, category },
        token,
      );
      if (!response.success) {
        console.error('Failed to send message:', response);
      } else {
        await loadConversation();
      }
    } catch (error) {
      console.error('Failed to send message:', error);
    } finally {
      setLoading(false);
    }
  };

  if (!mounted || !hasToken) {
    return null;
  }

  return (
    <div className="fixed bottom-4 right-4 z-50">
      {/* Chat Toggle Button */}
      {!isOpen && (
        <button
          onClick={() => setIsOpen(true)}
          className="w-14 h-14 rounded-full bg-brand-orange shadow-lg hover:bg-orange-600 transition-colors flex items-center justify-center text-white"
          title="Ouvrir TransChat"
        >
          <MessageCircle size={24} />
        </button>
      )}

      {/* Chat Window */}
      {isOpen && (
        <div
          className={`bg-white rounded-lg shadow-2xl border border-gray-200 flex flex-col transition-all ${
            isMinimized ? 'w-80 h-16' : 'w-80 h-96'
          }`}
        >
          {/* Header */}
          <div className="bg-gradient-to-r from-brand-orange to-orange-600 text-white px-4 py-3 rounded-t-lg flex justify-between items-center">
            <div className="flex items-center gap-2">
              <MessageCircle size={20} />
              <span className="font-semibold">TransChat</span>
            </div>
            <div className="flex gap-2">
              <button
                onClick={() => setIsMinimized(!isMinimized)}
                className="hover:bg-orange-700 p-1 rounded transition-colors"
              >
                {isMinimized ? <Maximize2 size={16} /> : <Minimize2 size={16} />}
              </button>
              <button
                onClick={() => setIsOpen(false)}
                className="hover:bg-orange-700 p-1 rounded transition-colors"
              >
                <X size={16} />
              </button>
            </div>
          </div>

          {!isMinimized && (
            <>
              {/* Messages Area */}
              <div className="flex-1 overflow-y-auto p-3 bg-gray-50 space-y-3">
                {messages.length === 0 ? (
                  <div className="text-center text-gray-500 text-sm py-8">
                    <p className="font-semibold mb-2">Bienvenue sur TransChat 👋</p>
                    <p>Posez vos questions sur vos trajets, réservations ou services</p>
                  </div>
                ) : (
                  messages.map((msg, idx) => (
                    <div
                      key={idx}
                      className={`flex ${
                        msg.senderType === 'PASSENGER' ? 'justify-end' : 'justify-start'
                      }`}
                    >
                      <div
                        className={`max-w-xs rounded-lg px-3 py-2 text-sm ${
                          msg.senderType === 'PASSENGER'
                            ? 'bg-brand-orange text-white rounded-br-none'
                            : 'bg-gray-300 text-gray-900 rounded-bl-none'
                        }`}
                      >
                        <p className="text-xs font-semibold opacity-75 mb-1">
                          {msg.userName}
                        </p>
                        <p>{msg.message}</p>
                      </div>
                    </div>
                  ))
                )}
              </div>

              {/* Category Selector */}
              <div className="px-3 py-2 border-t">
                <select
                  value={category}
                  onChange={(e) => setCategory(e.target.value)}
                  className="w-full text-xs px-2 py-1 border rounded bg-white"
                >
                  <option value="GENERAL">Général</option>
                  <option value="BOOKING">Réservation</option>
                  <option value="TECHNICAL">Technique</option>
                  <option value="COMPLAINT">Réclamation</option>
                  <option value="OTHER">Autre</option>
                </select>
              </div>

              {/* Input Area */}
              <div className="border-t p-3 bg-white rounded-b-lg">
                <div className="flex gap-2">
                  <input
                    type="text"
                    value={inputMessage}
                    onChange={(e) => setInputMessage(e.target.value)}
                    onKeyPress={(e) => e.key === 'Enter' && !loading && sendMessage()}
                    placeholder="Votre message..."
                    disabled={loading}
                    className="flex-1 text-sm px-3 py-2 border rounded focus:outline-none focus:ring-2 focus:ring-brand-orange disabled:opacity-50"
                  />
                  <button
                    onClick={sendMessage}
                    disabled={loading || !inputMessage.trim()}
                    className="bg-brand-orange text-white px-3 py-2 rounded hover:bg-orange-600 disabled:opacity-50 transition-colors"
                  >
                    <Send size={16} />
                  </button>
                </div>
              </div>
            </>
          )}
        </div>
      )}
    </div>
  );
}

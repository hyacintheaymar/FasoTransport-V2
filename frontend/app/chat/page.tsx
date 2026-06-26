'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { authGet, authPost } from '../../lib/api';
import { getAdminToken } from '../../lib/auth';
import DashboardLayout from '../../components/DashboardLayout';
import { MessageSquare, CheckCircle } from 'lucide-react';

interface ChatMessage {
  _id: string;
  message: string;
  userName: string;
  senderType: 'PASSENGER' | 'SUPPORT';
  isResolved: boolean;
  category?: string;
  createdAt: string;
}

export default function ChatAdminPage() {
  const router = useRouter();
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedMessage, setSelectedMessage] = useState<ChatMessage | null>(null);
  const [replyText, setReplyText] = useState('');

  const token = getAdminToken();

  useEffect(() => {
    if (!token) {
      router.replace('/login');
      return;
    }
    loadMessages();
  }, [token, router]);

  const loadMessages = async () => {
    try {
      const response = await authGet('/chat/all');
      if (response.success) {
        setMessages(response.data);
      }
    } catch (error) {
      console.error('Failed to load messages:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleReply = async () => {
    if (!selectedMessage || !replyText.trim()) return;

    try {
      const response = await authPost(
        `/chat/reply/${selectedMessage._id}`,
        { reply: replyText },
      );
      if (response.success) {
        setReplyText('');
        setSelectedMessage(null);
        loadMessages();
      }
    } catch (error) {
      console.error('Failed to send reply:', error);
    }
  };

  return (
    <DashboardLayout title="Gestion TransChat">
      {loading ? (
        <div className="text-center py-10">
          <div className="loading mx-auto mb-4" />
          <p>Chargement des messages...</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Messages List */}
          <div className="lg:col-span-2">
            <div className="card">
              <h2 className="flex items-center gap-2 mb-4">
                <MessageSquare size={20} /> Messages ({messages.length})
              </h2>
              {messages.length === 0 ? (
                <p className="text-gray-500 text-center py-8">
                  Aucun message pour le moment
                </p>
              ) : (
                <div className="space-y-2 max-h-96 overflow-y-auto">
                  {messages.map((msg) => (
                    <div
                      key={msg._id}
                      onClick={() => setSelectedMessage(msg)}
                      className={`p-3 rounded-lg border cursor-pointer transition-colors ${
                        selectedMessage?._id === msg._id
                          ? 'bg-brand-orange/10 border-brand-orange'
                          : 'bg-gray-50 border-gray-200 hover:bg-gray-100'
                      }`}
                    >
                      <div className="flex justify-between items-start mb-2">
                        <div>
                          <p className="font-semibold text-sm">{msg.userName}</p>
                          <p className="text-xs text-gray-500">
                            {msg.category && `[${msg.category}]`}
                            {new Date(msg.createdAt).toLocaleString('fr-FR')}
                          </p>
                        </div>
                        {msg.isResolved && (
                          <CheckCircle size={16} className="text-green-500" />
                        )}
                      </div>
                      <p className="text-sm text-gray-700 line-clamp-2">
                        {msg.message}
                      </p>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>

          {/* Detail & Reply */}
          <div>
            {selectedMessage ? (
              <div className="card">
                <h3 className="font-semibold mb-4">Détails du message</h3>
                <div className="space-y-3 mb-4">
                  <div>
                    <label className="label">De</label>
                    <p className="text-sm text-gray-700">{selectedMessage.userName}</p>
                  </div>
                  <div>
                    <label className="label">Catégorie</label>
                    <p className="text-sm text-gray-700">
                      {selectedMessage.category || 'Général'}
                    </p>
                  </div>
                  <div>
                    <label className="label">Date</label>
                    <p className="text-sm text-gray-700">
                      {new Date(selectedMessage.createdAt).toLocaleString('fr-FR')}
                    </p>
                  </div>
                  <div>
                    <label className="label">Message</label>
                    <p className="text-sm bg-gray-50 p-3 rounded">
                      {selectedMessage.message}
                    </p>
                  </div>
                  <div>
                    <label className="label">Statut</label>
                    <span
                      className={`text-xs px-2 py-1 rounded ${
                        selectedMessage.isResolved
                          ? 'bg-green-100 text-green-700'
                          : 'bg-yellow-100 text-yellow-700'
                      }`}
                    >
                      {selectedMessage.isResolved ? 'Résolu' : 'En attente'}
                    </span>
                  </div>
                </div>

                <div>
                  <label className="label">Votre réponse</label>
                  <textarea
                    value={replyText}
                    onChange={(e) => setReplyText(e.target.value)}
                    placeholder="Écrivez votre réponse..."
                    className="input text-sm min-h-20"
                  />
                  <button
                    onClick={handleReply}
                    disabled={!replyText.trim()}
                    className="btn-primary btn-sm mt-3 w-full disabled:opacity-50"
                  >
                    Envoyer la réponse
                  </button>
                </div>
              </div>
            ) : (
              <div className="card text-center py-8">
                <p className="text-gray-500">Sélectionnez un message pour répondre</p>
              </div>
            )}
          </div>
        </div>
      )}
    </DashboardLayout>
  );
}

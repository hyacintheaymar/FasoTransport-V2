const axios = require('axios');

async function testChat() {
  try {
    // Note: This requires the backend to be running.
    // Since we are in a dev environment, we assume the user will run it.
    // This is a template for the user to verify.
    console.log('Testing Chat AI Integration...');
    
    // Simulating a message send
    // In a real test, we would need a JWT token
    console.log('Step 1: Check if AiService is correctly instantiated (Check backend logs)');
    
    console.log('Step 2: Manual verification recommended via the mobile app or Postman.');
    console.log('Endpoint: POST http://localhost:4000/chat/send');
    console.log('Body: { "message": "Quels sont les horaires pour Bobo ?" }');
    
  } catch (error) {
    console.error('Test failed:', error.message);
  }
}

testChat();

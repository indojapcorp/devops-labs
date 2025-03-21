// services/payment/src/index.js
const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const jwt = require('jsonwebtoken');

const app = express();
const PORT = process.env.PORT || 3005;
const JWT_SECRET = process.env.JWT_SECRET || 'your_jwt_secret';
const STRIPE_API_KEY = process.env.STRIPE_API_KEY || 'your_stripe_api_key';

// Mock Stripe integration
// In a real app, you'd use the Stripe SDK
const mockProcessPayment = (amount, paymentMethod) => {
  return new Promise((resolve) => {
    // Simulate processing delay
    setTimeout(() => {
      // Generate random transaction ID
      const transactionId = 'txn_' + Math.random().toString(36).substring(2, 15);
      
      // In a real app, you'd handle different payment methods differently
      const status = Math.random() > 0.1 ? 'completed' : 'failed';
      
      resolve({
        transactionId,
        status,
        amount,
        paymentMethod
      });
    }, 500);
  });
};

// Middleware
app.use(cors());
app.use(express.json());
app.use(morgan('combined'));

// Authentication middleware
const authenticate = (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'Authentication required' });
    }
    
    const token = authHeader.split(' ')[1];
    const decoded = jwt.verify(token, JWT_SECRET);
    
    req.user = decoded;
    next();
  } catch (error) {
    res.status(401).json({ error: 'Invalid token' });
  }
};

// Routes
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'OK' });
});

// Process payment
app.post('/process', authenticate, async (req, res) => {
  try {
    const { orderId, amount, paymentMethod } = req.body;
    
    // Process payment
    const paymentResult = await mockProcessPayment(amount, paymentMethod);
    
    // In a real app, you'd store payment details in a database
    
    res.json({
      orderId,
      ...paymentResult
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get payment status
app.get('/:transactionId', authenticate, (req, res) => {
  // In a real app, you'd fetch payment details from a database
  // For this example, we'll return a mock response
  res.json({
    transactionId: req.params.transactionId,
    status: 'completed',
    amount: 100.00,
    paymentMethod: 'credit_card',
    processedAt: new Date()
  });
});

app.listen(PORT, () => {
  console.log(`Payment service running on port ${PORT}`);
});
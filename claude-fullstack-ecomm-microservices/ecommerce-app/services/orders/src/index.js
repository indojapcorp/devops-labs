// services/orders/src/index.js
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const morgan = require('morgan');
const jwt = require('jsonwebtoken');
const axios = require('axios');

const app = express();
const PORT = process.env.PORT || 3004;
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://orders-db:27017/orders';
const JWT_SECRET = process.env.JWT_SECRET || 'your_jwt_secret';
const PAYMENT_SERVICE = process.env.PAYMENT_SERVICE || 'http://payment-service:3005';
const CART_SERVICE = process.env.CART_SERVICE || 'http://cart-service:3003';
const NOTIFICATIONS_SERVICE = process.env.NOTIFICATIONS_SERVICE || 'http://notifications-service:3006';

// MongoDB connection
mongoose.connect(MONGODB_URI)
  .then(() => console.log('Connected to MongoDB'))
  .catch(err => console.error('MongoDB connection error:', err));

// Order Schema
const orderItemSchema = new mongoose.Schema({
  productId: { type: String, required: true },
  name: { type: String, required: true },
  price: { type: Number, required: true },
  quantity: { type: Number, required: true },
  imageUrl: { type: String }
});

const orderSchema = new mongoose.Schema({
  userId: { type: String, required: true },
  items: [orderItemSchema],
  totalAmount: { type: Number, required: true },
  shippingAddress: {
    street: { type: String, required: true },
    city: { type: String, required: true },
    state: { type: String, required: true },
    zipCode: { type: String, required: true },
    country: { type: String, required: true }
  },
  paymentInfo: {
    method: { type: String, required: true },
    transactionId: { type: String },
    status: { type: String, default: 'pending' }
  },
  status: { 
    type: String, 
    enum: ['pending', 'processing', 'shipped', 'delivered', 'canceled'],
    default: 'pending'
  },
  createdAt: { type: Date, default: Date.now }
});

const Order = mongoose.model('Order', orderSchema);

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

// Get orders for a user
app.get('/', authenticate, async (req, res) => {
  try {
    const userId = req.user.id;
    const orders = await Order.find({ userId }).sort({ createdAt: -1 });
    
    res.json(orders);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get specific order
app.get('/:id', authenticate, async (req, res) => {
  try {
    const userId = req.user.id;
    const order = await Order.findOne({ _id: req.params.id, userId });
    
    if (!order) {
      return res.status(404).json({ error: 'Order not found' });
    }
    
    res.json(order);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Create a new order
app.post('/', authenticate, async (req, res) => {
  try {
    const userId = req.user.id;
    const { items, totalAmount, shippingAddress, paymentInfo } = req.body;
    
    // Create the order
    const order = new Order({
      userId,
      items,
      totalAmount,
      shippingAddress,
      paymentInfo
    });
    
    await order.save();
    
    // Process payment
    try {
      const paymentResponse = await axios.post(`${PAYMENT_SERVICE}/process`, {
        orderId: order._id,
        amount: totalAmount,
        paymentMethod: paymentInfo.method
      }, {
        headers: { Authorization: req.headers.authorization }
      });
      
      // Update order with payment status
      order.paymentInfo.status = paymentResponse.data.status;
      order.paymentInfo.transactionId = paymentResponse.data.transactionId;
      
      if (paymentResponse.data.status === 'completed') {
        order.status = 'processing';
      }
      
      await order.save();
      
      // Clear cart after successful order
      await axios.delete(`${CART_SERVICE}`, {
        headers: { Authorization: req.headers.authorization }
      });
      
      // Send order confirmation notification
      await axios.post(`${NOTIFICATIONS_SERVICE}/email`, {
        to: req.user.email,
        subject: `Order Confirmation #${order._id}`,
        templateName: 'order-confirmation',
        data: {
          orderId: order._id,
          items: order.items,
          totalAmount: order.totalAmount,
          shippingAddress: order.shippingAddress
        }
      });
      
    } catch (error) {
      console.error('Payment processing failed:', error.message);
      // We still return the order with a pending payment status
    }
    
    res.status(201).json(order);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Update order status (admin only)
app.put('/:id/status', authenticate, async (req, res) => {
  try {
    // Check if user is admin
    if (req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Unauthorized' });
    }
    
    const { status } = req.body;
    
    const order = await Order.findById(req.params.id);
    
    if (!order) {
      return res.status(404).json({ error: 'Order not found' });
    }
    
    order.status = status;
    await order.save();
    
    // Send notification about status change
    try {
      await axios.post(`${NOTIFICATIONS_SERVICE}/email`, {
        to: req.user.email, // We need to fetch the actual user's email
        subject: `Order Status Update #${order._id}`,
        templateName: 'order-status-update',
        data: {
          orderId: order._id,
          status: order.status
        }
      });
    } catch (error) {
      console.error('Failed to send notification:', error.message);
    }
    
    res.json(order);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Cancel order
app.put('/:id/cancel', authenticate, async (req, res) => {
  try {
    const userId = req.user.id;
    const order = await Order.findOne({ _id: req.params.id, userId });
    
    if (!order) {
      return res.status(404).json({ error: 'Order not found' });
    }
    
    // Check if order can be canceled
    if (order.status !== 'pending' && order.status !== 'processing') {
      return res.status(400).json({ error: 'Order cannot be canceled' });
    }
    
    order.status = 'canceled';
    await order.save();
    
    // Send cancellation notification
    try {
      await axios.post(`${NOTIFICATIONS_SERVICE}/email`, {
        to: req.user.email,
        subject: `Order Cancellation #${order._id}`,
        templateName: 'order-cancellation',
        data: {
          orderId: order._id
        }
      });
    } catch (error) {
      console.error('Failed to send notification:', error.message);
    }
    
    res.json(order);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.listen(PORT, () => {
  console.log(`Orders service running on port ${PORT}`);
});
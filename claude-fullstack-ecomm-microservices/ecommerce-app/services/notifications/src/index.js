// services/notifications/src/index.js
const express = require('express');
const nodemailer = require('nodemailer');
const cors = require('cors');
const morgan = require('morgan');

const app = express();
const PORT = process.env.PORT || 3006;
const EMAIL_USER = process.env.EMAIL_USER || 'notifications@example.com';
const EMAIL_PASS = process.env.EMAIL_PASS || 'password';
const EMAIL_HOST = process.env.EMAIL_HOST || 'smtp.example.com';
const EMAIL_PORT = process.env.EMAIL_PORT || 587;

// In production, use real SMTP config
const transporter = nodemailer.createTransport({
  host: EMAIL_HOST,
  port: EMAIL_PORT,
  secure: false,
  auth: {
    user: EMAIL_USER,
    pass: EMAIL_PASS
  },
  tls: {
    rejectUnauthorized: false // Only for development
  }
});

// For development, we'll just log instead of sending real emails
const sendEmail = async (to, subject, text) => {
  console.log(`[EMAIL] To: ${to}, Subject: ${subject}, Body: ${text}`);
  
  // Uncomment this in production
  /*
  return transporter.sendMail({
    from: EMAIL_USER,
    to,
    subject,
    text
  });
  */
  
  return Promise.resolve();
};

// Middleware
app.use(cors());
app.use(express.json());
app.use(morgan('combined'));

// Routes
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'OK' });
});

// Send order confirmation notification
app.post('/order-confirmation', async (req, res) => {
  try {
    const { orderId, userId, totalAmount } = req.body;
    
    // In a real app, fetch user email from user service
    const userEmail = `${userId}@example.com`;
    
    await sendEmail(
      userEmail,
      `Order Confirmation #${orderId}`,
      `Thank you for your order! Your order #${orderId} has been confirmed. Total amount: $${totalAmount.toFixed(2)}.`
    );
    
    res.status(200).json({ message: 'Order confirmation sent' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Send order status update notification
app.post('/order-status-update', async (req, res) => {
  try {
    const { orderId, userId, status } = req.body;
    
    // In a real app, fetch user email from user service
    const userEmail = `${userId}@example.com`;
    
    await sendEmail(
      userEmail,
      `Order Status Update #${orderId}`,
      `Your order #${orderId} has been updated to: ${status}.`
    );
    
    res.status(200).json({ message: 'Status update notification sent' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Send order cancellation notification
app.post('/order-cancellation', async (req, res) => {
  try {
    const { orderId, userId } = req.body;
    
    // In a real app, fetch user email from user service
    const userEmail = `${userId}@example.com`;
    
    await sendEmail(
      userEmail,
      `Order Cancellation #${orderId}`,
      `Your order #${orderId} has been cancelled.`
    );
    
    res.status(200).json({ message: 'Cancellation notification sent' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.listen(PORT, () => {
  console.log(`Notifications service running on port ${PORT}`);
});

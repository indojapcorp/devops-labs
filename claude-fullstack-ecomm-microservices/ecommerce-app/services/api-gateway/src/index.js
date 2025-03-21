// services/api-gateway/src/index.js
const express = require('express');
const cors = require('cors');
const { createProxyMiddleware } = require('http-proxy-middleware');
const morgan = require('morgan');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(morgan('combined'));

// Service discovery should ideally be done with a service mesh or discovery service
// For simplicity, we'll use environment variables
const AUTH_SERVICE = process.env.AUTH_SERVICE || 'http://auth-service:3001';
const PRODUCTS_SERVICE = process.env.PRODUCTS_SERVICE || 'http://products-service:3002';
const CART_SERVICE = process.env.CART_SERVICE || 'http://cart-service:3003';
const ORDERS_SERVICE = process.env.ORDERS_SERVICE || 'http://orders-service:3004';
const PAYMENT_SERVICE = process.env.PAYMENT_SERVICE || 'http://payment-service:3005';

// Configure routes
app.use('/api/auth', createProxyMiddleware({ 
  target: AUTH_SERVICE,
  changeOrigin: true,
  pathRewrite: {'^/api/auth' : ''}
}));

app.use('/api/products', createProxyMiddleware({ 
  target: PRODUCTS_SERVICE,
  changeOrigin: true,
  pathRewrite: {'^/api/products' : ''}
}));

app.use('/api/cart', createProxyMiddleware({ 
  target: CART_SERVICE,
  changeOrigin: true,
  pathRewrite: {'^/api/cart' : ''}
}));

app.use('/api/orders', createProxyMiddleware({ 
  target: ORDERS_SERVICE,
  changeOrigin: true,
  pathRewrite: {'^/api/orders' : ''}
}));

app.use('/api/payment', createProxyMiddleware({ 
  target: PAYMENT_SERVICE,
  changeOrigin: true,
  pathRewrite: {'^/api/payment' : ''}
}));

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'OK' });
});

app.listen(PORT, () => {
  console.log(`API Gateway running on port ${PORT}`);
});

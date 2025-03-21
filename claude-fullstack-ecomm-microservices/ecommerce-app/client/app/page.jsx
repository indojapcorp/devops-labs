"use client";

import { useState, useEffect } from 'react';
import Link from 'next/link';
import axios from 'axios';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000/api';

export default function Home() {
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    const fetchProducts = async () => {
      try {
        const response = await axios.get(`${API_URL}/products`);
        setProducts(response.data);
      } catch (err) {
        setError(err.message);
      } finally {
        setLoading(false);
      }
    };

    fetchProducts();
  }, []);

  if (loading) {
    return (
      <div className="container mx-auto px-4 py-8">
        <h1 className="text-3xl font-bold mb-6">Loading products...</h1>
      </div>
    );
  }

  if (error) {
    return (
      <div className="container mx-auto px-4 py-8">
        <h1 className="text-3xl font-bold mb-6">Error loading products</h1>
        <p className="text-red-500">{error}</p>
      </div>
    );
  }

  return (
    <div className="container mx-auto px-4 py-8">
      <h1 className="text-3xl font-bold mb-6">Welcome to Our E-commerce Store</h1>
      
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
        {products.map((product) => (
          <div key={product._id} className="border rounded-lg overflow-hidden shadow-lg">
            <div className="h-48 bg-gray-200 flex items-center justify-center">
              {product.imageUrl ? (
                <img 
                  src={product.imageUrl} 
                  alt={product.name} 
                  className="object-cover h-full w-full"
                />
              ) : (
                <div className="text-gray-500">No image available</div>
              )}
            </div>
            
            <div className="p-4">
              <h2 className="text-xl font-semibold mb-2">{product.name}</h2>
              <p className="text-gray-600 mb-2 line-clamp-2">{product.description}</p>
              <p className="text-lg font-bold text-indigo-600">${product.price.toFixed(2)}</p>
              
              <div className="mt-4 flex justify-between">
                <Link 
                  href={`/products/${product._id}`}
                  className="text-indigo-600 hover:text-indigo-800"
                >
                  View Details
                </Link>
                <button 
                  className="bg-indigo-600 text-white px-4 py-2 rounded hover:bg-indigo-700"
                  onClick={() => addToCart(product)}
                >
                  Add to Cart
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );

  // This would typically be implemented with proper state management
  function addToCart(product) {
    // Check for authentication
    const token = localStorage.getItem('token');
    if (!token) {
      // Redirect to login or show login modal
      alert('Please log in to add items to your cart');
      return;
    }

    // Send add to cart request
    axios.post(
      `${API_URL}/cart/items`, 
      {
        productId: product._id,
        name: product.name,
        price: product.price,
        quantity: 1,
        imageUrl: product.imageUrl
      },
      {
        headers: { Authorization: `Bearer ${token}` }
      }
    )
    .then(() => {
      alert('Item added to cart');
    })
    .catch(err => {
      console.error('Error adding to cart:', err);
      alert('Failed to add item to cart');
    });
  }
}
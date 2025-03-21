// user-service/server.js
const express = require('express');
const mongoose = require('mongoose');
const bodyParser = require('body-parser');

// Initialize express
const app = express();
app.use(bodyParser.json());

// MongoDB connection
mongoose.connect('mongodb://database-service:27017/users', {
    useNewUrlParser: true,
    useUnifiedTopology: true,
}).then(() => console.log("Connected to MongoDB"))
  .catch((err) => console.error("Error connecting to MongoDB:", err));

// Create a user schema
const UserSchema = new mongoose.Schema({
    name: String,
    email: String,
});

// Create a User model
const User = mongoose.model('User', UserSchema);

// CRUD Routes

// Create User
app.post('/users', async (req, res) => {
    const user = new User(req.body);
    try {
        await user.save();
        res.status(201).send(user);
    } catch (err) {
        res.status(400).send(err);
    }
});

// Read Users
app.get('/users', async (req, res) => {
    try {
        const users = await User.find();
        res.status(200).send(users);
    } catch (err) {
        res.status(400).send(err);
    }
});

// Update User
app.put('/users/:id', async (req, res) => {
    try {
        const user = await User.findByIdAndUpdate(req.params.id, req.body, { new: true });
        res.status(200).send(user);
    } catch (err) {
        res.status(400).send(err);
    }
});

// Delete User
app.delete('/users/:id', async (req, res) => {
    try {
        await User.findByIdAndDelete(req.params.id);
        res.status(200).send({ message: "User deleted" });
    } catch (err) {
        res.status(400).send(err);
    }
});

// Start the server
app.listen(3000, () => {
    console.log("User service is running on port 3000");
});

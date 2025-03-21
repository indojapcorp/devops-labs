const express = require("express");
const sqlite3 = require("sqlite3").verbose();
const bodyParser = require("body-parser");

const app = express();
const db = new sqlite3.Database(":memory:"); // Use an in-memory SQLite DB for simplicity

// Middleware
app.use(bodyParser.json());

// Create Table (for users)
db.serialize(() => {
  db.run("CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, email TEXT)");
});

// CREATE - Add new user
app.post("/users", (req, res) => {
  const { name, email } = req.body;
  const stmt = db.prepare("INSERT INTO users (name, email) VALUES (?, ?)");
  stmt.run(name, email, function (err) {
    if (err) {
      return res.status(500).send("Error inserting user");
    }
    res.status(201).json({ id: this.lastID, name, email });
  });
  stmt.finalize();
});

// READ - Get all users
app.get("/users", (req, res) => {
  db.all("SELECT * FROM users", (err, rows) => {
    if (err) {
      return res.status(500).send("Error fetching users");
    }
    res.json(rows);
  });
});

// READ - Get user by ID
app.get("/users/:id", (req, res) => {
  const { id } = req.params;
  db.get("SELECT * FROM users WHERE id = ?", [id], (err, row) => {
    if (err) {
      return res.status(500).send("Error fetching user");
    }
    if (!row) {
      return res.status(404).send("User not found");
    }
    res.json(row);
  });
});

// UPDATE - Update user by ID
app.put("/users/:id", (req, res) => {
  const { id } = req.params;
  const { name, email } = req.body;
  const stmt = db.prepare("UPDATE users SET name = ?, email = ? WHERE id = ?");
  stmt.run(name, email, id, function (err) {
    if (err) {
      return res.status(500).send("Error updating user");
    }
    res.json({ id, name, email });
  });
  stmt.finalize();
});

// DELETE - Delete user by ID
app.delete("/users/:id", (req, res) => {
  const { id } = req.params;
  const stmt = db.prepare("DELETE FROM users WHERE id = ?");
  stmt.run(id, function (err) {
    if (err) {
      return res.status(500).send("Error deleting user");
    }
    res.status(204).send();
  });
  stmt.finalize();
});

// Server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});

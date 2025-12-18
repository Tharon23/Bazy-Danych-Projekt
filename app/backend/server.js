require('dotenv').config();
const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');

const app = express();
const port = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Database Connection
const pool = new Pool({
  user: process.env.DB_USER || 'postgres',
  host: process.env.DB_HOST || 'localhost',
  database: process.env.DB_NAME || 'warsztat',
  password: process.env.DB_PASSWORD, // User must set this in .env
  port: process.env.DB_PORT || 5432,
});

// Test Connection
pool.connect((err, client, release) => {
  if (err) {
    return console.error('Error acquiring client', err.stack);
  }
  console.log('Connected to PostgreSQL database: ' + (process.env.DB_NAME || 'warsztat'));
  release();
});

// --- API ROUTES ---

// 1. Get all stats for Dashboard
app.get('/api/stats', async (req, res) => {
  try {
    const ordersCount = await pool.query("SELECT COUNT(*) FROM zlecenia WHERE status NOT IN ('Zakonczone', 'Anulowane')");
    const lowStockCount = await pool.query("SELECT COUNT(*) FROM czesci WHERE ilosc_na_stanie < 10");
    const topMechanic = await pool.query("SELECT mechanik, srednia_na_zlecenie FROM widok_ranking_mechanikow LIMIT 1");

    res.json({
      activeOrders: parseInt(ordersCount.rows[0].count),
      lowStockItems: parseInt(lowStockCount.rows[0].count),
      topMechanic: topMechanic.rows[0] || { mechanik: 'Brak danych', srednia_na_zlecenie: 0 }
    });
  } catch (err) {
    console.error(err.message);
    res.status(500).send("Server Error");
  }
});

// 2. Get Active Orders
app.get('/api/orders', async (req, res) => {
  try {
    const result = await pool.query("SELECT * FROM widok_aktywne_zlecenia ORDER BY data_przyjecia DESC");
    res.json(result.rows);
  } catch (err) {
    console.error(err.message);
    res.status(500).send("Server Error");
  }
});

// 3. Get Mechanics Ranking
app.get('/api/mechanics', async (req, res) => {
  try {
    const result = await pool.query("SELECT * FROM widok_ranking_mechanikow");
    res.json(result.rows);
  } catch (err) {
    console.error(err.message);
    res.status(500).send("Server Error");
  }
});

// 4. Get Inventory (Low Stock)
app.get('/api/inventory', async (req, res) => {
  try {
    const result = await pool.query("SELECT * FROM widok_do_zamowienia");
    res.json(result.rows);
  } catch (err) {
    console.error(err.message);
    res.status(500).send("Server Error");
  }
});

// 4b. Get All Mechanics (Simple list for dropdown)
app.get('/api/mechanics-all', async (req, res) => {
  try {
    const result = await pool.query("SELECT id_mechanika, imie || ' ' || nazwisko as nazwa FROM mechanicy");
    res.json(result.rows);
  } catch (err) {
    console.error(err.message);
    res.status(500).send("Server Error");
  }
});

// 5. Get All Vehicles (for dropdown)
app.get('/api/vehicles', async (req, res) => {
  try {
    const result = await pool.query("SELECT id_pojazdu, marka, model, nr_rejestracyjny FROM pojazdy");
    res.json(result.rows);
  } catch (err) {
    console.error(err.message);
    res.status(500).send("Server Error");
  }
});

// 6. Create New Order (POST)
app.post('/api/orders', async (req, res) => {
  const { id_pojazdu, id_mechanika, opis } = req.body;

  // Basic Validation
  if (!id_pojazdu || !id_mechanika || !opis) {
    return res.status(400).json({ error: "Wszystkie pola są wymagane." });
  }

  try {
    // 1. Check if mechanic is available using DB function
    const availabilityCheck = await pool.query("SELECT czy_mechanik_dostepny($1)", [id_mechanika]);
    const isAvailable = availabilityCheck.rows[0].czy_mechanik_dostepny;

    if (!isAvailable) {
      return res.status(409).json({ error: "Wybrany mechanik jest obecnie zajęty innym zleceniem." });
    }

    // 2. Insert Order
    // Status defaults to 'Przyjete'
    const newOrder = await pool.query(
      "INSERT INTO zlecenia (id_pojazdu, id_mechanika, opis, status, koszt_robocizny) VALUES ($1, $2, $3, 'Przyjete', 0) RETURNING *",
      [id_pojazdu, id_mechanika, opis]
    );

    res.json(newOrder.rows[0]);
  } catch (err) {
    console.error(err.message);
    res.status(500).send("Server Error: " + err.message);
  }
});

// 7. Update Order Status (PATCH)
app.patch('/api/orders/:id', async (req, res) => {
  const { id } = req.params;
  const { status } = req.body;

  const validStatuses = ['Przyjete', 'W trakcie', 'Oczekuje na czesci', 'Zakonczone', 'Anulowane'];

  if (!validStatuses.includes(status)) {
    return res.status(400).json({ error: "Nieprawidłowy status." });
  }

  try {
    // JEŚLI ZAMYKAMY ZLECENIE -> USTAW DATĘ I KOSZT (np. losowy między 100 a 500 zł)
    if (status === 'Zakonczone') {
      const randomKoszt = Math.floor(Math.random() * 400) + 100; // Demo: Losowa cena
      
      await pool.query(
        "UPDATE zlecenia SET status = $1, data_zakonczenia = CURRENT_TIMESTAMP, koszt_robocizny = $2 WHERE id_zlecenia = $3", 
        [status, randomKoszt, id]
      );
    } else {
      // Logic for Mechanic Availability Check
      if (status === 'W trakcie') {
        // Get the mechanic assigned to this order
        const orderRes = await pool.query("SELECT id_mechanika FROM zlecenia WHERE id_zlecenia = $1", [id]);
        if (orderRes.rows.length > 0) {
          const mechId = orderRes.rows[0].id_mechanika;
          // Check if mechanic has OTHER active orders (W trakcie)
          const busyCheck = await pool.query(
            "SELECT COUNT(*) FROM zlecenia WHERE id_mechanika = $1 AND status = 'W trakcie' AND id_zlecenia != $2",
            [mechId, id]
          );

          if (parseInt(busyCheck.rows[0].count) > 0) {
            return res.status(409).json({ error: "Ten mechanik realizuje już inne zlecenie w tym momencie!" });
          }
        }
      }

      await pool.query("UPDATE zlecenia SET status = $1 WHERE id_zlecenia = $2", [status, id]);
    }

    res.json({ message: "Status zaktualizowany" });
  } catch (err) {
    console.error(err.message);
    res.status(500).send("Server Error");
  }
});

// 8. Restock Inventory (PATCH)
app.patch('/api/inventory/:id/restock', async (req, res) => {
  const { id } = req.params;
  try {
    await pool.query("UPDATE czesci SET ilosc_na_stanie = ilosc_na_stanie + 50 WHERE id_czesci = $1", [id]);
    res.json({ message: "Zamówiono towar (+50 szt.)" });
  } catch (err) {
    console.error(err.message);
    res.status(500).send("Server Error");
  }
});

app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});

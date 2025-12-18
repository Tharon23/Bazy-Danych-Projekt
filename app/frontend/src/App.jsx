import React, { useEffect, useState } from 'react';
import axios from 'axios';
import { LayoutDashboard, Users, AlertTriangle, Car, Wrench, Plus, X, Package } from 'lucide-react';

const API_URL = 'http://localhost:3000/api';

function App() {
  const [stats, setStats] = useState(null);
  const [orders, setOrders] = useState([]);
  const [mechanics, setMechanics] = useState([]);
  const [allMechanics, setAllMechanics] = useState([]);
  const [vehicles, setVehicles] = useState([]);
  const [inventory, setInventory] = useState([]); // New: Low stock items
  const [loading, setLoading] = useState(true);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [error, setError] = useState('');

  // Form State
  const [formData, setFormData] = useState({
    id_pojazdu: '',
    id_mechanika: '',
    opis: ''
  });

  const fetchData = async () => {
    try {
      const [statsRes, ordersRes, mechanicsRes, vehiclesRes, allMechanicsRes, inventoryRes] = await Promise.all([
        axios.get(`${API_URL}/stats`),
        axios.get(`${API_URL}/orders`),
        axios.get(`${API_URL}/mechanics`),
        axios.get(`${API_URL}/vehicles`),
        axios.get(`${API_URL}/mechanics-all`),
        axios.get(`${API_URL}/inventory`) // Fetch inventory
      ]);

      setStats(statsRes.data);
      setOrders(ordersRes.data);
      setMechanics(mechanicsRes.data);
      setVehicles(vehiclesRes.data);
      setAllMechanics(allMechanicsRes.data);
      setInventory(inventoryRes.data);
    } catch (err) {
      console.error("Error fetching data:", err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  const handleInputChange = (e) => {
    setFormData({
      ...formData,
      [e.target.name]: e.target.value
    });
  };

  const handleStatusChange = async (id, newStatus) => {
    try {
      await axios.patch(`${API_URL}/orders/${id}`, { status: newStatus });
      // Optimistic update or refresh
      fetchData();
    } catch (err) {
      if (err.response && err.response.status === 409) {
        alert(err.response.data.error);
      } else {
        alert("Błąd aktualizacji statusu");
      }
    }
  };

  const handleRestock = async (id, nazwa) => {
    try {
      await axios.patch(`${API_URL}/inventory/${id}/restock`);
      alert(`Zamówiono dostawę dla: ${nazwa}`);
      fetchData();
    } catch (err) {
      alert("Błąd podczas zamawiania towaru.");
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');

    if (!formData.id_pojazdu || !formData.id_mechanika || !formData.opis) {
      setError("Wymagane są wszystkie pola!");
      return;
    }

    try {
      await axios.post(`${API_URL}/orders`, formData);
      setIsModalOpen(false);
      setFormData({ id_pojazdu: '', id_mechanika: '', opis: '' });
      fetchData();
      alert("Zlecenie dodane pomyślnie!");
    } catch (err) {
      setError(err.response?.data?.error || "Wystąpił błąd przy dodawaniu zlecenia.");
    }
  };

  if (loading) return <div className="glass-panel" style={{ margin: '2rem', padding: '2rem' }}>Ładowanie warsztatu...</div>;

  return (
    <div style={{ padding: '2rem', maxWidth: '1200px', margin: '0 auto', position: 'relative' }}>

      {/* HEADER */}
      <header style={{ marginBottom: '3rem', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
          <Wrench size={48} color="var(--accent-blue)" />
          <div>
            <h1 className="title" style={{ margin: 0 }}>Warsztat Pro</h1>
            <p style={{ margin: 0, color: 'var(--text-secondary)' }}>Panel Zarządzania Serwisem</p>
          </div>
        </div>
        <button
          onClick={() => setIsModalOpen(true)}
          style={{
            background: 'var(--accent-blue)', color: 'white', border: 'none',
            padding: '0.75rem 1.5rem', borderRadius: '8px', cursor: 'pointer',
            fontWeight: '600', display: 'flex', alignItems: 'center', gap: '0.5rem',
            boxShadow: '0 4px 6px rgba(59, 130, 246, 0.3)'
          }}>
          <Plus size={20} /> Nowe Zlecenie
        </button>
      </header>

      {/* KPI Cards */}
      <div className="card-grid" style={{ marginBottom: '3rem', padding: 0 }}>

        <div className="glass-panel" style={{ padding: '1.5rem', display: 'flex', alignItems: 'center', gap: '1rem' }}>
          <div style={{ padding: '1rem', background: 'rgba(59, 130, 246, 0.2)', borderRadius: '12px' }}>
            <Car size={32} color="#60a5fa" />
          </div>
          <div>
            <div style={{ color: 'var(--text-secondary)' }}>Aktywne Zlecenia</div>
            <div className="stat-value">{stats?.activeOrders || 0}</div>
          </div>
        </div>

        <div className="glass-panel" style={{ padding: '1.5rem', display: 'flex', alignItems: 'center', gap: '1rem' }}>
          <div style={{ padding: '1rem', background: 'rgba(239, 68, 68, 0.2)', borderRadius: '12px' }}>
            <AlertTriangle size={32} color="#f87171" />
          </div>
          <div>
            <div style={{ color: 'var(--text-secondary)' }}>Niski Stan Części</div>
            <div className="stat-value">{stats?.lowStockItems || 0}</div>
          </div>
        </div>

        <div className="glass-panel" style={{ padding: '1.5rem', display: 'flex', alignItems: 'center', gap: '1rem' }}>
          <div style={{ padding: '1rem', background: 'rgba(16, 185, 129, 0.2)', borderRadius: '12px' }}>
            <Users size={32} color="#34d399" />
          </div>
          <div>
            <div style={{ color: 'var(--text-secondary)' }}>Najskuteczniejszy</div>
            <div style={{ fontSize: '1.2rem', fontWeight: 'bold' }}>{stats?.topMechanic?.mechanik || "-"}</div>
            <div style={{ fontSize: '0.9rem', color: 'var(--text-secondary)' }}>
              Śr. {stats?.topMechanic?.srednia_na_zlecenie || 0} PLN / zlecenie
            </div>
          </div>
        </div>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: '2rem', alignItems: 'start' }}>

        {/* Left Column */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: '2rem' }}>

          {/* Active Orders List */}
          <div className="glass-panel" style={{ padding: '1.5rem' }}>
            <h2 style={{ marginTop: 0, display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
              <LayoutDashboard size={20} /> Ostatnie Zlecenia
            </h2>
            <table className="table-container">
              <thead>
                <tr>
                  <th>Samochód</th>
                  <th>Opis Usterki</th>
                  <th>Klient</th>
                  <th>Status</th>
                  <th>Mechanik</th>
                </tr>
              </thead>
              <tbody>
                {orders.map(order => (
                  <tr key={order.id_zlecenia}>
                    <td>
                      <div style={{ fontWeight: 600 }}>{order.samochod}</div>
                      <div style={{ fontSize: '0.8rem', color: 'var(--text-secondary)' }}>{new Date(order.data_przyjecia).toLocaleDateString()}</div>
                    </td>

                    <td style={{ maxWidth: '200px', fontSize: '0.9rem', color: '#cbd5e1' }}>
                      {order.opis}
                    </td>
                    <td>{order.wlasciciel}</td>
                    <td>
                      <select
                        value={order.status}
                        onChange={(e) => handleStatusChange(order.id_zlecenia, e.target.value)}
                        style={{
                          background: 'transparent',
                          color: order.status === 'W trakcie' ? '#60a5fa' : order.status === 'Oczekuje na czesci' ? '#f87171' : '#34d399',
                          border: '1px solid var(--glass-border)',
                          borderRadius: '4px',
                          padding: '0.25rem',
                          fontWeight: 'bold'
                        }}
                      >
                        <option value="Przyjete">Przyjete</option>
                        <option value="W trakcie">W trakcie</option>
                        <option value="Oczekuje na czesci">Oczekuje na czesci</option>
                        <option value="Zakonczone">Zakonczone</option>
                        <option value="Anulowane">Anulowane</option>
                      </select>
                    </td>
                    <td>{order.mechanik}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {/* Low Stock Inventory - NEW */}
          <div className="glass-panel" style={{ padding: '1.5rem' }}>
            <h2 style={{ marginTop: 0, display: 'flex', alignItems: 'center', gap: '0.5rem', color: '#f87171' }}>
              <Package size={20} /> Braki Magazynowe (Do Zamówienia)
            </h2>
            {inventory.length === 0 ? (
              <div style={{ color: 'var(--text-secondary)' }}>Brak towarów o niskim stanie.</div>
            ) : (
              <table className="table-container">
                <thead>
                  <tr>
                    <th>Nazwa Części</th>
                    <th>Stan</th>
                    <th>Cena Zakupu</th>
                    <th>Akcja</th>
                  </tr>
                </thead>
                <tbody>
                  {inventory.map(item => (
                    <tr key={item.id_czesci}>
                      <td style={{ fontWeight: 600 }}>{item.nazwa}</td>
                      <td style={{ color: '#f87171', fontWeight: 'bold' }}>{item.ilosc_na_stanie} szt.</td>
                      <td>{item.cena_zakupu} PLN</td>
                      <td>
                        <button style={{
                          padding: '0.25rem 0.75rem', fontSize: '0.8rem',
                          background: 'rgba(59, 130, 246, 0.2)', color: '#60a5fa',
                          border: 'none', borderRadius: '4px', cursor: 'pointer'
                        }} onClick={() => handleRestock(item.id_czesci, item.nazwa)}>
                          Zamów
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>

        </div>

        {/* Right Column: Mechanics Ranking */}
        <div className="glass-panel" style={{ padding: '1.5rem' }}>
          <h2 style={{ marginTop: 0, display: 'flex', alignItems: 'center', gap: '0.5rem' }}>
            <Users size={20} /> Ranking
          </h2>
          {mechanics.map((mech, index) => (
            <div key={index} style={{
              display: 'flex',
              justifyContent: 'space-between',
              alignItems: 'center',
              padding: '1rem 0',
              borderBottom: index !== mechanics.length - 1 ? '1px solid var(--glass-border)' : 'none'
            }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '1rem' }}>
                <div style={{
                  width: '30px', height: '30px', borderRadius: '50%',
                  background: 'var(--bg-card)', display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontWeight: 'bold', color: 'var(--text-secondary)'
                }}>
                  {index + 1}
                </div>
                <div>
                  <div style={{ fontWeight: 600 }}>{mech.mechanik}</div>
                  <div style={{ fontSize: '0.8rem', color: 'var(--text-secondary)' }}>{mech.liczba_zlecen} zleceń</div>
                </div>
              </div>
              <div style={{ fontWeight: 700, color: 'var(--accent-green)' }}>
                {parseFloat(mech.laczny_przychod_z_robocizny).toLocaleString()} PLN
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* MODAL */}
      {isModalOpen && (
        <div style={{
          position: 'fixed', top: 0, left: 0, width: '100%', height: '100%',
          background: 'rgba(0,0,0,0.7)', backdropFilter: 'blur(5px)',
          display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000
        }}>
          <div className="glass-panel" style={{ width: '500px', padding: '2rem', background: '#1e293b' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '1.5rem' }}>
              <h2 style={{ margin: 0 }}>Nowe Zlecenie</h2>
              <button onClick={() => setIsModalOpen(false)} style={{ background: 'none', border: 'none', color: 'white', cursor: 'pointer' }}><X /></button>
            </div>

            {error && <div style={{ color: '#f87171', marginBottom: '1rem', padding: '0.5rem', background: 'rgba(239, 68, 68, 0.1)', borderRadius: '4px' }}>{error}</div>}

            <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '1rem' }}>
              <div>
                <label style={{ display: 'block', marginBottom: '0.5rem', color: 'var(--text-secondary)' }}>Pojazd</label>
                <select
                  name="id_pojazdu"
                  value={formData.id_pojazdu}
                  onChange={handleInputChange}
                  style={{ width: '100%', padding: '0.75rem', borderRadius: '6px', background: '#0f172a', color: 'white', border: '1px solid var(--glass-border)' }}
                >
                  <option value="">-- Wybierz Pojazd --</option>
                  {vehicles.map(v => (
                    <option key={v.id_pojazdu} value={v.id_pojazdu}>
                      {v.marka} {v.model} ({v.nr_rejestracyjny})
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label style={{ display: 'block', marginBottom: '0.5rem', color: 'var(--text-secondary)' }}>Mechanik</label>
                <select
                  name="id_mechanika"
                  value={formData.id_mechanika}
                  onChange={handleInputChange}
                  style={{ width: '100%', padding: '0.75rem', borderRadius: '6px', background: '#0f172a', color: 'white', border: '1px solid var(--glass-border)' }}
                >
                  <option value="">-- Wybierz Mechanika --</option>
                  {allMechanics.map(m => (
                    <option key={m.id_mechanika} value={m.id_mechanika}>
                      {m.nazwa}
                    </option>
                  ))}
                </select>
              </div>

              <div>
                <label style={{ display: 'block', marginBottom: '0.5rem', color: 'var(--text-secondary)' }}>Opis Usterki</label>
                <textarea
                  name="opis"
                  value={formData.opis}
                  onChange={handleInputChange}
                  rows="4"
                  style={{ width: '100%', padding: '0.75rem', borderRadius: '6px', background: '#0f172a', color: 'white', border: '1px solid var(--glass-border)' }}
                ></textarea>
              </div>

              <button type="submit" style={{
                marginTop: '1rem', padding: '0.75rem', background: 'var(--accent-green)',
                color: 'white', border: 'none', borderRadius: '6px', fontWeight: 'bold', cursor: 'pointer'
              }}>
                Dodaj Zlecenie
              </button>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}

export default App;

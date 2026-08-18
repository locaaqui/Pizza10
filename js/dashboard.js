// ================================================================
// Pizza10 — Dashboard Module
// ================================================================

const ORDERS_TABLE = 'pizza10_pedidos';

let dashboardOrders = [];

/**
 * Load dashboard data
 */
async function loadDashboard() {
  try {
    // Get today's date range
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const todayISO = today.toISOString();

    // Load all orders for today
    const { data, error } = await sb
      .from(ORDERS_TABLE)
      .select('*')
      .gte('created_at', todayISO)
      .order('created_at', { ascending: false });

    if (error) {
      console.warn('Tabela pizza10_pedidos não encontrada ou vazia:', error.message);
      dashboardOrders = [];
    } else {
      dashboardOrders = data || [];
    }

    updateStats();
    renderRecentOrders();
  } catch (err) {
    console.error('Erro ao carregar dashboard:', err);
    dashboardOrders = [];
    updateStats();
    renderRecentOrders();
  }
}

/**
 * Update stats cards
 */
function updateStats() {
  const total = dashboardOrders.length;
  const pending = dashboardOrders.filter(o => o.status === 'novo' || o.status === 'preparando').length;
  const delivering = dashboardOrders.filter(o => o.status === 'entrega').length;
  const delivered = dashboardOrders.filter(o => o.status === 'entregue').length;
  const revenue = dashboardOrders
    .filter(o => o.status !== 'cancelado')
    .reduce((sum, o) => sum + (parseFloat(o.total) || 0), 0);

  animateValue('statTotal', total);
  animateValue('statPending', pending);
  animateValue('statDelivering', delivering);
  animateValue('statDelivered', delivered);

  const revenueEl = document.getElementById('statRevenue');
  if (revenueEl) {
    revenueEl.textContent = 'R$ ' + revenue.toFixed(2).replace('.', ',');
  }
}

/**
 * Animate number counting
 */
function animateValue(elementId, target) {
  const el = document.getElementById(elementId);
  if (!el) return;

  const start = parseInt(el.textContent) || 0;
  const duration = 600;
  const startTime = performance.now();

  function update(currentTime) {
    const elapsed = currentTime - startTime;
    const progress = Math.min(elapsed / duration, 1);
    const eased = 1 - Math.pow(1 - progress, 3);
    el.textContent = Math.round(start + (target - start) * eased);
    if (progress < 1) requestAnimationFrame(update);
  }

  requestAnimationFrame(update);
}

/**
 * Render recent orders table
 */
function renderRecentOrders() {
  const tbody = document.getElementById('recentOrdersBody');
  if (!tbody) return;

  if (dashboardOrders.length === 0) {
    tbody.innerHTML = `
      <tr>
        <td colspan="6" style="text-align:center; padding:40px; color:var(--text-muted);">
          <i class="fas fa-pizza-slice" style="font-size:32px; display:block; margin-bottom:12px; opacity:0.3;"></i>
          Nenhum pedido hoje ainda. Bora vender! 🍕
        </td>
      </tr>
    `;
    return;
  }

  tbody.innerHTML = dashboardOrders.slice(0, 10).map(order => {
    const statusMap = {
      novo: { label: 'Novo', class: 'badge-new', icon: 'fa-bell' },
      preparando: { label: 'Preparando', class: 'badge-preparing', icon: 'fa-fire' },
      entrega: { label: 'Em Entrega', class: 'badge-delivering', icon: 'fa-motorcycle' },
      entregue: { label: 'Entregue', class: 'badge-delivered', icon: 'fa-check' },
      cancelado: { label: 'Cancelado', class: 'badge-cancelled', icon: 'fa-times' },
    };

    const s = statusMap[order.status] || statusMap.novo;
    const time = new Date(order.created_at).toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' });

    return `
      <tr>
        <td style="color:var(--text-primary); font-weight:500;">#${String(order.id).padStart(4, '0')}</td>
        <td style="color:var(--text-primary);">${order.cliente_nome || '—'}</td>
        <td>${order.itens_resumo || '—'}</td>
        <td style="color:var(--pizza-orange); font-weight:600;">R$ ${parseFloat(order.total || 0).toFixed(2).replace('.', ',')}</td>
        <td><span class="badge ${s.class}"><i class="fas ${s.icon}"></i> ${s.label}</span></td>
        <td style="color:var(--text-muted);">${time}</td>
      </tr>
    `;
  }).join('');
}

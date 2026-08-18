// ================================================================
// Pizza10 — Pedidos (Orders) Module
// ================================================================

const PEDIDOS_TABLE = 'pedidos_pizza10';

let allOrders = [];
let filteredOrders = [];
let currentStatusFilter = 'todos';
let currentSearchQuery = '';

/**
 * Load all orders
 */
async function loadOrders() {
  try {
    const { data, error } = await sb
      .from(PEDIDOS_TABLE)
      .select('*')
      .order('created_at', { ascending: false });

    if (error) {
      console.warn('Tabela pizza10_pedidos não encontrada:', error.message);
      allOrders = [];
    } else {
      allOrders = data || [];
    }
  } catch (e) {
    console.error('Erro ao carregar pedidos:', e);
    allOrders = [];
  }

  applyFilters();
}

/**
 * Apply filters and render
 */
function applyFilters() {
  filteredOrders = allOrders;

  // Status filter
  if (currentStatusFilter !== 'todos') {
    filteredOrders = filteredOrders.filter(o => o.status === currentStatusFilter);
  }

  // Search filter
  if (currentSearchQuery) {
    const q = currentSearchQuery.toLowerCase();
    filteredOrders = filteredOrders.filter(o =>
      (o.cliente_nome || '').toLowerCase().includes(q) ||
      (o.cliente_telefone || '').includes(q) ||
      String(o.id).includes(q)
    );
  }

  renderOrders();
  updateOrderCounts();
}

/**
 * Update filter counts
 */
function updateOrderCounts() {
  const counts = {
    todos: allOrders.length,
    novo: allOrders.filter(o => o.status === 'novo').length,
    preparando: allOrders.filter(o => o.status === 'preparando').length,
    entrega: allOrders.filter(o => o.status === 'entrega').length,
    entregue: allOrders.filter(o => o.status === 'entregue').length,
    cancelado: allOrders.filter(o => o.status === 'cancelado').length,
  };

  Object.entries(counts).forEach(([key, count]) => {
    const el = document.getElementById(`count-${key}`);
    if (el) el.textContent = count;
  });
}

/**
 * Set status filter
 */
function setStatusFilter(status) {
  currentStatusFilter = status;

  document.querySelectorAll('.filter-tab').forEach(tab => {
    tab.classList.toggle('active', tab.dataset.status === status);
  });

  applyFilters();
}

/**
 * Set search query
 */
function setSearchQuery(query) {
  currentSearchQuery = query;
  applyFilters();
}

/**
 * Render orders table
 */
function renderOrders() {
  const tbody = document.getElementById('ordersBody');
  if (!tbody) return;

  if (filteredOrders.length === 0) {
    tbody.innerHTML = `
      <tr>
        <td colspan="7" style="text-align:center; padding:48px; color:var(--text-muted);">
          <i class="fas fa-inbox" style="font-size:36px; display:block; margin-bottom:12px; opacity:0.3;"></i>
          ${allOrders.length === 0 ? 'Nenhum pedido registrado ainda.' : 'Nenhum pedido encontrado com os filtros atuais.'}
        </td>
      </tr>
    `;
    return;
  }

  tbody.innerHTML = filteredOrders.map(order => {
    const statusMap = {
      novo: { label: 'Novo', class: 'badge-new', icon: 'fa-bell', next: 'preparando' },
      preparando: { label: 'Preparando', class: 'badge-preparing', icon: 'fa-fire', next: 'entrega' },
      entrega: { label: 'Em Entrega', class: 'badge-delivering', icon: 'fa-motorcycle', next: 'entregue' },
      entregue: { label: 'Entregue', class: 'badge-delivered', icon: 'fa-check', next: null },
      cancelado: { label: 'Cancelado', class: 'badge-cancelled', icon: 'fa-times', next: null },
    };

    const s = statusMap[order.status] || statusMap.novo;
    const date = new Date(order.created_at);
    const dateStr = date.toLocaleDateString('pt-BR');
    const timeStr = date.toLocaleTimeString('pt-BR', { hour: '2-digit', minute: '2-digit' });

    const nextBtn = s.next
      ? `<button class="btn btn-sm btn-secondary" onclick="advanceStatus(${order.id}, '${s.next}')" title="Avançar status">
           <i class="fas fa-arrow-right"></i>
         </button>`
      : '';

    const cancelBtn = order.status !== 'cancelado' && order.status !== 'entregue'
      ? `<button class="btn btn-sm btn-secondary" onclick="advanceStatus(${order.id}, 'cancelado')" title="Cancelar" style="color:var(--red);">
           <i class="fas fa-times"></i>
         </button>`
      : '';

    return `
      <tr>
        <td style="color:var(--text-primary); font-weight:600;">#${String(order.id).padStart(4, '0')}</td>
        <td>
          <div style="color:var(--text-primary); font-weight:500;">${order.cliente_nome || '—'}</div>
          <div style="font-size:12px; color:var(--text-muted);">${order.cliente_telefone || ''}</div>
        </td>
        <td>${order.itens_resumo || '—'}</td>
        <td style="color:var(--pizza-orange); font-weight:600;">R$ ${parseFloat(order.total || 0).toFixed(2).replace('.', ',')}</td>
        <td><span class="badge ${s.class}"><i class="fas ${s.icon}"></i> ${s.label}</span></td>
        <td style="color:var(--text-muted);">${dateStr} ${timeStr}</td>
        <td>
          <div style="display:flex; gap:6px;">
            ${nextBtn}
            ${cancelBtn}
            <button class="btn btn-sm btn-secondary" onclick="viewOrderDetail(${order.id})" title="Ver detalhes">
              <i class="fas fa-eye"></i>
            </button>
          </div>
        </td>
      </tr>
    `;
  }).join('');
}

/**
 * Advance order status
 */
async function advanceStatus(orderId, newStatus) {
  const statusLabels = {
    preparando: 'Preparando',
    entrega: 'Em Entrega',
    entregue: 'Entregue',
    cancelado: 'Cancelado',
  };

  if (newStatus === 'cancelado') {
    if (!confirm('Tem certeza que deseja cancelar este pedido?')) return;
  }

  try {
    const { error } = await sb
      .from(PEDIDOS_TABLE)
      .update({ status: newStatus, updated_at: new Date().toISOString() })
      .eq('id', orderId);

    if (error) throw error;

    showToast(`Pedido #${String(orderId).padStart(4, '0')} → ${statusLabels[newStatus]}`, 'success');
    await loadOrders();
  } catch (err) {
    showToast('Erro ao atualizar pedido: ' + err.message, 'error');
  }
}

/**
 * View order detail (opens modal)
 */
function viewOrderDetail(orderId) {
  const order = allOrders.find(o => o.id === orderId);
  if (!order) return;

  const modal = document.getElementById('orderDetailModal');
  if (!modal) return;

  document.getElementById('detailId').textContent = '#' + String(order.id).padStart(4, '0');
  document.getElementById('detailCliente').textContent = order.cliente_nome || '—';
  document.getElementById('detailTelefone').textContent = order.cliente_telefone || '—';
  document.getElementById('detailEndereco').textContent = order.endereco || '—';
  document.getElementById('detailItens').textContent = order.itens_resumo || '—';
  document.getElementById('detailObs').textContent = order.observacoes || 'Nenhuma';
  document.getElementById('detailTotal').textContent = 'R$ ' + parseFloat(order.total || 0).toFixed(2).replace('.', ',');
  document.getElementById('detailData').textContent = new Date(order.created_at).toLocaleString('pt-BR');

  const statusMap = {
    novo: { label: 'Novo', class: 'badge-new' },
    preparando: { label: 'Preparando', class: 'badge-preparing' },
    entrega: { label: 'Em Entrega', class: 'badge-delivering' },
    entregue: { label: 'Entregue', class: 'badge-delivered' },
    cancelado: { label: 'Cancelado', class: 'badge-cancelled' },
  };
  const s = statusMap[order.status] || statusMap.novo;
  document.getElementById('detailStatus').innerHTML = `<span class="badge ${s.class}">${s.label}</span>`;

  modal.classList.add('active');
}

/**
 * Close order detail modal
 */
function closeOrderDetail() {
  const modal = document.getElementById('orderDetailModal');
  if (modal) modal.classList.remove('active');
}

/**
 * Create a new order (modal)
 */
function openNewOrderModal() {
  const modal = document.getElementById('newOrderModal');
  if (modal) modal.classList.add('active');

  // Reset form
  const form = document.getElementById('newOrderForm');
  if (form) form.reset();
}

function closeNewOrderModal() {
  const modal = document.getElementById('newOrderModal');
  if (modal) modal.classList.remove('active');
}

async function saveNewOrder() {
  const nome = document.getElementById('noCliente').value.trim();
  const telefone = document.getElementById('noTelefone').value.trim();
  const endereco = document.getElementById('noEndereco').value.trim();
  const itens = document.getElementById('noItens').value.trim();
  const total = document.getElementById('noTotal').value.trim();
  const obs = document.getElementById('noObs').value.trim();

  if (!nome || !itens || !total) {
    showToast('Preencha nome, itens e total.', 'error');
    return;
  }

  try {
    const { error } = await sb.from(PEDIDOS_TABLE).insert({
      cliente_nome: nome,
      cliente_telefone: telefone,
      endereco: endereco,
      itens_resumo: itens,
      total: parseFloat(total.replace(',', '.')) || 0,
      observacoes: obs,
      status: 'novo',
      created_at: new Date().toISOString(),
    });

    if (error) throw error;

    showToast('Pedido criado com sucesso! 🍕', 'success');
    closeNewOrderModal();
    await loadOrders();
  } catch (err) {
    showToast('Erro ao criar pedido: ' + err.message, 'error');
  }
}

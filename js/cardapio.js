// ================================================================
// Pizza10 — Cardápio (Menu) Module
// ================================================================

const MENU_TABLE = 'produtos_pizza10';
const CATEGORIAS_TABLE = 'categorias_pizza10';

// Default menu items (used if Supabase table doesn't exist yet)
const DEFAULT_MENU = [
  // Pizzas Tradicionais
  {
    id: 1, categoria: 'tradicionais', nome: 'Margherita',
    descricao: 'Molho de tomate, mozzarella de búfala, manjericão fresco e azeite extra virgem.',
    imagem: 'img/pizza-calabresa.jpg'
  },
  {
    id: 2, categoria: 'tradicionais', nome: 'Calabresa',
    descricao: 'Calabresa artesanal fatiada, cebola caramelizada e azeitonas pretas.',
    imagem: 'img/pizza-calabresa.jpg'
  },
  {
    id: 3, categoria: 'tradicionais', nome: 'Quatro Queijos',
    descricao: 'Mozzarella, gorgonzola, parmesão e provolone derretidos na perfeição.',
    imagem: 'img/pizza-quatro-queijos.jpg'
  },
  {
    id: 4, categoria: 'tradicionais', nome: 'Portuguesa',
    descricao: 'Presunto, ovos, cebola, azeitonas, ervilha e mozzarella.',
    imagem: 'img/pizza-portuguesa.jpg'
  },
  {
    id: 5, categoria: 'tradicionais', nome: 'Frango com Catupiry',
    descricao: 'Frango desfiado temperado com catupiry cremoso e milho.',
    imagem: 'img/pizza-frango-catupiry.jpg'
  },
  {
    id: 6, categoria: 'tradicionais', nome: 'Napolitana',
    descricao: 'Tomate em rodelas, mozzarella, parmesão ralado e manjericão.',
    imagem: 'img/pizza-portuguesa.jpg'
  },

  // Pizzas Especiais
  {
    id: 7, categoria: 'especiais', nome: 'Trufada de Cogumelos',
    descricao: 'Mix de cogumelos frescos, azeite trufado, rúcula e lascas de parmesão.',
    imagem: 'img/pizza-picanha.jpg'
  },
  {
    id: 8, categoria: 'especiais', nome: 'Filé Mignon com Cheddar',
    descricao: 'Cubos de filé mignon grelhados, cheddar inglês e cebola crispy.',
    imagem: 'img/pizza-picanha.jpg'
  },
  {
    id: 9, categoria: 'especiais', nome: 'Camarão ao Alho',
    descricao: 'Camarões salteados no alho, tomate seco, rúcula e cream cheese.',
    imagem: 'img/pizza-frango-catupiry.jpg'
  },
  {
    id: 10, categoria: 'especiais', nome: 'Picanha Especial na Lenha',
    descricao: 'Picanha grelhada em fatias, mozzarella nobre, alho frito crocante e ervas.',
    imagem: 'img/pizza-picanha.jpg'
  },

  // Bebidas
  {
    id: 11, categoria: 'bebidas', nome: 'Coca-Cola 350ml',
    descricao: 'Coca-Cola Original gelada.',
    imagem: 'https://images.unsplash.com/photo-1554866585-cd94860890b7?w=600&q=80'
  },
  {
    id: 12, categoria: 'bebidas', nome: 'Suco Natural de Laranja',
    descricao: 'Suco de laranja espremido na hora. 500ml.',
    imagem: 'https://images.unsplash.com/photo-1621506289937-a8e4df240d0b?w=600&q=80'
  },
  {
    id: 13, categoria: 'bebidas', nome: 'Água Mineral 500ml',
    descricao: 'Água mineral sem gás.',
    imagem: 'https://images.unsplash.com/photo-1560023907-5f339617ea30?w=600&q=80'
  },
  {
    id: 14, categoria: 'bebidas', nome: 'Cerveja Artesanal IPA',
    descricao: 'IPA artesanal local com notas cítricas. 500ml.',
    imagem: 'https://images.unsplash.com/photo-1535958636474-b021ee887b13?w=600&q=80'
  },

  // Sobremesas
  {
    id: 15, categoria: 'sobremesas', nome: 'Vulcão de Nutella & Morangos',
    descricao: 'Pura Nutella cremosa original com morangos frescos e raspas de chocolate.',
    imagem: 'img/pizza-nutella-morango.jpg'
  },
  {
    id: 16, categoria: 'sobremesas', nome: 'Petit Gâteau',
    descricao: 'Bolo de chocolate com centro líquido, sorvete de creme e calda.',
    imagem: 'img/pizza-nutella-morango.jpg'
  },
];

let menuItems = [];
let activeCategory = 'todos';

/**
 * Load menu items from Supabase or use defaults
 */
async function loadMenu() {
  try {
    const { data, error } = await sb.from(MENU_TABLE).select('*').eq('ativo', true).order('categoria');

    if (error || !data || data.length === 0) {
      console.info('Usando cardápio padrão (tabela pizza10_cardapio não encontrada ou vazia).');
      menuItems = DEFAULT_MENU;
    } else {
      menuItems = data;
    }
  } catch (e) {
    menuItems = DEFAULT_MENU;
  }

  renderMenu();
}

/**
 * Filter by category
 */
function filterCategory(category) {
  activeCategory = category;

  // Update tabs
  document.querySelectorAll('.category-tab').forEach(tab => {
    tab.classList.toggle('active', tab.dataset.category === category);
  });

  renderMenu();
}

/**
 * Render menu items
 */
function renderMenu() {
  const grid = document.getElementById('menuGrid');
  if (!grid) return;

  const filtered = activeCategory === 'todos'
    ? menuItems
    : menuItems.filter(item => item.categoria === activeCategory);

  if (filtered.length === 0) {
    grid.innerHTML = `
      <div class="empty-state" style="grid-column: 1 / -1;">
        <i class="fas fa-pizza-slice"></i>
        <p>Nenhum item encontrado nesta categoria.</p>
      </div>
    `;
    return;
  }

  grid.innerHTML = filtered.map((item, idx) => `
    <div class="menu-item" style="animation-delay: ${idx * 0.06}s">
      <img class="menu-item-img" src="${item.imagem}" alt="${item.nome}" loading="lazy"
           onerror="this.src='https://images.unsplash.com/photo-1513104890138-7c749659a591?w=600&q=80'">
      <div class="menu-item-body">
        <h3>${item.nome}</h3>
        <p class="description">${item.descricao}</p>
        <div class="menu-item-footer">
          <a href="${ANOTA_AI_URL}" target="_blank" class="btn-card-order" style="width: 100%; justify-content: center; text-decoration: none; padding: 10px 14px; font-size: 13px;">
            <i class="fas fa-utensils"></i> Ver Opções & Pedir
          </a>
        </div>
      </div>
    </div>
  `).join('');
}

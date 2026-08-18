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
    preco: 42.90, imagem: 'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=600&q=80'
  },
  {
    id: 2, categoria: 'tradicionais', nome: 'Calabresa',
    descricao: 'Calabresa artesanal fatiada, cebola caramelizada e azeitonas pretas.',
    preco: 39.90, imagem: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=600&q=80'
  },
  {
    id: 3, categoria: 'tradicionais', nome: 'Quatro Queijos',
    descricao: 'Mozzarella, gorgonzola, parmesão e provolone derretidos na perfeição.',
    preco: 45.90, imagem: 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=600&q=80'
  },
  {
    id: 4, categoria: 'tradicionais', nome: 'Portuguesa',
    descricao: 'Presunto, ovos, cebola, azeitonas, ervilha e mozzarella.',
    preco: 43.90, imagem: 'https://images.unsplash.com/photo-1600628421060-939639517883?w=600&q=80'
  },
  {
    id: 5, categoria: 'tradicionais', nome: 'Frango com Catupiry',
    descricao: 'Frango desfiado temperado com catupiry cremoso e milho.',
    preco: 42.90, imagem: 'https://images.unsplash.com/photo-1571407970349-bc81e7e96d47?w=600&q=80'
  },
  {
    id: 6, categoria: 'tradicionais', nome: 'Napolitana',
    descricao: 'Tomate em rodelas, mozzarella, parmesão ralado e manjericão.',
    preco: 40.90, imagem: 'https://images.unsplash.com/photo-1588315029754-2dd089d39a1a?w=600&q=80'
  },

  // Pizzas Especiais
  {
    id: 7, categoria: 'especiais', nome: 'Trufada de Cogumelos',
    descricao: 'Mix de cogumelos frescos, azeite trufado, rúcula e lascas de parmesão.',
    preco: 59.90, imagem: 'https://images.unsplash.com/photo-1593560708920-61dd98c46a4e?w=600&q=80'
  },
  {
    id: 8, categoria: 'especiais', nome: 'Filé Mignon com Cheddar',
    descricao: 'Cubos de filé mignon grelhados, cheddar inglês e cebola crispy.',
    preco: 62.90, imagem: 'https://images.unsplash.com/photo-1628840042765-356cda07504e?w=600&q=80'
  },
  {
    id: 9, categoria: 'especiais', nome: 'Camarão ao Alho',
    descricao: 'Camarões salteados no alho, tomate seco, rúcula e cream cheese.',
    preco: 68.90, imagem: 'https://images.unsplash.com/photo-1595854341625-f33ee10dbf94?w=600&q=80'
  },
  {
    id: 10, categoria: 'especiais', nome: 'Parma com Burrata',
    descricao: 'Presunto parma curado, burrata cremosa, tomate cereja e rúcula.',
    preco: 64.90, imagem: 'https://images.unsplash.com/photo-1604382355076-af4b0eb60143?w=600&q=80'
  },

  // Bebidas
  {
    id: 11, categoria: 'bebidas', nome: 'Coca-Cola 350ml',
    descricao: 'Coca-Cola Original gelada.',
    preco: 6.90, imagem: 'https://images.unsplash.com/photo-1554866585-cd94860890b7?w=600&q=80'
  },
  {
    id: 12, categoria: 'bebidas', nome: 'Suco Natural de Laranja',
    descricao: 'Suco de laranja espremido na hora. 500ml.',
    preco: 12.90, imagem: 'https://images.unsplash.com/photo-1621506289937-a8e4df240d0b?w=600&q=80'
  },
  {
    id: 13, categoria: 'bebidas', nome: 'Água Mineral 500ml',
    descricao: 'Água mineral sem gás.',
    preco: 4.90, imagem: 'https://images.unsplash.com/photo-1560023907-5f339617ea30?w=600&q=80'
  },
  {
    id: 14, categoria: 'bebidas', nome: 'Cerveja Artesanal IPA',
    descricao: 'IPA artesanal local com notas cítricas. 500ml.',
    preco: 18.90, imagem: 'https://images.unsplash.com/photo-1535958636474-b021ee887b13?w=600&q=80'
  },

  // Sobremesas
  {
    id: 15, categoria: 'sobremesas', nome: 'Pizza de Chocolate',
    descricao: 'Chocolate ao leite e chocolate branco com morango e confetes.',
    preco: 38.90, imagem: 'https://images.unsplash.com/photo-1541745537411-b8d1eae6c18a?w=600&q=80'
  },
  {
    id: 16, categoria: 'sobremesas', nome: 'Petit Gâteau',
    descricao: 'Bolo de chocolate com centro líquido, sorvete de creme e calda.',
    preco: 24.90, imagem: 'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?w=600&q=80'
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
          <span class="menu-item-price">R$ ${parseFloat(item.preco).toFixed(2).replace('.', ',')}</span>
          <a href="https://wa.me/${WHATSAPP_NUMBER}?text=${encodeURIComponent(`Olá! Gostaria de pedir: ${item.nome} - R$ ${parseFloat(item.preco).toFixed(2).replace('.', ',')}`)}"
             target="_blank" class="btn-whatsapp">
            <i class="fab fa-whatsapp"></i> Pedir
          </a>
        </div>
      </div>
    </div>
  `).join('');
}

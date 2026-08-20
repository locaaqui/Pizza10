// ================================================================
// Pizza10 — Supabase Configuration
// Shared Supabase instance (same as Locaki)
// ================================================================

const SUPABASE_URL = 'https://ykppjqamzrzgirewdgpa.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_iEBiMYqlR5tdMcdzS2MCww_sDtayvvE';

const sb = supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// Pizza 10 Itatiba — Business Info & URLs
const WHATSAPP_NUMBER = '5511972070747';
const ANOTA_AI_URL = 'https://app.anota.ai/pizza-10-2?utm_source=portal-share-btn';
const PIZZA10_INFO = {
  nome: 'Pizza 10',
  cidade: 'Itatiba - SP',
  endereco: 'Rua Atílio Lanfranchi, 91 – Vila Bela Vista, Itatiba - SP, 13253-120',
  whatsapp: '(11) 97207-0747',
  whatsappRaw: '5511972070747',
  telefone1: '(11) 4534-1010',
  telefone2: '(11) 4534-3026',
  horario: 'Todos os dias, das 18h às 00h',
  ratingGoogle: 4.6,
  totalAvaliacoes: 320,
  cardapioUrl: 'https://app.anota.ai/pizza-10-2?utm_source=portal-share-btn',
  instagram: 'https://www.instagram.com/pizza_10itatiba/'
};

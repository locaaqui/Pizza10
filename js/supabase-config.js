// ================================================================
// Pizza10 — Supabase Configuration
// Shared Supabase instance (same as Locaki)
// ================================================================

const SUPABASE_URL = 'https://ykppjqamzrzgirewdgpa.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_iEBiMYqlR5tdMcdzS2MCww_sDtayvvE';

const sb = supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// WhatsApp number for orders
const WHATSAPP_NUMBER = '5511999999999'; // TODO: Update with real number

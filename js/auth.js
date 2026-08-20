// ================================================================
// Pizza10 — Authentication Module
// Uses Supabase Auth (shared with Locaki)
// ================================================================

/**
 * Check if user has an active session.
 * If on a protected page and no session, redirect to login.
 * If on login page and has session, redirect to dashboard.
 */
async function checkAuth(isProtectedPage = true) {
  try {
    const { data } = await sb.auth.getSession();
    const session = data?.session;

    if (isProtectedPage && !session) {
      window.location.replace('login.html');
      return null;
    }

    if (!isProtectedPage && session) {
      window.location.replace('admin-clientes.html');
      return session;
    }

    if (session) {
      await updateUserUI(session);
    }

    return session;
  } catch (err) {
    console.error('Auth check failed:', err);
    if (isProtectedPage) {
      window.location.replace('login.html');
    }
    return null;
  }
}

/**
 * Sign in with username/email and password
 */
async function signIn(nameOrEmail, password) {
  let email = nameOrEmail;

  // If not an email, try to resolve from usuarios_gestao table
  if (!nameOrEmail.includes('@')) {
    const { data } = await sb
      .from('usuarios_gestao')
      .select('email')
      .ilike('nome', nameOrEmail)
      .maybeSingle();

    email = data?.email || (nameOrEmail.toLowerCase().replace(/[^a-z0-9]/g, '') + '@locaki.com.br');
  }

  const { data, error } = await sb.auth.signInWithPassword({
    email,
    password,
  });

  if (error) {
    throw new Error('Usuário ou senha incorretos.');
  }

  return data;
}

/**
 * Sign out and redirect to login
 */
async function signOut() {
  await sb.auth.signOut();
  window.location.replace('login.html');
}

/**
 * Update UI elements with user info
 */
async function updateUserUI(session) {
  if (!session?.user) return;

  const user = session.user;
  let userName = user.email?.split('@')[0] || 'Admin';

  // Try to get display name from usuarios_gestao
  try {
    const { data: gestao } = await sb
      .from('usuarios_gestao')
      .select('nome, is_blocked')
      .eq('id', user.id)
      .maybeSingle();

    if (gestao?.is_blocked) {
      await sb.auth.signOut();
      window.location.replace('index.html');
      return;
    }

    if (gestao?.nome) {
      userName = gestao.nome;
    }
  } catch (e) {
    // Ignore - use email-derived name
  }

  // Update user label in header
  const userLabel = document.getElementById('userLabel');
  if (userLabel) {
    userLabel.innerHTML = `<i class="fas fa-user-circle"></i> ${userName}`;
  }
}

/**
 * Show toast notification
 */
function showToast(message, type = 'success') {
  let toast = document.getElementById('toast');
  if (!toast) {
    toast = document.createElement('div');
    toast.id = 'toast';
    toast.className = 'toast';
    document.body.appendChild(toast);
  }

  const icons = {
    success: 'fa-check-circle',
    error: 'fa-exclamation-circle',
    info: 'fa-info-circle',
  };

  toast.className = `toast ${type}`;
  toast.innerHTML = `<i class="fas ${icons[type] || icons.info}"></i> <span>${message}</span>`;
  toast.classList.add('show');

  setTimeout(() => {
    toast.classList.remove('show');
  }, 3500);
}

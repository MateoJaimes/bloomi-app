export const authCallbackHtml = `<!doctype html>
<html lang="es">
<head>
  <meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
  <meta name="referrer" content="no-referrer">
  <title>Bloomi · Tu cuenta</title>
  <style>
    *{box-sizing:border-box}body{font-family:system-ui,sans-serif;background:#fff8fa;color:#30272a;margin:0;padding:24px}
    main{max-width:480px;margin:8vh auto;background:white;border-radius:24px;padding:32px;box-shadow:0 8px 40px #512b3710}
    h1{font-size:28px}p{line-height:1.6;color:#66555c}label{display:block;margin:20px 0 8px}
    input,button{width:100%;padding:14px;font:inherit;border-radius:12px;border:1px solid #d8c8ce}
    button{margin-top:24px;background:#b73e68;color:white;border:0;font-weight:600;cursor:pointer}
    button:disabled{opacity:.6;cursor:wait}[hidden]{display:none!important}#message{white-space:pre-line}
  </style>
  <script src="/auth-callback.js" defer></script>
</head>
<body><main>
  <p style="color:#b73e68;font-weight:800;letter-spacing:1px">BLOOMI</p>
  <h1 id="title">Verificando tu enlace…</h1>
  <p id="description">Espera un momento.</p>
  <form id="reset-form" hidden>
    <label for="password">Nueva contraseña</label>
    <input id="password" name="password" type="password" minlength="10" maxlength="128" required autocomplete="new-password">
    <label for="confirmation">Confirma tu nueva contraseña</label>
    <input id="confirmation" name="confirmation" type="password" minlength="10" maxlength="128" required autocomplete="new-password">
    <label style="display:flex;gap:8px;align-items:center"><input id="show-password" type="checkbox" style="width:auto">Mostrar contraseñas</label>
    <button id="submit" type="submit">Guardar nueva contraseña</button>
  </form>
  <p id="message" role="status" aria-live="polite"></p>
  <noscript>Activa JavaScript para continuar con este enlace.</noscript>
</main></body></html>`;

// The callback token stays in memory and is removed from the browser address
// before any network request. No third-party scripts or resources are loaded.
export const authCallbackScript = String.raw`(() => {
  const fragment = new URLSearchParams(window.location.hash.slice(1));
  const query = new URLSearchParams(window.location.search);
  let token = fragment.get('access_token');
  const type = fragment.get('type') || query.get('type');
  const failed = fragment.has('error') || fragment.has('error_code') || query.has('error') || query.has('error_code');
  window.history.replaceState(null, '', window.location.pathname);
  const title = document.getElementById('title');
  const description = document.getElementById('description');
  const form = document.getElementById('reset-form');
  const message = document.getElementById('message');
  const button = document.getElementById('submit');
  const password = document.getElementById('password');
  const confirmation = document.getElementById('confirmation');
  document.getElementById('show-password').addEventListener('change', (event) => {
    password.type = confirmation.type = event.target.checked ? 'text' : 'password';
  });

  if (failed || (type === 'recovery' && !token)) {
    token = null;
    title.textContent = 'El enlace no es válido o venció';
    description.textContent = 'Vuelve a Bloomi, toca «¿Olvidaste tu contraseña?» y solicita un correo nuevo. Usa el enlace más reciente.';
    return;
  }
  if (type !== 'recovery') {
    token = null;
    title.textContent = type === 'signup' || type === 'email' ? '¡Correo confirmado!' : 'Tu cuenta de Bloomi';
    description.textContent = 'Si acabas de confirmar tu correo, vuelve a la app e inicia sesión. Para recuperar tu contraseña, solicita un correo desde «¿Olvidaste tu contraseña?» y abre su enlace más reciente.';
    return;
  }
  title.textContent = 'Restablece tu contraseña';
  description.textContent = 'Elige una contraseña nueva de al menos 10 caracteres para volver a tu cuenta.';
  form.hidden = false;
  let busy = false;
  form.addEventListener('submit', async (event) => {
    event.preventDefault();
    if (busy || !form.reportValidity()) return;
    if (password.value !== confirmation.value) {
      message.textContent = 'Las contraseñas no coinciden.';
      return;
    }
    busy = true;
    button.disabled = true;
    message.textContent = 'Guardando tu nueva contraseña…';
    try {
      const response = await fetch('/v1/auth/update-password', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: 'Bearer ' + token },
        body: JSON.stringify({ password: password.value }),
      });
      if (!response.ok) {
        if (response.status === 401) {
          token = null;
          form.hidden = true;
          message.textContent = 'El enlace venció. Vuelve a la app y solicita un correo nuevo.';
          return;
        }
        message.textContent = 'No fue posible cambiar la contraseña. Prueba con una contraseña diferente o solicita un enlace nuevo desde la app.';
        return;
      }
      token = null;
      form.reset();
      form.hidden = true;
      title.textContent = 'Contraseña actualizada';
      description.textContent = 'Vuelve a Bloomi e inicia sesión con tu nueva contraseña.';
      message.textContent = '';
    } catch (_) {
      message.textContent = 'No pudimos conectar. Revisa tu conexión e inténtalo de nuevo.';
    } finally {
      busy = false;
      button.disabled = false;
    }
  });
})();`;

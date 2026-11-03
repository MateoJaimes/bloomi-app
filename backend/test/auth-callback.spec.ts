import { runInNewContext } from 'node:vm';
import { authCallbackHtml, authCallbackScript } from '../src/auth/auth-callback.page';

function openCallback(hash: string, search = '') {
  const elements = Object.fromEntries(['title', 'description', 'reset-form', 'message', 'submit', 'password', 'confirmation', 'show-password'].map(id => [id, {
    textContent: '', hidden: id === 'reset-form', disabled: false, value: '',
    reportValidity: () => true, reset: jest.fn(), addEventListener: jest.fn(),
  }]));
  const replaceState = jest.fn();
  const fetch = jest.fn();
  runInNewContext(authCallbackScript, {
    URLSearchParams, document: { getElementById: (id: string) => elements[id] }, fetch,
    window: { location: { hash, search, pathname: '/' }, history: { replaceState } },
  });
  const submit = () => elements['reset-form'].addEventListener.mock.calls[0][1]({ preventDefault: jest.fn() });
  return { elements, replaceState, fetch, submit };
}

describe('email callback page', () => {
  it('loads a separate script compatible with the default CSP', () => {
    expect(authCallbackHtml).toContain('src="/auth-callback.js"');
    expect(authCallbackHtml).not.toContain('<script>');
  });

  it('shows the reset form for recovery links and removes tokens from the address', () => {
    const page = openCallback('#access_token=secret&refresh_token=private&type=recovery');
    expect(page.elements['reset-form'].hidden).toBe(false);
    expect(page.elements.title.textContent).toBe('Restablece tu contraseña');
    expect(page.replaceState).toHaveBeenCalledWith(null, '', '/');
    expect(page.fetch).not.toHaveBeenCalled();
  });

  it('preserves email confirmation without offering a reset form', () => {
    const page = openCallback('#access_token=secret&type=signup');
    expect(page.elements['reset-form'].hidden).toBe(true);
    expect(page.elements.title.textContent).toBe('¡Correo confirmado!');
  });

  it.each(['#error=access_denied&error_code=otp_expired', '#type=recovery'])('explains invalid links: %s', hash => {
    const page = openCallback(hash);
    expect(page.elements['reset-form'].hidden).toBe(true);
    expect(page.elements.title.textContent).toContain('venció');
  });

  it('blocks mismatched passwords before sending a request', async () => {
    const page = openCallback('#access_token=secret&type=recovery');
    page.elements.password.value = 'new-password-123';
    page.elements.confirmation.value = 'different-password';
    await page.submit();
    expect(page.fetch).not.toHaveBeenCalled();
    expect(page.elements.message.textContent).toContain('no coinciden');
  });

  it('sends the recovery token as a bearer and shows success after the update', async () => {
    const page = openCallback('#access_token=secret&type=recovery');
    page.elements.password.value = page.elements.confirmation.value = 'new-password-123';
    page.fetch.mockResolvedValue({ ok: true });
    await page.submit();
    expect(page.fetch).toHaveBeenCalledWith('/v1/auth/update-password', {
      method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: 'Bearer secret' },
      body: JSON.stringify({ password: 'new-password-123' }),
    });
    expect(page.elements.title.textContent).toBe('Contraseña actualizada');
    expect(page.elements['reset-form'].hidden).toBe(true);
    expect(page.elements['reset-form'].reset).toHaveBeenCalled();
  });

  it('handles expired sessions without claiming success', async () => {
    const page = openCallback('#access_token=secret&type=recovery');
    page.elements.password.value = page.elements.confirmation.value = 'new-password-123';
    page.fetch.mockResolvedValue({ ok: false, status: 401 });
    await page.submit();
    expect(page.elements.message.textContent).toContain('venció');
    expect(page.elements['reset-form'].hidden).toBe(true);
  });
});

import {
  clearAdminToken,
  getAdminToken,
  getRefreshToken,
  setAdminTokens,
} from './auth';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000';

type Method = 'GET' | 'POST' | 'PATCH' | 'DELETE';

async function requestWithAuth(
  method: Method,
  path: string,
  token?: string,
  body?: unknown,
) {
  const initialToken = token || getAdminToken();

  const run = (accessToken?: string) =>
    fetch(`${API_URL}${path}`, {
      method,
      headers: {
        ...(body ? { 'Content-Type': 'application/json' } : {}),
        ...(accessToken ? { Authorization: `Bearer ${accessToken}` } : {}),
      },
      ...(body ? { body: JSON.stringify(body) } : {}),
      cache: 'no-store',
    });

  let response = await run(initialToken || undefined);

  if (response.status === 401 && !path.startsWith('/auth/')) {
    const refreshToken = getRefreshToken();
    if (refreshToken) {
      const refreshResponse = await fetch(`${API_URL}/auth/refresh`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ refreshToken }),
      });

      if (refreshResponse.ok) {
        const refreshed = await refreshResponse.json();
        setAdminTokens(refreshed.accessToken, refreshed.refreshToken);
        response = await run(refreshed.accessToken);
      } else {
        clearAdminToken();
      }
    }
  }

  return response;
}

export async function apiGet(path: string, token?: string) {
  const res = await requestWithAuth('GET', path, token);

  if (!res.ok) {
    throw new Error(`API ${path} failed: ${res.status}`);
  }

  return res.json();
}

export async function apiPost(path: string, body: unknown, token?: string) {
  const res = await requestWithAuth('POST', path, token, body);

  if (!res.ok) {
    const text = await res.text();
    throw new Error(text || `API ${path} failed: ${res.status}`);
  }

  return res.json();
}

export async function apiPatch(path: string, body: unknown, token?: string) {
  const res = await requestWithAuth('PATCH', path, token, body);

  if (!res.ok) {
    const text = await res.text();
    throw new Error(text || `API ${path} failed: ${res.status}`);
  }

  return res.json();
}

export async function authGet(path: string) {
  return apiGet(path, getAdminToken() || undefined);
}

export async function authPost(path: string, body: unknown) {
  return apiPost(path, body, getAdminToken() || undefined);
}

export async function authPatch(path: string, body: unknown) {
  return apiPatch(path, body, getAdminToken() || undefined);
}

export async function apiDelete(path: string, token?: string) {
  const res = await requestWithAuth('DELETE', path, token);

  if (!res.ok) {
    const text = await res.text();
    throw new Error(text || `API ${path} failed: ${res.status}`);
  }

  // Handle 204 No Content or empty responses gracefully
  const text = await res.text();
  return text ? JSON.parse(text) : { success: true };
}

export async function authDelete(path: string) {
  return apiDelete(path, getAdminToken() || undefined);
}

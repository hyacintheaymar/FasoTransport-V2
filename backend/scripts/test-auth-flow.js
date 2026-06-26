/* eslint-disable no-console */

const API_BASE_URL = process.env.API_BASE_URL || 'http://localhost:4000';
const TEST_EMAIL = process.env.TEST_EMAIL || 'admin@fasotransport.bf';
const TEST_PASSWORD = process.env.TEST_PASSWORD || 'Password123!';

function assert(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}

async function post(path, body, token) {
  const response = await fetch(`${API_BASE_URL}${path}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: JSON.stringify(body),
  });

  const text = await response.text();
  let data;
  try {
    data = text ? JSON.parse(text) : {};
  } catch {
    data = { raw: text };
  }

  return { response, data };
}

async function get(path, token) {
  const response = await fetch(`${API_BASE_URL}${path}`, {
    headers: token ? { Authorization: `Bearer ${token}` } : {},
  });

  const text = await response.text();
  let data;
  try {
    data = text ? JSON.parse(text) : {};
  } catch {
    data = { raw: text };
  }

  return { response, data };
}

async function main() {
  console.log(`Testing auth flow on ${API_BASE_URL}`);

  const health = await get('/health');
  assert(health.response.ok, `Health check failed: ${health.response.status}`);

  const login = await post('/auth/login', {
    email: TEST_EMAIL,
    password: TEST_PASSWORD,
  });

  assert(login.response.ok, `Login failed: ${login.response.status}`);
  assert(login.data.accessToken, 'Login response missing accessToken');
  assert(login.data.refreshToken, 'Login response missing refreshToken');

  const accessToken = login.data.accessToken;
  const refreshToken = login.data.refreshToken;

  const me = await get('/auth/me', accessToken);
  assert(me.response.ok, `Me failed: ${me.response.status}`);
  assert(me.data.email, 'Me response missing email');

  const refresh = await post('/auth/refresh', { refreshToken });
  assert(refresh.response.ok, `Refresh failed: ${refresh.response.status}`);
  assert(refresh.data.accessToken, 'Refresh response missing accessToken');
  assert(refresh.data.refreshToken, 'Refresh response missing refreshToken');

  const logout = await post('/auth/logout', {}, refresh.data.accessToken);
  assert(logout.response.ok, `Logout failed: ${logout.response.status}`);

  const refreshAfterLogout = await post('/auth/refresh', {
    refreshToken: refresh.data.refreshToken,
  });
  assert(
    refreshAfterLogout.response.status === 401,
    `Expected refresh after logout to fail with 401, got ${refreshAfterLogout.response.status}`,
  );

  console.log('Auth flow test passed');
}

main().catch((error) => {
  console.error('Auth flow test failed');
  console.error(error.message);
  process.exit(1);
});

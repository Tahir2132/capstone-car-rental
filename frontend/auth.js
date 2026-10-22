// Capston Rent – login and sign-up with Amazon Cognito
// Uses Cognito managed login (authorization code flow with PKCE).

const COGNITO = {
  domain: "https://us-east-11fcdvhqrl.auth.us-east-1.amazoncognito.com",
  clientId: "44og1u2sfk8uoodmjg5cuun35",
  redirectUri: location.origin, // must be an "Allowed callback URL" in Cognito
  scope: "openid email",
};

// ---------- helpers ----------
function b64url(buffer) {
  return btoa(String.fromCharCode(...new Uint8Array(buffer)))
    .replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}
function randomString() {
  return b64url(crypto.getRandomValues(new Uint8Array(32)));
}
function sha256(text) {
  return crypto.subtle.digest("SHA-256", new TextEncoder().encode(text));
}
function readToken(token) {
  try {
    const payload = token.split(".")[1].replace(/-/g, "+").replace(/_/g, "/");
    return JSON.parse(atob(payload));
  } catch {
    return null;
  }
}

// ---------- login / sign-up / logout ----------
async function startLogin(signUp) {
  const verifier = randomString();
  const state = randomString();
  sessionStorage.setItem("pkce_verifier", verifier);
  sessionStorage.setItem("pkce_state", state);

  const params = new URLSearchParams({
    response_type: "code",
    client_id: COGNITO.clientId,
    redirect_uri: COGNITO.redirectUri,
    scope: COGNITO.scope,
    state,
    code_challenge_method: "S256",
    code_challenge: b64url(await sha256(verifier)),
  });
  const page = signUp ? "signup" : "oauth2/authorize";
  location.href = `${COGNITO.domain}/${page}?${params}`;
}

function logout() {
  sessionStorage.removeItem("id_token");
  sessionStorage.removeItem("access_token");
  const params = new URLSearchParams({ client_id: COGNITO.clientId, logout_uri: COGNITO.redirectUri });
  location.href = `${COGNITO.domain}/logout?${params}`;
}

// After login, Cognito sends the customer back with ?code=...&state=...
async function handleLoginRedirect() {
  const url = new URL(location.href);
  const code = url.searchParams.get("code");
  if (!code) return;

  const stateOk = url.searchParams.get("state") === sessionStorage.getItem("pkce_state");
  const verifier = sessionStorage.getItem("pkce_verifier");
  history.replaceState(null, "", location.pathname); // remove ?code= from the address bar
  if (!stateOk || !verifier) return;

  const res = await fetch(`${COGNITO.domain}/oauth2/token`, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "authorization_code",
      client_id: COGNITO.clientId,
      code,
      redirect_uri: COGNITO.redirectUri,
      code_verifier: verifier,
    }),
  });
  sessionStorage.removeItem("pkce_verifier");
  sessionStorage.removeItem("pkce_state");
  if (!res.ok) {
    console.error("Login failed:", await res.text());
    return;
  }
  const tokens = await res.json();
  sessionStorage.setItem("id_token", tokens.id_token);
  sessionStorage.setItem("access_token", tokens.access_token);
}

function currentUser() {
  const user = readToken(sessionStorage.getItem("id_token") || "");
  if (!user || user.exp * 1000 < Date.now()) return null;
  return user;
}

// For the booking phase: send this token to the protected booking API
function getIdToken() {
  return currentUser() ? sessionStorage.getItem("id_token") : null;
}
window.capstonAuth = { getIdToken, currentUser };

// ---------- show the buttons in the header ----------
function renderAuth() {
  const box = document.getElementById("auth");
  if (!box) return;
  const user = currentUser();
  box.innerHTML = "";

  if (user) {
    const name = document.createElement("span");
    name.className = "auth-user";
    name.textContent = `Hi, ${user.email}`;
    const out = document.createElement("button");
    out.className = "auth-btn";
    out.textContent = "Log out";
    out.onclick = logout;
    box.append(name, out);
  } else {
    const login = document.createElement("button");
    login.className = "auth-btn";
    login.textContent = "Log in";
    login.onclick = () => startLogin(false);
    const signup = document.createElement("button");
    signup.className = "auth-btn auth-primary";
    signup.textContent = "Sign up";
    signup.onclick = () => startLogin(true);
    box.append(login, signup);
  }
}

const authStyle = document.createElement("style");
authStyle.textContent = `
  #auth { display: flex; align-items: center; gap: 10px; }
  .auth-user { color: #D3DDE8; font-size: 15px; }
  .auth-btn { font: inherit; font-size: 15px; font-weight: 600; padding: 6px 14px; border-radius: 4px;
              border: 2px solid #FFFFFF; background: transparent; color: #FFFFFF; cursor: pointer; }
  .auth-primary { background: #F2C230; border-color: #F2C230; color: #0C2540; }
`;
document.head.appendChild(authStyle);

handleLoginRedirect().finally(renderAuth);

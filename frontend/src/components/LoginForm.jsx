import { useState } from "react";

import monSiteLogo from "../assets/mon-site-logo.png";
import ThemeToggle from "./ThemeToggle.jsx";

export default function LoginForm({
  appName = "__APP_NAME__",
  onSubmit,
  busy = false,
  error = "",
  message = "",
  theme = "dark",
  onThemeChange,
}) {
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");

  async function handleSubmit(event) {
    event.preventDefault();
    await onSubmit?.({ username, password });
  }

  return (
    <section className="login-shell">
      <article className="login-card">
        <div className="login-head">
          <img className="login-logo" src={monSiteLogo} alt="mon-site.ca" />
          <ThemeToggle
            theme={theme}
            onChange={onThemeChange}
            className="login-theme-toggle"
          />
        </div>
        <p className="eyebrow">{appName}</p>
        <h1>Connexion</h1>
        <p className="hero-copy">
          Accès privé à l’application auto-hébergée.
        </p>
        {message ? <div className="status-banner">{message}</div> : null}
        {error ? <div className="status-banner error">{error}</div> : null}
        <form className="data-form" onSubmit={handleSubmit}>
          <label>
            Nom d&apos;utilisateur
            <input
              type="text"
              value={username}
              onChange={(event) => setUsername(event.target.value)}
              required
              autoComplete="username"
            />
          </label>
          <label>
            Mot de passe
            <input
              type="password"
              value={password}
              onChange={(event) => setPassword(event.target.value)}
              required
              autoComplete="current-password"
            />
          </label>
          <button className="primary-button" type="submit" disabled={busy}>
            {busy ? "Connexion en cours..." : "Se connecter"}
          </button>
        </form>
      </article>
    </section>
  );
}

import { useEffect, useState } from "react";

import LoginForm from "./components/LoginForm.jsx";
import ThemeToggle from "./components/ThemeToggle.jsx";
import monSiteLogo from "./assets/mon-site-logo.png";

const APP_NAME = "__APP_NAME__";
const THEME_KEY = "mon-site.theme";
const LEGACY_THEME_KEYS = ["__APP_SLUG__.theme"];

function getInitialTheme() {
  if (typeof window === "undefined") {
    return "dark";
  }

  const savedTheme = [THEME_KEY, ...LEGACY_THEME_KEYS]
    .map((key) => window.localStorage.getItem(key))
    .find((value) => value === "light" || value === "dark");

  if (savedTheme) {
    return savedTheme;
  }

  return window.matchMedia("(prefers-color-scheme: light)").matches ? "light" : "dark";
}

export default function App() {
  const [theme, setTheme] = useState(getInitialTheme);
  const [isAuthenticated, setAuthenticated] = useState(false);

  useEffect(() => {
    document.documentElement.dataset.theme = theme;
    window.localStorage.setItem(THEME_KEY, theme);
  }, [theme]);

  if (!isAuthenticated) {
    return (
      <LoginForm
        appName={APP_NAME}
        onSubmit={() => setAuthenticated(true)}
        onThemeChange={setTheme}
        theme={theme}
      />
    );
  }

  return (
    <main className="app-shell">
      <header className="app-header">
        <div className="brand-block">
          <img className="brand-logo" src={monSiteLogo} alt="mon-site.ca" />
          <div>
            <p className="eyebrow">{APP_NAME}</p>
            <h1 className="app-title">Application prête</h1>
          </div>
        </div>
        <div className="user-meta">
          <ThemeToggle theme={theme} onChange={setTheme} />
          <button className="secondary-button" type="button" onClick={() => setAuthenticated(false)}>
            Déconnexion
          </button>
        </div>
      </header>

      <section className="panel">
        <p className="hero-copy">
          Frontend React/Vite fonctionnel. Remplace ce contenu par les écrans métier de l’application.
        </p>
      </section>
    </main>
  );
}

#!/bin/bash
set -euo pipefail

#############################################
# Steampunk Vite + React + Tailwind Setup Script
# - Overwrites steampunk_setup.log on each run.
# - Creates a new GitHub repo (via gh CLI).
# - Deploys to GitHub Pages, printing a clear link.
# - Configures Storybook using PostCSS for Tailwind.
# - Inserts the correct Google Fonts link for “Special Elite”.
# - Replaces default <title> with $APP_NAME.
# - Removes ANSI escape codes for a clean console output.
# - Auto-launches Storybook
#############################################

# Overwrite log file on each run
rm -f steampunk_setup.log
exec > >(tee steampunk_setup.log) 2>&1
set -x

#############################################
# 1. Check GH CLI installation & authentication
#############################################
if ! command -v gh &> /dev/null; then
  echo "ERROR: GitHub CLI (gh) is not installed or not in PATH."
  exit 1
fi

if ! gh auth status &> /dev/null; then
  echo "ERROR: GitHub CLI is installed but you're not authenticated."
  echo "Run 'gh auth login' and follow prompts, then re-run this script."
  exit 1
fi

#############################################
# 2. Load environment variables from .env
#############################################
if [ ! -f .env ]; then
  echo "ERROR: .env file not found! Please create a .env file with APP_NAME and GITHUB_ACCOUNT."
  exit 1
fi

set -a
source .env
set +a

if [ -z "${APP_NAME:-}" ]; then
  echo "ERROR: APP_NAME variable is not set in .env."
  exit 1
fi

if [ -z "${GITHUB_ACCOUNT:-}" ]; then
  echo "ERROR: GITHUB_ACCOUNT variable is not set in .env."
  exit 1
fi

echo "Using application name: $APP_NAME"
echo "Using GitHub account: $GITHUB_ACCOUNT"

#############################################
# 3. If current directory is a Git repo, move up one level
#############################################
if [ -d ".git" ]; then
  echo "Detected .git folder here. Moving up one directory to create new project in parallel."
  cd ..
fi

#############################################
# 4. Create new project folder (if it doesn’t exist)
#############################################
if [ -d "$APP_NAME" ]; then
  echo "ERROR: Directory '$APP_NAME' already exists. Aborting to avoid overwriting."
  exit 1
fi

echo "Creating Vite + React (TypeScript) project in folder: $APP_NAME"
npm create vite@latest "$APP_NAME" -- --template react-ts

cd "$APP_NAME"

#############################################
# 5. Create blank files in the project root
#############################################
echo "Creating blank files: scaffolding.sh and components.txt..."
touch scaffolding.sh
touch components.txt

#############################################
# 6. Install project dependencies
#############################################
echo "Installing project dependencies..."
npm install

#############################################
# 7. Install additional dev dependencies
#############################################
echo "Installing dev dependencies: Tailwind, PostCSS, Autoprefixer, @tailwindcss/postcss, gh-pages, Prettier..."
npm install -D tailwindcss postcss autoprefixer @tailwindcss/postcss gh-pages prettier

#############################################
# 7.1 Overwrite default react.svg if custom one exists
#############################################
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
if [ -f "$SCRIPT_DIR/react.svg" ]; then
  rm -f src/assets/react.svg
  cp "$SCRIPT_DIR/react.svg" src/assets/react.svg
  echo "Custom react.svg found and copied to src/assets, overwriting the default."
fi

#############################################
# 8. Create PostCSS config for Tailwind
#############################################
cat <<'EOF' > postcss.config.cjs
module.exports = {
  plugins: {
    '@tailwindcss/postcss': {},
    autoprefixer: {},
  },
};
EOF

#############################################
# 9. Create Tailwind CSS entry file
#############################################
cat <<'EOF' > src/tailwind.css
@tailwind base;
@tailwind components;
@tailwind utilities;
EOF

#############################################
# 10. Configure Vite
#############################################
echo "Writing vite.config.ts..."
cat <<EOF > vite.config.ts
// vite.config.ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  base: '/$APP_NAME/',
  plugins: [react()],
});
EOF

echo "Writing tailwind.config.js..."
cat <<'EOF' > tailwind.config.js
// tailwind.config.js
/** @type {import('tailwindcss').Config} */
module.exports = {
  darkMode: 'class',
  content: [
    './index.html',
    './src/**/*.{js,ts,jsx,tsx}',
    './stories/**/*.{js,jsx,ts,tsx,mdx}'
  ],
  theme: {
    extend: {
      colors: {
        copper: { DEFAULT: '#B87333', dark: '#8D5A22' },
        bronze: { DEFAULT: '#CD7F32', dark: '#A85C28' },
        gold:   { DEFAULT: '#D4AF37', dark: '#A67C27' },
        ivory:  { DEFAULT: '#FFFFF0', dark: '#ECECEC' },
      },
      fontFamily: {
        special: ['"Special Elite"', 'cursive'],
        arbutus: ['"Arbutus Slab"', 'serif'],
        cinzel:  ['Cinzel', 'serif'],
      },
      // 1) Increase base font size to make text larger
      fontSize: {
        base: '18px'
      },
    },
  },
  plugins: [],
};
EOF

#############################################
# 11. Global CSS (Tailwind + steampunk styles)
#############################################
echo "Writing src/index.css..."
cat <<'EOF' > src/index.css
/* src/index.css */

/* Global custom styles */
:root {
  line-height: 1.5;
  font-weight: 400;
  color-scheme: light dark;
  color: rgba(255, 255, 255, 0.87);
  background-color: #242424;
  font-synthesis: none;
  text-rendering: optimizeLegibility;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

/* Load Tailwind */
@import './tailwind.css';

/* Enforce the Special Elite font */
.font-special {
  font-family: "Special Elite", cursive !important;
}

/* Steampunk gradient for headers */
.steampunk-gradient {
  background: linear-gradient(
    90deg,
    #B87333 0%,
    #CD7F32 33%,
    #D4AF37 66%,
    #FFFFF0 100%
  );
  -webkit-background-clip: text;
  color: transparent;
}

a {
  font-weight: 500;
  color: #646cff;
  text-decoration: inherit;
}
a:hover {
  color: #535bf2;
}

body {
  margin: 0;
  display: flex;
  place-items: center;
  min-width: 320px;
  min-height: 100vh;
}

h1 {
  font-size: 3.2em;
  line-height: 1.1;
}

.logo.react {
  animation: logo-spin 20s linear infinite;
}
.logo.react:hover {
  animation-direction: reverse;
}

@keyframes logo-spin {
  from { transform: rotate(0deg); }
  to { transform: rotate(360deg); }
}
EOF

#############################################
# 12. Insert <link> in index.html for "Special Elite" & set <title> to $APP_NAME
#############################################
if [[ -f index.html ]]; then
  sed -i '/<title>.*<\/title>/d' index.html
  tmpfile=$(mktemp)
  cat <<EOF > "$tmpfile"
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Special+Elite&display=swap" rel="stylesheet">
<title>$APP_NAME</title>
EOF
  sed -i '/<head>/r '"$tmpfile" index.html
  rm "$tmpfile"

  # 2) Force dark mode by default: add class="dark" to <html> 
  sed -i 's#<html>#<html class="dark">#' index.html
else
  echo "WARNING: index.html not found. Could not insert Google Fonts link or set <title> to $APP_NAME."
fi

#############################################
# 13. App.tsx with gradient header
#############################################
echo "Writing src/App.tsx..."
cat <<'EOF' > src/App.tsx
// src/App.tsx
import { useState } from "react";
import reactLogo from "./assets/react.svg";
import viteLogo from "/vite.svg";
import "./App.css";
import "./index.css";

function App() {
  const [count, setCount] = useState(0);

  return (
    <>
      <div className="bg-copper dark:bg-copper-dark p-6 flex flex-col items-center justify-center text-center">
        <h1 className="text-4xl font-special steampunk-gradient">
          Steampunk Vite App
        </h1>
        <p className="mt-4 text-gold dark:text-gold-dark">
          Using Arbutus Slab → <span className="font-arbutus">Hello</span>
        </p>
        <p className="mt-4 text-bronze dark:text-bronze-dark">
          Using Cinzel → <span className="font-cinzel">Classical vibes</span>
        </p>
        <div className="flex items-center justify-center gap-6 mt-6">
          <a href="https://vite.dev" target="_blank">
            <img src={viteLogo} className="logo" alt="Vite logo" />
          </a>
          <a href="https://react.dev" target="_blank">
            <img src={reactLogo} className="logo react" alt="React logo" />
          </a>
        </div>
      </div>
      <h1>Vite + React</h1>
      <div className="card">
        <button onClick={() => setCount((count) => count + 1)}>
          count is {count}
        </button>
        <p>
          Edit <code>src/App.tsx</code> and save to test HMR
        </p>
      </div>
      <p className="read-the-docs">
        Click on the Vite and React logos to learn more
      </p>
    </>
  );
}

export default App;
EOF

#############################################
# 14. Initialize Git, commit, create remote repo
#############################################
echo "Initializing Git repository..."
git init

echo "Adding all files to Git..."
git add .
echo "Committing initial code..."
git commit -m "Initial commit"
git branch -M main

echo "Creating new GitHub repo via gh CLI (public) and pushing code..."
gh repo create "$GITHUB_ACCOUNT/$APP_NAME" --public --source=. --remote=origin --push

#############################################
# 15. Update package.json for GitHub Pages & deploy
#############################################
echo "Updating package.json scripts for GitHub Pages deployment..."
node -e "let pkg=require('./package.json'); pkg.scripts.predeploy='npm run build'; pkg.scripts.deploy='gh-pages -d dist'; require('fs').writeFileSync('package.json', JSON.stringify(pkg, null, 2));"

echo "Deploying to GitHub Pages..."
npm run deploy

REPO_URL="https://github.com/$GITHUB_ACCOUNT/$APP_NAME"
DEPLOYED_URL="https://$GITHUB_ACCOUNT.github.io/$APP_NAME/"

echo ""
echo "============================================================"
echo "GitHub Repository: $REPO_URL"
echo "Deployed GitHub Pages: $DEPLOYED_URL"
echo "============================================================"
echo ""

#############################################
# 17. Initialize Storybook
#############################################
echo "Initializing Storybook with Vite builder..."
yes | npx storybook@latest init --builder=vite

echo "Writing .storybook/preview.ts..."
cat <<'EOF' > .storybook/preview.ts
import '../src/tailwind.css';
import '../src/index.css';

export const parameters = {
  actions: { argTypesRegex: "^on[A-Z].*" },
  controls: { matchers: { color: /(background|color)$/i, date: /Date$/ } },
};
EOF

echo "Writing .storybook/main.js to override Vite base..."
mkdir -p .storybook
cat <<'EOF' > .storybook/main.js
module.exports = {
  stories: ['../src/**/*.stories.@(js|jsx|ts|tsx)'],
  addons: [
    '@storybook/addon-links',
    '@storybook/addon-essentials'
  ],
  core: {
    builder: 'storybook-builder-vite'
  },
  viteFinal: async (config, { configType }) => {
    config.base = '/';
    return config;
  },
};
EOF

#############################################
# 18. Confirm Git status and auto-launch Storybook
#############################################
echo "Confirming Git status..."
git status

echo "Git repository looks good. Auto-launching Storybook..."
npm run storybook

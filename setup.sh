#!/bin/bash
set -e  # Exit immediately if any command fails

# -----------------------------------------------------------------------------
# This script automates the setup for a Steampunk Vite + React + Tailwind project.
# It now reads the application name and GitHub account name from an .env file.
#
# Prerequisite:
# 1. Create an .env file in the same directory with the following content:
#      APP_NAME=steampunk-react-app
#      GITHUB_ACCOUNT=TortoiseWolfe
#
# The script will:
#   - Source APP_NAME and GITHUB_ACCOUNT from .env.
#   - Scaffold a new Vite project with React and TypeScript using the app name.
#   - Install Tailwind CSS, Storybook, gh-pages, and Prettier.
#   - Configure Vite, Tailwind, and global CSS (including steampunk styling and reverse logo rotation).
#   - Initialize Storybook with Tailwind.
#   - Update package.json for GitHub Pages deployment.
#   - Initialize a Git repository, add a remote using the provided GitHub account, commit, and push.
#
# IMPORTANT: Review automated changes to maintain the integrity of your existing system
# and adhere to your established codebase standards.
# -----------------------------------------------------------------------------

# Check if .env file exists
if [ ! -f .env ]; then
  echo ".env file not found! Please create an .env file with APP_NAME and GITHUB_ACCOUNT defined (e.g., APP_NAME=steampunk-react-app and GITHUB_ACCOUNT=TortoiseWolfe)."
  exit 1
fi

# Source the .env file to load APP_NAME and GITHUB_ACCOUNT
set -a
source .env
set +a

if [ -z "$APP_NAME" ]; then
  echo "APP_NAME variable is not set in .env file."
  exit 1
fi

if [ -z "$GITHUB_ACCOUNT" ]; then
  echo "GITHUB_ACCOUNT variable is not set in .env file."
  exit 1
fi

echo "Using application name: $APP_NAME"
echo "Using GitHub account: $GITHUB_ACCOUNT"

# -----------------------------------------------------------------------------
# 1. Create & Scaffold the Project
# -----------------------------------------------------------------------------
echo "Creating Vite + React project..."
npm create vite@latest "$APP_NAME" -- --template react-ts

cd "$APP_NAME"

echo "Installing project dependencies..."
npm install

# -----------------------------------------------------------------------------
# 2. Install Dependencies
# -----------------------------------------------------------------------------
echo "Installing additional dev dependencies (Tailwind, Storybook support, gh-pages, Prettier)..."
npm install -D tailwindcss @tailwindcss/vite gh-pages prettier

# -----------------------------------------------------------------------------
# 3. Configure Vite & Tailwind
# -----------------------------------------------------------------------------
echo "Setting up vite.config.ts..."
cat <<EOF > vite.config.ts
// vite.config.ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import tailwind from '@tailwindcss/vite';

export default defineConfig({
  base: '/$APP_NAME/', // Use '/' for user/organization sites.
  plugins: [react(), tailwind()],
});
EOF

echo "Setting up tailwind.config.js..."
cat <<EOF > tailwind.config.js
// tailwind.config.js
/** @type {import('tailwindcss').Config} */
export default {
  darkMode: 'class', // Enable class-based dark mode
  content: [
    './index.html',
    './src/**/*.{js,ts,jsx,tsx}',
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
    },
  },
  plugins: [],
};
EOF

# -----------------------------------------------------------------------------
# 4. Set Up Tailwind & Custom CSS
# -----------------------------------------------------------------------------
echo "Setting up src/index.css with Tailwind and custom steampunk styles..."
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
@tailwind base;
@tailwind components;
@tailwind utilities;

/* Force Tailwind font utilities to override global settings */
.font-special {
  font-family: "Special Elite", cursive !important;
}
.font-arbutus {
  font-family: "Arbutus Slab", serif !important;
}
.font-cinzel {
  font-family: "Cinzel", serif !important;
}

/* Keep all original styles */
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

/* Reverse rotation on hover for React logo */
.logo.react {
  animation: logo-spin 20s linear infinite;
  transition: transform 0.5s linear;
}

.logo.react:hover {
  animation: none;
  transform: rotate(calc(var(--rotation) * -1deg));
}

@keyframes logo-spin {
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
}
EOF

# -----------------------------------------------------------------------------
# 5. Install & Configure Storybook
# -----------------------------------------------------------------------------
echo "Initializing Storybook with Vite builder..."
npx storybook@latest init --builder=vite

echo "Configuring Storybook to use Tailwind CSS..."
cat <<'EOF' > .storybook/preview.js
import '../src/index.css';

export const parameters = {
  actions: { argTypesRegex: "^on[A-Z].*" },
  controls: { matchers: { color: /(background|color)$/i, date: /Date$/ } },
};
EOF

# -----------------------------------------------------------------------------
# 6. Install & Configure GitHub Pages Deployment
# -----------------------------------------------------------------------------
echo "Updating package.json scripts for GitHub Pages deployment..."
node -e "let pkg=require('./package.json'); pkg.scripts.predeploy='npm run build'; pkg.scripts.deploy='gh-pages -d dist'; require('fs').writeFileSync('package.json', JSON.stringify(pkg, null, 2));"

echo "Initializing Git repository and making initial commit..."
git init
git add .
git commit -m 'Initial commit'
git branch -M main

echo "Adding remote repository..."
git remote add origin https://github.com/$GITHUB_ACCOUNT/$APP_NAME.git
git push -u origin main

echo "Deploying to GitHub Pages..."
npm run deploy

echo "Setup complete! Your project has been configured with:"
echo "  - A fully functional Vite + React + Tailwind setup with a steampunk theme"
echo "  - A reverse-rotating React logo on hover"
echo "  - Storybook integration for component development"
echo "  - GitHub Pages deployment configuration using the GitHub account: $GITHUB_ACCOUNT"
echo ""
echo "Reminder: Always review automated changes to maintain the integrity of your existing system and adhere to established codebase standards."

#!/bin/bash
set -euo pipefail

#region Header - Script Information
#############################################
# Steampunk Vite + React + Tailwind Setup Script
# - Overwrites steampunk_setup.log on each run
# - Creates a new GitHub repo (via gh CLI).
# - Deploys to GitHub Pages, printing a clear link.
# - Configures Storybook using PostCSS for Tailwind.
# - Uses .env for APP_NAME, GITHUB_ACCOUNT, and STEAMPUNK_* variables.
# - Correctly expands env variables (no literal $APP_NAME in final output!).
# - Creates custom Storybook stories for Button, Card, Header, NavList, UnorderedList, and Link.
# - Auto-launches Storybook.
#############################################
#endregion Header - Script Information

#region 0. Initialize Logging
rm -f steampunk_setup.log
exec > >(tee steampunk_setup.log) 2>&1
set -x
#endregion 0. Initialize Logging

#region 0.5 Initialize SSH Agent and Add SSH Key
if [ -z "${SSH_AUTH_SOCK:-}" ]; then
  echo "Starting ssh-agent..."
  eval "$(ssh-agent -s)"
fi
if [ -f "$HOME/.ssh/id_rsa" ]; then
  echo "Adding SSH key..."
  ssh-add "$HOME/.ssh/id_rsa"
else
  echo "WARNING: SSH key not found at $HOME/.ssh/id_rsa."
  echo "Please add your SSH key for passwordless Git operations."
fi
#endregion 0.5 Initialize SSH Agent and Add SSH Key

#region 1. Check GH CLI installation & authentication
if ! command -v gh &> /dev/null; then
  echo "ERROR: GitHub CLI (gh) is not installed or not in PATH."
  exit 1
fi
if ! gh auth status &> /dev/null; then
  echo "ERROR: GitHub CLI is installed but you're not authenticated."
  echo "Run 'gh auth login' and follow prompts, then re-run this script."
  exit 1
fi
#endregion 1. Check GH CLI installation & authentication

#region 2. Load environment variables from .env
if [ ! -f .env ]; then
  echo "ERROR: .env file not found!"
  echo "Please create a .env file with APP_NAME, GITHUB_ACCOUNT, and STEAMPUNK_* variables."
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
#endregion 2. Load environment variables from .env

#region 3. If current directory is a Git repo, move up one directory
if [ -d ".git" ]; then
  echo "Detected .git folder here. Moving up one directory..."
  cd ..
fi
#endregion 3. If current directory is a Git repo, move up one directory

#region 4. Create new project folder
if [ -d "$APP_NAME" ]; then
  echo "ERROR: Directory '$APP_NAME' already exists. Aborting."
  exit 1
fi
echo "Creating Vite + React (TypeScript) project: $APP_NAME"
npm create vite@latest "$APP_NAME" -- --template react-ts
cd "$APP_NAME"
#endregion 4. Create new project folder

#region 5. Create blank files
echo "Creating blank files: scaffolding.sh and components.txt..."
touch scaffolding.sh
touch components.txt
#endregion 5. Create blank files

#region 6. Install project dependencies
echo "Installing project dependencies..."
npm install
#endregion 6. Install project dependencies

#region 7. Install additional dev dependencies
echo "Installing dev dependencies: Tailwind, PostCSS, Autoprefixer, @tailwindcss/postcss, gh-pages, Prettier..."
npm install -D tailwindcss postcss autoprefixer @tailwindcss/postcss gh-pages prettier
#endregion 7. Install additional dev dependencies

#region 8. Create PostCSS config
cat <<'EOF' > postcss.config.cjs
module.exports = {
  plugins: {
    '@tailwindcss/postcss': {},
    autoprefixer: {},
  },
};
EOF
#endregion 8. Create PostCSS config

#region 9. Create Tailwind CSS entry
cat <<'EOF' > src/tailwind.css
@tailwind base;
@tailwind components;
@tailwind utilities;
EOF
#endregion 9. Create Tailwind CSS entry

#
# For configuration files and HTML, we want expansions so that the environment
# variables are replaced with actual values.
#

#region 10. Configure Vite and Tailwind (with expansions)
echo "Writing vite.config.ts..."
cat <<EOF > vite.config.ts
// vite.config.ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  base: '/${APP_NAME}/',
  plugins: [react()],
});
EOF

echo "Writing tailwind.config.js..."
cat <<EOF > tailwind.config.js
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
        copper: { DEFAULT: "${STEAMPUNK_COLOR_PRIMARY}", dark: "#A85C22" },
        bronze: { DEFAULT: "${STEAMPUNK_COLOR_SECONDARY}", dark: "#A85C28" },
        gold:   { DEFAULT: "${STEAMPUNK_COLOR_TERTIARY}",  dark: "#A67C27" },
        ivory:  { DEFAULT: "${STEAMPUNK_COLOR_IVORY}",     dark: "${STEAMPUNK_COLOR_IVORY_DARK}" },
      },
      fontFamily: {
        special: ["${STEAMPUNK_FONT_PRIMARY}", "cursive"],
        arbutus: ["${STEAMPUNK_FONT_SECONDARY}", "serif"],
        cinzel:  ["${STEAMPUNK_FONT_TERTIARY}", "serif"],
      },
      fontSize: {
        base: '18px'
      },
    },
  },
  plugins: [],
};
EOF
#endregion 10. Configure Vite and Tailwind

#region 11. Global CSS (with expansions)
echo "Writing src/index.css..."
cat <<EOF > src/index.css
@import './tailwind.css';
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

/* Enforce the primary font */
.font-special {
  font-family: "${STEAMPUNK_FONT_PRIMARY}", cursive !important;
}

/* Enforce the secondary font */
.font-arbutus {
  font-family: "${STEAMPUNK_FONT_SECONDARY}", serif !important;
}

/* Enforce the tertiary font */
.font-cinzel {
  font-family: "${STEAMPUNK_FONT_TERTIARY}", serif !important;
}

/* Steampunk gradient for headers */
.steampunk-gradient {
  background: linear-gradient(
    90deg,
    ${STEAMPUNK_COLOR_PRIMARY} 0%,
    ${STEAMPUNK_COLOR_SECONDARY} 33%,
    ${STEAMPUNK_COLOR_TERTIARY} 66%,
    ${STEAMPUNK_COLOR_IVORY} 100%
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
#endregion 11. Global CSS

#region 12. Insert Google Fonts links and update index.html (with expansions)
if [[ -f index.html ]]; then
  sed -i '/<title>.*<\/title>/d' index.html
  tmpfile=$(mktemp)
  cat <<EOF > "$tmpfile"
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Special+Elite&display=swap" rel="stylesheet">
<link href="https://fonts.googleapis.com/css2?family=Arbutus+Slab&display=swap" rel="stylesheet">
<link href="https://fonts.googleapis.com/css2?family=Cinzel&display=swap" rel="stylesheet">
<title>${APP_NAME}</title>
EOF
  sed -i '/<head>/r '"$tmpfile" index.html
  rm "$tmpfile"
  sed -i 's#<html>#<html class="dark">#' index.html
else
  echo "WARNING: index.html not found. Could not insert Google Fonts or set <title>."
fi
#endregion 12. Insert Google Fonts links

#
# For code files (TSX), we want no expansions so we use quoted heredocs.
#

#region 13. Configure App.tsx (use unquoted heredoc for expansion of repo URL)
echo "Writing src/App.tsx..."
cat <<EOF > src/App.tsx
// src/App.tsx
import { useState } from "react";
import reactLogo from "./assets/react.svg";
import viteLogo from "/vite.svg";
import { NavList } from "./components/ui/NavList";
import { UnorderedList } from "./components/ui/UnorderedList";
import { Link } from "./components/ui/Link";
import "./App.css";
import "./index.css";

function App() {
  const [count, setCount] = useState(0);
  const [activeNav, setActiveNav] = useState(0);
  const [activeUnordered, setActiveUnordered] = useState(0);
  const navItems = ["Home", "About", "Services", "Contact"];
  const unorderedItems = ["Item 1", "Item 2", "Item 3", "Item 4"];
  const repoUrl = "https://github.com/${GITHUB_ACCOUNT}/${APP_NAME}";

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
        {/* Render NavList with active item highlighting */}
        <NavList items={navItems} activeIndex={activeNav} onItemClick={(i) => setActiveNav(i)} />
        {/* Render UnorderedList with selected item highlighting */}
        <UnorderedList items={unorderedItems} activeIndex={activeUnordered} onItemClick={(i) => setActiveUnordered(i)} />
        <div className="mt-4">
          <Link href={repoUrl}>View Repository on GitHub</Link>
        </div>
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
#endregion 13. Configure App.tsx

#region 13.5 Scaffold Steampunk Components (no expansions)
echo "Scaffolding steampunk-styled components..."
mkdir -p src/components/{common,layout,ui}

# Button.tsx
cat <<'EOF' > src/components/ui/Button.tsx
import React from 'react';

interface ButtonProps {
  children: React.ReactNode;
  variant?: 'primary' | 'secondary' | 'ghost';
  size?: 'sm' | 'md' | 'lg';
  onClick?: () => void;
  disabled?: boolean;
}

export const Button: React.FC<ButtonProps> = ({
  children,
  variant = 'primary',
  size = 'md',
  onClick,
  disabled = false,
}) => {
  const baseStyles =
    'font-cinzel rounded-md transition-all duration-200 border-2 flex items-center justify-center';
  const variantStyles = {
    primary:
      'bg-bronze text-ivory border-bronze-dark hover:bg-bronze-dark disabled:bg-bronze/50',
    secondary:
      'bg-transparent text-gold border-gold hover:bg-gold/10 disabled:text-gold/50',
    ghost:
      'bg-transparent text-copper border-transparent hover:text-copper-dark disabled:text-copper/50',
  };
  const sizeStyles = {
    sm: 'px-3 py-1 text-sm',
    md: 'px-4 py-2 text-base',
    lg: 'px-6 py-3 text-lg',
  };

  return (
    <button
      className={`${baseStyles} ${variantStyles[variant]} ${sizeStyles[size]}`}
      onClick={onClick}
      disabled={disabled}
    >
      {children}
    </button>
  );
};
EOF

# Card.tsx
cat <<'EOF' > src/components/common/Card.tsx
import React from 'react';

interface CardProps {
  children: React.ReactNode;
  title?: string;
}

export const Card: React.FC<CardProps> = ({ children, title }) => {
  return (
    <div className="bg-ivory/10 border-2 border-copper rounded-lg p-6 shadow-lg">
      {title && (
        <h2 className="text-2xl font-special text-gold steampunk-gradient mb-4">
          {title}
        </h2>
      )}
      <div className="text-ivory font-arbutus">{children}</div>
    </div>
  );
};
EOF

# Header.tsx
cat <<'EOF' > src/components/layout/Header.tsx
import React from 'react';

interface HeaderProps {
  title: string;
}

export const Header: React.FC<HeaderProps> = ({ title }) => {
  return (
    <header className="bg-copper dark:bg-copper-dark py-4 px-6">
      <h1 className="text-3xl font-special steampunk-gradient text-center">
        {title}
      </h1>
    </header>
  );
};
EOF

# Link.tsx
mkdir -p src/components/ui
cat <<'EOF' > src/components/ui/Link.tsx
import React from 'react';

interface LinkProps {
  href: string;
  children: React.ReactNode;
}

export const Link: React.FC<LinkProps> = ({ href, children }) => {
  return (
    <a href={href} className="text-blue-500 hover:underline" target="_blank" rel="noopener noreferrer">
      {children}
    </a>
  );
};
EOF
#endregion 13.5 Scaffold Steampunk Components

#region 13.6 Create Custom Stories for Components
echo "Creating custom Storybook stories for Button, Card, Header, and Link..."

# Button.stories.tsx
mkdir -p src/components/ui
cat <<'EOF' > src/components/ui/Button.stories.tsx
import { Button } from './Button';

export default {
  title: 'Components/Button',
  component: Button,
};

export const Primary = () => <Button variant="primary">Primary Button</Button>;
export const Secondary = () => <Button variant="secondary">Secondary Button</Button>;
export const Ghost = () => <Button variant="ghost">Ghost Button</Button>;
EOF

# Card.stories.tsx
mkdir -p src/components/common
cat <<'EOF' > src/components/common/Card.stories.tsx
import { Card } from './Card';

export default {
  title: 'Components/Card',
  component: Card,
};

export const DefaultCard = () => (
  <Card title="Card Title">
    <p>This is some card content.</p>
  </Card>
);
EOF

# Header.stories.tsx
mkdir -p src/components/layout
cat <<'EOF' > src/components/layout/Header.stories.tsx
import { Header } from './Header';

export default {
  title: 'Components/Header',
  component: Header,
};

export const DefaultHeader = () => <Header title="Steampunk Header" />;
EOF

# Link.stories.tsx
mkdir -p src/components/ui
cat <<'EOF' > src/components/ui/Link.stories.tsx
import { Link } from './Link';

export default {
  title: 'Components/Link',
  component: Link,
};

export const DefaultLink = () => <Link href="https://github.com/TortoiseWolfe/retro-futurism-react-app">View Repository on GitHub</Link>;
EOF
#endregion 13.6 Create Custom Stories for Components

#region 13.7 Scaffold Additional Custom Component: NavList
echo "Scaffolding additional custom component: NavList..."

mkdir -p src/components/ui
cat <<'EOF' > src/components/ui/NavList.tsx
import React from 'react';

interface NavListProps {
  items: string[];
  activeIndex: number;
  onItemClick?: (index: number) => void;
}

export const NavList: React.FC<NavListProps> = ({ items, activeIndex, onItemClick }) => {
  return (
    <ul className="list-disc pl-5">
      {items.map((item, index) => (
        <li
          key={index}
          className={`cursor-pointer ${index === activeIndex ? 'text-gold font-bold' : 'text-ivory'}`}
          onClick={() => onItemClick && onItemClick(index)}
        >
          {item}
        </li>
      ))}
    </ul>
  );
};
EOF
#endregion 13.7 Scaffold Additional Custom Component: NavList

#region 13.8 Create Custom Story for NavList
echo "Creating custom Storybook story for NavList..."

mkdir -p src/components/ui
cat <<'EOF' > src/components/ui/NavList.stories.tsx
import { NavList } from './NavList';

export default {
  title: 'Components/NavList',
  component: NavList,
};

export const DefaultNavList = () => {
  const items = ['Home', 'About', 'Services', 'Contact'];
  return <NavList items={items} activeIndex={0} onItemClick={(index) => alert('Clicked item ' + index)} />;
};
EOF
#endregion 13.8 Create Custom Story for NavList

#region 13.9 Scaffold Additional Custom Component: UnorderedList
echo "Scaffolding additional custom component: UnorderedList..."

mkdir -p src/components/ui
cat <<'EOF' > src/components/ui/UnorderedList.tsx
import React from 'react';

interface UnorderedListProps {
  items: string[];
  activeIndex: number;
  onItemClick?: (index: number) => void;
}

export const UnorderedList: React.FC<UnorderedListProps> = ({ items, activeIndex, onItemClick }) => {
  return (
    <ul className="list-disc pl-5">
      {items.map((item, index) => (
        <li
          key={index}
          className={`cursor-pointer ${index === activeIndex ? 'text-gold font-bold' : 'text-ivory'}`}
          onClick={() => onItemClick && onItemClick(index)}
        >
          {item}
        </li>
      ))}
    </ul>
  );
};
EOF
#endregion 13.9 Scaffold Additional Custom Component: UnorderedList

#region 13.10 Create Custom Story for UnorderedList
echo "Creating custom Storybook story for UnorderedList..."

mkdir -p src/components/ui
cat <<'EOF' > src/components/ui/UnorderedList.stories.tsx
import { UnorderedList } from './UnorderedList';

export default {
  title: 'Components/UnorderedList',
  component: UnorderedList,
};

export const DefaultUnorderedList = () => {
  const items = ['Item 1', 'Item 2', 'Item 3', 'Item 4'];
  return <UnorderedList items={items} activeIndex={1} onItemClick={(index) => alert('Clicked item ' + index)} />;
};
EOF
#endregion 13.10 Create Custom Story for UnorderedList

#region 14. Initialize Git, commit, create remote repo
echo "Initializing Git repository..."
git init
echo "Adding all files to Git..."
git add .
echo "Committing initial code..."
git commit -m "Initial commit"
git branch -M main
echo "Creating new GitHub repo via gh CLI (public) and pushing code..."
gh repo create "$GITHUB_ACCOUNT/$APP_NAME" --public --source=. --remote=origin --push
#endregion 14. Initialize Git, commit, create remote repo

#region 15. Update package.json for GitHub Pages & deploy
echo "Updating package.json scripts for GitHub Pages deployment..."
node -e "
let pkg=require('./package.json');
pkg.scripts.predeploy='npm run build';
pkg.scripts.deploy='gh-pages -d dist -f';
require('fs').writeFileSync('package.json', JSON.stringify(pkg, null, 2));
"
echo "Deploying to GitHub Pages..."
npm run deploy
REPO_URL="https://github.com/$GITHUB_ACCOUNT/$APP_NAME"
DEPLOYED_URL="https://$GITHUB_ACCOUNT.github.io/$APP_NAME/"
echo ""
echo "========================================"
echo "GitHub Repository: $REPO_URL"
echo "Deployed GitHub Pages: $DEPLOYED_URL"
echo "========================================"
echo ""
#endregion 15. Update package.json for GitHub Pages & deploy

#region 17. Initialize Storybook
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
echo "Writing .storybook/main.js..."
cat <<'EOF' > .storybook/main.js
module.exports = {
  stories: ['../src/**/*.stories.@(js|jsx,ts,tsx)'],
  addons: [
    '@storybook/addon-links',
    '@storybook/addon-essentials'
  ],
  core: { builder: 'storybook-builder-vite' },
  viteFinal: async (config, { configType }) => {
    config.base = '/';
    return config;
  },
};
EOF
#endregion 17. Initialize Storybook

#region 18. Confirm Git status and auto-launch Storybook
echo "Confirming Git status..."
git status
echo "Git repository looks good. Auto-launching Storybook..."
npm run storybook &
#endregion 18. Confirm Git status and auto-launch Storybook

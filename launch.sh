GREEN='\033[0;32m'
PINK='\033[1;35m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo -e "${CYAN}=======================================================${NC}"
    echo -e "${CYAN}  🚀  $1 ${NC}"
    echo -e "${CYAN}=======================================================${NC}"
}

spinner() {
    local pid=$1
    local msg=$2
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    while kill -0 $pid 2>/dev/null
    do
        i=$(( (i+1) % ${#spin} ))
        printf "\r${CYAN}%c${NC} ${msg}" "${spin:$i:1}"
        sleep 0.1
    done
    printf "\r%*s\r" $((${#msg}+5)) ""
}

if [ "$1" == "component" ] || [ "$1" == "page" ]; then
    SCAFFOLD_TYPE=$1
    ITEM_NAME=$2

    if [ -z "$ITEM_NAME" ]; then
        echo -e "${PINK}❌ Erro: Você precisa fornecer um nome para o ${SCAFFOLD_TYPE}.${NC}"
        echo "Uso: bash launch.sh ${SCAFFOLD_TYPE} NomeDoItem"
        exit 1
    fi

    if [ -f "tsconfig.json" ]; then
        EXT="tsx"
        STYLE_EXT="ts"
    else
        EXT="jsx"
        STYLE_EXT="js"
    fi

    if [ "$SCAFFOLD_TYPE" == "component" ]; then
        TARGET_DIR="src/components"
    else
        TARGET_DIR="src/pages"
    fi
    
    if [ "$SCAFFOLD_TYPE" == "page" ] && [ ! -d "src/pages" ]; then
        echo -e "${PINK}❌ Erro: O comando 'page' só está disponível em projetos com o padrão Router.${NC}"
        echo -e "${PINK}Para este projeto, utilize o comando: 'launch.sh component NomeDoSeuComponente'${NC}"
        exit 1
    fi

    if [ ! -d "$TARGET_DIR" ]; then
        echo -e "${PINK}❌ Erro: A pasta '${TARGET_DIR}' não foi encontrada.${NC}"
        echo "Rode este comando na raiz de um projeto existente."
        exit 1
    fi

    ITEM_PATH="${TARGET_DIR}/${ITEM_NAME}"
    mkdir -p "$ITEM_PATH"

    if [ "$SCAFFOLD_TYPE" == "component" ]; then
        cat <<EOF > "${ITEM_PATH}/index.${EXT}"
import React from 'react';
import * as S from './styles';

interface ${ITEM_NAME}Props {
  titulo?: string;
}

const ${ITEM_NAME}: React.FC<${ITEM_NAME}Props> = ({ titulo = "Componente Padrão" }) => {
  return (
    <S.Wrapper>
      <S.Titulo>${ITEM_NAME}</S.Titulo>
      <S.Descricao>Este é um componente com estilos separados.</S.Descricao>
    </S.Wrapper>
  );
};

export default ${ITEM_NAME};
EOF

        cat <<EOF > "${ITEM_PATH}/styles.${STYLE_EXT}"
import styled from 'styled-components';

export const Wrapper = styled.div\`
  background-color: #f0f0f0;
  padding: 2rem;
  border-radius: 8px;
  border: 1px solid #ccc;
  text-align: center;
\`;

export const Titulo = styled.h1\`
  color: #333;
  font-size: 1.5rem;
  margin: 0;
\`;

export const Descricao = styled.p\`
  color: #666;
  font-size: 1rem;
\`;
EOF
        echo -e "${GREEN}✅ Componente '${ITEM_NAME}' criado com sucesso em '${ITEM_PATH}'${NC}"
    else 
        cat <<EOF > "${ITEM_PATH}/index.${EXT}"
import React from 'react';
import * as S from './styles';
import Footer from '../../components/Footer';

const ${ITEM_NAME} = () => {
  return (
    <>
      <main>
        <S.Container>
          <S.Title>${ITEM_NAME}</S.Title>
          <S.Content>Esta é a página ${ITEM_NAME}.</S.Content>
        </S.Container>
      </main>
      <Footer />
    </>
  );
};

export default ${ITEM_NAME};
EOF

        cat <<EOF > "${ITEM_PATH}/styles.${STYLE_EXT}"
import styled from 'styled-components';

export const Container = styled.div\`
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 4rem 2rem;
\`;

export const Title = styled.h1\`
  font-size: 2.5rem;
  color: var(--accent-color);
  margin-bottom: 2rem;
\`;

export const Content = styled.p\`
  font-size: 1.1rem;
  line-height: 1.8;
  text-align: center;
\`;
EOF
        echo -e "${GREEN}✅ Página '${ITEM_NAME}' criada em '${ITEM_PATH}'${NC}"

        ENTRY_POINT=""
        if [ -f "src/main.tsx" ]; then ENTRY_POINT="src/main.tsx"; fi
        if [ -f "src/main.jsx" ]; then ENTRY_POINT="src/main.jsx"; fi
        if [ -f "src/index.tsx" ]; then ENTRY_POINT="src/index.tsx"; fi
        if [ -f "src/index.js" ]; then ENTRY_POINT="src/index.js"; fi
        
        if [ -n "$ENTRY_POINT" ]; then
            PAGE_NAME=$ITEM_NAME
            PAGE_PATH_LOWER=$(echo "$PAGE_NAME" | tr '[:upper:]' '[:lower:]')
            
            NEW_IMPORT="import ${PAGE_NAME} from './pages/${PAGE_NAME}';"
            awk -v new_import="$NEW_IMPORT" '
            {
              if ($0 ~ /^import /) {
                last_import_line = NR
              }
              lines[NR] = $0
            }
            END {
              for (i=1; i<=NR; i++) {
                print lines[i]
                if (i == last_import_line) {
                  print new_import
                }
              }
            }' "$ENTRY_POINT" > "${ENTRY_POINT}.tmp" && mv "${ENTRY_POINT}.tmp" "$ENTRY_POINT"
            
            NEW_ROUTE="  {\n    path: '/${PAGE_PATH_LOWER}',\n    element: <${PAGE_NAME} />,\n    errorElement: <div>Página não encontrada!</div>,\n  },"
            awk -v new_route="$NEW_ROUTE" '
            /createBrowserRouter\(\[/ {
              print;
              print new_route;
              next
            }
            { print }
            ' "$ENTRY_POINT" > "${ENTRY_POINT}.tmp" && mv "${ENTRY_POINT}.tmp" "$ENTRY_POINT"

            echo -e "${GREEN}✅ Rota para ${ITEM_NAME} adicionada em ${ENTRY_POINT}${NC}"
        fi
    fi
    exit 0
fi

PROJECT_NAME=$1
if [ -z "$PROJECT_NAME" ]; then
  read -p "Qual o nome do seu projeto? (ex: meu-app-incrivel) " PROJECT_NAME
fi

if [ -z "$PROJECT_NAME" ]; then
  echo -e "${PINK}❌ Nome do projeto não pode ser vazio.${NC}"
  exit 1
fi

PROJECT_NAME_LOWER=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]')

print_header "Escolha sua ferramenta de build"
PS3="Sua escolha: "
select tool in "Vite (Recomendado)" "Create React App"; do
    case $REPLY in
        1) TOOL_CHOICE="vite"; break;;
        2) TOOL_CHOICE="cra"; break;;
        *) echo "Opção inválida. Tente novamente.";;
    esac
done

print_header "JavaScript ou TypeScript?"
PS3="Sua escolha: "
select lang in "JavaScript" "TypeScript (Recomendado)"; do
    case $REPLY in
        1) LANG_CHOICE="js"; break;;
        2) LANG_CHOICE="ts"; break;;
        *) echo "Opção inválida. Tente novamente.";;
    esac
done

print_header "Qual padrão de projeto você prefere?"
PS3="Sua escolha: "
select pattern_choice in "Landing Page (Aplicação de página única)" "Router (Múltiplas páginas)"; do
    case $REPLY in
        1) PROJECT_PATTERN="landingpage"; break;;
        2) PROJECT_PATTERN="router"; break;;
        *) echo "Opção inválida. Tente novamente.";;
    esac
done

print_header "Deseja configurar ESLint e Prettier?"
PS3="Sua escolha: "
select lint_choice in "Sim (Recomendado)" "Não"; do
    case $REPLY in
        1) LINT_SETUP="yes"; break;;
        2) LINT_SETUP="no"; break;;
        *) echo "Opção inválida. Tente novamente.";;
    esac
done

print_header "Deseja criar um arquivo README.md?"
PS3="Sua escolha: "
select readme_choice in "Sim" "Não"; do
    case $REPLY in
        1) README_SETUP="yes"; break;;
        2) README_SETUP="no"; break;;
        *) echo "Opção inválida. Tente novamente.";;
    esac
done

print_header "Deseja criar um arquivo CHANGELOG.md?"
PS3="Sua escolha: "
select changelog_choice in "Sim" "Não"; do
    case $REPLY in
        1) CHANGELOG_SETUP="yes"; break;;
        2) CHANGELOG_SETUP="no"; break;;
        *) echo "Opção inválida. Tente novamente.";;
    esac
done

echo -e "\n${GREEN}✅ Ótimo! Configurando seu projeto '$PROJECT_NAME' com a base Jvmntr...${NC}"
echo -e "   - Ferramenta: ${PINK}$tool${NC}"
echo -e "   - Linguagem:  ${PINK}$lang${NC}"
echo -e "   - Padrão:     ${PINK}${pattern_choice}${NC}"
echo -e "   - Linter:     ${PINK}${lint_choice}${NC}"
echo -e "   - README:     ${PINK}${readme_choice}${NC}"
echo -e "   - CHANGELOG:  ${PINK}${changelog_choice}${NC}\n"

if [ "$LANG_CHOICE" == "ts" ]; then
    EXT="tsx"
    STYLE_EXT="ts"
else
    EXT="jsx"
    STYLE_EXT="js"
fi
MAIN_FILE_EXT=$EXT

print_header "1/8: Criando a estrutura base do projeto..."

if [ "$TOOL_CHOICE" == "vite" ]; then
    if [ "$LANG_CHOICE" == "ts" ]; then
        npm create vite@latest "$PROJECT_NAME_LOWER" -- --template react-ts
    else
        npm create vite@latest "$PROJECT_NAME_LOWER" -- --template react
    fi
else
    if [ "$LANG_CHOICE" == "ts" ]; then
        npx create-react-app "$PROJECT_NAME_LOWER" --template typescript
    else
        npx create-react-app "$PROJECT_NAME_LOWER"
    fi
fi

cd "$PROJECT_NAME_LOWER"

node -e "
  const fs = require('fs');
  const pkgPath = './package.json';
  const pkg = JSON.parse(fs.readFileSync(pkgPath));
  pkg.name = '${PROJECT_NAME_LOWER}';
  fs.writeFileSync(pkgPath, JSON.stringify(pkg, null, 2) + '\n');
"
echo "   - Nome do projeto atualizado em package.json."

print_header "2/8: Instalando dependências..."
npm install styled-components
if [ "$PROJECT_PATTERN" == "router" ]; then
    npm install react-router-dom
fi
if [ "$LANG_CHOICE" == "ts" ]; then
    npm install -D @types/styled-components
fi

if [ "$LINT_SETUP" == "yes" ]; then
    print_header "3/8: Configurando ESLint e Prettier..."
    
    if [ "$LANG_CHOICE" == "ts" ]; then
        npm install -D eslint prettier eslint-plugin-react@latest @typescript-eslint/eslint-plugin@latest @typescript-eslint/parser@latest eslint-plugin-react-hooks eslint-plugin-jsx-a11y eslint-config-prettier eslint-plugin-prettier
    else
        npm install -D eslint prettier eslint-plugin-react@latest eslint-plugin-react-hooks eslint-plugin-jsx-a11y eslint-config-prettier eslint-plugin-prettier
    fi
    echo "   - Dependências de Linter e Formatter instaladas."

    if [ "$LANG_CHOICE" == "ts" ]; then
        cat <<'EOF' > .eslintrc.json
{
  "root": true,
  "env": { "browser": true, "es2021": true, "node": true },
  "extends": [ "eslint:recommended", "plugin:react/recommended", "plugin:react/jsx-runtime", "plugin:@typescript-eslint/recommended", "plugin:react-hooks/recommended", "plugin:jsx-a11y/recommended", "plugin:prettier/recommended" ],
  "parser": "@typescript-eslint/parser",
  "parserOptions": { "ecmaFeatures": { "jsx": true }, "ecmaVersion": "latest", "sourceType": "module" },
  "plugins": ["react", "@typescript-eslint", "jsx-a11y", "prettier"],
  "rules": { "prettier/prettier": "error", "react/prop-types": "off" },
  "settings": { "react": { "version": "detect" } }
}
EOF
    else
        cat <<'EOF' > .eslintrc.json
{
  "root": true,
  "env": { "browser": true, "es2021": true, "node": true },
  "extends": [ "eslint:recommended", "plugin:react/recommended", "plugin:react/jsx-runtime", "plugin:react-hooks/recommended", "plugin:jsx-a11y/recommended", "plugin:prettier/recommended" ],
  "parserOptions": { "ecmaFeatures": { "jsx": true }, "ecmaVersion": "latest", "sourceType": "module" },
  "plugins": ["react", "jsx-a11y", "prettier"],
  "rules": { "prettier/prettier": "error" },
  "settings": { "react": { "version": "detect" } }
}
EOF
    fi
    echo "   - Arquivo '.eslintrc.json' criado."

    cat <<'EOF' > .prettierrc
{ "semi": true, "singleQuote": true, "tabWidth": 2, "trailingComma": "all", "printWidth": 80 }
EOF
    echo "   - Arquivo '.prettierrc' criado."
    
    cat <<'EOF' > .prettierignore
build
dist
node_modules
coverage
EOF
    echo "   - Arquivo '.prettierignore' criado."

    LINT_EXTENSIONS=$([ "$LANG_CHOICE" == "ts" ] && echo "ts,tsx" || echo "js,jsx")
    node -e "
      const fs = require('fs');
      const pkgPath = './package.json';
      const pkg = JSON.parse(fs.readFileSync(pkgPath));
      pkg.scripts = { 
        ...pkg.scripts, 
        'lint': 'eslint . --ext ${LINT_EXTENSIONS} --report-unused-disable-directives --max-warnings 0', 
        'format': 'prettier --write \"src/**/*.{${LINT_EXTENSIONS},css,md}\"' 
      };
      fs.writeFileSync(pkgPath, JSON.stringify(pkg, null, 2) + '\n');
    "
    echo "   - Scripts 'lint' e 'format' adicionados ao package.json."

else
    print_header "3/8: Pulando configuração de Linter/Formatter..."
fi


print_header "4/8: Organizando a estrutura de pastas e arquivos..."

rm -f src/App.css src/logo.svg src/assets/react.svg

mkdir -p src/components src/assets/images
echo "   - Estrutura base de pastas criada."

print_header "5/8: Criando arquivos de template..."

if [ "$README_SETUP" == "yes" ]; then
    cat <<EOF > README.md
<h1 align="center">
  👨🏻‍💻 <br>
  ${PROJECT_NAME}
</h1>

<div align="center">
  <img src="https://img.shields.io/badge/React-20232A?style=for-the-badge&logo=react&logoColor=61DAFB" />
  <img src="https://img.shields.io/badge/TypeScript-007ACC?style=for-the-badge&logo=typescript&logoColor=white" />
  <img src="https://img.shields.io/badge/styled--components-DB7093?style=for-the-badge&logo=styled-components&logoColor=white" />
</div>

<br>

<img src="[Imagem do projeto]" alt="Imagem do projeto">

<h4 align="center">
  <a href="[Seu link aqui]">Clique para visitar o projeto</a>
</h4>

## 💼 Tecnologias utilizadas
- ReactJS;
- Typescript;
- Styled-components;

## ✒️ Feito por:
<img align="left" height="94px" width="94px" alt="Foto de perfil" src="./src/assets/images/profile_git.jpg">

**Feito com 🖤 por João 'Jvmntr' Monteiro** \\
[**Desenvolvedor fullstack**]  <br><br>
[![Linkedin](https://img.shields.io/badge/-Jvmntr-333333?style=flat-square&logo=Linkedin&logoColor=white&link=https://www.linkedin.com/in/jvmntr/)](https://www.linkedin.com/in/jvmntr/)
<br/>
EOF
    echo "   - Arquivo 'README.md' padrão criado."
    echo "   - ${PINK}Lembrete: Adicione sua foto de perfil em 'src/assets/images/profile_git.jpg'${NC}"
fi

if [ "$CHANGELOG_SETUP" == "yes" ]; then
    cat <<EOF > CHANGELOG.md
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Your new feature here.

## [1.0.0] - $(date +%F)

### Added
- Initial project structure generated with Jvmntr's script.
EOF
    echo "   - Arquivo 'CHANGELOG.md' criado."
fi

mkdir -p src/components/Footer
cat <<EOF > src/components/Footer/index.${EXT}
import * as S from './styles';

const Footer = () => {
    const currentYear = new Date().getFullYear();

    return (
        <S.FooterContainer data-testid="footer-container">
            <S.CopyrightText>
                @{currentYear} Jvmntr. Todos os direitos reservados.
            </S.CopyrightText>
            <S.DevMessage>
                Feito com 🖤 por João <span className="nickname">'Jvmntr'</span> Monteiro
            </S.DevMessage>
        </S.FooterContainer>
    );
};

export default Footer;
EOF

cat <<EOF > src/components/Footer/styles.${STYLE_EXT}
import styled from "styled-components";

export const FooterContainer = styled.footer\`
    display: flex;
    flex-direction:column;
    justify-content: center;
    align-items: center;
    width: 100%;
    padding: 2.5rem 2rem;
    background-color: var(--background-primary);
    color: var(--text-secondary);
    font-family: "Fira Code", monospace;
    font-size: 0.9rem;
    box-sizing: border-box;
    border-top: 1px solid var(--accent-color);
    margin-top: auto;

    @media (max-width: 480px){
        padding: 2rem 1rem;
        font-size: 0.8rem
    }
\`;

export const CopyrightText = styled.p\`
    margin: 0 0 0.5rem 0;
    text-align: center;
\`;

export const DevMessage = styled.p\`
    margin: 0;
    text-align: center;
    color: var(--text-secondary);

    .nickname {
        color: var(--accent-color); 
    }
\`;
EOF
echo "   - Componente Footer criado."

print_header "6/8: Configurando o padrão do projeto..."

ENTRY_POINT="src/main.${MAIN_FILE_EXT}"
if [ "$TOOL_CHOICE" == "cra" ]; then
    ENTRY_POINT="src/index.${MAIN_FILE_EXT}"
fi

TS_NON_NULL_ASSERTION=""
if [ "$LANG_CHOICE" == "ts" ]; then
    TS_NON_NULL_ASSERTION="!"
fi

if [ "$PROJECT_PATTERN" == "router" ]; then
    rm -f src/App.${EXT}
    mkdir -p src/pages
    
    mkdir -p src/pages/HomePage
    cat <<EOF > src/pages/HomePage/index.${EXT}
import * as S from './styles';
import Footer from '../../components/Footer';

const HomePage = () => {
  return (
    <>
      <main>
        <S.Container>
          <S.Title>Bem-vindo ao ${PROJECT_NAME}!</S.Title>
          <S.Subtitle>Sua página inicial está funcionando.</S.Subtitle>
        </S.Container>
      </main>
      <Footer />
    </>
  );
};

export default HomePage;
EOF

    cat <<EOF > src/pages/HomePage/styles.${STYLE_EXT}
import styled from "styled-components";

export const Container = styled.div\`
  text-align: center;
  padding: 4rem 2rem;
\`;

export const Title = styled.h1\`
  margin-bottom: 1rem;
\`;

export const Subtitle = styled.p\`
  font-family: var(--font-monospace);
\`;
EOF
    echo "   - Padrão Router: Pasta 'pages' e 'HomePage' criadas."

    rm -f ${ENTRY_POINT}
    cat <<EOF > ${ENTRY_POINT}
import React from 'react';
import ReactDOM from 'react-dom/client';
import { createBrowserRouter, RouterProvider } from 'react-router-dom';
import HomePage from './pages/HomePage';
import './index.css';

const router = createBrowserRouter([
  {
    path: '/',
    element: <HomePage />,
    errorElement: <div>Página não encontrada!</div>,
  },
]);

const root = ReactDOM.createRoot(document.getElementById('root')${TS_NON_NULL_ASSERTION});
root.render(
  <React.StrictMode>
    <RouterProvider router={router} />
  </React.StrictMode>,
);
EOF
    echo "   - Arquivo de entrada configurado com React Router."
else
    cat <<EOF > src/App.${EXT}
import React from 'react';
import Footer from './components/Footer';

const App = () => {
  return (
    <>
      <main>
        <div style={{ textAlign: 'center', padding: '4rem 2rem' }}>
          <h1 style={{ marginBottom: '1rem' }}>Bem-vindo ao ${PROJECT_NAME}!</h1>
          <p style={{ fontFamily: 'var(--font-monospace)'}}>
            Sua landing page está funcionando.
          </p>
        </div>
      </main>
      <Footer />
    </>
  );
};

export default App;
EOF
    echo "   - Padrão Landing Page: 'App.${EXT}' principal criado."

    rm -f ${ENTRY_POINT}
    cat <<EOF > ${ENTRY_POINT}
import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';
import './index.css';

const root = ReactDOM.createRoot(document.getElementById('root')${TS_NON_NULL_ASSERTION});
root.render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
);
EOF
    echo "   - Arquivo de entrada configurado para renderizar o App principal."
fi

print_header "7/8: Configurando estilos globais..."

cat <<'EOF' > src/index.css
@import url('https://fonts.googleapis.com/css2?family=Fira+Code:wght@400;500;700&family=Inter:wght@400;700&display=swap');
:root {
  --background-primary: #1a1b26;
  --background-secondary: #24283b;
  --accent-color: #bb9af7;
  --text-primary: #c0caf5;
  --text-secondary: #a9b1d6;
  --border-color: #414868;
  --font-primary: 'Inter', sans-serif;
  --font-monospace: 'Fira Code', monospace;
}
* { margin: 0; padding: 0; box-sizing: border-box; }
body {
  font-family: var(--font-primary);
  background-color: var(--background-primary);
  color: var(--text-primary);
  line-height: 1.6;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}
#root { display: flex; flex-direction: column; min-height: 100vh; }
main { flex: 1; }
EOF
echo "   - Arquivo 'index.css' atualizado."


print_header "8/8: Inicializando o repositório Git..."

if command -v git &> /dev/null; then
    (git init && git add . && git commit -m "🎉 Commit inicial: Projeto gerado com o script") > /dev/null 2>&1 &
    spinner $! "Inicializando repositório Git..."
    echo -e "${GREEN}✅ Repositório Git inicializado com sucesso.${NC}"
else
    echo "   - ${PINK}Aviso: Git não encontrado. Pulei a inicialização do repositório.${NC}"
    echo "   - ${PINK}Você pode inicializá-lo manualmente com 'git init'.${NC}"
fi

print_header "🎉 Projeto criado com sucesso! 🎉"
echo -e "Para começar, execute os seguintes comandos:\n"
echo -e "   ${PINK}cd ${PROJECT_NAME_LOWER}${NC}"
START_CMD=$([ "$TOOL_CHOICE" == "vite" ] && echo "dev" || echo "start")
echo -e "   ${PINK}npm run ${START_CMD}${NC}"
if [ "$LINT_SETUP" == "yes" ]; then
    echo -e "   ${PINK}npm run lint${NC} (para verificar o código)"
    echo -e "   ${PINK}npm run format${NC} (para formatar o código)"
fi
echo ""
echo -e "${GREEN}Bons estudos e codificação!${NC}"
echo ""
# 📦 Next.js Template

Um template robusto e moderno de [Next.js](https://nextjs.org) configurado com as melhores práticas, estrutura profissional e ferramentas de desenvolvimento produtivas.

---

## ✨ Características

- ⚡ **Next.js 16** - Framework React moderno com App Router
- 🎨 **Tailwind CSS 4** - Utility-first CSS framework
- 📘 **TypeScript** - Type safety e melhor experiência de desenvolvimento
- ✅ **ESLint** - Análise estática de código
- 🎯 **Estrutura escalável** - Pastas organizadas para componentes, hooks, contextos e utilities
- 🔄 **Hot Reload** - Atualização automática durante desenvolvimento
- 📱 **Responsivo** - Design mobile-first pronto para usar

---

## 📋 Pré-requisitos

Antes de começar, certifique-se de ter instalado:

- **Node.js** >= 18.x ([Download](https://nodejs.org/))
- **npm**, **yarn**, **pnpm** ou **bun** como gerenciador de pacotes

Verifique a instalação:

```bash
node --version
npm --version
```

---

## 🚀 Instalação

1. **Clone ou faça download do repositório**

```bash
git clone https://github.com/seu-usuario/next-template.git
cd next-template
```

2. **Instale as dependências**

```bash
npm install
# ou
pnpm install
# ou
yarn install
# ou
bun install
```

---

## 🐳 Desenvolvimento com Devcontainer e Codespaces

Este projeto suporta [Dev Containers](https://containers.dev/) e [GitHub Codespaces](https://github.com/features/codespaces), oferecendo um ambiente de desenvolvimento consistente sem necessidade de instalação local.

### VSCode Dev Container

O projeto inclui configuração `.devcontainer` para usar com VSCode:

**Requisitos:**
- [VSCode](https://code.visualstudio.com/)
- [Docker Desktop](https://www.docker.com/products/docker-desktop)
- Extensão [Dev Containers](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

**Instruções:**

1. Abra a pasta do projeto no VSCode
2. Pressione `F1` e execute o comando: `Dev Containers: Reopen in Container`
3. VSCode vai construir e iniciar o container automaticamente
4. Assim que pronto, execute: `npm run dev`

> **💡 Benefício:** Ambiente completamente isolado com todas as dependências pré-instaladas

### GitHub Codespaces

Execute o projeto diretamente no navegador usando GitHub Codespaces:

**Instruções:**

1. No repositório GitHub, clique no botão verde `Code`
2. Vá para a aba `Codespaces`
3. Clique em `Create codespace on main`
4. Espere o Codespace ser inicializado
5. No terminal integrado, execute: `npm run dev`
6. Clique no botão de `Ports` e abra a porta `3000` para visualizar a aplicação

**Configuração automática:**
- Todo o ambiente é criado automaticamente baseado no `.devcontainer`
- Não necessita instalação local de ferramentas
- Disponível diretamente no navegador

> **✨ Benefício:** Desenvolvimento completamente na nuvem, sem necessidade de máquina poderosa

---

## 🎯 Começando

### Modo Desenvolvimento

Inicie o servidor de desenvolvimento:

```bash
npm run dev
# ou
pnpm dev
# ou
yarn dev
# ou
bun dev
```

Abra [http://localhost:3000](http://localhost:3000) no seu navegador para ver o resultado.

> **Dica:** O projeto aceita hot reload automático. Edite `src/app/page.tsx` e veja as mudanças em tempo real.

### Modo Produção

Para compilar e testar em ambiente de produção:

```bash
npm run build
npm run start
```

---

## 📁 Estrutura de Projeto

```
src/
├── api/              # Rotas API (Route Handlers)
├── app/              # App Router do Next.js
│   ├── layout.tsx    # Layout raiz
│   ├── page.tsx      # Página inicial
│   └── globals.css   # Estilos globais
├── components/       # Componentes React reutilizáveis
├── contexts/         # Context API para estado global
├── hooks/            # Custom React hooks
└── libs/
    └── cn.ts         # Utilitários (ex: merge de classes Tailwind)
```

---

## ⚙️ Scripts Disponíveis

| Comando | Descrição |
|---------|-----------|
| `npm run dev` | Inicia servidor de desenvolvimento na porta 3000 |
| `npm run build` | Compila para produção |
| `npm run start` | Inicia servidor de produção |
| `npm run lint` | Executa análise de código com ESLint |

---

## 🛠️ Tecnologias Utilizadas

| Tecnologia | Versão | Propósito |
|-----------|--------|----------|
| [Next.js](https://nextjs.org) | 16.1.6 | Framework React |
| [React](https://react.dev) | 19.2.3 | Biblioteca UI |
| [TypeScript](https://www.typescriptlang.org) | 5.x | Type safety |
| [Tailwind CSS](https://tailwindcss.com) | 4.x | Styling |
| [ESLint](https://eslint.org) | 9.x | Linting |

---

## 📝 Configuração

### TypeScript

O projeto está configurado com `tsconfig.json`. Ajuste conforme necessário:

```json
{
  "compilerOptions": {
    "target": "ES2020",
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "strict": true,
    "jsx": "react-jsx"
  }
}
```

### Tailwind CSS

O Tailwind está configurado em `postcss.config.mjs` e `tailwindcss`. Customize o tema editando a configuração do Tailwind.

### ESLint

As regras de linting estão em `eslint.config.mjs`. Atualize conforme suas necessidades de projeto.

---

## 📚 Recursos e Documentação

- 📖 [Documentação do Next.js](https://nextjs.org/docs) - Aprenda sobre features e API
- 🎓 [Curso Next.js](https://nextjs.org/learn) - Tutorial interativo
- 🎨 [Tailwind CSS Docs](https://tailwindcss.com/docs) - Guia essencial do Tailwind
- 📘 [TypeScript Handbook](https://www.typescriptlang.org/docs/) - Referência completa

---

## 🚢 Deployment

### Vercel (Recomendado)

A forma mais fácil de fazer deploy é usar a [Vercel Platform](https://vercel.com):

1. Push seu código para GitHub
2. Conecte seu repositório à Vercel
3. Deploy automático em cada push

[Documentação de Deploy Vercel](https://nextjs.org/docs/app/building-your-application/deploying)

### Outras Plataformas

- [Netlify](https://netlify.com)
- [Railway](https://railway.app)
- [AWS Amplify](https://aws.amazon.com/amplify/)
- [Docker](https://www.docker.com/) (criando seu próprio container)

---

## 🤝 Contribuindo

Contribuições são bem-vindas! Para contribuir:

1. Faça um **fork** do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um **Pull Request**

Please ensure your code follows the project's ESLint rules and is properly typed with TypeScript.

---

## 📄 Licença

Este projeto está licenciado sob a MIT License - veja o arquivo `LICENSE` para detalhes.

---

## ❓ Suporte

Se encontrar problemas ou tiver dúvidas:

- Abra uma [Issue](https://github.com/gshelldev/next-template/issues)
- Consulte a [documentação do Next.js](https://nextjs.org/docs)
- Verifique as [perguntas frequentes](https://github.com/gshelldev/next-template/discussions)

---

## 📞 Contato

Desenvolvido com ❤️ por [GShellDev™](https://github.com/gshelldev)


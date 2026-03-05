import Image from "next/image";
import Link from "next/link";

const links = [
  {
    title: "Documentação",
    description: "Referência completa do Next.js (App Router, Data Fetching, etc.).",
    href: "https://nextjs.org/docs?utm_source=create-next-app&utm_medium=appdir-template-tw&utm_campaign=create-next-app",
  },
  {
    title: "Aprender",
    description: "Tutoriais guiados do básico ao avançado.",
    href: "https://nextjs.org/learn?utm_source=create-next-app&utm_medium=appdir-template-tw&utm_campaign=create-next-app",
  },
  {
    title: "Templates",
    description: "Boilerplates e starters para casos de uso comuns.",
    href: "https://vercel.com/templates?framework=next.js&utm_source=create-next-app&utm_medium=appdir-template-tw&utm_campaign=create-next-app",
  },
  {
    title: "Deploy (Vercel)",
    description: "Faça deploy com integração nativa para Next.js.",
    href: "https://vercel.com/new?utm_source=create-next-app&utm_medium=appdir-template-tw&utm_campaign=create-next-app",
  },
];

export default function Home() {
  return (
    <div className="flex min-h-screen items-center justify-center bg-zinc-50 font-sans dark:bg-black">
      <main className="flex min-h-screen w-full max-w-3xl flex-col items-center justify-between bg-white px-16 py-32 dark:bg-black sm:items-start">        
        {/* Header / Brand */}
        <div className="flex items-center gap-3">
          <Image
            className="dark:invert"
            src="/next.svg"
            alt="Next.js logo"
            width={100}
            height={20}
            priority
          />
          <span className="rounded-full border border-black/[.08] px-3 py-1 text-sm font-medium text-zinc-700 dark:border-white/[.145] dark:text-zinc-300">
            App Router + Tailwind
          </span>
        </div>
        {/* Hero */}
        <div className="flex flex-col items-center gap-6 text-center sm:items-start sm:text-left">
          <h1 className="max-w-md text-3xl font-semibold leading-10 tracking-tight text-black dark:text-zinc-50">
            Template base do Next.js (App Router)
          </h1>

          <p className="max-w-md text-lg leading-8 text-zinc-600 dark:text-zinc-400">
            Comece editando <code className="font-medium text-zinc-950 dark:text-zinc-50">app/page.tsx</code>.
            Este layout é compatível com <span className="font-medium text-zinc-950 dark:text-zinc-50">Codespaces</span>{" "}
            e <span className="font-medium text-zinc-950 dark:text-zinc-50">DevContainer</span>.
          </p>

          <div className="grid w-full grid-cols-1 gap-3 sm:grid-cols-2">
            {links.map((item) => (
              <Link
                key={item.title}
                href={item.href}
                target="_blank"
                rel="noopener noreferrer"
                className="group rounded-2xl border border-black/[.08] p-5 transition-colors hover:bg-black/[.04] dark:border-white/[.145] dark:hover:bg-[#1a1a1a]"
              >
                <div className="flex items-center justify-between gap-4">
                  <h2 className="text-base font-semibold text-zinc-950 dark:text-zinc-50">
                    {item.title}
                  </h2>
                  <span className="text-zinc-400 transition-transform group-hover:translate-x-0.5">
                    →
                  </span>
                </div>
                <p className="mt-2 text-sm leading-6 text-zinc-600 dark:text-zinc-400">
                  {item.description}
                </p>
              </Link>
            ))}
          </div>
        </div>
        {/* CTA */}
        <div className="mt-4 flex flex-col gap-4 text-base font-medium sm:flex-row">
          <Link
            className="flex h-12 w-full items-center justify-center gap-2 rounded-full bg-foreground px-5 text-background transition-colors hover:bg-[#383838] dark:hover:bg-[#ccc] md:w-[158px]"
            href="https://vercel.com/new?utm_source=create-next-app&utm_medium=appdir-template-tw&utm_campaign=create-next-app"
            target="_blank"
            rel="noopener noreferrer"
          >
            <Image
              className="dark:invert"
              src="/vercel.svg"
              alt="Vercel logomark"
              width={16}
              height={16}
            />
            Deploy
          </Link>
          <Link
            className="flex h-12 w-full items-center justify-center rounded-full border border-solid border-black/[.08] px-5 transition-colors hover:border-transparent hover:bg-black/[.04] dark:border-white/[.145] dark:hover:bg-[#1a1a1a] md:w-[158px]"
            href="https://nextjs.org/docs?utm_source=create-next-app&utm_medium=appdir-template-tw&utm_campaign=create-next-app"
            target="_blank"
            rel="noopener noreferrer"
          >
            Docs
          </Link>
        </div>
      </main>
    </div>
  );
}
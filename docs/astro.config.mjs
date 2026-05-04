// @ts-check
import { defineConfig } from "astro/config";
import starlight from "@astrojs/starlight";
import react from "@astrojs/react";
import starlightSidebarTopics from "starlight-sidebar-topics";
import starlightLinksValidator from "starlight-links-validator";

export default defineConfig({
  site: "https://bjw-s-labs.github.io",
  base: "/helm-charts/docs",
  markdown: {
    shikiConfig: {
      langs: [],
    },
  },
  integrations: [
    react(),
    starlight({
      title: "Helm Charts",
      favicon: "/favicon.svg",
      plugins: [
        starlightLinksValidator({
          errorOnRelativeLinks: false,
        }),
        starlightSidebarTopics([
          {
            label: "App Template",
            link: "/app-template/",
            icon: "open-book",
            items: [
              { slug: "app-template/getting-started" },
              {
                label: "Values reference",
                collapsed: true,
                autogenerate: {
                  directory: "app-template/reference",
                  collapsed: true,
                },
              },
              {
                label: "How to...",
                autogenerate: { directory: "app-template/howto" },
              },
              {
                label: "Examples",
                autogenerate: { directory: "app-template/examples" },
              },
              {
                label: "Upgrade instructions",
                items: [
                  { slug: "app-template/upgrades/4-to-5" },
                  { slug: "app-template/upgrades/3-to-4" },
                  { slug: "app-template/upgrades/2-to-3" },
                  { slug: "app-template/upgrades/1-to-2" },
                ],
              },
            ],
          },
        ]),
      ],
      social: [
        {
          icon: "github",
          label: "GitHub",
          href: "https://github.com/bjw-s-labs/helm-charts",
        },
      ],
      editLink: {
        baseUrl: "https://github.com/bjw-s-labs/helm-charts/edit/main/docs/",
      },
      lastUpdated: true,
      pagination: false,
      expressiveCode: {
        themes: ["github-dark", "github-light"],
        styleOverrides: {
          borderRadius: "0.375rem",
        },
      },
      customCss: ["./src/styles/custom.css"],
    }),
  ],
});

// @ts-check
import { defineConfig } from "astro/config";
import starlight from "@astrojs/starlight";
import react from "@astrojs/react";
import starlightSidebarTopics from "starlight-sidebar-topics";
import starlightLinksValidator from "starlight-links-validator";

export default defineConfig({
  site: "https://bjw-s-labs.github.io",
  base: "/helm-charts",
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
            label: "Guides",
            link: "/guides/getting-started/",
            icon: "open-book",
            items: [
              {
                label: "Getting Started",
                items: [{ slug: "guides/getting-started" }],
              },
              {
                label: "App Template",
                autogenerate: { directory: "app-template" },
              },
            ],
          },
          {
            label: "Reference",
            link: "/reference/",
            icon: "information",
            items: [
              {
                label: "Values Reference",
                collapsed: true,
                autogenerate: { directory: "reference", collapsed: true },
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

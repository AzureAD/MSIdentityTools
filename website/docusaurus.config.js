// @ts-check
// `@type` JSDoc annotations allow editor autocompletion and type checking
// (when paired with `@ts-check`).
// There are various equivalent ways to declare your Docusaurus config.
// See: https://docusaurus.io/docs/api/docusaurus-config

import {themes as prismThemes} from 'prism-react-renderer';

/** @type {import('@docusaurus/types').Config} */
const config = {
  title: 'MSIdentityTools',
  tagline: 'Microsoft Identity Tools',
  favicon: 'img/favicon.ico',

  // Set the production url of your site here
  url: 'https://azuread.github.com/',
  // Set the /<baseUrl>/ pathname under which your site is served
  // For GitHub pages deployment, it is often '/<projectName>/'
  baseUrl: '/MSIdentityTools/',

  // GitHub pages deployment config.
  // If you aren't using GitHub pages, you don't need these.
  organizationName: 'AzureAD', // Usually your GitHub org/user name.
  projectName: 'MSIdentityTools', // Usually your repo name.

  onBrokenLinks: 'throw',
  onBrokenMarkdownLinks: 'warn',

  // Even if you don't use internationalization, you can use this field to set
  // useful metadata like html lang. For example, if your site is Chinese, you
  // may want to replace "en" with "zh-Hans".
  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },
  themes: [
    "@easyops-cn/docusaurus-search-local",
  ],

  presets: [
    [
      'classic',
      /** @type {import('@docusaurus/preset-classic').Options} */
      ({
        docs: {
          routeBasePath: '/', // Serve the docs at the site's root
          // Please change this to your repo.
          // Remove this to remove the "edit this page" links.
          editUrl:
            'https://github.com/facebook/docusaurus/tree/main/packages/create-docusaurus/templates/shared/',
        },
        blog: false,
        theme: {
          customCss: './src/css/custom.css',
        },
      }),
    ],
  ],

  themeConfig:
    /** @type {import('@docusaurus/preset-classic').ThemeConfig} */
    ({
      // Replace with your project's social card
      navbar: {
        title: 'MSIdentityTools',
        logo: {
          alt: 'MSIdentityTools',
          src: 'img/logo.svg',
        },
        items: [
          {
            type: "doc",
            position: "left",
            docId: "commands/commands-overview",
            label: "Commands",
          },
          {
            "aria-label": "GitHub Repository",
            className: "navbar--github-link",
            href: "https://github.com/azuread/msidentitytools",
            position: "right",
          },
        ],
      },
      footer: {
        style: 'dark',
        links: [
          {
            title: 'Docs',
            items: [
              {
                label: 'Commands',
                to: '/commands',
              },
            ],
          },
          {
            title: 'Community',
            items: [
              {
                label: 'Reddit',
                href: 'https://reddit.com/r/entra',
              },
              {
                label: 'Discord',
                href: 'https://discord.entra.news',
              },
              {
                label: 'Twitter',
                href: 'https://twitter.com/merill',
              },
            ],
          },
          {
            title: 'More',
            items: [
              {
                label: 'GitHub',
                href: 'https://github.com/azuread/msidentitytools',
              },
            ],
          },
        ],
        copyright: `Built by the Microsoft Security → Customer Experience Engineering Team`,
      },
      prism: {
        theme: prismThemes.github,
        darkTheme: prismThemes.dracula,
      },
    }),
};

export default config;

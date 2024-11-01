import { hopeTheme } from "vuepress-theme-hope";

import { zhNavbar } from "./navbar.js";
import { zhSidebar } from "./sidebar.js";

export default hopeTheme({
  hostname: "https://vuepress-theme-hope-docs-demo.netlify.app",

  darkmode: "toggle",
  author: {
    name: "Cotton Eye Joe",
    url: "https://github.com/ToDreamr",
  },

  iconAssets: "fontawesome-with-brands",

  logo: "秒速５センチメートル.svg",

  repo: "Todreamr/Dr.Magic",

  docsDir: "src",

  locales: {
    "/": {
      // navbar
      navbar: zhNavbar,
      // sidebar
      sidebar: zhSidebar,

      footer: "由萌ICP备案",

      displayFooter: true,

      // page meta
      metaLocales: {
        editLink: "在 GitHub 上编辑此页",
      },
    },
  },

  encrypt: {
    config: {
      // 这会加密整个 guide 目录，并且两个密码都是可用的
      "/doc/": ["docKing", "docTang"],
      // 这只会加密 /config/page.html
      "/doc/工作相关的文档/工作.html": "kintang",
      "/think":"20031003"
    },
  },
  copyright: "Copyright © Mr.Cotton Eye Joe",
  plugins: {
    blog: {
      excerptLength: 0,
    },
  
    components: {
      components: ["Badge", "VPCard"],
    },
    
    mdEnhance: {
      align: true,
      attrs: true,
      codetabs: true,
      component: true,
      demo: true,
      figure: true,
      imgLazyload: true,
      imgSize: true,
      include: true,
      mark: true,
      plantuml: true,
      spoiler: true,
      stylize: [
        {
          matcher: "Recommended",
          replacer: ({ tag }) => {
            if (tag === "em")
              return {
                tag: "Badge",
                attrs: { type: "tip" },
                content: "Recommended",
              };
          },
        },
      ],
      sub: true,
      sup: true,
      tabs: true,
      tasklist: true,
      vPre: true,
    },
   
  },
});

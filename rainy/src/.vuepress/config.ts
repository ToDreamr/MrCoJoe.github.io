import { defineUserConfig } from "vuepress";

import theme from "./theme.js";
import { blogPlugin } from '@vuepress/plugin-blog'
import { hopeTheme } from "vuepress-theme-hope";

export default defineUserConfig({
  base: "/",
  lang: "zh-CN",
  theme:hopeTheme({
    encrypt: {
      config: {
        // 这会加密整个 guide 目录，并且两个密码都是可用的
        "/doc/": ["docKing", "docTang"],
        // 这只会加密 /config/page.html
        "/doc/工作相关的文档/工作.html": "kintang",
      },
    },
  }),

  plugins: [
    blogPlugin({
      // 选项
    }),
  ],
  // Enable it with pwa
  // shouldPrefetch: false,
});

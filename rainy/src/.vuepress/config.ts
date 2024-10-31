import { defineUserConfig } from "vuepress";

import theme from "./theme.js";
// import { blogPlugin } from '@vuepress/plugin-blog'
import { hopeTheme } from "vuepress-theme-hope";
// import { copyrightPlugin } from '@vuepress/plugin-copyright'


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
        "think":"20031003"
      },
    },
  }),

  plugins: [
    // blogPlugin({
    //   // 选项
      
    // }),
    // copyrightPlugin({
    //   // options
    //   global:true,
    //   triggerLength:20,
    //   license:"本站所有博客创作和所有权归九歌天上有，请勿直接转载"
    // }),
  ],
  // Enable it with pwa
  // shouldPrefetch: false,
});
import { defineUserConfig } from "vuepress";
import { getDirname, path } from 'vuepress/utils'
import theme from "./config/theme.js";

const __dirname = getDirname(import.meta.url)

export default defineUserConfig({
  base: "/",
  lang: "zh-CN",
  theme,
  port:81,
  head: [
    [
      'meta',
      {
        name: 'viewport',
        content: 'width=device-width,initial-scale=1,user-scalable=no'
      }
    ],
    ['script', { async: true, src: 'https://umami.zhenxin.me/script.js', 'data-website-id': 'a799e189-cf7e-4f5a-ac98-71de364f3637' }],
    ['script', { src: 'https://cdn.armoe.cn/static/js/autoGray.js' }]
  ],
  plugins: [
  ],
});
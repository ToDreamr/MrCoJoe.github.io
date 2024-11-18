import { defineUserConfig } from "vuepress";
import { getDirname } from 'vuepress/utils'
import theme from "./config/theme.js";
import { oml2dPlugin } from 'vuepress-plugin-oh-my-live2d';
import vuepressPluginAnchorRight from 'vuepress-plugin-anchor-right';

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
    ['script', { async: true, src: 'https://umami.zhenxin.me/script.js',
      'data-website-id': 'a799e189-cf7e-4f5a-ac98-71de364f3637' }],
    ['script', { src: 'https://cdn.armoe.cn/static/js/autoGray.js' }]
  ],
  plugins: [
    oml2dPlugin({
      // 在这里配置选项
      models: [
        {
          path: 'https://model.oml2d.com/Pio/model.json',
          "scale": 0.4,
          "position": [0, 50],
          "stageStyle": {
            "height": 300
          }
        }
      ]
    }),
    vuepressPluginAnchorRight({
      showDepth: 4,
      expand: {
        trigger: 'hover',
        clickModeDefaultOpen: true
      },
    }),
  ],
});
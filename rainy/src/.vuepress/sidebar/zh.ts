import { sidebar } from "vuepress-theme-hope";

export const zhSidebar = sidebar({
  "/": [
    {
      text: "后端理论",
      icon: "home",
      prefix: "doc/",
      collapsible: true,
      children: "structure",
    },
    {
      text: "指引",
      icon: "book",
      collapsible: true,
      prefix: "guide/",
      children: "structure",
    },
    {
      text: "帮助",
      prefix: "help/",
      children: "structure",
      collapsible: true,
      icon:"check-square"
    },
    {
      text: "幻灯片",
      icon: "person-chalkboard",
      link: "https://plugin-md-enhance.vuejs.press/zh/guide/content/revealjs/demo.html",
    },
  ],
});

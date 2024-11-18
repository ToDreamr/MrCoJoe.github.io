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
      text: "盘古",
      prefix: "盘古/",
      children: "structure",
      collapsible: true,
      icon:"check-square"
    },
    {
      text: "思考",
      icon: "book",
      collapsible: true,
      prefix: "think/",
      children: "structure",
    },
    {
      text: "帮助",
      prefix: "help/",
      children: "structure",
      collapsible: true,
      icon:"check-square"
    },
  ],
});

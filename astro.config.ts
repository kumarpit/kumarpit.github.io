import { defineConfig } from "astro/config";
import fs from "fs";
import mdx from "@astrojs/mdx";
import tailwind from "@astrojs/tailwind";
import sitemap from "@astrojs/sitemap";
import remarkUnwrapImages from "remark-unwrap-images";
import rehypeExternalLinks from "rehype-external-links";
import { remarkReadingTime } from "./src/utils/remark-reading-time";
import remarkMath from "remark-math";
import rehypeKatex from "rehype-katex";
import racketGrammar from "./src/assets/syntaxes/racket.tmLanguage.json";
import expressiveCode from "astro-expressive-code";
const racket = {
  id: "Racket",
  scopeName: "source.racket",
  grammar: racketGrammar,
  aliases: ["rkt", "racket"]
};


// https://astro.build/config
export default defineConfig({
  // ! Please remember to replace the following site property with your own domain
  site: "https://kumarpit.github.io",
  markdown: {
    remarkPlugins: [remarkUnwrapImages, remarkReadingTime, remarkMath],
    rehypePlugins: [[rehypeExternalLinks, {
      target: "_blank",
      rel: ["nofollow, noopener, noreferrer"]
    }], [rehypeKatex, {}]],
    remarkRehype: {
      footnoteLabelProperties: {
        className: [""]
      }
    },
    shikiConfig: {
      theme: "slack-dark",
      wrap: true,
      //      langs: ['c']
    }
  },
  integrations: [expressiveCode(), mdx({}), tailwind({
    applyBaseStyles: false
  }), sitemap()],
  image: {
    domains: ["webmention.io"]
  },
  // https://docs.astro.build/en/guides/prefetch/
  prefetch: true,
  vite: {
    plugins: [rawFonts([".ttf"])],
    optimizeDeps: {
      exclude: ["@resvg/resvg-js"]
    }
  }
});
function rawFonts(ext: Array<string>) {
  return {
    name: "vite-plugin-raw-fonts",
    // eslint-disable-next-line @typescript-eslint/ban-ts-comment
    // @ts-ignore:next-line
    transform(_, id) {
      if (ext.some(e => id.endsWith(e))) {
        const buffer = fs.readFileSync(id);
        return {
          code: `export default ${JSON.stringify(buffer)}`,
          map: null
        };
      }
    }
  };
}

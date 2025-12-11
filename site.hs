{-# LANGUAGE OverloadedStrings #-}

import Control.Monad (forM)
import Data.Default (def)
import Data.Functor.Identity (runIdentity)
import Data.List (sortBy, groupBy)
import qualified Data.Map as M
import Data.Maybe (fromMaybe, listToMaybe)
import Data.Monoid (mappend)
import Data.Ord (comparing)
import Hakyll
import System.FilePath ((-<.>))
import Text.Pandoc.Highlighting (Style, haddock, pygments, styleToCss)
import Text.Pandoc.Options
  ( Extension
      ( Ext_backtick_code_blocks,
        Ext_fenced_code_attributes,
        Ext_fenced_code_blocks,
        Ext_latex_macros,
        Ext_tex_math_dollars,
        Ext_tex_math_double_backslash
      ),
    HTMLMathMethod (MathJax),
    ReaderOptions,
    WriterOptions (..),
    extensionsFromList,
  )
import Text.Pandoc.Templates (Template, compileTemplate)

--------------------------------------------------------------------------------
main :: IO ()
main = do
  generateSyntaxHighlightingCSS
  let config =
        defaultConfiguration
          { destinationDirectory = "docs" -- <- publish to docs/
          }
  hakyllWith config $ do
    -- Copy images as-is
    match "images/*" $ do
      route idRoute
      compile copyFileCompiler

    -- Copy JavaScript as-is
    match "js/*" $ do
      route idRoute
      compile copyFileCompiler

    -- Compress CSS
    match "css/*" $ do
      route idRoute
      compile compressCssCompiler

    -- About
    match "about.md" $ do
        route   $ setExtension "html"
        compile $ pandocCompiler
            >>= loadAndApplyTemplate "templates/default.html" defaultContext
            >>= relativizeUrls

    -- Blog posts
    match "posts/*" $ do
      route $ setExtension "html"
      compile $
        pandocCompiler_
          >>= loadAndApplyTemplate "templates/post.html" postCtx
          >>= loadAndApplyTemplate "templates/default.html" postCtx
          >>= relativizeUrls

    -- All posts, books, research kernels
    create ["archive.html"] $ do
        route idRoute
        compile $ do
            posts <- recentFirst =<< loadAll "posts/*"
            books <- recentFirst =<< loadAll "books/*"
            researchKernels <- recentFirst =<< loadAll "research-kernels/*"
            let archiveCtx =
                    listField "posts" postCtx (return posts) `mappend`
                    groupedBooksField "groupedBooks" books `mappend`
                    listField "researchKernels" postCtx (return researchKernels) `mappend`
                    constField "title" "Archives"            `mappend`
                    defaultContext

            makeItem ""
                >>= loadAndApplyTemplate "templates/archive.html" archiveCtx
                >>= loadAndApplyTemplate "templates/default.html" archiveCtx
                >>= relativizeUrls

    -- Notes
    match "books/*" $ do
      route $ setExtension "html"
      compile $
        pandocCompiler_
          >>= loadAndApplyTemplate "templates/post.html" postCtx
          >>= loadAndApplyTemplate "templates/default.html" postCtx
          >>= relativizeUrls

    match "research-kernels/*" $ do
      route $ setExtension "html"
      compile $
        pandocCompiler_
          >>= loadAndApplyTemplate "templates/post.html" postCtx
          >>= loadAndApplyTemplate "templates/default.html" postCtx
          >>= relativizeUrls

    -- Index page
    match "index.html" $ do
      route idRoute
      compile $ do
        posts <- recentFirst =<< loadAll "posts/*"
        books <- recentFirst =<< loadAll "books/*"
        researchKernels <- recentFirst =<< loadAll "research-kernels/*"
        let indexCtx =
              listField "posts" postCtx (return posts)
                `mappend` groupedBooksField "groupedBooks" books
                `mappend` listField "researchKernels" postCtx (return researchKernels)
                `mappend` defaultContext

        getResourceBody
          >>= applyAsTemplate indexCtx
          >>= loadAndApplyTemplate "templates/home.html" indexCtx
          >>= relativizeUrls

    -- Templates
    match "templates/*" $ compile templateBodyCompiler

--------------------------------------------------------------------------------
-- Post context with date formatting
postCtx :: Hakyll.Context String
postCtx =
  dateField "date" "%B %e, %Y"
    `mappend` defaultContext

-- Context for grouped books (with nested notes)
groupedBooksField :: String -> [Item String] -> Context String
groupedBooksField name items = field name $ \_ -> do
    -- Get metadata for all items and group by "book" field
    itemsWithMeta <- mapM getItemMeta items
    let groupedMap = foldr addToGroup M.empty itemsWithMeta
    let groups = M.toList groupedMap

    -- Generate HTML for nested list
    return $ concatMap renderBookGroup groups
  where
    getItemMeta item = do
      metadata <- getMetadata (itemIdentifier item)
      return (item, metadata)

    addToGroup (item, metadata) acc =
      let bookName = fromMaybe "Untitled" $ lookupString "book" metadata
      in M.insertWith (++) bookName [(item, metadata)] acc

    renderBookGroup (bookTitle, notesWithMeta) =
      if length notesWithMeta == 1
        then renderSingleNote bookTitle (head notesWithMeta)
        else "<li>" ++ bookTitle ++ "\n" ++
             "  <ul>\n" ++
             concatMap renderNote (sortBy (comparing (itemIdentifier . fst)) notesWithMeta) ++
             "  </ul>\n" ++
             "</li>\n"

    renderSingleNote bookTitle (item, metadata) =
      let identifier = itemIdentifier item
          url = toUrl $ toFilePath identifier -<.> "html"
      in "<li><a href=\"" ++ url ++ "\">" ++ bookTitle ++ "</a></li>\n"

    renderNote (item, metadata) =
      let identifier = itemIdentifier item
          url = toUrl $ toFilePath identifier -<.> "html"
          title = fromMaybe "Untitled" $ lookupString "title" metadata
      in "    <li><a href=\"" ++ url ++ "\">" ++ title ++ "</a></li>\n"

--------------------------------------------------------------------------------
syntaxHighlightingStyle :: Style
syntaxHighlightingStyle = pygments  -- Change this to: pygments, tango, espresso, zenburn, kate, monochrome, breezeDark, or haddock

generateSyntaxHighlightingCSS :: IO ()
generateSyntaxHighlightingCSS = do
  let css = styleToCss syntaxHighlightingStyle
  writeFile "css/syntax.css" css
  return ()

pandocCompiler_ :: Compiler (Item String)
pandocCompiler_ =
  let extensions =
        -- Pandoc Extensions: http://pandoc.org/MANUAL.html#extensions
        -- Math extensions
        [ Ext_tex_math_dollars,
          Ext_tex_math_double_backslash,
          Ext_latex_macros,
          -- Code extensions
          Ext_fenced_code_blocks,
          Ext_backtick_code_blocks,
          Ext_fenced_code_attributes
        ]
      defaultExtensions = writerExtensions defaultHakyllWriterOptions
      writerOptions =
        defaultHakyllWriterOptions
          { writerExtensions = defaultExtensions <> extensionsFromList extensions,
            writerHTMLMathMethod = MathJax ""
          }
   in pandocCompilerWith defaultHakyllReaderOptions writerOptions

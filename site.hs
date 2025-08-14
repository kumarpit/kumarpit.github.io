{-# LANGUAGE OverloadedStrings #-}
import           Data.Monoid (mappend)
import           Hakyll
import           Data.Default (def)
import           Text.Pandoc.Options (ReaderOptions, WriterOptions(..), Extension (Ext_tex_math_dollars, Ext_tex_math_double_backslash, Ext_latex_macros, Ext_fenced_code_blocks, Ext_backtick_code_blocks, Ext_fenced_code_attributes), HTMLMathMethod (MathJax), extensionsFromList)
import           Text.Pandoc.Templates (compileTemplate, Template)
import           Data.Text (Text)
import           qualified Data.Text as T
import           Data.Functor.Identity (runIdentity)
import           Text.Pandoc.Highlighting (haddock, Style, styleToCss)

--------------------------------------------------------------------------------
main :: IO ()

main  = do 
    generateSyntaxHighlightingCSS
    let config = defaultConfiguration
                   { destinationDirectory = "docs" }  -- <- publish to docs/
    hakyllWith config $ do
        -- Copy images as-is
        match "images/*" $ do
            route   idRoute
            compile copyFileCompiler

        -- Compress CSS
        match "css/*" $ do
            route   idRoute
            compile compressCssCompiler

        -- Blog posts
        match "posts/*" $ do
            route $ setExtension "html"
            compile $ pandocCompiler_
                >>= loadAndApplyTemplate "templates/post.html"    postCtx
                >>= loadAndApplyTemplate "templates/default.html" postCtx
                >>= relativizeUrls

        -- Notes
        match "notes/*" $ do
            route $ setExtension "html"
            compile $ pandocCompiler_
                >>= loadAndApplyTemplate "templates/post.html"    postCtx
                >>= loadAndApplyTemplate "templates/default.html" postCtx
                >>= relativizeUrls

        -- Index page
        match "index.html" $ do
            route idRoute
            compile $ do
                posts <- recentFirst =<< loadAll "posts/*"
                notes <- recentFirst =<< loadAll "notes/*"
                let indexCtx =
                        listField "posts" postCtx (return posts) `mappend`
                        listField "notes" postCtx (return notes) `mappend`
                        defaultContext

                getResourceBody
                    >>= applyAsTemplate indexCtx
                    >>= loadAndApplyTemplate "templates/default.html" indexCtx
                    >>= relativizeUrls

        -- Templates
        match "templates/*" $ compile templateBodyCompiler

--------------------------------------------------------------------------------
-- Post context with date formatting
postCtx :: Hakyll.Context String
postCtx =
    dateField "date" "%B %e, %Y" `mappend`
    defaultContext

--------------------------------------------------------------------------------
syntaxHighlightingStyle :: Style
syntaxHighlightingStyle = haddock

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
          [ Ext_tex_math_dollars
          , Ext_tex_math_double_backslash
          , Ext_latex_macros
          -- Code extensions
          , Ext_fenced_code_blocks
          , Ext_backtick_code_blocks
          , Ext_fenced_code_attributes
          ]
        defaultExtensions = writerExtensions defaultHakyllWriterOptions
        writerOptions = defaultHakyllWriterOptions
          { writerExtensions = defaultExtensions <> extensionsFromList extensions
          , writerHTMLMathMethod = MathJax "" 
          }
    in pandocCompilerWith defaultHakyllReaderOptions writerOptions

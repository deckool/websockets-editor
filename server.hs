--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
module Main where


--------------------------------------------------------------------------------
import           Control.Concurrent      (forkIO)
import           Control.Exception       (finally)
import           Control.Monad           (forever, unless)
import qualified Data.ByteString         as B
import qualified Data.ByteString.Char8   as BC
import qualified Data.ByteString.Lazy.Char8   as LC
import qualified Network.WebSockets      as WS
import qualified Network.WebSockets.Snap as WS
import           Snap.Core               (Snap)
import qualified Snap.Core               as Snap
import qualified Snap.Http.Server        as Snap
import qualified Snap.Util.FileServe     as Snap
import qualified System.IO               as IO
import qualified System.Process          as Process

import           Text.Discount
import qualified Data.Text as T
import Control.Monad.IO.Class


--------------------------------------------------------------------------------
app :: Snap ()
app = Snap.route
    [ ("",               Snap.ifTop $ Snap.serveFile "console.html")
    , ("cdn",            Snap.serveDirectory ".")
    , ("console.js",     Snap.serveFile "console.js")
    , ("console", console)
    , ("client",         Snap.serveFile "client.html")
    , ("style.css",      Snap.serveFile "style.css")
    , ("mark",           Snap.serveDirectory "mark")
    ]


--------------------------------------------------------------------------------
console :: Snap ()
console = do
    --Just shell <- Snap.getParam "shell"
    WS.runWebSocketsSnap $ consoleApp "discountC"
    --Snap.writeBS "hi"


--------------------------------------------------------------------------------
consoleApp :: String -> WS.ServerApp
consoleApp shell pending = do

    (stdin, stdout, stderr, phandle) <- Process.runInteractiveCommand shell

{--    let z                                = WS.pendingRequest pending
    let ps = WS.Request z "what?"
    print $ show ps
    print $ WS.requestPath z
    print $ WS.requestHeaders z
    print $ WS.requestSecure z --}
    conn                             <- WS.acceptRequest pending

    _ <- forkIO $ copyHandleToConn stdout conn
    _ <- forkIO $ copyHandleToConn stderr conn
    _ <- forkIO $ copyConnToHandle conn stdin

    exitCode <- Process.waitForProcess phandle
    putStrLn $ "consoleApp ended: " ++ show exitCode


--------------------------------------------------------------------------------
copyHandleToConn :: IO.Handle -> WS.Connection -> IO ()
copyHandleToConn h c = do
    bs <- B.hGetSome h 1024
    print bs
    unless (B.null bs) $ do
        --putStrLn $ "> " ++ show bs
        WS.sendTextData c bs
        copyHandleToConn h c


--------------------------------------------------------------------------------
copyConnToHandle :: WS.Connection -> IO.Handle -> IO ()
copyConnToHandle c h = flip finally (IO.hClose h) $ forever $ do
    bs <- WS.receiveData c
    let getInfo = wordsWhen (=='*') (BC.unpack bs)
    let headInfo = unlines $ take 1 getInfo
    print headInfo
    let noHeader = length headInfo
    let send = drop noHeader $ BC.unpack bs
    print send
    let mdParsed = parseMarkdown compatOptions $ BC.pack send
    --print headInfo
    --print send
    WS.sendTextData c mdParsed
    --B.hPutStr h mdParsed
    B.writeFile "example.json" $ BC.pack headInfo
    B.writeFile "example.md" $ BC.pack send
    IO.hFlush h

wordsWhen     :: (Char-> Bool) -> String -> [String]
wordsWhen p s =  case dropWhile p s of
                      "" -> []
                      s' -> w : wordsWhen p s''
                            where (w, s'') = break p s'

--------------------------------------------------------------------------------
main :: IO ()
main = Snap.httpServe (Snap.setPort 8003 config) app
  where
    config =
        Snap.setErrorLog  Snap.ConfigNoLog $
        Snap.setAccessLog Snap.ConfigNoLog $
        Snap.defaultConfig

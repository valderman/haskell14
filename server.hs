import qualified Network.WebSockets as WS
import qualified Control.Concurrent as Conc
import qualified Control.Exception as Ex
import qualified Data.ByteString as BS
import qualified Data.ByteString.UTF8 as BS

main = do
  clients <- Conc.newMVar []
  nextClientID <- Conc.newMVar 0
  WS.runServer "0.0.0.0" 24601 $ \pending -> do
    conn <- WS.acceptRequest pending
    cid <- Conc.modifyMVar nextClientID $ \cid -> do
      return (cid+1, cid)

    let endSession :: Ex.SomeException -> IO ()
        endSession e = Conc.modifyMVar clients $ \cs -> do
          return ([c | c <- cs, fst c /= cid],())

    flip Ex.catch endSession $ do
      let loop = do
            msg <- WS.receiveData conn :: IO BS.ByteString
            case splitAt 4 $ BS.toString msg of
              ("helo", "") -> do
                Conc.modifyMVar clients $ \cs -> return ((cid,conn):cs,())
              ("text", msg) -> do
                recipients <- Conc.withMVar clients return
                flip mapM_ recipients $ do
                  \(_,r) -> Conc.forkIO $ WS.sendTextData r (BS.fromString msg)
            loop
        in loop

import Haste.App
import Haste.App.Concurrent as HC
import qualified Control.Concurrent as CC
import qualified Data.List as L

main = runApp (defaultConfig "ws://localhost:24601" 24601) $ do
  clients <- liftServerIO $ CC.newMVar []

  hello <- export $ mkUseful clients >>= \clients -> do
    sid <- getSessionID
    liftIO $ CC.modifyMVar clients $ \cs -> do
      mv <- CC.newEmptyMVar
      return ((sid, mv):cs ,())

  awaitMsg <- export $ mkUseful clients >>= \clients -> do
    sid <- getSessionID
    liftIO $ do
      cs <- CC.withMVar clients return
      case L.find ((== sid) . fst) cs of
        Just (_, mv) -> CC.takeMVar mv
        _            -> fail "Client did not say hello - abort session!"

  sendMsg <- export $ \msg -> mkUseful clients >>= \clients -> liftIO $ do
    recipients <- CC.withMVar clients return
    mapM_ (CC.forkIO . flip CC.putMVar msg . snd) recipients

  runClient $ withElems ["log", "message"] $ \[log, msgbox] -> do
    onServer hello

    mbox <- HC.statefully [] $ \oldlines newline -> do
      setProp log "value" $ unlines $ newline:oldlines
      return . Just $ newline:oldlines
    HC.fork . forever $ mbox <! onServer awaitMsg
    
    msgbox `onEvent` OnKeyPress $ \13 -> do
      getProp msgbox "value" >>= onServer . (sendMsg <.>)
      setProp msgbox "value" ""

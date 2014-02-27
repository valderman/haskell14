import Data.List
import Haste.App
import Haste.App.Concurrent
import qualified Control.Concurrent as CC

type Recipient = (SessionID, CC.MVar String)
type RcptList = CC.MVar [Recipient]

srvHello :: Useless RcptList -> Server ()
srvHello uRcpts = do
  recipients <- mkUseful uRcpts
  sid <- getSessionID
  rcptMVar <- liftIO CC.newEmptyMVar
  liftIO $ CC.modifyMVar recipients $ \cs -> do
    return ((sid, rcptMVar):cs ,())

srvSend :: Useless RcptList -> String -> Server ()
srvSend uRcpts message = do
    rcpts <- mkUseful uRcpts
    liftIO $ do
      recipients <- CC.withMVar rcpts return
      mapM_ (CC.forkIO . deliver message) recipients
  where
    deliver :: String -> Recipient -> IO ()
    deliver message (_, rcptMVar) =
      CC.putMVar rcptMVar message

srvAwait :: Useless RcptList -> Server String
srvAwait uRcpts = do
  rcpts <- mkUseful uRcpts
  sid <- getSessionID
  liftIO $ do
    recipients <- CC.withMVar rcpts return
    case find ((== sid) . fst) recipients of
      Just (_, mv) -> CC.takeMVar mv
      _            -> fail "Unregistered session; aborting"

appMain :: App Done
appMain = do
  recipients <- liftServerIO $ CC.newMVar []

  hello <- export $ srvHello recipients
  awaitMsg <- export $ srvAwait recipients
  sendMsg <- export $ srvSend recipients

  runClient $ withElems ["log", "message"] $ \[log, msgbox] -> do
    onServer hello

    mbox <- statefully [] $ \oldlines newline -> do
      setProp log "value" $ unlines $ newline:oldlines
      return . Just $ newline:oldlines
    fork . forever $ mbox <! onServer awaitMsg
    
    msgbox `onEvent` OnKeyPress $ \13 -> do
      msg <- getProp msgbox "value"
      onServer (sendMsg <.> msg)
      setProp msgbox "value" ""

main :: IO ()
main = runApp (mkConfig "ws://localhost:1111" 1111) appMain

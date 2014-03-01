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
    deliver msg (_, rcptMVar) = CC.putMVar rcptMVar msg

srvAwait :: Useless RcptList -> Server String
srvAwait uRcpts = do
  rcpts <- mkUseful uRcpts
  sid <- getSessionID
  liftIO $ do
    recipients <- CC.withMVar rcpts return
    case lookup sid recipients of
      Just mv -> CC.takeMVar mv
      _       -> fail "Unregistered session; aborting"

appMain :: App Done
appMain = do
  recipients <- liftServerIO $ CC.newMVar []

  hello <- export $ srvHello recipients
  awaitMsg <- export $ srvAwait recipients
  sendMsg <- export $ srvSend recipients

  runClient $ do
    withElems ["log","message"] $ \[log,msgbox] -> do
      onServer hello

      let rcvLoop chatlines = do
            setProp log "value" $ unlines chatlines
            message <- onServer awaitMsg
            rcvLoop (message : chatlines)
      fork $ rcvLoop []
    
      msgbox `onEvent` OnKeyPress $ \13 -> do
        msg <- getProp msgbox "value"
        setProp msgbox "value" ""
        onServer (sendMsg <.> msg)

main :: IO ()
main =
  runApp (mkConfig "ws://localhost:1111" 1111) appMain

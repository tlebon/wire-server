{-# LANGUAGE ForeignFunctionInterface #-}

-- This file is part of the Wire Server implementation.
--
-- Copyright (C) 2022 Wire Swiss GmbH <opensource@wire.com>
--
-- This program is free software: you can redistribute it and/or modify it under
-- the terms of the GNU Affero General Public License as published by the Free
-- Software Foundation, either version 3 of the License, or (at your option) any
-- later version.
--
-- This program is distributed in the hope that it will be useful, but WITHOUT
-- ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
-- FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
-- details.
--
-- You should have received a copy of the GNU Affero General Public License along
-- with this program. If not, see <https://www.gnu.org/licenses/>.

module Jwt.Tools (testHaskellApi, generateDpopToken) where

import Control.Monad.Trans.Except
import Data.ByteString.Conversion (ToByteString, toByteString')
import Data.Id (ClientId (client))
import Data.Misc (HttpsUrl)
import Data.Nonce (Nonce)
import Data.String.Conversions (cs)
import Foreign.C.String (CString, newCString, peekCString)
import Foreign.C.Types (CULong (..), CUShort (..))
import Imports
import Network.HTTP.Types (StdMethod (..))
import Numeric (readHex)
import Test.QuickCheck (Arbitrary (arbitrary), generate)
import Wire.API.MLS.Credential (ClientIdentity (ClientIdentity, ciClient, ciDomain, ciUser))
import Wire.API.MLS.Epoch (Epoch (..))
import Wire.API.User.Client.DPoPAccessToken (DPoPAccessToken (DPoPAccessToken), DPoPTokenGenerationError (..), Proof (Proof))

generateDpopToken ::
  (MonadIO m) =>
  Proof ->
  ClientIdentity ->
  Nonce ->
  HttpsUrl ->
  StdMethod ->
  Word16 ->
  Word64 ->
  Epoch ->
  ByteString ->
  ExceptT DPoPTokenGenerationError m DPoPAccessToken
generateDpopToken dpopProof cid nonce uri method maxSkewSecs maxExpiration now backendPubkeyBundle = do
  dpopProofCStr <- liftIO $ toCStr dpopProof
  uidCStr <- liftIO $ toCStr $ ciUser cid
  cidCUShort <- case readHex @Word16 (cs $ client $ ciClient cid) of
    [(a, "")] -> pure (CUShort a)
    _ -> throwE InvalidClientId
  domainCStr <- liftIO $ toCStr $ ciDomain cid
  nonceCStr <- liftIO $ toCStr nonce
  uriCStr <- liftIO $ toCStr uri
  methodCStr <- liftIO $ newCString $ cs $ methodToBS method
  backendPubkeyBundleCStr <- liftIO $ newCString $ cs backendPubkeyBundle
  responseCStr <-
    liftIO $
      generateDpopTokenFFI
        dpopProofCStr
        uidCStr
        cidCUShort
        domainCStr
        nonceCStr
        uriCStr
        methodCStr
        (CUShort maxSkewSecs)
        (CULong maxExpiration)
        (CULong $ epochNumber now)
        backendPubkeyBundleCStr
  responseStr <- liftIO $ peekCString responseCStr
  let mbError = readMaybe @Word8 (cs responseStr) >>= mapError
  maybe (pure $ DPoPAccessToken $ cs responseStr) throwE mbError
  where
    mapError :: Word8 -> Maybe DPoPTokenGenerationError
    mapError 0 = Nothing
    mapError 1 = Just InvalidDPoPProofSyntax
    mapError 2 = Just InvalidHeaderTyp
    mapError 3 = Just AlgNotSupported
    mapError 4 = Just BadSignature
    mapError _ = error "todo(leif): map other errors"

    toCStr :: forall a. (ToByteString a) => a -> IO CString
    toCStr = newCString . cs . toByteString'

    methodToBS :: StdMethod -> ByteString
    methodToBS = \case
      GET -> "GET"
      POST -> "POST"
      HEAD -> "HEAD"
      PUT -> "PUT"
      DELETE -> "DELETE"
      TRACE -> "TRACE"
      CONNECT -> "CONNECT"
      OPTIONS -> "OPTIONS"
      PATCH -> "PATCH"

foreign import ccall "generate_dpop_token"
  generateDpopTokenFFI ::
    CString ->
    CString ->
    CUShort ->
    CString ->
    CString ->
    CString ->
    CString ->
    CUShort ->
    CULong ->
    CULong ->
    CString ->
    IO CString

testHaskellApi :: IO ()
testHaskellApi = do
  cid <- ClientIdentity <$> generate arbitrary <*> generate arbitrary <*> generate arbitrary
  now <- generate arbitrary
  nonce <- generate arbitrary
  uri <- generate arbitrary
  result <-
    runExceptT $
      generateDpopToken
        (Proof "xxxx.yyyy.zzzz")
        cid
        nonce
        uri
        POST
        16
        360
        now
        (cs pubKeyBundle)
  putStrLn $ "result: " <> show result

pubKeyBundle :: String
pubKeyBundle =
  "-----BEGIN PRIVATE KEY-----\n"
    <> "MIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQDHH+mwKhUe+LhA\n"
    <> "0l/JeY+ARtlPSBnx3gHkuboxAM4T5sNENR0LxnjEkuCzDOczFEINUjSoWuC+U1FU\n"
    <> "uyX6S5qL3RYNjtTt675lfTczxnjUM9HSGEaGaSPOxmHfyXOofY3O0fgd531WkO4U\n"
    <> "j7RxUS2E0dEGub62iNOYh+2B2yIAexi+OD5ZGmJaO4dzlPIyAKa+L/mknOt0n6lZ\n"
    <> "OrD9t36WW3aiON5paNy92W/K+lMGikz17l/VxsUg3capd3hXWVXaOMUFGTj5PdsT\n"
    <> "jT3TTVFNZoTAdfbvf/jLF5VBLcUKr5Tm8NcL6g+gQYbp2Utel8XzfYEGj92KFm4E\n"
    <> "Aa9ui9pnAgMBAAECggEAey2NpRFTQXaAnHDHGl4dXC/3q+ihTBKWv0P5HuktkfgV\n"
    <> "YPMuRaN//7IQWBKqTtnARndM5bxZ/MKTtEOVKbFtKAoa40YxCADmJegApwGmqzZn\n"
    <> "HH0x22Hc6cOktgfriRYqC/+taepSiaNb89I1wEeETf5xPKTYihg4NMoZLVQ+Q2bK\n"
    <> "Etf4Bd+K+fqDwY5W3FsbgrA3K0N8W57QNxLAFju5RCfljlDOSjcUxiVf6WVyI9OA\n"
    <> "a8klqT1WGEBfKQrWrmzjQCJ7BfSX3TPixSsedHvc2NbbpIVofwXMm7mkD9q4xb0D\n"
    <> "L4JGpt9wahKOBKzphYFwCtLzRpXl5earFWyeFtF6yQKBgQD3fkxBiP8Ql/zWINd3\n"
    <> "csjfHR3wPIFwE5TzEMckwXCra/XyA7srNJiK1Yf5I0e83iyiNAfSfKu6UBIqoSiR\n"
    <> "PNNyvP2I7gEYsMEYhO/gbDgbRfFjf73x4ONnu/1yPg+gYsUY1GKbkTniCdMRxTp7\n"
    <> "2T/5gCmoS8j2Aup0uuG+uYL0RQKBgQDN+ARraGEtvkuQQNM2MPm7wk/tT1zVhosL\n"
    <> "ascYXnpKvvCn2M3UEtn815cEtatnSf5NbQdinWEJlJ7hcJs8Pdsay9AMvzdo5V5k\n"
    <> "rXssd5F5UCJS1SY9q8etv8unbRWW2jtk4CzCXUfSPmf9qcOXhtb71wKAWN46O0Xo\n"
    <> "bNK0BWp8uwKBgELL+5jUeMLpwnuocX7zo/NT0Hi+W9D79/+CT71D2Dzr7n1bNHD8\n"
    <> "yQ7vgrtjIkF/VVyR3mqY62BlrAGFbYWFfSxChcsnMXSQgA02E+fmTV5PCk9ocsON\n"
    <> "htLAki77QQxwm/GPoO2LzKuNK0JokNhMUk/sn1Gk4qBDOTQ4HCV1vDphAoGADmWo\n"
    <> "wW1BZbYoiAPP/7i6rCIv/hGPFqnZ7Elhc1WfTLw+DC1+bbWHoUHcn4qnWYf1i6n0\n"
    <> "WzNPBiFqXa3GXBaiyyO1/j4bfGyUBYuO0ZPmCknMrGeTzbnFMmL2tFROrwXAIxP8\n"
    <> "bPWiQJL2J+gG8P+O5XmpBhmwJvffshhxPf4m7GMCgYA84q14KFXQqDzepYQfOVwK\n"
    <> "tHWHyhkGvPQ2Zao3lEuzBqvLqJDidWvdcoZZaFT1UNPMmmuJP7V2VyaYaWDjyUwG\n"
    <> "p1fpflPQJlghj//p4GmNPr0/V1a3Nm6TDTVt8Y9iFb98IrP9Vn8z25OQ6l3wt67s\n"
    <> "KQWgiN/8oPk6HrOAE8KBTA==\n"
    <> "-----END PRIVATE KEY-----\n"

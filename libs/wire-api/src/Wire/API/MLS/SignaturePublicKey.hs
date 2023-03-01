module Wire.API.MLS.SignaturePublicKey where

import Imports
import Wire.API.MLS.Serialisation

newtype SignaturePublicKey = SignaturePublicKey {unSignaturePublicKey :: ByteString}

instance ParseMLS SignaturePublicKey where
  parseMLS = SignaturePublicKey <$> parseMLSBytes @VarInt

--------------------------------------------------------------------------------
-- Copyright © 2011 National Institute of Aerospace / Galois, Inc.
--------------------------------------------------------------------------------

-- | Generates a C99 header from a copilot-specification. The functionality
-- provided by the header must be implemented by back-ends targetting C99.

module Copilot.Compile.Header.C99 (c99HeaderName, genC99Header) where

import Copilot.Core.Version
import Data.List (intersperse)
import Text.PrettyPrint.HughesPJ
import Prelude hiding (unlines)

--------------------------------------------------------------------------------

c99HeaderName :: Name -> String
c99HeaderName = (++ "_copilot.h")

genC99Header :: Name -> Spec -> IO ()
genC99Header pname spec = writeFile (c99HeaderName pname) (c99Header pname spec)

c99Header :: Name -> Spec -> String
c99Header pname spec = render $ concatH $
  [ text "/* Generated by Copilot Core v." <+> text version <+> text "*/"
  , text ""
  , ppHeaders
  , text ""
  , text "/* Observers (defined by Copilot): */"
  , text ""
  , ppObservers (specObservers spec)
  , text ""
  , text "/* Triggers (must be defined by user): */"
  , text ""
  , ppTriggerPrototypes (specTriggers spec)
  , text ""
  , text "/* External variables (must be defined by user): */"
  , text ""
  , ppExternalVariables (externVars spec)
  , text ""
  , text "/* External arrays (must be defined by user): */"
  , text ""
  , ppExternalArrays (externArrays spec)
  , text ""
  , text "/* External functions (must be defined by user): */"
  , text ""
  , ppExternalFunctions (externFuns spec)
  , text ""
  , text "/* Step function: */"
  , text ""
  , ppStep pname
  ]

--------------------------------------------------------------------------------

ppHeaders :: Doc
ppHeaders = unlines
  [ "#include <stdint.h>"
  , "#include <stdbool.h>"
  ]

--------------------------------------------------------------------------------

ppObservers :: [Observer] -> Doc
ppObservers = concatH . map ppObserver

ppObserver :: Observer -> Doc
ppObserver
  Observer
    { observerName     = name
    , observerExprType = t } =
        string "extern" <+> string (typeSpec (UType t)) <+>
        string name <> text ";"

--------------------------------------------------------------------------------

ppTriggerPrototypes :: [Trigger] -> Doc
ppTriggerPrototypes = concatH . map ppTriggerPrototype

ppTriggerPrototype :: Trigger -> Doc
ppTriggerPrototype
  Trigger
    { triggerName = name
    , triggerArgs = args } =
        string "void" <+> string name <+> string "(" <> ppArgs args <> string ");"

  where

  ppArgs :: [UExpr] -> Doc
  ppArgs = concatH . intersperse (text ",") . map ppArg

  ppArg :: UExpr -> Doc
  ppArg UExpr { uExprType = t } = text (typeSpec (UType t))

--------------------------------------------------------------------------------

ppExternalVariables :: [ExternVar] -> Doc
ppExternalVariables = concatH . map ppExternalVariable

ppExternalVariable :: ExternVar -> Doc
ppExternalVariable
  ExternVar
    { externVarName = name
    , externVarType = t } =
        string "extern" <+> text (typeSpec t) <+> text name <> text ";"

--------------------------------------------------------------------------------

ppExternalArrays :: [ExternArray] -> Doc
ppExternalArrays = concatH . map ppExternalArray

ppExternalArray :: ExternArray -> Doc
ppExternalArray
  ExternArray
    { externArrayName = name
    , externArrayType = t } =
        string "extern" <+> text (typeSpec t) <+> text "*" <+>
        text name <> text ";"

--------------------------------------------------------------------------------

ppExternalFunctions :: [ExternFun] -> Doc
ppExternalFunctions = concatH . map ppExternalFunction

ppExternalFunction :: ExternFun -> Doc
ppExternalFunction
  ExternFun
    { externFunName      = name
    , externFunType      = t
    , externFunArgsTypes = args } =
        string (typeSpec t) <+> string name <+>
        string "(" <> ppArgs args <> string ");"

  where

  ppArgs :: [UType] -> Doc
  ppArgs = concatH . intersperse (text ",") . map ppArg

  ppArg :: UType -> Doc
  ppArg UType { uTypeType = t } = text (typeSpec (UType t))

--------------------------------------------------------------------------------

typeSpec :: UType -> String
typeSpec UType { uTypeType = t } = typeSpec' t

  where

  typeSpec' (Bool   _) = "bool"
  typeSpec' (Int8   _) = "int8_t"
  typeSpec' (Int16  _) = "int16_t"
  typeSpec' (Int32  _) = "int32_t"
  typeSpec' (Int64  _) = "int64_t"
  typeSpec' (Word8  _) = "uint8_t"
  typeSpec' (Word16 _) = "uint16_t"
  typeSpec' (Word32 _) = "uint32_t"
  typeSpec' (Word64 _) = "uint64_t"
  typeSpec' (Float  _) = "float"
  typeSpec' (Double _) = "double"

--------------------------------------------------------------------------------

ppStep :: Name -> Doc
ppStep name = text "void step_" <> text name <> text "();"

--------------------------------------------------------------------------------

-- Utility functions:

string :: String -> Doc
string = text

concatV :: [Doc] -> Doc
concatV = foldr (<>) empty

concatH :: [Doc] -> Doc
concatH = foldr ($$) empty

unlines :: [String] -> Doc
unlines = concatH . map text

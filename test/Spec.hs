{-# LANGUAGE OverloadedStrings #-}

module Main (main) where

import Data.Aeson (Value (..))
import qualified Data.Aeson as Aeson
import qualified Data.Aeson.Key as Key
import qualified Data.Aeson.KeyMap as KeyMap
import qualified Data.ByteString.Lazy as BL
import qualified Data.ByteString.Lazy.Char8 as BL8
import qualified Data.Text as T
import qualified Data.Vector as V
import Stakeholder.App (Result (..), runArgs)
import Test.Tasty (TestTree, defaultMain, testGroup)
import Test.Tasty.HUnit
import qualified Test.Tasty.QuickCheck as QC

main :: IO ()
main = defaultMain tests

tests :: TestTree
tests =
    testGroup
        "haskell-stakeholder"
        [ testCase "list-values exposes the full registry and dedicated renderer keys" testListValues
        , testGroup "dedicated family metadata" (map dedicatedCase dedicatedFamilies)
        , QC.testProperty "deterministic json stays stable for the same seed" propDeterministic
        , testCase "experimental provider flags fail fast" testExperimentalFailFast
        ]

dedicatedFamilies :: [(String, String, String, String)]
dedicatedFamilies =
    [ ("code_analyzer", "classic-six.code_analyzer", "analysisFocus", "typed interfaces, agent-authored patches, and MCP assumptions")
    , ("data_processing", "classic-six.data_processing", "dataWindow", "embeddings, semantic chunks, and batch transforms with deterministic ordering")
    , ("jargon", "classic-six.jargon", "languagePolicy", "credible 2026 terminology instead of fake-deep phrasing")
    , ("metrics", "classic-six.metrics", "signalBlend", "queue depth, token spend, and GPU occupancy in a single operations lane")
    , ("network_activity", "classic-six.network_activity", "transportMix", "RPC, event-stream, and adapter traffic under deterministic retry rules")
    , ("system_monitoring", "classic-six.system_monitoring", "telemetryScope", "collector pressure, runner health, and policy-denial signals across the stack")
    , ("agent_workflows", "modern-core.agent_workflows", "coordinationMode", "delegated agent work, approval gates, and cross-repo handoff envelopes")
    , ("platform_engineering", "modern-core.platform_engineering", "platformSurface", "golden paths, identity boundaries, and queue ownership in the shared platform lane")
    , ("observability_ai_runtime", "modern-core.observability_ai_runtime", "runtimeSignals", "trace spans, token burn, GPU pressure, and policy denials in one runtime lane")
    , ("delivery_preview_ops", "modern-core.delivery_preview_ops", "deliveryGuardrail", "preview deploys, canaries, release flags, and rollback checkpoints under seed control")
    , ("supply_chain_security", "modern-core.supply_chain_security", "supplyChainPosture", "provenance, attestations, dependency drift, and secret exposure in one security lane")
    ]

runStdout :: [String] -> Assertion -> IO BL.ByteString
runStdout args _ = do
    let result = runArgs args
    assertEqual "expected success" 0 (resultExitCode result)
    pure (resultStdout result)

parseJson :: BL.ByteString -> Assertion -> IO Value
parseJson payload _ =
    case Aeson.eitherDecode payload of
        Left err -> assertFailure err >> pure Null
        Right value -> pure value

expectObject :: Value -> Assertion -> IO Aeson.Object
expectObject (Object o) _ = pure o
expectObject _ _ = assertFailure "expected JSON object" >> pure KeyMap.empty

expectArray :: Value -> Assertion -> IO [Value]
expectArray (Array v) _ = pure (V.toList v)
expectArray _ _ = assertFailure "expected JSON array" >> pure []

lookupKeyValue :: Aeson.Object -> T.Text -> Assertion -> IO Value
lookupKeyValue obj key _ =
    case KeyMap.lookup (Key.fromText key) obj of
        Just value -> pure value
        Nothing -> assertFailure ("missing key: " <> T.unpack key) >> pure Null

expectText :: Value -> Assertion -> IO T.Text
expectText (String t) _ = pure t
expectText _ _ = assertFailure "expected JSON string" >> pure ""

expectBool :: Value -> Assertion -> IO Bool
expectBool (Bool b) _ = pure b
expectBool _ _ = assertFailure "expected JSON bool" >> pure False

testListValues :: Assertion
testListValues = do
    payload <- runStdout ["--list-values"] (pure ())
    value <- parseJson payload (pure ())
    root <- expectObject value (pure ())
    generatorFamiliesValue <- lookupKeyValue root "generatorFamilies" (pure ())
    generatorFamilies <- expectArray generatorFamiliesValue (pure ())
    assertBool "expected broad registry" (length generatorFamilies >= 30)
    mapM_ (assertRenderer generatorFamilies) dedicatedFamilies
  where
    assertRenderer generatorFamilies (familyId', rendererKey', _, _) = do
        family <-
            case filter (matchesId familyId') generatorFamilies of
                (v : _) -> pure v
                [] -> assertFailure ("missing family " <> familyId') >> pure Null
        obj <- expectObject family (pure ())
        rendererValue <- lookupKeyValue obj "rendererKey" (pure ()) >>= flip expectText (pure ())
        smokeValue <- lookupKeyValue obj "smoke" (pure ()) >>= flip expectBool (pure ())
        assertEqual "rendererKey mismatch" (T.pack rendererKey') rendererValue
        assertBool "expected smoke family" smokeValue
    matchesId wanted (Object obj) =
        case KeyMap.lookup "id" obj of
            Just (String actual) -> actual == T.pack wanted
            _ -> False
    matchesId _ _ = False

dedicatedCase :: (String, String, String, String) -> TestTree
dedicatedCase (familyId', rendererKey', focusKey', focusValue') =
    testCase familyId' $ do
        payload <-
            runStdout
                [ "--dev-type"
                , "backend"
                , "--complexity"
                , "medium"
                , "--seed"
                , familyId' <> "-seed"
                , "--focus-family"
                , familyId'
                , "--output-format"
                , "json"
                ]
                (pure ())
        value <- parseJson payload (pure ())
        root <- expectObject value (pure ())
        eventsValue <- lookupKeyValue root "events" (pure ())
        events <- expectArray eventsValue (pure ())
        activity <- case events of
            (v : _) -> pure v
            [] -> assertFailure "expected at least one event" >> pure Null
        activityObj <- expectObject activity (pure ())
        messageValue <- lookupKeyValue activityObj "message" (pure ()) >>= flip expectText (pure ())
        contextValue <- lookupKeyValue activityObj "context" (pure ())
        contextObj <- expectObject contextValue (pure ())
        rendererValue <- lookupKeyValue contextObj "renderer" (pure ()) >>= flip expectText (pure ())
        detailValue <- lookupKeyValue contextObj "detail" (pure ()) >>= flip expectText (pure ())
        familyFocusKeyValue <- lookupKeyValue contextObj "familyFocusKey" (pure ()) >>= flip expectText (pure ())
        focusValueActual <- lookupKeyValue contextObj (T.pack focusKey') (pure ()) >>= flip expectText (pure ())
        sourceRepo <- lookupKeyValue contextObj "traceabilitySourceRepo" (pure ()) >>= flip expectText (pure ())
        javaRepo <- lookupKeyValue contextObj "traceabilityJavaRepo" (pure ()) >>= flip expectText (pure ())
        contractRepo <- lookupKeyValue contextObj "traceabilityContractRepo" (pure ()) >>= flip expectText (pure ())
        parityClass <- lookupKeyValue contextObj "traceabilityParityClass" (pure ()) >>= flip expectText (pure ())
        assertEqual "renderer mismatch" (T.pack rendererKey') rendererValue
        assertEqual "detail mismatch" "dedicated first-push renderer" detailValue
        assertEqual "focus key mismatch" (T.pack focusKey') familyFocusKeyValue
        assertEqual "focus value mismatch" (T.pack focusValue') focusValueActual
        assertEqual "source repo mismatch" "rust-stakeholder" sourceRepo
        assertEqual "java repo mismatch" "java-stakeholder" javaRepo
        assertEqual "contract repo mismatch" "stakeholder-core" contractRepo
        assertEqual "parity class mismatch" "full-parity" parityClass
        assertBool "message should cite Java, Rust, and stakeholder-core" ("Java, Rust, and stakeholder-core" `T.isInfixOf` messageValue)

propDeterministic :: QC.NonNegative Int -> Bool
propDeterministic (QC.NonNegative n) =
    resultStdout first == resultStdout second
  where
    seed = "prop-" <> show n
    args = ["--dev-type", "backend", "--complexity", "medium", "--seed", seed, "--focus-family", "code_analyzer", "--output-format", "json"]
    first = runArgs args
    second = runArgs args

testExperimentalFailFast :: Assertion
testExperimentalFailFast = do
    let result = runArgs ["--experimental-provider", "openai-compatible"]
    assertEqual "expected fail-fast exit code" 2 (resultExitCode result)
    assertBool
        "stderr should mention experimental-provider"
        ( T.isInfixOf
            "experimental-provider is not implemented yet in haskell-stakeholder"
            (T.pack (BL8.unpack (resultStderr result)))
        )

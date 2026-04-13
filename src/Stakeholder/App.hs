{-# LANGUAGE OverloadedStrings #-}

module Stakeholder.App (
    Result (..),
    runArgs,
    runCli,
)
where

import Data.Aeson (Value (..), encode, object, (.=))
import qualified Data.Aeson.Key as Key
import qualified Data.Aeson.KeyMap as KeyMap
import Data.Bits (xor)
import qualified Data.ByteString as BS
import qualified Data.ByteString.Lazy as BL
import qualified Data.ByteString.Lazy.Char8 as BL8
import Data.List (isPrefixOf)
import qualified Data.Text as T
import qualified Data.Text.Encoding as TE
import Data.Word (Word64)
import Numeric (showHex)
import System.Exit (ExitCode (..), exitWith)
import System.IO (stderr)

-- Core data

data FamilyDef = FamilyDef
    { familyId :: T.Text
    , familyLabel :: T.Text
    , familyGroup :: T.Text
    , familySummary :: T.Text
    , familyRendererKey :: T.Text
    , familySmoke :: Bool
    }
    deriving (Eq, Show)

data DedicatedMeta = DedicatedMeta
    { metaFocusKey :: T.Text
    , metaFocusValue :: T.Text
    , metaSourcePath :: T.Text
    , metaJavaPath :: T.Text
    , metaContractPath :: T.Text
    }
    deriving (Eq, Show)

data SessionConfig = SessionConfig
    { cfgDevType :: T.Text
    , cfgComplexity :: T.Text
    , cfgJargon :: T.Text
    , cfgOutputFormat :: T.Text
    , cfgSeed :: T.Text
    , cfgFocusFamily :: T.Text
    , cfgFramework :: T.Text
    , cfgProject :: T.Text
    , cfgDuration :: Int
    , cfgAlerts :: Bool
    , cfgTeam :: Bool
    , cfgMinimal :: Bool
    , cfgTrace :: Bool
    , cfgNoColor :: Bool
    }
    deriving (Eq, Show)

data ParseState = ParseState
    { psConfig :: SessionConfig
    , psShowHelp :: Bool
    , psListValues :: Bool
    , psExperimental :: Maybe T.Text
    }
    deriving (Eq, Show)

data Result = Result
    { resultExitCode :: Int
    , resultStdout :: BL.ByteString
    , resultStderr :: BL.ByteString
    }
    deriving (Eq, Show)

defaultSessionConfig :: SessionConfig
defaultSessionConfig =
    SessionConfig
        { cfgDevType = "backend"
        , cfgComplexity = "medium"
        , cfgJargon = "normal"
        , cfgOutputFormat = "text"
        , cfgSeed = "haskell-default-seed"
        , cfgFocusFamily = "code_analyzer"
        , cfgFramework = ""
        , cfgProject = "stakeholder-circus"
        , cfgDuration = 15
        , cfgAlerts = False
        , cfgTeam = False
        , cfgMinimal = False
        , cfgTrace = False
        , cfgNoColor = False
        }

defaultParseState :: ParseState
defaultParseState = ParseState defaultSessionConfig False False Nothing

families :: [FamilyDef]
families =
    [ FamilyDef "code_analyzer" "code_analyzer" "classic-six" "code review, build graph, SDK drift" "classic-six.code_analyzer" True
    , FamilyDef "data_processing" "data_processing" "classic-six" "fixtures, pipelines, transforms" "classic-six.data_processing" True
    , FamilyDef "jargon" "jargon" "classic-six" "credible domain language" "classic-six.jargon" True
    , FamilyDef "metrics" "metrics" "classic-six" "token cost, burn, queue depth" "classic-six.metrics" True
    , FamilyDef "network_activity" "network_activity" "classic-six" "API, SSE, and transport events" "classic-six.network_activity" True
    , FamilyDef "system_monitoring" "system_monitoring" "classic-six" "health, backpressure, saturation" "classic-six.system_monitoring" True
    , FamilyDef "agent_workflows" "agent_workflows" "modern-core" "delegation, retries, approvals" "modern-core.agent_workflows" True
    , FamilyDef "platform_engineering" "platform_engineering" "modern-core" "golden paths, identity, queues" "modern-core.platform_engineering" True
    , FamilyDef "observability_ai_runtime" "observability_ai_runtime" "modern-core" "tracing, burn rate, GPU pressure" "modern-core.observability_ai_runtime" True
    , FamilyDef "delivery_preview_ops" "delivery_preview_ops" "modern-core" "preview deploys, canaries, flags" "modern-core.delivery_preview_ops" True
    , FamilyDef "supply_chain_security" "supply_chain_security" "modern-core" "provenance, attestations, secrets" "modern-core.supply_chain_security" True
    , FamilyDef "ai_inference_ops" "ai_inference_ops" "ai-governance" "model routing, fallback, cache" "ai-governance.fallback" False
    , FamilyDef "knowledge_retrieval" "knowledge_retrieval" "ai-governance" "stale embeddings, recall, citations" "ai-governance.fallback" False
    , FamilyDef "evaluation_and_guardrails" "evaluation_and_guardrails" "ai-governance" "eval drift, guardrail failures" "ai-governance.fallback" False
    , FamilyDef "aibom_provenance" "aibom_provenance" "ai-governance" "model lineage and AI bills of materials" "ai-governance.fallback" False
    , FamilyDef "data_governance_compliance" "data_governance_compliance" "ai-governance" "consent, retention, audit" "ai-governance.fallback" False
    , FamilyDef "finops_capacity" "finops_capacity" "ai-governance" "budget, quota, resource burn" "ai-governance.fallback" False
    , FamilyDef "identity_and_trust" "identity_and_trust" "security-blockchain" "keys, delegation, trust boundaries" "security-blockchain.fallback" False
    , FamilyDef "agent_boundary_security" "agent_boundary_security" "security-blockchain" "tool, prompt, and auth boundaries" "security-blockchain.fallback" False
    , FamilyDef "blockchain_protocol_ops" "blockchain_protocol_ops" "security-blockchain" "rollups, validators, account abstraction" "security-blockchain.fallback" False
    , FamilyDef "cross_chain_interop" "cross_chain_interop" "security-blockchain" "chain abstraction and transfers" "security-blockchain.fallback" False
    , FamilyDef "proof_and_sequencer_ops" "proof_and_sequencer_ops" "security-blockchain" "proof queues, ordering, MEV" "security-blockchain.fallback" False
    , FamilyDef "fhir_profile_generator" "fhir_profile_generator" "health-protocol" "FHIR resource generation" "health-protocol.fallback" False
    , FamilyDef "smart_launch_oauth" "smart_launch_oauth" "health-protocol" "SMART launch and OAuth context" "health-protocol.fallback" False
    , FamilyDef "bulk_fhir_population_ops" "bulk_fhir_population_ops" "health-protocol" "bulk export and analytics" "health-protocol.fallback" False
    , FamilyDef "hl7v2_feed_ops" "hl7v2_feed_ops" "health-protocol" "ADT/ORU feed handling" "health-protocol.fallback" False
    , FamilyDef "clinical_workflow_events" "clinical_workflow_events" "health-protocol" "hooks, subscriptions, workflow events" "health-protocol.fallback" False
    , FamilyDef "dicomweb_imaging_ops" "dicomweb_imaging_ops" "health-protocol" "QIDO/WADO/STOW imaging flows" "health-protocol.fallback" False
    , FamilyDef "openehr_semantic_record_ops" "openehr_semantic_record_ops" "health-protocol" "archetypes, templates, AQL" "health-protocol.fallback" False
    , FamilyDef "device_telemetry_clinical" "device_telemetry_clinical" "health-protocol" "bedside telemetry and alerts" "health-protocol.fallback" False
    , FamilyDef "emr_vendor_adapter" "emr_vendor_adapter" "health-protocol" "EMR vendor adapter flows" "health-protocol.fallback" False
    , FamilyDef "ocpp_chargepoint_ops" "ocpp_chargepoint_ops" "health-protocol" "OCPP 1.6 and 2.x chargepoint ops" "health-protocol.fallback" False
    , FamilyDef "ocpi_roaming_ops" "ocpi_roaming_ops" "health-protocol" "roaming, sessions, tariffs" "health-protocol.fallback" False
    , FamilyDef "mcp_a2a_ops" "mcp_a2a_ops" "health-protocol" "MCP and A2A tool calls" "health-protocol.fallback" False
    , FamilyDef "streaming_bus_ops" "streaming_bus_ops" "health-protocol" "Kafka, NATS, MQTT, event buses" "health-protocol.fallback" False
    , FamilyDef "service_mesh_rpc_ops" "service_mesh_rpc_ops" "health-protocol" "gRPC and GraphQL federation" "health-protocol.fallback" False
    , FamilyDef "edge_client_runtime" "edge_client_runtime" "health-protocol" "edge UI, hydration, offline sync" "health-protocol.fallback" False
    , FamilyDef "embedded_agentic_pipeline" "embedded_agentic_pipeline" "health-protocol" "deterministic control loops" "health-protocol.fallback" False
    , FamilyDef "multilingual_security_packs" "multilingual_security_packs" "overlay-quantum" "localized security/operator tone" "overlay-quantum.fallback" False
    , FamilyDef "security_persona_packs" "security_persona_packs" "overlay-quantum" "SOC, CTI, reverse-engineering personas" "overlay-quantum.fallback" False
    , FamilyDef "hybrid_runtime_ops" "hybrid_runtime_ops" "overlay-quantum" "quantum jobs, sessions, batches" "overlay-quantum.fallback" False
    , FamilyDef "capacity_cost_controller" "capacity_cost_controller" "overlay-quantum" "queues, reservations, spend controls" "overlay-quantum.fallback" False
    , FamilyDef "batch_execution_tuner" "batch_execution_tuner" "overlay-quantum" "batch throughput and benchmarks" "overlay-quantum.fallback" False
    , FamilyDef "compiler_maintainer" "compiler_maintainer" "overlay-quantum" "transpiler and plugin maintenance" "overlay-quantum.fallback" False
    , FamilyDef "interop_adapter_engineer" "interop_adapter_engineer" "overlay-quantum" "OpenQASM and QIR adaptation" "overlay-quantum.fallback" False
    , FamilyDef "preflight_capacity_planner" "preflight_capacity_planner" "overlay-quantum" "resource estimation and gating" "overlay-quantum.fallback" False
    , FamilyDef "simulator_performance_engineer" "simulator_performance_engineer" "overlay-quantum" "simulators, GPU, local mode" "overlay-quantum.fallback" False
    ]

devTypes, jargonLevels, complexities, outputFormats :: [T.Text]
devTypes = ["backend", "blockchain", "data-science", "dev-ops", "frontend", "fullstack", "game-development", "machine-learning", "security", "systems-programming"]
jargonLevels = ["low", "normal", "high", "extreme"]
complexities = ["low", "medium", "high", "extreme"]
outputFormats = ["text", "json"]

runCli :: [String] -> IO ()
runCli args = do
    let result = runArgs args
    BL8.putStr (resultStdout result)
    BL8.hPutStr stderr (resultStderr result)
    if resultExitCode result == 0
        then pure ()
        else exitWith (ExitFailure (resultExitCode result))

runArgs :: [String] -> Result
runArgs args =
    case parseArgs defaultParseState args of
        Left err -> failure err
        Right st
            | psShowHelp st -> success helpText
            | Just provider <- psExperimental st ->
                failure $ "experimental-provider is not implemented yet in haskell-stakeholder (" <> provider <> ")"
            | psListValues st -> success (encode listValuesPayload)
            | otherwise ->
                case requireFamily (cfgFocusFamily (psConfig st)) of
                    Left err -> failure err
                    Right family ->
                        if cfgOutputFormat (psConfig st) == "json"
                            then success (encode (sessionPayload (psConfig st) family))
                            else success (textPayload (psConfig st) family)

success :: BL.ByteString -> Result
success out = Result 0 out BL.empty

failure :: T.Text -> Result
failure msg = Result 2 BL.empty (renderText (msg <> "\n"))

helpText :: BL.ByteString
helpText =
    BL8.unlines
        [ "Usage: haskell-stakeholder [options]"
        , "  --list-values"
        , "  --dev-type <backend|blockchain|data-science|dev-ops|frontend|fullstack|game-development|machine-learning|security|systems-programming>"
        , "  --complexity <low|medium|high|extreme>"
        , "  --jargon <low|normal|high|extreme>"
        , "  --output-format <text|json>"
        , "  --seed <value>"
        , "  --focus-family <family-id>"
        , "  --alerts"
        , "  --team"
        , "  --minimal"
        , "  --trace"
        , "  experimental provider flags are parsed but fail fast"
        ]

renderText :: T.Text -> BL.ByteString
renderText = BL.fromStrict . TE.encodeUtf8

parseArgs :: ParseState -> [String] -> Either T.Text ParseState
parseArgs st [] = Right st
parseArgs st (arg : rest)
    | arg == "--help" = parseArgs st{psShowHelp = True} rest
    | arg == "--list-values" = parseArgs st{psListValues = True} rest
    | arg == "--alerts" = parseArgs st{psConfig = (psConfig st){cfgAlerts = True}} rest
    | arg == "--team" = parseArgs st{psConfig = (psConfig st){cfgTeam = True}} rest
    | arg == "--minimal" = parseArgs st{psConfig = (psConfig st){cfgMinimal = True}} rest
    | arg == "--trace" = parseArgs st{psConfig = (psConfig st){cfgTrace = True}} rest
    | arg == "--no-color" = parseArgs st{psConfig = (psConfig st){cfgNoColor = True}} rest
    | arg == "--dev-type" = withValue arg rest $ \v ->
        if T.pack v `elem` devTypes
            then parseArgs st{psConfig = (psConfig st){cfgDevType = T.pack v}} (tail rest)
            else Left (invalidValue "--dev-type" v)
    | arg == "--complexity" = withValue arg rest $ \v ->
        if T.pack v `elem` complexities
            then parseArgs st{psConfig = (psConfig st){cfgComplexity = T.pack v}} (tail rest)
            else Left (invalidValue "--complexity" v)
    | arg == "--jargon" = withValue arg rest $ \v ->
        if T.pack v `elem` jargonLevels
            then parseArgs st{psConfig = (psConfig st){cfgJargon = T.pack v}} (tail rest)
            else Left (invalidValue "--jargon" v)
    | arg == "--output-format" = withValue arg rest $ \v ->
        if T.pack v `elem` outputFormats
            then parseArgs st{psConfig = (psConfig st){cfgOutputFormat = T.pack v}} (tail rest)
            else Left (invalidValue "--output-format" v)
    | arg == "--seed" = withValue arg rest $ \v -> parseArgs st{psConfig = (psConfig st){cfgSeed = T.pack v}} (tail rest)
    | arg == "--focus-family" = withValue arg rest $ \v -> parseArgs st{psConfig = (psConfig st){cfgFocusFamily = T.pack v}} (tail rest)
    | arg == "--framework" = withValue arg rest $ \v -> parseArgs st{psConfig = (psConfig st){cfgFramework = T.pack v}} (tail rest)
    | arg == "--project" = withValue arg rest $ \v -> parseArgs st{psConfig = (psConfig st){cfgProject = T.pack v}} (tail rest)
    | arg == "--duration" = withValue arg rest $ \v ->
        case reads v of
            [(n, "")] -> parseArgs st{psConfig = (psConfig st){cfgDuration = n}} (tail rest)
            _ -> Left (invalidValue "--duration" v)
    | arg == "--experimental-provider" = withValue arg rest $ \v -> parseArgs st{psExperimental = Just (T.pack v)} (tail rest)
    | experimentalProviderPrefix `isPrefixOf` arg = parseArgs st{psExperimental = Just (T.pack (drop (length experimentalProviderPrefix) arg))} rest
    | otherwise = Left ("Unknown argument '" <> T.pack arg <> "'.")
  where
    experimentalProviderPrefix = "--experimental-provider=" :: String

withValue :: String -> [String] -> (String -> Either T.Text ParseState) -> Either T.Text ParseState
withValue flag values next =
    case values of
        [] -> Left ("Missing value for " <> T.pack flag <> ".")
        (v : _) -> next v

invalidValue :: T.Text -> String -> T.Text
invalidValue flag value = "Invalid value '" <> T.pack value <> "' for " <> flag <> "."

requireFamily :: T.Text -> Either T.Text FamilyDef
requireFamily wanted =
    case filter ((== wanted) . familyId) families of
        (f : _) -> Right f
        [] -> Left ("Unknown family '" <> wanted <> "'.")

listValuesPayload :: Value
listValuesPayload =
    object
        [ "generatorFamilies" .= fmap familyJson families
        , "devTypes" .= devTypes
        , "jargonLevels" .= jargonLevels
        , "complexities" .= complexities
        , "outputFormats" .= outputFormats
        ]

familyJson :: FamilyDef -> Value
familyJson f =
    object
        [ "id" .= familyId f
        , "label" .= familyLabel f
        , "group" .= familyGroup f
        , "summary" .= familySummary f
        , "rendererKey" .= familyRendererKey f
        , "renderer" .= familyRendererKey f
        , "smoke" .= familySmoke f
        ]

sessionPayload :: SessionConfig -> FamilyDef -> Value
sessionPayload cfg family =
    object
        [ "sessionId" .= sessionId
        , "mode" .= ("deterministic" :: T.Text)
        , "config" .= configJson
        , "events" .= [event]
        ]
  where
    meta = dedicatedMeta (familyId family)
    sessionId = T.pack ("haskell-" <> showHex (deterministicHash (cfgSeed cfg) (familyId family)) "")
    configJson =
        object
            [ "devType" .= cfgDevType cfg
            , "complexity" .= cfgComplexity cfg
            , "jargon" .= cfgJargon cfg
            , "outputFormat" .= cfgOutputFormat cfg
            , "seed" .= cfgSeed cfg
            , "focusFamily" .= cfgFocusFamily cfg
            , "framework" .= cfgFramework cfg
            , "project" .= cfgProject cfg
            , "duration" .= cfgDuration cfg
            , "alerts" .= cfgAlerts cfg
            , "team" .= cfgTeam cfg
            , "minimal" .= cfgMinimal cfg
            , "trace" .= cfgTrace cfg
            , "noColor" .= cfgNoColor cfg
            ]
    event =
        Object
            ( KeyMap.fromList
                [ ("eventType", String "generator.activity")
                , ("sequence", Number 1)
                , ("message", String (sessionMessage family meta detail))
                , ("timestamp", String (timestampText (cfgSeed cfg) (familyId family)))
                , ("context", contextObject family meta detail)
                ]
            )
    detail = if familySmoke family then "dedicated first-push renderer" else "grouped fallback renderer"

contextObject :: FamilyDef -> DedicatedMeta -> T.Text -> Value
contextObject family meta detail =
    Object
        ( KeyMap.fromList
            [ ("family", String (familyId family))
            , ("renderer", String (familyRendererKey family))
            , ("detail", String detail)
            , ("familyFocusKey", String (metaFocusKey meta))
            , (Key.fromText (metaFocusKey meta), String (metaFocusValue meta))
            , ("traceabilitySourceRepo", String "rust-stakeholder")
            , ("traceabilityJavaRepo", String "java-stakeholder")
            , ("traceabilityContractRepo", String "stakeholder-core")
            , ("traceabilityParityClass", String "full-parity")
            , ("traceabilitySourcePath", String (metaSourcePath meta))
            , ("traceabilityJavaPath", String (metaJavaPath meta))
            , ("traceabilityContractPath", String (metaContractPath meta))
            ]
        )

textPayload :: SessionConfig -> FamilyDef -> BL.ByteString
textPayload cfg family =
    renderText $ sessionId <> " deterministic " <> cfgDevType cfg <> "\n" <> sessionMessage family meta detail
  where
    sessionId = T.pack ("haskell-" <> showHex (deterministicHash (cfgSeed cfg) (familyId family)) "")
    meta = dedicatedMeta (familyId family)
    detail = if familySmoke family then "dedicated first-push renderer" else "grouped fallback renderer"

sessionMessage :: FamilyDef -> DedicatedMeta -> T.Text -> T.Text
sessionMessage family meta detail =
    familyId family <> ": " <> metaFocusValue meta <> "; " <> detail <> " aligned to Java, Rust, and stakeholder-core with a pure deterministic core."

dedicatedMeta :: T.Text -> DedicatedMeta
dedicatedMeta familyIdText
    | familyIdText == "code_analyzer" = DedicatedMeta "analysisFocus" "typed interfaces, agent-authored patches, and MCP assumptions" "src/generators/code_analyzer.rs" "java-stakeholder/src/main/java/stakeholder/generators/CodeAnalyzerRenderer.java" "stakeholder-core/docs/traceability-matrix.md#code_analyzer"
    | familyIdText == "data_processing" = DedicatedMeta "dataWindow" "embeddings, semantic chunks, and batch transforms with deterministic ordering" "src/generators/data_processing.rs" "java-stakeholder/src/main/java/stakeholder/generators/DataProcessingRenderer.java" "stakeholder-core/docs/traceability-matrix.md#data_processing"
    | familyIdText == "jargon" = DedicatedMeta "languagePolicy" "credible 2026 terminology instead of fake-deep phrasing" "src/generators/jargon.rs" "java-stakeholder/src/main/java/stakeholder/generators/JargonRenderer.java" "stakeholder-core/docs/traceability-matrix.md#jargon"
    | familyIdText == "metrics" = DedicatedMeta "signalBlend" "queue depth, token spend, and GPU occupancy in a single operations lane" "src/generators/metrics.rs" "java-stakeholder/src/main/java/stakeholder/generators/MetricsRenderer.java" "stakeholder-core/docs/traceability-matrix.md#metrics"
    | familyIdText == "network_activity" = DedicatedMeta "transportMix" "RPC, event-stream, and adapter traffic under deterministic retry rules" "src/generators/network_activity.rs" "java-stakeholder/src/main/java/stakeholder/generators/NetworkActivityRenderer.java" "stakeholder-core/docs/traceability-matrix.md#network_activity"
    | familyIdText == "system_monitoring" = DedicatedMeta "telemetryScope" "collector pressure, runner health, and policy-denial signals across the stack" "src/generators/system_monitoring.rs" "java-stakeholder/src/main/java/stakeholder/generators/SystemMonitoringRenderer.java" "stakeholder-core/docs/traceability-matrix.md#system_monitoring"
    | familyIdText == "agent_workflows" = DedicatedMeta "coordinationMode" "delegated agent work, approval gates, and cross-repo handoff envelopes" "src/generators/agent_workflows.rs" "java-stakeholder/src/main/java/stakeholder/generators/AgentWorkflowsRenderer.java" "stakeholder-core/docs/traceability-matrix.md#agent_workflows"
    | familyIdText == "platform_engineering" = DedicatedMeta "platformSurface" "golden paths, identity boundaries, and queue ownership in the shared platform lane" "src/generators/platform_engineering.rs" "java-stakeholder/src/main/java/stakeholder/generators/PlatformEngineeringRenderer.java" "stakeholder-core/docs/traceability-matrix.md#platform_engineering"
    | familyIdText == "observability_ai_runtime" = DedicatedMeta "runtimeSignals" "trace spans, token burn, GPU pressure, and policy denials in one runtime lane" "src/generators/observability_ai_runtime.rs" "java-stakeholder/src/main/java/stakeholder/generators/ObservabilityAiRuntimeRenderer.java" "stakeholder-core/docs/traceability-matrix.md#observability_ai_runtime"
    | familyIdText == "delivery_preview_ops" = DedicatedMeta "deliveryGuardrail" "preview deploys, canaries, release flags, and rollback checkpoints under seed control" "src/generators/delivery_preview_ops.rs" "java-stakeholder/src/main/java/stakeholder/generators/DeliveryPreviewOpsRenderer.java" "stakeholder-core/docs/traceability-matrix.md#delivery_preview_ops"
    | familyIdText == "supply_chain_security" = DedicatedMeta "supplyChainPosture" "provenance, attestations, dependency drift, and secret exposure in one security lane" "src/generators/supply_chain_security.rs" "java-stakeholder/src/main/java/stakeholder/generators/SupplyChainSecurityRenderer.java" "stakeholder-core/docs/traceability-matrix.md#supply_chain_security"
    | otherwise = DedicatedMeta "groupFallback" "later packet families remain grouped until their dedicated tranche lands" "src/activities.rs" "java-stakeholder/src/main/java/stakeholder/generators/GroupedFallbackRenderer.java" "stakeholder-core/docs/traceability-matrix.md#grouped-fallback"

deterministicHash :: T.Text -> T.Text -> Word64
deterministicHash seed family = BS.foldl' step offset (TE.encodeUtf8 (seed <> "::" <> family))
  where
    offset = 14695981039346656037
    prime = 1099511628211
    step h b = (h `xor` fromIntegral b) * prime

timestampText :: T.Text -> T.Text -> T.Text
timestampText seed family = T.pack ("2026-01-01T00:00:" <> seconds <> "Z")
  where
    seconds = pad2 . fromIntegral $ deterministicHash seed family `mod` 60

pad2 :: Int -> String
pad2 n
    | n < 10 = '0' : show n
    | otherwise = show n

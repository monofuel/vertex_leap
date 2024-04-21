import curly, std/[locks, json, times, options]

type
  SafetyCategory* = enum
    HARM_CATEGORY_SEXUALLY_EXPLICIT,
    HARM_CATEGORY_HATE_SPEECH,
    HARM_CATEGORY_HARASSMENT,
    HARM_CATEGORY_DANGEROUS_CONTENT
  SafetyThreshold* = enum
    BLOCK_NONE,
    BLOCK_LOW_AND_ABOVE,
    BLOCK_MED_AND_ABOVE,
    BLOCK_ONLY_HIGH
  SafetyProbability* = enum
    HARM_PROBABILITY_UNSPECIFIED,
    NEGLIGIBLE,
    LOW,
    MEDIUM,
    HIGH
  GeminiProFinishReason* = enum
    UNSPECIFIED,
    STOP,
    MAX_TOKENS,
    SAFETY,
    RECITATION,
    OTHER

  GCPCredentials* = ref object
    projectId*: string
    privateKey*: string
    clientId*: string
    clientEmail*: string
    authUri*: string
    tokenUri*: string
  VertexAIAPI* = ref object
    curlPool*: CurlPool
    curlTimeout*: float32
    location*: string # location for vertex AI Project
    credentials*: GCPCredentials # GCP service account credentials
    authLock*: Lock # Lock for auth token generation
    authExp*: Time # Expiration of the current auth token
    authToken*: string # ephemeral auth token, valid for 1 hour



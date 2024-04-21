import curly, jsony, std/[locks, times, options]

type
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

  # Gemini-Pro types
  GeminiProTextPart* = ref object
    text*: string
  GeminiProSystemInstruction* = ref object
    parts*: seq[GeminiProTextPart]
  GeminiProSafetySettings* = ref object
    category*: string
    threshold*: string
  GeminiProGenerationConfig* = ref object
    temperature*: float
    topP*: float
    topK*: int
    candidateCount*: Option[int]
    maxOutputTokens*: Option[int]
    stopSequences*: Option[seq[string]]
  GeminiProContents* = ref object
    role*: string
    parts*: seq[GeminiProTextPart]
  GeminiProRequest* = ref object
    contents*: seq[GeminiProContents]
    systemInstruction*: Option[GeminiProSystemInstruction]
    safetySettings*: seq[GeminiProSafetySettings]
    generationConfig*: GeminiProGenerationConfig
  GeminiProSafetyRating* = ref object
    category*: string # TODO enum
    probability*: string # TODO enum
    blocked*: bool
  GeminiProCitationDate* = ref object
    year*, month*, day*: int
  GeminiProCitation* = ref object
    startIndex*, endIndex*: int
    uri*, title*, license*: string
    publicationDate*: GeminiProCitationDate
  GeminiProCitationMetadata* = ref object
    citations*: seq[GeminiProCitation]
  GeminiProCandidateContent* = ref object
    parts*: seq[GeminiProTextPart]
  GeminiProCandidate* = ref object
    content*: GeminiProCandidateContent
    finishReason*: string # TODO enum
    safetyRatings*: seq[GeminiProSafetyRating]
    citationMetadata*: GeminiProCitationMetadata
  GeminiProUsageMetadata* = ref object
    promptTokenCount*, candidatesTokenCount*, totalTokenCount*: int
  GeminiProResponse* = ref object
    candidates*: seq[GeminiProCandidate]
    usageMetadata*: GeminiProUsageMetadata

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
    FINISH_REASON_UNSPECIFIED,
    FINISH_REASON_STOP,
    FINISH_REASON_MAX_TOKENS,
    FINISH_REASON_SAFETY,
    FINISH_REASON_RECITATION,
    FINISH_REASON_OTHER

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
  GeminiProInlineData* = ref object
    mimeType*: string
    data*: string
  GeminiProFileData* = ref object
    mimeType*: string
    uri*: string
  VideoOffset* = ref object
    seconds*: int
    nanos*: int
  GeminiProVideoMetadata* = ref object
    startOffset*: VideoOffset
    endOffset*: VideoOffset
  GeminiProTextPart* = ref object
    # These 3 fields form a union, only one should be set
    text*: Option[string]
    inlineData*: Option[GeminiProInlineData]
    fileData*: Option[GeminiProFileData]
  GeminiProSystemInstruction* = ref object
    role*: string # this field is ignored
    parts*: seq[GeminiProTextPart]
  GeminiProSafetySettings* = ref object
    category*: SafetyCategory
    threshold*: SafetyThreshold
  GeminiProGenerationConfig* = ref object
    temperature*: float
    topP*: float
    topK*: int
    candidateCount*: Option[int]
    maxOutputTokens*: Option[int]
    stopSequences*: Option[seq[string]]
    responseMimeType*: Option[string] # either "text/plain" or "application/json"
  GeminiProContents* = ref object
    role*: string
    parts*: seq[GeminiProTextPart]
  GeminiProFunction* = ref object
    name*: string
    description*: string
    parameters*: JsonNode # OpenAPI schema
  GeminiProTool* = ref object
    functionDescription*: seq[GeminiProFunction]
  GeminiProRequest* = ref object
    contents*: seq[GeminiProContents]
    systemInstruction*: Option[GeminiProSystemInstruction]
    tools*: Option[seq[GeminiProTool]]
    safetySettings*: seq[GeminiProSafetySettings]
    generationConfig*: GeminiProGenerationConfig
  GeminiProSafetyRating* = ref object
    category*: SafetyCategory
    probability*: SafetyProbability
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
    finishReason*: GeminiProFinishReason
    safetyRatings*: seq[GeminiProSafetyRating]
    citationMetadata*: GeminiProCitationMetadata
  GeminiProUsageMetadata* = ref object
    promptTokenCount*, candidatesTokenCount*, totalTokenCount*: int
  GeminiProResponse* = ref object
    candidates*: seq[GeminiProCandidate]
    usageMetadata*: GeminiProUsageMetadata

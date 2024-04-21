import std/[json, options], jsony, ./types, ./client

# https://cloud.google.com/vertex-ai/generative-ai/docs/model-reference/gemini

type
  GeminiProInlineData* = ref object
    mimeType*: string
    data*: string
  GeminiProFileData* = ref object
    mimeType*: string
    fileUri*: string
  VideoOffset* = ref object
    seconds*: int
    nanos*: int
  GeminiProVideoMetadata* = ref object
    startOffset*: VideoOffset
    endOffset*: VideoOffset
  GeminiProContentPart* = ref object
    # These 3 fields form a union, only one should be set
    text*: Option[string]
    inlineData*: Option[GeminiProInlineData]
    fileData*: Option[GeminiProFileData]
  GeminiProSystemInstruction* = ref object
    role*: string # this field is ignored
    parts*: seq[GeminiProContentPart]
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
    parts*: seq[GeminiProContentPart]
  GeminiProFunction* = ref object
    name*: string
    description*: string
    parameters*: JsonNode # OpenAPI schema
  GeminiProTool* = ref object
    functionDescription*: seq[GeminiProFunction]
  GeminiProRequest* = ref object
    contents*: seq[GeminiProContents]
    systemInstruction*: Option[GeminiProSystemInstruction] # not all models on vertex support this
    tools*: Option[seq[GeminiProTool]]
    safetySettings*: seq[GeminiProSafetySettings]
    generationConfig*: GeminiProGenerationConfig
  GeminiProSafetyRating* = ref object
    category*: SafetyCategory
    probability*: SafetyProbability
    severity*: string # TODO enum
    severityScore*: float
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
    parts*: seq[GeminiProContentPart]
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
    error*: JsonNode

proc dumpHook(s: var string, v: object) =
  ## jsony skip optional fields that are nil
  s.add '{'
  var i = 0
  # Normal objects.
  for k, e in v.fieldPairs:
    when compiles(e.isSome):
      if e.isSome:
        if i > 0:
          s.add ','
        s.dumpHook(k)
        s.add ':'
        s.dumpHook(e)
        inc i
    else:
      if i > 0:
        s.add ','
      s.dumpHook(k)
      s.add ':'
      s.dumpHook(e)
      inc i
  s.add '}'

proc geminiProGenerate*(api: VertexAIAPI, model: string, req: GeminiProRequest): GeminiProResponse =
  ## Call a gemini-pro related model (1.0, 1.5, vision).
  ## takes a full request object and returns a full response object

  # streamGenerateContent is also valid for gemini, but not implementing for now
  let url = api.getGenerateUrl(model, "generateContent")
  let reqStr = toJson(req)
  
  let resp = api.post(url, reqStr)
  result = fromJson(resp.body, GeminiProResponse)

proc geminiProGenerate*(api: VertexAIAPI, model: string, prompt: string, system: string = "", image: string = ""): string =
  ## Simplified version of geminiProGenerate for text generation
  
  let req = GeminiProRequest(
    generationConfig: GeminiProGenerationConfig(
      temperature: 0.2,
      topP: 0.8,
      topK: 40
    ),
    contents: @[
      GeminiProContents(
        role: "user",
        parts: @[
          GeminiProContentPart(text: option(prompt))
        ]
      )
    ]
  )

  if system != "":
    req.systemInstruction = option(
      GeminiProSystemInstruction(
        parts: @[GeminiProContentPart(text: option(system))]
      )
    )
  if image != "":
    let imgPart =
        GeminiProContentPart(
          fileData: option(GeminiProFileData(
            mimeType: "image/jpeg",
            fileUri: image
          ))
        )
    req.contents[0].parts.add(imgPart)

  let resp = geminiProGenerate(api, model, req)
  result = ""
  assert resp.candidates.len == 1
  for part in resp.candidates[0].content.parts:
    # responses are always text parts
    result.add(part.text.get)
import std/[options, json], jsony, ./types, ./client
# palm 2 API
# https://cloud.google.com/vertex-ai/generative-ai/docs/model-reference/text-chat

# only chat apis are implemented for now
# TODO implement text apis

type
  Citation* = ref object
    startIndex*: int
    endIndex*: int
    url*, title*, license*, publicationDate*: string
  CitationsMetadata* = ref object
    citations*: seq[Citation]
  LogProbs* = ref object
    tokenLogProbs*: seq[float]
    tokens*: seq[string]
    topLogProbs*: seq[JsonNode]
  SafetyAttribute* = ref object
    categories*: seq[string]
    blocked*: bool
    scores*: seq[float]
    errors*: seq[int]
  TokenCountMetadata* = ref object
    totalBillableCharacters*: int
    totalTokens*: int
  TokenMetadata* = ref object
    inputTokenCount*: TokenCountMetadata
    outputTokenCount*: TokenCountMetadata
  PredictionMetadata* = ref object
    tokenMetadata*: TokenMetadata
  VertexChatMessage* = ref object
    content*: string
    author*: string
  VertexChatHistory = seq[VertexChatMessage]
  VertexChatExample* = ref object
    input*: VertexChatMessage
    output*: VertexChatMessage
  ChatBisonChatInstance* = ref object
    context*: string
    examples*: seq[VertexChatExample]
    messages*: VertexChatHistory
  ChatBisonChatParameters* = ref object
    temperature*: float
    maxOutputTokens*: int
    topP*: float
    topK*: int
    stopSequences*: seq[string]
    candidateCount*: int
  CodeChatBisonChatParameters* = ref object
    temperature*: float
    maxOutputTokens*: int
    candidateCount*: int
  ChatBisonChatRequest* = ref object
    instances*: seq[ChatBisonChatInstance]
    parameters*: ChatBisonChatParameters
  CodeChatBisonChatRequest* = ref object
    instances*: seq[ChatBisonChatInstance]
    parameters*: CodeChatBisonChatParameters
  ChatBisonChatPrediction* = ref object
    candidates*: seq[VertexChatMessage]
    citationMetadata*: seq[CitationsMetadata]
    # logprobs*: LogProbs
    safetyAttributes*: seq[SafetyAttribute]
    # groundingMetadata
  ChatBisonChatResponse* = ref object
    predictions*: seq[ChatBisonChatPrediction]
    metadata*: PredictionMetadata

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

proc chatBisonChatGenerate*(api: VertexAIAPI, model: string, req: ChatBisonChatRequest): ChatBisonChatResponse =
  ## Call a palm2 chat model (chat bison or codechat bison)
  ## takes a full request object and returns a full response object

  let url = api.getGenerateUrl(model, "predict")
  let reqStr = toJson(req)
  
  let resp = api.post(url, reqStr)
  result = fromJson(resp.body, ChatBisonChatResponse)

proc chatBisonChatGenerate*(api: VertexAIAPI, model: string, prompt: string, context: string = ""): string =
  ## Simplified version of ChatBisonChatGenerate for text generation
  
  let req = ChatBisonChatRequest(
    parameters: ChatBisonChatParameters(
      temperature: 0.2,
      maxOutputTokens: 1024,
      topP: 0.95,
      topK: 0,
      candidateCount: 1
    ),
    instances: @[
      ChatBisonChatInstance(
        context: context,
        messages: @[
          VertexChatMessage(
            author: "USER",
            content: prompt
          )
        ]
      )
    ]
  )
  
  let resp = chatBisonChatGenerate(api, model, req)
  assert resp.predictions.len != 0
  result = resp.predictions[0].candidates[0].content

import std/[json, options], jsony, ./types, ./client

type 
  GeckoTaskType* = enum
    RETRIEVAL_QUERY, 
    RETRIEVAL_DOCUMENT, 
    SEMANTIC_SIMILARITY, 
    CLASSIFICATION, 
    CLUSTERING, 
    QUESTION_ANSWERING, 
    FACT_VERIFICATION
  GeckoInstance* = ref object
    taskType*: Option[GeckoTaskType]
    title*: Option[string]
    content*: string
  GeckoRequest* = ref object
    instances: seq[GeckoInstance]
  GeckoStatistics* = ref object
    truncated*: bool
    tokenCount*: int
  GeckoEmbedding* = ref object
    statistics*: GeckoStatistics
    values*: seq[float]
  GeckoPrediction* = ref object
    embeddings*: GeckoEmbedding
  GeckoMetadata* = ref object
    billableCharacterCount*: int
  GeckoResponse* = ref object
    predictions: seq[GeckoPrediction]
    metadata*: GeckoMetadata


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

proc geckoTextEmbed*(api: VertexAIAPI, model: string, req: GeckoRequest): GeckoResponse =

  let url = api.getGenerateUrl(model, "predict")
  let reqStr = toJson(req)
  
  let resp = api.post(url, reqStr)
  result = fromJson(resp.body, GeckoResponse)

proc geckoTextEmbed*(api: VertexAIAPI, model: string, text: string): seq[float] =
  let req = GeckoRequest(instances: @[GeckoInstance(content: text)])
  let resp = geckoTextEmbed(api, model, req)
  echo resp.predictions.len
  result = resp.predictions[0].embeddings.values


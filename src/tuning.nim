import std/[json, strformat, strutils, options], jsony, ./types, ./client

# Gemini 1.0 pro fine tuning API
# https://cloud.google.com/vertex-ai/generative-ai/docs/models/tune-gemini-overview
# https://cloud.google.com/vertex-ai/generative-ai/docs/models/gemini-use-supervised-tuning
# these docs suck: https://cloud.google.com/vertex-ai/generative-ai/docs/model-reference/tuning

# the supervised training set is a jsonl file
type
  VertexFineTuneMessage* = ref object
    role*: string # system, user, or model
    content*: string
  VertexFineTuneChat* = ref object
    messages*: seq[VertexFineTuneMessage]

# create resp
# {
#   "name": "projects/649241623633/locations/us-central1/tuningJobs/1715586718876303360",
#   "tunedModelDisplayName": "gemini-1.0-pro-002-8099975f-3eac-4132-949b-34833e964858",
#   "baseModel": "gemini-1.0-pro-002",
#   "supervisedTuningSpec": {
#     "trainingDatasetUri": "gs://cloud-samples-data/ai-platform/generative_ai/sft_train_data.jsonl",
#     "validationDatasetUri": "gs://cloud-samples-data/ai-platform/generative_ai/sft_validation_data.jsonl"
#   },
#   "state": "JOB_STATE_PENDING",
#   "createTime": "2024-04-21T20:16:16.273513Z",
#   "updateTime": "2024-04-21T20:16:16.273513Z"
# }

type
  HyperParameters* = ref object
    epochCount*: Option[int]
    learningRateMultiplier*: Option[float]
  SupervisedTuningSpec* = ref object
    trainingDatasetUri*: string # Must be a gs:// jsonl file
    validationDatasetUri*: Option[string]
  CreateGeminiProTuningJobRequest* = ref object
    baseModel*: string # "gemini-1.0-pro-002"
    supervisedTuningSpec*: SupervisedTuningSpec
    hyperParameters*: Option[HyperParameters]
    tunedModelDisplayName*: Option[string]
  TuneJob* = ref object
    name*: string
    tunedModelDisplayName*: string
    baseModel*: string
    supervisedTuningSpec*: SupervisedTuningSpec
    state*: string # JOB_STATE_PENDING
    createTime*: string
    updateTime*: string
  ListTuningJobResp* = ref object
    tuningJobs*: seq[TuneJob]


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

proc getTrainingUrl*(
  api: VertexAIAPI,
  ): string =
  ## Get the URL for the generate method
  ## palm2 models use "predict"
  ## gemini-pro models use "generateContent"
  ## streamGenerateContent is also valid but I'm not implementing it for now
  # most LLM work goes through this API, however the request / response format is often totally different
  result = &"https://{api.location}-aiplatform.googleapis.com" & 
    &"/v1/projects/{api.credentials.projectId}/locations/" & 
    &"{api.location}/tuningJobs"


# TODO uploading data training set

proc createGeminiProTuningJob*(api: VertexAIAPI, req: CreateGeminiProTuningJobRequest): TuneJob =
  let url = getTrainingUrl(api)
  let reqStr = toJson(req)
  let resp = api.post(url, reqStr)
  result = fromJson(resp.body, TuneJob)

proc listGeminiProTuningJobs*(api: VertexAIAPI): ListTuningJobResp =
  let url = getTrainingUrl(api)
  let resp = api.get(url)
  echo resp.body
  result = fromJson(resp.body, ListTuningJobResp)

proc getGeminiProTuningJob*(api: VertexAIAPI, name: string): TuneJob =
  if not name.startsWith("projects/"):
    raise newException(Exception, "Invalid tuning job name")
  let url = &"https://{api.location}-aiplatform.googleapis.com/v1/" & name
  let resp = api.get(url)
  result = fromJson(resp.body, TuneJob)

proc cancelGeminiProTuningJob*(api: VertexAIAPI, name: string) =
  if not name.startsWith("projects/"):
    raise newException(Exception, "Invalid tuning job name")
  let url = &"https://{api.location}-aiplatform.googleapis.com/v1/" & name & ":cancel"
  discard api.post(url, "")
  # docs say the response is an empty json object
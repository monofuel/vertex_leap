import jsony, std/[unittest, options, json]

type
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
  GeminiProRequest* = object
    contents*: seq[GeminiProContents]
    systemInstruction*: Option[GeminiProSystemInstruction]
    safetySettings*: GeminiProSafetySettings
    generationConfig*: GeminiProGenerationConfig

proc dumpHook*(s: var string, v: object) =
  ## jsony `hack` to skip optional fields that are nil
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

# Test serialization / deserialization of requests according to the API

proc validateJsonStrings*(json1: string, json2: string) =
  ## Compare two json strings for equivelancy
  ## hunt down those pesky nulls or other differences
  let
    parsed1 = fromJson(json1)
    parsed2 = fromJson(json2)
  
  if parsed1 != parsed2:
    echo "json1: \n", parsed1.pretty
    echo ""
    echo "json2: \n", parsed2.pretty
    echo ""
    assert false



suite "serialization":
  suite "requests":
    test "user1":
      let str = """
{
  "contents": [{
    "role": "user",
    "parts": [{
        "text": "Give me a recipe for banana bread."
    }]
  }],
  "safetySettings": {
    "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
    "threshold": "BLOCK_LOW_AND_ABOVE"
  },
  "generationConfig": {
    "temperature": 0.2,
    "topP": 0.8,
    "topK": 40
  }
}
"""
      let req = fromJson(str, GeminiProRequest)
      assert req.contents[0].role == "user"
      assert req.contents[0].parts.len == 1
      echo "TOJSON"
      let jsonStr = toJson(req)
      validateJsonStrings(str, jsonStr)

    test "user2":
      let str = """
{
  "contents": [
    {
      "role": "USER",
      "parts": [{ "text": "Hello!" }]
    },
    {
      "role": "MODEL",
      "parts": [{ "text": "Argh! What brings ye to my ship?" }]
    },
    {
      "role": "USER",
      "parts": [{ "text": "Wow! You are a real-life priate!" }]
    }
  ],
  "safetySettings": {
    "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
    "threshold": "BLOCK_LOW_AND_ABOVE"
  },
  "generationConfig": {
    "temperature": 0.2,
    "topP": 0.8,
    "topK": 40,
    "maxOutputTokens": 200,
  }
}
"""
      let req = fromJson(str, GeminiProRequest)
      assert req.contents[0].role == "USER"
      assert req.contents.len == 3
      let jsonStr = toJson(req)
      validateJsonStrings(str, jsonStr)
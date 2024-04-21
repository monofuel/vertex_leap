import curly, jwtea, jsony, ./types, std/[uri, locks, json, times, os]

proc getFreshAuthToken*(api: VertexAIAPI): string =
  acquire(api.authLock)
  # auth tokens expire in 60 minutes, adding in 10 min buffer
  if api.authExp > now().toTime:
    release(api.authLock)
    return api.authToken

  let gcpCreds = api.credentials
  let dur = initDuration(minutes = 50)
  api.authExp = now().toTime + dur
  let
    scopes = "https://www.googleapis.com/auth/cloud-platform"
    header = %*{
      "alg": "RS256",
      "typ": "JWT"
    }
    claims = %*{
      "iss": gcpCreds.client_email,
      "scope": scopes,
      "aud": "https://www.googleapis.com/oauth2/v4/token",
      "exp": api.authExp.toUnix,
      "iat": epochTime().int
    }
    privateKey = gcpCreds.private_key
  let jwt = signJwt(header, claims, privateKey)

  # request auth token
  let req = "grant_type=" & encodeUrl(
      "urn:ietf:params:oauth:grant-type:jwt-bearer") &
      "&assertion=" & jwt
  let resp = api.curlPool.post(
    url = "https://www.googleapis.com/oauth2/v4/token",
    headers = @[
      ("Content-Type", "application/x-www-form-urlencoded")
    ],
    body = req,
  )
  if resp.code != 200:
    echo "status code: " & $resp.code
    echo "Error getting auth token: " & resp.body
    raise newException(Exception, "Error getting auth token")
  let respJson = fromJson(resp.body, JsonNode)
  api.authToken = respJson["access_token"].str
  result = api.authToken

  release(api.authLock)
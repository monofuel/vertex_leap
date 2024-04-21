import vertex_leap, jsony, std/[unittest, options, os]

# Fine tuning Gemini Pro
# Important: this test is very very slow
# there is a default quota limit of "Global concurrent tuning jobs" = 1

# you can find tuning jobs in the Vertex AI console
# https://console.cloud.google.com/vertex-ai/generative/language/tuning?hl=en

# GCP provides a test dataset for fine tuning
# "training_dataset_uri": "gs://cloud-samples-data/ai-platform/generative_ai/sft_train_data.jsonl",
# "validation_dataset_uri": "gs://cloud-samples-data/ai-platform/generative_ai/sft_validation_data.jsonl",
const
  Gemini_1_0_pro_002 = "gemini-1.0-pro-002"
  TrainingDatasetURI = "gs://cloud-samples-data/ai-platform/generative_ai/sft_train_data.jsonl"
  ValidationDatasetURI = "gs://cloud-samples-data/ai-platform/generative_ai/sft_validation_data.jsonl"

suite "gemini pro tuning":
  var vertexai: VertexAIAPI

  setup:

    let credentialPath = os.getEnv("GOOGLE_APPLICATION_CREDENTIALS", "")
    if credentialPath == "":
      let credStr = readFile("tests/service_account.json")
      let creds = fromJson(credStr, GCPCredentials)
      vertexai = newVertexAIAPI(credentials = option(creds))
    else:
      vertexai = newVertexAIAPI()
  teardown:
    vertexai.close()

  suite "1.0-pro-002":
    var job: TuneJob
    test "create tuning job":
      let req = CreateGeminiProTuningJobRequest(
        baseModel: Gemini_1_0_pro_002,
        supervisedTuningSpec: SupervisedTuningSpec(
          trainingDatasetUri: TrainingDatasetURI,
          validationDatasetUri: option(ValidationDatasetURI),
        )
      )
      job = vertexai.createGeminiProTuningJob(req)
      assert job.state == "JOB_STATE_PENDING"
      assert job.baseModel == Gemini_1_0_pro_002
    test "list tuning jobs":
      let jobs = vertexai.listGeminiProTuningJobs()
      assert jobs.tuningJobs.len > 0
      echo jobs.tuningJobs.len
    test "wait for job completion":
      echo "waiting for job..."  
      for i in 1..600:
        job = vertexai.getGeminiProTuningJob(job.name)
        if job.state == "JOB_STATE_SUCCEEDED":
          break
        assert job.state != "JOB_STATE_FAILED"
        write(stdout, ".")
        sleep(30 * 1000)
      echo "SUCCESS"
      echo toJson(job)
from openai import OpenAI
import os

def main() -> None:
    # Defaults can be overridden by AGENT_HUB_REGION.
    REGION = os.getenv("TF_VAR_region")
    MODEL_ID = "openai.gpt-oss-120b"

    BASE_URL = f"https://inference.generativeai.{REGION}.oci.oraclecloud.com/20231130/openai/v1"
    PROJECT_OCID = os.environ.get( "TF_VAR_project_ocid" )
    GENAI_API_KEY = os.environ.get( "TF_VAR_genai_api_key" )

    client = OpenAI(
        base_url=BASE_URL,
        api_key=GENAI_API_KEY,
        project=PROJECT_OCID,
    )

    request = "What is 2x2?"

    response = client.responses.create(
        model=MODEL_ID,
        temperature=0.0,
        input=request,
    )

    print("Request:", request)
    print(response.output_text)
    print("")
    print("Full response:", response)
    print("")


if __name__ == "__main__":
    main()

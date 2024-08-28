import json
import argparse
import uuid
from mlserver.types import InferenceRequest
from mlserver.codecs import Base64Codec

parser = argparse.ArgumentParser()
parser.add_argument("filename", help="converts image to bytes array", type=str)
args = parser.parse_args()

with open(args.filename, "rb") as image_file:
    image_read = image_file.read()
    print(image_read)

print(f"{type([image_read])}", flush=True)
print(f"{Base64Codec.can_encode([image_read])}", flush=True)

request_input = Base64Codec.encode_input(name=str(uuid.uuid4()),  payload=[image_read], use_bytes=False)

print(f"Request input: {request_input}")



inference_request = InferenceRequest(id=str(uuid.uuid4()), inputs=[request_input], parameters=request_input.parameters)

print(f"Inference request: {inference_request}")

last_node = args.filename.split("/")[-1]
result_file = "{filename}.{ext}".format(filename=str(last_node).split(".")[0], ext="json")

with open(f"mlserver_inputs/{result_file}", "w") as outfile:
    json.dump(inference_request.dict(), outfile, sort_keys=True)


#!/usr/bin/python3
"""
The script takes text or image file as input and generates json input with
tensor inputs for KServe v2 protocol.
"""
import json
import numpy as np
import argparse
from utils import check_image_with_pil
from PIL import Image
from torchvision import transforms
import mlserver.grpc.converters as converters
from google.protobuf import json_format

from mlserver.types import InferenceRequest
from mlserver.codecs import NumpyCodec

parser = argparse.ArgumentParser()
parser.add_argument('filename', help='input filename')
args = parser.parse_args()
args = vars(args)
filename = args["filename"]

# get last node in filename and replace . with _
last_node = filename.split("/")[-1].replace('.','_')
outputFileName=f"input_{last_node}.json"
grpcOutputFileName=f"grpc_input_{last_node}.json"

if check_image_with_pil(filename):
    image = Image.open(filename)  # PIL's JpegImageFile format (size=(W,H))
    tran = transforms.ToTensor(
    )  # Convert the numpy array or PIL.Image read image to (C, H, W) Tensor format and /255 normalize to [0, 1.0]
    initData = tran(image)
    ## The MNIST pytorch archive file has a handler which converts the shape of the input tensor to (1,1,28,28)
    ## So we need to reshape the input tensor to (1,1,28,28) to match the expected input shape
    data = np.reshape( initData, (1,1,28,28))
else:
    with open(filename, 'r') as fp:
        text = fp.read()
    data = list(bytes(text.encode()))

data = np.array(data)

inference_request = InferenceRequest(
    inputs=[NumpyCodec.encode_input(name="payload", payload=data)]
)
#inference_request = NumpyRequestCodec.encode_request(payload=data)

print(inference_request, flush=True)

with open(f'mlserver_inputs/{outputFileName}', 'w') as outfile:
    json.dump(inference_request.dict(), outfile)
    
print(f"Input tensor saved to mlserver_inputs/{outputFileName}") 

inference_request_g = converters.ModelInferRequestConverter.from_types(
    inference_request, model_name="mnist_v2"
)
grpc_input = json_format.MessageToDict(inference_request_g)

# write to json file 
with open(f'mlserver_inputs/{grpcOutputFileName}', 'w') as outfile:
    json.dump(grpc_input, outfile)
    
print(f"Input tensor saved to mlserver_inputs/{grpcOutputFileName}")
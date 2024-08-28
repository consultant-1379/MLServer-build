import torch
from mlserver.model import MLModel
from mlserver.utils import get_model_uri
from mlserver.logging import logger
from mlserver.codecs import decode_args
import numpy as np


class PyTorchModel(MLModel):
    async def load(self) -> bool:
        model_uri = await get_model_uri(settings=self._settings)
        logger.info(f"Loading model from {model_uri}")
        self._model = torch.jit.load(model_uri)
        self._model.eval()
        logger.info(f"Model loaded from {model_uri}")
        self.ready = True
        logger.info(f"Model {self._settings.name} loaded")
        return self.ready

    @decode_args
    async def predict(self, payload: np.ndarray) -> np.ndarray:
        logger.info(f"Received request: {payload}")
        input_tensor = torch.from_numpy(payload)
        logger.debug(f"Input tensor: {input_tensor} type: {type(input_tensor)}")

        with torch.no_grad():
            result_tensor = self._model(input_tensor)
            return result_tensor.numpy()

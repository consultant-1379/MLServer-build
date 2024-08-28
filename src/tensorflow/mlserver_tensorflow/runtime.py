import numpy as np
import tensorflow as tf
from mlserver.codecs import decode_args
from mlserver.logging import logger
from mlserver.model import MLModel
from mlserver.settings import ModelSettings
from mlserver.utils import get_model_uri

from mlserver_tensorflow.common import TensorflowRuntimeSettings

WELLKNOWN_MODEL_FILENAMES = ["saved_model.pb", "saved_model.pbtxt"]


class TensorflowRuntime(MLModel):
    """Runtime class for specific Tensorflow models"""
    
    def __init__(self, settings: ModelSettings):
        if settings.parameters is None:
            self._tf_settings = TensorflowRuntimeSettings()
        else:
            extra = settings.parameters.extra
            self._tf_settings = TensorflowRuntimeSettings(**extra)  # type: ignore

        super().__init__(settings)

    async def _get_model_uri(self) -> str:
        model_uri = await get_model_uri(self._settings, WELLKNOWN_MODEL_FILENAMES)
        # check if model uri ends with any of the wellknown model filenames
        if model_uri.endswith(tuple(WELLKNOWN_MODEL_FILENAMES)):
            # go one level up to get the parent dir
            model_uri = model_uri[: model_uri.rfind("/")]
        return model_uri

    async def load(self) -> bool:
        model_uri = await self._get_model_uri()
        logger.info(f"Loading model from {model_uri}")
        self._model = tf.saved_model.load(model_uri)
        logger.info(f"Model loaded from {model_uri}")
        self.ready = True
        logger.info(f"Model {self._settings.name} loaded")
        return self.ready

    @decode_args
    async def predict(self, payload: np.ndarray) -> np.ndarray:
        payload_tensor = tf.constant(payload)
        signature_name = self._tf_settings.signature
        default_signature = self._model.signatures[signature_name]
        result = default_signature(payload_tensor)

        if isinstance(result, dict):
            try:
                response_data = result["output_0"].numpy()
            except KeyError:
                logger.warning(
                    f'''Model {self._settings.name} does not have an 
                        output named 'output_0'. Returning the first output.'''
                )
                response_data = list(result.values())[0].numpy()
        else:
            response_data = result.numpy()
        return response_data

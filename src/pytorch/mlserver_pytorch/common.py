from pydantic import BaseSettings

ENV_PREFIX_PYTORCHRUNTIME_SETTINGS = "MLSERVER_MODEL_PYTORCHRUNTIME_"

class TensorflowRuntimeSettings(BaseSettings):
    """
    Parameters that apply only to pytorch models
    """

    class Config:
        env_prefix = ENV_PREFIX_PYTORCHRUNTIME_SETTINGS




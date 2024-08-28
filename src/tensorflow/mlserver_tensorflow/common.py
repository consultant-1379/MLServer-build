from pydantic import BaseSettings

ENV_PREFIX_TENSORFLOWRUNTIME_SETTINGS = "MLSERVER_MODEL_TENSORFLOWRUNTIME_"

class TensorflowRuntimeSettings(BaseSettings):
    """
    Parameters that apply only to tensorflow models
    """

    class Config:
        env_prefix = ENV_PREFIX_TENSORFLOWRUNTIME_SETTINGS
    
    signature : str = "serving_default"


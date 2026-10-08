from huggingface_hub import HfApi
from app.core.config import settings

api = HfApi(token=settings.hf_token)
api.create_repo(repo_id=settings.hf_model_repo, repo_type="model", private=True, exist_ok=True)

for fname in ["best_multitask_model.pth", "emotion_thresholds.json"]:
    api.upload_file(
        path_or_fileobj=f"{fname}",
        path_in_repo=fname,
        repo_id=settings.hf_model_repo,
        repo_type="model",
    )
    print("Đã upload:", fname)
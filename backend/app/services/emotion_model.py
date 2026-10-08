import torch
import torch.nn as nn
import json
import os
import numpy as np
from transformers import AutoModel, AutoTokenizer
from huggingface_hub import hf_hub_download
from app.core.config import settings

PHOBERT_MODEL = "vinai/phobert-base-v2"
NUM_VIGO_LABELS = 28

VIGO_EMOTIONS = [
    'amusement', 'excitement', 'joy', 'love', 'desire', 'optimism',
    'caring', 'pride', 'admiration', 'gratitude', 'relief', 'approval',
    'realization', 'surprise', 'curiosity', 'confusion', 'fear',
    'nervousness', 'remorse', 'embarrassment', 'disappointment',
    'sadness', 'grief', 'disgust', 'anger', 'annoyance',
    'disapproval', 'neutral'
]

class PhoBERTMultiTask(nn.Module):
    def __init__(self, num_hate_labels=3, num_emotion_labels=NUM_VIGO_LABELS, dropout=0.3):
        super().__init__()
        self.phobert = AutoModel.from_pretrained(PHOBERT_MODEL, use_safetensors=True)
        hidden_size = self.phobert.config.hidden_size
        intermediate_size = 256

        self.emotion_head = nn.Sequential(
            nn.Linear(hidden_size, hidden_size // 2),
            nn.GELU(),
            nn.Dropout(dropout),
            nn.Linear(hidden_size // 2, intermediate_size),
            nn.GELU(),
            nn.Dropout(dropout),
            nn.Linear(intermediate_size, num_emotion_labels)
        )

        self.hate_head = nn.Sequential(
            nn.Linear(hidden_size, intermediate_size),
            nn.BatchNorm1d(intermediate_size),
            nn.ReLU(),
            nn.Dropout(dropout),
            nn.Linear(intermediate_size, num_hate_labels)
        )

    def forward(self, input_ids, attention_mask):
        outputs = self.phobert(input_ids=input_ids, attention_mask=attention_mask)
        last_hidden = outputs.last_hidden_state
        mask_exp = attention_mask.unsqueeze(-1).expand(last_hidden.size()).float()
        sum_emb = torch.sum(last_hidden * mask_exp, 1)
        sum_mask = torch.clamp(mask_exp.sum(1), min=1e-9)
        pooled = sum_emb / sum_mask
        return self.emotion_head(pooled), self.hate_head(pooled)


class EmotionService:
    def __init__(self):
        self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
        self.tokenizer = AutoTokenizer.from_pretrained(PHOBERT_MODEL)

        checkpoint_path = hf_hub_download(
            repo_id=settings.hf_model_repo,
            filename="best_multitask_model.pth",
            token=settings.hf_token,
        )
        thresholds_path = hf_hub_download(
            repo_id=settings.hf_model_repo,
            filename="emotion_thresholds.json",
            token=settings.hf_token,
        )

        self.model = PhoBERTMultiTask()
        state_dict = torch.load(checkpoint_path, map_location=self.device, weights_only=True)
        self.model.load_state_dict(state_dict)
        self.model.to(self.device)
        self.model.eval()

        self.thresholds = self._load_thresholds(thresholds_path)

    def _load_thresholds(self, path, default=0.5):
        with open(path, "r", encoding="utf-8") as f:
            threshold_dict = json.load(f)
        return np.array([threshold_dict.get(label, default) for label in VIGO_EMOTIONS])

    def predict_emotion(self, text: str) -> list[str]:
        encoding = self.tokenizer(
            text, add_special_tokens=True, max_length=128,
            padding="max_length", truncation=True, return_tensors="pt"
        )
        input_ids = encoding["input_ids"].to(self.device)
        attention_mask = encoding["attention_mask"].to(self.device)

        with torch.no_grad():
            emo_logits, _ = self.model(input_ids, attention_mask)
            probs = torch.sigmoid(emo_logits).cpu().numpy()[0]

        detected_with_prob = [
            (VIGO_EMOTIONS[i], probs[i]) for i in range(NUM_VIGO_LABELS)
            if probs[i] > self.thresholds[i]
        ]
        detected_with_prob.sort(key=lambda x: x[1], reverse=True)
        detected = [label for label, _ in detected_with_prob]
        return detected if detected else ["neutral"]


emotion_service = EmotionService()
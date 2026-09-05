import re
from typing import List

class TextPreprocessor:
    """Cleans and tokenizes speech-to-text outputs and memory prompts."""

    @staticmethod
    def clean_text(raw_text: str) -> str:
        if not raw_text:
            return ""
        # Strip excessive whitespace and control characters
        cleaned = re.sub(r"\s+", " ", raw_text).strip()
        return cleaned

    @staticmethod
    def tokenize_words(text: str) -> List[str]:
        cleaned = TextPreprocessor.clean_text(text)
        return [w for w in re.findall(r"\b\w+\b", cleaned.lower())]

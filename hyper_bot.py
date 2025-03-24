import time
import requests
import logging
import sys

# Hyperbolic API configuration
HYPERBOLIC_API_URL = "https://api.hyperbolic.xyz/v1/chat/completions"
HYPERBOLIC_API_KEY = "$API_KEY"  # Replaced by Bash script
MODEL = "meta-llama/Llama-3.3-70B-Instruct"
MAX_TOKENS = 2048
TEMPERATURE = 0.7
TOP_P = 0.9
DELAY_BETWEEN_QUESTIONS = 30  # Delay between questions in seconds

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def get_response(question: str) -> str:
    headers = {
        "Content-Type": "application/json",
        "Authorization": f"Bearer {HYPERBOLIC_API_KEY}"
    }
    data = {
        "messages": [{"role": "user", "content": question}],
        "model": MODEL,
        "max_tokens": MAX_TOKENS,
        "temperature": TEMPERATURE,
        "top_p": TOP_P
    }
    response = requests.post(HYPERBOLIC_API_URL, headers=headers, json=data, timeout=30)
    response.raise_for_status()
    json_response = response.json()
    return json_response.get("choices", [{}])[0].get("message", {}).get("content", "No answer")

def main():
    # Check if filename is provided as argument
    if len(sys.argv) < 2:
        logger.error("No questions file provided. Usage: python hyper_bot.py <questions_file>")
        sys.exit(1)
    
    questions_file = sys.argv[1]
    
    # Reading questions from the provided file
    try:
        with open(questions_file, "r", encoding="utf-8") as f:
            questions = [line.strip() for line in f if line.strip()]
    except Exception as e:
        logger.error(f"Error reading the file {questions_file}: {e}")
        sys.exit(1)

    if not questions:
        logger.error(f"The file {questions_file} contains no questions.")
        sys.exit(1)

    index = 0
    while True:
        question = questions[index]
        logger.info(f"Question #{index+1}: {question}")
        try:
            answer = get_response(question)
            logger.info(f"Answer: {answer}")
        except Exception as e:
            logger.error(f"Error retrieving answer for question: {question}\n{e}")
        index = (index + 1) % len(questions)
        time.sleep(DELAY_BETWEEN_QUESTIONS)

if __name__ == "__main__":
    main()

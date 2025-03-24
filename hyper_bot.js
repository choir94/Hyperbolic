const fs = require('fs');
const axios = require('axios');

// Hyperbolic API configuration
const HYPERBOLIC_API_URL = "https://api.hyperbolic.xyz/v1/chat/completions";
const HYPERBOLIC_API_KEY = "$API_KEY"; // Replaced by Bash script
const MODEL = "meta-llama/Llama-3.3-70B-Instruct";
const MAX_TOKENS = 2048;
const TEMPERATURE = 0.7;
const TOP_P = 0.9;
const DELAY_BETWEEN_QUESTIONS = 30 * 1000; // Delay in milliseconds

const logger = {
    info: console.log,
    error: console.error
};

async function getResponse(question) {
    const headers = {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${HYPERBOLIC_API_KEY}`
    };
    const data = {
        messages: [{ role: "user", content: question }],
        model: MODEL,
        max_tokens: MAX_TOKENS,
        temperature: TEMPERATURE,
        top_p: TOP_P
    };
    try {
        const response = await axios.post(HYPERBOLIC_API_URL, data, { headers, timeout: 30000 });
        return response.data.choices[0].message.content || "No answer";
    } catch (error) {
        throw error;
    }
}

async function main() {
    let questions;
    try {
        const content = fs.readFileSync("questions.txt", "utf-8");
        questions = content.split('\n').map(line => line.trim()).filter(line => line);
    } catch (error) {
        logger.error(`Error reading the questions.txt file: ${error}`);
        return;
    }

    if (!questions.length) {
        logger.error("The questions.txt file contains no questions.");
        return;
    }

    let index = 0;
    while (true) {
        const question = questions[index];
        logger.info(`Question #${index + 1}: ${question}`);
        try {
            const answer = await getResponse(question);
            logger.info(`Answer: ${answer}`);
        } catch (error) {
            logger.error(`Error retrieving answer for question: ${question}\n${error}`);
        }
        index = (index + 1) % questions.length;
        await new Promise(resolve => setTimeout(resolve, DELAY_BETWEEN_QUESTIONS));
    }
}

main().catch(error => logger.error(`Main error: ${error}`));

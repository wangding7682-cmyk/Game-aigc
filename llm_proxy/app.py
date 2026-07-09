from flask import Flask, request, jsonify
import requests
import json
import os
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)

ARK_API_BASE = os.getenv("ARK_API_BASE", "https://ark.cn-beijing.volces.com/api/v3")
ARK_API_KEY = os.getenv("ARK_API_KEY", "")
ARK_MODEL = os.getenv("ARK_MODEL", "ep-20260430103756-7wgz4")
REQUEST_TIMEOUT = int(os.getenv("REQUEST_TIMEOUT", "30"))


@app.route("/api/llm/chat", methods=["POST"])
def chat_proxy():
    try:
        data = request.get_json()
        if not data:
            return jsonify({"ok": False, "error": "Invalid request body"}), 400

        messages = data.get("messages", [])
        max_tokens = data.get("max_tokens", 600)
        temperature = data.get("temperature", 0.7)
        response_format = data.get("response_format", None)

        if not ARK_API_KEY:
            return jsonify({"ok": False, "error": "ARK_API_KEY not configured"}), 500

        url = f"{ARK_API_BASE}/chat/completions"
        headers = {
            "Content-Type": "application/json",
            "Authorization": f"Bearer {ARK_API_KEY}",
        }
        body = {
            "model": ARK_MODEL,
            "messages": messages,
            "max_tokens": max_tokens,
            "temperature": temperature,
        }
        if response_format:
            body["response_format"] = response_format

        response = requests.post(
            url,
            headers=headers,
            json=body,
            timeout=REQUEST_TIMEOUT,
        )

        response.raise_for_status()
        result = response.json()

        choices = result.get("choices", [])
        if choices and len(choices) > 0:
            content = choices[0].get("message", {}).get("content", "")
            return jsonify({
                "ok": True,
                "content": content,
                "usage": result.get("usage", {}),
                "model": result.get("model", ""),
            })
        else:
            return jsonify({"ok": False, "error": "No choices in response"}), 500

    except requests.exceptions.Timeout:
        return jsonify({"ok": False, "error": "Request timeout"}), 504
    except requests.exceptions.RequestException as e:
        return jsonify({"ok": False, "error": f"Request failed: {str(e)}"}), 502
    except Exception as e:
        return jsonify({"ok": False, "error": f"Server error: {str(e)}"}), 500


@app.route("/api/llm/health", methods=["GET"])
def health_check():
    return jsonify({
        "ok": True,
        "status": "running",
        "api_base": ARK_API_BASE,
        "model": ARK_MODEL,
        "api_key_configured": bool(ARK_API_KEY),
    })


if __name__ == "__main__":
    port = int(os.getenv("PORT", "5000"))
    debug = os.getenv("DEBUG", "false").lower() == "true"
    print(f"LLM Proxy Server starting on port {port}...")
    print(f"ARK API Base: {ARK_API_BASE}")
    print(f"ARK Model: {ARK_MODEL}")
    print(f"API Key configured: {bool(ARK_API_KEY)}")
    app.run(host="0.0.0.0", port=port, debug=debug)

from flask import Flask, jsonify, request


app = Flask(__name__)
tasks = [
    {"id": 1, "title": "Read the sandbox runbook", "done": True},
    {"id": 2, "title": "Run the boundary tests", "done": False},
]


@app.get("/tasks")
def list_tasks():
    return jsonify(tasks)


@app.post("/tasks")
def create_task():
    payload = request.get_json(silent=True) or {}
    title = payload.get("title", "").strip()
    if not title:
        return jsonify({"error": "title is required"}), 400

    task = {"id": len(tasks) + 1, "title": title, "done": False}
    tasks.append(task)
    return jsonify(task), 201


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8000)


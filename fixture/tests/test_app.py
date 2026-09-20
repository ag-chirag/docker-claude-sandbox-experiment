from app import app


def test_list_tasks():
    client = app.test_client()
    response = client.get("/tasks")
    assert response.status_code == 200
    assert len(response.get_json()) >= 2


def test_create_task_requires_title():
    client = app.test_client()
    response = client.post("/tasks", json={})
    assert response.status_code == 400


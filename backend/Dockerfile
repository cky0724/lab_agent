FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -i https://pypi.tuna.tsinghua.edu.cn/simple -r requirements.txt
COPY . .
CMD ["uvicorn", "app.main:app", "--host", "127.0.0.1", "--port", "8000"]
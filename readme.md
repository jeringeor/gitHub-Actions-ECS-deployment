## 🚀 Project: Deploy Flask App on AWS ECS via GitHub Actions

### ✅ **Objective**

Build a Dockerized Flask app → Push image to AWS ECR → Deploy to ECS Fargate automatically using GitHub Actions.

---

## 📁 **Folder Structure**

```
my-app/
├── app.py
├── Dockerfile
├── requirements.txt
├── task-definition.json
└── .github/
    └── workflows/
        └── deploy.yml
```

---

## ✅ **Step-by-Step Guide**

### 1️⃣ Create Project Directory

```sh
mkdir my-app
cd my-app
```

---

### 2️⃣ Create Flask App (`app.py`)

```python
from flask import Flask

app = Flask(__name__)

@app.route("/")
def home():
    return "Hello from AWS ECS via GitHub Actions!"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
```

---

### 3️⃣ Create Dependency File (`requirements.txt`)

```txt
Flask==3.0.0
```

---

### 4️⃣ Create Dockerfile

```Dockerfile
FROM python:3.11-slim
WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .
EXPOSE 80

CMD ["python", "app.py"]
```

---

### 5️⃣ Create ECS Task Definition (`task-definition.json`)

Replace `<AWS_ACCOUNT_ID>` and `<AWS_REGION>` accordingly.

```json
{
  "family": "my-task",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "256",
  "memory": "512",
  "executionRoleArn": "arn:aws:iam::<AWS_ACCOUNT_ID>:role/ecsTaskExecutionRole",
  "containerDefinitions": [
    {
      "name": "my-container",
      "image": "<AWS_ACCOUNT_ID>.dkr.ecr.<AWS_REGION>.amazonaws.com/my-repo:latest",
      "portMappings": [
        {
          "containerPort": 80,
          "hostPort": 80,
          "protocol": "tcp"
        }
      ],
      "essential": true
    }
  ]
}
```

---

### 6️⃣ Create IAM Execution Role for ECS (`trust-policy.json`)

Run locally:

```sh
nano trust-policy.json
```

Paste this:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

Create the role:

```sh
aws iam create-role \
  --role-name ecsTaskExecutionRole \
  --assume-role-policy-document file://trust-policy.json
```

Attach required policy:

```sh
aws iam attach-role-policy \
  --role-name ecsTaskExecutionRole \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy
```

---

### 7️⃣ Register the ECS Task Definition

```sh
aws ecs register-task-definition --cli-input-json file://task-definition.json
```

---

### 8️⃣ Create ECS Service (Fargate)

```sh
aws ecs create-service \
  --cluster my-cluster \
  --service-name my-service \
  --task-definition my-task \
  --desired-count 1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[<subnet-id>],securityGroups=[<sg-id>],assignPublicIp=ENABLED}"
```

---

### 9️⃣ Initialize Git and Push Code to GitHub

```sh
git init
git add .
git commit -m "Initial commit with Flask app and ECS setup"
git branch -M main
git remote add origin https://github.com/<your-username>/<your-repo>.git
git push -u origin main
```

---

### 🔐 1️⃣0️⃣ Add GitHub Secrets

Go to **GitHub → Repository → Settings → Secrets and variables → Actions** and add:

| Secret Key              | Value                     |
| ----------------------- | ------------------------- |
| `AWS_ACCESS_KEY_ID`     | **(Your IAM Access Key)** |
| `AWS_SECRET_ACCESS_KEY` | **(Your IAM Secret Key)** |
| `AWS_REGION`            | e.g., `us-east-2`         |
| `ECR_REPOSITORY_NAME`   | e.g., `my-repo`           |
| `ECS_CLUSTER`           | `my-cluster`              |
| `ECS_SERVICE`           | `my-service`              |
| `TASK_DEFINITION`       | `task-definition.json`    |

---

### ⚙️ 1️⃣1️⃣ Add GitHub Actions Workflow (`.github/workflows/deploy.yml`)

```yaml
name: Deploy to AWS ECS

on:
  push:
    branches:
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Configure AWS Credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ secrets.AWS_REGION }}

      - name: Login to AWS ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v1

      - name: Build, Tag, and Push Docker Image
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          IMAGE_TAG: ${{ github.sha }}
        run: |
          docker build -t $ECR_REGISTRY/${{ secrets.ECR_REPOSITORY_NAME }}:$IMAGE_TAG .
          docker push $ECR_REGISTRY/${{ secrets.ECR_REPOSITORY_NAME }}:$IMAGE_TAG

      - name: Render new ECS task definition
        id: task-def
        uses: aws-actions/amazon-ecs-render-task-definition@v1
        with:
          task-definition: ${{ secrets.TASK_DEFINITION }}
          container-name: my-container
          image: ${{ steps.login-ecr.outputs.registry }}/${{ secrets.ECR_REPOSITORY_NAME }}:${{ github.sha }}

      - name: Deploy to ECS
        uses: aws-actions/amazon-ecs-deploy-task-definition@v1
        with:
          cluster: ${{ secrets.ECS_CLUSTER }}
          service: ${{ secrets.ECS_SERVICE }}
          task-definition: ${{ steps.task-def.outputs.task-definition }}
          wait-for-service-stability: true
```

---

### ✅ 1️⃣2️⃣ Redeploy and Verify

Push your changes:

```sh
git add .
git commit -m "Added GitHub Actions workflow"
git push origin main
```

* Go to GitHub → **Actions** → Monitor workflow
* Go to AWS → ECS → Tasks → Check container status
* Copy Public IP → Visit in Browser:
  ✅ Should display: `Hello from AWS ECS via GitHub Actions!`

---

## 🎉 You're Done!

You've successfully:

* Built a Dockerized app
* Pushed it to ECR
* Deployed on ECS Fargate
* Automated deployments with GitHub Actions

from fastapi import FastAPI
import joblib
import pandas as pd
import boto3
from botocore import UNSIGNED
from botocore.client import Config

app = FastAPI()
s3 = boto3.client('s3', endpoint_url='http://localhost:4566', config=Config(signature_version=UNSIGNED))
# Use host.docker.internal for MacBook's LocalStack
#s3 = boto3.client('s3', endpoint_url='http://host.docker.internal:4566', config=Config(signature_version=UNSIGNED))
#s3 = boto3.client('s3', endpoint_url='http://localstack:4566', config=Config(signature_version=UNSIGNED))

s3.download_file('house-price-data', 'models/model.pkl', 'model.pkl')
model = joblib.load('model.pkl')

@app.post("/predict")
async def predict(data: dict):
    df = pd.DataFrame([data])
    prediction = model.predict(df)[0]
    return {"prediction": float(prediction)}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
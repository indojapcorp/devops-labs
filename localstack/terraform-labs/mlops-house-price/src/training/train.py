import pandas as pd
import boto3
from sklearn.linear_model import LinearRegression
from sklearn.model_selection import train_test_split
import joblib
from botocore import UNSIGNED
from botocore.client import Config

def train_model():
    s3 = boto3.client('s3', endpoint_url='http://localhost:4566', config=Config(signature_version=UNSIGNED))
    s3.download_file('house-price-data', 'processed/housing_preprocessed.csv', 'housing_preprocessed.csv')
    df = pd.read_csv('housing_preprocessed.csv')
    X = df.drop(columns=['median_house_value'])
    y = df['median_house_value']
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
    model = LinearRegression()
    model.fit(X_train, y_train)
    score = model.score(X_test, y_test)
    print(f"Model R^2 Score: {score}")
    # Save model
    joblib.dump(model, 'model.pkl')
    s3.upload_file('model.pkl', 'house-price-data', 'models/model.pkl')
    print("Model uploaded to s3://house-price-data/models/model.pkl")

if __name__ == "__main__":
    train_model()
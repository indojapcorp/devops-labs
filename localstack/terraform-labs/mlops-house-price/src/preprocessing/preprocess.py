import pandas as pd
import boto3
from botocore import UNSIGNED
from botocore.client import Config

def preprocess_data():
    s3 = boto3.client('s3', endpoint_url='http://localhost:4566', config=Config(signature_version=UNSIGNED))
    s3.download_file('house-price-data', 'raw/housing.csv', 'housing.csv')
    df = pd.read_csv('housing.csv')
    # Basic preprocessing
    df = df.dropna()  # Drop missing values
    df = df.drop(columns=['ocean_proximity'])  # Simplify for demo
    # Save preprocessed data
    df.to_csv('housing_preprocessed.csv', index=False)
    s3.upload_file('housing_preprocessed.csv', 'house-price-data', 'processed/housing_preprocessed.csv')
    print("Preprocessed data uploaded to s3://house-price-data/processed/housing_preprocessed.csv")
    return df

if __name__ == "__main__":
    preprocess_data()
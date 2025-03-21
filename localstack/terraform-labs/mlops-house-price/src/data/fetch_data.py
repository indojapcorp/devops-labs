import pandas as pd
import boto3
from botocore import UNSIGNED
from botocore.client import Config

def fetch_data():
    # Connect to LocalStack S3
    s3 = boto3.client('s3', endpoint_url='http://localhost:4566', config=Config(signature_version=UNSIGNED))
    # Download sample dataset (e.g., California housing)
    url = "https://raw.githubusercontent.com/ageron/handson-ml2/master/datasets/housing/housing.csv"
    df = pd.read_csv(url)
    # Upload to LocalStack S3
    df.to_csv('housing.csv', index=False)
    s3.upload_file('housing.csv', 'house-price-data', 'raw/housing.csv')
    print("Data uploaded to s3://house-price-data/raw/housing.csv")
    return df

if __name__ == "__main__":
    fetch_data()